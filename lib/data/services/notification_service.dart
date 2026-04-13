import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ─── Notification ID Registry ─────────────────────────────────────────────────
// 1001 : sleep reminder
// 1002 : feed reminder
// 2001–2024 : monthly milestone (month 1–24)
// 9001 : debug test notification

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Android Channels ────────────────────────────────────────────────────────

  static const _channelReminder = AndroidNotificationChannel(
    'sara_reminders',
    'Baby Reminders',
    description: 'Gentle reminders to log baby activities',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  static const _channelMilestone = AndroidNotificationChannel(
    'sara_milestones',
    'Milestone Notifications',
    description: 'Monthly milestone updates for your baby',
    importance: Importance.high,
    playSound: true,
  );

  // ─── Notification Detail Presets (static — no allocation per call) ───────────

  static const NotificationDetails _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'sara_reminders',
      'Baby Reminders',
      channelDescription: 'Gentle reminders to log baby activities',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const NotificationDetails _milestoneDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'sara_milestones',
      'Milestone Notifications',
      channelDescription: 'Monthly milestone updates for your baby',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ─── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Set tz.local to device timezone — without this all times default to UTC.
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS: don't request permission here — we do it explicitly via
    // requestPermission(). But DO enable foreground presentation so that
    // show() and zonedSchedule() display banners even while the app is open.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channelReminder);
    await androidImpl?.createNotificationChannel(_channelMilestone);

    _initialized = true;
    _log('Initialized. Timezone: ${tzInfo.identifier}');
  }

  // ─── Permission ──────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      return (await Permission.notification.request()).isGranted;
    }
    return true;
  }

  Future<bool> get hasPermission async {
    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return (await impl?.checkPermissions())?.isEnabled ?? false;
    }
    if (Platform.isAndroid) {
      return (await Permission.notification.status).isGranted;
    }
    return true;
  }

  // ─── Quiet Hours ─────────────────────────────────────────────────────────────

  /// Returns true if the DELIVERY time falls in the quiet window (22:00–07:00).
  /// Checking delivery time (not current time) prevents a notification
  /// scheduled at 21:55 from waking the parent at 23:25.
  bool _isQuietDelivery(tz.TZDateTime scheduledTime) {
    final h = scheduledTime.hour;
    return h >= 22 || h < 7;
  }

  // ─── Sleep Reminder ──────────────────────────────────────────────────────────

  /// Schedules a "time to log sleep" reminder [afterMinutes] from now.
  Future<void> scheduleSleepReminder({
    required String babyName,
    required String title,
    required String body,
    int afterMinutes = 90,
  }) async {
    if (!(await hasPermission)) return;

    final delay = Duration(minutes: afterMinutes);

    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

    if (_isQuietDelivery(scheduledTime)) {
      _log('Sleep reminder suppressed — delivery in quiet hours');
      return;
    }

    try {
      await _plugin.zonedSchedule(
        1001,
        title,
        body,
        scheduledTime,
        _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'sleep',
      );
      _log('Sleep reminder → $scheduledTime');
    } catch (e) {
      _log('scheduleSleepReminder failed: $e');
    }
  }

  Future<void> cancelSleepReminder() => _plugin.cancel(1001);

  // ─── Feed Reminder ───────────────────────────────────────────────────────────

  /// Schedules a "time to log feed" reminder [afterMinutes] from now.
  Future<void> scheduleFeedReminder({
    required String title,
    required String body,
    int afterMinutes = 150,
  }) async {
    if (!(await hasPermission)) return;

    final delay = Duration(minutes: afterMinutes);

    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

    if (_isQuietDelivery(scheduledTime)) {
      _log('Feed reminder suppressed — delivery in quiet hours');
      return;
    }

    try {
      await _plugin.zonedSchedule(
        1002,
        title,
        body,
        scheduledTime,
        _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'feed',
      );
      _log('Feed reminder → $scheduledTime');
    } catch (e) {
      _log('scheduleFeedReminder failed: $e');
    }
  }

  Future<void> cancelFeedReminder() => _plugin.cancel(1002);

  // ─── Milestone Notifications ─────────────────────────────────────────────────

  /// Schedule monthly milestone notifications for months 1–24.
  /// Milestones already in the past are skipped automatically.
  /// Each notification fires exactly ONCE (no repeat).
  Future<void> scheduleMilestoneNotifications({
    required DateTime birthDate,
    required String Function(int month) titleBuilder,
    required String Function(int month) bodyBuilder,
  }) async {
    if (!(await hasPermission)) return;

    // Cancel any stale milestone notifications before rebuilding the schedule.
    for (int i = 1; i <= 24; i++) {
      await _plugin.cancel(2000 + i);
    }

    final now = DateTime.now();
    int scheduled = 0;

    for (int month = 1; month <= 24; month++) {
      // Dart normalises overflow months (e.g. Jan 31 + 1 month = Mar 2/3).
      final milestoneDate = DateTime(
        birthDate.year,
        birthDate.month + month,
        birthDate.day,
        9, // 09:00 local morning
        0,
      );

      if (milestoneDate.isBefore(now)) continue;

      try {
        await _plugin.zonedSchedule(
          2000 + month,
          titleBuilder(month),
          bodyBuilder(month),
          tz.TZDateTime.from(milestoneDate, tz.local),
          _milestoneDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'milestone_$month',
          // No matchDateTimeComponents → fires ONCE, not yearly.
        );
        scheduled++;
      } catch (e) {
        _log('Milestone month $month failed: $e');
      }
    }

    _log('Milestone notifications scheduled: $scheduled future months');
  }

  Future<void> cancelAllMilestoneNotifications() async {
    for (int i = 1; i <= 24; i++) {
      await _plugin.cancel(2000 + i);
    }
  }


  /// Cancels every pending notification.
  Future<void> cancelAll() => _plugin.cancelAll();

  // ─── Settings ────────────────────────────────────────────────────────────────

  static const _keySleepReminders = 'notif_sleep_reminders';
  static const _keyFeedReminders = 'notif_feed_reminders';
  static const _keyMilestoneNotifs = 'notif_milestones';

  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      sleepRemindersEnabled: prefs.getBool(_keySleepReminders) ?? true,
      feedRemindersEnabled: prefs.getBool(_keyFeedReminders) ?? true,
      milestoneNotificationsEnabled:
          prefs.getBool(_keyMilestoneNotifs) ?? true,
    );
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySleepReminders, settings.sleepRemindersEnabled);
    await prefs.setBool(_keyFeedReminders, settings.feedRemindersEnabled);
    await prefs.setBool(
        _keyMilestoneNotifs, settings.milestoneNotificationsEnabled);
  }

  // ─── Internal ────────────────────────────────────────────────────────────────

  void _log(String msg) {
    if (kDebugMode) debugPrint('[NotificationService] $msg');
  }
}

// ─── Settings Model ───────────────────────────────────────────────────────────

class NotificationSettings {
  final bool sleepRemindersEnabled;
  final bool feedRemindersEnabled;
  final bool milestoneNotificationsEnabled;

  const NotificationSettings({
    this.sleepRemindersEnabled = true,
    this.feedRemindersEnabled = true,
    this.milestoneNotificationsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? sleepRemindersEnabled,
    bool? feedRemindersEnabled,
    bool? milestoneNotificationsEnabled,
  }) =>
      NotificationSettings(
        sleepRemindersEnabled:
            sleepRemindersEnabled ?? this.sleepRemindersEnabled,
        feedRemindersEnabled: feedRemindersEnabled ?? this.feedRemindersEnabled,
        milestoneNotificationsEnabled:
            milestoneNotificationsEnabled ?? this.milestoneNotificationsEnabled,
      );
}
