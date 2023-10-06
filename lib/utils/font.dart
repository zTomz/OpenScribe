import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openscribe/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> changeFontFamily(BuildContext context, String fontName) async {
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

  // Save primary color to shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  final result = await sharedPreferences.setString(
    MemoryLocations.fontFamily,
    fontName,
  );
  debugPrint("Status saving font [$fontName]: $result");
}

final Map<String?, TextStyle> fontFamilies = {
  null: const TextStyle(),
  "Inconsolata": GoogleFonts.inconsolata(),
  "Inter": GoogleFonts.inter(),
  "Kanit": GoogleFonts.kanit(),
  "Lato": GoogleFonts.lato(),
  "Montserrat": GoogleFonts.montserrat(),
  "Nunito": GoogleFonts.nunito(),
  "Nunito Sans": GoogleFonts.nunitoSans(),
  "Open Sans": GoogleFonts.openSans(),
  "Open Sans Condensed": GoogleFonts.openSansCondensed(),
  "Oswald": GoogleFonts.oswald(),
  "Raleway": GoogleFonts.raleway(),
  "Roboto": GoogleFonts.roboto(),
  "Roboto Condensed": GoogleFonts.robotoCondensed(),
  "Roboto Mono": GoogleFonts.robotoMono(),
  "Roboto Slab": GoogleFonts.robotoSlab(),
  "Rubik": GoogleFonts.rubik(),
  "Rubik Mono One": GoogleFonts.rubikMonoOne(),
  "Rubik Pixels": GoogleFonts.rubikPixels(),
  "Ubuntu": GoogleFonts.ubuntu(),
  "Ubuntu Condensed": GoogleFonts.ubuntuCondensed(),
  "Ubuntu Mono": GoogleFonts.ubuntuMono(),
};
