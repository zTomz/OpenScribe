// ignore_for_file: unnecessary_string_interpolations

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/utils/provider.dart';
import 'package:openscribe/utils/utils.dart';
import 'package:uuid/uuid.dart';

@immutable
class Document {
  final String? title;
  final String text;
  final String? diskLocation;
  final String uuid;
  final DateTime? lastSaved;
  final DateTime? lastModified;

  const Document({
    required this.title,
    required this.text,
    required this.diskLocation,
    required this.uuid,
    this.lastSaved,
    this.lastModified,
  });

  static Document empty() {
    return Document(
      title: null,
      text: "",
      diskLocation: null,
      uuid: const Uuid().v4(),
      lastSaved: null,
      lastModified: DateTime.now(),
    );
  }

  Document copyWith({
    String? title,
    String? text,
    String? diskLocation,
    DateTime? lastSaved,
  }) {
    return Document(
      title: title ?? this.title,
      text: text ?? this.text,
      diskLocation: diskLocation ?? this.diskLocation,
      uuid: uuid,
      lastSaved: lastSaved ?? this.lastSaved,
      lastModified: DateTime.now(),
    );
  }

  bool get isEmpty => title == null && text.isEmpty && diskLocation == null;
  bool get isNotEmpty => !isEmpty;
  bool get isNotSaved => title != null && diskLocation == null;
  bool get isSaved => diskLocation != null;

  @override
  String toString() {
    return 'Document(title: $title, text: $text, diskLocation: $diskLocation, uuid: $uuid, lastSaved: $lastSaved, lastModified: $lastModified)';
  }

  String? formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    final DateFormat formatter = DateFormat('dd.MM.yyyy | HH:mm:ss');
    return formatter.format(dateTime);
  }
}

class DocumentNotifier extends StateNotifier<List<Document>> {
  DocumentNotifier() : super([Document.empty()]);

  /// Newly created document gets returned
  Document createNew() {
    final newDoc = Document.empty();

    state = [
      ...state,
      newDoc,
    ];

    return newDoc;
  }

