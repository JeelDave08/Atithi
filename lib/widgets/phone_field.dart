import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../theme/app_colors.dart';
import 'app_text_field.dart';

class PhoneField extends StatelessWidget {
  const PhoneField({
    required this.country,
    required this.controller,
    required this.onCountryChanged,
    required this.validator,
    super.key,
  });

  final CountryDialCode country;
  final TextEditingController controller;
  final ValueChanged<CountryDialCode> onCountryChanged;
  final String? Function(String?) validator;

  Future<void> _chooseCountry(BuildContext context) async {
    final selected = await showModalBottomSheet<CountryDialCode>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: _CountryPickerSheet(countries: countries),
        ),
      ),
    );
    if (selected == null) return;
    if (controller.text.length > selected.phoneLength) {
      controller.text = controller.text.substring(0, selected.phoneLength);
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
    onCountryChanged(selected);
  }

  @override
  // Align the country pill to the input, not to the input plus its error.
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Material(
            color: const Color(0xFFFAF5EA),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _chooseCountry(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        country.dialCode,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF0B2347),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF0B2347),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: AppTextField(
          hint: 'Mobile number',
          controller: controller,
          validator: validator,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
        ),
      ),
    ],
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.countries});

  final List<CountryDialCode> countries;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCountries = widget.countries.where((country) {
      final query = _query.trim().toLowerCase();
      return country.name.toLowerCase().contains(query) ||
          country.dialCode.contains(query);
    }).toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 20, 22, 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose country',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search country',
              prefixIcon: const Icon(Icons.search, color: AppColors.navy),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: filteredCountries.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0x1F0B2347)),
            itemBuilder: (context, index) {
              final item = filteredCountries[index];
              return ListTile(
                leading: Text(item.flag, style: const TextStyle(fontSize: 23)),
                title: Text(
                  item.name,
                  style: const TextStyle(color: AppColors.navy),
                ),
                trailing: Text(
                  item.dialCode,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ],
    );
  }
}
