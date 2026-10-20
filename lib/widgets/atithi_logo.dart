import 'package:flutter/material.dart';

class AtithiLogo extends StatelessWidget {
  const AtithiLogo({super.key, this.size = 156});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Atithi logo',
    image: true,
    child: Image.asset(
      'assets/images/atithi_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}
