import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF2E3440), // Set the background color here
        body: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding around the column
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.start, // Align content at the top
            children: [
              // Custom Title and Subtitle
              Column(
                children: [
                  SizedBox(height: 40), // Space between subtitle and image
                  Text(
                    'EnCorinVest',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFECEFF4)), // Set text color to #eceff4
                  ),
                  Text(
                    'By: Kanagawa Yamada',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4)), // Set text color to #eceff4
                  ),
                  SizedBox(height: 20), // Space between button sections
                  Image.asset(
                    'assets/logo.png', // Replace with your image path
                    height: 100, // Adjust height as needed
                  ),
                  SizedBox(height: 20), // Space between image and buttons
                ],
              ),
              // Power Save Button with Description
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the description
                children: [
                  Text(
                    'Set the CPU Frequency to Minimum',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4)), // Set text color to #eceff4
                    textAlign: TextAlign.center, // Center the text
                  ),
                  SizedBox(
                    width: double.infinity, // Fill the width
                    child: ElevatedButton(
                      onPressed: () async {
                        await executeScript('powersafe.sh');
                      },
                      child: Text('Power Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBCB8B),
                        foregroundColor: Color(0xFF2E3440),
                        padding: EdgeInsets.symmetric(
                            vertical: 12), // Adjust vertical padding
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Space between button sections
                ],
              ),
              // Balanced Button with Description
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the description
                children: [
                  Text(
                    'Back to default',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4)), // Set text color to #eceff4
                    textAlign: TextAlign.center, // Center the text
                  ),
                  SizedBox(
                    width: double.infinity, // Fill the width
                    child: ElevatedButton(
                      onPressed: () async {
                        await executeScript('balanced.sh');
                      },
                      child: Text('Balanced'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA3BE8C),
                        foregroundColor: Color(0xFF2E3440),
                        padding: EdgeInsets.symmetric(
                            vertical: 12), // Adjust vertical padding
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Space between button sections
                ],
              ),
              // Performance Button with Description
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the description
                children: [
                  Text(
                    'ALL IN PERFORMANCE! WHO CARES ABOUT BATTERY!',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4)), // Set text color to #eceff4
                    textAlign: TextAlign.center, // Center the text
                  ),
                  SizedBox(
                    width: double.infinity, // Fill the width
                    child: ElevatedButton(
                      onPressed: () async {
                        await executeScript('performance.sh');
                      },
                      child: Text('Performance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBF616A),
                        foregroundColor: Color(0xFF2E3440),
                        padding: EdgeInsets.symmetric(
                            vertical: 12), // Adjust vertical padding
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Space between button sections
                ],
              ),
              // Kill All Apps Button with Description
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the description
                children: [
                  Text(
                    'Killing every app that runs (Including EnCorinVest app)',
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFECEFF4)), // Set text color to #eceff4
                    textAlign: TextAlign.center, // Center the text
                  ),
                  SizedBox(
                    width: double.infinity, // Fill the width
                    child: ElevatedButton(
                      onPressed: () async {
                        await executeScript('kill.sh');
                      },
                      child: Text('Kill All Apps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD08770),
                        foregroundColor: Color(0xFF2E3440),
                        padding: EdgeInsets.symmetric(
                            vertical: 12), // Adjust vertical padding
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> executeScript(String scriptName) async {
    try {
      // Replace '/path/to/' with the actual path where your scripts are located
      var result = await run(
          'su', ['-c', '/data/adb/modules/EnCorinVest/Scripts/$scriptName']);
      print('Output: ${result.stdout}');
      print('Error: ${result.stderr}');
    } catch (e) {
      print('Error executing script: $e');
    }
  }
}
