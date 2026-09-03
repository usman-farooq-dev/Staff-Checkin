enum CheckStatus { upcoming, completed, missed, overdue }

class ComplianceCheckModel {
  final String id;
  final String title;
  final String scheduledTime;
  final String? completedTime;
  final int taskCount;
  final int completedTasks;
  final CheckStatus status;
  final String? overdueInfo;

  const ComplianceCheckModel({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.completedTime,
    required this.taskCount,
    this.completedTasks = 0,
    required this.status,
    this.overdueInfo,
  });

  bool get isOverdue => status == CheckStatus.overdue;
  bool get isCompleted => status == CheckStatus.completed;
  bool get isMissed => status == CheckStatus.missed;
}
