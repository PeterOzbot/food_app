import 'package:equatable/equatable.dart';

class MealEntry extends Equatable {
  final int? id;
  final DateTime date;
  final String text;

  // Macronutrients – required
  final double calories;
  final double protein;
  final double totalFat;
  final double carbohydrates;
  final double dietaryFiber;
  final double sugars;

  // Macronutrients – optional
  final double? saturatedFat;
  final double? transFat;

  // Vitamins
  final double? vitaminA;
  final double? vitaminC;
  final double? vitaminD;
  final double? vitaminE;
  final double? vitaminK;
  final double? thiaminB1;
  final double? riboflavinB2;
  final double? niacinB3;
  final double? vitaminB6;
  final double? folateB9;
  final double? vitaminB12;
  final double? pantothenicAcidB5;
  final double? biotinB7;

  // Minerals
  final double? calcium;
  final double? iron;
  final double? magnesium;
  final double? phosphorus;
  final double? potassium;
  final double? sodium;
  final double? zinc;
  final double? copper;
  final double? manganese;
  final double? selenium;

  // Extras
  final double? cholesterol;
  final double? water;

  const MealEntry({
    this.id,
    required this.date,
    required this.text,
    required this.calories,
    required this.protein,
    required this.totalFat,
    required this.carbohydrates,
    required this.dietaryFiber,
    required this.sugars,
    this.saturatedFat,
    this.transFat,
    this.vitaminA,
    this.vitaminC,
    this.vitaminD,
    this.vitaminE,
    this.vitaminK,
    this.thiaminB1,
    this.riboflavinB2,
    this.niacinB3,
    this.vitaminB6,
    this.folateB9,
    this.vitaminB12,
    this.pantothenicAcidB5,
    this.biotinB7,
    this.calcium,
    this.iron,
    this.magnesium,
    this.phosphorus,
    this.potassium,
    this.sodium,
    this.zinc,
    this.copper,
    this.manganese,
    this.selenium,
    this.cholesterol,
    this.water,
  });

  // ── Serialisation ──────────────────────────────────────────────────────

