import 'package:flutter/services.dart';
import '../models/medication_log.dart';

class LocalNotificationService {
  static const _channel = MethodChannel('com.devbeaver.qrdoc/emergency');

  // Schedule daily repeating alarms for a new medication log
  static Future<void> scheduleAlarmsForMedication(MedicationLog log) async {
    if (!log.isActive) return;

    final List<Map<String, int>> times;
    if (log.frequencyPerDay >= 3) {
      times = [
        {'hour': 8, 'minute': 0},
        {'hour': 13, 'minute': 0},
        {'hour': 19, 'minute': 0},
      ];
    } else if (log.frequencyPerDay == 2) {
      times = [
        {'hour': 8, 'minute': 0},
        {'hour': 19, 'minute': 0},
      ];
    } else {
      times = [
        {'hour': 8, 'minute': 0},
      ];
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
        // Graceful error logging
        print("Failed to schedule native alarm: ${e.message}");
      }
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
