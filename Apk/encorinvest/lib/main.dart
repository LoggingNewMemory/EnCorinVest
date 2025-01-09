import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasRootAccess = false;
  String _currentMode = 'None';
  String _executingScript = '';
  final String _modeFile = '/data/adb/modules/EnCorinVest/current_mode.txt';

  @override
  void initState() {
    super.initState();
    _checkRootAccess();
    _loadCurrentMode();
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
    return MaterialApp(
      home: Scaffold(
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
                  Image.asset(
                    'assets/logo.png',
                    height: 60,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Root Access: ${_hasRootAccess ? 'Yes' : 'No'}',
                style: TextStyle(
                  fontSize: 16,
                  color: _hasRootAccess ? Color(0xFF34C759) : Color(0xFFE74C3C),
                ),
              ),
              Text(
                'Current Mode: $_currentMode',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFECEFF4),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(height: 40),
              _buildControlRow(
                'Set the CPU Frequency to Minimum',
                'powersafe.sh',
                'Power Save',
                Color(0xFFEBCB8B),
              ),
              SizedBox(height: 20),
              _buildControlRow(
                'Back to default',
                'balanced.sh',
                'Balanced',
                Color(0xFFA3BE8C),
              ),
              SizedBox(height: 20),
              _buildControlRow(
                'ALL IN PERFORMANCE! WHO CARES\nABOUT BATTERY!',
                'performance.sh',
                'Performance',
                Color(0xFFBF616A),
              ),
              SizedBox(height: 20),
              _buildControlRow(
                'Killing every app that runs\n(including EnCorinVest app)',
                'kill.sh',
                'Kill All\nApps',
                Color(0xFFD08770),
              ),
              SizedBox(height: 20),
              _buildControlRow(
                'Cooling The Device For 2 Minutes',
                'cool.sh',
                'Cool Down',
                Color(0xFF88C0D0),
              ),
            ],
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: isExecuting ? Color(0xFFECEFF4) : buttonColor,
              foregroundColor: Color(0xFF2E3440),
              padding: EdgeInsets.symmetric(vertical: 12),
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
