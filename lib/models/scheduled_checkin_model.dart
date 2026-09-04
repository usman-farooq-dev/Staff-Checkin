import 'package:cloud_firestore/cloud_firestore.dart';
import 'check_task_model.dart';

class ScheduledCheckInModel {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final DateTime? createdAt;
  final String status;
  final Map<String, String> storeStatus;
  final Map<String, int> remindAt;
  final Map<String, int> snoozeCount;
  final List<CheckTaskModel> tasks;

  const ScheduledCheckInModel({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.createdAt,
    this.status = 'pending',
    this.storeStatus = const {},
    this.remindAt = const {},
    this.snoozeCount = const {},
    this.tasks = const [],
  });

  /// Factory constructor from Firestore DocumentSnapshot
  factory ScheduledCheckInModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ScheduledCheckInModel.fromMap(data, doc.id);
  }

  /// Factory constructor from Map
  factory ScheduledCheckInModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    // Parse scheduledAt in UTC
    DateTime scheduledDate;
    final scheduledAtRaw = data['scheduledAt'];
    if (scheduledAtRaw is int) {
      scheduledDate = DateTime.fromMillisecondsSinceEpoch(scheduledAtRaw, isUtc: true);
    } else if (scheduledAtRaw is Timestamp) {
      scheduledDate = scheduledAtRaw.toDate().toUtc();
    } else if (scheduledAtRaw is String) {
      scheduledDate = DateTime.tryParse(scheduledAtRaw)?.toUtc() ?? DateTime.now().toUtc();
    } else {
      scheduledDate = DateTime.now().toUtc();
    }
    scheduledDate = scheduledDate.toUtc();

    // Parse createdAt in UTC
    DateTime? createdDate;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(createdAtRaw, isUtc: true);
    } else if (createdAtRaw is Timestamp) {
      createdDate = createdAtRaw.toDate().toUtc();
    } else if (createdAtRaw is String) {
      createdDate = DateTime.tryParse(createdAtRaw)?.toUtc();
    }
    createdDate = createdDate?.toUtc();

    // Parse storeStatus map
    final Map<String, String> storeStatusMap = {};
    if (data['storeStatus'] is Map) {
      final rawMap = data['storeStatus'] as Map;
      rawMap.forEach((key, value) {
        storeStatusMap[key.toString()] = value.toString().toLowerCase();
      });
    }

    // Parse remindAt map (snooze timestamps in ms)
    final Map<String, int> remindAtMap = {};
    final rawRemindAt = data['remindAt'] ?? data['snoozeUntil'];
    if (rawRemindAt is Map) {
      rawRemindAt.forEach((key, value) {
        if (value is num) {
          remindAtMap[key.toString()] = value.toInt();
        }
      });
    }

    // Parse snoozeCount map (track how many times snoozed - max 1 allowed)
    final Map<String, int> snoozeCountMap = {};
    final rawSnoozeCount = data['snoozeCount'];
    if (rawSnoozeCount is Map) {
      rawSnoozeCount.forEach((key, value) {
        if (value is num) {
          snoozeCountMap[key.toString()] = value.toInt();
        }
      });
    } else if (remindAtMap.isNotEmpty) {
      remindAtMap.forEach((key, _) {
        snoozeCountMap[key] = 1;
      });
    }

    // Parse tasks list
    final List<CheckTaskModel> tasksList = [];
    if (data['tasks'] is List) {
      final rawList = data['tasks'] as List;
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          tasksList.add(CheckTaskModel.fromMap(item, i));
        } else if (item is Map) {
          tasksList.add(
            CheckTaskModel.fromMap(Map<String, dynamic>.from(item), i),
          );
        }
      }
    }

    return ScheduledCheckInModel(
      id: documentId,
      title: data['title'] as String? ?? 'Scheduled Compliance Check',
      scheduledAt: scheduledDate,
      createdAt: createdDate,
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      storeStatus: storeStatusMap,
      remindAt: remindAtMap,
      snoozeCount: snoozeCountMap,
      tasks: tasksList,
    );
  }

  /// Check if this check can still be snoozed (ONLY ONCE per store)
  bool canSnoozeForStore(String storeId) {
    if (storeId.isNotEmpty) {
      final count = snoozeCount[storeId] ?? 0;
      if (count >= 1) return false;
      if (remindAt.containsKey(storeId)) return false;
      return true;
    }
    if (snoozeCount.values.any((c) => c >= 1)) return false;
    if (remindAt.isNotEmpty) return false;
    return true;
  }

  /// The effective scheduled DateTime aligned for comparison with device clock.
  /// Uses UTC components of scheduledAt (as stored in Firestore) aligned with local/display clock.
  DateTime get effectiveScheduledDateTime {
    final utc = scheduledAt.toUtc();
    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  /// Check if the check is overdue relative to effective scheduled time
  bool get isOverdue {
    final now = DateTime.now();
    return now.isAfter(effectiveScheduledDateTime);
  }

  /// Formatted Time String (computed in UTC, clean display without UTC text)
  String get formattedTime {
    final utc = scheduledAt.toUtc();
    final hour = utc.hour;
    final minute = utc.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:$minute $period';
  }

  /// Formatted Date String (computed in UTC, clean display without UTC text)
  String get formattedDate {
    final utc = scheduledAt.toUtc();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[utc.month - 1]} ${utc.day}, ${utc.year}';
  }

  /// Formatted Date & Time (computed in UTC, clean display without UTC text)
  String get formattedDateTime {
    final utc = scheduledAt.toUtc();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[utc.month - 1]} ${utc.day}, ${utc.year} • $formattedTime';
  }

  /// Detailed overdue or due time info string (calculated in sync with display time)
  String get overdueOrDueInfo {
    final now = DateTime.now();
    final sched = effectiveScheduledDateTime;
    if (now.isAfter(sched)) {
      final diff = now.difference(sched);
      if (diff.inMinutes < 60) {
        final mins = diff.inMinutes;
        return mins <= 1 ? 'Overdue by 1 minute' : 'Overdue by $mins minutes';
      } else {
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        return mins > 0
            ? 'Overdue by $hours hr $mins min'
            : 'Overdue by $hours hr';
      }
    } else {
      final diff = sched.difference(now);
      if (diff.inMinutes < 60) {
        final mins = diff.inMinutes;
        return mins <= 1 ? 'Due in 1 minute' : 'Due in $mins minutes';
      } else {
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        return mins > 0 ? 'Due in $hours hr $mins min' : 'Due in $hours hr';
      }
    }
  }

  /// Subtitle formatted for Hero Card (e.g. "Overdue by 8 minutes • 5 tasks")
  String get heroSubtitle {
    final taskCount = tasks.length;
    final taskLabel = taskCount == 1 ? '1 task' : '$taskCount tasks';
    return '$overdueOrDueInfo • $taskLabel';
  }

  /// Subtitle formatted for Tasks Screen (e.g. "5 tasks • Overdue by 1 hr 26 min")
  String get taskInfoSubtitle {
    final taskCount = tasks.length;
    final taskLabel = taskCount == 1 ? '1 task' : '$taskCount tasks';
    return '$taskLabel • $overdueOrDueInfo';
  }

  /// Check if this check should trigger an alert popup for the given store
  bool shouldTriggerAlertForStore(String storeId) {
    // 1. Must be actionable (pending or missed) for store
    if (!isActionableForStore(storeId)) return false;

    final now = DateTime.now();
    final sched = effectiveScheduledDateTime;

    // 2. Must be today (matching effective scheduled date OR utc scheduled date)
    final isSameDate = (sched.year == now.year &&
            sched.month == now.month &&
            sched.day == now.day) ||
        (scheduledAt.toUtc().year == now.toUtc().year &&
            scheduledAt.toUtc().month == now.toUtc().month &&
            scheduledAt.toUtc().day == now.toUtc().day);
    if (!isSameDate) {
      return false;
    }

    // 3. Current time must have reached or passed effective scheduled time
    if (now.isBefore(sched)) return false;

    // 4. If snoozed in remindAt/snoozeUntil, verify if 15 mins have passed
    if (remindAt.containsKey(storeId)) {
      final snoozedUntilMs = remindAt[storeId]!;
      if (now.millisecondsSinceEpoch < snoozedUntilMs) {
        // Still snoozed, do not show yet
        return false;
      }
    }

    return true;
  }

  /// Get specific status for a given storeId
  String getStoreStatus(String storeId) {
    return storeStatus[storeId] ?? status;
  }

  /// Check if this check contains the storeId and has pending status for it
  bool isPendingForStore(String storeId) {
    if (storeStatus.isNotEmpty && storeStatus.containsKey(storeId)) {
      return storeStatus[storeId] == 'pending';
    }
    return status == 'pending';
  }

  /// Check if this check is marked as missed for the storeId
  bool isMissedForStore(String storeId) {
    if (storeStatus.isNotEmpty && storeStatus.containsKey(storeId)) {
      return storeStatus[storeId] == 'missed';
    }
    return status == 'missed';
  }

  /// Check if this check is actionable (either pending or missed) so staff can complete it
  bool isActionableForStore(String storeId) {
    if (storeStatus.isNotEmpty && storeStatus.containsKey(storeId)) {
      final s = storeStatus[storeId];
      return s == 'pending' || s == 'missed';
    }
    return status == 'pending' || status == 'missed';
  }

  /// Check if this check is completed for the storeId
  bool isCompletedForStore(String storeId) {
    if (storeStatus.isNotEmpty && storeStatus.containsKey(storeId)) {
      return storeStatus[storeId] == 'completed';
    }
    return status == 'completed';
  }

  ScheduledCheckInModel copyWith({
    String? id,
    String? title,
    DateTime? scheduledAt,
    DateTime? createdAt,
    String? status,
    Map<String, String>? storeStatus,
    Map<String, int>? remindAt,
    Map<String, int>? snoozeCount,
    List<CheckTaskModel>? tasks,
  }) {
    return ScheduledCheckInModel(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      storeStatus: storeStatus ?? this.storeStatus,
      remindAt: remindAt ?? this.remindAt,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      tasks: tasks ?? this.tasks,
    );
  }
}
