import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Future<void> showCustomFlushbar(
  BuildContext context,
  String title,
  String message,
  IconData icon, {
  Color? color = const Color(0xFFEF5350),
}) async {
  Flushbar(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(16),
    backgroundColor: color!,
    titleText: Text(
      title,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    messageText: Text(message, style: TextStyle(color: Colors.white)),
    icon: Icon(icon, color: Colors.white),
    duration: Duration(seconds: 3),
  ).show(context);
}
