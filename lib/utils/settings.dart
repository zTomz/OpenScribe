import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/utils/font.dart';

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

  @override
  String toString() {
    return 'Settings{font: $font, whenEditorLaunched: $whenEditorLaunched, isLoaded: $isLoaded}';
  }

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
      isLoaded: true,
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

  Future<void> changeFontFamily(String fontName, BuildContext context) async {
    TextStyle? newFontFamily = fontFamilies[fontName];

    if (newFontFamily == null) {
      return;
    }

    newFontFamily = newFontFamily.copyWith(inherit: true);

    final textTheme = Theme.of(context).textTheme;

    final newTextTheme = textTheme.copyWith(
      headlineLarge: newFontFamily.copyWith(
        fontSize: (textTheme.headlineLarge ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.headlineLarge ?? const TextStyle()).fontWeight,
      ),
      headlineMedium: newFontFamily.copyWith(
        fontSize: (textTheme.headlineMedium ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.headlineMedium ?? const TextStyle()).fontWeight,
      ),
      headlineSmall: newFontFamily.copyWith(
        fontSize: (textTheme.headlineSmall ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.headlineSmall ?? const TextStyle()).fontWeight,
      ),
      titleLarge: newFontFamily.copyWith(
        fontSize: (textTheme.titleLarge ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.titleLarge ?? const TextStyle()).fontWeight,
      ),
      titleMedium: newFontFamily.copyWith(
        fontSize: (textTheme.titleMedium ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.titleMedium ?? const TextStyle()).fontWeight,
      ),
      titleSmall: newFontFamily.copyWith(
        fontSize: (textTheme.titleSmall ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.titleSmall ?? const TextStyle()).fontWeight,
      ),
      bodyLarge: newFontFamily.copyWith(
        fontSize: (textTheme.bodyLarge ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.bodyLarge ?? const TextStyle()).fontWeight,
      ),
      bodyMedium: newFontFamily.copyWith(
        fontSize: (textTheme.bodyMedium ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.bodyMedium ?? const TextStyle()).fontWeight,
      ),
      bodySmall: newFontFamily.copyWith(
        fontSize: (textTheme.bodySmall ?? const TextStyle()).fontSize,
        fontWeight: (textTheme.bodySmall ?? const TextStyle()).fontWeight,
      ),
    );

    AdaptiveTheme.of(context).setTheme(
      light: AdaptiveTheme.of(context).lightTheme.copyWith(
            textTheme: newTextTheme,
          ),
      dark: AdaptiveTheme.of(context).darkTheme.copyWith(
            textTheme: newTextTheme,
          ),
    );

    state = state.copyWith(
      font: fontName,
    );

    await save();
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

    debugPrint("Write: ${data.toString()}");
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
