import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openscribe/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    ValueNotifier<Color> primaryColor = useState(colorScheme.primary);
    final showColorPicker = useState(false);

    return Scaffold(
      body: Column(
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
                  Text("Theme", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text("Theme Mode"),
                    trailing: DropdownButton(
                      value: AdaptiveTheme.of(context).mode,
                      items: const [
                        DropdownMenuItem(
                          value: AdaptiveThemeMode.light,
                          child: Text("Light"),
                        ),
                        DropdownMenuItem(
                          value: AdaptiveThemeMode.dark,
                          child: Text("Dark"),
                        ),
                        DropdownMenuItem(
                          value: AdaptiveThemeMode.system,
                          child: Text("System   "),
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
                    title: const Text("Primary Color"),
                    trailing: Tooltip(
                      message: "Toggle color picker",
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
                ],
              ),
            ),
          ),
        ],
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
    debugPrint(result.toString());
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
          const Text("Settings"),
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
