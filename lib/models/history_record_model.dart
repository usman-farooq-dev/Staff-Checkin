import 'compliance_check_model.dart';

class EvidenceItemModel {
  final String title;
  final String fileType; // 'PHOTO' or 'VIDEO'
  final String fileName;
  final String mediaUrl;
  final bool isVideo;

  const EvidenceItemModel({
    required this.title,
    this.fileType = 'PHOTO',
    required this.fileName,
    this.mediaUrl = '',
    this.isVideo = false,
  });

  factory EvidenceItemModel.fromMap(Map<String, dynamic> map) {
    final taskName = map['taskName'] as String? ?? 'Task Evidence';
    final mediaType = (map['mediaType'] as String? ?? 'photo').toLowerCase();
    final mediaUrl = map['mediaUrl'] as String? ?? '';
    final isVid = mediaType == 'video' ||
        mediaUrl.toLowerCase().contains('.mp4') ||
        mediaUrl.toLowerCase().contains('.mov');

    final fileName = mediaUrl.isNotEmpty
        ? Uri.tryParse(mediaUrl)?.pathSegments.last ?? '${taskName}_evidence'
        : '${taskName}_evidence';

    return EvidenceItemModel(
      title: taskName,
      fileType: isVid ? 'VIDEO' : 'PHOTO',
      fileName: fileName,
      mediaUrl: mediaUrl,
      isVideo: isVid,
    );
  }
}

class HistoryRecordModel {
  final String id;
  final String title;
  final String date;
  final int scheduledTimestamp;
  final String scheduledTime;
  final String autoRecordedTime;
  final String completedTime;
  final int totalEvidence;
  final int completedEvidence;
  final CheckStatus status;
  final String staffName;
  final String storeName;
  final String location;
  final List<EvidenceItemModel> evidenceList;

  const HistoryRecordModel({
    required this.id,
    required this.title,
    required this.date,
    this.scheduledTimestamp = 0,
    required this.scheduledTime,
    this.autoRecordedTime = '9:00 PM',
    required this.completedTime,
    required this.totalEvidence,
    required this.completedEvidence,
    required this.status,
    this.staffName = 'Ahmed Khan',
    this.storeName = 'Islamabad Store',
    this.location = 'F-7 Markaz, Islamabad',
    this.evidenceList = const [],
  });

  String get evidenceSummary => '$completedEvidence of $totalEvidence evidence items';

  HistoryRecordModel copyWith({
    String? id,
    String? title,
    String? date,
    int? scheduledTimestamp,
    String? scheduledTime,
    String? autoRecordedTime,
    String? completedTime,
    int? totalEvidence,
    int? completedEvidence,
    CheckStatus? status,
    String? staffName,
    String? storeName,
    String? location,
    List<EvidenceItemModel>? evidenceList,
  }) {
    return HistoryRecordModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      scheduledTimestamp: scheduledTimestamp ?? this.scheduledTimestamp,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      autoRecordedTime: autoRecordedTime ?? this.autoRecordedTime,
      completedTime: completedTime ?? this.completedTime,
      totalEvidence: totalEvidence ?? this.totalEvidence,
      completedEvidence: completedEvidence ?? this.completedEvidence,
      status: status ?? this.status,
      staffName: staffName ?? this.staffName,
      storeName: storeName ?? this.storeName,
      location: location ?? this.location,
      evidenceList: evidenceList ?? this.evidenceList,
    );
  }
}
