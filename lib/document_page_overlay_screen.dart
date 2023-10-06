import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:openscribe/pages/document_editing_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/utils/font.dart';
import 'package:openscribe/utils/provider.dart';
import 'package:openscribe/utils/settings.dart';
import 'package:openscribe/widgets/documents_tab.dart';
import 'package:openscribe/widgets/window_button_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class DocumentPageOverlayScreen extends ConsumerStatefulWidget {
  const DocumentPageOverlayScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DocumentPageOverlayScreenState();
}

class _DocumentPageOverlayScreenState
    extends ConsumerState<DocumentPageOverlayScreen> with WindowListener {
  @override
  void initState() {
    super.initState();

    initialize(context);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<Document> documents = ref.watch(documentProvider);
    final windowSize = MediaQuery.of(context).size;
    final double tabSize = min(
      175,
      max(
        82,
        windowSize.width * 0.7 / documents.length - 10,
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          SizedBox(
            height: windowTitleBarHeight,
            child: Row(
              children: [
                const SizedBox(width: 10),
                SizedBox(
                  width: 25,
                  height: 25,
                  child: Image.asset("assets/icons/app_icon.ico"),
                ),
                SizedBox(
                  width: min(
                    windowSize.width * 0.7,
                    documents.length * (tabSize + 10),
                  ),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.invertedStylus,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.unknown,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: ListView.builder(
                      itemCount: documents.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => DocumentTab(
                        document: documents[index],
                        documents: documents,
                        tabSize: tabSize,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: WindowCaption(
                    backgroundColor: colorScheme.background,
                    brightness: colorScheme.brightness,
                  ),
                ),
              ],
            ),
          ),
          const WindowButtonBar(),
          const Expanded(
            child: DocumentEditingPage(),
          ),
        ],
      ),
    );
  }

  Future<void> initialize(BuildContext context) async {
    await ref.read(settingsProvider.notifier).load(); // If it is already loaded, it doesnt load again

    final settings = ref.read(settingsProvider.notifier).getSettings;

    if (settings.font == null || settings.font == "Default") {
      return;
    }

    // ignore: use_build_context_synchronously
    changeFontFamily(
      context,
      settings.font!,
    );
  }

  @override
  void onWindowClose() async {
    final settings = ref.read(settingsProvider.notifier).getSettings;

    if (settings.whenEditorLaunched ==
        WhenEditorLaunched.documentsFromOlderSession) {
      // Clear shared preferences
      final instance = await SharedPreferences.getInstance();
      await instance.setStringList(
        MemoryLocations.documentsFromOlderSessions,
        [],
      );

      // Save not saved documents
      final documents =
          ref.read(documentProvider.notifier).getDocuments().where(
                (element) => element.isNotEmpty,
              );

      for (final Document document in documents) {
        await ref
            .read(documentProvider.notifier)
            .saveToDocumentsCache(document);
      }

      final result = await instance.setStringList(
        MemoryLocations.documentsFromOlderSessions,
        documents.map((e) => e.uuid).toList(),
      );

      debugPrint(
        "Saved documents to cache: $result - ${documents.map((e) => e.uuid).toList()}",
      );

      // Save all saved documents
      await ref.read(documentProvider.notifier).saveAll();

      // Save settings
      await ref.read(settingsProvider.notifier).save();

      // Exit
      if (canCloseWindow) {
        super.onWindowClose();
        exit(0);
      }
    } else {
      final documents = ref.read(documentProvider.notifier).getDocuments();

      bool dialogGotShown = false;
      int index = 0;

      for (final document in documents) {
        dialogGotShown = true;

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Warning"),
            content: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(text: "The docuement "),
                  TextSpan(
                    text: document.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: " is not saved.")
                ],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await ref.read(documentProvider.notifier).save(document);
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();

                  if (index == documents.length - 1) {
                    await ref.read(settingsProvider.notifier).save();
                    if (canCloseWindow) {
                      super.onWindowClose();
                      exit(0);
                    }
                  }
                },
                child: const Text("Save"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  if (index == documents.length - 1) {
                    await ref.read(settingsProvider.notifier).save();
                    if (canCloseWindow) {
                      super.onWindowClose();
                      exit(0);
                    }
                  }
                },
                child: const Text("Don't save"),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(documentProvider.notifier).saveAll();

                  // Just close the window and save settings
                  await ref.read(settingsProvider.notifier).save();
                  if (canCloseWindow) {
                    super.onWindowClose();
                    exit(0);
                  }
                },
                child: const Text("Quit"),
              ),
            ],
          ),
        );

        index += 1;
      }

      if (!dialogGotShown) {
        await ref.read(documentProvider.notifier).saveAll();
        await ref.read(settingsProvider.notifier).save();
        if (canCloseWindow) {
          super.onWindowClose();
          exit(0);
        }
      }
    }
  }
}
