import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../theme/app_colors.dart';
import 'auth_field.dart';

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
          child: Column(
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
              Expanded(
                child: ListView.separated(
                  itemCount: countries.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0x1F0B2347)),
                  itemBuilder: (context, index) {
                    final item = countries[index];
                    return ListTile(
                      leading: Text(
                        item.flag,
                        style: const TextStyle(fontSize: 23),
                      ),
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
          ),
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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        height: 56,
        child: Material(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _chooseCountry(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 17)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      country.dialCode,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.navy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: AuthField(
          hint: 'Mobile number',
          controller: controller,
          validator: validator,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          maxLength: country.phoneLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    ],
  );
}
