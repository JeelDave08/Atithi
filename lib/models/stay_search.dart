class StaySearch {
  const StaySearch({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
  });
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  int get totalGuests => adults + children;
  int get nights => checkOut.difference(checkIn).inDays;
  bool get isActive => nights > 0 && adults > 0;
}
