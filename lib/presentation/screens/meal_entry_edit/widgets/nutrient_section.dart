import 'package:flutter/material.dart';

/// Collapsible section that wraps a set of [NutrientField] widgets.
class NutrientSection extends StatelessWidget {
  const NutrientSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        initiallyExpanded: initiallyExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

