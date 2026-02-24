import 'package:flutter/material.dart';

/// Non-dismissible bottom sheet shown after a successful AI-Fill operation.
///
/// Displays the AI's [confidence] level (colour-coded badge) and optional
/// [note] explaining any assumptions. The user must tap **Apply** to confirm;
/// the sheet cannot be dismissed by dragging or tapping outside.
///
/// Returns `true` via [Navigator.pop] when Apply is tapped.
class AiResultBottomSheet extends StatelessWidget {
  const AiResultBottomSheet({
    super.key,
    required this.confidence,
    this.note,
  });

  /// AI self-assessment: `'high'`, `'medium'`, or `'low'`.
  final String confidence;

  /// Any assumptions the AI made (e.g. estimated portion sizes).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Estimation Result',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Confidence:',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
                _ConfidenceBadge(confidence: confidence),
              ],
            ),
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes: ',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Text(note!, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confidence badge ──────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final String confidence;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (confidence.toLowerCase()) {
      'high' => (Colors.green, 'High'),
      'medium' => (Colors.amber.shade700, 'Medium'),
      _ => (Colors.red, 'Low'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38), // ~15 % opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

