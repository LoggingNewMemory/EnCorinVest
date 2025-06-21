import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:async';
import 'languages.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_page.dart'; // Import the about page
import 'utilities_page.dart';

/// Manages reading and writing configuration settings from/to the encorin.txt file.
class ConfigManager {
  static const String _configFilePath =
      '/data/adb/modules/EnCorinVest/encorin.txt';
  static const String _defaultLanguage = 'EN';
  static const String _defaultMode = 'None';

  static Future<Map<String, String>> readConfig() async {
    String language = _defaultLanguage;
    String currentMode = _defaultMode;

    try {
      var result =
          await run('su', ['-c', 'cat $_configFilePath'], verbose: false);
      if (result.exitCode == 0) {
        String content = result.stdout.toString();
        List<String> lines = content.split('\n');
        for (String line in lines) {
          if (line.startsWith('language=')) {
            String value = line.substring('language='.length).trim();
            if (value.isNotEmpty) language = value.toUpperCase();
          } else if (line.startsWith('current_mode=')) {
            String value = line.substring('current_mode='.length).trim();
            if (value.isNotEmpty) currentMode = value.toUpperCase();
          }
        }
      }
    } catch (e) {
      print('Error reading config file: $e');
    }

    return {'language': language, 'current_mode': currentMode};
  }

  static Future<void> writeConfig(
      {required String language, required String currentMode}) async {
    String content = '[EnCorinVest config]\n'
        'language=${language.toUpperCase()}\n'
        'current_mode=${currentMode.toUpperCase()}\n';

    try {
      await run('su', ['-c', 'echo "$content" > $_configFilePath'],
          verbose: false);
    } catch (e) {
      print('Error writing config file: $e');
    }
  }

  static Future<void> saveLanguage(String languageCode) async {
    var currentConfig = await readConfig();
    await writeConfig(
        language: languageCode, currentMode: currentConfig['current_mode']!);
  }

