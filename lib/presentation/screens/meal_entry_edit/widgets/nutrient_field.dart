import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single labelled numeric text field used in the edit screen.
class NutrientField extends StatelessWidget {
  const NutrientField({
    super.key,
    required this.label,
    required this.unit,
    required this.initialValue,
    required this.onChanged,
    this.required = false,
    this.readOnly = false,
  });

  final String label;
  final String unit;
  final double? initialValue;
  final ValueChanged<double?> onChanged;
  final bool required;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue:
          initialValue != null ? initialValue!.toStringAsFixed(1) : '',
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: readOnly,
        fillColor: readOnly
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
      keyboardType: readOnly
          ? null
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: readOnly
          ? []
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: required && !readOnly
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            }
          : null,
      onChanged: readOnly
          ? null
          : (v) => onChanged(double.tryParse(v)),
    );
  }
}

