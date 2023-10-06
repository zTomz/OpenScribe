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