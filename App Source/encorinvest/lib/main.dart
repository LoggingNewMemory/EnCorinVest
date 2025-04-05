import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:async';

class LangEN {
  static const Map<String, String> translations = {
    'app_title': 'EnCorinVest',
    'by': 'By: Kanagawa Yamada',
    'root_access': 'Root Access:',
    'module_installed': 'Module Installed:',
    'module_version': 'Module Version:',
    'current_mode': 'Current Mode:',
    'select_language': 'Select Language:',
    'power_save_desc': 'Prioritizing Battery Over Performance',
    'balanced_desc': 'Balance Battery and Performance',
    'performance_desc': 'Prioritizing Performance Over Battery',
    'clear_desc': 'Clear RAM By Killing All Apps',
    'cooldown_desc': 'Cool Down Your Device\n(Let It Rest for 2 Minutes)',
    'gaming_desc': 'Set to Performance and Kill All Apps',
    'power_save': 'Power Save',
    'balanced': 'Balanced',
    'performance': 'Performance',
    'clear': 'Clear',
    'cooldown': 'Cool Down',
    'gaming_pro': 'Gaming Pro',
    'about_title':
        'Thank you for the great people who helped improve EnCorinVest:',
    'about_quote':
        '"Great Collaboration Lead to Great Innovation"\n~ Kanagawa Yamada (Main Dev)',
    'about_note':
        'EnCorinVest Is Always Free, Open Source, and Open For Improvement',
    'credits_1': 'Rem01 Gaming',
    'credits_2': 'VelocityFox22',
    'credits_3': 'MiAzami',
    'credits_4': 'Kazuyoo',
    'credits_5': 'RiProG',
    'credits_6': 'Lieudahbelajar',
    'credits_7': 'KanaDev_IS',
    'credits_8': 'And All Testers That I Can\'t Mentioned One by One'
  };
}

class LangID {
  static const Map<String, String> translations = {
    'app_title': 'EnCorinVest',
    'by': 'Oleh: Kanagawa Yamada',
    'root_access': 'Akses Root:',
    'module_installed': 'Modul Terpasang:',
    'module_version': 'Versi Modul:',
    'current_mode': 'Mode Saat Ini:',
    'select_language': 'Pilih Bahasa:',
    'power_save_desc': 'Memprioritaskan Baterai Di Atas Performa',
    'balanced_desc': 'Seimbangkan Baterai dan Performa',
    'performance_desc': 'Memprioritaskan Performa Di Atas Baterai',
    'clear_desc': 'Bersihkan RAM Dengan Membunuh Semua Aplikasi',
    'cooldown_desc':
        'Dinginkan Perangkat Anda\n(Biarkan Beristirahat Selama 2 Menit)',
    'gaming_desc': 'Atur ke Performa dan Bunuh Semua Aplikasi',
    'power_save': 'Hemat Daya',
    'balanced': 'Seimbang',
    'performance': 'Performa',
    'clear': 'Bersihkan',
    'cooldown': 'Dinginkan',
    'gaming_pro': 'Pro Gaming',
    'about_title':
        'Terima kasih kepada orang-orang hebat yang membantu memperbaiki EnCorinVest:',
    'about_quote':
        '"Kolaborasi Hebat Mengarah pada Inovasi Hebat"\n~ Kanagawa Yamada (Pengembang Utama)',
    'about_note':
        'EnCorinVest Selalu Gratis, Sumber Terbuka, dan Terbuka untuk Peningkatan',
    'credits_1': 'Rem01 Gaming',
    'credits_2': 'VelocityFox22',
    'credits_3': 'MiAzami',
    'credits_4': 'Kazuyoo',
    'credits_5': 'RiProG',
    'credits_6': 'Lieudahbelajar',
    'credits_7': 'KanaDev_IS',
    'credits_8': 'Dan Semua Penguji yang Tidak Bisa Disebutkan Satu per Satu'
  };
}

class LangJP {
  static const Map<String, String> translations = {
    'app_title': 'エンコリンベスト',
    'by': '作成者: 神奈川山田',
    'root_access': 'ルートアクセス:',
    'module_installed': 'モジュール:',
    'module_version': 'モジュールバージョン:',
    'current_mode': '現在のモード:',
    'select_language': '言語を選択:',
    'power_save_desc': 'バッテリーを優先（パフォーマンス最小）',
    'balanced_desc': 'バッテリーとパフォーマンスのバランス',
    'performance_desc': 'パフォーマンスを優先（バッテリー最小）',
    'clear_desc': 'すべてのアプリを終了してRAMをクリア',
    'cooldown_desc': 'デバイスを冷却\n(2分間休ませる)',
    'gaming_desc': 'パフォーマンスモードですべてのアプリを終了',
    'power_save': '省電力',
    'balanced': 'バランス',
    'performance': 'パフォーマンス',
    'clear': 'クリア',
    'cooldown': '冷却',
    'gaming_pro': 'ゲーミングプロ',
    'about_title': 'EnCorinVestの改善に協力してくれた素晴らしい人々に感謝します:',
    'about_quote': '"偉大なコラボレーションは偉大なイノベーションにつながる"\n~ 神奈川山田 (メイン開発者)',
    'about_note': 'EnCorinVestは常に無料、オープンソース、そして改善に開かれています',
    'credits_1': 'Rem01 Gaming',
    'credits_2': 'VelocityFox22',
    'credits_3': 'MiAzami',
    'credits_4': 'カズヨオ',
    'credits_5': 'RiProG',
    'credits_6': 'リエドラブラジャル',
    'credits_7': 'KanaDev_IS',
    'credits_8': '名前を挙げられなかったすべてのテスター'
  };
}

