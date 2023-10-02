import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NoteEditingPage extends HookConsumerWidget {
  const NoteEditingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Document note = ref.watch(currentNoteProvider);

    final titleController = useTextEditingController();
    final noteController = useTextEditingController();

    titleController.text = (note.title ?? "Unknown")
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
            await ref.read(noteProvider.notifier).save(note);
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
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): () {
          // Create a new document and asign it to currentNoteProvider
          ref.read(currentNoteProvider.notifier).state =
              ref.read(noteProvider.notifier).createNew();
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL):
            () async {
          try {
            ref.read(currentNoteProvider.notifier).state =
                await ref.read(noteProvider.notifier).loadDocument();
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
          backgroundColor: colorScheme.background,
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SizedBox(
                  height: 35,
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
                          ref.read(currentNoteProvider.notifier).state = ref
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
                Expanded(
                  child: TextField(
                    maxLines: null,
                    controller: noteController,
                    onChanged: (value) {
                      ref.read(currentNoteProvider.notifier).state =
                          note.copyWith(
                        text: noteController.text,
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