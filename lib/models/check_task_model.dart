enum RequirementType { photo, video, photoOrVideo }

class CheckTaskModel {
  final int stepNumber;
  final String title;
  final String description;
  final RequirementType requirementType;
  final bool isRequired;
  final bool isCompleted;
  final String? capturedFilePath;
  final String imageUrl;

  const CheckTaskModel({
    required this.stepNumber,
    required this.title,
    this.description = '',
    required this.requirementType,
    this.isRequired = false,
    this.isCompleted = false,
    this.capturedFilePath,
    this.imageUrl = '',
  });

  String get requirementLabel {
    switch (requirementType) {
      case RequirementType.photo:
        return 'Photo required';
      case RequirementType.video:
        return 'Video required';
      case RequirementType.photoOrVideo:
        return 'Photo or video required';
    }
  }

  bool get isVideoFile {
    if (capturedFilePath != null) {
      final path = capturedFilePath!.toLowerCase();
      if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.mkv')) {
        return true;
      }
    }
    return requirementType == RequirementType.video;
  }

  String get resolvedMediaType => isVideoFile ? 'video' : 'photo';

  factory CheckTaskModel.fromMap(Map<String, dynamic> map, int index) {
    final taskName = map['taskName'] as String? ?? map['title'] as String? ?? 'Task ${index + 1}';
    final mediaTypeStr = (map['mediaType'] as String? ?? 'both').toLowerCase();
    final isRequired = map['isRequired'] as bool? ?? false;

    RequirementType requirementType;
    if (mediaTypeStr == 'image' || mediaTypeStr == 'photo') {
      requirementType = RequirementType.photo;
    } else if (mediaTypeStr == 'video') {
      requirementType = RequirementType.video;
    } else {
      requirementType = RequirementType.photoOrVideo;
    }

    return CheckTaskModel(
      stepNumber: index + 1,
      title: taskName,
      description: map['description'] as String? ?? 'Capture evidence for $taskName.',
      requirementType: requirementType,
      isRequired: isRequired,
      isCompleted: map['isCompleted'] as bool? ?? false,
      capturedFilePath: map['capturedFilePath'] as String?,
      imageUrl: map['imageUrl'] as String? ?? map['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    String mediaTypeStr;
    switch (requirementType) {
      case RequirementType.photo:
        mediaTypeStr = 'photo';
        break;
      case RequirementType.video:
        mediaTypeStr = 'video';
        break;
      case RequirementType.photoOrVideo:
        mediaTypeStr = 'both';
        break;
    }

    return {
      'taskName': title,
      'mediaType': mediaTypeStr,
      'isRequired': isRequired,
      'isCompleted': isCompleted,
      if (capturedFilePath != null) 'capturedFilePath': capturedFilePath,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    };
  }

  CheckTaskModel copyWith({
    int? stepNumber,
    String? title,
    String? description,
    RequirementType? requirementType,
    bool? isRequired,
    bool? isCompleted,
    String? capturedFilePath,
    String? imageUrl,
  }) {
    return CheckTaskModel(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      requirementType: requirementType ?? this.requirementType,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      capturedFilePath: capturedFilePath ?? this.capturedFilePath,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
