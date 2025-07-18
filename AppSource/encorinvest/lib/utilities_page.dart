import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'languages.dart';

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
  final String _gameTxtPath = '/data/EnCorinVest/game.txt';
  // --- Path to the config file ---
  final String _configFilePath = '/data/adb/modules/EnCorinVest/encorin.txt';
  final String _hamadaMarker = '# Start HamadaAI (Default is Disabled)';
  final String _hamadaProcessName =
      'HamadaAI'; // Process name for start/kill/check
  final String _hamadaStartCommand = 'HamadaAI'; // Command to start
  final String _hamadaStopCommand = 'killall HamadaAI'; // Command to stop
  final String _hamadaCheckCommand =
      'pgrep -x HamadaAI'; // Command to check if running

  // Add this line:
  final String MODULE_PATH = '/data/adb/modules/EnCorinVest'; //

  // --- UI state ---
  bool _isCopyingLogs = false;
  bool _hamadaAiEnabled = false; // State reflecting actual process status
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
  bool _dndEnabled = false;
  bool _isDndConfigUpdating = false;

  // --- Bypass Charging State ---
  bool _isBypassSupported = false;
  bool _bypassEnabled = false;
  bool _isCheckingBypass = false;
  bool _isTogglingBypass = false;
  String _bypassSupportStatus = '';

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
    _checkHamadaProcessStatus(); // Check initial process status
    _readAndApplyDndConfig();
    _checkResolutionServiceAvailability();
    _checkHamadaStartOnBoot();
    _loadGameTxt();
    _loadInitialBypassState(); // Load initial bypass state on page load
  }

  Future<ProcessResult> _runRootCommandAndWait(String command) async {
    print('Executing root command (and waiting): $command');
    try {
      return await Process.run('su', ['-c', command]);
    } catch (e) {
      print('Error running root command "$command": $e');
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
    }
  }

  Future<bool> _checkRootAccess() async {
    try {
      final result = await _runRootCommandAndWait('id');
      if (result.exitCode == 0 && result.stdout.toString().contains('uid=0')) {
        return true;
      } else {
        print('Root access check failed or not granted.');
        return false;
      }
    } catch (e) {
      print('Error checking root access: $e');
      return false;
    }
  }

  // --- Log Copying Logic ---
  Future<void> _copyLogs() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isCopyingLogs = true);

    final sourceLogPath = '/data/EnCorinVest/EnCorinVest.log';
    final destinationLogPath = '/sdcard/Download/EnCorinVest.log';
    print("Copying EnCorinVest.log to $destinationLogPath...");

    try {
      // Copy the EnCorinVest.log file
      final command = 'cp $sourceLogPath $destinationLogPath';
      final result = await _runRootCommandAndWait(command);

      if (mounted) {
        if (result.exitCode == 0) {
          print("EnCorinVest.log copied successfully.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_localization.translate('logs_copied_success',
                    args: {'path': destinationLogPath}))),
          );
        } else {
          print('Failed to copy EnCorinVest.log: ${result.stderr}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_localization.translate('logs_copied_failed'))),
          );
        }
      }
    } catch (e) {
      print('Error copying EnCorinVest.log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_localization.translate('logs_copied_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCopyingLogs = false);
    }
  }

  // --- Updated DND Logic ---
  Future<bool?> _readDndConfig() async {
    if (!await _checkRootAccess()) return null;
    print("Reading DND config from $_configFilePath");

    final result = await _runRootCommandAndWait('cat $_configFilePath');
    if (result.exitCode == 0) {
      final content = result.stdout.toString();
      final match = RegExp(r'^DND=(.*)$', multiLine: true).firstMatch(content);
      if (match != null) {
        bool enabled = match.group(1)?.trim().toLowerCase() == 'yes';
        print("DND config found: $enabled");
        return enabled;
      }
    }
    print("DND config not found, defaulting to false");
    return false;
  }

  Future<bool> _writeDndConfig(bool enabled) async {
    if (!await _checkRootAccess() || !mounted) return false;

    setState(() => _isDndConfigUpdating = true);
    print("Writing DND=$enabled to $_configFilePath");

    final valueString = enabled ? 'Yes' : 'No';

    try {
      // Read the current config file
      final readResult = await _runRootCommandAndWait('cat $_configFilePath');
      if (readResult.exitCode != 0) {
        print('Failed to read config file: ${readResult.stderr}');
        return false;
      }

      String content = readResult.stdout.toString();

      // Only update if DND line exists
      if (content.contains(RegExp(r'^DND=', multiLine: true))) {
        content = content.replaceAll(
          RegExp(r'^DND=.*$', multiLine: true),
          'DND=$valueString',
        );

        // Write back to file
        String base64Content = base64Encode(utf8.encode(content));
        final writeCommand =
            '''echo '$base64Content' | base64 -d > $_configFilePath''';
        final writeResult = await _runRootCommandAndWait(writeCommand);

        if (writeResult.exitCode == 0) {
          print("DND config file update successful.");
          if (mounted) setState(() => _dndEnabled = enabled);
          return true;
        } else {
          print(
              'DND config file write failed. Exit Code: ${writeResult.exitCode}, Stderr: ${writeResult.stderr}');
          return false;
        }
      } else {
        print('DND line not found in config file. Skipping update.');
        return false;
      }
    } catch (e) {
      print('Error updating DND config file: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isDndConfigUpdating = false);
    }
  }

  Future<void> _readAndApplyDndConfig() async {
    bool? configState = await _readDndConfig();

    if (mounted) {
      setState(() {
        _dndEnabled = configState ?? false;
        print("Initial DND state from config: $_dndEnabled");
      });
    }
  }

  Future<void> _toggleDnd(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    if (_isDndConfigUpdating) return;

    bool configWritten = await _writeDndConfig(enable);
    if (!configWritten && mounted) {
      print("Error: DND config write failed.");
    } else if (configWritten && mounted) {
      print("DND state updated to $enable");
    }
  }

  // --- Updated Hamada AI Logic ---
  Future<void> _checkHamadaProcessStatus() async {
    if (!await _checkRootAccess()) return;

    final result = await _runRootCommandAndWait(_hamadaCheckCommand);
    bool isRunning = result.exitCode == 0;

    if (mounted) {
      setState(() {
        _hamadaAiEnabled = isRunning;
      });
      print("HamadaAI process running: $isRunning");
    }
  }

  Future<void> _toggleHamadaAI(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    if (_isHamadaCommandRunning) return;

    setState(() => _isHamadaCommandRunning = true);

    try {
      if (enable) {
        // Start HamadaAI
        await _runRootCommandFireAndForget(_hamadaStartCommand);
        print('HamadaAI start command executed');

        // Wait a moment and verify it started
        await Future.delayed(Duration(milliseconds: 500));
        await _checkHamadaProcessStatus();
      } else {
        // Stop HamadaAI
        final result = await _runRootCommandAndWait(_hamadaStopCommand);
        print('HamadaAI stop result: Exit Code ${result.exitCode}');

        if (mounted) {
          setState(() => _hamadaAiEnabled = false);
        }
      }
    } catch (e) {
      print('Error toggling HamadaAI: $e');
    } finally {
      if (mounted) setState(() => _isHamadaCommandRunning = false);
    }
  }

  // Keep the existing boot logic unchanged
  Future<void> _checkHamadaStartOnBoot() async {
    if (!await _checkRootAccess()) return;
    final result = await _runRootCommandAndWait('cat $_serviceFilePath');
    if (result.exitCode == 0) {
      final content = result.stdout.toString();
      bool found = content.contains('HamadaAI');
      if (mounted) setState(() => _hamadaStartOnBoot = found);
    } else {
      if (mounted) setState(() => _hamadaStartOnBoot = false);
    }
  }

  Future<void> _setHamadaStartOnBoot(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;

    setState(() => _isServiceFileUpdating = true);

    try {
      final readResult = await _runRootCommandAndWait('cat $_serviceFilePath');
      if (readResult.exitCode != 0) {
        throw Exception('Failed read: ${readResult.stderr}');
      }

      String content = readResult.stdout.toString();
      List<String> lines = content.replaceAll('\r\n', '\n').split('\n');

      // Remove any existing "HamadaAI" entry
      lines.removeWhere((line) => line.trim() == _hamadaStartCommand);

      // Remove trailing empty lines
      while (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }

      if (enable) {
        // Add "HamadaAI" at the end
        lines.add(_hamadaStartCommand);
      }

      String newContent = lines.join('\n');
      if (newContent.isNotEmpty && !newContent.endsWith('\n')) {
        newContent += '\n';
      }

      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd =
          '''echo '$base64Content' | base64 -d > $_serviceFilePath''';

      final writeResult = await _runRootCommandAndWait(writeCmd);

      if (writeResult.exitCode != 0) {
        throw Exception('Failed write: ${writeResult.stderr}');
      }

      if (mounted) setState(() => _hamadaStartOnBoot = enable);
      print("Service file updated successfully.");
    } catch (e) {
      print('Error updating service file: $e');
      if (mounted) setState(() => _hamadaStartOnBoot = !enable);
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
      print('Resolution successfully set to $pct%');
    } catch (e) {
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
        print("Resolution reset to original.");
      }
    } catch (e) {
      print('Error resetting resolution: $e');
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
          print("Failed to read game.txt: ${result.stderr}");
          setState(() {
            _gameTxtContent = '';
            _gameTxtController.text = '';
          });
          if (result.stderr.toString().toLowerCase().contains('no such file'))
            print("game.txt not found.");
        }
      }
    } catch (e) {
      if (mounted) {
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
          print("game.txt saved successfully.");
        } else {
          print('Failed save game.txt: ${result.stderr}');
        }
      }
    } catch (e) {
      print('Error saving game.txt: $e');
    } finally {
      if (mounted) setState(() => _isGameTxtSaving = false);
    }
  }