class LangJV {
  static const Map<String, String> translations = {
    'app_title': 'EnCorinVest',
    'by': 'Dening: Kanagawa Yamada',
    'root_access': 'Akses Root:',
    'module_installed': 'Modul Dipasang:',
    'module_version': 'Versi Modul:',
    'current_mode': 'Mode Saiki:',
    'select_language': 'Pilih Basa:',
    'power_save_desc': 'Ngutamakake Baterai Tinimbang Performa',
    'balanced_desc': 'Seimbangake Baterai lan Performa',
    'performance_desc': 'Ngutamakake Performa Tinimbang Baterai',
    'clear_desc': 'Resiki RAM Kanthi Mateni Kabeh Aplikasi',
    'cooldown_desc': 'Ngandhapake Suhu Piranti\n(Lerenke 2 Menit)',
    'gaming_desc': 'Setel nang Performa lan Mateni Kabeh Aplikasi',
    'power_save': 'Ngirit Daya',
    'balanced': 'Seimbang',
    'performance': 'Performa',
    'clear': 'Resiki',
    'cooldown': 'Adhem',
    'gaming_pro': 'Pro Gaming',
    'about_title':
        'Matur nuwun marang wong-wong apik sing wis mbantu ngapiki EnCorinVest:',
    'about_quote':
        '"Kolaborasi Apik Nggowo Inovasi Apik"\n~ Kanagawa Yamada (Pengembang Utama)',
    'about_note':
        'EnCorinVest Mesti Gratis, Open Source, lan Mesti Terbuka Kanggo Pengembangan',
    'credits_1': 'Rem01 Gaming',
    'credits_2': 'VelocityFox22',
    'credits_3': 'MiAzami',
    'credits_4': 'Kazuyoo',
    'credits_5': 'RiProG',
    'credits_6': 'Lieudahbelajar',
    'credits_7': 'KLD - Kanagawa Lab Dev',
    'credits_8': 'Lan Kabeh Tester sing Ora Bisa Disebutke Siji-siji'
  };
}

