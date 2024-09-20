import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;
  final IconAlignment? iconAlignment;
  final String size; 

  const OutlineButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = AppStyles.primaryForeground,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.size = 'normal'
  }) : super(key: key); 


  @override
  Widget build(BuildContext context) {
    double fontSize = 14;
    double iconSize = 16; 
    double hPadding = 15.0;
    double vPadding = 2;

    if (size=='small') {
      fontSize = 13;
      iconSize = 15;  
      hPadding = 12;
      vPadding = 8;
    } else if (size == 'large') {
      fontSize = 20;
      iconSize = 22;  
      hPadding = 16;
      vPadding = 5;
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.0), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), 
        ),
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding), 
        minimumSize: Size(0,0),
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