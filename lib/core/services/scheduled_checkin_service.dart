import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/scheduled_checkin_model.dart';
import 'staff_auth_service.dart';

class TodaysProgressModel {
  final int totalScheduled;
  final int completedScheduled;
  final int totalTasks;
  final int completedTasks;

  const TodaysProgressModel({
    required this.totalScheduled,
    required this.completedScheduled,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  int get percentage => totalScheduled > 0
      ? ((completedScheduled / totalScheduled) * 100).round()
      : 0;

  int get pendingScheduled => totalScheduled - completedScheduled;
}

class ScheduledCheckInService {
  ScheduledCheckInService._();
  static final ScheduledCheckInService instance = ScheduledCheckInService._();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static const String _collectionName = 'Scheduled_CheckIn';

  /// Helper to check if two dates are on the same calendar day (supports both wall-clock and UTC)
  bool _isSameDay(DateTime a, DateTime b) {
    if (a.year == b.year && a.month == b.month && a.day == b.day) {
      return true;
    }
    final aUtc = a.toUtc();
    final bUtc = b.toUtc();
    return aUtc.year == bUtc.year &&
        aUtc.month == bUtc.month &&
        aUtc.day == bUtc.day;
  }

  /// Resolve current storeId from parameter or logged-in staff session
  String _resolveStoreId(String? storeId) {
    if (storeId != null && storeId.isNotEmpty) {
      return storeId;
    }
    return StaffAuthService.instance.currentStaff?.storeId ?? '';
  }

  /// Stream today's pending scheduled check-ins for the active store
  /// Sorted in ASCENDING order by scheduledAt.
  Stream<List<ScheduledCheckInModel>> streamTodaysPendingChecks({String? storeId}) {
    final targetStoreId = _resolveStoreId(storeId);
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);

    return firestore.collection(_collectionName).snapshots().map((snapshot) {
      return _processAndFilterDocs(snapshot.docs, targetStoreId, filterPending: true);
    });
  }

  /// Stream today's completed checks for the active store
  Stream<List<ScheduledCheckInModel>> streamTodaysCompletedChecks({String? storeId}) {
    final targetStoreId = _resolveStoreId(storeId);
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);

    return firestore.collection(_collectionName).snapshots().map((snapshot) {
      return _processAndFilterDocs(snapshot.docs, targetStoreId, filterPending: false);
    });
  }

  /// Stream today's progress statistics (total, completed, percentage) in realtime
  Stream<TodaysProgressModel> streamTodaysProgress({String? storeId}) {
    final targetStoreId = _resolveStoreId(storeId);
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(const TodaysProgressModel(
        totalScheduled: 0,
        completedScheduled: 0,
      ));
    }

