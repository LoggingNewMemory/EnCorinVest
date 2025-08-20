import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:async';
import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_page.dart';
import 'utilities_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '/l10n/app_localizations.dart';

/// Manages reading and writing configuration settings using SharedPreferences.
/// The app will remember the last selected mode locally.
class ConfigManager {
  static const String _modeKey = 'current_mode';
  static const String _defaultMode = 'NONE';

  /// Reads the current mode from SharedPreferences.
  static Future<Map<String, String>> readConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentMode = prefs.getString(_modeKey) ?? _defaultMode;
      return {'current_mode': currentMode};
    } catch (e) {
      return {'current_mode': _defaultMode};
    }
  }

  /// Saves the current mode to SharedPreferences.
  static Future<void> saveMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.toUpperCase());
    } catch (e) {
      // Error saving mode
    }
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
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.2;
  String _currentTheme = 'Classic'; // Default theme

  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue);
  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final languageCode = prefs.getString('language_code') ?? 'en';
    final path = prefs.getString('background_image_path');
    final opacity = prefs.getDouble('background_opacity') ?? 0.2;
    final theme = prefs.getString('theme_preference') ?? 'Classic';

    setState(() {
      _locale = Locale(languageCode);
      _backgroundImagePath = path;
      _backgroundOpacity = opacity;
      _currentTheme = theme;
    });
  }

  Future<void> _updateLocale(Locale locale) async {
    if (!mounted) return;
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  Future<void> _updateTheme(String theme) async {
    if (_currentTheme == theme) return;
    if (!mounted) return;
    setState(() {
      _currentTheme = theme;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', theme);
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
        home: Scaffold(
          // Conditional background color based on the selected theme
          backgroundColor:
              _currentTheme == 'Classic' ? Colors.transparent : null,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_backgroundImagePath != null &&
                  _backgroundImagePath!.isNotEmpty)
                Opacity(
                  opacity: _backgroundOpacity,
                  child: Image.file(
                    File(_backgroundImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.transparent);
                    },
                  ),
                ),
              MainScreen(
                onLocaleChange: _updateLocale,
                onUtilitiesClosed: _loadAllPreferences,
                currentTheme: _currentTheme,
                onThemeChange: _updateTheme,
              ),
            ],
          ),
        ),
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        themeMode: ThemeMode.system,
      );
    });
  }
}

class MainScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final VoidCallback onUtilitiesClosed;
  final String currentTheme;
  final Function(String) onThemeChange;

  MainScreen({
    required this.onLocaleChange,
    required this.onUtilitiesClosed,
    required this.currentTheme,
    required this.onThemeChange,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _hasRootAccess = false;
  bool _moduleInstalled = false;
  String _moduleVersion = 'Unknown';
  String _currentMode = 'NONE';
  String _selectedLanguage = 'EN';
  String _executingScript = '';
  bool _isLoading = true;
  bool _isHamadaAiRunning = false;
  Timer? _hamadaCheckTimer;
  bool _isContentVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hamadaCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _initializeState();
    } else if (state == AppLifecycleState.paused) {
      _hamadaCheckTimer?.cancel();
    }
  }

  void _startHamadaTimer() {
    _hamadaCheckTimer?.cancel();
    if (mounted) {
      _hamadaCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (mounted) {
          _checkHamadaProcessStatus();
        }
      });
    }
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final languageCode = prefs.getString('language_code') ?? 'en';
    const codeMap = {'en': 'EN', 'id': 'ID', 'ja': 'JP'};
    setState(() {
      _selectedLanguage = codeMap[languageCode] ?? 'EN';
    });
  }

  Future<void> _initializeState() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await _loadSelectedLanguage();

    final rootGranted = await _checkRootAccess();
    if (rootGranted) {
      final config = await ConfigManager.readConfig();
      await _checkHamadaProcessStatus();
      await _checkModuleInstalled();
      if (_moduleInstalled) await _getModuleVersion();

      if (mounted) {
        setState(() {
          _currentMode = config['current_mode'] ?? 'NONE';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _moduleInstalled = false;
          _moduleVersion = 'Root Required';
          _currentMode = 'Root Required';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isContentVisible = true;
      });
      _startHamadaTimer();
    }
  }

  Future<bool> _checkRootAccess() async {
    try {
      var result = await run('su', ['-c', 'id'], verbose: false);
      bool hasAccess = result.exitCode == 0;
      if (mounted) setState(() => _hasRootAccess = hasAccess);
      return hasAccess;
    } catch (e) {
      if (mounted) setState(() => _hasRootAccess = false);
      return false;
    }
  }

  Future<void> _checkHamadaProcessStatus() async {
    if (!_hasRootAccess) return;
    try {
      final result =
          await run('su', ['-c', 'pgrep -x HamadaAI'], verbose: false);
      bool isRunning = result.exitCode == 0;
      if (mounted && _isHamadaAiRunning != isRunning) {
        setState(() => _isHamadaAiRunning = isRunning);
      }
    } catch (e) {
      if (mounted && _isHamadaAiRunning) {
        setState(() => _isHamadaAiRunning = false);
      }
    }
  }

  Future<void> _checkModuleInstalled() async {
    if (!_hasRootAccess) return;
    try {
      var result = await run(
          'su', ['-c', 'test -d /data/adb/modules/EnCorinVest && echo "yes"'],
          verbose: false);
      if (mounted) {
        setState(
            () => _moduleInstalled = result.stdout.toString().trim() == 'yes');
      }
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
      if (mounted) {
        setState(
            () => _moduleVersion = version.isNotEmpty ? version : 'Unknown');
      }
    } catch (e) {
      if (mounted) setState(() => _moduleVersion = 'Error');
    }
  }

  Future<void> executeScript(String scriptName, String modeKey) async {
    if (!_hasRootAccess ||
        !_moduleInstalled ||
        _executingScript.isNotEmpty ||
        _isHamadaAiRunning) return;

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

  void _changeLanguage(String language) {
    if (language == _selectedLanguage) return;

    const localeMap = {'EN': 'en', 'ID': 'id', 'JP': 'ja'};
    String localeCode = localeMap[language.toUpperCase()] ?? 'en';
    widget.onLocaleChange(Locale(localeCode));

    if (mounted) setState(() => _selectedLanguage = language.toUpperCase());
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _navigateToAboutPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AboutPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _navigateToUtilitiesPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UtilitiesPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    _initializeState();
    widget.onUtilitiesClosed();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: LinearProgressIndicator(),
                ))
              : AnimatedOpacity(
                  opacity: _isContentVisible ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: SingleChildScrollView(
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
                            'POWER_SAVE'),
                        _buildControlRow(
                            localization.balanced_desc,
                            'balanced.sh',
                            localization.balanced,
                            Icons.balance,
                            'BALANCED'),
                        _buildControlRow(
                            localization.performance_desc,
                            'performance.sh',
                            localization.performance,
                            Icons.speed,
                            'PERFORMANCE'),
                        _buildControlRow(
                            localization.gaming_desc,
                            'game.sh',
                            localization.gaming_pro,
                            Icons.sports_esports,
                            'GAMING_PRO'),
                        _buildControlRow(localization.cooldown_desc, 'cool.sh',
                            localization.cooldown, Icons.ac_unit, 'COOLDOWN'),
                        _buildControlRow(localization.clear_desc, 'kill.sh',
                            localization.clear, Icons.clear_all, 'CLEAR'),
                        SizedBox(height: 5),
                        _buildLanguageSelector(localization),
                        SizedBox(height: 3),
                        _buildThemeSelector(localization),
                        SizedBox(height: 20),
                      ],
                    ),
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
      color: colorScheme.surfaceContainerHighest,
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
                isBold: true,
                _hasRootAccess ? Colors.green : colorScheme.error),
            _buildStatusRow(
                localization.module_installed,
                _moduleInstalled ? localization.yes : localization.no,
                isBold: true,
                _moduleInstalled ? Colors.green : colorScheme.error),
            _buildStatusRow(localization.module_version, _moduleVersion,
                colorScheme.primary,
                isBold: true, isVersion: true),
            _buildStatusRow(
                localization.mode_status_label,
                _isHamadaAiRunning
                    ? localization.mode_hamada_ai
                    : localization.mode_manual,
                colorScheme.primary,
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
      color: colorScheme.surfaceContainerHighest,
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
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
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
              dropdownColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              underline: Container(),
              iconEnabledColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AppLocalizations localization) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localization.select_theme,
                style: Theme.of(context).textTheme.bodyMedium),
            ToggleButtons(
              isSelected: [
                widget.currentTheme == 'Classic',
                widget.currentTheme == 'Modern',
              ],
              onPressed: (int index) {
                widget.onThemeChange(index == 0 ? 'Classic' : 'Modern');
              },
              borderRadius: BorderRadius.circular(8.0),
              selectedColor: colorScheme.onPrimary,
              fillColor: colorScheme.primary,
              color: colorScheme.onSurfaceVariant,
              constraints: BoxConstraints(minHeight: 32.0, minWidth: 80.0),
              children: <Widget>[
                Text(localization.theme_classic),
                Text(localization.theme_modern),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow(String description, String scriptName,
      String buttonText, IconData modeIcon, String modeKey) {
    final isCurrentMode = _currentMode == modeKey;
    final isExecutingThis = _executingScript == scriptName;
    final isHamadaMode = _isHamadaAiRunning;
    final isInteractable = _hasRootAccess && _moduleInstalled;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isHamadaMode ? 0.6 : 1.0,
      child: Card(
        elevation: 0,
        color: isCurrentMode && !isHamadaMode
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: !isInteractable
              ? null
              : () {
                  if (isHamadaMode) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .please_disable_hamada_ai_first)));
                  } else if (_executingScript.isEmpty) {
                    executeScript(scriptName, modeKey);
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  modeIcon,
                  size: 24,
                  color: isCurrentMode && !isHamadaMode
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buttonText,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isCurrentMode && !isHamadaMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontStyle: isCurrentMode && !isHamadaMode
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  color: isCurrentMode && !isHamadaMode
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isCurrentMode && !isHamadaMode
                                  ? colorScheme.onPrimaryContainer
                                      .withOpacity(0.8)
                                  : colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isCurrentMode && !isHamadaMode
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.primary),
                    ),
                  )
                else if (isCurrentMode && !isHamadaMode)
                  Icon(Icons.check_circle,
                      color: colorScheme.onPrimaryContainer, size: 20)
                else
                  Icon(Icons.arrow_forward_ios,
                      color: colorScheme.onSurface, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