class AppLocalizations {
  final String langCode;
  late Map<String, String> _localizedStrings;
  AppLocalizations(this.langCode) {
    switch (langCode) {
      case 'EN':
        _localizedStrings = LangEN.translations;
        break;
      case 'ID':
        _localizedStrings = LangID.translations;
        break;
      case 'JP':
        _localizedStrings = LangJP.translations;
        break;
      case 'JV':
        _localizedStrings = LangJV.translations;
        break;
      default:
        _localizedStrings = LangEN.translations;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class LanguagePreference {
  static final String _languageFilePath =
      '/data/adb/modules/EnCorinVest/language.txt';
  static Future<String> getSavedLanguage() async {
    try {
      var result = await run('su', ['-c', 'cat $_languageFilePath']);
      String savedLanguage = result.stdout.toString().trim();
      return savedLanguage.isNotEmpty ? savedLanguage : 'EN';
    } catch (e) {
      return 'EN';
    }
  }

  static Future<void> saveLanguage(String languageCode) async {
    try {
      await run('su', ['-c', 'echo "$languageCode" > $_languageFilePath']);
    } catch (e) {}
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Orbitron',
        scaffoldBackgroundColor: Color(0xFF0A0F2C),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0A0F2C),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF00F0FF)),
          titleTextStyle: TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 20,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0), fontSize: 15),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 15),
          titleLarge: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
            fontFamily: 'Orbitron',
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            color: Color(0xFFE0E0E0),
            fontFamily: 'Orbitron',
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle:
              TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Orbitron'),
          inputDecorationTheme: InputDecorationTheme(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00F0FF), width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00F0FF), width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

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
      setState(() {
        _deviceModel = 'Unknown';
        _cpuInfo = 'Unknown';
        _osVersion = 'Unknown';
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              localization.translate('about_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            ...credits.map((creditKey) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
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
            Text(
              localization.translate('about_quote'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF00F0FF),
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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Color(0xFF00F0FF),
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
  String _selectedLanguage = 'EN';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _checkRootAccess();
    _loadCurrentMode();
    _checkModuleInstalled();
    _getModuleVersion();
  }

  Future<void> _loadSavedLanguage() async {
    String savedLanguage = await LanguagePreference.getSavedLanguage();
    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  Future<void> _loadCurrentMode() async {
    try {
      var result = await run('su', ['-c', 'cat $_modeFile']);
      if (result.stdout.toString().trim().isNotEmpty) {
        setState(() {
          _currentMode = result.stdout.toString().trim().toUpperCase();
        });
      }
    } catch (e) {}
  }

  Future<void> _saveCurrentMode(String mode) async {
    try {
      await run('su', ['-c', 'echo "$mode" > $_modeFile']);
    } catch (e) {}
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
    } catch (e) {}
  }

  Future<void> executeScript(String scriptName, String buttonText) async {
    if (_executingScript.isNotEmpty) return;
    setState(() {
      _executingScript = scriptName;
      if (buttonText != 'Clear') {
        _currentMode = buttonText.toUpperCase();
      }
    });
    try {
      if (buttonText != 'Clear') {
        await _saveCurrentMode(_currentMode);
      }
      var result = await run(
          'su', ['-c', '/data/adb/modules/EnCorinVest/Scripts/$scriptName']);
    } catch (e) {
    } finally {
      setState(() {
        _executingScript = '';
      });
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    LanguagePreference.saveLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations(_selectedLanguage);
    const Color neonPink = Color(0xFFFFB6C1);
    const Color neonGreen = Color(0xFF98FB98);
    const Color neonYellow = Color(0xFFFAFAD2);
    const Color neonOrange = Color(0xFFFFDAB9);
    const Color neonPurple = Color(0xFFE6E6FA);
    const Color neonCyan = Color(0xFFAFECFF);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                        localization.translate('app_title'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        localization.translate('by'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AboutPage(selectedLanguage: _selectedLanguage),
                        ),
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
                        localization.translate('root_access'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        localization.translate('module_installed'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        localization.translate('module_version'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        localization.translate('current_mode'),
                        style: Theme.of(context).textTheme.bodyMedium,
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
                          fontSize: 15,
                          fontFamily: 'Orbitron',
                          color: _hasRootAccess
                              ? Color(0xFF00F0FF)
                              : Color(0xFFFF007F),
                        ),
                      ),
                      Text(
                        _moduleInstalled ? 'Yes' : 'No',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Orbitron',
                          color: _moduleInstalled
                              ? Color(0xFF00F0FF)
                              : Color(0xFFFF007F),
                        ),
                      ),
                      Text(
                        _moduleVersion,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _currentMode,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildControlRow(
                localization.translate('power_save_desc'),
                'powersafe.sh',
                localization.translate('power_save'),
                neonGreen,
              ),
              SizedBox(height: 10),
              _buildControlRow(
                localization.translate('balanced_desc'),
                'balanced.sh',
                localization.translate('balanced'),
                neonCyan,
              ),
              SizedBox(height: 10),
              _buildControlRow(
                localization.translate('performance_desc'),
                'performance.sh',
                localization.translate('performance'),
                neonOrange,
              ),
              SizedBox(height: 10),
              _buildControlRow(
                localization.translate('clear_desc'),
                'kill.sh',
                localization.translate('clear'),
                neonPink,
              ),
              SizedBox(height: 10),
              _buildControlRow(
                localization.translate('cooldown_desc'),
                'cool.sh',
                localization.translate('cooldown'),
                neonPurple,
              ),
              SizedBox(height: 10),
              _buildControlRow(
                localization.translate('gaming_desc'),
                'game.sh',
                localization.translate('gaming_pro'),
                neonYellow,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localization.translate('select_language'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    items: <String>['EN', 'ID', 'JP', 'JV'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _changeLanguage(newValue);
                      }
                    },
                    dropdownColor: Color(0xFF0A0F2C),
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontFamily: 'Orbitron',
                    ),
                    underline: Container(
                      height: 2,
                      color: Color(0xFF00F0FF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlRow(String description, String scriptName,
      String buttonText, Color buttonColor) {
    bool isExecuting = _executingScript == scriptName;
    Color pressedColor =
        HSLColor.fromColor(buttonColor).withLightness(0.6).toColor();
    Color disabledColor = buttonColor.withOpacity(0.5);
    Color textColor =
        buttonColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    Color textDisabledColor = textColor.withOpacity(0.7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
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
                if (states.contains(MaterialState.disabled)) {
                  return disabledColor;
                }
                if (states.contains(MaterialState.pressed)) {
                  return pressedColor;
                }
                return buttonColor;
              }),
              foregroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.disabled)) {
                  return textDisabledColor;
                }
                return textColor;
              }),
              padding:
                  MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 12)),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: textColor.withOpacity(0.5), width: 1),
                ),
              ),
              overlayColor:
                  MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
              elevation: MaterialStateProperty.resolveWith<double>((states) {
                if (states.contains(MaterialState.pressed)) return 2.0;
                return 4.0;
              }),
              shadowColor:
                  MaterialStateProperty.all(buttonColor.withOpacity(0.5)),
            ),
            child: Text(
              isExecuting ? '...' : buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
