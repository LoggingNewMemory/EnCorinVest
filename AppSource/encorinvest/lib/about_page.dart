import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import '/l10n/app_localizations.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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

  String? _backgroundImagePath;
  double _backgroundOpacity = 0.2;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadBackgroundSettings(),
      _loadDeviceInfo(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBackgroundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final path = prefs.getString('background_image_path');
      final opacity = prefs.getDouble('background_opacity') ?? 0.2;
      setState(() {
        _backgroundImagePath = path;
        _backgroundOpacity = opacity;
      });
    } catch (e) {
      // Error loading background settings
    }
  }

  Future<bool> _checkRootAccessInAbout() async {
    try {
      var result = await run('su', ['-c', 'id'], verbose: false);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadDeviceInfo() async {
    final rootGranted = await _checkRootAccessInAbout();

    String deviceModel = 'N/A';
    String cpuInfo = 'N/A';
    String osVersion = 'N/A';

    if (rootGranted) {
      try {
        final results = await Future.wait([
          run('su', ['-c', 'getprop ro.product.model'], verbose: false),
          run('su', ['-c', 'getprop ro.board.platform'], verbose: false),
          run('su', ['-c', 'getprop ro.hardware'], verbose: false),
          run('su', ['-c', 'cat /proc/cpuinfo | grep Hardware | cut -d: -f2'],
              verbose: false),
          run('su', ['-c', 'getprop ro.build.version.release'], verbose: false),
        ]);

        deviceModel = results[0].stdout.toString().trim();
        cpuInfo = results[1].stdout.toString().trim();

        if (cpuInfo.isEmpty || cpuInfo.toLowerCase() == 'unknown') {
          cpuInfo = results[2].stdout.toString().trim();
        }
        if (cpuInfo.isEmpty || cpuInfo.toLowerCase() == 'unknown') {
          cpuInfo = results[3].stdout.toString().trim();
        }

        osVersion = 'Android ' + results[4].stdout.toString().trim();
      } catch (e) {
        deviceModel = 'Error';
        cpuInfo = 'Error';
        osVersion = 'Error';
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
      });
    }
  }

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
    final credits = _getCredits(localization);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: _isLoading
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: LinearProgressIndicator(),
                  ))
                : AnimatedOpacity(
                    opacity: _isLoading ? 0.0 : 1.0,
                    duration: Duration(milliseconds: 500),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 0,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
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
