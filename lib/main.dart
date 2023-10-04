import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/document_page_overlay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await Window.initialize();

  await Window.setEffect(effect: WindowEffect.transparent);

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(530, 270),
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

  AdaptiveThemeMode? savedThemeMode = await AdaptiveTheme.getThemeMode();

  final Color? primaryColor = await loadPrimaryColor();

  runApp(
    ProviderScope(
      child: MyApp(
        savedThemeMode: savedThemeMode,
        primaryColor: primaryColor,
      ),
    ),
  );
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
        colorScheme: ColorScheme.light(
          primary: widget.primaryColor ?? Colors.orange,
        ),
      ),
      dark: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: widget.primaryColor ?? Colors.orange,
        ),
      ),
      // debugShowFloatingThemeButton: true,
      initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (theme, darkTheme) {
        return MaterialApp(
          builder: (context, child) {
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
    final sharedPreferences = await SharedPreferences.getInstance();
    final documentsUuids = sharedPreferences.getStringList(
      MemoryLocations.documentsFromOlderSessions,
    );

    debugPrint("Old uuid's of documents: $documentsUuids");

    // No saved documents from older sessions
    if (documentsUuids == null || documentsUuids.isEmpty) {
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

        final instance = await SharedPreferences.getInstance();
        await instance.setStringList(
          MemoryLocations.documentsFromOlderSessions,
          [],
        );

        ref.read(documentProvider.notifier).createNew();
        return;
      }
    }

    // Clear shared preferences
    final instance = await SharedPreferences.getInstance();
    await instance.setStringList(
      MemoryLocations.documentsFromOlderSessions,
      [],
    );

    // Set current document to first document
    ref.read(currentDocumentProvider.notifier).state =
        ref.read(documentProvider.notifier).getFirstDocument();
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
