import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';

enum WhenEditorLaunched { documentsFromOlderSession, newSession }

@immutable
class Settings {
  final String? font;
  final WhenEditorLaunched whenEditorLaunched;
  final bool isLoaded;

  const Settings({
    this.font,
    required this.whenEditorLaunched,
    this.isLoaded = false,
  });

  const Settings.empty()
      : font = null,
        whenEditorLaunched = WhenEditorLaunched.documentsFromOlderSession,
        isLoaded = false;

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      font: json['font'],
      whenEditorLaunched: json['whenEditorLaunched'] ==
              "WhenEditorLaunched.documentsFromOlderSession"
          ? WhenEditorLaunched.documentsFromOlderSession
          : WhenEditorLaunched.newSession,
    );
  }

  Settings copyWith({
    String? font,
    WhenEditorLaunched? whenEditorLaunched,
    bool? isLoaded,
  }) {
    return Settings(
      font: font ?? this.font,
      whenEditorLaunched: whenEditorLaunched ?? this.whenEditorLaunched,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(const Settings.empty());

  Settings get getSettings => state;

  void changeFontFamily(String fontName) {
    state = state.copyWith(
      font: fontName,
    );
  }

  void changeWhenEditorLaunched(WhenEditorLaunched whenEditorLaunched) {
    state = state.copyWith(
      whenEditorLaunched: whenEditorLaunched,
    );
  }

  Future<void> save() async {
    debugPrint("Saving settings");

    final settingsFile = File(
        "${MemoryLocations.applicationDocumentsDirectory}\\OpenScribe\\Settings\\settings.json");

    if (await settingsFile.exists()) {
      await settingsFile.delete();
    }

    final data = {
      '"font"': '"${state.font}"',
      '"whenEditorLaunched"': '"${state.whenEditorLaunched}"',
    };

    await settingsFile.create(recursive: true);
    await settingsFile.writeAsString(data.toString());
  }

  Future<void> load({bool force = false}) async {
    if (state.isLoaded && !force) {
      return;
    }

    final settingsFile = File(
      "${MemoryLocations.applicationDocumentsDirectory}\\OpenScribe\\Settings\\settings.json",
    );

    if (!(await settingsFile.exists())) {
      return;
    }

    final data = await settingsFile.readAsString();

    final settings = Settings.fromJson(
      jsonDecode(data),
    );

    state = settings.copyWith(isLoaded: true);
  }
}
