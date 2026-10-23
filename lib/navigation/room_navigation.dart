import 'package:flutter/material.dart';

import '../models/room.dart';
import '../screens/booking/booking_screen.dart';
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
  final today = DateTime.now();
  final arrival = checkIn ?? DateTime(today.year, today.month, today.day);
  final departure = checkOut != null && checkOut.isAfter(arrival)
      ? checkOut
      : arrival.add(const Duration(days: 1));
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BookingScreen(
        room: room,
        checkIn: arrival,
        checkOut: departure,
        adults: adults,
        children: children,
      ),
    ),
  );
}
