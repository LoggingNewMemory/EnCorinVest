import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UtilitiesPage extends StatefulWidget {
  const UtilitiesPage({Key? key}) : super(key: key);

  @override
  _UtilitiesPageState createState() => _UtilitiesPageState();
}

class _UtilitiesPageState extends State<UtilitiesPage> {
  final String _serviceFilePath = '/data/adb/modules/EnCorinVest/service.sh';
  final String _gameTxtPath = '/data/EnCorinVest/game.txt';
  final String _configFilePath = '/data/adb/modules/EnCorinVest/encorin.txt';
  final String _encoreTweaksFilePath =
      '/data/adb/modules/EnCorinVest/Scripts/encoreTweaks.sh';
  final String _encorinFunctionFilePath =
      '/data/adb/modules/EnCorinVest/Scripts/encorinFunctions.sh';
  final String _hamadaMarker = '# Start HamadaAI (Default is Disabled)';
  final String _hamadaProcessName = 'HamadaAI';
  final String _hamadaStartCommand = 'HamadaAI';
  final String _hamadaStopCommand = 'killall HamadaAI';
  final String _hamadaCheckCommand = 'pgrep -x HamadaAI';
  final String MODULE_PATH = '/data/adb/modules/EnCorinVest';

  bool _hamadaAiEnabled = false;
  bool _hamadaStartOnBoot = false;
  bool _isHamadaCommandRunning = false;
  bool _isServiceFileUpdating = false;
  bool _isConfigUpdating = false;
  bool _resolutionServiceAvailable = false;
  bool _isResolutionChanging = false;
  double _resolutionValue = 5.0;
  bool _isGameTxtLoading = false;
  bool _isGameTxtSaving = false;
  String _gameTxtContent = '';
  final TextEditingController _gameTxtController = TextEditingController();
  bool _dndEnabled = false;
  bool _isDndConfigUpdating = false;
  bool _deviceMitigationEnabled = false;
  bool _liteModeEnabled = false;
  bool _isEncoreConfigUpdating = false;
  bool _isBypassSupported = false;
  bool _bypassEnabled = false;
  bool _isCheckingBypass = false;
  bool _isTogglingBypass = false;
  String _bypassSupportStatus = '';
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.2;
  bool _isBackgroundSettingsLoading = true;
  bool _isContentVisible = false;

  String _originalSize = '';
  int _originalDensity = 0;
  final List<int> _resolutionPercentages = [50, 60, 70, 80, 90, 100];

  // Governor settings
  List<String> _availableGovernors = [];
  String? _selectedGovernor;
  bool _isLoadingGovernors = true;
  bool _isSavingGovernor = false;

  @override
  void initState() {
    super.initState();
    _initializeUtilities();
  }

  Future<void> _initializeUtilities() async {
    await _loadBackgroundSettings();
    await _loadEncoreSwitchState();
    await _checkHamadaProcessStatus();
    await _readAndApplyDndConfig();
    await _checkResolutionServiceAvailability();
    await _checkHamadaStartOnBoot();
    await _loadGameTxt();
    await _loadInitialBypassState();
    await _loadAvailableGovernors();
    await _loadSelectedGovernor();
    if (mounted) {
      setState(() {
        _isContentVisible = true;
      });
    }
  }

  Future<void> _loadBackgroundSettings() async {
    if (!mounted) return;
    setState(() => _isBackgroundSettingsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('background_image_path');
      final opacity = prefs.getDouble('background_opacity') ?? 0.2;
      if (mounted) {
        setState(() {
          _backgroundImagePath = path;
          _backgroundOpacity = opacity;
        });
      }
    } catch (e) {
      // Error loading background settings
    } finally {
      if (mounted) setState(() => _isBackgroundSettingsLoading = false);
    }
  }

