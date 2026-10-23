import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomAmenitiesCard extends StatelessWidget {
  const RoomAmenitiesCard({required this.amenities, super.key});

  final List<String> amenities;

  static const _knownAmenities = <String, (IconData, String)>{
    'wifi': (Icons.wifi_rounded, 'Free WiFi'),
    'free_wifi': (Icons.wifi_rounded, 'Free WiFi'),
    'ac': (Icons.ac_unit_rounded, 'Air Conditioning'),
    'air_conditioning': (Icons.ac_unit_rounded, 'Air Conditioning'),
    'tv': (Icons.tv_rounded, 'TV'),
    'mini_bar': (Icons.local_bar_outlined, 'Mini Bar'),
    'minibar': (Icons.local_bar_outlined, 'Mini Bar'),
    'room_service': (Icons.room_service_outlined, 'Room Service'),
    'balcony': (Icons.balcony_rounded, 'Balcony'),
    'work_desk': (Icons.desk_rounded, 'Work Desk'),
    'breakfast': (Icons.free_breakfast_outlined, 'Breakfast'),
  };

  static String labelFor(String key) {
    final normalized =
        key.toLowerCase().trim().replaceAll(RegExp(r'[\s\-]+'), '_');
    if (_knownAmenities.containsKey(normalized)) {
      return _knownAmenities[normalized]!.$2;
    }
    return key.trim().split(RegExp(r'[\s_]+')).map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  List<(IconData, String)> get _resolvedList {
    final list = <(IconData, String)>[];
    final seen = <String>{};

    for (final raw in amenities) {
      final key = raw.toLowerCase().trim().replaceAll(RegExp(r'[\s\-]+'), '_');
      if (_knownAmenities.containsKey(key)) {
        final item = _knownAmenities[key]!;
        if (seen.add(item.$2)) {
          list.add(item);
        }
      } else {
        // Fallback for custom labels
        final formatted = raw.trim().split(RegExp(r'[\s_]+')).map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
        if (seen.add(formatted)) {
          list.add((Icons.check_circle_outline_rounded, formatted));
        }
      }
    }

    // If amenities list in database is empty, provide standard luxury amenities
    if (list.isEmpty) {
      return const [
        (Icons.wifi_rounded, 'Free WiFi'),
        (Icons.ac_unit_rounded, 'Air Conditioning'),
        (Icons.tv_rounded, 'TV'),
        (Icons.local_bar_outlined, 'Mini Bar'),
        (Icons.room_service_outlined, 'Room Service'),
      ];
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolvedList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Text(
          'Room Amenities',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF102F52),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal Icons & Labels Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$1,
                      size: 24,
                      color: const Color(0xFF102F52),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        item.$2,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102F52),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
