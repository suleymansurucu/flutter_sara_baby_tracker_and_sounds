import 'package:easy_localization/easy_localization.dart';
import 'package:home_widget/home_widget.dart';
import 'package:open_baby_sara/core/widget_bridge/widget_data_contract.dart';

/// Flutter → native widget köprüsü.
///
/// Bu servis native katmana (iOS WidgetKit / Android AppWidget) iki tür veri yazar:
///   1. Timer state   — is_running, start_timestamp
///   2. Localized strings — easy_localization üzerinden çevrilmiş metinler
///
/// Nasıl kullanılır:
///   - Timer başladığında / durduğunda ilgili `update*Widget` metodu çağrılır.
///   - App foreground'a döndüğünde ve locale/tema değiştiğinde
///     `refreshAllWidgets` çağrılır.
///
/// Native taraf widget'ı render ederken elapsed time'ı kendisi hesaplar:
///   elapsed = DateTime.now() - startTimestamp
/// Bu sayede her saniye Flutter'ın widget'ı güncellemesine gerek kalmaz.
class WidgetBridgeService {
  WidgetBridgeService._();

  // ─── Initialization ───────────────────────────────────────────────────────

  /// main() içinde, EasyLocalization.ensureInitialized() sonrasında çağrılır.
  static Future<void> initialize() async {
    // iOS: App Group olmadan widget ve app aynı UserDefaults'ı paylaşamaz.
    // Android: bu çağrı no-op'tur, zarar vermez.
    HomeWidget.setAppGroupId(WidgetDataContract.appGroupId);
  }

  // ─── Sleep widget ─────────────────────────────────────────────────────────

  static Future<void> updateSleepWidget({
    required bool isRunning,
    DateTime? startTime,
    int? lastDurationSeconds,
    DateTime? lastEndTime,
    required String babyName,
    required bool isGirlTheme,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData(WidgetDataContract.sleepRunning, isRunning),
      HomeWidget.saveWidgetData(
        WidgetDataContract.sleepStartTs,
        startTime?.millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.sleepLastDurSec,
        lastDurationSeconds,
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.sleepLastEndTs,
        lastEndTime?.millisecondsSinceEpoch,
      ),
      ..._metaWrites(babyName: babyName, isGirlTheme: isGirlTheme),
      ..._localizedStringWrites(),
    ]);

    await HomeWidget.updateWidget(
      iOSName: WidgetDataContract.sleepWidgetIos,
      androidName: WidgetDataContract.sleepWidgetAndroid,
    );
  }

  // ─── Breastfeed widget ────────────────────────────────────────────────────

  static Future<void> updateBreastfeedWidget({
    required bool leftRunning,
    DateTime? leftStartTime,
    required bool rightRunning,
    DateTime? rightStartTime,
    DateTime? lastEndTime,
    required String babyName,
    required bool isGirlTheme,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData(WidgetDataContract.bfLeftRunning, leftRunning),
      HomeWidget.saveWidgetData(
        WidgetDataContract.bfLeftStartTs,
        leftStartTime?.millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData(WidgetDataContract.bfRightRunning, rightRunning),
      HomeWidget.saveWidgetData(
        WidgetDataContract.bfRightStartTs,
        rightStartTime?.millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.bfLastEndTs,
        lastEndTime?.millisecondsSinceEpoch,
      ),
      ..._metaWrites(babyName: babyName, isGirlTheme: isGirlTheme),
      ..._localizedStringWrites(),
    ]);

    await HomeWidget.updateWidget(
      iOSName: WidgetDataContract.feedWidgetIos,
      androidName: WidgetDataContract.feedWidgetAndroid,
    );
  }

  // ─── Pump widget ──────────────────────────────────────────────────────────

  static Future<void> updatePumpWidget({
    required bool isRunning,
    DateTime? startTime,
    DateTime? lastEndTime,
    required String pumpMode,
    required String babyName,
    required bool isGirlTheme,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData(WidgetDataContract.pumpRunning, isRunning),
      HomeWidget.saveWidgetData(
        WidgetDataContract.pumpStartTs,
        startTime?.millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.pumpLastEndTs,
        lastEndTime?.millisecondsSinceEpoch,
      ),
      HomeWidget.saveWidgetData(WidgetDataContract.pumpMode, pumpMode),
      ..._metaWrites(babyName: babyName, isGirlTheme: isGirlTheme),
      ..._localizedStringWrites(),
    ]);

    await HomeWidget.updateWidget(
      iOSName: WidgetDataContract.pumpWidgetIos,
      androidName: WidgetDataContract.pumpWidgetAndroid,
    );
  }

  // ─── Toplu yenileme ───────────────────────────────────────────────────────

  /// App foreground'a döndüğünde, locale veya tema değiştiğinde çağrılır.
  /// Tüm localized string'leri ve meta verileri günceller, üç widget'ı da yeniler.
  static Future<void> refreshAllWidgets({
    required String babyName,
    required bool isGirlTheme,
  }) async {
    await Future.wait([
      ..._metaWrites(babyName: babyName, isGirlTheme: isGirlTheme),
      ..._localizedStringWrites(),
    ]);

    await Future.wait([
      HomeWidget.updateWidget(
        iOSName: WidgetDataContract.sleepWidgetIos,
        androidName: WidgetDataContract.sleepWidgetAndroid,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetDataContract.feedWidgetIos,
        androidName: WidgetDataContract.feedWidgetAndroid,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetDataContract.pumpWidgetIos,
        androidName: WidgetDataContract.pumpWidgetAndroid,
      ),
    ]);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Tema ve bebek adı yazmaları — her güncelleme çağrısına dahil edilir.
  static List<Future<void>> _metaWrites({
    required String babyName,
    required bool isGirlTheme,
  }) {
    return [
      HomeWidget.saveWidgetData(WidgetDataContract.babyName, babyName),
      HomeWidget.saveWidgetData(
        WidgetDataContract.theme,
        isGirlTheme ? 'girl' : 'boy',
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.primaryColor,
        // AppColors sabitlerinden alınan hex değerler
        isGirlTheme ? '#E91E63' : '#2196F3',
      ),
    ];
  }

  /// easy_localization üzerinden çevrilmiş UI string'lerini shared storage'a yazar.
  /// Locale değiştiğinde refreshAllWidgets çağrısı bu string'leri de günceller.
  ///
  /// NOT: 'last_sleep' anahtarı henüz localization dosyalarında yok.
  /// Sleep widget implementasyonunda (Adım 2) tüm 11 dil dosyasına eklenecek.
  static List<Future<void>> _localizedStringWrites() {
    return [
      HomeWidget.saveWidgetData(WidgetDataContract.strSleep, 'sleep'.tr()),
      HomeWidget.saveWidgetData(WidgetDataContract.strPump, 'pump'.tr()),
      HomeWidget.saveWidgetData(WidgetDataContract.strFeed, 'breastFeed'.tr()),
      HomeWidget.saveWidgetData(
        WidgetDataContract.strLeftSide,
        'left_side'.tr(),
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.strRightSide,
        'right_side'.tr(),
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.strStart,
        'tap_to_start_only'.tr(),
      ),
      HomeWidget.saveWidgetData(WidgetDataContract.strStop, 'tap_to_pause'.tr()),
      HomeWidget.saveWidgetData(
        WidgetDataContract.strLastPump,
        'last_pump'.tr(),
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.strLastFeed,
        'last_feed'.tr(),
      ),
      HomeWidget.saveWidgetData(
        WidgetDataContract.strLastSleep,
        'last_sleep'.tr(),
      ),
    ];
  }
}
