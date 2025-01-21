import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _deviceModel = 'Loading...';
  String _cpuInfo = 'Loading...';
  String _osVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      var deviceResult = await run('su', ['-c', 'getprop ro.product.model']);
      var cpuResult = await run('su', ['-c', 'getprop ro.hardware']);
      var osResult =
          await run('su', ['-c', 'getprop ro.build.version.release']);

      setState(() {
        _deviceModel = deviceResult.stdout.toString().trim();
        _cpuInfo = cpuResult.stdout.toString().split(':').last.trim();
        _osVersion = 'Android ' + osResult.stdout.toString().trim();
      });
    } catch (e) {
      print('Error loading device info: $e');
      setState(() {
        _deviceModel = 'Unknown';
        _cpuInfo = 'Unknown';
        _osVersion = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E3440),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E3440),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF8FBCBB)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoRow('Device:', _deviceModel),
                      _buildInfoRow('CPU:', _cpuInfo),
                      _buildInfoRow('OS:', _osVersion),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/KLC.png',
                  height: 80,
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Thank you for the great people who helped improve EnCorinVest:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFECEFF4),
              ),
            ),
            SizedBox(height: 15),
            ...[
              'Rem01 Gaming',
              'PersonPenggoreng',
              'MiAzami',
              'Kazuyoo',
              'RiProG',
              'Lieudahbelajar',
              'KLD - Kanagawa Lab Dev',
              'And All Testers That I Can\'t Mentioned One by One'
            ].map((name) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $name',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFECEFF4),
                    ),
                  ),
                )),
            SizedBox(height: 20),
            Text(
              'EnCorinVest Is Always Free, Open Source, and Open For Improvement',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFFECEFF4),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '"Great Collaboration Lead to Great Innovation"\n~ Kanagawa Yamada (Main Dev)',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFF8FBCBB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFECEFF4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF8FBCBB),
          ),
        ),
      ],
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _hasRootAccess = false;
  bool _moduleInstalled = false;
  String _moduleVersion = 'Unknown';
  String _currentMode = 'None';
  String _executingScript = '';
  final String _modeFile = '/data/adb/modules/EnCorinVest/current_mode.txt';

  @override
  void initState() {
    super.initState();
    _checkRootAccess();
    _loadCurrentMode();
    _checkModuleInstalled();
    _getModuleVersion();
  }

  Future<void> _loadCurrentMode() async {
    try {
      var result = await run('su', ['-c', 'cat $_modeFile']);
      if (result.stdout.toString().trim().isNotEmpty) {
        setState(() {
          _currentMode = result.stdout.toString().trim().toUpperCase();
        });
      }
    } catch (e) {
      print('Error loading mode: $e');
    }
  }

  Future<void> _saveCurrentMode(String mode) async {
    try {
      await run('su', ['-c', 'echo "$mode" > $_modeFile']);
    } catch (e) {
      print('Error saving mode: $e');
    }
  }

  Future<void> _checkRootAccess() async {
    try {
      var result = await run('su', ['-c', 'id']);
      setState(() {
        _hasRootAccess = result.exitCode == 0;
      });
    } catch (e) {
      setState(() {
        _hasRootAccess = false;
      });
    }
  }

  Future<void> _checkModuleInstalled() async {
    try {
      var result = await run(
          'su', ['-c', 'test -d /data/adb/modules/EnCorinVest && echo "yes"']);
      setState(() {
        _moduleInstalled = result.stdout.toString().trim() == 'yes';
      });
    } catch (e) {
      setState(() {
        _moduleInstalled = false;
      });
    }
  }

  Future<void> _getModuleVersion() async {
    try {
      var result = await run('su',
          ['-c', 'grep "version=" /data/adb/modules/EnCorinVest/module.prop']);
      String version = result.stdout.toString().trim();
      if (version.isNotEmpty) {
        version = version.split('=')[1];
        setState(() {
          _moduleVersion = version;
        });
      }
    } catch (e) {
      print('Error getting module version: $e');
    }
  }

  Future<void> executeScript(String scriptName, String buttonText) async {
    if (_executingScript.isNotEmpty) return;

    setState(() {
      _executingScript = scriptName;
    });

    try {
      var result = await run(
          'su', ['-c', '/data/adb/modules/EnCorinVest/Scripts/$scriptName']);
      var mode = scriptName.replaceAll('.sh', '').toUpperCase();
      await _saveCurrentMode(mode);
      setState(() {
        _currentMode = mode;
      });
      print('Output: ${result.stdout}');
      print('Error: ${result.stderr}');
    } catch (e) {
      print('Error executing script: $e');
    } finally {
      setState(() {
        _executingScript = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E3440),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EnCorinVest',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                    Text(
                      'By: Kanagawa Yamada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutPage()),
                    );
                  },
                  child: Image.asset(
                    'assets/logo.png',
                    height: 60,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Root Access:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                    Text(
                      'Module Installed:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                    Text(
                      'Module Version:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                    Text(
                      'Current Mode:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasRootAccess ? 'Yes' : 'No',
                      style: TextStyle(
                        fontSize: 16,
                        color: _hasRootAccess
                            ? Color(0xFF34C759)
                            : Color(0xFFE74C3C),
                      ),
                    ),
                    Text(
                      _moduleInstalled ? 'Yes' : 'No',
                      style: TextStyle(
                        fontSize: 16,
                        color: _moduleInstalled
                            ? Color(0xFF34C759)
                            : Color(0xFFE74C3C),
                      ),
                    ),
                    Text(
                      _moduleVersion,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                    Text(
                      _currentMode,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildControlRow(
              'Prioritizing Battery Over Performance',
              'powersafe.sh',
              'Power Save',
              Color(0xFFEBCB8B),
            ),
            SizedBox(height: 20),
            _buildControlRow(
              'Balance Battery and Performance',
              'balanced.sh',
              'Balanced',
              Color(0xFFA3BE8C),
            ),
            SizedBox(height: 20),
            _buildControlRow(
              'Prioritizing Performance Over Battery',
              'performance.sh',
              'Performance',
              Color(0xFFBF616A),
            ),
            SizedBox(height: 20),
            _buildControlRow(
              'Clear RAM By Killing All Apps',
              'kill.sh',
              'Clear',
              Color(0xFFD08770),
            ),
            SizedBox(height: 20),
            _buildControlRow(
              'Cool Down Your Device\n(Let It Rest for 2 Minutes)',
              'cool.sh',
              'Cool Down',
              Color(0xFF88C0D0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow(String description, String scriptName,
      String buttonText, Color buttonColor) {
    bool isExecuting = _executingScript == scriptName;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFECEFF4),
            ),
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: isExecuting
                ? null
                : () => executeScript(scriptName, buttonText),
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Color(0xFFECEFF4);
                }
                return isExecuting ? Color(0xFFECEFF4) : buttonColor;
              }),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                return Color(0xFF2E3440);
              }),
              padding:
                  MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 12)),
            ),
            child: Text(
              isExecuting ? 'Executing' : buttonText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
