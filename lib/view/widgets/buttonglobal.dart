import 'package:flutter/material.dart';
import 'package:nuevoyapita/utils/globalcolors.dart';

// En tu archivo buttonglobal.dart
class ButtonGlobal extends StatelessWidget {
  const ButtonGlobal({Key? key, this.text = 'Sign In'}) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 55,
      decoration: BoxDecoration(
        color: GlobalColors.mainColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}