/// Shared storage key sözleşmesi.
///
/// Flutter tarafı bu key'lere yazar, native widget (iOS Swift / Android Kotlin)
/// aynı key'lerden okur. Bir key'i değiştirmek her iki tarafı da etkiler.
class WidgetDataContract {
  WidgetDataContract._();

  // ─── Widget isimleri (HomeWidget.updateWidget parametreleri) ──────────────
  static const String sleepWidgetIos       = 'SleepWidget';
  static const String sleepWidgetAndroid   = 'SleepWidgetProvider';

  static const String feedWidgetIos        = 'BreastfeedWidget';
  static const String feedWidgetAndroid    = 'BreastfeedWidgetProvider';

  static const String pumpWidgetIos        = 'PumpWidget';
  static const String pumpWidgetAndroid    = 'PumpWidgetProvider';

  // iOS App Group — Xcode'da Runner ve widget extension'a eklenmesi gerekir.
  static const String appGroupId = 'group.com.suleymansurucu.sarababy';

  // ─── Meta ─────────────────────────────────────────────────────────────────
  /// 'girl' veya 'boy'
  static const String theme        = 'w_theme';
  /// '#E91E63' veya '#2196F3' (hex, iOS/Android her ikisi parse eder)
  static const String primaryColor = 'w_primary_color';
  /// Seçili bebeğin adı
  static const String babyName     = 'w_baby_name';

  // ─── Sleep ────────────────────────────────────────────────────────────────
  /// bool — timer şu an çalışıyor mu
  static const String sleepRunning       = 'sleep_running';
  /// int (ms epoch) — timer başladığında yazılır; widget elapsed'ı buradan hesaplar
  static const String sleepStartTs       = 'sleep_start_ts';
  /// int (saniye) — son tamamlanan uyku süresi
  static const String sleepLastDurSec    = 'sleep_last_dur_sec';
  /// int (ms epoch) — son uykunun bitiş zamanı
  static const String sleepLastEndTs     = 'sleep_last_end_ts';

  // ─── Breastfeed ───────────────────────────────────────────────────────────
  static const String bfLeftRunning  = 'bf_left_running';
  static const String bfLeftStartTs  = 'bf_left_start_ts';
  static const String bfRightRunning = 'bf_right_running';
  static const String bfRightStartTs = 'bf_right_start_ts';
  /// int (ms epoch) — sol veya sağ tarafın son bitiş zamanı
  static const String bfLastEndTs    = 'bf_last_end_ts';

  // ─── Pump ─────────────────────────────────────────────────────────────────
  static const String pumpRunning  = 'pump_running';
  static const String pumpStartTs  = 'pump_start_ts';
  static const String pumpLastEndTs = 'pump_last_end_ts';
  /// 'total' veya 'leftRight' — kullanıcının seçtiği pompa modu
  static const String pumpMode     = 'pump_mode';

  // ─── Localized strings (11 dil için Flutter tarafından çevrilmiş) ─────────
  static const String strSleep     = 'w_str_sleep';
  static const String strPump      = 'w_str_pump';
  static const String strFeed      = 'w_str_feed';
  static const String strLeftSide  = 'w_str_left_side';
  static const String strRightSide = 'w_str_right_side';
  static const String strStart     = 'w_str_start';
  static const String strStop      = 'w_str_stop';
  static const String strLastSleep = 'w_str_last_sleep';
  static const String strLastPump  = 'w_str_last_pump';
  static const String strLastFeed  = 'w_str_last_feed';
}
