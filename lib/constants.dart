import 'dart:ui';

import 'package:flutter/foundation.dart';

const double windowTitleBarHeight = 40.0;

class MemoryLocations {
  static const String documentsFromOlderSessions = "documentsFromOlderSessions";
  static const String primaryAppColor = "primaryAppColor";
  static const String fontFamily = "fontFamily";

  static const String documentsCacheLocation = "OpenScribe/Cache Documents/";
  static String? applicationDocumentsDirectory;
}

const bool canCloseWindow = kDebugMode ? false : true;

class LocalKeys {
  static const String warning = "fileSavePopup.warning";
  static const String dontSave = "fileSavePopup.dontSave";
  static const String isNotSaved = "fileSavePopup.isNotSaved";
  static const String quit = "fileSavePopup.quit";
  static const String theDocument = "fileSavePopup.theDocument";

  static const String file = "file";
  static const String newDocument = "newDocument";
  static const String open = "open";
  static const String save = "save";
  static const String saveAs = "saveAs";
  static const String view = "view";
  static const String zoomIn = "zoomIn";
  static const String zoomOut = "zoomOut";
  static const String resetZoom = "resetZoom";
  static const String unknown = "unknown";
  static const String thisIsTheLastDocument = "thisIsTheLastDocument";
  static const String areYouSure = "areYouSure";
  static const String doYouWantToDeleteThisDocument =
      "doYouWantToDeleteThisDocument";
  static const String cancel = "cancel";
  static const String delete = "delete";
  static const String diskLocation = "diskLocation";
  static const String lastSaved = "lastSaved";
  static const String lastModified = "lastModified";
  static const String notSaved = "notSaved";
  static const String notModified = "notModified";
  static const String enterYourTextHere = "enterYourTextHere";
  static const String theme = "theme";
  static const String themeMode = "themeMode";
  static const String dark = "dark";
  static const String light = "light";
  static const String system = "system";
  static const String primaryColor = "primaryColor";
  static const String toggleColorPicker = "toggleColorPicker";
  static const String text = "text";
  static const String font = "font";
  // ignore: constant_identifier_names
  static const String Default = "default";
  static const String storage = "storage";
  static const String whenEditorIsLaunched = "whenEditorIsLaunched";
  static const String loadFilesFromOlderSession = "loadFilesFromOlderSession";
  static const String openANewSession = "openANewSession";
  static const String settings = "settings";
  static const String language = "language";
  static const String german = "german";
  static const String english = "english";
  static const String french = "french";
  static const String spanish = "spanish";
  static const String italian = "italian";
  static const String russian = "russian";
  static const String portuguese = "portuguese";
  static const String ukrainian = "ukrainian";
  static const String chinese = "chinese";
  static const String japanese = "japanese";
  static const String korean = "korean";
  static const String arabic = "arabic";
  static const String turkish = "turkish";
  static const String cannotOpenSpecifiedFile = "cannotOpenSpecifiedFile";
  static const String fileWithSameTitleAlreadyExists = "fileWithSameTitleAlreadyExists";
  static const String youHaveToPickALocation = "youHaveToPickALocation";
  static const String fileIsNotAJsonFile = "fileIsNotAJsonFile";
  static const String fileDoesNotExist = "fileDoesNotExist";
  static const String printing = "printing";
  static const String documentIsEmpty = "documentIsEmpty";
}

Map<String, Locale> languageKeys = const {
  LocalKeys.german: Locale("de"),
  LocalKeys.english: Locale("en"),
  LocalKeys.french: Locale("fr"),
  LocalKeys.spanish: Locale("es"),
  LocalKeys.italian: Locale("it"),
  LocalKeys.russian: Locale("ru"),
  LocalKeys.portuguese: Locale("pt"),
  LocalKeys.ukrainian: Locale("uk"),
  LocalKeys.chinese: Locale("zh"),
  LocalKeys.japanese: Locale("ja"),
  LocalKeys.korean: Locale("ko"),
  LocalKeys.arabic: Locale("ar"),
  LocalKeys.turkish: Locale("tr"),
};
