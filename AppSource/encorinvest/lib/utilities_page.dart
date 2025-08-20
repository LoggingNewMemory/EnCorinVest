import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:process_run/process_run.dart';
import '/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

//region Helper Functions
Future<ProcessResult> _runRootCommandAndWait(String command) async {
  try {
    return await run('su', ['-c', command]);
  } catch (e) {
    return ProcessResult(0, -1, '', 'Execution failed: $e');
  }
}

Future<void> _runRootCommandFireAndForget(String command) async {
  try {
    await Process.start('su', ['-c', '$command &'],
        runInShell: true, mode: ProcessStartMode.detached);
  } catch (e) {
    // Error starting root command
  }
}

Future<bool> _checkRootAccess() async {
  try {
    final result = await _runRootCommandAndWait('id');
    return result.exitCode == 0 && result.stdout.toString().contains('uid=0');
  } catch (e) {
    return false;
  }
}
//endregion

class UtilitiesPage extends StatefulWidget {
  const UtilitiesPage({Key? key}) : super(key: key);

  @override
  _UtilitiesPageState createState() => _UtilitiesPageState();
}

class _UtilitiesPageState extends State<UtilitiesPage> {
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.2;
  bool _isLoading = true;

  // Data for child widgets
  Map<String, dynamic>? _encoreState;
  Map<String, dynamic>? _governorState;
  bool? _dndEnabled;
  Map<String, bool>? _hamadaAiState;
  Map<String, dynamic>? _resolutionState;
  String? _gameTxtContent;
  Map<String, dynamic>? _bypassChargingState;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    final bool hasRoot = await _checkRootAccess();

    // Start all data fetching processes and the artificial delay concurrently.
    final dataFutures = [
      _loadBackgroundSettings(),
      if (hasRoot) ...[
        _loadEncoreSwitchState(),
        _loadGovernorState(),
        _loadDndState(),
        _loadHamadaAiState(),
        _loadResolutionState(),
        _loadGameTxtState(),
        _loadBypassChargingState(),
      ]
    ];

    final delayFuture = Future.delayed(const Duration(seconds: 1));

    // Await both the data and the delay.
    final results = await Future.wait(dataFutures);
    await delayFuture;

    if (!mounted) return;

