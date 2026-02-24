import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/openai_service.dart';
import '../../../data/models/meal_entry_model.dart';
import '../../providers/ai_macro_provider.dart';
import '../../providers/day_detail_provider.dart';
import '../../providers/meal_entry_edit_provider.dart';
import '../../providers/meal_list_provider.dart';
import 'widgets/ai_result_bottom_sheet.dart';
import 'widgets/nutrient_field.dart';
import 'widgets/nutrient_section.dart';

class MealEntryEditScreen extends ConsumerStatefulWidget {
  const MealEntryEditScreen({
    super.key,
    this.entryId,
    this.initialDate,
    this.existingEntry,
  });

  /// null → new entry
  final int? entryId;

  /// Used when creating a new entry from a specific day's screen.
  final DateTime? initialDate;

  /// Full entry passed from the list screen to pre-fill for editing.
  final MealEntry? existingEntry;

  @override
  ConsumerState<MealEntryEditScreen> createState() =>
      _MealEntryEditScreenState();
}

class _MealEntryEditScreenState extends ConsumerState<MealEntryEditScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Defer provider mutation to after the first frame so we never modify
    // a provider while the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mealEntryEditProvider.notifier).init(
            existing: widget.existingEntry,
            date: widget.initialDate,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(mealEntryEditProvider);
    final entry = editState.entry;
    final isNew = editState.isNew;

    // React to AI-Fill completion and errors.
    ref.listen<AsyncValue<AiMacroResult?>>(aiMacroProvider, (_, next) {
      next.whenOrNull(
        data: (aiResult) {
          if (aiResult == null) return; // idle — nothing to do
          // Show result bottom sheet before updating any form fields.
          _showAiFillResultSheet(context, aiResult);
        },
        error: (error, _) {
          ref.read(aiMacroProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI error: $error')),
          );
        },
      );
    });

    return PopScope(
      canPop: !editState.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && editState.isDirty) {
          final leave = await _confirmDiscard(context);
          if (leave && context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNew ? 'New Entry' : 'Edit Entry'),
          actions: [
            if (editState.isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: () => _save(context),
                child: const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            children: [
              _BasicInfoSection(entry: entry, isNew: isNew),
              _MacroSection(entry: entry),
              NutrientSection(
                title: 'Vitamins',
                children: _vitaminFields(entry),
              ),
              NutrientSection(
                title: 'Minerals',
                children: _mineralFields(entry),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(mealEntryEditProvider.notifier).save();
    if (success && context.mounted) {
      // Invalidate both list and day-detail so they refresh on pop.
      ref.invalidate(mealListProvider);
      final date = ref.read(mealEntryEditProvider).entry.date;
      ref.invalidate(dayDetailProvider(
        DateTime(date.year, date.month, date.day),
      ));
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows the AI-Fill Result bottom sheet and, if the user taps Apply,
  /// merges the AI entry into the form and resets the provider.
  Future<void> _showAiFillResultSheet(
    BuildContext context,
    AiMacroResult aiResult,
  ) async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => AiResultBottomSheet(
        confidence: aiResult.confidence,
        note: aiResult.note,
      ),
    );

    if (applied == true && mounted) {
      final current = ref.read(mealEntryEditProvider).entry;
      final merged =
          aiResult.entry.copyWith(date: current.date, text: current.text);
      ref.read(mealEntryEditProvider.notifier).update(merged);
      ref.read(aiMacroProvider.notifier).reset();
    }
  }

  List<Widget> _vitaminFields(MealEntry e) {
    return [
      NutrientField(label: 'Vitamin A', unit: 'mcg', initialValue: e.vitaminA, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Vitamin C', unit: 'mg', initialValue: e.vitaminC, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Vitamin D', unit: 'mcg', initialValue: e.vitaminD, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Vitamin E', unit: 'mg', initialValue: e.vitaminE, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Vitamin K', unit: 'mcg', initialValue: e.vitaminK, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Thiamin B1', unit: 'mg', initialValue: e.thiaminB1, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Riboflavin B2', unit: 'mg', initialValue: e.riboflavinB2, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Niacin B3', unit: 'mg', initialValue: e.niacinB3, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Vitamin B6', unit: 'mg', initialValue: e.vitaminB6, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Folate B9', unit: 'mcg', initialValue: e.folateB9, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Vitamin B12', unit: 'mcg', initialValue: e.vitaminB12, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Pantothenic Acid B5', unit: 'mg', initialValue: e.pantothenicAcidB5, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Biotin B7', unit: 'mcg', initialValue: e.biotinB7, readOnly: true, onChanged: (_) {}),
    ];
  }

  List<Widget> _mineralFields(MealEntry e) {
    return [
      NutrientField(label: 'Calcium', unit: 'mg', initialValue: e.calcium, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Iron', unit: 'mg', initialValue: e.iron, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Magnesium', unit: 'mg', initialValue: e.magnesium, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Phosphorus', unit: 'mg', initialValue: e.phosphorus, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Potassium', unit: 'mg', initialValue: e.potassium, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Sodium', unit: 'mg', initialValue: e.sodium, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Zinc', unit: 'mg', initialValue: e.zinc, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Copper', unit: 'mg', initialValue: e.copper, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Manganese', unit: 'mg', initialValue: e.manganese, readOnly: true, onChanged: (_) {}),
      NutrientField(label: 'Selenium', unit: 'mcg', initialValue: e.selenium, readOnly: true, onChanged: (_) {}),
    ];
  }
}

// ── Basic Info Section ───────────────────────────────────────────────────────

class _BasicInfoSection extends ConsumerWidget {
  const _BasicInfoSection({required this.entry, required this.isNew});
  final MealEntry entry;
  final bool isNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void upd(MealEntry updated) =>
        ref.read(mealEntryEditProvider.notifier).update(updated);

    final aiState = ref.watch(aiMacroProvider);
    final isAiLoading = aiState.isLoading;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Basic Info', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            // Date picker row
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: entry.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  upd(entry.copyWith(date: picked));
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('d MMMM yyyy').format(entry.date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: entry.text,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (v) => upd(entry.copyWith(text: v)),
            ),
            // AI-Fill button — available for both new and existing entries.
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (isAiLoading || entry.text.trim().isEmpty)
                  ? null
                  : () => ref
                      .read(aiMacroProvider.notifier)
                      .estimate(entry.text),
              icon: isAiLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(isAiLoading ? 'Calculating…' : 'AI-Fill'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Macro Section ────────────────────────────────────────────────────────────

class _MacroSection extends ConsumerWidget {
  const _MacroSection({required this.entry});
  final MealEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NutrientSection(
      title: 'Macronutrients',
      initiallyExpanded: true,
      children: [
        NutrientField(label: 'Calories', unit: 'kcal', initialValue: entry.calories, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Protein', unit: 'g', initialValue: entry.protein, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Total Fat', unit: 'g', initialValue: entry.totalFat, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Carbohydrates', unit: 'g', initialValue: entry.carbohydrates, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Dietary Fiber', unit: 'g', initialValue: entry.dietaryFiber, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Sugars', unit: 'g', initialValue: entry.sugars, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Saturated Fat', unit: 'g', initialValue: entry.saturatedFat, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Trans Fat', unit: 'g', initialValue: entry.transFat, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Cholesterol', unit: 'mg', initialValue: entry.cholesterol, readOnly: true, onChanged: (_) {}),
        NutrientField(label: 'Water', unit: 'ml', initialValue: entry.water, readOnly: true, onChanged: (_) {}),
      ],
    );
  }
}

