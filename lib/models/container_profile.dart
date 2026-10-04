class ContainerProfile {
  final String id;
  final String profileName;
  final String image;
  final String command;
  final String ports;
  final String envVars; // Newline or comma separated KEY=VAL
  final String restartPolicy; // "no", "always", "unless-stopped"
  final bool keepAlive;
  final bool isBuiltIn;

  ContainerProfile({
    required this.id,
    required this.profileName,
    required this.image,
    this.command = '',
    this.ports = '',
    this.envVars = '',
    this.restartPolicy = 'no',
    this.keepAlive = false,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileName': profileName,
        'image': image,
        'command': command,
        'ports': ports,
        'envVars': envVars,
        'restartPolicy': restartPolicy,
        'keepAlive': keepAlive,
        'isBuiltIn': isBuiltIn,
      };

  factory ContainerProfile.fromJson(Map<String, dynamic> json) => ContainerProfile(
        id: json['id'] ?? '',
        profileName: json['profileName'] ?? 'Custom Profile',
        image: json['image'] ?? '',
        command: json['command'] ?? '',
        ports: json['ports'] ?? '',
        envVars: json['envVars'] ?? '',
        restartPolicy: json['restartPolicy'] ?? 'no',
        keepAlive: json['keepAlive'] ?? false,
        isBuiltIn: json['isBuiltIn'] ?? false,
      );

  static List<ContainerProfile> get builtInProfiles => [
        ContainerProfile(
          id: 'builtin-alpine-keepalive',
          profileName: 'Alpine Keep-Alive Shell',
          image: 'alpine:latest',
          command: 'sh -c "while true; do sleep 3600; done"',
          keepAlive: true,
          isBuiltIn: true,
        ),
        ContainerProfile(
          id: 'builtin-ubuntu-keepalive',
          profileName: 'Ubuntu Keep-Alive Shell',
          image: 'ubuntu:latest',
          command: 'bash -c "while true; do sleep 3600; done"',
          keepAlive: true,
          isBuiltIn: true,
        ),
        ContainerProfile(
          id: 'builtin-nginx-web',
          profileName: 'Nginx Web Server',
          image: 'nginx:alpine',
          ports: '8080:80',
          restartPolicy: 'unless-stopped',
          isBuiltIn: true,
        ),
        ContainerProfile(
          id: 'builtin-redis-cache',
          profileName: 'Redis In-Memory Cache',
          image: 'redis:alpine',
          ports: '6379:6379',
          isBuiltIn: true,
        ),
      ];
}