    // Process results and update the UI state in a single call.
    setState(() {
      int resultIndex = 0;
      final bgSettings = results[resultIndex++] as Map<String, dynamic>;
      _backgroundImagePath = bgSettings['path'];
      _backgroundOpacity = bgSettings['opacity'];

      if (hasRoot) {
        _encoreState = results[resultIndex++] as Map<String, dynamic>;
        _governorState = results[resultIndex++] as Map<String, dynamic>;
        _dndEnabled = results[resultIndex++] as bool;
        _hamadaAiState = results[resultIndex++] as Map<String, bool>;
        _resolutionState = results[resultIndex++] as Map<String, dynamic>;
        _gameTxtContent = results[resultIndex++] as String;
        _bypassChargingState = results[resultIndex++] as Map<String, dynamic>;
      }

      _isLoading = false;
    });
  }

  //region Data Loading Methods
  Future<Map<String, dynamic>> _loadBackgroundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('background_image_path');
      final opacity = prefs.getDouble('background_opacity') ?? 0.2;
      return {'path': path, 'opacity': opacity};
    } catch (e) {
      return {'path': null, 'opacity': 0.2};
    }
  }

  Future<Map<String, dynamic>> _loadEncoreSwitchState() async {
    final result = await _runRootCommandAndWait(
        'cat /data/adb/modules/EnCorinVest/Scripts/encoreTweaks.sh');
    if (result.exitCode == 0) {
      final content = result.stdout.toString();
      return {
        'deviceMitigation': RegExp(r'^DEVICE_MITIGATION=(\d)', multiLine: true)
                .firstMatch(content)
                ?.group(1) ==
            '1',
        'liteMode': RegExp(r'^LITE_MODE=(\d)', multiLine: true)
                .firstMatch(content)
                ?.group(1) ==
            '1',
      };
    }
    return {'deviceMitigation': false, 'liteMode': false};
  }

  Future<Map<String, dynamic>> _loadGovernorState() async {
    final results = await Future.wait([
      _runRootCommandAndWait(
          'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors'),
      _runRootCommandAndWait('cat /data/adb/modules/EnCorinVest/encorin.txt'),
    ]);
    final governorsResult = results[0];
    final configResult = results[1];

    List<String> available = (governorsResult.exitCode == 0 &&
            governorsResult.stdout.toString().isNotEmpty)
        ? governorsResult.stdout.toString().trim().split(' ')
        : [];

    String? selected;
    if (configResult.exitCode == 0) {
      selected = RegExp(r'^GOV=(.*)$', multiLine: true)
          .firstMatch(configResult.stdout.toString())
          ?.group(1)
          ?.trim();
    }
    return {'available': available, 'selected': selected};
  }

  Future<bool> _loadDndState() async {
    final result = await _runRootCommandAndWait(
        'cat /data/adb/modules/EnCorinVest/encorin.txt');
    if (result.exitCode == 0) {
      final match = RegExp(r'^DND=(.*)$', multiLine: true)
          .firstMatch(result.stdout.toString());
      return match?.group(1)?.trim().toLowerCase() == 'yes';
    }
    return false;
  }

  Future<Map<String, bool>> _loadHamadaAiState() async {
    final results = await Future.wait([
      _runRootCommandAndWait('pgrep -x HamadaAI'),
      _runRootCommandAndWait('cat /data/adb/modules/EnCorinVest/service.sh'),
    ]);
    return {
      'enabled': results[0].exitCode == 0,
      'onBoot': results[1].stdout.toString().contains('HamadaAI'),
    };
  }

  Future<Map<String, dynamic>> _loadResolutionState() async {
    final results = await Future.wait([
      _runRootCommandAndWait('wm size'),
      _runRootCommandAndWait('wm density')
    ]);
    final sr = results[0];
    final dr = results[1];

    bool available = sr.exitCode == 0 &&
        sr.stdout.toString().contains('Physical size:') &&
        dr.exitCode == 0 &&
        (dr.stdout.toString().contains('Physical density:') ||
            dr.stdout.toString().contains('Override density:'));

    String originalSize = '';
    int originalDensity = 0;

    if (available) {
      originalSize = RegExp(r'Physical size:\s*([0-9]+x[0-9]+)')
              .firstMatch(sr.stdout.toString())
              ?.group(1) ??
          '';
      originalDensity = int.tryParse(
              RegExp(r'(?:Physical|Override) density:\s*([0-9]+)')
                      .firstMatch(dr.stdout.toString())
                      ?.group(1) ??
                  '') ??
          0;
      if (originalSize.isEmpty || originalDensity == 0) available = false;
    }
    return {
      'isAvailable': available,
      'originalSize': originalSize,
      'originalDensity': originalDensity
    };
  }

  Future<String> _loadGameTxtState() async {
    final result =
        await _runRootCommandAndWait('cat /data/EnCorinVest/game.txt');
    return result.exitCode == 0 ? result.stdout.toString() : '';
  }

  Future<Map<String, dynamic>> _loadBypassChargingState() async {
    final localization = AppLocalizations.of(context)!;
    final results = await Future.wait([
      _runRootCommandAndWait(
          '/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh test'),
      _runRootCommandAndWait('cat /data/adb/modules/EnCorinVest/encorin.txt'),
    ]);
    final supportResult = results[0];
    final configResult = results[1];

    bool isSupported =
        supportResult.stdout.toString().toLowerCase().contains('supported');
    String statusMsg = isSupported
        ? localization.bypass_charging_supported
        : localization.bypass_charging_unsupported;

    bool isEnabled = false;
    if (configResult.exitCode == 0) {
      isEnabled = RegExp(r'^ENABLE_BYPASS=(Yes|No)', multiLine: true)
              .firstMatch(configResult.stdout.toString())
              ?.group(1)
              ?.toLowerCase() ==
          'yes';
    }
    return {
      'isSupported': isSupported,
      'statusMsg': statusMsg,
      'isEnabled': isEnabled
    };
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(localization.utilities_title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty)
            Opacity(
              opacity: _backgroundOpacity,
              child: Image.file(
                File(_backgroundImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.transparent),
              ),
            ),
          if (_isLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: LinearProgressIndicator(),
            ))
          else
            AnimatedOpacity(
              opacity: _isLoading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EncoreSwitchCard(
                      initialDeviceMitigation:
                          _encoreState?['deviceMitigation'] ?? false,
                      initialLiteMode: _encoreState?['liteMode'] ?? false,
                    ),
                    GovernorCard(
                      initialAvailableGovernors:
                          _governorState?['available'] ?? [],
                      initialSelectedGovernor: _governorState?['selected'],
                    ),
                    DndCard(initialDndEnabled: _dndEnabled ?? false),
                    HamadaAiCard(
                      initialHamadaAiEnabled:
                          _hamadaAiState?['enabled'] ?? false,
                      initialHamadaStartOnBoot:
                          _hamadaAiState?['onBoot'] ?? false,
                    ),
                    ResolutionCard(
                      isAvailable: _resolutionState?['isAvailable'] ?? false,
                      originalSize: _resolutionState?['originalSize'] ?? '',
                      originalDensity:
                          _resolutionState?['originalDensity'] ?? 0,
                    ),
                    GameTxtCard(initialContent: _gameTxtContent ?? ''),
                    BypassChargingCard(
                      isSupported:
                          _bypassChargingState?['isSupported'] ?? false,
                      isEnabled: _bypassChargingState?['isEnabled'] ?? false,
                      supportStatus: _bypassChargingState?['statusMsg'] ??
                          localization.bypass_charging_unsupported,
                    ),
                    BackgroundSettingsCard(
                      initialPath: _backgroundImagePath,
                      initialOpacity: _backgroundOpacity,
                      onSettingsChanged: (path, opacity) {
                        if (!mounted) return;
                        setState(() {
                          _backgroundImagePath = path;
                          _backgroundOpacity = opacity;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//region Card Widgets
class EncoreSwitchCard extends StatefulWidget {
  final bool initialDeviceMitigation;
  final bool initialLiteMode;

  const EncoreSwitchCard(
      {Key? key,
      required this.initialDeviceMitigation,
      required this.initialLiteMode})
      : super(key: key);

  @override
  _EncoreSwitchCardState createState() => _EncoreSwitchCardState();
}

class _EncoreSwitchCardState extends State<EncoreSwitchCard> {
  late bool _deviceMitigationEnabled;
  late bool _liteModeEnabled;
  bool _isUpdating = false;

  final String _encoreTweaksFilePath =
      '/data/adb/modules/EnCorinVest/Scripts/encoreTweaks.sh';
  final String _encorinFunctionFilePath =
      '/data/adb/modules/EnCorinVest/Scripts/encorinFunctions.sh';

  @override
  void initState() {
    super.initState();
    _deviceMitigationEnabled = widget.initialDeviceMitigation;
    _liteModeEnabled = widget.initialLiteMode;
  }

  Future<void> _updateEncoreTweak(String key, bool enable) async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isUpdating = true);

    try {
      final value = enable ? '1' : '0';
      final sedCommandTweaks =
          "sed -i 's|^$key=.*|$key=$value|' $_encoreTweaksFilePath";
      final sedCommandFunctions =
          "sed -i 's|^$key=.*|$key=$value|' $_encorinFunctionFilePath";

      final results = await Future.wait([
        _runRootCommandAndWait(sedCommandTweaks),
        _runRootCommandAndWait(sedCommandFunctions)
      ]);

      if (results.every((r) => r.exitCode == 0)) {
        if (mounted) {
          setState(() {
            if (key == 'DEVICE_MITIGATION') _deviceMitigationEnabled = enable;
            if (key == 'LITE_MODE') _liteModeEnabled = enable;
          });
        }
      } else {
        throw Exception('Failed to write to one or more script files.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update settings: $e')));
        setState(() {
          _deviceMitigationEnabled = widget.initialDeviceMitigation;
          _liteModeEnabled = widget.initialLiteMode;
        });
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.encore_switch_title,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(localization.encore_switch_description,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(localization.device_mitigation_title),
              subtitle: Text(localization.device_mitigation_description),
              value: _deviceMitigationEnabled,
              onChanged: _isUpdating
                  ? null
                  : (value) => _updateEncoreTweak('DEVICE_MITIGATION', value),
              secondary: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.security_update_warning),
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(localization.lite_mode_title),
              subtitle: Text(localization.lite_mode_description),
              value: _liteModeEnabled,
              onChanged: _isUpdating
                  ? null
                  : (value) => _updateEncoreTweak('LITE_MODE', value),
              secondary: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.flourescent),
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class GovernorCard extends StatefulWidget {
  final List<String> initialAvailableGovernors;
  final String? initialSelectedGovernor;

  const GovernorCard(
      {Key? key,
      required this.initialAvailableGovernors,
      this.initialSelectedGovernor})
      : super(key: key);
  @override
  _GovernorCardState createState() => _GovernorCardState();
}

class _GovernorCardState extends State<GovernorCard> {
  late List<String> _availableGovernors;
  String? _selectedGovernor;
  bool _isSaving = false;
  final String _configFilePath = '/data/adb/modules/EnCorinVest/encorin.txt';

  @override
  void initState() {
    super.initState();
    _availableGovernors = widget.initialAvailableGovernors;
    _selectedGovernor = widget.initialSelectedGovernor;
  }

  Future<void> _saveGovernor(String? governor) async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isSaving = true);
    final valueString = governor ?? '';

    try {
      final sedCommand =
          "sed -i 's|^GOV=.*|GOV=$valueString|' $_configFilePath";
      final result = await _runRootCommandAndWait(sedCommand);

      if (result.exitCode == 0) {
        if (mounted) setState(() => _selectedGovernor = governor);
      } else {
        throw Exception('Failed to write to config file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save governor: $e')));
        setState(() => _selectedGovernor = widget.initialSelectedGovernor);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.custom_governor_title,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(localization.custom_governor_description,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            if (_availableGovernors.isEmpty)
              Center(
                  child: Text('No governors found or root access denied.',
                      style: TextStyle(color: colorScheme.error)))
            else
              DropdownButtonFormField<String>(
                value: _availableGovernors.contains(_selectedGovernor)
                    ? _selectedGovernor
                    : null,
                hint: Text(localization.no_governor_selected),
                isExpanded: true,
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8))),
                onChanged: _isSaving ? null : _saveGovernor,
                items: [
                  DropdownMenuItem<String>(
                      value: null,
                      child: Text(localization.no_governor_selected)),
                  ..._availableGovernors.map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DndCard extends StatefulWidget {
  final bool initialDndEnabled;
  const DndCard({Key? key, required this.initialDndEnabled}) : super(key: key);
  @override
  _DndCardState createState() => _DndCardState();
}

class _DndCardState extends State<DndCard> {
  late bool _dndEnabled;
  bool _isUpdating = false;
  final String _configFilePath = '/data/adb/modules/EnCorinVest/encorin.txt';

  @override
  void initState() {
    super.initState();
    _dndEnabled = widget.initialDndEnabled;
  }

  Future<void> _toggleDnd(bool enable) async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isUpdating = true);
    final valueString = enable ? 'Yes' : 'No';

    try {
      final sedCommand =
          "sed -i 's|^DND=.*|DND=$valueString|' $_configFilePath";
      final result = await _runRootCommandAndWait(sedCommand);
      if (result.exitCode == 0) {
        if (mounted) setState(() => _dndEnabled = enable);
      } else {
        throw Exception('Failed to write to config file.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update DND setting: $e')));
        setState(() => _dndEnabled = widget.initialDndEnabled);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.dnd_title,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(localization.dnd_description,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(localization.dnd_toggle_title),
              value: _dndEnabled,
              onChanged: _isUpdating ? null : _toggleDnd,
              secondary: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bedtime),
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class HamadaAiCard extends StatefulWidget {
  final bool initialHamadaAiEnabled;
  final bool initialHamadaStartOnBoot;

  const HamadaAiCard(
      {Key? key,
      required this.initialHamadaAiEnabled,
      required this.initialHamadaStartOnBoot})
      : super(key: key);
  @override
  _HamadaAiCardState createState() => _HamadaAiCardState();
}

class _HamadaAiCardState extends State<HamadaAiCard> {
  late bool _hamadaAiEnabled;
  late bool _hamadaStartOnBoot;
  bool _isTogglingProcess = false;
  bool _isTogglingBoot = false;

  final String _serviceFilePath = '/data/adb/modules/EnCorinVest/service.sh';
  final String _hamadaStartCommand = 'HamadaAI';

  @override
  void initState() {
    super.initState();
    _hamadaAiEnabled = widget.initialHamadaAiEnabled;
    _hamadaStartOnBoot = widget.initialHamadaStartOnBoot;
  }

  /// Fetches the current state of HamadaAI directly.
  /// This is used to refresh the card's state after a toggle action.
  Future<Map<String, bool>> _fetchCurrentState() async {
    if (!await _checkRootAccess()) {
      return {'enabled': _hamadaAiEnabled, 'onBoot': _hamadaStartOnBoot};
    }
    final results = await Future.wait([
      _runRootCommandAndWait('pgrep -x HamadaAI'),
      _runRootCommandAndWait('cat $_serviceFilePath'),
    ]);
    return {
      'enabled': results[0].exitCode == 0,
      'onBoot': results[1].stdout.toString().contains('HamadaAI'),
    };
  }

  Future<void> _refreshState() async {
    final state = await _fetchCurrentState();
    if (mounted) {
      setState(() {
        _hamadaAiEnabled = state['enabled'] ?? false;
        _hamadaStartOnBoot = state['onBoot'] ?? false;
      });
    }
  }

  Future<void> _toggleHamadaAI(bool enable) async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isTogglingProcess = true);
    try {
      if (enable) {
        await _runRootCommandFireAndForget(_hamadaStartCommand);
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await _runRootCommandAndWait('killall HamadaAI');
      }
      await _refreshState();
    } finally {
      if (mounted) setState(() => _isTogglingProcess = false);
    }
  }

  Future<void> _setHamadaStartOnBoot(bool enable) async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isTogglingBoot = true);
    try {
      String content = (await _runRootCommandAndWait('cat $_serviceFilePath'))
          .stdout
          .toString();
      List<String> lines = content.replaceAll('\r\n', '\n').split('\n');
      lines.removeWhere((line) => line.trim() == _hamadaStartCommand);

      while (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }

      if (enable) {
        lines.add(_hamadaStartCommand);
      }

      String newContent = lines.join('\n');
      if (newContent.isNotEmpty && !newContent.endsWith('\n')) {
        newContent += '\n';
      }

      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd =
          '''echo '$base64Content' | base64 -d > $_serviceFilePath''';
      final result = await _runRootCommandAndWait(writeCmd);

      if (result.exitCode == 0) {
        if (mounted) setState(() => _hamadaStartOnBoot = enable);
      } else {
        throw Exception('Failed to write to service file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update boot setting: $e')));
        await _refreshState();
      }
    } finally {
      if (mounted) setState(() => _isTogglingBoot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isBusy = _isTogglingProcess || _isTogglingBoot;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.hamada_ai,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(localization.hamada_ai_description,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(localization.hamada_ai_toggle_title),
              value: _hamadaAiEnabled,
              onChanged: isBusy ? null : _toggleHamadaAI,
              secondary: _isTogglingProcess
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.psychology_alt),
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(localization.hamada_ai_start_on_boot),
              value: _hamadaStartOnBoot,
              onChanged: isBusy ? null : _setHamadaStartOnBoot,
              secondary: _isTogglingBoot
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.rocket_launch),
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class ResolutionCard extends StatefulWidget {
  final bool isAvailable;
  final String originalSize;
  final int originalDensity;
  const ResolutionCard(
      {Key? key,
      required this.isAvailable,
      required this.originalSize,
      required this.originalDensity})
      : super(key: key);
  @override
  _ResolutionCardState createState() => _ResolutionCardState();
}

class _ResolutionCardState extends State<ResolutionCard> {
  bool _isChanging = false;
  late double _currentValue;
  final List<int> _percentages = [50, 60, 70, 80, 90, 100];

  @override
  void initState() {
    super.initState();
    _currentValue = (_percentages.length - 1).toDouble();
  }

  @override
  void dispose() {
    if (widget.isAvailable &&
        _currentValue != (_percentages.length - 1).toDouble()) {
      _resetResolution(showSnackbar: false);
    }
    super.dispose();
  }

  String _getCurrentPercentageLabel() {
    int idx = _currentValue.round().clamp(0, _percentages.length - 1);
    return '${_percentages[idx]}%';
  }

  Future<void> _applyResolution(double value) async {
    if (!widget.isAvailable ||
        widget.originalSize.isEmpty ||
        widget.originalDensity <= 0) return;
    if (mounted) setState(() => _isChanging = true);

    final idx = value.round().clamp(0, _percentages.length - 1);
    final pct = _percentages[idx];

    try {
      final parts = widget.originalSize.split('x');
      final newW = (int.parse(parts[0]) * pct / 100).floor();
      final newH = (int.parse(parts[1]) * pct / 100).floor();
      final newD = (widget.originalDensity * pct / 100).floor();

      if (newW <= 0 || newH <= 0 || newD <= 0) throw Exception('Invalid dims');

      await _runRootCommandAndWait('wm size ${newW}x$newH');
      await _runRootCommandAndWait('wm density $newD');

      if (mounted) setState(() => _currentValue = value);
    } catch (e) {
      await _resetResolution();
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  Future<void> _resetResolution({bool showSnackbar = true}) async {
    if (!widget.isAvailable) return;
    if (mounted) setState(() => _isChanging = true);
    try {
      await _runRootCommandAndWait('wm size reset');
      await _runRootCommandAndWait('wm density reset');
      if (mounted) {
        setState(() => _currentValue = (_percentages.length - 1).toDouble());
      }
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.downscale_resolution,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (!widget.isAvailable)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(localization.resolution_unavailable_message,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.error),
                      textAlign: TextAlign.center))
            else ...[
              Row(
                children: [
                  Icon(Icons.screen_rotation,
                      color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _currentValue,
                      min: 0,
                      max: (_percentages.length - 1).toDouble(),
                      divisions: _percentages.length - 1,
                      label: _getCurrentPercentageLabel(),
                      onChanged: _isChanging
                          ? null
                          : (double value) {
                              if (mounted) {
                                setState(() => _currentValue = value);
                              }
                            },
                      onChangeEnd: _isChanging ? null : _applyResolution,
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
                  onPressed: _isChanging ? null : _resetResolution,
                  icon: _isChanging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: Text(localization.reset_resolution),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GameTxtCard extends StatefulWidget {
  final String initialContent;
  const GameTxtCard({Key? key, required this.initialContent}) : super(key: key);
  @override
  _GameTxtCardState createState() => _GameTxtCardState();
}

class _GameTxtCardState extends State<GameTxtCard> {
  final _controller = TextEditingController();
  bool _isSaving = false;
  final String _gameTxtPath = '/data/EnCorinVest/game.txt';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialContent;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isSaving = true);
    final newContent = _controller.text;
    try {
      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd = '''echo '$base64Content' | base64 -d > $_gameTxtPath''';
      await _runRootCommandAndWait(writeCmd);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving game.txt')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.edit_game_txt_title,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 10,
              minLines: 5,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: localization.game_txt_hint,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: textTheme.bodyMedium?.copyWith(fontSize: 14.0),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveContent,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(localization.save_button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BypassChargingCard extends StatefulWidget {
  final bool isSupported;
  final bool isEnabled;
  final String supportStatus;
  const BypassChargingCard(
      {Key? key,
      required this.isSupported,
      required this.isEnabled,
      required this.supportStatus})
      : super(key: key);
  @override
  _BypassChargingCardState createState() => _BypassChargingCardState();
}

class _BypassChargingCardState extends State<BypassChargingCard> {
  late bool _isEnabled;
  bool _isToggling = false;

  final String _configFilePath = '/data/adb/modules/EnCorinVest/encorin.txt';
  final String _controllerPath =
      '/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh';

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
  }

  Future<void> _toggleBypass(bool enable) async {
    if (!await _checkRootAccess()) return;
    if (mounted) setState(() => _isToggling = true);

    try {
      final value = enable ? 'Yes' : 'No';
      final sedCommand =
          "sed -i 's|^ENABLE_BYPASS=.*|ENABLE_BYPASS=$value|' $_configFilePath";
      await _runRootCommandAndWait(sedCommand);

      if (widget.isSupported) {
        final action = enable ? 'enable' : 'disable';
        await _runRootCommandAndWait('$_controllerPath $action');
      }

      if (mounted) setState(() => _isEnabled = enable);
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.bypass_charging_title,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(localization.bypass_charging_description,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Center(
                child: Text(widget.supportStatus,
                    style: textTheme.bodyMedium?.copyWith(
                        color: widget.isSupported
                            ? Colors.green
                            : colorScheme.error,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(localization.bypass_charging_toggle),
              value: _isEnabled,
              onChanged:
                  (_isToggling || !widget.isSupported) ? null : _toggleBypass,
              secondary: _isToggling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.battery_charging_full),
              activeColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class BackgroundSettingsCard extends StatefulWidget {
  final String? initialPath;
  final double initialOpacity;
  final Function(String?, double) onSettingsChanged;

  const BackgroundSettingsCard({
    Key? key,
    required this.initialPath,
    required this.initialOpacity,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _BackgroundSettingsCardState createState() => _BackgroundSettingsCardState();
}

class _BackgroundSettingsCardState extends State<BackgroundSettingsCard> {
  late String? _path;
  late double _opacity;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    _opacity = widget.initialOpacity;
  }

  // Update state if the parent widget provides new initial values
  @override
  void didUpdateWidget(BackgroundSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPath != oldWidget.initialPath ||
        widget.initialOpacity != oldWidget.initialOpacity) {
      setState(() {
        _path = widget.initialPath;
        _opacity = widget.initialOpacity;
      });
    }
  }

  Future<void> _pickAndSetImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('background_image_path', pickedFile.path);
        setState(() => _path = pickedFile.path);
        widget.onSettingsChanged(_path, _opacity);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _updateOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_opacity', opacity);
    widget.onSettingsChanged(_path, opacity);
  }

  Future<void> _resetBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image_path');
    await prefs.setDouble('background_opacity', 0.2);
    if (mounted) {
      setState(() {
        _path = null;
        _opacity = 0.2;
      });
    }
    widget.onSettingsChanged(null, 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.background_settings_title,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(localization.background_settings_description,
                style:
                    textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Text(localization.opacity_slider_label,
                style: textTheme.bodyMedium),
            Slider(
              value: _opacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(_opacity * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                if (mounted) {
                  setState(() => _opacity = value);
                  widget.onSettingsChanged(_path, value);
                }
              },
              onChangeEnd: _updateOpacity,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickAndSetImage,
                    child: const Icon(Icons.image),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetBackground,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer),
                    child: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//endregion
