import '../../../models/room.dart';

class BookingFormState {
  const BookingFormState({
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
  });

  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;

  int get nights => checkOut.difference(checkIn).inDays;
  int get totalGuests => adults + children;
  bool get isWithinCapacity => totalGuests <= room.maxGuests;
  double get roomPrice => (room.pricePerNight ?? 0) * nights;
  double get taxes => roomPrice * .12;
  double get total => roomPrice + taxes;

  static String? validateName(String? value) =>
      (value?.trim().length ?? 0) < 2 ? 'Enter at least 2 characters.' : null;
  static String? validatePhone(String? value) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid 10-digit mobile number.';
  static String? validateEmail(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid email address.';
}
