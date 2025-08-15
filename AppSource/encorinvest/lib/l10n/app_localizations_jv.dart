// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Javanese (`jv`).
class AppLocalizationsJv extends AppLocalizations {
  AppLocalizationsJv([String locale = 'jv']) : super(locale);

  @override
  String get app_title => 'EnCorinVest';

  @override
  String get by => 'Dening: Kanagawa Yamada';

  @override
  String get root_access => 'Akses Root:';

  @override
  String get module_installed => 'Modul Dipasang:';

  @override
  String get module_version => 'Versi Modul:';

  @override
  String get current_mode => 'Mode Saiki:';

  @override
  String get select_language => 'Pilih Basa:';

  @override
  String get power_save_desc => 'Ngutamakake Baterai Tinimbang Performa';

  @override
  String get balanced_desc => 'Seimbangake Baterai lan Performa';

  @override
  String get performance_desc => 'Ngutamakake Performa Tinimbang Baterai';

  @override
  String get clear_desc => 'Resiki RAM Kanthi Mateni Kabeh Aplikasi';

  @override
  String get cooldown_desc => 'Ngandhapake Suhu Piranti\n(Lerenke 2 Menit)';

  @override
  String get gaming_desc => 'Setel nang Performa lan Mateni Kabeh Aplikasi';

  @override
  String get power_save => 'Ngirit Daya';

  @override
  String get balanced => 'Seimbang';

  @override
  String get performance => 'Performa';

  @override
  String get clear => 'Resiki';

  @override
  String get cooldown => 'Adhem';

  @override
  String get gaming_pro => 'Pro Gaming';

  @override
  String get about_title =>
      'Matur nuwun marang wong-wong apik sing wis mbantu ngapiki EnCorinVest:';

  @override
  String get about_quote =>
      '\"Kolaborasi Apik Nggowo Inovasi Apik\"\n~ Kanagawa Yamada (Pengembang Utama)';

  @override
  String get about_note =>
      'EnCorinVest Mesti Gratis, Open Source, lan Mesti Terbuka Kanggo Pengembangan';

  @override
  String get credits_1 => 'Rem01 Gaming';

  @override
  String get credits_2 => 'VelocityFox22';

  @override
  String get credits_3 => 'MiAzami';

  @override
  String get credits_4 => 'Kazuyoo';

  @override
  String get credits_5 => 'RiProG';

  @override
  String get credits_6 => 'Lieudahbelajar';

  @override
  String get credits_7 => 'KLD - Kanagawa Lab Dev';

  @override
  String get credits_8 => 'Lan Kabeh Tester sing Ora Bisa Disebutke Siji-siji';

  @override
  String get yes => 'Nggih';

  @override
  String get no => 'Mboten';

  @override
  String get device => 'Piranti:';

  @override
  String get cpu => 'CPU:';

  @override
  String get os => 'OS:';

  @override
  String get utilities => 'Utilitas';

  @override
  String get utilities_title => 'Utilitas';

  @override
  String get encore_switch_title => 'Saklar Encore';

  @override
  String get encore_switch_description => 'Nguwasani Carane Encore Mlakune';

  @override
  String get device_mitigation_title => 'Mitigasi Piranti';

  @override
  String get device_mitigation_description => 'Uripke yen layar mandheg';

  @override
  String get lite_mode_title => 'Mode LITE';

  @override
  String get lite_mode_description => 'Nganggo mode Lite (Dijaluk dening Fans)';

  @override
  String get hamada_ai => 'HAMADA AI';

  @override
  String get hamada_ai_description =>
      'Otomatis Ganti menyang Performa pas Mlebu Game';

  @override
  String get downscale_resolution => 'Mudhunake Resolusi';

  @override
  String selected_resolution(String resolution) {
    return 'Dipilih: $resolution';
  }

  @override
  String get reset_resolution => 'Bali menyang Asli';

  @override
  String get hamada_ai_toggle_title => 'Aktifke HAMADA AI';

  @override
  String get hamada_ai_start_on_boot => 'Mulai pas Boot';

  @override
  String get edit_game_txt_title => 'Edit game.txt';

  @override
  String get save_button => 'Simpen';

  @override
  String get executing_command => 'Nglakokake...';

  @override
  String get command_executed => 'Peréntah dilakokake.';

  @override
  String get command_failed => 'Peréntah gagal.';

  @override
  String get saving_file => 'Nyimpen...';

  @override
  String get file_saved => 'File disimpen.';

  @override
  String get file_save_failed => 'Gagal nyimpen file.';

  @override
  String get reading_file => 'Moco file...';

  @override
  String get file_read_failed => 'Gagal moco file.';

  @override
  String get writing_service_file => 'Nganyari skrip boot...';

  @override
  String get service_file_updated => 'Skrip boot dianyari.';

  @override
  String get service_file_update_failed => 'Gagal nganyari skrip boot.';

  @override
  String get error_no_root => 'Butuh akses root.';

  @override
  String get error_file_not_found => 'File ora ditemokake.';

  @override
  String get game_txt_hint => 'Lebokna jeneng paket game, siji per baris...';

  @override
  String get resolution_unavailable_message =>
      'Kontrol resolusi ora kasedhiya ing piranti iki.';

  @override
  String get applying_changes => 'Nerapake owah-owahan...';

  @override
  String get dnd_title => 'Saklar DND';

  @override
  String get dnd_description => 'Otomatis Nguripake / Mateni DND';

  @override
  String get dnd_toggle_title => 'Aktifke Saklar Otomatis DND';

  @override
  String get bypass_charging_title => 'Bypass Charging';

  @override
  String get bypass_charging_description =>
      'Aktifke Bypass Charging Nalika Mode Performa & Gaming Pro ing Piranti sing Didukung';

  @override
  String get bypass_charging_toggle => 'Aktifke Bypass Charging';

  @override
  String get bypass_charging_unsupported =>
      'Bypass charging ora didukung ing piranti sampeyan';

  @override
  String get bypass_charging_supported =>
      'Bypass charging didukung ing piranti sampeyan';
}
