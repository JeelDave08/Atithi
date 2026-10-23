import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomSearchBar extends StatefulWidget {
  const RoomSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<RoomSearchBar> createState() => _RoomSearchBarState();
}

class _RoomSearchBarState extends State<RoomSearchBar> {
  bool _focused = false;

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.gold,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: TextField(
            controller: widget.controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: AppColors.navy, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
              suffixIcon: widget.controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.close_rounded, color: AppColors.greyText),
                    ),
              hintText: 'Search rooms, type, amenities...',
              hintStyle: const TextStyle(color: AppColors.greyText, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    ),
  );
}