    return firestore.collection(_collectionName).snapshots().map((snapshot) {
      final now = DateTime.now();
      int totalScheduled = 0;
      int completedScheduled = 0;
      int totalTasks = 0;
      int completedTasks = 0;

      for (final doc in snapshot.docs) {
        final check = ScheduledCheckInModel.fromFirestore(doc);
        final isToday = _isSameDay(check.effectiveScheduledDateTime, now) ||
            _isSameDay(check.scheduledAt, now);

        if (isToday) {
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

          if (storeMatch) {
            totalScheduled++;
            final taskCount = check.tasks.length;
            totalTasks += taskCount;

            if (isCompleted) {
              completedScheduled++;
              completedTasks += taskCount;
            }
          }
        }
      }

      return TodaysProgressModel(
        totalScheduled: totalScheduled,
        completedScheduled: completedScheduled,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
      );
    });
  }

  /// Fetch today's pending scheduled check-ins as a Future
  Future<List<ScheduledCheckInModel>> getTodaysPendingChecks({String? storeId}) async {
    final targetStoreId = _resolveStoreId(storeId);
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore.collection(_collectionName).get();
      return _processAndFilterDocs(snapshot.docs, targetStoreId, filterPending: true);
    } catch (e) {
      debugPrint('Error fetching Scheduled_CheckIn: $e');
      return [];
    }
  }

  /// Fetch the next single upcoming/overdue pending check (the first one after ascending sort)
  Future<ScheduledCheckInModel?> getNextPendingCheck({String? storeId}) async {
    final list = await getTodaysPendingChecks(storeId: storeId);
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  /// Core Filter & Sort logic:
  /// 1. Parse each Firestore document into ScheduledCheckInModel
  /// 2. Check if scheduledAt matches Today (or is today/overdue active check)
  /// 3. Filter by storeStatus contains targetStoreId AND status == 'pending'
  /// 4. Sort ascending by scheduledAt
  List<ScheduledCheckInModel> _processAndFilterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String storeId, {
    required bool filterPending,
  }) {
    final now = DateTime.now();
    final List<ScheduledCheckInModel> filtered = [];

    for (final doc in docs) {
      final check = ScheduledCheckInModel.fromFirestore(doc);

      // 1. Date Check: Match today's date (wall-clock or UTC)
      final isToday = _isSameDay(check.effectiveScheduledDateTime, now) ||
          _isSameDay(check.scheduledAt, now);

      // 2. Store Status Check:
      bool storeMatch;
      bool statusMatch;

      if (storeId.isNotEmpty) {
        if (check.storeStatus.containsKey(storeId)) {
          storeMatch = true;
          final currentStoreStatus = check.storeStatus[storeId];
          statusMatch = filterPending
              ? (currentStoreStatus == 'pending' || currentStoreStatus == 'missed')
              : (currentStoreStatus == 'completed');
        } else {
          // If storeStatus map exists but doesn't contain this storeId, skip
          storeMatch = false;
          statusMatch = false;
        }
      } else {
        // Fallback if no storeId is logged in: check overall status
        storeMatch = true;
        statusMatch = filterPending
            ? (check.status == 'pending' || check.status == 'missed')
            : (check.status == 'completed');
      }

      if (isToday && storeMatch && statusMatch) {
        filtered.add(check);
      }
    }

    // 3. Ascending sort on effectiveScheduledDateTime:
    filtered.sort((a, b) =>
        a.effectiveScheduledDateTime.compareTo(b.effectiveScheduledDateTime));

    return filtered;
  }

  /// Snooze a scheduled check alert for 15 minutes by saving `remindAt.<storeId>` and incrementing `snoozeCount` in Firestore
  Future<bool> snoozeCheckFor15Minutes({
    required String checkId,
    String? storeId,
  }) async {
    final targetStoreId = _resolveStoreId(storeId);
    final firestore = _firestore;
    if (firestore == null) return false;

    final snoozeUntil = DateTime.now()
        .toUtc()
        .add(const Duration(minutes: 15))
        .millisecondsSinceEpoch;

    try {
      if (targetStoreId.isNotEmpty) {
        await firestore.collection(_collectionName).doc(checkId).update({
          'remindAt.$targetStoreId': snoozeUntil,
          'snoozeUntil.$targetStoreId': snoozeUntil,
          'snoozeCount.$targetStoreId': FieldValue.increment(1),
        });
      } else {
        await firestore.collection(_collectionName).doc(checkId).update({
          'remindAt.default': snoozeUntil,
          'snoozeUntil.default': snoozeUntil,
          'snoozeCount.default': FieldValue.increment(1),
        });
      }
      debugPrint(
          'Check $checkId snoozed until: ${DateTime.fromMillisecondsSinceEpoch(snoozeUntil)}');
      return true;
    } catch (e) {
      debugPrint('Error snoozing check alert: $e');
      return false;
    }
  }

  /// Mark a scheduled check as completed for the given storeId in Firestore
  Future<bool> completeCheckForStore({
    required String checkId,
    String? storeId,
  }) async {
    final targetStoreId = _resolveStoreId(storeId);
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      if (targetStoreId.isNotEmpty) {
        // Update storeStatus.<storeId> to "completed"
        await firestore.collection(_collectionName).doc(checkId).update({
          'storeStatus.$targetStoreId': 'completed',
        });
      } else {
        await firestore.collection(_collectionName).doc(checkId).update({
          'status': 'completed',
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error updating check status to completed: $e');
      return false;
    }
  }
}
