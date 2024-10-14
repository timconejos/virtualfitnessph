import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';
// Reusable button component
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = AppStyles.primaryColor,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(0,0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(text, style: AppStyles.vifitTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}