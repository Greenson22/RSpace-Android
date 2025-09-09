// lib/features/progress/domain/models/color_palette_model.dart

import 'package:flutter/material.dart';

class ColorPalette {
  String name;
  final int backgroundColor;
  final int textColor;
  final int progressBarColor;

  ColorPalette({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.progressBarColor,
  });

  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      name: json['name'] as String,
      backgroundColor: json['backgroundColor'] as int,
      textColor: json['textColor'] as int,
      progressBarColor: json['progressBarColor'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'progressBarColor': progressBarColor,
    };
  }
}
