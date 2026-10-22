import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';
import '../screens/room_details/room_details_constants.dart';

class BookingConflictException implements Exception {
  const BookingConflictException();

  @override
  String toString() => 'This room is not available for the selected dates';
}

class BookingStageException implements Exception {
  const BookingStageException(this.stage, this.cause);

  final BookingFailureStage stage;
  final Object cause;
}

enum BookingFailureStage { storage, database }

class BookingResult {
  const BookingResult({required this.photoPath, required this.idProofPath});

  final String? photoPath;
  final String idProofPath;
}

class BookingService {
  BookingService({SupabaseClient? client, FirebaseAuth? auth})
    : _client = client ?? Supabase.instance.client,
      _auth = auth ?? FirebaseAuth.instance;

  final SupabaseClient _client;
  final FirebaseAuth _auth;

  Future<bool> hasConflict({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final rows = await _client
          .from('bookings')
          .select('room_id')
          .eq('room_id', roomId)
          .neq('booking_status', 'cancelled')
          .lt('check_in', _date(checkOut))
          .gt('check_out', _date(checkIn))
          .limit(1);
      return rows.isNotEmpty;
    } catch (error, stack) {
      debugPrint('Booking overlap check ignored: $error\n$stack');
      return false;
    }
  }

  Future<BookingResult> createBooking({
    required Room room,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required String specialRequests,
    required String idProofType,
    required Uint8List idProofBytes,
    Uint8List? guestPhotoBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to complete your booking.');
    }

    final nights = checkOut.difference(checkIn).inDays;
    final roomPrice = (room.pricePerNight ?? 0) * nights;
    final taxes = roomPrice * kTaxRate;
    final now = DateTime.now().microsecondsSinceEpoch;
    String? photoPath;
    late final String idProofPath;

    try {
      if (guestPhotoBytes != null) {
        photoPath = '${user.uid}/${now}_photo.jpg';
        await _client.storage
            .from('guest-docs')
            .uploadBinary(
              photoPath,
              guestPhotoBytes,
              fileOptions: const FileOptions(
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      }
      idProofPath = '${user.uid}/${now}_id.jpg';
      await _client.storage
          .from('guest-docs')
          .uploadBinary(
            idProofPath,
            idProofBytes,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );
    } catch (error) {
      throw BookingStageException(BookingFailureStage.storage, error);
    }

    final row = <String, dynamic>{
      'property_id': room.propertyId,
      'room_id': room.id,
      'firebase_uid': user.uid,
      'guest_name': guestName.trim(),
      'guest_email': guestEmail.trim(),
      'guest_phone': guestPhone.trim(),
      'check_in': _date(checkIn),
      'check_out': _date(checkOut),
      'adults': adults,
      'children': children,
      'nights': nights,
      'room_price': roomPrice,
      'taxes_amount': taxes,
      'total_amount': roomPrice + taxes,
      'special_requests': specialRequests.trim().isEmpty
          ? null
          : specialRequests.trim(),
      'guest_photo_path': photoPath,
      'id_proof_type': idProofType,
      'id_proof_path': idProofPath,
      'booking_status': 'confirmed',
      'payment_status': 'pending',
    };

    try {
      await _client.from('bookings').insert(row);
    } on PostgrestException catch (error) {
      final statusConstraintError =
          (error.code == '22P02' || error.code == '23514') &&
          error.message.contains('booking_status');
      if (statusConstraintError) {
        try {
          await _client.from('bookings').insert({
            ...row,
            'booking_status': 'pending',
          });
          return BookingResult(photoPath: photoPath, idProofPath: idProofPath);
        } catch (retryError) {
          throw BookingStageException(BookingFailureStage.database, retryError);
        }
      }
      throw BookingStageException(BookingFailureStage.database, error);
    } catch (error) {
      throw BookingStageException(BookingFailureStage.database, error);
    }

    return BookingResult(photoPath: photoPath, idProofPath: idProofPath);
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
