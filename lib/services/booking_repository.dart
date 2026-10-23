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
  const BookingResult({
    required this.bookingId,
    required this.photoPath,
    required this.idProofPath,
  });

  final String bookingId;
  final String? photoPath;
  final String idProofPath;
}

class BookingRepository {
  BookingRepository({SupabaseClient? client, FirebaseAuth? auth})
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
          .select('id')
          .eq('room_id', roomId)
          .inFilter('booking_status', ['confirmed', 'pending'])
          .lt('check_in', _date(checkOut))
          .gt('check_out', _date(checkIn))
          .or(
            'booking_status.eq.confirmed,and(booking_status.eq.pending,expires_at.gt.${DateTime.now().toUtc().toIso8601String()})',
          )
          .limit(1);
      return rows.isNotEmpty;
    } catch (error, stack) {
      try {
        final rows = await _client
            .from('bookings')
            .select('id')
            .eq('room_id', roomId)
            .eq('booking_status', 'confirmed')
            .lt('check_in', _date(checkOut))
            .gt('check_out', _date(checkIn))
            .limit(1);
        return rows.isNotEmpty;
      } catch (_) {
        debugPrint('Booking overlap check failed: $error\n$stack');
        rethrow;
      }
    }
  }

  Future<bool> checkAvailability({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) => hasConflict(roomId: roomId, checkIn: checkIn, checkOut: checkOut);

  Future<void> uploadFile({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) => _client.storage
      .from('guest-docs')
      .uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: contentType),
      );

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
    required String idProofExtension,
    required Uint8List guestPhotoBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to complete your booking.');
    }

    final nights = checkOut.difference(checkIn).inDays;
    final roomPrice = (room.pricePerNight ?? 0) * nights;
    final taxes = roomPrice * kTaxRate;
    final now = DateTime.now().millisecondsSinceEpoch;
    String? photoPath;
    final idExtension = switch (idProofExtension.toLowerCase()) {
      'pdf' => 'pdf',
      'png' => 'png',
      _ => 'jpg',
    };
    final idMime = switch (idExtension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    final idProofPath = '${user.uid}/${now}_id.$idExtension';

    try {
      photoPath = '${user.uid}/${now}_photo.jpg';
      await uploadFile(
        path: photoPath,
        bytes: guestPhotoBytes,
        contentType: 'image/jpeg',
      );
      await uploadFile(
        path: idProofPath,
        bytes: idProofBytes,
        contentType: idMime,
      );
    } catch (error) {
      await _removeUploaded(photoPath, idProofPath);
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
      'booking_status': 'pending',
      'payment_status': 'pending',
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    };

    try {
      final inserted = await _client
          .from('bookings')
          .insert(row)
          .select()
          .single();
      return BookingResult(
        bookingId: inserted['id'].toString(),
        photoPath: photoPath,
        idProofPath: idProofPath,
      );
    } on PostgrestException catch (error) {
      await _removeUploaded(photoPath, idProofPath);
      throw BookingStageException(BookingFailureStage.database, error);
    } catch (error) {
      await _removeUploaded(photoPath, idProofPath);
      throw BookingStageException(BookingFailureStage.database, error);
    }
  }

  Future<void> _removeUploaded(String? photoPath, String idProofPath) async {
    final paths = [?photoPath, idProofPath];
    try {
      await _client.storage.from('guest-docs').remove(paths);
    } catch (error) {
      debugPrint('Could not remove uploaded booking documents: $error');
    }
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
