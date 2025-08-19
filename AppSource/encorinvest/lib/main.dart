import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_page.dart';
import 'utilities_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '/l10n/app_localizations.dart';

/// Manages reading and writing configuration settings from/to the encorin.txt file.
class ConfigManager {
  static const String _configFilePath =
      '/data/adb/modules/EnCorinVest/encorin.txt';
  // Use a consistent, non-localized key
  static const String _defaultMode = 'NONE';

  static Future<Map<String, String>> readConfig() async {
    String currentMode = _defaultMode;

    try {
      var result =
          await run('su', ['-c', 'cat $_configFilePath'], verbose: false);
      if (result.exitCode == 0) {
        String content = result.stdout.toString();
        List<String> lines = content.split('\n');
        for (String line in lines) {
          if (line.startsWith('current_mode=')) {
            String value = line.substring('current_mode='.length).trim();
            if (value.isNotEmpty) currentMode = value.toUpperCase();
          }
        }
      }
    } catch (e) {
      print('Error reading config file: $e');
    }

    return {'current_mode': currentMode};
  }

  /// Updates a specific field in the config file without clearing other content
  static Future<void> _updateConfigField(String fieldName, String value) async {
    try {
      var readResult = await run(
          'su', ['-c', 'cat $_configFilePath 2>/dev/null || echo ""'],
          verbose: false);

      List<String> lines = [];
      bool fieldFound = false;

      if (readResult.exitCode == 0 &&
          readResult.stdout.toString().trim().isNotEmpty) {
        String content = readResult.stdout.toString();
        lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('$fieldName=')) {
            lines[i] = '$fieldName=${value.toUpperCase()}';
            fieldFound = true;
            break;
          }
        }
      } else {
        lines = ['[EnCorinVest config]'];
      }

      if (!fieldFound) {
        lines.add('$fieldName=${value.toUpperCase()}');
      }

      while (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }

      String updatedContent = lines.join('\n') + '\n';
      await run('su', ['-c', 'echo "$updatedContent" > $_configFilePath'],
          verbose: false);
    } catch (e) {
      print('Error updating config field $fieldName: $e');
    }
  }

  /// Saves only the current_mode field, preserving other config values
  static Future<void> saveMode(String mode) async {
    await _updateConfigField('current_mode', mode);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue);
  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  void _loadLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('language_code') ?? 'en';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  void setLocale(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

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
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MainScreen(onLocaleChange: setLocale),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        themeMode: ThemeMode.system,
      );
    });
  }
}

class MainScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  MainScreen({required this.onLocaleChange});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _hasRootAccess = false;
  bool _moduleInstalled = false;
  String _moduleVersion = 'Unknown';
  String _currentMode = 'NONE';
  String _selectedLanguage = 'EN';
  String _executingScript = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
    _initializeState();
  }

  void _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('language_code') ?? 'en';
    Map<String, String> codeMap = {
      'en': 'EN',
      'id': 'ID',
      'ja': 'JP',
    };
    if (mounted) {
      setState(() {
        _selectedLanguage = codeMap[languageCode] ?? 'EN';
      });
    }
  }

  Future<void> _initializeState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    bool rootGranted = await _checkRootAccess();
    if (rootGranted) {
      var config = await ConfigManager.readConfig();
      if (mounted) {
        setState(() {
          _currentMode = config['current_mode'] ?? 'NONE';
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

  Future<void> executeScript(String scriptName, String modeKey) async {
    if (!_hasRootAccess || !_moduleInstalled || _executingScript.isNotEmpty)
      return;

    String targetMode =
        (modeKey == 'CLEAR' || modeKey == 'COOLDOWN') ? 'NONE' : modeKey;

    if (mounted) {
      setState(() {
        _executingScript = scriptName;
        _currentMode = targetMode;
      });
    }

    try {
      await ConfigManager.saveMode(targetMode);

      var result = await run(
          'su', ['-c', '/data/adb/modules/EnCorinVest/Scripts/$scriptName'],
          verbose: false);

      if (result.exitCode != 0) {
        await _refreshStateFromConfig();
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
        _currentMode = config['current_mode'] ?? 'NONE';
      });
    }
  }

  void _changeLanguage(String language) async {
    if (language == _selectedLanguage) return;

    Map<String, String> localeMap = {
      'EN': 'en',
      'ID': 'id',
      'JP': 'ja',
    };

    String localeCode = localeMap[language.toUpperCase()] ?? 'en';
    widget.onLocaleChange(Locale(localeCode));

    if (mounted) setState(() => _selectedLanguage = language.toUpperCase());
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
        context, MaterialPageRoute(builder: (context) => AboutPage()));
  }

  void _navigateToUtilitiesPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => UtilitiesPage()));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
                          localization.power_save_desc,
                          'powersafe.sh',
                          localization.power_save,
                          Icons.battery_saver,
                          colorScheme.primaryContainer,
                          colorScheme.onPrimaryContainer,
                          'POWER_SAVE'),
                      _buildControlRow(
                          localization.balanced_desc,
                          'balanced.sh',
                          localization.balanced,
                          Icons.balance,
                          colorScheme.secondaryContainer,
                          colorScheme.onSecondaryContainer,
                          'BALANCED'),
                      _buildControlRow(
                          localization.performance_desc,
                          'performance.sh',
                          localization.performance,
                          Icons.speed,
                          colorScheme.tertiaryContainer,
                          colorScheme.onTertiaryContainer,
                          'PERFORMANCE'),
                      _buildControlRow(
                          localization.gaming_desc,
                          'game.sh',
                          localization.gaming_pro,
                          Icons.sports_esports,
                          colorScheme.errorContainer,
                          colorScheme.onErrorContainer,
                          'GAMING_PRO'),
                      _buildControlRow(
                          localization.cooldown_desc,
                          'cool.sh',
                          localization.cooldown,
                          Icons.ac_unit,
                          colorScheme.surfaceVariant,
                          colorScheme.onSurfaceVariant,
                          'COOLDOWN'),
                      _buildControlRow(
                          localization.clear_desc,
                          'kill.sh',
                          localization.clear,
                          Icons.clear_all,
                          colorScheme.error,
                          colorScheme.onError,
                          'CLEAR'),
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
                  localization.app_title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),
              Text(
                localization.by,
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
                localization.root_access,
                _hasRootAccess ? localization.yes : localization.no,
                _hasRootAccess ? Colors.green : colorScheme.error),
            _buildStatusRow(
                localization.module_installed,
                _moduleInstalled ? localization.yes : localization.no,
                _moduleInstalled ? Colors.green : colorScheme.error),
            _buildStatusRow(localization.module_version, _moduleVersion,
                colorScheme.onSurfaceVariant,
                isVersion: true),
            _buildStatusRow(localization.current_mode,
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
                localization.app_title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                localization.utilities,
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
        Text(localization.select_language,
            style: Theme.of(context).textTheme.bodyMedium),
        DropdownButton<String>(
          value: _selectedLanguage,
          items: <String>['EN', 'ID', 'JP'].map((String value) {
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
      Color foregroundColor,
      String modeKey) {
    bool isCurrentMode = _currentMode == modeKey;
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
        onTap: canExecute ? () => executeScript(scriptName, modeKey) : null,
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
