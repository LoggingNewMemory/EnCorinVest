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
  final String _hamadaMarker = '# Start HamadaAI (Default is Disabled)';
  final String _hamadaProcessName =
      'HamadaAI'; // Process name for start/kill/check
  final String _hamadaStartCommand = 'HamadaAI'; // Command to start
  final String _hamadaStopCommand = 'killall HamadaAI'; // Command to stop
  final String _hamadaCheckCommand =
      'pgrep -x HamadaAI'; // Command to check if running

  // --- UI state ---
  bool _hamadaAiEnabled = false; // State for the runtime toggle
  bool _hamadaStartOnBoot = false; // State for the boot toggle
  bool _isHamadaCommandRunning = false; // Loading indicator for start/stop
  bool _isServiceFileUpdating =
      false; // Loading indicator for boot toggle update
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
    _checkInitialHamadaStatus(); // Check if HamadaAI is running initially
    _checkResolutionServiceAvailability();
    _checkHamadaStartOnBoot();
    _loadGameTxt();
  }

  // --- Utility Functions ---

  void _showSnackbar(String messageKey,
      {bool isError = false, Map<String, String>? args}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_localization.translate(messageKey, args: args)),
        backgroundColor: isError ? Colors.red : null,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<ProcessResult> _runRootCommandAndWait(String command) async {
    print('Executing root command (and waiting): $command');
    try {
      // Use shell explicitly for commands involving pipes or redirection
      // if 'su -c' doesn't handle them reliably across devices.
      // However, for simple commands, 'su -c command' is often sufficient.
      // Let's stick with 'su -c' for now unless pipes fail.
      return await Process.run('su', ['-c', command]);
      // Example using shell:
      // return await Process.run('su', ['-c', 'sh -c "$command"']);
    } catch (e) {
      print('Error running root command "$command": $e');
      if (mounted)
        _showSnackbar('command_failed',
            isError: true, args: {'command': command});
      return ProcessResult(0, -1, '', 'Execution failed: $e');
    }
  }

  Future<void> _runRootCommandFireAndForget(String command) async {
    print('Executing root command (fire and forget): $command');
    try {
      // Ensure the command runs in the background properly
      await Process.start('su', ['-c', '$command &'],
          runInShell: true, mode: ProcessStartMode.detached);
    } catch (e) {
      print('Error starting root command "$command": $e');
      if (mounted)
        _showSnackbar('command_failed',
            isError: true, args: {'command': command});
    }
  }

  Future<bool> _checkRootAccess() async {
    try {
      final result = await _runRootCommandAndWait('id');
      if (result.exitCode == 0 && result.stdout.toString().contains('uid=0')) {
        return true;
      } else {
        if (mounted) _showSnackbar('error_no_root', isError: true);
        return false;
      }
    } catch (e) {
      if (mounted) _showSnackbar('error_no_root', isError: true);
      return false;
    }
  }

  // --- Hamada AI Logic ---

  Future<void> _checkInitialHamadaStatus() async {
    if (!await _checkRootAccess()) return;
    final result = await _runRootCommandAndWait(_hamadaCheckCommand);
    bool isRunning = result.exitCode == 0;
    if (mounted) {
      setState(() => _hamadaAiEnabled = isRunning);
      print("Initial Hamada AI running state: $isRunning");
    }
  }

  Future<void> _toggleHamadaAI(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isHamadaCommandRunning = true);
    final commandToRun = enable ? _hamadaStartCommand : _hamadaStopCommand;
    final actionKey = enable ? 'Starting' : 'Stopping';

    _showSnackbar('executing_command');

    try {
      if (enable) {
        await _runRootCommandFireAndForget(commandToRun);
        if (mounted) {
          setState(() => _hamadaAiEnabled = true);
          // Use a more specific key if available, e.g., 'hamada_ai_started'
          _showSnackbar('Command executed');
        }
      } else {
        final result = await _runRootCommandAndWait(commandToRun);
        if (mounted) {
          setState(() => _hamadaAiEnabled = false);
          // Use a more specific key if available, e.g., 'hamada_ai_stopped'
          _showSnackbar('Command executed');
          print(
              'Killall result: Exit Code ${result.exitCode}, Stderr: ${result.stderr}');
        }
      }
    } catch (e) {
      print('Error $actionKey Hamada AI: $e');
      if (mounted) {
        _showSnackbar('command_failed',
            isError: true, args: {'command': commandToRun});
        setState(() => _hamadaAiEnabled = !enable); // Revert state
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
              found = trimmedLine == _hamadaProcessName;
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

  /// Updates the service.sh file using base64 encoding to avoid escaping issues.
  Future<void> _setHamadaStartOnBoot(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;

    setState(() => _isServiceFileUpdating = true);
    _showSnackbar('writing_service_file');

    try {
      // 1. Read current content
      final readResult = await _runRootCommandAndWait('cat $_serviceFilePath');
      if (readResult.exitCode != 0) {
        throw Exception('Failed read: ${readResult.stderr}');
      }
      String content = readResult.stdout.toString();
      // Normalize line endings to Unix style (\n)
      List<String> lines = content.replaceAll('\r\n', '\n').split('\n');

      // Remove trailing empty line if present from split
      if (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }

      // 2. Find marker
      int markerIndex =
          lines.indexWhere((line) => line.contains(_hamadaMarker));
      if (markerIndex == -1) {
        throw Exception('Marker "$_hamadaMarker" not found.');
      }

      // 3. Find and remove existing command line below marker
      int commandLineIndex = -1;
      for (int i = markerIndex + 1; i < lines.length; i++) {
        final trimmedLine = lines[i].trim();
        if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
          if (trimmedLine == _hamadaProcessName) commandLineIndex = i;
          break; // Only check first relevant line
        }
      }
      if (commandLineIndex != -1) lines.removeAt(commandLineIndex);

      // 4. Add command if enabling
      if (enable) lines.insert(markerIndex + 1, _hamadaProcessName);

      // 5. Prepare new content string (ensure trailing newline)
      String newContent = lines.join('\n') + '\n';

      // 6. Encode content to Base64
      String base64Content = base64Encode(utf8.encode(newContent));

      // 7. Construct write command using base64 decode
      // Ensure the base64 utility is available (standard on most Android systems)
      // Use single quotes around the base64 string to prevent shell interpretation
      final writeCmd =
          '''echo '$base64Content' | base64 -d > $_serviceFilePath''';

      // 8. Execute write command
      print("Attempting to write service file..."); // Log before execution
      final writeResult = await _runRootCommandAndWait(writeCmd);

      if (writeResult.exitCode != 0) {
        // Log detailed error output from the command
        print('Write failed. Exit Code: ${writeResult.exitCode}');
        print('Stderr: ${writeResult.stderr}');
        print(
            'Stdout: ${writeResult.stdout}'); // Stdout might also contain errors from the pipe
        throw Exception('Failed write: ${writeResult.stderr}');
      }

      // 9. Update state on success
      if (mounted) setState(() => _hamadaStartOnBoot = enable);
      _showSnackbar('service_file_updated');
      print("Service file write successful.");
    } catch (e) {
      print('Error updating service file: $e');
      if (mounted) _showSnackbar('service_file_update_failed', isError: true);
      if (mounted)
        setState(() => _hamadaStartOnBoot = !enable); // Revert visual state
    } finally {
      if (mounted) setState(() => _isServiceFileUpdating = false);
    }
  }

  // --- Resolution Logic --- (No changes needed)
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
        if (mounted) setState(() => _resolutionServiceAvailable = false);
        return;
      }
      final dr = await _runRootCommandAndWait('wm density');
      final dm = RegExp(r'(?:Physical|Override) density:\s*([0-9]+)')
          .firstMatch(dr.stdout.toString());
      if (dm != null && dm.group(1) != null) {
        _originalDensity = int.tryParse(dm.group(1)!) ?? 0;
        if (_originalDensity == 0) if (mounted)
          setState(() => _resolutionServiceAvailable = false);
      } else {
        if (mounted) setState(() => _resolutionServiceAvailable = false);
      }
    } catch (e) {
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
      _showSnackbar('Resolution change unavailable.', isError: true);
      if (mounted)
        setState(() =>
            _resolutionValue = (_resolutionPercentages.length - 1).toDouble());
      return;
    }
    if (mounted) setState(() => _isResolutionChanging = true);
    final idx = value.round().clamp(0, _resolutionPercentages.length - 1);
    final pct = _resolutionPercentages[idx];
    try {
      final parts = _originalSize.split('x');
      final origW = int.tryParse(parts[0]);
      final origH = int.tryParse(parts[1]);
      if (parts.length != 2 ||
          origW == null ||
          origH == null ||
          origW <= 0 ||
          origH <= 0) throw FormatException('Invalid size');
      final newW = (origW * pct / 100).floor();
      final newH = (origH * pct / 100).floor();
      final newD = (_originalDensity * pct / 100).floor();
      if (newW <= 0 || newH <= 0 || newD <= 0)
        throw FormatException('Calculated zero/negative');
      final sr = await _runRootCommandAndWait('wm size ${newW}x${newH}');
      if (sr.exitCode != 0) throw Exception('Set size failed: ${sr.stderr}');
      final dr = await _runRootCommandAndWait('wm density $newD');
      if (dr.exitCode != 0) {
        await _runRootCommandAndWait('wm size reset');
        throw Exception('Set density failed: ${dr.stderr}');
      }
      if (mounted) setState(() => _resolutionValue = value);
      _showSnackbar('Resolution set to $pct%'); // Add localization key
    } catch (e) {
      _showSnackbar('Error changing resolution: ${e.toString()}',
          isError: true);
      await _resetResolution(showSnackbar: false);
      if (mounted)
        setState(() =>
            _resolutionValue = (_resolutionPercentages.length - 1).toDouble());
    } finally {
      if (mounted) setState(() => _isResolutionChanging = false);
    }
  }

  Future<void> _resetResolution({bool showSnackbar = true}) async {
    if (!_resolutionServiceAvailable) return;
    if (mounted) setState(() => _isResolutionChanging = true);
    try {
      final sr = await _runRootCommandAndWait('wm size reset');
      final dr = await _runRootCommandAndWait('wm density reset');
      if (sr.exitCode != 0 || dr.exitCode != 0) throw Exception('Reset failed');
      if (mounted)
        setState(() =>
            _resolutionValue = (_resolutionPercentages.length - 1).toDouble());
      if (showSnackbar)
        _showSnackbar('Resolution reset to original'); // Add localization key
    } catch (e) {
      if (showSnackbar)
        _showSnackbar('Error resetting resolution', isError: true);
    } finally {
      if (mounted) setState(() => _isResolutionChanging = false);
    }
  }

  // --- game.txt Logic --- (No changes needed)
  Future<void> _loadGameTxt() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isGameTxtLoading = true);
    try {
      final result = await _runRootCommandAndWait('cat $_gameTxtPath');
      if (mounted) {
        if (result.exitCode == 0) {
          setState(() {
            _gameTxtContent = result.stdout.toString();
            _gameTxtController.text = _gameTxtContent;
          });
        } else {
          _showSnackbar('file_read_failed', isError: true);
          setState(() {
            _gameTxtContent = '';
            _gameTxtController.text = '';
          });
          if (result.stderr.toString().toLowerCase().contains('no such file'))
            _showSnackbar('error_file_not_found', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('file_read_failed', isError: true);
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
    _showSnackbar('saving_file');
    final newContent = _gameTxtController.text;
    try {
      // Use base64 for game.txt as well for consistency and robustness
      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd = '''echo '$base64Content' | base64 -d > $_gameTxtPath''';
      final result = await _runRootCommandAndWait(writeCmd);
      if (mounted) {
        if (result.exitCode == 0) {
          setState(() {
            _gameTxtContent = newContent;
          });
          _showSnackbar('file_saved');
        } else {
          _showSnackbar('file_save_failed', isError: true);
          print('Failed save game.txt: ${result.stderr}');
        }
      }
    } catch (e) {
      if (mounted) _showSnackbar('file_save_failed', isError: true);
    } finally {
      if (mounted) setState(() => _isGameTxtSaving = false);
    }
  }

  @override
  void dispose() {
    // Attempt to stop Hamada AI if it was left enabled by the toggle
    if (_hamadaAiEnabled) {
      print("Stopping Hamada AI on dispose...");
      _runRootCommandAndWait(
          _hamadaStopCommand); // Run stop command on dispose if needed
    }
    if (_resolutionServiceAvailable &&
        _resolutionValue != (_resolutionPercentages.length - 1).toDouble()) {
      _resetResolution(showSnackbar: false);
    }
    _gameTxtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Build method remains the same as the previous version ---
    // (Using SwitchListTile for Hamada AI runtime toggle)
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final cardElevation = 2.0;
    final cardMargin = const EdgeInsets.only(bottom: 16);
    final cardPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

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
                      onChanged:
                          _isHamadaCommandRunning || _isServiceFileUpdating
                              ? null
                              : (bool value) {
                                  _toggleHamadaAI(value);
                                },
                      secondary: _isHamadaCommandRunning
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
                      onChanged:
                          _isServiceFileUpdating || _isHamadaCommandRunning
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
                          hintText: 'Content of game.txt',
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
                          'Resolution changing requires root and working \'wm\' commands.',
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
                            Text("Applying changes...",
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
                              : () => _resetResolution(),
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
