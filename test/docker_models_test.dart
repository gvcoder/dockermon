import 'package:flutter_test/flutter_test.dart';
import 'package:dockermon/models/container_info.dart';
import 'package:dockermon/models/image_info.dart';
import 'package:dockermon/models/container_profile.dart';

void main() {
  group('ContainerInfo Model Tests', () {
    test('correctly deserializes from standard Docker JSON map', () {
      final json = {
        'ID': 'a1b2c3d4e5f67890abcdef1234567890',
        'Names': '/web-app',
        'Image': 'nginx:alpine',
        'State': 'running',
        'Status': 'Up 2 hours',
        'CreatedAt': '2026-10-10 12:00:00',
        'Ports': '0.0.0.0:8080->80/tcp',
      };

      final container = ContainerInfo.fromDockerJson(json);

      expect(container.id, equals('a1b2c3d4e5f67890abcdef1234567890'));
      expect(container.name, equals('/web-app'));
      expect(container.cleanName, equals('web-app'));
      expect(container.shortId, equals('a1b2c3d4e5f6'));
      expect(container.image, equals('nginx:alpine'));
      expect(container.state, equals(ContainerState.running));
      expect(container.isRunning, isTrue);
      expect(container.isStopped, isFalse);
      expect(container.status, equals('Up 2 hours'));
      expect(container.ports, equals('0.0.0.0:8080->80/tcp'));
    });

    test('correctly maps all container states', () {
      final states = {
        'running': ContainerState.running,
        'Up 45 minutes': ContainerState.running,
        'exited': ContainerState.exited,
        'stopped': ContainerState.exited,
        'paused': ContainerState.paused,
        'created': ContainerState.created,
        'restarting': ContainerState.restarting,
        'dead': ContainerState.dead,
        'unrecognized_status': ContainerState.unknown,
      };

      for (final entry in states.entries) {
        final container = ContainerInfo.fromDockerJson({
          'ID': '1234567890ab',
          'Names': 'test',
          'Image': 'alpine',
          'State': entry.key,
          'Status': entry.key,
          'CreatedAt': '',
          'Ports': '',
        });
        expect(container.state, equals(entry.value), reason: 'Failed for state: ${entry.key}');
      }
    });

    test('isStopped returns true for exited and created states', () {
      final exited = ContainerInfo.fromDockerJson({'State': 'exited'});
      final created = ContainerInfo.fromDockerJson({'State': 'created'});
      final running = ContainerInfo.fromDockerJson({'State': 'running'});

      expect(exited.isStopped, isTrue);
      expect(created.isStopped, isTrue);
      expect(running.isStopped, isFalse);
    });

    test('fromLineFormat parses raw JSON line and handles fallback', () {
      const validLine = '{"ID":"c0ffee123456","Names":"api-server","Image":"node:20","State":"running","Status":"Up","CreatedAt":"","Ports":""}';
      final container = ContainerInfo.fromLineFormat(validLine);
      expect(container.id, equals('c0ffee123456'));
      expect(container.cleanName, equals('api-server'));

      const invalidLine = 'not-json-content';
      final fallback = ContainerInfo.fromLineFormat(invalidLine);
      expect(fallback.name, equals('Unknown'));
      expect(fallback.status, equals('not-json-content'));
    });
  });

  group('DockerImageInfo Model Tests', () {
    test('correctly parses image JSON and generates full name and short ID', () {
      final json = {
        'Repository': 'redis',
        'Tag': '7-alpine',
        'ID': 'sha256:d8b76e1a90c23456789abcdef1234567',
        'CreatedSince': '2 days ago',
        'Size': '35.4MB',
      };

      final image = DockerImageInfo.fromDockerJson(json);

      expect(image.repository, equals('redis'));
      expect(image.tag, equals('7-alpine'));
      expect(image.fullName, equals('redis:7-alpine'));
      expect(image.shortId, equals('d8b76e1a90c2'));
      expect(image.createdSince, equals('2 days ago'));
      expect(image.size, equals('35.4MB'));
      expect(image.isDangling, isFalse);
    });

    test('detects dangling images with <none> tag or repository', () {
      final danglingTag = DockerImageInfo.fromDockerJson({
        'Repository': 'my-app',
        'Tag': '<none>',
        'ID': 'sha256:11223344556677',
      });
      final danglingRepo = DockerImageInfo.fromDockerJson({
        'Repository': '<none>',
        'Tag': '<none>',
        'ID': 'sha256:99887766554433',
      });

      expect(danglingTag.isDangling, isTrue);
      expect(danglingTag.fullName, equals('my-app'));
      expect(danglingRepo.isDangling, isTrue);
      expect(danglingRepo.fullName, equals('<none>'));
    });
  });

  group('ContainerProfile Model Tests', () {
    test('provides complete built-in launch profiles', () {
      final profiles = ContainerProfile.builtInProfiles;

      expect(profiles.length, greaterThanOrEqualTo(4));
      expect(profiles.any((p) => p.profileName.contains('Alpine Keep-Alive')), isTrue);
      expect(profiles.any((p) => p.profileName.contains('Ubuntu Keep-Alive')), isTrue);
      expect(profiles.any((p) => p.profileName.contains('Nginx Web Server')), isTrue);
      expect(profiles.any((p) => p.profileName.contains('Redis')), isTrue);
    });

    test('serializes and deserializes cleanly via toJson and fromJson', () {
      final original = ContainerProfile(
        id: 'custom-profile-1',
        profileName: 'My Custom Microservice',
        image: 'golang:1.22-alpine',
        command: 'go run main.go',
        ports: '9000:9000',
        envVars: 'ENV=production\nDEBUG=false',
        restartPolicy: 'unless-stopped',
        keepAlive: true,
        isBuiltIn: false,
      );

      final json = original.toJson();
      final restored = ContainerProfile.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.profileName, equals(original.profileName));
      expect(restored.image, equals(original.image));
      expect(restored.command, equals(original.command));
      expect(restored.ports, equals(original.ports));
      expect(restored.envVars, equals(original.envVars));
      expect(restored.restartPolicy, equals(original.restartPolicy));
      expect(restored.keepAlive, isTrue);
      expect(restored.isBuiltIn, isFalse);
    });
  });
}
