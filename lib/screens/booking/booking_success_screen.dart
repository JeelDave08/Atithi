import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';

class BookingSuccessData {
  const BookingSuccessData({
    required this.roomName,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.total,
  });

  final String roomName;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double total;
}

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({required this.data, super.key});

  final BookingSuccessData data;

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .22),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.darkGold,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Booking Confirmed!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.navy,
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your stay is reserved. We look forward to welcoming you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyText, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.roomName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.navy,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.roomType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${DateFormat('d MMM yyyy').format(data.checkIn)} – ${DateFormat('d MMM yyyy').format(data.checkOut)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.navy),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${data.adults} Adults + ${data.children} Children',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.greyText),
                          ),
                          const Divider(height: 24, color: AppColors.border),
                          Text(
                            'Total Amount · ${_currency.format(data.total)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/bookings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: AppColors.cream,
                          minimumSize: const Size(0, 52),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.book_outlined),
                        label: const Text(
                          'View My Bookings',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(color: AppColors.gold),
                          minimumSize: const Size(0, 50),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
