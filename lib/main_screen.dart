import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:openscribe/pages/note_editing_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/widgets/documents_tab.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WindowListener {
  @override
  void initState() {
    super.initState();

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

    List<Document> documents = ref.watch(noteProvider);
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
            height: 40,
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
          Container(
            height: 20,
            margin: const EdgeInsets.only(left: 5, top: 5),
            child: Row(
              children: [
                MenuAnchor(
                  builder: (context, controller, child) => TextButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text("File"),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () {
                        ref.read(currentNoteProvider.notifier).state =
                            ref.read(noteProvider.notifier).createNew();
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/document.svg",
                            color: colorScheme.primary,
                            width: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "New Document",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MenuItemButton(
                      onPressed: () async {
                        try {
                          final currentNote =
                              ref.read(currentNoteProvider.notifier).state;

                          ref.read(noteProvider.notifier).changeText(
                                currentNote.text,
                                currentNote.uuid,
                              );
                          await ref
                              .read(noteProvider.notifier)
                              .save(currentNote);

                          ref.read(currentNoteProvider.notifier).state = ref
                              .read(noteProvider.notifier)
                              .getDocumentWithUuid(currentNote.uuid);
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
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/disk.svg",
                            color: colorScheme.primary,
                            width: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Save Document",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MenuItemButton(
                      onPressed: () async {
                        try {
                          ref.read(currentNoteProvider.notifier).state =
                              await ref
                                  .read(noteProvider.notifier)
                                  .loadDocument();
                        } catch (error) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).clearSnackBars();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                error as String,
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            "assets/icons/folder.svg",
                            color: colorScheme.primary,
                            width: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Load Document",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: NoteEditingPage(),
          ),
        ],
      ),
    );
  }

  @override
  void onWindowClose() async {
    final documents = ref
        .read(noteProvider.notifier)
        .getDocuments()
        .where((element) => element.isNotSaved);

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
                await ref.read(noteProvider.notifier).save(document);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();

                if (index == documents.length - 1) {
                  super.onWindowClose();
                  exit(0);
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                if (index == documents.length - 1) {
                  super.onWindowClose();
                  exit(0);
                }
              },
              child: const Text("Don't save"),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(noteProvider.notifier).saveAll();

                // Just close the window
                super.onWindowClose();
                exit(0);
              },
              child: const Text("Quit"),
            ),
          ],
        ),
      );

      index += 1;
    }

    if (!dialogGotShown) {
      await ref.read(noteProvider.notifier).saveAll();
      super.onWindowClose();
      exit(0);
    }
  }
}
