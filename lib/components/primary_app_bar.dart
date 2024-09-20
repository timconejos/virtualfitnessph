import 'package:flutter/material.dart';
import 'package:virtualfitnessph/styles/app_styles.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget{ 
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;

  PrimaryAppBar({
    required this.title,
    this.backgroundColor = AppStyles.primaryColor, // Default color if not provided
    this.actions,
    this.centerTitle = false, // Default to center the title
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppStyles.primaryForeground), // Default text style
      ),
      backgroundColor: backgroundColor,
      foregroundColor: AppStyles.primaryForeground,
      actions: actions,
      centerTitle: centerTitle, // Center the title by default
      leading: leading, // Optionally set the leading widget  
      // flexibleSpace: Container(
      //   alignment: Alignment.centerLeft, 
      //   padding: EdgeInsets.only(top: 20.0), 
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [AppStyles.primaryColor, AppStyles.primaryForeground],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
      // ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}