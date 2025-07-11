import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

final ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.pink,
  onPrimary: Colors.white,
  secondary: Colors.grey.shade900,
  onSecondary: Colors.white60,
  tertiary: Colors.white,
  onTertiary: Colors.black,
  surface: Color.fromARGB(255, 15, 15, 15),
  onSurface: Colors.white,
  error: Colors.red,
  onError: Colors.white,
);

final AppBarTheme appBarTheme = AppBarTheme(
  backgroundColor: Color.fromARGB(255, 15, 15, 15),
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
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
  ),
  filled: true,
  fillColor: colorScheme.secondary,
  hintStyle: TextStyle(color: Colors.grey.shade500),
);

final BottomNavigationBarThemeData bottomNavigationBarTheme =
    BottomNavigationBarThemeData(
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.white,
      backgroundColor: Color.fromARGB(255, 15, 15, 15),
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );

final DropdownMenuThemeData dropdownMenuTheme = DropdownMenuThemeData(
  menuStyle: MenuStyle(
    backgroundColor: WidgetStateProperty.all(Colors.grey.shade900),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.transparent),
      ),
    ),
  ),
  inputDecorationTheme: inputDecorationTheme,
);

final PinTheme pinTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: TextStyle(
    fontSize: 20,
    color: colorScheme.onSecondary,
    fontFamily: "roboto",
  ),
  decoration: BoxDecoration(
    border: Border.all(color: colorScheme.primary),
    borderRadius: BorderRadius.circular(8),
  ),
);


const double buttonTextSize = 18.0;
final ElevatedButtonThemeData elevatedButtonThemeData = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    textStyle: TextStyle(
      fontSize: buttonTextSize,
      fontWeight: FontWeight.w500,
      fontFamily: "Inter",
      color: colorScheme.onPrimary,
      letterSpacing: 0.0,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

final ThemeData themeData = ThemeData(
  colorScheme: colorScheme,
  appBarTheme: appBarTheme,
  bottomNavigationBarTheme: bottomNavigationBarTheme,
  inputDecorationTheme: inputDecorationTheme,
  dropdownMenuTheme: dropdownMenuTheme,
  elevatedButtonTheme: elevatedButtonThemeData,
  fontFamily: "Inter",
);
