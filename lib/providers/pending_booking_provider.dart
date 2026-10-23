import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room.dart';
import '../models/stay_search.dart';

class BookingRequest {
  const BookingRequest({required this.room, required this.staySearch});
  final Room room;
  final StaySearch staySearch;
}

class PendingBookingNotifier extends Notifier<BookingRequest?> {
  @override
  BookingRequest? build() => null;
  void save(BookingRequest request) => state = request;
  void clear() => state = null;
}

final pendingBookingProvider =
    NotifierProvider<PendingBookingNotifier, BookingRequest?>(
      PendingBookingNotifier.new,
    );
