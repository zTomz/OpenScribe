import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';

class DocumentTab extends ConsumerWidget {
  final Document document;
  final List<Document> documents;
  final double tabSize;

  const DocumentTab({
    super.key,
    required this.document,
    required this.documents,
    required this.tabSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 5),
      child: InkWell(
        onTap: () {
          ref.read(currentDocumentProvider.notifier).state = document;
        },
        hoverColor: Colors.grey.withOpacity(0.075),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15),
        ),
        child: Container(
          height: 35,
          width: tabSize,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                  (document.title ?? "Unknown")
                      .replaceAll(
                        ".edoc",
                        "",
                      )
                      .replaceAll(
                        ".txt",
                        "",
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  // Remove document
                  if (documents.length <= 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          "This is the last document.",
                        ),
                      ),
                    );
                    return;
                  }

                  if (document.isEmpty) {
                    ref.read(documentProvider.notifier).remove(
                          document.uuid,
                        );

                    if (ref.read(currentDocumentProvider.notifier).state.uuid ==
                        document.uuid) {
                      ref.read(currentDocumentProvider.notifier).state = ref
                          .read(documentProvider.notifier)
                          .getFirstDocument();
                    }
                  } else {
                    ref.read(documentProvider.notifier).save(document);
                    ref.read(documentProvider.notifier).remove(document.uuid);

                    if (ref.read(currentDocumentProvider.notifier).state.uuid ==
                        document.uuid) {
                      ref.read(currentDocumentProvider.notifier).state = ref
                          .read(documentProvider.notifier)
                          .getFirstDocument();
                    }
                  }
                },
                hoverColor: Colors.grey.withOpacity(0.3),
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
    );
  }
}
