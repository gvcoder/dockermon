import 'dart:convert';

enum ContainerState {
  running,
  exited,
  paused,
  created,
  restarting,
  dead,
  unknown
}

class ContainerInfo {
  final String id;
  final String name;
  final String image;
  final String stateRaw;
  final String status;
  final String created;
  final String ports;

  ContainerInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.stateRaw,
    required this.status,
    required this.created,
    required this.ports,
  });

  String get shortId => id.length > 12 ? id.substring(0, 12) : id;

  String get cleanName => name.startsWith('/') ? name.substring(1) : name;

  ContainerState get state {
    final s = stateRaw.toLowerCase();
    if (s.contains('running') || s == 'up') return ContainerState.running;
    if (s.contains('exited') || s.contains('stopped')) return ContainerState.exited;
    if (s.contains('paused')) return ContainerState.paused;
    if (s.contains('created')) return ContainerState.created;
    if (s.contains('restarting')) return ContainerState.restarting;
    if (s.contains('dead')) return ContainerState.dead;
    return ContainerState.unknown;
  }

  bool get isRunning => state == ContainerState.running;
  bool get isStopped => state == ContainerState.exited || state == ContainerState.created;

  factory ContainerInfo.fromDockerJson(Map<String, dynamic> json) {
    return ContainerInfo(
      id: json['ID'] ?? json['Id'] ?? json['id'] ?? '',
      name: json['Names'] ?? json['Name'] ?? json['name'] ?? '',
      image: json['Image'] ?? json['image'] ?? '',
      stateRaw: json['State'] ?? json['state'] ?? json['Status'] ?? '',
      status: json['Status'] ?? json['status'] ?? '',
      created: json['CreatedAt'] ?? json['Created'] ?? json['created'] ?? '',
      ports: json['Ports'] ?? json['ports'] ?? '',
    );
  }

  factory ContainerInfo.fromLineFormat(String line) {
    try {
      final jsonMap = jsonDecode(line) as Map<String, dynamic>;
      return ContainerInfo.fromDockerJson(jsonMap);
    } catch (_) {
      // Fallback for custom parsing if needed
      return ContainerInfo(
        id: '',
        name: 'Unknown',
        image: '',
        stateRaw: 'unknown',
        status: line,
        created: '',
        ports: '',
      );
    }
  }
}
