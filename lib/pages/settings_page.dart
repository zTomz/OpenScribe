import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:openscribe/utils/font.dart';
import 'package:openscribe/utils/provider.dart';
import 'package:openscribe/utils/settings.dart';
import 'package:openscribe/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    ValueNotifier<Color> primaryColor = useState(colorScheme.primary);
    final showColorPicker = useState(false);

    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SettingsWindowBar(
              onClose: () async {
                changePrimaryColor(context, primaryColor.value);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text(
                      LocalKeys.theme.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: colorScheme.onBackground),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(LocalKeys.themeMode.tr()),
                      trailing: DropdownButton(
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: colorScheme.onBackground),
                        value: AdaptiveTheme.of(context).mode,
                        items: [
                          DropdownMenuItem(
                            value: AdaptiveThemeMode.light,
                            child: Text(LocalKeys.light.tr()),
                          ),
                          DropdownMenuItem(
                            value: AdaptiveThemeMode.dark,
                            child: Text(LocalKeys.dark.tr()),
                          ),
                          DropdownMenuItem(
                            value: AdaptiveThemeMode.system,
                            child: Text("${LocalKeys.system.tr()}   "),
                          )
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          AdaptiveTheme.of(context).setThemeMode(value);
                        },
                        alignment: Alignment.centerLeft,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.all(10),
                        underline: const SizedBox.shrink(),
                        icon: Icon(
                          AdaptiveTheme.of(context).mode ==
                                  AdaptiveThemeMode.light
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(LocalKeys.primaryColor.tr()),
                      trailing: Tooltip(
                        message: LocalKeys.toggleColorPicker.tr(),
                        child: InkWell(
                          onTap: () {
                            // Color picker gets closed
                            if (showColorPicker.value) {
                              changePrimaryColor(context, primaryColor.value);
                            }

                            showColorPicker.value = !showColorPicker.value;
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 70,
                            height: 35,
                            decoration: BoxDecoration(
                              color: primaryColor.value,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.onBackground,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showColorPicker.value)
                      PaletteHuePicker(
                        onChanged: (color) {
                          primaryColor.value = color.toColor();
                        },
                        color: HSVColor.fromColor(
                          primaryColor.value,
                        ),
                        hueBorderRadius: BorderRadius.circular(20),
                        paletteBorderRadius: BorderRadius.circular(20),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      LocalKeys.text.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: colorScheme.onBackground),
                    ),
                    ListTile(
                      title: Text(LocalKeys.font.tr()),
                      trailing: DropdownButton(
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: colorScheme.onBackground),
                        value: settings.font ?? LocalKeys.Default.tr(),
                        items: fontFamilies.keys.map((key) {
                          return DropdownMenuItem(
                            value: key ?? "Default",
                            child: Text(
                              key ?? LocalKeys.Default.tr(),
                              style: fontFamilies[key] ?? const TextStyle(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value == null) return;

                          await ref
                              .read(settingsProvider.notifier)
                              .changeFontFamily(value, context);
                        },
                        alignment: Alignment.centerLeft,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.all(10),
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.font_download_rounded),
                      ),
                    ),
                    if (Utils.isDesktop) const SizedBox(height: 10),
                    if (Utils.isDesktop)
                      Text(
                        LocalKeys.storage.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(color: colorScheme.onBackground),
                      ),
                    if (Utils.isDesktop)
                      ListTile(
                        title: Text(LocalKeys.whenEditorIsLaunched.tr()),
                        trailing: DropdownButton<WhenEditorLaunched>(
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: colorScheme.onBackground),
                          value: settings.whenEditorLaunched,
                          items: [
                            DropdownMenuItem(
                              value:
                                  WhenEditorLaunched.documentsFromOlderSession,
                              child: Text(
                                "${LocalKeys.loadFilesFromOlderSession.tr()}   ",
                              ),
                            ),
                            DropdownMenuItem(
                              value: WhenEditorLaunched.newSession,
                              child: Text(
                                LocalKeys.openANewSession.tr(),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            ref
                                .read(settingsProvider.notifier)
                                .changeWhenEditorLaunched(value);
                          },
                          alignment: Alignment.centerLeft,
                          borderRadius: BorderRadius.circular(10),
                          padding: const EdgeInsets.all(10),
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.save_rounded),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      LocalKeys.language.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: colorScheme.onBackground),
                    ),
                    ListTile(
                      title: Text(LocalKeys.language.tr()),
                      trailing: DropdownButton<Locale>(
                        value: context.locale,
                        items: languageKeys.keys
                            .map(
                              (lang) => DropdownMenuItem(
                                value: languageKeys[lang],
                                child: Text(
                                  lang.tr(),
                                  style: TextStyle(
                                    color: colorScheme.onBackground,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          context.setLocale(value);
                        },
                        alignment: Alignment.centerLeft,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.all(10),
                        underline: const SizedBox.shrink(),
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(
                            Icons.language_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> changePrimaryColor(
      BuildContext context, Color primaryColor) async {
    AdaptiveTheme.of(context).setTheme(
      light: AdaptiveTheme.of(context).lightTheme.copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
            ),
          ),
      dark: AdaptiveTheme.of(context).darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
            ),
          ),
    );

    // Save primary color to shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    final result = await sharedPreferences.setString(
      MemoryLocations.primaryAppColor,
      primaryColor.value.toString(),
    );
    debugPrint("Status saving primary color: $result");
  }
}

class SettingsWindowBar extends StatelessWidget {
  final void Function() onClose;

  const SettingsWindowBar({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: windowTitleBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 10),
          SizedBox(
            width: 35,
            height: 35,
            child: IconButton(
              onPressed: () {
                onClose();

                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              iconSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            LocalKeys.settings.tr(),
            style: TextStyle(
              color: colorScheme.onBackground,
            ),
          ),
          if (Utils.isDesktop)
            Expanded(
              child: WindowCaption(
                backgroundColor: colorScheme.background,
                brightness: colorScheme.brightness,
              ),
            ),
        ],
      ),
    );
  }
}
