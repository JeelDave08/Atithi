import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomDescription extends StatelessWidget {
  const RoomDescription({
    required this.description,
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = description.trim().isEmpty
        ? 'Settle into a thoughtfully designed room made for a comfortable stay.'
        : description;
    const bodyStyle = TextStyle(
      color: AppColors.greyText,
      fontSize: 14,
      height: 1.55,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final measurement = TextPainter(
          text: TextSpan(text: text, style: bodyStyle),
          textDirection: Directionality.of(context),
          maxLines: 4,
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = measurement.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Description'),
            const SizedBox(height: 9),
            Text(
              text,
              maxLines: expanded ? null : 4,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: bodyStyle,
            ),
            if (canExpand)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onToggle,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkGold,
                  ),
                  child: Text(expanded ? 'Show less' : 'Read more'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: AppColors.navy,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );
}
