import 'package:openscribe/models/document.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final documentProvider = StateNotifierProvider<DocumentNotifier, List<Document>>(
  (ref) => DocumentNotifier(),
);

final currentDocumentProvider = StateProvider<Document>(
  (ref) => ref.read(documentProvider.notifier).getFirstDocument(),
);

const double windowTitleBarHeight = 40.0;