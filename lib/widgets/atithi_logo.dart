import 'package:flutter/material.dart';

class AtithiLogo extends StatelessWidget {
  const AtithiLogo({super.key, this.size = 128});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Atithi logo',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5EB),
        borderRadius: BorderRadius.circular(size == 128 ? 28 : 20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/images/atithi_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}
