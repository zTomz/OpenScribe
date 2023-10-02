import 'package:openscribe/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/pages/note_editing_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: MyColors.blue),
      ),
      home: const MainScreen(child: NoteEditingPage()),
    );
  }
}
