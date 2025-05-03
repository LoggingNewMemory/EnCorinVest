import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Import for base64 encoding
import 'languages.dart'; // Ensure this import points to your languages file

class UtilitiesPage extends StatefulWidget {
  final String selectedLanguage;
  const UtilitiesPage({Key? key, required this.selectedLanguage})
      : super(key: key);

  @override
  _UtilitiesPageState createState() => _UtilitiesPageState();
}

class _UtilitiesPageState extends State<UtilitiesPage> {
  // --- File Paths & Commands ---
  final String _serviceFilePath = '/data/adb/modules/EnCorinVest/service.sh';
  final String _gameTxtPath = '/data/adb/modules/EnCorinVest/game.txt';
  // --- Path to the config file ---
  final String _configFilePath = '/data/adb/modules/EnCorinVest/encorin.txt';
  final String _hamadaMarker = '# Start HamadaAI (Default is Disabled)';
  final String _hamadaProcessName =
      'HamadaAI'; // Process name for start/kill/check
  final String _hamadaStartCommand = 'HamadaAI'; // Command to start
  final String _hamadaStopCommand = 'killall HamadaAI'; // Command to stop
  final String _hamadaCheckCommand =
      'pgrep -x HamadaAI'; // Command to check if running

  // --- UI state ---
  bool _hamadaAiEnabled = false; // State reflecting the config file
  bool _hamadaStartOnBoot = false; // State for the boot toggle
  bool _isHamadaCommandRunning = false; // Loading indicator for start/stop
  bool _isServiceFileUpdating =
      false; // Loading indicator for boot toggle update
  bool _isConfigUpdating = false; // Loading indicator for config update
  bool _resolutionServiceAvailable = false;
  bool _isResolutionChanging = false;
  double _resolutionValue = 5.0; // Default index corresponds to 100%
  bool _isGameTxtLoading = false;
  bool _isGameTxtSaving = false;
  String _gameTxtContent = ''; // Content of game.txt
  final TextEditingController _gameTxtController = TextEditingController();

  // --- Original values (fetched once if service is available) ---
  String _originalSize = '';
  int _originalDensity = 0;

  // --- Resolution percentages mapped to slider values (0 to 5) ---
  final List<int> _resolutionPercentages = [50, 60, 70, 80, 90, 100];

  late AppLocalizations _localization; // Initialize localization here

  @override
  void initState() {
    super.initState();
    _localization =
        AppLocalizations(widget.selectedLanguage); // Instantiate localization
    // --- UPDATED: Read config first, then check process ---
    _readAndApplyHamadaConfig();
    _checkResolutionServiceAvailability();
    _checkHamadaStartOnBoot();
    _loadGameTxt();
  }

  // --- Utility Functions ---

  // --- REMOVED _showSnackbar function ---
  // void _showSnackbar(String messageKey,
  //     {bool isError = false, Map<String, String>? args}) {
  //   if (!mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(_localization.translate(messageKey, args: args)),
  //       backgroundColor: isError ? Colors.red : null,
  //       duration: Duration(seconds: 3),
  //     ),
  //   );
  // }

  Future<ProcessResult> _runRootCommandAndWait(String command) async {
    print('Executing root command (and waiting): $command');
    try {
      return await Process.run('su', ['-c', command]);
    } catch (e) {
      print('Error running root command "$command": $e');
      // --- REMOVED Snackbar ---
      // if (mounted)
      //   _showSnackbar('command_failed',
      //       isError: true, args: {'command': command});
      return ProcessResult(0, -1, '', 'Execution failed: $e');
    }
  }

  Future<void> _runRootCommandFireAndForget(String command) async {
    print('Executing root command (fire and forget): $command');
    try {
      await Process.start('su', ['-c', '$command &'],
          runInShell: true, mode: ProcessStartMode.detached);
    } catch (e) {
      print('Error starting root command "$command": $e');
      // --- REMOVED Snackbar ---
      // if (mounted)
      //   _showSnackbar('command_failed',
      //       isError: true, args: {'command': command});
    }
  }

  Future<bool> _checkRootAccess() async {
    try {
      final result = await _runRootCommandAndWait('id');
      if (result.exitCode == 0 && result.stdout.toString().contains('uid=0')) {
        return true;
      } else {
        // --- REMOVED Snackbar ---
        // if (mounted) _showSnackbar('error_no_root', isError: true);
        print('Root access check failed or not granted.');
        return false;
      }
    } catch (e) {
      // --- REMOVED Snackbar ---
      // if (mounted) _showSnackbar('error_no_root', isError: true);
      print('Error checking root access: $e');
      return false;
    }
  }

