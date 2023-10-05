import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

@immutable
class Document {
  final String? title;
  final String text;
  final String? diskLocation;
  final String uuid;

  const Document({
    required this.title,
    required this.text,
    required this.diskLocation,
    required this.uuid,
  });

  static Document empty() {
    return Document(
      title: null,
      text: "",
      diskLocation: null,
      uuid: const Uuid().v4(),
    );
  }

  Document copyWith({
    String? title,
    String? text,
    String? diskLocation,
  }) {
    return Document(
      title: title ?? this.title,
      text: text ?? this.text,
      diskLocation: diskLocation ?? this.diskLocation,
      uuid: uuid,
    );
  }

  @override
  String toString() {
    return 'Document(title: $title, text: $text, diskLocation: $diskLocation, uuid: $uuid)';
  }

  bool get isEmpty => title == null && text.isEmpty && diskLocation == null;
  bool get isNotEmpty => !isEmpty;
  bool get isNotSaved => title != null && diskLocation == null;
  bool get isSaved => diskLocation != null;
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
      dialogTitle: "Open document",
      type: FileType.custom,
      allowedExtensions: ["edoc", "txt"],
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      throw "Cannot open specified file.";
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
    final applicationDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final path =
        "${applicationDocumentsDirectory.path}\\${MemoryLocations.documentsCacheLocation}\\$uuid.json";

    final file = File(path);

    if (!(await file.exists())) {
      throw "File does not exist.";
    }

    if (path.split(".").last != "json") {
      throw "File is not a json file.";
    }

    final Map<String, dynamic> data = jsonDecode(await file.readAsString());

    if (removeOldDocument) {
      await file.delete();
    }

    Document newDoc = Document(
      title: data["title"] == "Unknown" ? null : data["title"],
      text: data["text"],
      diskLocation:
          data["diskLocation"] == "null" ? null : data["diskLocation"],
      uuid: uuid,
    );

    state = [
      ...state,
      newDoc,
    ];

    return newDoc;
  }

  void changeTitle(String newTitle, String uuid) {
    Document doc = state.firstWhere((doc) => doc.uuid == uuid);

    if (doc.diskLocation != null) {
      List<String> newPathList = doc.diskLocation!.split("\\");
      newPathList.removeLast();
      String newPath = newPathList.join("\\");

      if (File("$newPath\\$newTitle.edoc").existsSync()) {
        doc = doc.copyWith(
          title: doc.title,
        );
        throw "File with same title already exists.";
      }

      File(doc.diskLocation!).renameSync("$newPath\\$newTitle.edoc");

      doc = doc.copyWith(
        title: newTitle,
        diskLocation: "$newPath\\$newTitle.edoc",
      );
      return;
    }

    doc = doc.copyWith(title: newTitle);

    // Update the state, remove the old document and add the updatet one
    state = [
      doc,
      for (final document in state)
        if (document.uuid != uuid) document,
    ];
  }

  void changeText(String newText, String uuid) {
    Document doc = state.firstWhere((doc) => doc.uuid == uuid);

    // Update the state, remove the old document and add the updatet one
    state = [
      doc.copyWith(text: newText),
      for (final document in state)
        if (document.uuid != uuid) document,
    ];
  }

  Future<void> save(Document doc) async {
    String? diskLocation = doc.diskLocation;

    if (diskLocation == null) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: "Save file",
        fileName: "${doc.title ?? "Unknown"}.edoc",
        type: FileType.custom,
        allowedExtensions: ["edoc", "txt"],
      );

      if (result != null) {
        diskLocation = result;
      } else {
        throw "You have to pick a location.";
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
    state = [
      doc.copyWith(diskLocation: diskLocation),
      for (final document in state)
        if (document.uuid != doc.uuid) document,
    ];
  }

  Future<void> saveAs(Document doc) async {
    String? diskLocation;

    final result = await FilePicker.platform.saveFile(
      dialogTitle: "Save file",
      fileName: "${doc.title ?? "Unknown"}.edoc",
      type: FileType.custom,
      allowedExtensions: ["edoc", "txt"],
    );

    if (result != null) {
      diskLocation = result;
    } else {
      throw "You have to pick a location.";
    }

    final file = File(diskLocation);
    if (file.existsSync()) {
      file.writeAsStringSync(doc.text);
    } else {
      file.createSync();
      file.writeAsStringSync(doc.text);
    }

    // Update the state, remove the old document and add the updatet one
    state = [
      doc.copyWith(diskLocation: diskLocation),
      for (final document in state)
        if (document.uuid != doc.uuid) document,
    ];
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
    final applicationDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    final path =
        "${applicationDocumentsDirectory.path}\\${MemoryLocations.documentsCacheLocation}\\${document.uuid}.json"; // Important: JSON Document, not .edoc, the name of doc is the uuid and the title + text is stored in the document
    final file = File(path);

    // Almost impossible, but just in case
    if (file.existsSync()) {
      return;
    }

    final dataToWrite = {
      "\"title\"": "\"${document.title ?? "Unknown"}\"",
      "\"text\"": "\"${document.text}\"",
      "\"diskLocation\"":
          '"${(document.diskLocation ?? "null").replaceAll("\\", "\\\\")}"',
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
    final applicationDocumentsDirectory =
        await getApplicationDocumentsDirectory();
    Directory cacheDocumentsDirectory = Directory(
      "${applicationDocumentsDirectory.path}\\${MemoryLocations.documentsCacheLocation}",
    );

    await cacheDocumentsDirectory.delete(recursive: true);
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
