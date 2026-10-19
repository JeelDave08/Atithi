import 'package:flutter/material.dart';

const double _kLogoZoom = 1.08;

class AtithiRoundLogo extends StatelessWidget {
  const AtithiRoundLogo({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'atithi logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5F0E4),
          border: Border.all(
            color: const Color(0x4DC8924B),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: Transform.scale(
            scale: _kLogoZoom,
            child: Image.asset(
              'assets/images/atithi_logo.jpeg',
              fit: BoxFit.contain,
              width: size,
              height: size,
            ),
          ),
        ),
      ),
    );
  }
}
