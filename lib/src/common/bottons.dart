import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton(
      {super.key, required this.color, required this.text, this.textColor});
  final Color color;
  final String text;
  final Color? textColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          onPressed: () {},
          icon: const Icon(
            Icons.album_outlined,
            color: Colors.white,
          ),
          label: Text(text,
              style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontFamily: "Montserrat",
                  letterSpacing: -1,
                  fontWeight: FontWeight.bold)),
        ));
  }
}

class CustomButton extends StatelessWidget {
  const CustomButton(
      {super.key, required this.color, required this.text, this.textColor});
  final Color color;
  final String text;
  final Color? textColor;
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          onPressed: () {},
          child: Text(text,
              style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontFamily: "Montserrat",
                  letterSpacing: -1,
                  fontWeight: FontWeight.bold)),
        ));
  }
}