  Future<Document> openDocument() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: LocalKeys.open.tr(),
      type: FileType.any,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      throw "${LocalKeys.cannotOpenSpecifiedFile.tr()}.";
    }

    Document newDoc = Document(
      title: result.files.single.name,
      text: File(result.files.single.path!).readAsStringSync(),
      diskLocation: result.files.single.path!,
      uuid: const Uuid().v4(),
    );

    state = [
      ...state,
      newDoc,
    ];

    return newDoc;
  }

  Future<Document> loadDocumentFromCache(String uuid,
      {bool removeOldDocument = false}) async {
    final path =
        "${MemoryLocations.applicationDocumentsDirectory}\\${MemoryLocations.documentsCacheLocation}\\$uuid.json";

    final file = File(path);

    if (!(await file.exists())) {
      throw "${LocalKeys.fileDoesNotExist.tr()}.";
    }

    if (path.split(".").last != "json") {
      throw "${LocalKeys.fileIsNotAJsonFile.tr()}.";
    }

    final Map<String, dynamic> data = jsonDecode(await file.readAsString());

    if (removeOldDocument) {
      await file.delete();
    }

    Document newDoc = Document(
      title: data["title"] == LocalKeys.unknown.tr() ? null : data["title"],
      text: data["text"],
      diskLocation:
          data["diskLocation"] == "null" ? null : data["diskLocation"],
      uuid: uuid,
      lastSaved: data["lastSaved"] == "null"
          ? null
          : DateTime.parse(data["lastSaved"]),
      lastModified: DateTime.now(),
    );

    state = [
      ...state,
      newDoc,
    ];

    return newDoc;
  }

  Document changeTitle(String newTitle, String uuid) {
    Document doc = state.firstWhere((doc) => doc.uuid == uuid);

    if (doc.diskLocation != null) {
      if (!(File(doc.diskLocation!).existsSync())) {
        doc = Document(
          title: newTitle,
          text: doc.text,
          diskLocation: null,
          uuid: doc.uuid,
        );
        state = [
          doc,
          for (final document in state)
            if (document.uuid != uuid) document,
        ];
        return doc;
      }

      List<String> newPathList = doc.diskLocation!.split("\\");
      newPathList.removeLast();
      String newPath = newPathList.join("\\");

      if (File("$newPath\\$newTitle.odoc").existsSync()) {
        throw LocalKeys.fileWithSameTitleAlreadyExists.tr();
      }

      File(doc.diskLocation!).renameSync("$newPath\\$newTitle.odoc");

      doc = doc.copyWith(
        title: newTitle,
        diskLocation: "$newPath\\$newTitle.odoc",
      );
      // Update the state, remove the old document and add the updatet one
      state = [
        doc,
        for (final document in state)
          if (document.uuid != uuid) document,
      ];
      return doc;
    }

    doc = doc.copyWith(title: newTitle);

    // Update the state, remove the old document and add the updatet one
    state = [
      doc,
      for (final document in state)
        if (document.uuid != uuid) document,
    ];

    return doc;
  }

  Document changeText(String newText, String uuid) {
    Document doc = state.firstWhere((doc) => doc.uuid == uuid);
    doc = doc.copyWith(text: newText);

    // Update the state, remove the old document and add the updatet one
    state = [
      doc,
      for (final document in state)
        if (document.uuid != uuid) document,
    ];

    return doc;
  }

  Future<Document> save(Document doc) async {
    String? diskLocation = doc.diskLocation;

    if (!(File(doc.diskLocation ?? "").existsSync())) {
      diskLocation = null;
    }

    if (diskLocation == null) {
      String? result;

      if (Utils.isDesktop) {
        result = await FilePicker.platform.saveFile(
          dialogTitle: LocalKeys.saveAs.tr(),
          fileName: "${doc.title ?? LocalKeys.unknown.tr()}.odoc",
          type: FileType.custom,
          allowedExtensions: ["odoc", "txt"],
        );

        if (result != null) {
          diskLocation = result;
        } else {
          throw "${LocalKeys.youHaveToPickALocation.tr()}.";
        }
      } else {
        final folderPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: "Save ${doc.title ?? LocalKeys.unknown.tr()}.odoc",
        );

        if (folderPath != null) {
          result = "$folderPath/${doc.title ?? LocalKeys.unknown.tr()}.odoc";
          diskLocation = result;
        } else {
          throw "${LocalKeys.youHaveToPickALocation.tr()}.";
        }
      }
    }

    final file = File(diskLocation);
    if (file.existsSync()) {
      file.writeAsStringSync(doc.text);
    } else {
      file.createSync();
      file.writeAsStringSync(doc.text);
    }

    // Update the state, remove the old document and add the updatet one
    final updatetDoc = doc.copyWith(
      title: doc.title ?? LocalKeys.unknown.tr(),
      diskLocation: diskLocation,
      lastSaved: DateTime.now(),
    );

    state = [
      updatetDoc,
      for (final document in state)
        if (document.uuid != doc.uuid) document,
    ];

    return updatetDoc;
  }

  Future<Document> saveAs(Document doc) async {
    String? diskLocation;

    String? result;

    if (Utils.isDesktop) {
      result = await FilePicker.platform.saveFile(
        dialogTitle: LocalKeys.saveAs.tr(),
        fileName: "${doc.title ?? LocalKeys.unknown.tr()}.odoc",
        type: FileType.custom,
        allowedExtensions: ["odoc", "txt"],
      );

      if (result != null) {
        diskLocation = result;
      } else {
        throw "${LocalKeys.youHaveToPickALocation.tr()}.";
      }
    } else {
      final folderPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Save ${doc.title ?? LocalKeys.unknown.tr()}.odoc",
      );

      if (folderPath != null) {
        result = "$folderPath/${doc.title ?? LocalKeys.unknown.tr()}.odoc";
        diskLocation = result;
      } else {
        throw "${LocalKeys.youHaveToPickALocation.tr()}.";
      }
    }

    final file = File(diskLocation);
    if (file.existsSync()) {
      file.writeAsStringSync(doc.text);
    } else {
      file.createSync();
      file.writeAsStringSync(doc.text);
    }

    // Update the state, remove the old document and add the updatet one
    final updatetDoc = doc.copyWith(
      title: doc.title ?? LocalKeys.unknown.tr(),
      diskLocation: diskLocation,
      lastSaved: DateTime.now(),
    );

    state = [
      updatetDoc,
      for (final document in state)
        if (document.uuid != doc.uuid) document,
    ];

    return updatetDoc;
  }

  /// Saves only every already saved document. Unsaved documents are ignored.
  Future<void> saveAll() async {
    for (final document in state) {
      if (document.isSaved) {
        await save(document);
      }
    }
  }

  Future<void> saveToDocumentsCache(Document document) async {
    final path =
        "${MemoryLocations.applicationDocumentsDirectory}\\${MemoryLocations.documentsCacheLocation}\\${document.uuid}.json"; // Important: JSON Document, not .odoc, the name of doc is the uuid and the title + text is stored in the document
    final file = File(path);

    // Almost impossible, but just in case
    if (file.existsSync()) {
      return;
    }

    final dataToWrite = {
      '"title"': '"${document.title ?? LocalKeys.unknown.tr()}"',
      '"text"': '"${document.text}"',
      '"diskLocation"':
          '"${(document.diskLocation ?? "null").replaceAll("\\", "\\\\")}"',
      '"lastSaved"':
          '"${document.lastSaved == null ? "null" : document.lastSaved!.toIso8601String()}"',
    };

    file.createSync(recursive: true);
    file.writeAsStringSync(dataToWrite.toString());
  }

  void remove(String uuid) {
    state = [
      for (final document in state)
        if (document.uuid != uuid) document,
    ];
  }

  void removeMultiple(List<String> uuids) {
    state = [
      for (final uuid in uuids)
        for (final document in state)
          if (document.uuid != uuid) document,
    ];
  }

  Future<void> deleteCachedDocuments() async {
    Directory cacheDocumentsDirectory = Directory(
      "${MemoryLocations.applicationDocumentsDirectory}\\${MemoryLocations.documentsCacheLocation}",
    );

    await cacheDocumentsDirectory.delete(recursive: true);
  }

  Future<void> removeDocumentWithDialog(Document selectedDocument,
      Document currentDocument, BuildContext context, WidgetRef ref) async {
    // Remove document
    if (state.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "${LocalKeys.thisIsTheLastDocument.tr()}.",
          ),
        ),
      );
      return;
    }

    if (selectedDocument.isEmpty) {
      remove(selectedDocument.uuid);

      if (currentDocument.uuid == selectedDocument.uuid) {
        ref.read(currentDocumentProvider.notifier).state = getFirstDocument();
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
                remove(selectedDocument.uuid);

                if (currentDocument.uuid == selectedDocument.uuid) {
                  ref.read(currentDocumentProvider.notifier).state =
                      getFirstDocument();
                }

                Navigator.of(context).pop();
              },
              child: Text(
                LocalKeys.delete.tr(),
              ),
            ),
            TextButton(
              onPressed: () {
                save(selectedDocument);

                Navigator.pop(context);
              },
              child: Text(
                LocalKeys.save.tr(),
              ),
            ),
          ],
        ),
      );
    }
  }

  Document getFirstDocument() {
    return state.first;
  }

  Document getDocumentWithUuid(String uuid) {
    return state.firstWhere((doc) => doc.uuid == uuid);
  }

  List<Document> getDocuments() {
    return state;
  }

  void clear() {
    state = [];
  }
}
