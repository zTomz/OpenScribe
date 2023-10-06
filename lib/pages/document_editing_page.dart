import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DocumentEditingPage extends HookConsumerWidget {
  const DocumentEditingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final zoom = ref.watch(zoomProvider); // Normal zoom

    Document document = ref.watch(currentDocumentProvider);

    final titleController = useTextEditingController();
    final textController = useTextEditingController();

    if (document.title != titleController.text) {
      titleController.text = (document.title ?? "Unknown")
          .replaceAll(
            ".edoc",
            "",
          )
          .replaceAll(
            ".txt",
            "",
          );
    }
    if (document.text != textController.text) {
      textController.text = document.text;
    }

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
            ref.read(documentProvider.notifier).changeText(
                  textController.text,
                  document.uuid,
                );

            ref.read(currentDocumentProvider.notifier).state =
                await ref.read(documentProvider.notifier).save(document);
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
            ref.read(documentProvider.notifier).changeText(
                  textController.text,
                  document.uuid,
                );
            ref.read(currentDocumentProvider.notifier).state =
                await ref.read(documentProvider.notifier).saveAs(document);
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
                            .read(documentProvider.notifier)
                            .changeTitle(value, document.uuid);

                        ref.read(currentDocumentProvider.notifier).state = ref
                            .read(documentProvider.notifier)
                            .getDocumentWithUuid(document.uuid);
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
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      suffix: Container(
                        width: 25,
                        height: 25,
                        margin: const EdgeInsets.only(right: 2.5),
                        child: Tooltip(
                          message: """
Disk location: ${document.diskLocation ?? "Not saved"}""",
                          child: InkWell(
                            onTap: () {},
                            hoverColor: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(5),
                            child: Icon(
                              Icons.info_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    maxLines: null,
                    controller: textController,
                    onChanged: (value) {
                      ref.read(currentDocumentProvider.notifier).state =
                          document.copyWith(
                        text: textController.text,
                      );
                      ref.read(documentProvider.notifier).changeText(
                            textController.text,
                            document.uuid,
                          );
                    },
                    style: TextStyle(
                      fontSize: 16 *
                          (zoom / 100), // The zoom only controls the font size
                    ),
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
