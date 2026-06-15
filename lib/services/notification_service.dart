import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// NotificationService — Local notification scheduling (singleton)
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailySummaryNotificationId = 1001;
  static const String _dailySummaryChannelId = 'daily_summary_channel';
  static const String _dailySummaryChannelName = 'Daily Summary';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize plugin, timezone, and request OS permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    await _initializeTimeZone();
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    _setLocalTimeZoneFromDeviceOffset();
  }

  /// Maps the device UTC offset to an IANA zone (Etc/GMT sign is inverted)
  void _setLocalTimeZoneFromDeviceOffset() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final locationName = hours >= 0
          ? 'Etc/GMT-$hours'
          : 'Etc/GMT+${hours.abs()}';
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('NotificationService: falling back to UTC timezone — $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Cancel any existing daily summary, then schedule for 8:00 PM local time
  Future<void> scheduleDailySummary(double totalSpent) async {
    if (!_isInitialized) {
      throw StateError(
        'NotificationService.initialize() must be called before scheduling.',
      );
    }

    await _plugin.cancel(_dailySummaryNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      0,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final formattedTotal = totalSpent.toStringAsFixed(2);

    const androidDetails = AndroidNotificationDetails(
      _dailySummaryChannelId,
      _dailySummaryChannelName,
      channelDescription: 'Evening spending summary notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      _dailySummaryNotificationId,
      'Daily Summary',
      "You've spent RM $formattedTotal today. Tap to review your budget!",
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel the scheduled daily summary notification
  Future<void> cancelDailySummary() async {
    await _plugin.cancel(_dailySummaryNotificationId);
  }
}
