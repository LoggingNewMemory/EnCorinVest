import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'languages.dart';

class AboutPage extends StatefulWidget {
  final String selectedLanguage;

  AboutPage({required this.selectedLanguage});

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _deviceModel = 'Loading...';
  String _cpuInfo = 'Loading...';
  String _osVersion = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
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

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations(widget.selectedLanguage);
    final List<String> credits = [
      'credits_1',
      'credits_2',
      'credits_3',
      'credits_4',
      'credits_5',
      'credits_6',
      'credits_7',
      'credits_8'
    ];

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                                localization.translate('device'), _deviceModel),
                            _buildInfoRow(
                                localization.translate('cpu'), _cpuInfo),
                            _buildInfoRow(
                                localization.translate('os'), _osVersion),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      localization.translate('about_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                    SizedBox(height: 15),
                    ...credits.map((creditKey) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '• ${localization.translate(creditKey)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )),
                    SizedBox(height: 20),
                    Text(
                      localization.translate('about_note'),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        localization.translate('about_quote'),
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
