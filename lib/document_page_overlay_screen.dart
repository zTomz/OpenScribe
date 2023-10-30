import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:openscribe/pages/document_editing_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/pages/settings_page.dart';
import 'package:openscribe/utils/font.dart';
import 'package:openscribe/utils/provider.dart';
import 'package:openscribe/utils/settings.dart';
import 'package:openscribe/utils/utils.dart';
import 'package:openscribe/widgets/documents_tab.dart';
import 'package:openscribe/widgets/window_button_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class DocumentPageOverlayScreen extends StatefulHookConsumerWidget {
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

    final zoom = ref.watch(zoomProvider);
    final documentIndex = useState(0);

    List<Document> documents = ref.watch(documentProvider);
    final windowSize = MediaQuery.of(context).size;
    final double tabSize = min(
      175,
      max(
        82,
        windowSize.width * 0.7 / documents.length - 10,
      ),
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): () {
          // Create a new document and asign it to currentDocumentProvider
          ref.read(currentDocumentProvider.notifier).state =
              ref.read(documentProvider.notifier).createNew();
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
            () async {
          try {
            ref.read(currentDocumentProvider.notifier).state =
                await ref.read(documentProvider.notifier).openDocument();
          } catch (error) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).clearSnackBars();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  error.toString(),
                ),
              ),
            );
          }
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            () async {
          try {
            ref.read(currentDocumentProvider.notifier).state =
                await ref.read(documentProvider.notifier).save(
                      ref.read(currentDocumentProvider.notifier).state,
                    );
          } catch (error) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).clearSnackBars();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  error.toString(),
                ),
              ),
            );
          }
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyS): () async {
          try {
            ref.read(currentDocumentProvider.notifier).state = await ref
                .read(documentProvider.notifier)
                .saveAs(ref.read(currentDocumentProvider.notifier).state);
          } catch (error) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).clearSnackBars();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  error.toString(),
                ),
              ),
            );
          }
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal):
            () {
          ref.read(zoomProvider.notifier).state += 5;
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus):
            () {
          if (zoom >= 10) {
            ref.read(zoomProvider.notifier).state -= 5;
          }
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0):
            () {
          ref.read(zoomProvider.notifier).state = 100;
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.tab): () {
          if (documentIndex.value >=
              ref.read(documentProvider.notifier).getDocuments().length) {
            documentIndex.value = 0;
          }

          ref.read(currentDocumentProvider.notifier).state = ref
              .read(documentProvider.notifier)
              .getDocuments()[documentIndex.value];
          documentIndex.value += 1;
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.delete):
            () {
          final currentDocument = ref.read(currentDocumentProvider);
          ref.read(documentProvider.notifier).removeDocumentWithDialog(
                currentDocument,
                currentDocument,
                context,
                ref,
              );
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): () {
          onWindowClose();
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma):
            () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          );
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
            () async {
          final currentDocument = ref.read(currentDocumentProvider);
          await Utils.displayPrintingDialog(
            currentDocument.title,
            currentDocument.text,
            context,
          );
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: SafeArea(
          child: Column(
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
                    if (Utils.isDesktop)
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
                      )
                    else
                      Expanded(
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
                    if (Utils.isDesktop)
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
        ),
      ),
    );
  }

  Future<void> initialize(BuildContext context) async {
    await ref
        .read(settingsProvider.notifier)
        .load(); // If it is already loaded, it doesnt load again

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
            title: Text(LocalKeys.warning.tr()),
            content: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "${LocalKeys.theDocument.tr()} "),
                  TextSpan(
                    text: document.title ?? LocalKeys.unknown.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: " ${LocalKeys.isNotSaved.tr()}.")
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
                child: Text(LocalKeys.save.tr()),
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
                child: Text(LocalKeys.dontSave.tr()),
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
                child: Text(LocalKeys.quit.tr()),
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
