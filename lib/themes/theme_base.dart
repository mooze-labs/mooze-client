import 'package:flutter/material.dart';

final ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.pink,
  onPrimary: Colors.white,
  secondary: Colors.grey,
  onSecondary: Colors.black,
  tertiary: Colors.white,
  onTertiary: Colors.black,
  surface: Color(0xFF14181B),
  onSurface: Colors.white,
  error: Colors.red,
  onError: Colors.white,
);

final AppBarTheme appBarTheme = AppBarTheme(
  backgroundColor: Color(0xFF14181B),
  centerTitle: true,
  titleTextStyle: TextStyle(
    fontSize: 22,
    fontFamily: "roboto",
    fontWeight: FontWeight.bold,
  ),
  iconTheme: IconThemeData(color: Colors.white),
);

final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.pink),
  ),
  filled: true,
  fillColor: Color(0xFF1E1E1E),
  hintStyle: TextStyle(color: Colors.grey.shade500),
);

final BottomNavigationBarThemeData bottomNavigationBarTheme =
    BottomNavigationBarThemeData(
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.white,
      backgroundColor: Color(0XFF14181B),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );

final ThemeData themeData = ThemeData(
  colorScheme: colorScheme,
  appBarTheme: appBarTheme,
  bottomNavigationBarTheme: bottomNavigationBarTheme,
  inputDecorationTheme: inputDecorationTheme,
  fontFamily: "roboto",
);
