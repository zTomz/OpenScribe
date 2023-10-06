import 'package:openscribe/models/document.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final documentProvider =
    StateNotifierProvider<DocumentNotifier, List<Document>>(
  (ref) => DocumentNotifier(),
);

final currentDocumentProvider = StateProvider<Document>(
  (ref) => ref.read(documentProvider.notifier).getFirstDocument(),
);

final zoomProvider = StateProvider<double>((ref) => 100.0);

const double windowTitleBarHeight = 40.0;

class MemoryLocations {
  static const String documentsFromOlderSessions = "documentsFromOlderSessions";
  static const String primaryAppColor = "primaryAppColor";
  static const String fontFamily = "fontFamily";

  static const String documentsCacheLocation = "OpenScribe/Cache Documents/";
  static String? applicationDocumentsDirectory;
}
