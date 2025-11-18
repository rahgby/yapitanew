import 'package:flutter/material.dart';

class GlobalColors {
  static Color mainColor = _hexToColor('1B61B6');
  static Color textColor = _hexToColor('778AA1');

  static Color _hexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}