// --- Updated Bypass Charging Logic ---

  Future<void> _loadInitialBypassState() async {
    if (!await _checkRootAccess() || !mounted) return;

    try {
      // First check if bypass is supported using the test script
      await _checkBypassSupport();

      // Then read the ENABLE_BYPASS value from config
      final result = await _runRootCommandAndWait('cat $_configFilePath');
      if (result.exitCode == 0) {
        final content = result.stdout.toString();
        final enabledMatch = RegExp(r'^ENABLE_BYPASS=(Yes|No)', multiLine: true)
            .firstMatch(content);

        if (mounted) {
          setState(() {
            _bypassEnabled = enabledMatch?.group(1)?.toLowerCase() == 'yes';
            print("Initial bypass state from config: $_bypassEnabled");
          });
        }
      }
    } catch (e) {
      print('Error loading initial bypass state: $e');
      if (mounted) {
        setState(() {
          _bypassEnabled = false;
        });
      }
    }
  }

  Future<void> _checkBypassSupport() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() {
      _isCheckingBypass = true;
      _bypassSupportStatus = '';
    });

    try {
      // Run test script to check support
      final controllerPath =
          '/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh';
      final result = await _runRootCommandAndWait('$controllerPath test');

      if (mounted) {
        setState(() {
          final output = result.stdout.toString().toLowerCase().trim();

          if (output.contains('supported')) {
            _isBypassSupported = true;
            _bypassSupportStatus =
                _localization.translate('bypass_charging_supported');
            print("Bypass support: SUPPORTED");
          } else if (output.contains('unsupported')) {
            _isBypassSupported = false;
            _bypassSupportStatus =
                _localization.translate('bypass_charging_unsupported');
            print("Bypass support: UNSUPPORTED");
          } else {
            // Default to unsupported if output is unclear
            _isBypassSupported = false;
            _bypassSupportStatus =
                _localization.translate('bypass_charging_unsupported');
            print("Bypass support: UNSUPPORTED (unclear output: $output)");
          }
        });
      }
    } catch (e) {
      print('Error checking bypass support: $e');
      if (mounted) {
        setState(() {
          _isBypassSupported = false;
          _bypassSupportStatus =
              _localization.translate('bypass_charging_unsupported');
        });
      }
    } finally {
      if (mounted) setState(() => _isCheckingBypass = false);
    }
  }

  Future<bool> _updateBypassConfig(bool enabled) async {
    try {
      final value = enabled ? 'Yes' : 'No';

      // Read current config
      final readResult = await _runRootCommandAndWait('cat $_configFilePath');
      if (readResult.exitCode != 0) {
        print('Failed to read config file: ${readResult.stderr}');
        return false;
      }

      String content = readResult.stdout.toString();

      // Only update if ENABLE_BYPASS line exists
      if (content.contains(RegExp(r'^ENABLE_BYPASS=', multiLine: true))) {
        content = content.replaceAll(
          RegExp(r'^ENABLE_BYPASS=.*$', multiLine: true),
          'ENABLE_BYPASS=$value',
        );

        // Write updated config back to file
        final base64Content = base64Encode(utf8.encode(content));
        final writeResult = await _runRootCommandAndWait(
          'echo "$base64Content" | base64 -d > $_configFilePath',
        );

        if (writeResult.exitCode == 0) {
          print("ENABLE_BYPASS config update successful.");
          return true;
        } else {
          print(
              'ENABLE_BYPASS config write failed. Exit Code: ${writeResult.exitCode}, Stderr: ${writeResult.stderr}');
          return false;
        }
      } else {
        print('ENABLE_BYPASS line not found in config file. Skipping update.');
        return false;
      }
    } catch (e) {
      print('Error updating bypass config: $e');
      return false;
    }
  }

  Future<void> _toggleBypassCharging(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isTogglingBypass = true);

    try {
      // Update config file first
      final configUpdated = await _updateBypassConfig(enable);
      if (!configUpdated) {
        print('Failed to update bypass config');
        return;
      }

      // If supported, execute controller script
      if (_isBypassSupported) {
        final controllerPath =
            '/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh';
        final action = enable ? 'enable' : 'disable';
        final result = await _runRootCommandAndWait('$controllerPath $action');

        if (result.exitCode != 0) {
          print('Bypass controller failed: ${result.stderr}');
          // Still update the UI state since config was updated successfully
        }
      }

      // Update UI state to match the config
      if (mounted) {
        setState(() => _bypassEnabled = enable);
        print("Bypass charging toggled to: $enable");
      }
    } catch (e) {
      print('Error toggling bypass charging: $e');
    } finally {
      if (mounted) setState(() => _isTogglingBypass = false);
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

    bool isHamadaBusy = _isHamadaCommandRunning ||
        _isServiceFileUpdating ||
        _isConfigUpdating ||
        _isDndConfigUpdating;

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
            // --- 1. DND Card ---
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
                      _localization.translate('dnd_title'),
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localization.translate('dnd_description'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(_localization.translate('dnd_toggle_title')),
                      value: _dndEnabled,
                      onChanged: _isDndConfigUpdating
                          ? null
                          : (bool value) {
                              _toggleDnd(value);
                            },
                      secondary: _isDndConfigUpdating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.bedtime),
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            // --- 2. HAMADA AI Card ---
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
                    Text(
                      _localization.translate('hamada_ai_description'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
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
                      secondary: _isHamadaCommandRunning
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.psychology_alt),
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text(_localization.translate(
                          'hamada_ai_start_on_boot')), // Corrected key
                      value: _hamadaStartOnBoot,
                      onChanged: _isServiceFileUpdating
                          ? null
                          : (bool value) {
                              _setHamadaStartOnBoot(value);
                            },
                      secondary: _isServiceFileUpdating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.rocket_launch),
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            // --- 3. Resolution Card ---
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
                      _localization
                          .translate('downscale_resolution'), // Renamed key
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // If you want a description for resolution, add 'downscale_resolution_description' to languages.dart
                    // Text(
                    //   _localization.translate('downscale_resolution_description'), // New key needed in languages.dart
                    //   style: textTheme.bodySmall?.copyWith(
                    //     color: colorScheme.onSurfaceVariant,
                    //     fontStyle: FontStyle.italic,
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    if (!_resolutionServiceAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _localization.translate(
                              'resolution_unavailable_message'), // Renamed key
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Icon(Icons.screen_rotation,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: _resolutionValue,
                              min: 0,
                              max: (_resolutionPercentages.length - 1)
                                  .toDouble(),
                              divisions: _resolutionPercentages.length - 1,
                              label: _getCurrentPercentageLabel(),
                              onChanged: _isResolutionChanging
                                  ? null
                                  : (double value) {
                                      setState(() {
                                        _resolutionValue = value;
                                      });
                                    },
                              onChangeEnd: _isResolutionChanging
                                  ? null
                                  : (double value) {
                                      _applyResolution(value);
                                    },
                              activeColor: colorScheme.primary,
                              inactiveColor:
                                  colorScheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                          ),
                          Text(_getCurrentPercentageLabel(),
                              style: textTheme.bodyLarge
                                  ?.copyWith(color: colorScheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: colorScheme.secondaryContainer,
                            foregroundColor: colorScheme.onSecondaryContainer,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isResolutionChanging
                              ? null
                              : () => _resetResolution(),
                          icon: _isResolutionChanging
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.refresh),
                          label:
                              Text(_localization.translate('reset_resolution')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // --- 4. game.txt Editor Card ---
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
                      _localization
                          .translate('edit_game_txt_title'), // Renamed key
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // If you want a description for game.txt editor, add 'edit_game_txt_description' to languages.dart
                    // Text(
                    //   _localization.translate('edit_game_txt_description'), // New key needed in languages.dart
                    //   style: textTheme.bodySmall?.copyWith(
                    //     color: colorScheme.onSurfaceVariant,
                    //     fontStyle: FontStyle.italic,
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    TextField(
                      controller: _gameTxtController,
                      maxLines: 10,
                      minLines: 5,
                      enabled: !_isGameTxtLoading && !_isGameTxtSaving,
                      decoration: InputDecoration(
                        hintText: _localization.translate('game_txt_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: colorScheme.outline, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: colorScheme.outline, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: colorScheme.primary, width: 2.0),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Removed the "Reading File" button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed:
                                _isGameTxtSaving ? null : () => _saveGameTxt(),
                            icon: _isGameTxtSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.save),
                            label: Text(_localization.translate('save_button')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // --- 5. Bypass Charging Card ---
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
                      _localization.translate('bypass_charging_title'),
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localization.translate('bypass_charging_description'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_bypassSupportStatus.isNotEmpty) ...[
                      Center(
                        child: Text(
                          _bypassSupportStatus,
                          style: textTheme.bodyMedium?.copyWith(
                            color: _isBypassSupported
                                ? Colors.green
                                : colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SwitchListTile(
                      title: Text(
                          _localization.translate('bypass_charging_toggle')),
                      value: _bypassEnabled,
                      onChanged: (_isTogglingBypass || !_isBypassSupported)
                          ? null
                          : (bool value) {
                              _toggleBypassCharging(value);
                            },
                      secondary: _isTogglingBypass
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.battery_charging_full),
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // --- 6. Copy Logs Card ---
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
                      _localization.translate('copy_logs_title'),
                      style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localization.translate('copy_logs_description'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isCopyingLogs ? null : _copyLogs,
                        icon: _isCopyingLogs
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              )
                            : Icon(Icons.description_outlined),
                        label:
                            Text(_localization.translate('copy_logs_button')),
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
