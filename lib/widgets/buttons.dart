import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({
    required this.text,
    required this.onPressed,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textStyle: GoogleFonts.roboto(
        fontSize: 19.0,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onPrimary,
        letterSpacing: 0.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      minimumSize: Size(size.width * 0.8, 50.0),
      maximumSize: Size(size.width * 0.9, 50.0),
      iconAlignment: IconAlignment.start,
      elevation: 3.0,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20.0),
        label: Text(text),
      );
    }

    return ElevatedButton(
      style: style,
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class DeactivatedButton extends StatelessWidget {
  final String text;
  final IconData? icon;

  const DeactivatedButton({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(
        fontSize: 19.0,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        letterSpacing: 0.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      minimumSize: Size(size.width * 0.8, 50.0),
      maximumSize: Size(size.width * 0.9, 50.0),
      iconAlignment: IconAlignment.start,
      elevation: 3.0,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        onPressed: null,
        icon: Icon(icon, color: Colors.black, size: 20.0),
        label: Text(text),
      );
    }

    return ElevatedButton(style: style, onPressed: null, child: Text(text));
  }
}

class TertiaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const TertiaryButton({
    required this.text,
    required this.onPressed,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(
        fontSize: 19.0,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        letterSpacing: 0.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      minimumSize: Size(size.width * 0.8, 50.0),
      maximumSize: Size(size.width * 0.9, 50.0),
      iconAlignment: IconAlignment.start,
      elevation: 3.0,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black, size: 20.0),
        label: Text(text),
      );
    }

    return ElevatedButton(
      style: style,
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class DisabledButton extends StatelessWidget {
  final String text;
  final IconData? icon;

  const DisabledButton({required this.text, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ButtonStyle style = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(
        fontSize: 19.0,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        letterSpacing: 0.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      minimumSize: Size(size.width * 0.8, 50.0),
      maximumSize: Size(size.width * 0.9, 50.0),
      iconAlignment: IconAlignment.start,
      elevation: 3.0,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        icon: Icon(icon, color: Colors.black, size: 20.0),
        onPressed: null,
        label: Text(text),
      );
    }

    return ElevatedButton(style: style, onPressed: null, child: Text(text));
  }
}
