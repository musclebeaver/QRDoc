import 'package:flutter/services.dart';
import '../models/medication_log.dart';
import '../main.dart';

class LocalNotificationService {
  static const _channel = MethodChannel('com.devbeaver.qrdoc/emergency');

  // Helper to parse "HH:mm" time string into hour and minute map
  static Map<String, int> _parseTime(String timeStr, int defaultHour, int defaultMinute) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? defaultHour;
      final m = int.tryParse(parts[1]) ?? defaultMinute;
      return {'hour': h, 'minute': m};
    }
    return {'hour': defaultHour, 'minute': defaultMinute};
  }

  // Schedule daily repeating alarms for a new medication log based on custom user times
  static Future<void> scheduleAlarmsForMedication(MedicationLog log) async {
    if (!log.isActive) return;

    final reminderTimes = localStorage.getReminderTimes();
    final morning = _parseTime(reminderTimes['morning'] ?? '08:00', 8, 0);
    final lunch = _parseTime(reminderTimes['lunch'] ?? '13:00', 13, 0);
    final evening = _parseTime(reminderTimes['evening'] ?? '19:00', 19, 0);

    final List<Map<String, int>> times;
    if (log.frequencyPerDay >= 3) {
      times = [morning, lunch, evening];
    } else if (log.frequencyPerDay == 2) {
      times = [morning, evening];
    } else {
      times = [morning];
    }

    for (int i = 0; i < log.frequencyPerDay; i++) {
      if (i >= times.length) break;
      final hour = times[i]['hour']!;
      final minute = times[i]['minute']!;
      final alarmId = _generateAlarmId(log.id, i);

      try {
        await _channel.invokeMethod('scheduleMedicationAlarm', {
          'id': alarmId,
          'title': '🚨 VitalPass 복약 알림',
          'message': '약 복용 시간입니다: ${log.medicineName} (${log.dosage})',
          'hour': hour,
          'minute': minute,
        });
      } on PlatformException catch (e) {
        print("Failed to schedule native alarm: ${e.message}");
      }
    }
  }

  // Reschedule all active alarms when reminder times are modified in settings
  static Future<void> rescheduleAllAlarms(List<MedicationLog> activeLogs) async {
    for (var log in activeLogs) {
      await cancelAlarmsForMedication(log);
      await scheduleAlarmsForMedication(log);
    }
  }

  // Cancel scheduled daily alarms for a deleted or deactivated medication
  static Future<void> cancelAlarmsForMedication(MedicationLog log) async {
    for (int i = 0; i < log.frequencyPerDay; i++) {
      final alarmId = _generateAlarmId(log.id, i);
      try {
        await _channel.invokeMethod('cancelMedicationAlarm', {
          'id': alarmId,
        });
      } on PlatformException catch (e) {
        print("Failed to cancel native alarm: ${e.message}");
      }
    }
  }

  // Hash the UUID string into a stable 31-bit positive integer for native notification triggers
  static int _generateAlarmId(String medicationLogId, int index) {
    final hash = medicationLogId.hashCode.abs() & 0x3FFFFFFF;
    return hash + index;
  }
}
