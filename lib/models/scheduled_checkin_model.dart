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
    // Parse scheduledAt
    DateTime scheduledDate;
    final scheduledAtRaw = data['scheduledAt'];
    if (scheduledAtRaw is int) {
      scheduledDate = DateTime.fromMillisecondsSinceEpoch(scheduledAtRaw);
    } else if (scheduledAtRaw is Timestamp) {
      scheduledDate = scheduledAtRaw.toDate();
    } else if (scheduledAtRaw is String) {
      scheduledDate = DateTime.tryParse(scheduledAtRaw) ?? DateTime.now();
    } else {
      scheduledDate = DateTime.now();
    }

    // Parse createdAt
    DateTime? createdDate;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is int) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else if (createdAtRaw is Timestamp) {
      createdDate = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdDate = DateTime.tryParse(createdAtRaw);
    }

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
      return count < 1;
    }
    return snoozeCount.isEmpty;
  }

  /// Check if the check is overdue relative to now
  bool get isOverdue => DateTime.now().isAfter(scheduledAt);

  /// Formatted Time String (e.g. 6:57 PM)
  String get formattedTime {
    final hour = scheduledAt.hour;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:$minute $period';
  }

  /// Detailed overdue or due time info string
  String get overdueOrDueInfo {
    final now = DateTime.now();
    if (now.isAfter(scheduledAt)) {
      final diff = now.difference(scheduledAt);
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
      final diff = scheduledAt.difference(now);
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
    // 1. Must be pending for store
    if (!isPendingForStore(storeId)) return false;

    // 2. Must be today
    final now = DateTime.now();
    if (scheduledAt.year != now.year ||
        scheduledAt.month != now.month ||
        scheduledAt.day != now.day) {
      return false;
    }

    // 3. Current time must have reached or passed scheduledAt
    if (now.isBefore(scheduledAt)) return false;

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
