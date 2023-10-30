import 'package:easy_localization/easy_localization.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/utils/provider.dart';

class DocumentEditingPage extends HookConsumerWidget {
  const DocumentEditingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final zoom = ref.watch(zoomProvider);

    Document document = ref.watch(currentDocumentProvider);

    final titleController = useTextEditingController();
    final textController = useTextEditingController();

    if (document.title != titleController.text) {
      titleController.text = (document.title ?? LocalKeys.unknown.tr())
          .replaceAll(
            ".odoc",
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: titleController,
                    style: TextStyle(
                      fontSize: 25,
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (value) {
                      try {
                        ref.read(currentDocumentProvider.notifier).state = ref
                            .read(documentProvider.notifier)
                            .changeTitle(value, document.uuid);
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
                    decoration: const InputDecoration.collapsed(
                      border: InputBorder.none,
                      hintText: "Title",
                    ),
                  ),
                ),
                ExcludeFocus(
                  child: Container(
                    width: 25,
                    height: 25,
                    margin: const EdgeInsets.only(right: 2.5),
                    child: Tooltip(
                      message: """
${LocalKeys.diskLocation.tr()}: ${document.diskLocation ?? LocalKeys.notSaved.tr()}
${LocalKeys.lastSaved.tr()}: ${document.formatDateTime(document.lastSaved) ?? LocalKeys.notSaved.tr()}
${LocalKeys.lastModified.tr()}: ${document.formatDateTime(document.lastModified) ?? LocalKeys.notModified.tr()}""",
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
              ],
            ),
            Expanded(
              child: TextField(
                controller: textController,
                onChanged: (value) {
                  ref.read(currentDocumentProvider.notifier).state =
                      ref.read(documentProvider.notifier).changeText(
                            textController.text,
                            document.uuid,
                          );
                },
                maxLines: null,
                style: TextStyle(
                  fontSize:
                      16 * (zoom / 100), // The zoom only controls the font size
                  color: colorScheme.onBackground,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: LocalKeys.enterYourTextHere.tr(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
