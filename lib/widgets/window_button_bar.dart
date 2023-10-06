import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/pages/settings_page.dart';

class WindowButtonBar extends HookConsumerWidget {
  const WindowButtonBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 25,
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
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text("File"),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () {
                  ref.read(currentDocumentProvider.notifier).state =
                      ref.read(documentProvider.notifier).createNew();
                },
                child: const CustomMenuButton(
                  text: "New document",
                  shortcut: "Control + N",
                ),
              ),
              MenuItemButton(
                onPressed: () async {
                  try {
                    ref.read(currentDocumentProvider.notifier).state = await ref
                        .read(documentProvider.notifier)
                        .openDocument();
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
                child: const CustomMenuButton(
                  text: "Open",
                  shortcut: "Control + O",
                ),
              ),
              MenuItemButton(
                onPressed: () async {
                  try {
                    final currentDocument =
                        ref.read(currentDocumentProvider.notifier).state;

                    ref.read(documentProvider.notifier).changeText(
                          currentDocument.text,
                          currentDocument.uuid,
                        );
                    ref.read(currentDocumentProvider.notifier).state = await ref
                        .read(documentProvider.notifier)
                        .save(currentDocument);
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
                child: const CustomMenuButton(
                  text: "Save",
                  shortcut: "Control + S",
                ),
              ),
              MenuItemButton(
                onPressed: () async {
                  try {
                    final currentDocument =
                        ref.read(currentDocumentProvider.notifier).state;

                    ref.read(documentProvider.notifier).changeText(
                          currentDocument.text,
                          currentDocument.uuid,
                        );
                    ref.read(currentDocumentProvider.notifier).state = await ref
                        .read(documentProvider.notifier)
                        .saveAs(currentDocument);
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
                child: const CustomMenuButton(
                  text: "Save as",
                  shortcut: "Control + Shift + S",
                ),
              ),
            ],
          ),
          const SizedBox(width: 5),
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
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text("View"),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () {
                  ref.read(zoomProvider.notifier).state += 10;
                },
                child: const CustomMenuButton(
                  text: "Zoom in",
                  shortcut: "Control + Plus",
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  if (ref.read(zoomProvider.notifier).state >= 10) {
                    ref.read(zoomProvider.notifier).state -= 10;
                  }
                },
                child: const CustomMenuButton(
                  text: "Zoom out",
                  shortcut: "Control + Minus",
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  ref.read(zoomProvider.notifier).state = 100;
                },
                child: const CustomMenuButton(
                  text: "Reset zoom",
                  shortcut: "Control + 0",
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 25,
            height: 25,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              hoverColor: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
              child: Icon(
                Icons.settings_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class CustomMenuButton extends StatelessWidget {
  final String text;
  final String shortcut;
  const CustomMenuButton({
    super.key,
    required this.text,
    required this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              shortcut,
              style: TextStyle(
                color: colorScheme.primary.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