  static Future<void> saveMode(String mode) async {
    var currentConfig = await readConfig();
    await writeConfig(language: currentConfig['language']!, currentMode: mode);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue);
  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightColorScheme =
          lightDynamic?.harmonized() ?? _defaultLightColorScheme;
      ColorScheme darkColorScheme =
          darkDynamic?.harmonized() ?? _defaultDarkColorScheme;

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        themeMode: ThemeMode.system,
      );
    });
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _hasRootAccess = false;
  bool _moduleInstalled = false;
  String _moduleVersion = 'Unknown';
  String _currentMode = 'None';
  String _selectedLanguage = 'EN';
  String _executingScript = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    bool rootGranted = await _checkRootAccess();
    if (rootGranted) {
      var config = await ConfigManager.readConfig();
      if (mounted) {
        setState(() {
          _selectedLanguage =
              config['language'] ?? ConfigManager._defaultLanguage;
          _currentMode = config['current_mode'] ?? ConfigManager._defaultMode;
        });
      }
      await _checkModuleInstalled();
      if (_moduleInstalled) await _getModuleVersion();
    } else {
      if (mounted) {
        setState(() {
          _moduleInstalled = false;
          _moduleVersion = 'Root Required';
          _currentMode = 'Root Required';
          _selectedLanguage = ConfigManager._defaultLanguage;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool> _checkRootAccess() async {
    try {
      var result = await run('su', ['-c', 'id'], verbose: false);
      bool hasAccess = result.exitCode == 0;
      if (mounted) setState(() => _hasRootAccess = hasAccess);
      return hasAccess;
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkModuleInstalled() async {
    if (!_hasRootAccess) return;
    try {
      var result = await run(
          'su', ['-c', 'test -d /data/adb/modules/EnCorinVest && echo "yes"'],
          verbose: false);
      if (mounted)
        setState(
            () => _moduleInstalled = result.stdout.toString().trim() == 'yes');
    } catch (e) {
      if (mounted) setState(() => _moduleInstalled = false);
    }
  }

  Future<void> _getModuleVersion() async {
    if (!_hasRootAccess || !_moduleInstalled) return;
    try {
      var result = await run('su',
          ['-c', 'grep "^version=" /data/adb/modules/EnCorinVest/module.prop'],
          verbose: false);
      String line = result.stdout.toString().trim();
      String version =
          line.contains('=') ? line.split('=')[1].trim() : 'Unknown';
      if (mounted)
        setState(
            () => _moduleVersion = version.isNotEmpty ? version : 'Unknown');
    } catch (e) {
      if (mounted) setState(() => _moduleVersion = 'Error');
    }
  }

  Future<void> executeScript(String scriptName, String buttonText) async {
    if (!_hasRootAccess || !_moduleInstalled || _executingScript.isNotEmpty)
      return;
    String targetMode = buttonText.toUpperCase() ==
            localization.translate('clear').toUpperCase()
        ? 'None'
        : buttonText.toUpperCase();

    if (mounted) {
      setState(() {
        _executingScript = scriptName;
        if (buttonText.toUpperCase() !=
            localization.translate('clear').toUpperCase()) {
          _currentMode = buttonText.toUpperCase();
        }
      });
    }

    try {
      if (buttonText.toUpperCase() !=
          localization.translate('clear').toUpperCase()) {
        await ConfigManager.saveMode(buttonText.toUpperCase());
      }

      var result = await run(
          'su', ['-c', '/data/adb/modules/EnCorinVest/Scripts/$scriptName'],
          verbose: false);

      if (result.exitCode != 0) {
        await _refreshStateFromConfig();
      } else if (buttonText.toUpperCase() ==
          localization.translate('clear').toUpperCase()) {
        await ConfigManager.saveMode('None');
        if (mounted) setState(() => _currentMode = 'None');
      }
    } catch (e) {
      await _refreshStateFromConfig();
    } finally {
      if (mounted) setState(() => _executingScript = '');
    }
  }

  Future<void> _refreshStateFromConfig() async {
    if (!_hasRootAccess) return;
    var config = await ConfigManager.readConfig();
    if (mounted) {
      setState(() {
        _selectedLanguage =
            config['language'] ?? ConfigManager._defaultLanguage;
        _currentMode = config['current_mode'] ?? ConfigManager._defaultMode;
      });
    }
  }

  void _changeLanguage(String language) {
    if (language == _selectedLanguage) return;
    if (mounted) setState(() => _selectedLanguage = language.toUpperCase());
    ConfigManager.saveLanguage(language.toUpperCase());
  }

  Future<void> _launchURL(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error launching $url')));
    }
  }

  void _navigateToAboutPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                AboutPage(selectedLanguage: _selectedLanguage)));
  }

  void _navigateToUtilitiesPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                UtilitiesPage(selectedLanguage: _selectedLanguage)));
  }

  late AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    localization = AppLocalizations(_selectedLanguage);
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleHeader(colorScheme, localization),
                      SizedBox(height: 16),
                      _buildHeaderRow(localization),
                      SizedBox(height: 10),
                      _buildControlRow(
                          localization.translate('power_save_desc'),
                          'powersafe.sh',
                          localization.translate('power_save'),
                          Icons.battery_saver,
                          colorScheme.primaryContainer,
                          colorScheme.onPrimaryContainer),
                      _buildControlRow(
                          localization.translate('balanced_desc'),
                          'balanced.sh',
                          localization.translate('balanced'),
                          Icons.balance,
                          colorScheme.secondaryContainer,
                          colorScheme.onSecondaryContainer),
                      _buildControlRow(
                          localization.translate('performance_desc'),
                          'performance.sh',
                          localization.translate('performance'),
                          Icons.speed,
                          colorScheme.tertiaryContainer,
                          colorScheme.onTertiaryContainer),
                      _buildControlRow(
                          localization.translate('gaming_desc'),
                          'game.sh',
                          localization.translate('gaming_pro'),
                          Icons.sports_esports,
                          colorScheme.errorContainer,
                          colorScheme.onErrorContainer),
                      _buildControlRow(
                          localization.translate('cooldown_desc'),
                          'cool.sh',
                          localization.translate('cooldown'),
                          Icons.ac_unit,
                          colorScheme.surfaceVariant,
                          colorScheme.onSurfaceVariant),
                      _buildControlRow(
                          localization.translate('clear_desc'),
                          'kill.sh',
                          localization.translate('clear'),
                          Icons.clear_all,
                          colorScheme.error,
                          colorScheme.onError),
                      SizedBox(height: 25),
                      _buildLanguageSelector(localization),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTitleHeader(
      ColorScheme colorScheme, AppLocalizations localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _navigateToAboutPage,
                child: Text(
                  localization.translate('app_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),
              Text(
                localization.translate('by'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.telegram, color: colorScheme.primary),
              onPressed: () => _launchURL('https://t.me/KLAGen2'),
              tooltip: 'Telegram',
            ),
            IconButton(
              icon: Icon(Icons.code, color: colorScheme.primary),
              onPressed: () =>
                  _launchURL('https://github.com/LoggingNewMemory/EnCorinVest'),
              tooltip: 'GitHub',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderRow(AppLocalizations localization) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildStatusInfo(localization)),
          SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _navigateToUtilitiesPage,
              borderRadius: BorderRadius.circular(12),
              child: _buildUtilitiesBox(localization),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(AppLocalizations localization) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusRow(
                localization.translate('root_access'),
                _hasRootAccess
                    ? localization.translate('yes')
                    : localization.translate('no'),
                _hasRootAccess ? Colors.green : colorScheme.error),
            _buildStatusRow(
                localization.translate('module_installed'),
                _moduleInstalled
                    ? localization.translate('yes')
                    : localization.translate('no'),
                _moduleInstalled ? Colors.green : colorScheme.error),
            _buildStatusRow(localization.translate('module_version'),
                _moduleVersion, colorScheme.onSurfaceVariant,
                isVersion: true),
            _buildStatusRow(localization.translate('current_mode'),
                _currentMode.toUpperCase(), colorScheme.primary,
                isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor,
      {bool isBold = false, bool isVersion = false}) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
              overflow: isVersion ? TextOverflow.ellipsis : TextOverflow.fade,
              softWrap: !isVersion,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilitiesBox(AppLocalizations localization) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 30, color: colorScheme.primary),
              SizedBox(height: 10),
              Text(
                localization.translate('app_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                localization.translate('utilities'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppLocalizations localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(localization.translate('select_language'),
            style: Theme.of(context).textTheme.bodyMedium),
        DropdownButton<String>(
          value: _selectedLanguage,
          items: <String>['EN', 'ID', 'JP', 'JV'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) _changeLanguage(newValue);
          },
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          underline: Container(
              height: 1, color: Theme.of(context).colorScheme.primary),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildControlRow(
      String description,
      String scriptName,
      String buttonText,
      IconData modeIcon,
      Color backgroundColor,
      Color foregroundColor) {
    bool isCurrentMode = _currentMode == buttonText.toUpperCase();
    bool isExecutingThis = _executingScript == scriptName;
    bool canExecute =
        _hasRootAccess && _moduleInstalled && _executingScript.isEmpty;
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: isCurrentMode
          ? colorScheme.primaryContainer
          : colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: canExecute ? () => executeScript(scriptName, buttonText) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                modeIcon,
                size: 24,
                color: isCurrentMode
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buttonText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isCurrentMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontStyle: isCurrentMode
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: isCurrentMode
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isCurrentMode
                                ? colorScheme.onPrimaryContainer
                                    .withOpacity(0.8)
                                : colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              if (isExecutingThis)
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(isCurrentMode
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.primary),
                  ),
                )
              else if (isCurrentMode)
                Icon(Icons.check_circle,
                    color: colorScheme.onPrimaryContainer, size: 20)
              else
                Icon(Icons.arrow_forward_ios,
                    color: colorScheme.onSurfaceVariant, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
