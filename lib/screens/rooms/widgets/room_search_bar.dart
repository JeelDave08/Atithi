import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoomSearchBar extends StatefulWidget {
  const RoomSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.onFilters,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onFilters;

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
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _focused
                ? const Color(0xFFC59B3F)
                : const Color(0xFFE5CCA0),
            width: _focused ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(
                Icons.search_rounded,
                color: AppColors.navy,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search rooms, type, amenities...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9EA7B5),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  splashRadius: 20,
                  onPressed: widget.onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.greyText,
                    size: 18,
                  ),
                ),
              if (widget.onFilters != null) ...[
                Container(
                  height: 22,
                  width: 1,
                  color: const Color(0xFFE8DFC8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                IconButton(
                  tooltip: 'Filter options',
                  splashRadius: 22,
                  onPressed: widget.onFilters,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFFC59B3F),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 4),
              ] else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    ),
  );
}
