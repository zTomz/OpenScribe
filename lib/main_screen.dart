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
                                color: MyColors.grey,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    documents[index].title,
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
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: MyColors.grey,
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
                const Expanded(
                  child: WindowCaption(),
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
  void onWindowClose() {
    ref.read(noteProvider.notifier).saveAll();

    super.onWindowClose();
  }
}
