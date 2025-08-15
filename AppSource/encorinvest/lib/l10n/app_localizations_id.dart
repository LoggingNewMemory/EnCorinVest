// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get app_title => 'EnCorinVest';

  @override
  String get by => 'Oleh: Kanagawa Yamada';

  @override
  String get root_access => 'Akses Root:';

  @override
  String get module_installed => 'Modul Terpasang:';

  @override
  String get module_version => 'Versi Modul:';

  @override
  String get current_mode => 'Mode Saat Ini:';

  @override
  String get select_language => 'Pilih Bahasa:';

  @override
  String get power_save_desc => 'Memprioritaskan Baterai Di Atas Performa';

  @override
  String get balanced_desc => 'Seimbangkan Baterai dan Performa';

  @override
  String get performance_desc => 'Memprioritaskan Performa Di Atas Baterai';

  @override
  String get clear_desc => 'Bersihkan RAM Dengan Membunuh Semua Aplikasi';

  @override
  String get cooldown_desc =>
      'Dinginkan Perangkat Anda\n(Biarkan Beristirahat Selama 2 Menit)';

  @override
  String get gaming_desc => 'Atur ke Performa dan Bunuh Semua Aplikasi';

  @override
  String get power_save => 'Hemat Daya';

  @override
  String get balanced => 'Seimbang';

  @override
  String get performance => 'Performa';

  @override
  String get clear => 'Bersihkan';

  @override
  String get cooldown => 'Dinginkan';

  @override
  String get gaming_pro => 'Pro Gaming';

  @override
  String get about_title =>
      'Terima kasih kepada orang-orang hebat yang membantu memperbaiki EnCorinVest:';

  @override
  String get about_quote =>
      '\"Kolaborasi Hebat Mengarah pada Inovasi Hebat\"\n~ Kanagawa Yamada (Pengembang Utama)';

  @override
  String get about_note =>
      'EnCorinVest Selalu Gratis, Sumber Terbuka, dan Terbuka untuk Peningkatan';

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
  String get credits_7 => 'KanaDev_IS';

  @override
  String get credits_8 =>
      'Dan Semua Penguji yang Tidak Bisa Disebutkan Satu per Satu';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String get device => 'Perangkat:';

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
  String get encore_switch_description => 'Mengontrol Cara Kerja Encore';

  @override
  String get device_mitigation_title => 'Mitigasi Perangkat';

  @override
  String get device_mitigation_description =>
      'Nyalakan jika Anda mengalami layar beku';

  @override
  String get lite_mode_title => 'Mode LITE';

  @override
  String get lite_mode_description =>
      'Menggunakan mode Lite (Diminta oleh Penggemar)';

  @override
  String get hamada_ai => 'HAMADA AI';

  @override
  String get hamada_ai_description =>
      'Otomatis Beralih ke Performa Saat Memasuki Game';

  @override
  String get downscale_resolution => 'Turunkan Resolusi';

  @override
  String selected_resolution(String resolution) {
    return 'Terpilih: $resolution';
  }

  @override
  String get reset_resolution => 'Kembali ke Asli';

  @override
  String get hamada_ai_toggle_title => 'Aktifkan HAMADA AI';

  @override
  String get hamada_ai_start_on_boot => 'Mulai saat Boot';

  @override
  String get edit_game_txt_title => 'Edit game.txt';

  @override
  String get save_button => 'Simpan';

  @override
  String get executing_command => 'Menjalankan...';

  @override
  String get command_executed => 'Perintah dijalankan.';

  @override
  String get command_failed => 'Perintah gagal.';

  @override
  String get saving_file => 'Menyimpan...';

  @override
  String get file_saved => 'File disimpan.';

  @override
  String get file_save_failed => 'Gagal menyimpan file.';

  @override
  String get reading_file => 'Membaca file...';

  @override
  String get file_read_failed => 'Gagal membaca file.';

  @override
  String get writing_service_file => 'Memperbarui skrip boot...';

  @override
  String get service_file_updated => 'Skrip boot diperbarui.';

  @override
  String get service_file_update_failed => 'Gagal memperbarui skrip boot.';

  @override
  String get error_no_root => 'Membutuhkan akses root.';

  @override
  String get error_file_not_found => 'File tidak ditemukan.';

  @override
  String get game_txt_hint => 'Masukkan nama paket game, satu per baris...';

  @override
  String get resolution_unavailable_message =>
      'Kontrol resolusi tidak tersedia di perangkat ini.';

  @override
  String get applying_changes => 'Menerapkan perubahan...';

  @override
  String get dnd_title => 'Saklar DND';

  @override
  String get dnd_description => 'Otomatis Nyalakan / Matikan DND';

  @override
  String get dnd_toggle_title => 'Aktifkan Saklar Otomatis DND';

  @override
  String get bypass_charging_title => 'Bypass Charging';

  @override
  String get bypass_charging_description =>
      'Aktifkan Bypass Charging Saat Mode Performa & Gaming Pro di Perangkat yang Didukung';

  @override
  String get bypass_charging_toggle => 'Aktifkan Bypass Charging';

  @override
  String get bypass_charging_unsupported =>
      'Bypass charging tidak didukung di perangkat Anda';

  @override
  String get bypass_charging_supported =>
      'Bypass charging didukung di perangkat Anda';
}
