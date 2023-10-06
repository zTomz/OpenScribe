import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/models/document.dart';
import 'package:openscribe/utils/settings.dart';

final documentProvider =
    StateNotifierProvider<DocumentNotifier, List<Document>>(
  (ref) => DocumentNotifier(),
);

final currentDocumentProvider = StateProvider<Document>(
  (ref) => ref.read(documentProvider.notifier).getFirstDocument(),
);

final zoomProvider = StateProvider<double>((ref) => 100.0);

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>(
  (ref) => SettingsNotifier(),
);
