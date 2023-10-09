import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/models/document.dart';
import 'package:openscribe/utils/provider.dart';

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

    final currentDocument = ref.watch(currentDocumentProvider);

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
                  (document.title ?? LocalKeys.unknown.tr())
                      .replaceAll(
                        ".edoc",
                        "",
                      )
                      .replaceAll(
                        ".txt",
                        "",
                      ),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: document.uuid == currentDocument.uuid
                          ? colorScheme.primary
                          : colorScheme.onBackground),
                ),
              ),
              InkWell(
                onTap: () {
                  // Remove document
                  if (documents.length <= 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          LocalKeys.thisIsTheLastDocument.tr(),
                        ),
                      ),
                    );
                    return;
                  }

                  if (document.isEmpty) {
                    ref.read(documentProvider.notifier).remove(
                          document.uuid,
                        );

                    if (currentDocument.uuid == document.uuid) {
                      ref.read(currentDocumentProvider.notifier).state = ref
                          .read(documentProvider.notifier)
                          .getFirstDocument();
                    }
                  } else {
                    // Show dialog if user want to save or delete document
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          "${LocalKeys.warning.tr()}?",
                        ),
                        content: Text(
                          "${LocalKeys.doYouWantToDeleteThisDocument.tr()}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              LocalKeys.cancel.tr(),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(documentProvider.notifier).remove(
                                    document.uuid,
                                  );
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              LocalKeys.delete.tr(),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(documentProvider.notifier).save(
                                    document,
                                  );

                              Navigator.pop(context);
                            },
                            child: Text(
                              LocalKeys.save.tr(),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (currentDocument.uuid == document.uuid) {
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
