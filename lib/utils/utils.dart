import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:openscribe/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Utils {
  static pw.Document createPdfFromText(String title, String inputText) {
    final document = pw.Document(title: title);

    List<String> lines = inputText.split('\n'); // Split the string

    List<String> groupedLines = [];
    List<String> currentGroup = [];

    for (int i = 0; i < lines.length; i++) {
      currentGroup.add(lines[i]);

      if (currentGroup.length == 52 || i == lines.length - 1) {
        groupedLines.add(currentGroup.join("\n"));
        currentGroup = [];
      }
    }

    // Gib die gruppierten Teile aus
    for (final String text in groupedLines) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Text(
            text,
          ),
        ),
      );
    }

    return document;
  }

  static Future<void> displayPrintingDialog(
      String? documentTitle, String documentText, BuildContext context) async {
    if (documentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("${LocalKeys.documentIsEmpty.tr()}."),
        ),
      );
      return;
    }
    final pdfViewerController = PdfViewerController();

    final document = createPdfFromText(
      documentTitle ?? LocalKeys.unknown.tr(),
      documentText,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(40),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.background,
          ),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder(
                    future: document.save(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SfPdfViewer.memory(
                          snapshot.data!,
                          controller: pdfViewerController,
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }
                    }),
              ),
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(),
                  ),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Printing.layoutPdf(
                          onLayout: (_) async => Uint8List.fromList(
                            await document.save(),
                          ),
                        );
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: Text(LocalKeys.printing.tr()),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        pdfViewerController.previousPage();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        pdfViewerController.nextPage();
                      },
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    pdfViewerController.dispose();
  }

  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
