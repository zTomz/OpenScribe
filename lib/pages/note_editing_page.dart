import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NoteEditingPage extends HookConsumerWidget {
  const NoteEditingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Document note = ref.watch(currentNoteProvider);

    final titleController = useTextEditingController();
    final noteController = useTextEditingController();

    titleController.text = note.title
        .replaceAll(
          ".edoc",
          "",
        )
        .replaceAll(
          ".txt",
          "",
        );
    noteController.text = note.text;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            () async {
          try {
            ref.read(noteProvider.notifier).changeText(
                  noteController.text,
                  note.uuid,
                );
            await ref.read(noteProvider.notifier).save(note.uuid);
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
        }
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: titleController,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) {
                            try {
                              ref
                                  .read(noteProvider.notifier)
                                  .changeTitle(value, note.uuid);

                              // Else it will reset the content of note to empty, but in production it works (where no hot reload takes place)
                              if (kDebugMode) {
                                ref.read(currentNoteProvider.notifier).state =
                                    ref
                                        .read(noteProvider.notifier)
                                        .getDocumentWithUuid(note.uuid);
                              }
                            } catch (error) {
                              ScaffoldMessenger.of(context).clearSnackBars();
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
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          ref.read(noteProvider.notifier).createNew();
                        },
                        icon: SvgPicture.asset("assets/icons/document.svg"),
                        tooltip: "New file",
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          try {
                            ref.read(noteProvider.notifier).changeText(
                                  noteController.text,
                                  note.uuid,
                                );
                            await ref.read(noteProvider.notifier).save(
                                  note.uuid,
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
                        icon: SvgPicture.asset("assets/icons/disk.svg"),
                        tooltip: "Save",
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () async {
                          try {
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
                                  error.toString(),
                                ),
                              ),
                            );
                          }
                        },
                        icon: SvgPicture.asset("assets/icons/folder.svg"),
                        tooltip: "Open",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    maxLines: null,
                    controller: noteController,
                    onChanged: (value) {
                      ref.read(noteProvider.notifier).changeText(
                            value,
                            note.uuid,
                          );
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your text here",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
