import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:openscribe/pages/note_editing_page.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainScreen({
    super.key,
    required this.child,
  });

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
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(left: 10.0, top: 5),
                        child: InkWell(
                          onTap: () {
                            ref.read(currentNoteProvider.notifier).state =
                                documents[index];
                          },
                          hoverColor: MyColors.grey.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Container(
                            height: 35,
                            width: tabSize,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              border: Border.all(
                                width: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    documents[index].title ?? "Unknown",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    // Remove document
                                    if (documents.length <= 1) {
                                      return;
                                    }

                                    final document = documents[index];

                                    if (document.isEmpty) {
                                      ref.read(noteProvider.notifier).remove(
                                            document.uuid,
                                          );

                                      if (ref
                                              .read(
                                                  currentNoteProvider.notifier)
                                              .state
                                              .uuid ==
                                          document.uuid) {
                                        ref
                                                .read(currentNoteProvider.notifier)
                                                .state =
                                            ref
                                                .read(noteProvider.notifier)
                                                .getFirstDocument();
                                      }
                                    }
                                  },
                                  // TODO: Add a confirmation dialog
                                  onLongPress: () =>
                                      ref.read(noteProvider.notifier).remove(
                                            documents[index].uuid,
                                          ),
                                  hoverColor: MyColors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(180),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
