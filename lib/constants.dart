import 'package:openscribe/models/document.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyColors {
  static const Color black = Color(0xFF2d2e37);
  static const Color grey = Color(0xFFc4c4c4);
  static const Color blue = Color(0xFF3c3abe);
  static const Color white = Color(0xFFcfcfff);
  static const Color green = Color(0xFFA9E5BB);
  static const Color red = Color(0xFFF9544E);
}

final noteProvider = StateNotifierProvider<DocumentNotifier, List<Document>>(
  (ref) => DocumentNotifier(),
);

final currentNoteProvider = StateProvider<Document>(
  (ref) => ref.read(noteProvider.notifier).getFirstDocument(),
);
