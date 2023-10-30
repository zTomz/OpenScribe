import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/document_page_overlay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/utils/provider.dart';
import 'package:openscribe/utils/settings.dart';
import 'package:openscribe/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  MemoryLocations.applicationDocumentsDirectory =
      (await getApplicationDocumentsDirectory()).path;

  AdaptiveThemeMode? savedThemeMode = await AdaptiveTheme.getThemeMode();
  final Color? primaryColor = await loadPrimaryColor();

  await initWindow();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('de'),
          Locale('fr'),
          Locale('es'),
          Locale('it'),
          Locale('ru'),
          Locale('pt'),
          Locale("uk"),
          Locale("zh"),
          Locale("ja"),
          Locale("ko"),
          Locale("ar"),
          Locale("tr"),
        ],
        path: 'assets/langs',
        fallbackLocale: const Locale("en"),
        child: MyApp(
          savedThemeMode: savedThemeMode,
          primaryColor: primaryColor,
        ),
      ),
    ),
  );
}

Future<void> initWindow() async {
  // Nothing to init
  if (!Utils.isDesktop) {
    return;
  }

  await windowManager.ensureInitialized();
  await Window.initialize();

  await Window.setEffect(effect: WindowEffect.transparent);

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(530, 285),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });
}

class MyApp extends ConsumerStatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final Color? primaryColor;

  const MyApp({
    super.key,
    this.savedThemeMode,
    this.primaryColor,
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    loadOlderSessions();

    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        // brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: widget.primaryColor ?? Colors.orange,
        ),
      ),
      dark: ThemeData(
        useMaterial3: true,
        // brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: widget.primaryColor ?? Colors.orange,
        ),
      ),
      // debugShowFloatingThemeButton: true,
      initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (theme, darkTheme) {
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          builder: (context, child) {
            // Normal screen for Android and iOS
            if (!Utils.isDesktop) {
              return child!;
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: DragToResizeArea(
                enableResizeEdges: const [
                  ResizeEdge.topLeft,
                  ResizeEdge.top,
                  ResizeEdge.topRight,
                  ResizeEdge.left,
                  ResizeEdge.right,
                  ResizeEdge.bottomLeft,
                  ResizeEdge.bottomLeft,
                  ResizeEdge.bottomRight,
                ],
                child: child!,
              ),
            );
          },
          title: 'Open Scribe',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          home: const DocumentPageOverlayScreen(),
        );
      },
    );
  }

  Future<void> loadOlderSessions() async {
    await ref.read(settingsProvider.notifier).load();
    final settings = ref.read(settingsProvider.notifier).getSettings;

    if (settings.whenEditorLaunched == WhenEditorLaunched.newSession) {
      return;
    } else {
      final sharedPreferences = await SharedPreferences.getInstance();
      final documentsUuids = sharedPreferences.getStringList(
        MemoryLocations.documentsFromOlderSessions,
      );

      debugPrint("Old uuid's of documents: $documentsUuids");

      // No saved documents from older sessions
      if (documentsUuids == null || documentsUuids.isEmpty) {
        return;
      }

      final directory = Directory(
        "${MemoryLocations.applicationDocumentsDirectory}\\${MemoryLocations.documentsCacheLocation}",
      );

      // Folder got deleted
      if (!directory.existsSync() || directory.listSync().isEmpty) {
        await _cleanDocumentsSharedPreferences();
        return;
      }

      ref.read(documentProvider.notifier).clear();

      for (final uuid in documentsUuids) {
        try {
          await ref.read(documentProvider.notifier).loadDocumentFromCache(
                uuid,
                removeOldDocument: true,
              );
        } catch (error) {
          debugPrint("Error loading document:\n$error");

          ref.read(documentProvider.notifier).deleteCachedDocuments();

          await _cleanDocumentsSharedPreferences();

          ref.read(documentProvider.notifier).createNew();
          return;
        }
      }

      await _cleanDocumentsSharedPreferences();

      // Set current document to first document
      ref.read(currentDocumentProvider.notifier).state =
          ref.read(documentProvider.notifier).getFirstDocument();
    }
  }

  Future<void> _cleanDocumentsSharedPreferences() async {
    final instance = await SharedPreferences.getInstance();
    await instance.setStringList(
      MemoryLocations.documentsFromOlderSessions,
      [],
    );
  }
}

Future<Color?> loadPrimaryColor() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final primaryColor = sharedPreferences.getString(
    MemoryLocations.primaryAppColor,
  );

  if (primaryColor == null) {
    return null;
  }

  return Color(int.parse(primaryColor));
}
