import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../models/room.dart';
import '../models/stay_search.dart';
import '../providers/pending_booking_provider.dart';
import '../providers/stay_search_provider.dart';
import '../screens/room_details/room_details_screen.dart';

void openRoomDetails(
  BuildContext context,
  Room room, {
  DateTime? checkIn,
  DateTime? checkOut,
  int adults = 2,
  int children = 0,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RoomDetailsScreen(
        roomId: room.id,
        room: room,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
      ),
    ),
  );
}

void openRoomBooking(
  BuildContext context,
  Room room, {
  DateTime? checkIn,
  DateTime? checkOut,
  int adults = 2,
  int children = 0,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final arrival = checkIn ?? today;
  final departure = checkOut != null && checkOut.isAfter(arrival)
      ? checkOut
      : arrival.add(const Duration(days: 1));
  openBooking(
    context,
    room,
    staySearch: StaySearch(
      checkIn: arrival,
      checkOut: departure,
      adults: adults,
      children: children,
    ),
  );
}

void openBooking(BuildContext context, Room room, {StaySearch? staySearch}) {
  final container = ProviderScope.containerOf(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final selected = staySearch ?? container.read(staySearchProvider);
  final search = selected?.isActive == true
      ? selected!
      : StaySearch(
          checkIn: today,
          checkOut: today.add(const Duration(days: 1)),
          adults: 2,
          children: 0,
        );
  final request = BookingRequest(room: room, staySearch: search);
  if (FirebaseAuth.instance.currentUser == null) {
    container.read(pendingBookingProvider.notifier).save(request);
    context.go('/auth');
    return;
  }
  container.read(pendingBookingProvider.notifier).clear();
  context.push('/booking', extra: request);
}