  factory MealEntry.fromMap(Map<String, dynamic> m) => MealEntry(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        text: m['text'] as String,
        calories: (m['calories'] as num).toDouble(),
        protein: (m['protein'] as num).toDouble(),
        totalFat: (m['total_fat'] as num).toDouble(),
        carbohydrates: (m['carbohydrates'] as num).toDouble(),
        dietaryFiber: (m['dietary_fiber'] as num).toDouble(),
        sugars: (m['sugars'] as num).toDouble(),
        saturatedFat: (m['saturated_fat'] as num?)?.toDouble(),
        transFat: (m['trans_fat'] as num?)?.toDouble(),
        vitaminA: (m['vitamin_a'] as num?)?.toDouble(),
        vitaminC: (m['vitamin_c'] as num?)?.toDouble(),
        vitaminD: (m['vitamin_d'] as num?)?.toDouble(),
        vitaminE: (m['vitamin_e'] as num?)?.toDouble(),
        vitaminK: (m['vitamin_k'] as num?)?.toDouble(),
        thiaminB1: (m['thiamin_b1'] as num?)?.toDouble(),
        riboflavinB2: (m['riboflavin_b2'] as num?)?.toDouble(),
        niacinB3: (m['niacin_b3'] as num?)?.toDouble(),
        vitaminB6: (m['vitamin_b6'] as num?)?.toDouble(),
        folateB9: (m['folate_b9'] as num?)?.toDouble(),
        vitaminB12: (m['vitamin_b12'] as num?)?.toDouble(),
        pantothenicAcidB5: (m['pantothenic_acid_b5'] as num?)?.toDouble(),
        biotinB7: (m['biotin_b7'] as num?)?.toDouble(),
        calcium: (m['calcium'] as num?)?.toDouble(),
        iron: (m['iron'] as num?)?.toDouble(),
        magnesium: (m['magnesium'] as num?)?.toDouble(),
        phosphorus: (m['phosphorus'] as num?)?.toDouble(),
        potassium: (m['potassium'] as num?)?.toDouble(),
        sodium: (m['sodium'] as num?)?.toDouble(),
        zinc: (m['zinc'] as num?)?.toDouble(),
        copper: (m['copper'] as num?)?.toDouble(),
        manganese: (m['manganese'] as num?)?.toDouble(),
        selenium: (m['selenium'] as num?)?.toDouble(),
        cholesterol: (m['cholesterol'] as num?)?.toDouble(),
        water: (m['water'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'text': text,
        'calories': calories,
        'protein': protein,
        'total_fat': totalFat,
        'carbohydrates': carbohydrates,
        'dietary_fiber': dietaryFiber,
        'sugars': sugars,
        'saturated_fat': saturatedFat,
        'trans_fat': transFat,
        'vitamin_a': vitaminA,
        'vitamin_c': vitaminC,
        'vitamin_d': vitaminD,
        'vitamin_e': vitaminE,
        'vitamin_k': vitaminK,
        'thiamin_b1': thiaminB1,
        'riboflavin_b2': riboflavinB2,
        'niacin_b3': niacinB3,
        'vitamin_b6': vitaminB6,
        'folate_b9': folateB9,
        'vitamin_b12': vitaminB12,
        'pantothenic_acid_b5': pantothenicAcidB5,
        'biotin_b7': biotinB7,
        'calcium': calcium,
        'iron': iron,
        'magnesium': magnesium,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'sodium': sodium,
        'zinc': zinc,
        'copper': copper,
        'manganese': manganese,
        'selenium': selenium,
        'cholesterol': cholesterol,
        'water': water,
      };

  // ── copyWith ───────────────────────────────────────────────────────────

  MealEntry copyWith({
    int? id,
    DateTime? date,
    String? text,
    double? calories,
    double? protein,
    double? totalFat,
    double? carbohydrates,
    double? dietaryFiber,
    double? sugars,
    double? saturatedFat,
    double? transFat,
    double? vitaminA,
    double? vitaminC,
    double? vitaminD,
    double? vitaminE,
    double? vitaminK,
    double? thiaminB1,
    double? riboflavinB2,
    double? niacinB3,
    double? vitaminB6,
    double? folateB9,
    double? vitaminB12,
    double? pantothenicAcidB5,
    double? biotinB7,
    double? calcium,
    double? iron,
    double? magnesium,
    double? phosphorus,
    double? potassium,
    double? sodium,
    double? zinc,
    double? copper,
    double? manganese,
    double? selenium,
    double? cholesterol,
    double? water,
  }) => MealEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        text: text ?? this.text,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        totalFat: totalFat ?? this.totalFat,
        carbohydrates: carbohydrates ?? this.carbohydrates,
        dietaryFiber: dietaryFiber ?? this.dietaryFiber,
        sugars: sugars ?? this.sugars,
        saturatedFat: saturatedFat ?? this.saturatedFat,
        transFat: transFat ?? this.transFat,
        vitaminA: vitaminA ?? this.vitaminA,
        vitaminC: vitaminC ?? this.vitaminC,
        vitaminD: vitaminD ?? this.vitaminD,
        vitaminE: vitaminE ?? this.vitaminE,
        vitaminK: vitaminK ?? this.vitaminK,
        thiaminB1: thiaminB1 ?? this.thiaminB1,
        riboflavinB2: riboflavinB2 ?? this.riboflavinB2,
        niacinB3: niacinB3 ?? this.niacinB3,
        vitaminB6: vitaminB6 ?? this.vitaminB6,
        folateB9: folateB9 ?? this.folateB9,
        vitaminB12: vitaminB12 ?? this.vitaminB12,
        pantothenicAcidB5: pantothenicAcidB5 ?? this.pantothenicAcidB5,
        biotinB7: biotinB7 ?? this.biotinB7,
        calcium: calcium ?? this.calcium,
        iron: iron ?? this.iron,
        magnesium: magnesium ?? this.magnesium,
        phosphorus: phosphorus ?? this.phosphorus,
        potassium: potassium ?? this.potassium,
        sodium: sodium ?? this.sodium,
        zinc: zinc ?? this.zinc,
        copper: copper ?? this.copper,
        manganese: manganese ?? this.manganese,
        selenium: selenium ?? this.selenium,
        cholesterol: cholesterol ?? this.cholesterol,
        water: water ?? this.water,
      );

  // ── Equatable ──────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
        id, date, text,
        calories, protein, totalFat, carbohydrates, dietaryFiber, sugars,
        saturatedFat, transFat,
        vitaminA, vitaminC, vitaminD, vitaminE, vitaminK,
        thiaminB1, riboflavinB2, niacinB3, vitaminB6, folateB9,
        vitaminB12, pantothenicAcidB5, biotinB7,
        calcium, iron, magnesium, phosphorus, potassium,
        sodium, zinc, copper, manganese, selenium,
        cholesterol, water,
      ];
}