  Future<void> _pickAndSetImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('background_image_path', pickedFile.path);
        setState(() {
          _backgroundImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: ${e.toString()}')));
      }
    }
  }

  Future<void> _updateOpacity(double opacity) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_opacity', opacity);
  }

  Future<void> _resetBackground() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image_path');
    await prefs.setDouble('background_opacity', 0.2);
    if (mounted) {
      setState(() {
        _backgroundImagePath = null;
        _backgroundOpacity = 0.2;
      });
    }
  }

  Future<ProcessResult> _runRootCommandAndWait(String command) async {
    try {
      return await Process.run('su', ['-c', command]);
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
      if (result.exitCode == 0 && result.stdout.toString().contains('uid=0')) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadAvailableGovernors() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isLoadingGovernors = true);
    try {
      final result = await _runRootCommandAndWait(
          'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors');
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        final governors = result.stdout.toString().trim().split(' ');
        if (mounted) {
          setState(() {
            _availableGovernors = governors;
          });
        }
      }
    } catch (e) {
      // Error loading governors
    } finally {
      if (mounted) setState(() => _isLoadingGovernors = false);
    }
  }

  Future<void> _loadSelectedGovernor() async {
    if (!await _checkRootAccess() || !mounted) return;
    try {
      final result = await _runRootCommandAndWait('cat $_configFilePath');
      if (result.exitCode == 0) {
        final content = result.stdout.toString();
        final match =
            RegExp(r'^GOV=(.*)$', multiLine: true).firstMatch(content);
        if (match != null) {
          final gov = match.group(1)?.trim();
          if (gov != null && gov.isNotEmpty) {
            if (mounted) {
              setState(() {
                _selectedGovernor = gov;
              });
            }
          }
        }
      }
    } catch (e) {
      // Error loading selected governor
    }
  }

  Future<void> _saveGovernor(String? governor) async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isSavingGovernor = true);
    final valueString = governor ?? '';

    try {
      final readResult = await _runRootCommandAndWait('cat $_configFilePath');
      if (readResult.exitCode != 0) {
        throw Exception('Failed to read config file');
      }

      String content = readResult.stdout.toString();

      if (content.contains(RegExp(r'^GOV=', multiLine: true))) {
        content = content.replaceAll(
          RegExp(r'^GOV=.*$', multiLine: true),
          'GOV=$valueString',
        );
      } else {
        content = content.trimRight();
        if (content.isNotEmpty) content += '\n';
        content += 'GOV=$valueString\n';
      }

      String base64Content = base64Encode(utf8.encode(content));
      final writeCommand =
          '''echo '$base64Content' | base64 -d > $_configFilePath''';
      final writeResult = await _runRootCommandAndWait(writeCommand);

      if (writeResult.exitCode == 0) {
        if (mounted) setState(() => _selectedGovernor = governor);
      } else {
        throw Exception('Failed to write to config file');
      }
    } catch (e) {
      // Error saving governor
    } finally {
      if (mounted) setState(() => _isSavingGovernor = false);
    }
  }

  Future<void> _loadEncoreSwitchState() async {
    if (!await _checkRootAccess() || !mounted) return;

    final result = await _runRootCommandAndWait('cat $_encoreTweaksFilePath');
    if (result.exitCode == 0) {
      final content = result.stdout.toString();
      final mitigationMatch =
          RegExp(r'^DEVICE_MITIGATION=(\d)', multiLine: true)
              .firstMatch(content);
      final liteMatch =
          RegExp(r'^LITE_MODE=(\d)', multiLine: true).firstMatch(content);

      if (mounted) {
        setState(() {
          _deviceMitigationEnabled = mitigationMatch?.group(1) == '1';
          _liteModeEnabled = liteMatch?.group(1) == '1';
        });
      }
    }
  }

  // UPDATED FUNCTION
  Future<void> _updateEncoreTweak(String key, bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;

    setState(() => _isEncoreConfigUpdating = true);

    try {
      final value = enable ? '1' : '0';

      // --- 1. Update encoreTweaks.sh (existing logic) ---
      final readResult =
          await _runRootCommandAndWait('cat $_encoreTweaksFilePath');
      if (readResult.exitCode != 0) {
        throw Exception('Failed to read encoreTweaks.sh');
      }

      String content = readResult.stdout.toString();
      content = content.replaceAll(
        RegExp('^$key=.*\$', multiLine: true),
        '$key=$value',
      );

      String base64Content = base64Encode(utf8.encode(content));
      final writeCmd =
          '''echo '$base64Content' | base64 -d > $_encoreTweaksFilePath''';

      final writeResult = await _runRootCommandAndWait(writeCmd);
      if (writeResult.exitCode != 0) {
        throw Exception('Failed to write to encoreTweaks.sh');
      }

      // --- 2. Update encorinFuction.sh (new logic) ---
      final sedCommand =
          "sed -i 's|^$key=.*|$key=$value|' $_encorinFunctionFilePath";
      final sedResult = await _runRootCommandAndWait(sedCommand);
      if (sedResult.exitCode != 0) {
        // Optionally, you could try to revert the change to encoreTweaks.sh here
        throw Exception(
            'Failed to write to encorinFuction.sh. Error: ${sedResult.stderr}');
      }

      // --- 3. Update UI State ---
      if (mounted) {
        setState(() {
          if (key == 'DEVICE_MITIGATION') {
            _deviceMitigationEnabled = enable;
          } else if (key == 'LITE_MODE') {
            _liteModeEnabled = enable;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Revert UI on failure
        setState(() {
          if (key == 'DEVICE_MITIGATION') {
            _deviceMitigationEnabled = !enable;
          } else if (key == 'LITE_MODE') {
            _liteModeEnabled = !enable;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update settings: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isEncoreConfigUpdating = false);
    }
  }

  Future<bool?> _readDndConfig() async {
    if (!await _checkRootAccess()) return null;

    final result = await _runRootCommandAndWait('cat $_configFilePath');
    if (result.exitCode == 0) {
      final content = result.stdout.toString();
      final match = RegExp(r'^DND=(.*)$', multiLine: true).firstMatch(content);
      if (match != null) {
        return match.group(1)?.trim().toLowerCase() == 'yes';
      }
    }
    return false;
  }

  Future<bool> _writeDndConfig(bool enabled) async {
    if (!await _checkRootAccess() || !mounted) return false;

    setState(() => _isDndConfigUpdating = true);
    final valueString = enabled ? 'Yes' : 'No';

    try {
      final readResult = await _runRootCommandAndWait('cat $_configFilePath');
      if (readResult.exitCode != 0) {
        return false;
      }

      String content = readResult.stdout.toString();

      if (content.contains(RegExp(r'^DND=', multiLine: true))) {
        content = content.replaceAll(
          RegExp(r'^DND=.*$', multiLine: true),
          'DND=$valueString',
        );

        String base64Content = base64Encode(utf8.encode(content));
        final writeCommand =
            '''echo '$base64Content' | base64 -d > $_configFilePath''';
        final writeResult = await _runRootCommandAndWait(writeCommand);

        if (writeResult.exitCode == 0) {
          if (mounted) setState(() => _dndEnabled = enabled);
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
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
      });
    }
  }

  Future<void> _toggleDnd(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    if (_isDndConfigUpdating) return;
    await _writeDndConfig(enable);
  }

  Future<void> _checkHamadaProcessStatus() async {
    if (!await _checkRootAccess()) return;
    final result = await _runRootCommandAndWait(_hamadaCheckCommand);
    if (mounted) {
      setState(() {
        _hamadaAiEnabled = result.exitCode == 0;
      });
    }
  }

  Future<void> _toggleHamadaAI(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    if (_isHamadaCommandRunning) return;

    setState(() => _isHamadaCommandRunning = true);
    try {
      if (enable) {
        await _runRootCommandFireAndForget(_hamadaStartCommand);
        await Future.delayed(Duration(milliseconds: 500));
        await _checkHamadaProcessStatus();
      } else {
        await _runRootCommandAndWait(_hamadaStopCommand);
        if (mounted) {
          setState(() => _hamadaAiEnabled = false);
        }
      }
    } catch (e) {
      // Error toggling Hamada AI
    } finally {
      if (mounted) setState(() => _isHamadaCommandRunning = false);
    }
  }

  Future<void> _checkHamadaStartOnBoot() async {
    if (!await _checkRootAccess()) return;
    final result = await _runRootCommandAndWait('cat $_serviceFilePath');
    if (result.exitCode == 0) {
      if (mounted)
        setState(() =>
            _hamadaStartOnBoot = result.stdout.toString().contains('HamadaAI'));
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
        throw Exception('Failed to read service file');
      }

      String content = readResult.stdout.toString();
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
      final writeResult = await _runRootCommandAndWait(writeCmd);

      if (writeResult.exitCode != 0) {
        throw Exception('Failed to write to service file');
      }

      if (mounted) setState(() => _hamadaStartOnBoot = enable);
    } catch (e) {
      if (mounted) setState(() => _hamadaStartOnBoot = !enable);
    } finally {
      if (mounted) setState(() => _isServiceFileUpdating = false);
    }
  }

  Future<void> _checkResolutionServiceAvailability() async {
    try {
      final sr = await _runRootCommandAndWait('wm size');
      final dr = await _runRootCommandAndWait('wm density');
      bool available = sr.exitCode == 0 &&
          sr.stdout.toString().contains('Physical size:') &&
          dr.exitCode == 0 &&
          (dr.stdout.toString().contains('Physical density:') ||
              dr.stdout.toString().contains('Override density:'));

      if (mounted) setState(() => _resolutionServiceAvailable = available);

      if (available) {
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
      if (sm != null && sm.group(1) != null) {
        _originalSize = sm.group(1)!;
      } else {
        if (mounted) setState(() => _resolutionServiceAvailable = false);
        return;
      }

      final dr = await _runRootCommandAndWait('wm density');
      final dm = RegExp(r'(?:Physical|Override) density:\s*([0-9]+)')
          .firstMatch(dr.stdout.toString());
      if (dm != null && dm.group(1) != null) {
        _originalDensity = int.tryParse(dm.group(1)!) ?? 0;
        if (_originalDensity == 0) {
          if (mounted) setState(() => _resolutionServiceAvailable = false);
        }
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
      final origW = int.parse(parts[0]);
      final origH = int.parse(parts[1]);
      final newW = (origW * pct / 100).floor();
      final newH = (origH * pct / 100).floor();
      final newD = (_originalDensity * pct / 100).floor();

      if (newW <= 0 || newH <= 0 || newD <= 0)
        throw FormatException('Calculated invalid dimensions or density');

      final sr = await _runRootCommandAndWait('wm size ${newW}x${newH}');
      if (sr.exitCode != 0) throw Exception('Set size failed');

      final dr = await _runRootCommandAndWait('wm density $newD');
      if (dr.exitCode != 0) {
        await _runRootCommandAndWait('wm size reset');
        throw Exception('Set density failed');
      }
      if (mounted) setState(() => _resolutionValue = value);
    } catch (e) {
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
      await _runRootCommandAndWait('wm size reset');
      await _runRootCommandAndWait('wm density reset');
      if (mounted)
        setState(() =>
            _resolutionValue = (_resolutionPercentages.length - 1).toDouble());
    } catch (e) {
      // Error resetting resolution
    } finally {
      if (mounted) setState(() => _isResolutionChanging = false);
    }
  }

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
          setState(() {
            _gameTxtContent = '';
            _gameTxtController.text = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
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
    final newContent = _gameTxtController.text;
    try {
      String base64Content = base64Encode(utf8.encode(newContent));
      final writeCmd = '''echo '$base64Content' | base64 -d > $_gameTxtPath''';
      final result = await _runRootCommandAndWait(writeCmd);
      if (mounted) {
        if (result.exitCode == 0) {
          setState(() => _gameTxtContent = newContent);
        }
      }
    } catch (e) {
      // Error saving game.txt
    } finally {
      if (mounted) setState(() => _isGameTxtSaving = false);
    }
  }

  Future<void> _loadInitialBypassState() async {
    if (!await _checkRootAccess() || !mounted) return;
    try {
      await _checkBypassSupport();
      final result = await _runRootCommandAndWait('cat $_configFilePath');
      if (result.exitCode == 0) {
        final content = result.stdout.toString();
        final enabledMatch = RegExp(r'^ENABLE_BYPASS=(Yes|No)', multiLine: true)
            .firstMatch(content);
        if (mounted) {
          setState(() {
            _bypassEnabled = enabledMatch?.group(1)?.toLowerCase() == 'yes';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _bypassEnabled = false);
    }
  }

  Future<void> _checkBypassSupport() async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() {
      _isCheckingBypass = true;
      _bypassSupportStatus = '';
    });

    try {
      final controllerPath =
          '/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh';
      final result = await _runRootCommandAndWait('$controllerPath test');

      if (mounted) {
        final localization = AppLocalizations.of(context)!;
        final output = result.stdout.toString().toLowerCase().trim();
        setState(() {
          if (output.contains('supported')) {
            _isBypassSupported = true;
            _bypassSupportStatus = localization.bypass_charging_supported;
          } else {
            _isBypassSupported = false;
            _bypassSupportStatus = localization.bypass_charging_unsupported;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final localization = AppLocalizations.of(context)!;
        setState(() {
          _isBypassSupported = false;
          _bypassSupportStatus = localization.bypass_charging_unsupported;
        });
      }
    } finally {
      if (mounted) setState(() => _isCheckingBypass = false);
    }
  }

  Future<bool> _updateBypassConfig(bool enabled) async {
    try {
      final value = enabled ? 'Yes' : 'No';
      final configPath = _configFilePath;
      final checkResult =
          await _runRootCommandAndWait("grep -q '^ENABLE_BYPASS=' $configPath");
      if (checkResult.exitCode != 0) return false;

      final sedCommand =
          "sed -i 's|^ENABLE_BYPASS=.*|ENABLE_BYPASS=$value|' $configPath";
      final sedResult = await _runRootCommandAndWait(sedCommand);
      return sedResult.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleBypassCharging(bool enable) async {
    if (!await _checkRootAccess() || !mounted) return;
    setState(() => _isTogglingBypass = true);

    try {
      await _updateBypassConfig(enable);
      if (_isBypassSupported) {
        final controllerPath =
            '/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh';
        final action = enable ? 'enable' : 'disable';
        await _runRootCommandAndWait('$controllerPath $action');
      }
      if (mounted) setState(() => _bypassEnabled = enable);
    } catch (e) {
      // Error toggling bypass charging
    } finally {
      if (mounted) setState(() => _isTogglingBypass = false);
    }
  }

  @override
  void dispose() {
    if (_resolutionServiceAvailable &&
        _resolutionValue != (_resolutionPercentages.length - 1).toDouble()) {
      _resetResolution(showSnackbar: false);
    }
    _gameTxtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.transparent);
                },
              ),
            ),
          AnimatedOpacity(
            opacity: _isContentVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            localization.encore_switch_title,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.encore_switch_description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: Text(localization.device_mitigation_title),
                            subtitle: Text(
                                localization.device_mitigation_description),
                            value: _deviceMitigationEnabled,
                            onChanged: _isEncoreConfigUpdating
                                ? null
                                : (bool value) => _updateEncoreTweak(
                                    'DEVICE_MITIGATION', value),
                            secondary: _isEncoreConfigUpdating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.security_update_warning),
                            activeColor: colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: Text(localization.lite_mode_title),
                            subtitle: Text(localization.lite_mode_description),
                            value: _liteModeEnabled,
                            onChanged: _isEncoreConfigUpdating
                                ? null
                                : (bool value) =>
                                    _updateEncoreTweak('LITE_MODE', value),
                            secondary: _isEncoreConfigUpdating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.flourescent),
                            activeColor: colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            localization.custom_governor_title,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.custom_governor_description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingGovernors)
                            Center(
                                child: Column(
                              children: [
                                CircularProgressIndicator(),
                                const SizedBox(height: 8),
                                Text(localization.loading_governors),
                              ],
                            ))
                          else if (_availableGovernors.isEmpty)
                            Center(
                              child: Text(
                                'No governors found or root access denied.',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _availableGovernors
                                      .contains(_selectedGovernor)
                                  ? _selectedGovernor
                                  : null,
                              hint: Text(localization.no_governor_selected),
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: _isSavingGovernor
                                  ? null
                                  : (String? newValue) {
                                      _saveGovernor(newValue);
                                    },
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child:
                                      Text(localization.no_governor_selected),
                                ),
                                ..._availableGovernors
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
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
                            localization.dnd_title,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.dnd_description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: Text(localization.dnd_toggle_title),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.bedtime),
                            activeColor: colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            localization.hamada_ai,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.hamada_ai_description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: Text(localization.hamada_ai_toggle_title),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.psychology_alt),
                            activeColor: colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: Text(localization.hamada_ai_start_on_boot),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.rocket_launch),
                            activeColor: colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            localization.downscale_resolution,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (!_resolutionServiceAvailable)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                localization.resolution_unavailable_message,
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
                                    divisions:
                                        _resolutionPercentages.length - 1,
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
                                    inactiveColor: colorScheme.onSurfaceVariant
                                        .withOpacity(0.3),
                                  ),
                                ),
                                Text(_getCurrentPercentageLabel(),
                                    style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  foregroundColor:
                                      colorScheme.onSecondaryContainer,
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
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Icon(Icons.refresh),
                                label: Text(localization.reset_resolution),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
                            localization.edit_game_txt_title,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _gameTxtController,
                            maxLines: 10,
                            minLines: 5,
                            enabled: !_isGameTxtLoading && !_isGameTxtSaving,
                            decoration: InputDecoration(
                              hintText: localization.game_txt_hint,
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
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    foregroundColor:
                                        colorScheme.onPrimaryContainer,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _isGameTxtSaving
                                      ? null
                                      : () => _saveGameTxt(),
                                  icon: _isGameTxtSaving
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Icon(Icons.save),
                                  label: Text(localization.save_button),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            localization.bypass_charging_title,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.bypass_charging_description,
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
                            title: Text(localization.bypass_charging_toggle),
                            value: _bypassEnabled,
                            onChanged:
                                (_isTogglingBypass || !_isBypassSupported)
                                    ? null
                                    : (bool value) {
                                        _toggleBypassCharging(value);
                                      },
                            secondary: _isTogglingBypass
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.battery_charging_full),
                            activeColor: colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            localization.background_settings_title,
                            style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.background_settings_description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isBackgroundSettingsLoading)
                            Center(child: CircularProgressIndicator())
                          else ...[
                            Text(localization.opacity_slider_label,
                                style: textTheme.bodyMedium),
                            Slider(
                              value: _backgroundOpacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              label: (_backgroundOpacity * 100)
                                      .toStringAsFixed(0) +
                                  '%',
                              onChanged: (value) {
                                setState(() => _backgroundOpacity = value);
                              },
                              onChangeEnd: (value) {
                                _updateOpacity(value);
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _pickAndSetImage,
                                    child: Icon(Icons.image),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      foregroundColor:
                                          colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _resetBackground,
                                    child: Icon(Icons.refresh),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.errorContainer,
                                      foregroundColor:
                                          colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
