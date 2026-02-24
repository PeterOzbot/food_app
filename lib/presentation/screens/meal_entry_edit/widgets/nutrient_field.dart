import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single labelled numeric text field used in the edit screen.
///
/// Implemented as a [StatefulWidget] so that the displayed value updates
/// reactively when [initialValue] changes across widget rebuilds (e.g. after
/// an AI-Fill operation). A [StatelessWidget] with [TextFormField.initialValue]
/// would only apply the value on the very first build; subsequent rebuilds
/// with a new [initialValue] are silently ignored by Flutter's form state.
class NutrientField extends StatefulWidget {
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
  State<NutrientField> createState() => _NutrientFieldState();
}

class _NutrientFieldState extends State<NutrientField> {
  late TextEditingController _controller;

  String _format(double? v) => v != null ? v.toStringAsFixed(1) : '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.initialValue));
  }

  @override
  void didUpdateWidget(NutrientField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Push the new value into the controller only when it actually changed.
    // This keeps the field in sync after AI-Fill (or any other programmatic
    // state update) without disturbing fields the user is actively editing.
    if (oldWidget.initialValue != widget.initialValue) {
      final newText = _format(widget.initialValue);
      if (_controller.text != newText) {
        // Defer the controller update to after the current build phase.
        // Setting _controller.text notifies ValueNotifier listeners, which
        // causes Form (an ancestor) to call setState — forbidden while the
        // framework is already building the widget tree.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.text = newText;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.unit,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: widget.readOnly,
        fillColor: widget.readOnly
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
      keyboardType: widget.readOnly
          ? null
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: widget.readOnly
          ? []
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: widget.required && !widget.readOnly
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            }
          : null,
      onChanged: widget.readOnly
          ? null
          : (v) => widget.onChanged(double.tryParse(v)),
    );
  }
}

