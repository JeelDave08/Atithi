import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/sunset_widgets.dart';

class PropertyScreen extends StatefulWidget {
  const PropertyScreen({super.key});
  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  int _photo = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.navy,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          final scale = (c.maxWidth / 390).clamp(.86, 1.08);
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      _round(Icons.arrow_back, () => context.pop()),
                      const Spacer(),
                      const Text(
                        'G O A  ·  I N D I A',
                        style: TextStyle(
                          color: Palette.cream,
                          fontSize: 11,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const Spacer(),
                      _round(Icons.favorite_border, () => {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 340,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 250 * scale,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Palette.gold.withOpacity(.7),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(125 * scale),
                            bottom: const Radius.circular(70),
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ClipPath(
                          clipper: ArchClipper(top: 116 * scale, bottom: 60),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                itemCount: 10,
                                onPageChanged: (i) =>
                                    setState(() => _photo = i),
                                itemBuilder: (c, i) => CachedNetworkImage(
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&sig=$i',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const _PropertyPhotoFallback(),
                                  errorWidget: (context, url, error) =>
                                      const _PropertyPhotoFallback(),
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      Color(0x33200E0A),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            10,
                            (i) => Container(
                              width: i == _photo ? 6 : 4,
                              height: i == _photo ? 22 : 4,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: i == _photo
                                    ? Palette.gold
                                    : Palette.cream.withOpacity(.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${_photo + 1}/10',
                            style: const TextStyle(
                              color: Palette.cream,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Column(
                    children: [
                      Text(
                        'Sunset Villa Resort',
                        style: serif(28 * scale, italic: true),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '★ 4.8 · 124 reviews',
                        style: TextStyle(color: Palette.gold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                  decoration: const BoxDecoration(
                    color: Palette.cream,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _stat('Check-in', '2:00 PM'),
                          _stat('Check-out', '11:00 AM'),
                          _stat('Rooms', '24'),
                          _stat('Type', 'Resort'),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Divider(color: Palette.sand, height: 1),
                      ),
                      const Text(
                        'A serene coastal retreat where golden sunsets meet thoughtful hospitality. Unwind by the pool, savour local flavours, and make every evening one to remember.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Palette.body,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text('Amenities', style: serif(16, color: Palette.navy)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _amenity(Icons.wifi, 'WiFi'),
                          _amenity(Icons.pool, 'Pool'),
                          _amenity(Icons.restaurant, 'Dining'),
                          _amenity(Icons.local_parking, 'Parking'),
                          _amenity(Icons.ac_unit, 'AC'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: serif(16, color: Palette.navy),
                          children: const [
                            TextSpan(text: 'Rooms from '),
                            TextSpan(
                              text: '₹4,500',
                              style: TextStyle(
                                color: Palette.darkGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GoldButton(
                        label: 'Choose your nights ☼',
                        dark: true,
                        onPressed: () => context.go('/availability'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  Widget _round(IconData i, VoidCallback on) => InkWell(
    onTap: on,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Palette.gold.withOpacity(.4)),
      ),
      child: Icon(i, color: Palette.cream, size: 20),
    ),
  );
  Widget _stat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Palette.grey.withOpacity(.8)),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: Palette.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
  Widget _amenity(IconData icon, String label) => Column(
    children: [
      ArchContainer(
        top: 25,
        bottom: 10,
        color: Palette.sand,
        child: SizedBox(
          width: 52,
          height: 62,
          child: Icon(icon, color: Palette.navy, size: 21),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: Palette.body)),
    ],
  );
}

class _PropertyPhotoFallback extends StatelessWidget {
  const _PropertyPhotoFallback();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF396579), Color(0xFFE0A56F), Palette.navy],
      ),
    ),
    child: Icon(Icons.wb_sunny_outlined, color: Palette.gold, size: 40),
  );
}
