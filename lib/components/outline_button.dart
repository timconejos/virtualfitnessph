import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double fontSize;
  final IconData? icon;
  final IconAlignment? iconAlignment;
  final double iconSize;

  const OutlineButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = AppStyles.primaryForeground,
    this.fontSize = 12,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.iconSize = 15
  }) : super(key: key); 


  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.0), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), 
        ),
        padding: EdgeInsets.symmetric(horizontal: 15.0), 
        textStyle: TextStyle(
          fontSize: fontSize,
          color: color, 
        ),
        foregroundColor: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAlignment == IconAlignment.start) Icon(icon, size: iconSize),
          if (iconAlignment == IconAlignment.start) SizedBox(width: 8),
          Text(text), 
          if (iconAlignment == IconAlignment.end) SizedBox(width: 8),
          if (iconAlignment == IconAlignment.end) Icon(icon, size: iconSize), 
        ],
      ),
    );
  }
}