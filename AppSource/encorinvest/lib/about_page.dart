import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import '/l10n/app_localizations.dart';
import 'dart:io'; // Added for file operations
import 'package:shared_preferences/shared_preferences.dart'; // Added for local storage

class AboutPage extends StatefulWidget {
  AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _deviceModel = 'Loading...';
  String _cpuInfo = 'Loading...';
  String _osVersion = 'Loading...';
  bool _isLoading = true;

  // --- NEW: State for background image ---
  String? _backgroundImagePath;
  double _backgroundOpacity = 0.2;
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadBackgroundSettings(); // --- NEW: Load background settings on start ---
  }

  // --- NEW: Method to load background settings from SharedPreferences ---
  Future<void> _loadBackgroundSettings() async {
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
      print("Error loading background settings in about_page: $e");
    }
  }
  // --- END NEW ---

  Future<bool> _checkRootAccessInAbout() async {
    try {
      var result = await run('su', ['-c', 'id'], verbose: false);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadDeviceInfo() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    bool rootGranted = await _checkRootAccessInAbout();

    String deviceModel = 'N/A';
    String cpuInfo = 'N/A';
    String osVersion = 'N/A';

    if (rootGranted) {
      try {
        var deviceResult =
            await run('su', ['-c', 'getprop ro.product.model'], verbose: false);
        deviceModel = deviceResult.stdout.toString().trim();

        var cpuResult = await run('su', ['-c', 'getprop ro.board.platform'],
            verbose: false);
        cpuInfo = cpuResult.stdout.toString().trim();
        if (cpuInfo.isEmpty || cpuInfo.toLowerCase() == 'unknown') {
          cpuResult =
              await run('su', ['-c', 'getprop ro.hardware'], verbose: false);
          cpuInfo = cpuResult.stdout.toString().trim();
        }
        if (cpuInfo.isEmpty || cpuInfo.toLowerCase() == 'unknown') {
          cpuResult = await run(
              'su', ['-c', 'cat /proc/cpuinfo | grep Hardware | cut -d: -f2'],
              verbose: false);
          cpuInfo = cpuResult.stdout.toString().trim();
        }

        var osResult = await run(
            'su', ['-c', 'getprop ro.build.version.release'],
            verbose: false);
        osVersion = 'Android ' + osResult.stdout.toString().trim();
      } catch (e) {
        deviceModel = 'Error';
        cpuInfo = 'Error';
        osVersion = 'Error';
        print("Error loading device info: $e");
      }
    } else {
      deviceModel = 'Root Required';
      cpuInfo = 'Root Required';
      osVersion = 'Root Required';
    }

    if (mounted) {
      setState(() {
        _deviceModel = deviceModel.isEmpty ? 'N/A' : deviceModel;
        _cpuInfo = cpuInfo.isEmpty ? 'N/A' : cpuInfo;
        _osVersion = osVersion.isEmpty ? 'N/A' : osVersion;
        _isLoading = false;
      });
    }
  }

  // Helper to get credit strings dynamically
  List<String> _getCredits(AppLocalizations localization) {
    return [
      localization.credits_1,
      localization.credits_2,
      localization.credits_3,
      localization.credits_4,
      localization.credits_5,
      localization.credits_6,
      localization.credits_7,
      localization.credits_8,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final List<String> credits = _getCredits(localization);

    return Scaffold(
      // --- MODIFIED: Make background transparent ---
      backgroundColor: Colors.transparent,
      // --- END MODIFIED ---
      appBar: AppBar(
        // --- MODIFIED: Make AppBar transparent ---
        backgroundColor: Colors.transparent,
        elevation: 0,
        // --- END MODIFIED ---
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- NEW: Background Image Layer ---
          if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty)
            Opacity(
              opacity: _backgroundOpacity,
              child: Image.file(
                File(_backgroundImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading background image in about_page: $error");
                  return Container(color: Colors.transparent);
                },
              ),
            ),
          // --- END NEW ---
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                    localization.device, _deviceModel),
                                _buildInfoRow(localization.cpu, _cpuInfo),
                                _buildInfoRow(localization.os, _osVersion),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          localization.about_title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline),
                        ),
                        SizedBox(height: 15),
                        ...credits.map((creditText) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 3),
                              child: Text(
                                '• $creditText',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )),
                        SizedBox(height: 20),
                        Text(
                          localization.about_note,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            localization.about_quote,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
        ],
      ),
    );
  }

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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