  // --- Hamada AI Logic ---

  Future<bool?> _readHamadaConfig() async {
    if (!await _checkRootAccess()) return null;
    print("Reading HamadaAI config from $_configFilePath");
    final result = await _runRootCommandAndWait('cat $_configFilePath');
    if (result.exitCode == 0) {
      try {
        final content = result.stdout.toString();
        final lines = content.split('\n');
        for (var line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.toLowerCase().startsWith('hamadaai=')) {
            final value = trimmedLine.split('=')[1].trim().toLowerCase();
            print("Found config value: $value");
            return value == 'true';
          }
        }
        print("HamadaAI setting not found in config file.");
        return null; // Setting not found
      } catch (e) {
        print("Error parsing config file: $e");
        return null; // Error parsing
      }
    } else {
      print(
          "Error reading config file: Exit code ${result.exitCode}, Stderr: ${result.stderr}");
      // --- REMOVED Snackbar ---
      // if (mounted)
      //   _showSnackbar('file_read_failed',
      //       isError: true, args: {'file': _configFilePath});
      return null; // Error reading file
    }
  }

  Future<bool> _writeHamadaConfig(bool enabled) async {
    if (!await _checkRootAccess() || !mounted) return false;

    setState(() => _isConfigUpdating = true);
    // --- REMOVED Snackbar ---
    // _showSnackbar('updating_config_file'); // Add localization key
    print("Writing HamadaAI=$enabled to $_configFilePath");

    final valueString = enabled ? 'true' : 'false';
    final sedCommand =
        '''sed -i -e 's#^HamadaAI=.*#HamadaAI=$valueString#' -e t -e '\$aHamadaAI=$valueString' $_configFilePath''';

    try {
      final result = await _runRootCommandAndWait(sedCommand);

      if (result.exitCode == 0) {
        print("Config file update successful.");
        // --- REMOVED Snackbar ---
        // _showSnackbar('config_file_updated'); // Add localization key
        if (mounted) setState(() => _hamadaAiEnabled = enabled);
        return true;
      } else {
        print(
            'Config file update failed. Exit Code: ${result.exitCode}, Stderr: ${result.stderr}');
        // --- REMOVED Snackbar ---
        // if (mounted)
        //   _showSnackbar('config_file_update_failed', isError: true); // Add localization key
        return false;
      }
    } catch (e) {
      print('Error updating config file: $e');
      // --- REMOVED Snackbar ---
      // if (mounted)
      //   _showSnackbar('config_file_update_failed', isError: true); // Add localization key
      return false;
    } finally {
      if (mounted) setState(() => _isConfigUpdating = false);
    }
  }

  Future<void> _readAndApplyHamadaConfig() async {
    bool? configState = await _readHamadaConfig();

    if (mounted) {
      setState(() {
        _hamadaAiEnabled = configState ?? false;
        print("Initial Hamada AI state from config: $_hamadaAiEnabled");
      });
      await _verifyHamadaProcessStatus();
    }
  }

  Future<void> _verifyHamadaProcessStatus() async {
    if (!await _checkRootAccess()) return;
    final result = await _runRootCommandAndWait(_hamadaCheckCommand);
    bool isRunning = result.exitCode == 0;
    print("Actual Hamada AI process running state: $isRunning");

    if (mounted && _hamadaAiEnabled != isRunning) {
      print(
          "Warning: Hamada AI config state ($_hamadaAiEnabled) mismatches running state ($isRunning).");
    }
  }

  Future<void> _toggleHamadaAI(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    if (_isConfigUpdating) return;

    setState(() => _isHamadaCommandRunning = true);
    final commandToRun = enable ? _hamadaStartCommand : _hamadaStopCommand;
    final actionKey = enable ? 'Starting' : 'Stopping';

    // --- REMOVED Snackbar ---
    // _showSnackbar('executing_command');
    print('$actionKey Hamada AI...');

    bool commandSuccess = false;
    try {
      if (enable) {
        await _runRootCommandFireAndForget(commandToRun);
        commandSuccess = true; // Assume success for fire-and-forget
        if (mounted) {
          // --- REMOVED Snackbar ---
          // _showSnackbar('Command executed'); // More specific key?
          print('Start command executed.');
        }
      } else {
        final result = await _runRootCommandAndWait(commandToRun);
        commandSuccess = result.exitCode == 0;
        if (mounted) {
          // --- REMOVED Snackbar ---
          // _showSnackbar('Command executed'); // More specific key?
          print(
              'Killall result: Exit Code ${result.exitCode}, Stderr: ${result.stderr}');
          if (!commandSuccess) {
            print("Failed to stop Hamada AI process.");
          } else {
            print("Stop command executed successfully.");
          }
        }
      }

      if (commandSuccess) {
        bool configWritten = await _writeHamadaConfig(enable);
        if (!configWritten && mounted) {
          // --- REMOVED Snackbar ---
          // _showSnackbar('config_write_failed_after_command', isError: true); // Add localization key
          print("Error: Config write failed after command execution.");
        } else if (configWritten && mounted) {
          print("Hamada AI state and config updated to $enable");
        }
      } else {
        if (mounted) {
          // --- REMOVED Snackbar ---
          // _showSnackbar('command_failed',
          //     isError: true, args: {'command': commandToRun});
          print("Error: Command execution failed for $commandToRun");
        }
      }
    } catch (e) {
      print('Error $actionKey Hamada AI: $e');
      if (mounted) {
        // --- REMOVED Snackbar ---
        // _showSnackbar('command_failed',
        //     isError: true, args: {'command': commandToRun});
      }
    } finally {
      if (mounted) setState(() => _isHamadaCommandRunning = false);
    }
  }

  Future<void> _checkHamadaStartOnBoot() async {
    if (!await _checkRootAccess()) return;
    final result = await _runRootCommandAndWait('cat $_serviceFilePath');
    try {
      if (result.exitCode == 0) {
        final content = result.stdout.toString();
        final markerIndex = content.indexOf(_hamadaMarker);
        bool found = false;
        if (markerIndex != -1) {
          final subsequentLines = content.substring(markerIndex).split('\n');
          for (String line in subsequentLines.skip(1)) {
            final trimmedLine = line.trim();
            if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
              found = trimmedLine == _hamadaProcessName ||
                  trimmedLine == _hamadaStartCommand;
              break;
            }
          }
        }
        if (mounted) setState(() => _hamadaStartOnBoot = found);
      } else {
        if (mounted) setState(() => _hamadaStartOnBoot = false);
      }
    } catch (e) {
      if (mounted) setState(() => _hamadaStartOnBoot = false);
    }
  }

  Future<void> _setHamadaStartOnBoot(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;

    setState(() => _isServiceFileUpdating = true);
    // --- REMOVED Snackbar ---
    // _showSnackbar('writing_service_file');
    print('Writing service file...');

    try {
      final readResult = await _runRootCommandAndWait('cat $_serviceFilePath');
      if (readResult.exitCode != 0) {
        throw Exception('Failed read: ${readResult.stderr}');
      }
      String content = readResult.stdout.toString();
      List<String> lines = content.replaceAll('\r\n', '\n').split('\n');

      if (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }

      int markerIndex =
          lines.indexWhere((line) => line.contains(_hamadaMarker));
      if (markerIndex == -1) {
        throw Exception('Marker "$_hamadaMarker" not found.');
      }

      int commandLineIndex = -1;
      for (int i = markerIndex + 1; i < lines.length; i++) {
        final trimmedLine = lines[i].trim();
        if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
          if (trimmedLine == _hamadaProcessName ||
              trimmedLine == _hamadaStartCommand) commandLineIndex = i;
          break;
        }
      }
      if (commandLineIndex != -1) lines.removeAt(commandLineIndex);

      if (enable) lines.insert(markerIndex + 1, _hamadaStartCommand);

      String newContent = lines.join('\n') + '\n';
      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd =
          '''echo '$base64Content' | base64 -d > $_serviceFilePath''';

      print("Attempting to write service file...");
      final writeResult = await _runRootCommandAndWait(writeCmd);

      if (writeResult.exitCode != 0) {
        print('Write failed. Exit Code: ${writeResult.exitCode}');
        print('Stderr: ${writeResult.stderr}');
        print('Stdout: ${writeResult.stdout}');
        throw Exception('Failed write: ${writeResult.stderr}');
      }

      if (mounted) setState(() => _hamadaStartOnBoot = enable);
      // --- REMOVED Snackbar ---
      // _showSnackbar('service_file_updated');
      print("Service file write successful.");
    } catch (e) {
      print('Error updating service file: $e');
      // --- REMOVED Snackbar ---
      // if (mounted) _showSnackbar('service_file_update_failed', isError: true);
      if (mounted)
        setState(() => _hamadaStartOnBoot = !enable); // Revert visual state
    } finally {
      if (mounted) setState(() => _isServiceFileUpdating = false);
    }
  }

  Future<void> _checkResolutionServiceAvailability() async {
    bool canGetSize = false;
    bool canGetDensity = false;
    try {
      final sr = await _runRootCommandAndWait('wm size');
      if (sr.exitCode == 0 && sr.stdout.toString().contains('Physical size:'))
        canGetSize = true;
      final dr = await _runRootCommandAndWait('wm density');
      if (dr.exitCode == 0 &&
          (dr.stdout.toString().contains('Physical density:') ||
              dr.stdout.toString().contains('Override density:')))
        canGetDensity = true;
      if (mounted)
        setState(
            () => _resolutionServiceAvailable = canGetSize && canGetDensity);
      if (_resolutionServiceAvailable) {
        await _saveOriginalResolution();
        if (mounted)
          setState(() => _resolutionValue =
              (_resolutionPercentages.length - 1).toDouble());
      }
    } catch (e) {
      print('Error checking resolution service availability: $e');
      if (mounted) setState(() => _resolutionServiceAvailable = false);
    }
  }

  Future<void> _saveOriginalResolution() async {
    if (!_resolutionServiceAvailable) return;
    try {
      final sr = await _runRootCommandAndWait('wm size');
      final sm = RegExp(r'Physical size:\s*([0-9]+x[0-9]+)')
          .firstMatch(sr.stdout.toString());
      if (sm != null && sm.group(1) != null)
        _originalSize = sm.group(1)!;
      else {
        print("Failed to parse original screen size.");
        if (mounted) setState(() => _resolutionServiceAvailable = false);
        return;
      }
      final dr = await _runRootCommandAndWait('wm density');
      final dm = RegExp(r'(?:Physical|Override) density:\s*([0-9]+)')
          .firstMatch(dr.stdout.toString());
      if (dm != null && dm.group(1) != null) {
        _originalDensity = int.tryParse(dm.group(1)!) ?? 0;
        if (_originalDensity == 0) {
          print("Failed to parse original screen density or density is zero.");
          if (mounted) setState(() => _resolutionServiceAvailable = false);
        }
      } else {
        print("Failed to parse original screen density.");
        if (mounted) setState(() => _resolutionServiceAvailable = false);
      }
      print(
          "Original resolution saved: $_originalSize @ ${_originalDensity}dpi");
    } catch (e) {
      print("Error saving original resolution: $e");
      if (mounted) setState(() => _resolutionServiceAvailable = false);
    }
  }

  String _getCurrentPercentageLabel() {
    int idx =
        _resolutionValue.round().clamp(0, _resolutionPercentages.length - 1);
    return '${_resolutionPercentages[idx]}%';
  }

  Future<void> _applyResolution(double value) async {
    if (!_resolutionServiceAvailable ||
        _originalSize.isEmpty ||
        _originalDensity <= 0) {
      // --- REMOVED Snackbar ---
      // _showSnackbar('Resolution change unavailable.', isError: true);
      print(
          'Resolution change unavailable. Service not available or original values missing.');
      if (mounted)
        setState(() =>
            _resolutionValue = (_resolutionPercentages.length - 1).toDouble());
      return;
    }
    if (mounted) setState(() => _isResolutionChanging = true);
    final idx = value.round().clamp(0, _resolutionPercentages.length - 1);
    final pct = _resolutionPercentages[idx];
    print("Applying resolution: $pct%");
    try {
      final parts = _originalSize.split('x');
      final origW = int.tryParse(parts[0]);
      final origH = int.tryParse(parts[1]);
      if (parts.length != 2 ||
          origW == null ||
          origH == null ||
          origW <= 0 ||
          origH <= 0)
        throw FormatException('Invalid original size format: $_originalSize');
      final newW = (origW * pct / 100).floor();
      final newH = (origH * pct / 100).floor();
      final newD = (_originalDensity * pct / 100).floor();
      if (newW <= 0 || newH <= 0 || newD <= 0)
        throw FormatException(
            'Calculated zero/negative dimensions or density. W:$newW, H:$newH, D:$newD');

      print("Calculated new resolution: ${newW}x${newH} @ ${newD}dpi");

      final sr = await _runRootCommandAndWait('wm size ${newW}x${newH}');
      if (sr.exitCode != 0) throw Exception('Set size failed: ${sr.stderr}');
      final dr = await _runRootCommandAndWait('wm density $newD');
      if (dr.exitCode != 0) {
        print("Set density failed, attempting to reset size...");
        await _runRootCommandAndWait(
            'wm size reset'); // Attempt to revert size if density fails
        throw Exception('Set density failed: ${dr.stderr}');
      }
      if (mounted) setState(() => _resolutionValue = value);
      // --- REMOVED Snackbar ---
      // _showSnackbar('Resolution set to $pct%'); // Add localization key
      print('Resolution successfully set to $pct%');
    } catch (e) {
      // --- REMOVED Snackbar ---
      // _showSnackbar('Error changing resolution: ${e.toString()}',
      //     isError: true);
      print('Error changing resolution: ${e.toString()}');
      await _resetResolution(showSnackbar: false); // Attempt reset on error
      if (mounted)
        setState(() => _resolutionValue =
            (_resolutionPercentages.length - 1).toDouble()); // Reset slider
    } finally {
      if (mounted) setState(() => _isResolutionChanging = false);
    }
  }

  Future<void> _resetResolution({bool showSnackbar = true}) async {
    if (!_resolutionServiceAvailable) return;
    if (mounted) setState(() => _isResolutionChanging = true);
    print("Resetting resolution...");
    try {
      final sr = await _runRootCommandAndWait('wm size reset');
      final dr = await _runRootCommandAndWait('wm density reset');
      if (sr.exitCode != 0 || dr.exitCode != 0) {
        print(
            "Resolution reset command failed. Size exit: ${sr.exitCode}, Density exit: ${dr.exitCode}");
        throw Exception('Reset failed');
      }
      if (mounted)
        setState(() =>
            _resolutionValue = (_resolutionPercentages.length - 1).toDouble());
      if (showSnackbar) {
        // --- REMOVED Snackbar ---
        // _showSnackbar('Resolution reset to original'); // Add localization key
        print("Resolution reset to original.");
      }
    } catch (e) {
      print('Error resetting resolution: $e');
      // --- REMOVED Snackbar ---
      // if (showSnackbar)
      //   _showSnackbar('Error resetting resolution', isError: true);
    } finally {
      if (mounted) setState(() => _isResolutionChanging = false);
    }
  }

  Future<void> _loadGameTxt() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isGameTxtLoading = true);
    print("Loading game.txt...");
    try {
      final result = await _runRootCommandAndWait('cat $_gameTxtPath');
      if (mounted) {
        if (result.exitCode == 0) {
          setState(() {
            _gameTxtContent = result.stdout.toString();
            _gameTxtController.text = _gameTxtContent;
          });
          print("game.txt loaded successfully.");
        } else {
          // --- REMOVED Snackbar ---
          // _showSnackbar('file_read_failed', isError: true, args: {'file': _gameTxtPath});
          print("Failed to read game.txt: ${result.stderr}");
          setState(() {
            _gameTxtContent = '';
            _gameTxtController.text = '';
          });
          // --- REMOVED Snackbar ---
          // if (result.stderr.toString().toLowerCase().contains('no such file'))
          //   _showSnackbar('error_file_not_found', isError: true, args: {'file': _gameTxtPath});
          if (result.stderr.toString().toLowerCase().contains('no such file'))
            print("game.txt not found.");
        }
      }
    } catch (e) {
      if (mounted) {
        // --- REMOVED Snackbar ---
        // _showSnackbar('file_read_failed', isError: true, args: {'file': _gameTxtPath});
        print("Error loading game.txt: $e");
        setState(() {
          _gameTxtContent = '';
          _gameTxtController.text = '';
        });
      }
    } finally {
      if (mounted) setState(() => _isGameTxtLoading = false);
    }
  }

  Future<void> _saveGameTxt() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isGameTxtSaving = true);
    // --- REMOVED Snackbar ---
    // _showSnackbar('saving_file');
    print("Saving game.txt...");
    final newContent = _gameTxtController.text;
    try {
      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd = '''echo '$base64Content' | base64 -d > $_gameTxtPath''';
      final result = await _runRootCommandAndWait(writeCmd);
      if (mounted) {
        if (result.exitCode == 0) {
          setState(() {
            _gameTxtContent = newContent;
          });
          // --- REMOVED Snackbar ---
          // _showSnackbar('file_saved');
          print("game.txt saved successfully.");
        } else {
          // --- REMOVED Snackbar ---
          // _showSnackbar('file_save_failed', isError: true, args: {'file': _gameTxtPath});
          print('Failed save game.txt: ${result.stderr}');
        }
      }
    } catch (e) {
      // --- REMOVED Snackbar ---
      // if (mounted) _showSnackbar('file_save_failed', isError: true, args: {'file': _gameTxtPath});
      print('Error saving game.txt: $e');
    } finally {
      if (mounted) setState(() => _isGameTxtSaving = false);
    }
  }

  @override
  void dispose() {
    if (_resolutionServiceAvailable &&
        _resolutionValue != (_resolutionPercentages.length - 1).toDouble()) {
      _resetResolution(
          showSnackbar: false); // Keep reset logic, just no snackbar
    }
    _gameTxtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final cardElevation = 2.0;
    final cardMargin = const EdgeInsets.only(bottom: 16);
    final cardPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

    bool isHamadaBusy =
        _isHamadaCommandRunning || _isServiceFileUpdating || _isConfigUpdating;

    return Scaffold(
      appBar: AppBar(
        title: Text(_localization.translate('utilities_title')),
        backgroundColor: colorScheme.surfaceVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. HAMADA AI Card ---
            Card(
              elevation: cardElevation,
              margin: cardMargin,
              shape: cardShape,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localization.translate('hamada_ai'),
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                          _localization.translate('hamada_ai_toggle_title')),
                      value: _hamadaAiEnabled,
                      onChanged: isHamadaBusy
                          ? null
                          : (bool value) {
                              _toggleHamadaAI(value);
                            },
                      secondary: _isHamadaCommandRunning || _isConfigUpdating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.power_settings_new),
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(
                        height: 16,
                        color: colorScheme.outlineVariant.withOpacity(0.5)),
                    SwitchListTile(
                      title: Text(
                          _localization.translate('hamada_ai_start_on_boot')),
                      value: _hamadaStartOnBoot,
                      onChanged: isHamadaBusy
                          ? null
                          : (bool value) {
                              _setHamadaStartOnBoot(value);
                            },
                      secondary: _isServiceFileUpdating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.sync_disabled),
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. Edit game.txt Card ---
            Card(
              elevation: cardElevation,
              margin: cardMargin,
              shape: cardShape,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localization.translate('edit_game_txt_title'),
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (_isGameTxtLoading)
                      Center(child: CircularProgressIndicator())
                    else
                      TextField(
                        controller: _gameTxtController,
                        maxLines: 8,
                        minLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: _localization.translate('game_txt_hint'),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(12),
                          fillColor: colorScheme.surfaceContainer,
                          filled: true,
                        ),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface),
                        readOnly: _isGameTxtSaving,
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isGameTxtLoading || _isGameTxtSaving
                            ? null
                            : _saveGameTxt,
                        child: _isGameTxtSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Text(_localization.translate('save_button')),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 3. Downscale Resolution Card ---
            Card(
              elevation: cardElevation,
              margin: cardMargin,
              shape: cardShape,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localization.translate('downscale_resolution'),
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (!_resolutionServiceAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _localization
                              .translate('resolution_unavailable_message'),
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.error),
                        ),
                      )
                    else if (_isResolutionChanging)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 3)),
                            SizedBox(width: 12),
                            Text(_localization.translate('applying_changes'),
                                style: textTheme.bodyMedium),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          _localization.translate('selected_resolution', args: {
                            'resolution': _getCurrentPercentageLabel()
                          }),
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _resolutionValue,
                      min: 0,
                      max: (_resolutionPercentages.length - 1).toDouble(),
                      divisions: _resolutionPercentages.length - 1,
                      label: _getCurrentPercentageLabel(),
                      onChanged: (_resolutionServiceAvailable &&
                              !_isResolutionChanging)
                          ? (value) {
                              if (mounted)
                                setState(() => _resolutionValue = value);
                            }
                          : null,
                      onChangeEnd: (_resolutionServiceAvailable &&
                              !_isResolutionChanging)
                          ? (value) {
                              _applyResolution(value);
                            }
                          : null,
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    if (_resolutionServiceAvailable)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: colorScheme.outline),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isResolutionChanging
                              ? null
                              : () =>
                                  _resetResolution(), // Call without showSnackbar: true
                          child:
                              Text(_localization.translate('reset_resolution')),
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
}
