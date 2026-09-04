import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/compliance_check_model.dart';
import '../../models/history_record_model.dart';
import '../../models/scheduled_checkin_model.dart';
import 'staff_auth_service.dart';

class HistoryGroupModel {
  final String dateHeader;
  final List<HistoryRecordModel> records;

  const HistoryGroupModel({
    required this.dateHeader,
    required this.records,
  });
}

class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _resolveStoreId(String? storeId) {
    if (storeId != null && storeId.isNotEmpty) {
      return storeId;
    }
    return StaffAuthService.instance.currentStaff?.storeId ?? '';
  }

  String _formatTime(DateTime dt) {
    final utc = dt.toUtc();
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

  String _formatDateHeader(DateTime dt, DateTime now) {
    final dtUtc = dt.toUtc();
    final nowUtc = now.toUtc();
    if (dtUtc.year == nowUtc.year && dtUtc.month == nowUtc.month && dtUtc.day == nowUtc.day) {
      return 'Today';
    }
    final yesterday = nowUtc.subtract(const Duration(days: 1));
    if (dtUtc.year == yesterday.year &&
        dtUtc.month == yesterday.month &&
        dtUtc.day == yesterday.day) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dtUtc.month - 1]} ${dtUtc.day}, ${dtUtc.year}';
  }

  /// Stream all history records grouped by Date for the active store
  Stream<List<HistoryGroupModel>> streamHistoryGroups({String? storeId}) {
    final targetStoreId = _resolveStoreId(storeId);

    return _firestore
        .collection('Scheduled_CheckIn')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      final List<HistoryRecordModel> validRecords = [];

      for (final doc in snapshot.docs) {
        final check = ScheduledCheckInModel.fromFirestore(doc);
        final checkDate = check.scheduledAt.toUtc();
        final checkDayStart =
            DateTime.utc(checkDate.year, checkDate.month, checkDate.day);

        final bool isToday = checkDayStart.isAtSameMomentAs(todayStart);
        final bool isPast = checkDayStart.isBefore(todayStart);

        // Check store status
        bool storeMatch = false;
        bool isCompleted = false;

        if (targetStoreId.isNotEmpty) {
          if (check.storeStatus.containsKey(targetStoreId)) {
            storeMatch = true;
            isCompleted = check.storeStatus[targetStoreId] == 'completed';
          }
        } else {
          storeMatch = true;
          isCompleted = check.status == 'completed';
        }

        if (!storeMatch) continue;

        // Rule 1: For Today, ONLY show completed checks in history
        if (isToday) {
          if (isCompleted) {
            validRecords.add(HistoryRecordModel(
              id: check.id,
              title: check.title,
              date: 'Today',
              scheduledTimestamp: check.scheduledAt.millisecondsSinceEpoch,
              scheduledTime: _formatTime(checkDate),
              autoRecordedTime: _formatTime(checkDate),
              completedTime: _formatTime(checkDate),
              totalEvidence: check.tasks.length,
              completedEvidence: check.tasks.length,
              status: CheckStatus.completed,
              storeName: StaffAuthService.instance.currentStaff?.storeName ?? 'Islamabad Store',
            ));
          }
        } else if (isPast) {
          // Rule 2: For Past dates, show completed OR missed
          final status = isCompleted ? CheckStatus.completed : CheckStatus.missed;
          final header = _formatDateHeader(checkDate, now);

          validRecords.add(HistoryRecordModel(
            id: check.id,
            title: check.title,
            date: header,
            scheduledTimestamp: check.scheduledAt.millisecondsSinceEpoch,
            scheduledTime: _formatTime(checkDate),
            autoRecordedTime: isCompleted ? _formatTime(checkDate) : '--',
            completedTime: isCompleted ? _formatTime(checkDate) : '--',
            totalEvidence: check.tasks.length,
            completedEvidence: isCompleted ? check.tasks.length : 0,
            status: status,
            storeName: StaffAuthService.instance.currentStaff?.storeName ?? 'Islamabad Store',
          ));
        }
      }

      // Sort records by scheduledTimestamp descending (newest first)
      validRecords.sort(
        (a, b) => b.scheduledTimestamp.compareTo(a.scheduledTimestamp),
      );

      // Group records by Date header
      final Map<String, List<HistoryRecordModel>> groupedMap = {};
      for (final record in validRecords) {
        groupedMap.putIfAbsent(record.date, () => []).add(record);
      }

      return groupedMap.entries
          .map((e) => HistoryGroupModel(dateHeader: e.key, records: e.value))
          .toList();
    });
  }

  /// Fetch full CheckIn_Logs evidence, submittedAt timestamp, staff name, and store location
  Future<HistoryRecordModel> getFullHistoryDetails(
    HistoryRecordModel initialRecord, {
    String? storeId,
  }) async {
    final targetStoreId = _resolveStoreId(storeId);
    final currentStaff = StaffAuthService.instance.currentStaff;

    String staffName = currentStaff?.fullName ?? 'Ahmed Khan';
    String storeName = currentStaff?.storeName ?? 'Islamabad Store';
    String storeLocation = 'F-7 Markaz, Islamabad';
    String completedTime = initialRecord.completedTime;
    String autoRecordedTime = initialRecord.autoRecordedTime;
    List<EvidenceItemModel> evidenceList = [];
    int completedEvidence = initialRecord.completedEvidence;

    try {
      // 1. Fetch store address from 'Stores' collection if available
      if (targetStoreId.isNotEmpty) {
        final storeDoc =
            await _firestore.collection('Stores').doc(targetStoreId).get();
        if (storeDoc.exists) {
          final data = storeDoc.data() ?? {};
          storeName = data['storeName'] as String? ??
              data['name'] as String? ??
              storeName;
          storeLocation = data['location'] as String? ??
              data['address'] as String? ??
              data['city'] as String? ??
              storeLocation;
        }
      }

      // 2. Fetch CheckIn_Logs document for this scheduleId
      final logsQuery = await _firestore
          .collection('CheckIn_Logs')
          .where('scheduleId', isEqualTo: initialRecord.id)
          .get();

      if (logsQuery.docs.isNotEmpty) {
        final logData = logsQuery.docs.first.data();
        final submittedAtMs = logData['submittedAt'] as num?;
        final loggedStaffId = logData['staffId'] as String?;

        if (submittedAtMs != null) {
          final submittedDt =
              DateTime.fromMillisecondsSinceEpoch(submittedAtMs.toInt());
          completedTime = _formatTime(submittedDt);
          // Auto recorded time typically right at scheduled or 2 min before submission
          final autoRecordedDt =
              submittedDt.subtract(const Duration(minutes: 4));
          autoRecordedTime = _formatTime(autoRecordedDt);
        }

        // Fetch staff name if staffId is in log
        if (loggedStaffId != null && loggedStaffId.isNotEmpty) {
          if (loggedStaffId == currentStaff?.staffId) {
            staffName = currentStaff!.fullName;
          } else {
            final staffQuery = await _firestore
                .collection('Staff')
                .where('staffId', isEqualTo: loggedStaffId)
                .get();
            if (staffQuery.docs.isNotEmpty) {
              staffName =
                  staffQuery.docs.first.data()['fullName'] as String? ??
                      staffName;
            }
          }
        }

        // Parse evidence tasks from CheckIn_Logs
        final tasksList = logData['tasks'] as List<dynamic>? ?? [];
        evidenceList = tasksList.map((t) {
          if (t is Map<String, dynamic>) {
            return EvidenceItemModel.fromMap(t);
          } else if (t is Map) {
            return EvidenceItemModel.fromMap(Map<String, dynamic>.from(t));
          }
          return EvidenceItemModel(
            title: t.toString(),
            fileName: 'evidence.jpg',
          );
        }).toList();

        completedEvidence = evidenceList.length;
      }
    } catch (e) {
      debugPrint('Error fetching history details from CheckIn_Logs: $e');
    }

    return initialRecord.copyWith(
      completedTime: completedTime,
      autoRecordedTime: autoRecordedTime,
      staffName: staffName,
      storeName: storeName,
      location: storeLocation,
      evidenceList: evidenceList,
      completedEvidence: completedEvidence > 0
          ? completedEvidence
          : initialRecord.completedEvidence,
    );
  }
}
