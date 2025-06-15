import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:async';
import 'languages.dart'; // Import the languages file
import 'package:dynamic_color/dynamic_color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // Needed for File operations (though we use shell commands)

// Import the new utilities page
import 'utilities_page.dart'; //

/// Manages reading and writing configuration settings from/to the encorin.txt file.
class ConfigManager {
  // Path to the combined configuration file
  static const String _configFilePath =
      '/data/adb/modules/EnCorinVest/encorin.txt';
  // Default language code
  static const String _defaultLanguage = 'EN';
  // Default mode
  static const String _defaultMode = 'None';

  /// Reads the configuration file and returns a map containing settings.
  /// Returns default values if the file doesn't exist or is invalid.
  static Future<Map<String, String>> readConfig() async {
    String language = _defaultLanguage;
    String currentMode = _defaultMode;

    try {
      // Use 'su -c cat' to read the file content with root privileges
      var result = await run('su', ['-c', 'cat $_configFilePath'],
          verbose: false); // Added verbose: false

      if (result.exitCode == 0) {
        String content = result.stdout.toString();
        // Split the content into lines
        List<String> lines = content.split('\n');
        // Parse each line for settings
        for (String line in lines) {
          if (line.startsWith('language=')) {
            String value = line.substring('language='.length).trim();
            if (value.isNotEmpty) {
              language =
                  value.toUpperCase(); // Store language code in uppercase
            }
          } else if (line.startsWith('current_mode=')) {
            String value = line.substring('current_mode='.length).trim();
            if (value.isNotEmpty) {
              currentMode = value.toUpperCase(); // Store mode in uppercase
            }
          }
        }
      }
    } catch (e) {
      // Handle errors during file reading (e.g., file not found)
      // Defaults are already set, so we can ignore the error or log it
      print('Error reading config file: $e');
    }

    return {'language': language, 'current_mode': currentMode};
  }

  /// Writes the provided language and mode settings to the configuration file.
  static Future<void> writeConfig(
      {required String language, required String currentMode}) async {
    // Construct the content string in the specified format
    String content = '[EnCorinVest config]\n'
        'language=${language.toUpperCase()}\n' // Ensure uppercase
        'current_mode=${currentMode.toUpperCase()}\n'; // Ensure uppercase

    try {
      // Use 'su -c echo' to write the content to the file with root privileges
      // The outer quotes handle potential spaces, inner quotes are part of the command
      await run('su', ['-c', 'echo "$content" > $_configFilePath'],
          verbose: false); // Added verbose: false
    } catch (e) {
      // Handle errors during file writing
      print('Error writing config file: $e');
      // Optionally, show an error message to the user
    }
  }

  /// Saves only the language setting, preserving the current mode.
  static Future<void> saveLanguage(String languageCode) async {
    var currentConfig = await readConfig();
    await writeConfig(
        language: languageCode, currentMode: currentConfig['current_mode']!);
  }

  /// Saves only the mode setting, preserving the current language.
  static Future<void> saveMode(String mode) async {
    var currentConfig = await readConfig();
    await writeConfig(language: currentConfig['language']!, currentMode: mode);
  }
}

// --- Main Application ---
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Default color schemes for Material 3 theming
  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue);
  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    // Use DynamicColorBuilder to adapt theme colors based on system settings
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightColorScheme;
      ColorScheme darkColorScheme;

      // Use dynamic colors if available, otherwise fall back to defaults
      if (lightDynamic != null && darkDynamic != null) {
        lightColorScheme = lightDynamic.harmonized();
        darkColorScheme = darkDynamic.harmonized();
      } else {
        lightColorScheme = _defaultLightColorScheme;
        darkColorScheme = _defaultDarkColorScheme;
      }

      // Build the main MaterialApp
      return MaterialApp(
        debugShowCheckedModeBanner: false, // Hide the debug banner
        home: MainScreen(), // Set the main screen
        theme: ThemeData(
          // Light theme configuration
          useMaterial3: true,
          colorScheme: lightColorScheme,
        ),
        darkTheme: ThemeData(
          // Dark theme configuration
          useMaterial3: true,
          colorScheme: darkColorScheme,
        ),
        themeMode: ThemeMode.system, // Use system theme mode (light/dark)
      );
    });
  }
}

