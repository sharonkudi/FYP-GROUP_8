import 'package:bus_app/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
// ✅ Added

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isLanguageExpanded = false;
  bool isAccessibilityExpanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final loc = AppLocalizations.of(context)!; // ✅ Added

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings), // ✅ Localized
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Language section
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: Text(loc.language), // ✅ Localized
                initiallyExpanded: isLanguageExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => isLanguageExpanded = expanded);
                },
                children: [
                  RadioListTile(
                    title: Text(loc.malay), // ✅ Localized
                    value: 'ms',
                    groupValue: settings.locale.languageCode,
                    onChanged: (val) => settings.changeLanguage(val!),
                  ),
                  RadioListTile(
                    title: Text(loc.english), // ✅ Localized
                    value: 'en',
                    groupValue: settings.locale.languageCode,
                    onChanged: (val) => settings.changeLanguage(val!),
                  ),
                ],
              ),
            ),

            // Accessibility section
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.accessibility, color: Colors.blue),
                title: Text(loc.accessibility), // ✅ Localized
                initiallyExpanded: isAccessibilityExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => isAccessibilityExpanded = expanded);
                },
                children: [
                  ListTile(
                    title: Text(loc.fontSize), // ✅ Localized
                    trailing: DropdownButton<double>(
                      value: settings.fontSize,
                      items: [
                        DropdownMenuItem(
                            value: 12, child: Text(loc.small)), // ✅ Localized
                        DropdownMenuItem(
                            value: 14, child: Text(loc.medium)), // ✅ Localized
                        DropdownMenuItem(
                            value: 18, child: Text(loc.large)), // ✅ Localized
                      ],
                      onChanged: (val) => settings.changeFontSize(val!),
                    ),
                  ),
                  ListTile(
                    title: Text(loc.iconSize), // ✅ Localized
                    trailing: DropdownButton<double>(
                      value: settings.iconSize,
                      items: [
                        DropdownMenuItem(
                            value: 20, child: Text(loc.small)), // ✅ Localized
                        DropdownMenuItem(
                            value: 24, child: Text(loc.medium)), // ✅ Localized
                        DropdownMenuItem(
                            value: 30, child: Text(loc.large)), // ✅ Localized
                      ],
                      onChanged: (val) => settings.changeIconSize(val!),
                    ),
                  ),
                  ListTile(
                    title: Text(loc.mode), // ✅ Localized
                    trailing: Switch(
                      value: settings.isDarkMode,
                      onChanged: settings.toggleDarkMode,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                loc.save, // ✅ Localized
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
