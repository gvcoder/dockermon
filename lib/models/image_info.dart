class DockerImageInfo {
  final String repository;
  final String tag;
  final String id;
  final String createdSince;
  final String size;

  DockerImageInfo({
    required this.repository,
    required this.tag,
    required this.id,
    required this.createdSince,
    required this.size,
  });

  factory DockerImageInfo.fromDockerJson(Map<String, dynamic> json) {
    return DockerImageInfo(
      repository: json['Repository'] as String? ?? '<unknown>',
      tag: json['Tag'] as String? ?? '<none>',
      id: json['ID'] as String? ?? '',
      createdSince: json['CreatedSince'] as String? ?? json['CreatedAt'] as String? ?? '',
      size: json['Size'] as String? ?? '',
    );
  }

  String get fullName {
    if (tag.isEmpty || tag == '<none>') {
      return repository;
    }
    return '$repository:$tag';
  }

  String get shortId {
    final cleanId = id.replaceFirst('sha256:', '');
    return cleanId.length > 12 ? cleanId.substring(0, 12) : cleanId;
  }

  bool get isDangling => repository == '<none>' || tag == '<none>';
}