// --- About Page Widget ---
class AboutPage extends StatefulWidget {
  final String selectedLanguage; // Pass the current language

  AboutPage({required this.selectedLanguage});

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _deviceModel = 'Loading...';
  String _cpuInfo = 'Loading...';
  String _osVersion = 'Loading...';
  bool _isLoading = true; // Flag to show loading indicator

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo(); // Load device info when the page initializes
  }

  // Check for root access specifically for the About page needs
  Future<bool> _checkRootAccessInAbout() async {
    try {
      var result = await run('su', ['-c', 'id'], verbose: false);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // Load device information using shell commands (requires root)
  Future<void> _loadDeviceInfo() async {
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() {
      _isLoading = true;
    });

    bool rootGranted = await _checkRootAccessInAbout();

    String deviceModel = 'N/A';
    String cpuInfo = 'N/A';
    String osVersion = 'N/A';

    if (rootGranted) {
      try {
        // Get device model
        var deviceResult =
            await run('su', ['-c', 'getprop ro.product.model'], verbose: false);
        deviceModel = deviceResult.stdout.toString().trim();
        // Get CPU info (trying different properties)
        var cpuResult = await run('su', ['-c', 'getprop ro.board.platform'],
            verbose: false); // Changed prop for potentially better info
        cpuInfo = cpuResult.stdout.toString().trim();
        if (cpuInfo.isEmpty || cpuInfo.toLowerCase() == 'unknown') {
          cpuResult =
              await run('su', ['-c', 'getprop ro.hardware'], verbose: false);
          cpuInfo = cpuResult.stdout.toString().trim();
        }
        if (cpuInfo.isEmpty || cpuInfo.toLowerCase() == 'unknown') {
          cpuResult = await run(
              'su', ['-c', 'cat /proc/cpuinfo | grep Hardware | cut -d: -f2'],
              verbose: false); // Fallback using /proc/cpuinfo
          cpuInfo = cpuResult.stdout.toString().trim();
        }

        // Get Android OS version
        var osResult = await run(
            'su', ['-c', 'getprop ro.build.version.release'],
            verbose: false);
        osVersion = 'Android ' + osResult.stdout.toString().trim();
      } catch (e) {
        // Handle errors during command execution
        deviceModel = 'Error';
        cpuInfo = 'Error';
        osVersion = 'Error';
        print("Error loading device info: $e");
      }
    } else {
      // Indicate that root is required if not granted
      deviceModel = 'Root Required';
      cpuInfo = 'Root Required';
      osVersion = 'Root Required';
    }

    // Update the state with the loaded information
    if (mounted) {
      setState(() {
        _deviceModel = deviceModel.isEmpty ? 'N/A' : deviceModel;
        _cpuInfo = cpuInfo.isEmpty ? 'N/A' : cpuInfo;
        _osVersion = osVersion.isEmpty ? 'N/A' : osVersion;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get localization instance based on the passed language
    final localization = AppLocalizations(widget.selectedLanguage);
    // List of credit keys for translation
    final List<String> credits = [
      'credits_1', //
      'credits_2', //
      'credits_3', //
      'credits_5', //
      'credits_6', //
      'credits_7', //
      'credits_8' //
    ];

    return Scaffold(
      appBar: AppBar(), // Simple back button AppBar
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : SingleChildScrollView(
                // Allow scrolling if content overflows
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Device Information Section
                    Card(
                      // Use a Card for better visual grouping
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(localization.translate('device'),
                                _deviceModel), //
                            _buildInfoRow(
                                localization.translate('cpu'), _cpuInfo), //
                            _buildInfoRow(
                                localization.translate('os'), _osVersion), //
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Credits Section
                    Text(
                      localization.translate('about_title'), //
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                    SizedBox(height: 15),
                    // Display credits list
                    ...credits.map((creditKey) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '• ${localization.translate(creditKey)}', //
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )),
                    SizedBox(height: 20),

                    // Note and Quote Section
                    Text(
                      localization.translate('about_note'), //
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 20),
                    Center(
                      // Center the quote
                      child: Text(
                        localization.translate('about_quote'), //
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // Helper widget to build a row for device information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
              overflow:
                  TextOverflow.ellipsis, // Prevent long text from overflowing
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main Screen Widget ---
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // State variables
  bool _hasRootAccess = false;
  bool _moduleInstalled = false;
  String _moduleVersion = 'Unknown';
  String _currentMode = 'None'; // Now read from config
  String _selectedLanguage = 'EN'; // Now read from config
  String _executingScript = ''; // Track currently executing script
  bool _isLoading = true; // Flag for initial loading state

  @override
  void initState() {
    super.initState();
    _initializeState(); // Initialize the app state when the widget is created
  }

  // Initializes the application state by checking root, loading config, etc.
  Future<void> _initializeState() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // 1. Check for root access first
    bool rootGranted = await _checkRootAccess();

    if (rootGranted) {
      // 2. If root granted, read the combined config file
      var config = await ConfigManager.readConfig();
      if (mounted) {
        setState(() {
          _selectedLanguage =
              config['language'] ?? ConfigManager._defaultLanguage;
          _currentMode = config['current_mode'] ?? ConfigManager._defaultMode;
        });
      }

      // 3. Check if the module is installed
      await _checkModuleInstalled();

      // 4. If module installed, get its version
      if (_moduleInstalled) {
        await _getModuleVersion();
      } else {
        if (mounted) {
          setState(() {
            _moduleVersion = 'N/A';
          });
        }
      }
    } else {
      // If no root, set default/error states
      if (mounted) {
        setState(() {
          _moduleInstalled = false;
          _moduleVersion = 'Root Required';
          _currentMode = 'Root Required';
          _selectedLanguage =
              ConfigManager._defaultLanguage; // Keep default language
        });
      }
    }

    // 5. Mark loading as complete
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Checks if root access is available
  Future<bool> _checkRootAccess() async {
    bool hasAccess = false;
    try {
      var result = await run('su', ['-c', 'id'], verbose: false);
      hasAccess = result.exitCode == 0;
    } catch (e) {
      hasAccess = false;
      print("Error checking root access: $e");
    }
    if (mounted) {
      setState(() {
        _hasRootAccess = hasAccess;
      });
    }
    return hasAccess;
  }

  // Checks if the EnCorinVest Magisk module directory exists
  Future<void> _checkModuleInstalled() async {
    if (!_hasRootAccess) return;
    bool installed = false;
    try {
      // Check for the existence of the module directory
      var result = await run(
          'su', ['-c', 'test -d /data/adb/modules/EnCorinVest && echo "yes"'],
          verbose: false);
      installed = result.stdout.toString().trim() == 'yes';
    } catch (e) {
      installed = false;
      print("Error checking module installation: $e");
    }
    if (mounted) {
      setState(() {
        _moduleInstalled = installed;
      });
    }
  }

  // Reads the module version from the module.prop file
  Future<void> _getModuleVersion() async {
    if (!_hasRootAccess || !_moduleInstalled) return; // Need root and module
    String version = 'Unknown';
    try {
      // Grep the version line from module.prop
      var result = await run('su',
          ['-c', 'grep "^version=" /data/adb/modules/EnCorinVest/module.prop'],
          verbose: false);
      String line = result.stdout.toString().trim();
      // Extract the version value
      if (line.contains('=')) {
        version = line.split('=')[1].trim();
      }
    } catch (e) {
      version = 'Error';
      print("Error getting module version: $e");
    }
    if (mounted) {
      setState(() {
        _moduleVersion = version.isNotEmpty ? version : 'Unknown';
      });
    }
  }

  // Executes a profile script (e.g., powersafe.sh, balanced.sh)
  Future<void> executeScript(String scriptName, String buttonText) async {
    // Prevent execution if no root, module not installed, or another script is running
    if (!_hasRootAccess || !_moduleInstalled || _executingScript.isNotEmpty)
      return;

    String targetMode = buttonText.toUpperCase();
    // Special case: 'Clear' doesn't set a persistent mode, it resets to 'None' after execution
    if (targetMode == localization.translate('clear').toUpperCase()) {
      targetMode = 'None'; // The mode to save *after* execution
    }

    if (mounted) {
      setState(() {
        _executingScript = scriptName; // Mark script as executing
        // Optimistically update UI for modes other than 'Clear'
        if (buttonText.toUpperCase() !=
            localization.translate('clear').toUpperCase()) {
          _currentMode = buttonText.toUpperCase();
        }
      });
    }

    try {
      // 1. Save the *target* mode to the config file *before* running the script
      //    (unless it's the 'clear' action)
      if (buttonText.toUpperCase() !=
          localization.translate('clear').toUpperCase()) {
        await ConfigManager.saveMode(buttonText.toUpperCase());
      }

      // 2. Execute the script using 'su -c'
      var result = await run(
          'su', ['-c', '/data/adb/modules/EnCorinVest/Scripts/$scriptName'],
          verbose: false); // Execute the script

      // 3. Handle script result (optional: check result.exitCode)
      if (result.exitCode != 0) {
        print("Script $scriptName exited with code ${result.exitCode}");
        // Optionally show an error message to the user
        // Revert optimistic UI update if needed, or reload state fully
        await _refreshStateFromConfig(); // Reload state on error
      } else {
        // If it was the 'clear' script, explicitly save 'None' as the mode now
        if (buttonText.toUpperCase() ==
            localization.translate('clear').toUpperCase()) {
          await ConfigManager.saveMode('None');
          if (mounted) {
            setState(() {
              _currentMode = 'None';
            }); // Update UI for clear
          }
        }
        // For other scripts, the mode was already saved, UI updated optimistically.
      }
    } catch (e) {
      print("Error executing script $scriptName: $e");
      // Handle errors, maybe show a message, and refresh state
      await _refreshStateFromConfig(); // Reload state on error
    } finally {
      // 4. Always clear the executing script flag and potentially refresh state
      if (mounted) {
        setState(() {
          _executingScript = '';
        }); // Mark script as finished
        // Optionally, refresh state again to be absolutely sure,
        // though optimistic updates and error handling might cover it.
        // await _refreshStateFromConfig();
      }
    }
  }

  // Helper to reload language and mode from the config file and update UI
  Future<void> _refreshStateFromConfig() async {
    if (!_hasRootAccess) return; // Cannot refresh without root
    var config = await ConfigManager.readConfig();
    if (mounted) {
      setState(() {
        _selectedLanguage =
            config['language'] ?? ConfigManager._defaultLanguage;
        _currentMode = config['current_mode'] ?? ConfigManager._defaultMode;
      });
    }
  }

// Changes the application language and saves it to the config file
  void _changeLanguage(String language) {
    if (language == _selectedLanguage) return; // No change needed

    if (mounted) {
      setState(() {
        _selectedLanguage = language.toUpperCase(); // Update only the language
        // Do not reset _currentMode or HamadaAI state
      });
    }
    // Save the new language using ConfigManager
    ConfigManager.saveLanguage(language.toUpperCase());
  }

  // Function to launch URLs in an external application
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      print("Error launching URL $url: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching $url')),
        );
      }
    }
  }

  // Navigates to the About page
  void _navigateToAboutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutPage(
            selectedLanguage: _selectedLanguage), // Pass current language
      ),
    );
  }

  // *** UPDATED: Navigates to the Utilities page ***
  void _navigateToUtilitiesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the currently selected language
        builder: (context) => UtilitiesPage(
            selectedLanguage: _selectedLanguage), // <-- Passed language state
      ),
    );
  }

  // Instance of AppLocalizations for the current build context
  late AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    // Initialize localization for the current selected language
    localization = AppLocalizations(_selectedLanguage);
    // Get the current color scheme
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Ensure content is within safe areas (avoids notches, etc.)
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator()) // Show loading indicator
              : SingleChildScrollView(
                  // Make content scrollable
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Social Links Header
                      _buildTitleHeader(colorScheme, localization),
                      SizedBox(height: 16),
                      // Status Info and Utilities Box Row
                      _buildHeaderRow(localization), // Pass localization
                      SizedBox(height: 10), // Spacing

                      // Mode Control Rows (using Cards for better styling)
                      _buildControlRow(
                          localization.translate('power_save_desc'), //
                          'powersafe.sh', // Script name
                          localization.translate('power_save'), // Button text
                          Icons.battery_saver, // Icon
                          colorScheme
                              .primaryContainer, // Background (not directly used on button)
                          colorScheme
                              .onPrimaryContainer), // Foreground (not directly used on button)
                      _buildControlRow(
                          localization.translate('balanced_desc'), //
                          'balanced.sh', //
                          localization.translate('balanced'), //
                          Icons.balance, //
                          colorScheme.secondaryContainer, //
                          colorScheme.onSecondaryContainer), //
                      _buildControlRow(
                          localization.translate('performance_desc'), //
                          'performance.sh', //
                          localization.translate('performance'), //
                          Icons.speed, //
                          colorScheme.tertiaryContainer, //
                          colorScheme.onTertiaryContainer), //
                      _buildControlRow(
                          localization.translate('gaming_desc'), //
                          'game.sh', //
                          localization.translate('gaming_pro'), //
                          Icons.sports_esports, //
                          colorScheme
                              .errorContainer, // Use error colors for emphasis
                          colorScheme.onErrorContainer), //
                      _buildControlRow(
                          localization.translate('cooldown_desc'), //
                          'cool.sh', //
                          localization.translate('cooldown'), //
                          Icons.ac_unit, //
                          colorScheme.surfaceVariant, // Neutral colors
                          colorScheme.onSurfaceVariant), //
                      _buildControlRow(
                          localization.translate('clear_desc'), //
                          'kill.sh', //
                          localization.translate('clear'), //
                          Icons.clear_all, //
                          colorScheme.error, // Use error colors for emphasis
                          colorScheme.onError), //

                      SizedBox(height: 25), // Spacing before language selector
                      // Language Selector Row
                      _buildLanguageSelector(localization),
                      SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Builds the top header with title, author, and social links
  Widget _buildTitleHeader(
      ColorScheme colorScheme, AppLocalizations localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space items apart
      children: [
        // Title and Author (Clickable Title)
        Expanded(
          // Allow title section to take available space
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Make the title tappable to navigate to About page
              InkWell(
                onTap: _navigateToAboutPage,
                child: Text(
                  localization.translate('app_title'), // Use translated title
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        // Slightly larger title
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),
              Text(
                localization.translate('by'), // Use translated author line
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        // Social Media Icons Row
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.telegram,
                  color: colorScheme.primary), // Telegram icon
              onPressed: () =>
                  _launchURL('https://t.me/KLAGen2'), // Launch Telegram URL
              tooltip: 'Telegram', // Tooltip for accessibility
            ),
            IconButton(
              icon: Icon(Icons.code,
                  color: colorScheme.primary), // Changed to GitHub/Code icon
              onPressed: () => _launchURL(
                  'https://github.com/LoggingNewMemory/EnCorinVest'), // Launch GitHub URL (replace if needed)
              tooltip: 'GitHub', // Tooltip
            ),
          ],
        ),
      ],
    );
  }

  // Builds the row containing status info and the utilities box
  Widget _buildHeaderRow(AppLocalizations localization) {
    // Accept localization
    return IntrinsicHeight(
      // Ensures children in the Row have the same height
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Stretch children vertically
        children: [
          // Status Information Box (takes more space)
          Expanded(
            flex: 3, // Give more space to status info
            child: _buildStatusInfo(localization), // Pass localization
          ),
          SizedBox(width: 10), // Spacing between boxes
          // Utilities Box (takes less space)
          Expanded(
            flex: 2, // Give less space to utilities box
            // Wrap Utilities Box with InkWell for navigation
            child: InkWell(
              onTap: _navigateToUtilitiesPage, // Navigate on tap
              borderRadius: BorderRadius.circular(12), // Match card shape
              child: _buildUtilitiesBox(
                  localization), // Build the original box content & Pass localization
            ),
          ),
        ],
      ),
    );
  }

  // Builds the card displaying status information (Root, Module, Version, Mode)
  Widget _buildStatusInfo(AppLocalizations localization) {
    // Accept localization
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0, // Flat design
      color: colorScheme.surfaceVariant, // Use surface variant color
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: EdgeInsets.all(12), // Internal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          mainAxisSize: MainAxisSize.min, // Adjust height to content
          children: [
            // Display Root Access status
            _buildStatusRow(
                localization.translate('root_access'), //
                _hasRootAccess
                    ? localization.translate('yes') //
                    : localization.translate('no'), // Use translated Yes/No
                _hasRootAccess
                    ? Colors.green
                    : colorScheme.error), // Green for Yes, Error color for No
            // Display Module Installed status
            _buildStatusRow(
                localization.translate('module_installed'), //
                _moduleInstalled
                    ? localization.translate('yes') //
                    : localization.translate('no'), // Use translated Yes/No
                _moduleInstalled
                    ? Colors.green
                    : colorScheme.error), // Green for Yes, Error color for No
            // Display Module Version
            _buildStatusRow(
                localization.translate('module_version'), //
                _moduleVersion,
                colorScheme.onSurfaceVariant, // Normal text color
                isVersion: true), // Flag for potential ellipsis
            // Display Current Mode
            _buildStatusRow(
                localization.translate('current_mode'), //
                _currentMode.toUpperCase(), // Ensure mode is uppercase
                colorScheme.primary, // Use primary color for mode
                isBold: true), // Make the mode bold
          ],
        ),
      ),
    );
  }

  // Helper widget to build a single row within the status info card
  Widget _buildStatusRow(String label, String value, Color valueColor,
      {bool isBold = false, bool isVersion = false}) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 2.0), // Small vertical padding
      child: Row(
        children: [
          // Label text
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant)), // Label style
          SizedBox(width: 5), // Spacing between label and value
          // Value text (expandable)
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor, // Use the provided value color
                    fontWeight: isBold
                        ? FontWeight.bold
                        : FontWeight.normal, // Apply bold if requested
                  ),
              overflow: isVersion
                  ? TextOverflow.ellipsis
                  : TextOverflow.fade, // Ellipsis for version, fade otherwise
              softWrap: !isVersion, // Allow wrapping for non-version text
              maxLines: 1, // Limit to one line
            ),
          ),
        ],
      ),
    );
  }

  // Builds the card representing the "Utilities" section
  Widget _buildUtilitiesBox(AppLocalizations localization) {
    // Accept localization
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0, // Flat design
      color: colorScheme.surfaceVariant, // Use surface variant color
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Center(
        // Center the content within the card
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Internal padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: [
              // Settings icon
              Icon(
                Icons
                    .construction, // Changed icon to represent 'Utilities'/'Tools'
                size: 30,
                color: colorScheme.primary,
              ),
              SizedBox(height: 10), // Spacing
              // Title text
              Text(
                localization.translate('app_title'), // Use translated app title
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4), // Spacing
              // Subtitle text
              Text(
                localization.translate(
                    'utilities'), // Use translated 'Utilities' or default
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
              ),
              // *** REMOVED: Arrow icon Padding widget ***
            ],
          ),
        ),
      ),
    );
  }

  // Builds the language selection dropdown row
  Widget _buildLanguageSelector(AppLocalizations localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space items apart
      children: [
        // Label text
        Text(
          localization.translate('select_language'), //
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // Dropdown button
        DropdownButton<String>(
          value: _selectedLanguage, // Current selected language
          // Available language options
          items: <String>['EN', 'ID', 'JP', 'JV'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          // Callback when a new language is selected
          onChanged: (String? newValue) {
            if (newValue != null) {
              _changeLanguage(newValue); // Call the change language function
            }
          },
          // Styling for the dropdown
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary), // Text color
          dropdownColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest, // Background color of dropdown menu
          underline: Container(
              // Custom underline
              height: 1,
              color: Theme.of(context).colorScheme.primary),
          iconEnabledColor: Theme.of(context)
              .colorScheme
              .primary, // Color of the dropdown arrow
        ),
      ],
    );
  }

  // Builds a single control row (Card) for applying a mode/script
  Widget _buildControlRow(
      String description,
      String scriptName,
      String buttonText,
      IconData modeIcon,
      Color backgroundColor,
      Color foregroundColor) {
    bool isCurrentMode = _currentMode ==
        buttonText.toUpperCase(); // Check if this is the active mode
    bool isExecutingThis =
        _executingScript == scriptName; // Check if this script is running
    // Determine if the button should be enabled
    bool canExecute =
        _hasRootAccess && _moduleInstalled && _executingScript.isEmpty;
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0, // Flat design
      // Use primary container color if this is the current mode, otherwise surface variant
      color: isCurrentMode
          ? colorScheme.primaryContainer
          : colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Rounded corners
      margin: EdgeInsets.only(bottom: 10), // Spacing below the card
      child: InkWell(
        // Make the card tappable
        // Only allow tap if execution is possible
        onTap: canExecute ? () => executeScript(scriptName, buttonText) : null,
        borderRadius: BorderRadius.circular(12), // Match card's border radius
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Padding inside the card
          child: Row(
            children: [
              // Icon for the mode
              Icon(
                modeIcon,
                size: 24,
                // Use primary color if current mode, otherwise default onSurfaceVariant
                color: isCurrentMode
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 16), // Spacing between icon and text
              // Text content (Title and Description)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Title Text
                    Text(
                      buttonText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            // Bold and italic if current mode
                            fontWeight: isCurrentMode
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontStyle: isCurrentMode
                                ? FontStyle.italic
                                : FontStyle.normal,
                            // Adjust text color based on current mode status
                            color: isCurrentMode
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                    SizedBox(
                        height: 4), // Spacing between title and description
                    // Mode Description Text
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            // Adjust text color based on current mode status
                            color: isCurrentMode
                                ? colorScheme.onPrimaryContainer
                                    .withOpacity(0.8)
                                : colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                      maxLines: 2, // Limit description lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Indicator section (Spinner or Check/Arrow)
              SizedBox(width: 10), // Spacing before indicator
              // Show spinner if this script is executing
              if (isExecutingThis)
                SizedBox(
                  // Constrain spinner size
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // Use appropriate color based on card background
                    valueColor: AlwaysStoppedAnimation<Color>(isCurrentMode
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.primary),
                  ),
                )
              // Show checkmark if this is the current mode (and not executing)
              else if (isCurrentMode)
                Icon(
                  Icons.check_circle,
                  color: colorScheme
                      .onPrimaryContainer, // Use color matching the card background
                  size: 20,
                )
              // Show arrow otherwise (indicating tappable action)
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurfaceVariant, // Default arrow color
                  size: 16, // Slightly smaller arrow
                ),
            ],
          ),
        ),
      ),
    );
  }
}
