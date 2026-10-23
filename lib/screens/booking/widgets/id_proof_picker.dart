import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class IdProofPicker extends StatelessWidget {
  const IdProofPicker({
    required this.type,
    required this.onTypeChanged,
    required this.bytes,
    required this.extension,
    required this.error,
    required this.onPick,
    super.key,
  });
  final String type;
  final ValueChanged<String> onTypeChanged;
  final Uint8List? bytes;
  final String? extension;
  final String? error;
  final VoidCallback onPick;
  static const types = [
    'Aadhaar Card',
    'Passport',
    'Driving Licence',
    'Voter ID',
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<String>(
        initialValue: type,
        decoration: InputDecoration(
          labelText: 'Proof Type',
          labelStyle: const TextStyle(color: AppColors.navy),
          filled: true,
          fillColor: AppColors.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        dropdownColor: AppColors.cream,
        items: types
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: AppColors.navy),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onTypeChanged(value);
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          if (bytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: extension == 'pdf'
                  ? Container(
                      width: 54,
                      height: 54,
                      color: AppColors.cream,
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppColors.darkGold,
                      ),
                    )
                  : Image.memory(
                      bytes!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.darkGold,
              size: 18,
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Uploaded',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.darkGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onPick,
              child: const Text(
                'Change',
                style: TextStyle(color: AppColors.navy),
              ),
            ),
          ] else
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text(
                  'Upload ID Proof (JPG, PNG, PDF)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.gold),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
        ],
      ),
      if (error != null) ...[
        const SizedBox(height: 5),
        Text(
          error!,
          style: const TextStyle(color: AppColors.navy, fontSize: 12),
        ),
      ],
    ],
  );
}
