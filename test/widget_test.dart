import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dockermon/main.dart';
import 'package:dockermon/models/container_info.dart';
import 'package:dockermon/models/image_info.dart';
import 'package:dockermon/providers/docker_provider.dart';
import 'package:dockermon/services/docker_service.dart';
import 'package:dockermon/widgets/pull_image_dialog.dart';
import 'package:provider/provider.dart';

class FakeDockerService extends DockerService {
  @override
  Future<DockerHealthResult> checkHealth() async {
    return DockerHealthResult(DockerHealthState.ok, 'Docker is running');
  }

  @override
  Future<List<ContainerInfo>> getContainers() async {
    return [];
  }

  @override
  Future<List<DockerImageInfo>> getImages() async {
    return [];
  }
}

void main() {
  testWidgets('App initializes with branding, controls, and metric cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Provide a test-safe provider with background polling disabled and fake docker service
    final provider = DockerProvider(dockerService: FakeDockerService(), autoStart: false);

    await tester.pumpWidget(DockerMonApp(provider: provider));
    await tester.pump();

    // Verify Brand title & subtitle
    expect(find.text('DockerMon'), findsOneWidget);
    expect(find.text('Linux Docker Engine Monitor'), findsOneWidget);

    // Verify Action Controls
    expect(find.text('Launch Container'), findsOneWidget);
    expect(find.text('Live Sync'), findsOneWidget);

    // Verify Navigation View Switcher Tabs
    expect(find.text('Containers (0)'), findsOneWidget);
    expect(find.text('Images (0)'), findsOneWidget);

    // Verify Default Container Metric Cards
    expect(find.text('Total Containers'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Stopped'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('Navigation tab switching toggles between Containers and Images views', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = DockerProvider(dockerService: FakeDockerService(), autoStart: false);

    await tester.pumpWidget(DockerMonApp(provider: provider));
    await tester.pump();

    // Initially in Containers View
    expect(find.text('Total Containers'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_rounded), findsWidgets);

    // Tap on the 'Images (0)' tab
    final imagesTab = find.text('Images (0)');
    expect(imagesTab, findsOneWidget);
    await tester.tap(imagesTab);
    await tester.pumpAndSettle();

    // Verify View switched to Image Library
    expect(provider.activeTabIndex, equals(1));

    // Verify Metric cards updated dynamically to image statistics
    expect(find.text('Total Images'), findsOneWidget);
    expect(find.text('Active Tagged'), findsOneWidget);
    expect(find.text('Dangling / Unused'), findsOneWidget);
    expect(find.text('Profiles Built-In'), findsOneWidget);

    // Verify Image controls are visible
    expect(find.text('Pull Image'), findsOneWidget);
    expect(find.text('No local Docker images found'), findsOneWidget);

    // Tap back to 'Containers (0)' tab
    final containersTab = find.text('Containers (0)');
    await tester.tap(containersTab);
    await tester.pumpAndSettle();

    expect(provider.activeTabIndex, equals(0));
    expect(find.text('Total Containers'), findsOneWidget);
  });

  testWidgets('SearchFilterBar allows query entry and status chip selection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = DockerProvider(dockerService: FakeDockerService(), autoStart: false);

    await tester.pumpWidget(DockerMonApp(provider: provider));
    await tester.pump();

    // Verify Search Bar and Category Chips
    expect(find.text('All (0)'), findsOneWidget);
    expect(find.text('Running (0)'), findsOneWidget);
    expect(find.text('Stopped (0)'), findsOneWidget);
    expect(find.text('Paused (0)'), findsOneWidget);

    // Enter search text
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'nginx-web');
    await tester.pump();

    expect(provider.searchQuery, equals('nginx-web'));

    // Select 'Running' filter chip
    await tester.tap(find.text('Running (0)'));
    await tester.pump();

    expect(provider.selectedFilter, equals(StatusFilter.running));

    // Select 'Stopped' filter chip
    await tester.tap(find.text('Stopped (0)'));
    await tester.pump();

    expect(provider.selectedFilter, equals(StatusFilter.stopped));
  });

  testWidgets('PullImageDialog displays presets and updates text on chip tap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = DockerProvider(dockerService: FakeDockerService(), autoStart: false);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: PullImageDialog(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Dialog Elements
    expect(find.text('Pull Docker Image'), findsOneWidget);
    expect(find.text('Popular Presets'), findsOneWidget);

    // Verify Preset Chips exist
    expect(find.text('alpine:latest'), findsOneWidget);
    expect(find.text('redis:alpine'), findsOneWidget);
    expect(find.text('nginx:alpine'), findsOneWidget);
    expect(find.text('postgres:latest'), findsOneWidget);

    // Tap a preset chip (e.g. redis:alpine)
    await tester.tap(find.text('redis:alpine'));
    await tester.pump();

    // Text field should be populated with the preset
    final inputFinder = find.widgetWithText(TextField, 'redis:alpine');
    expect(inputFinder, findsOneWidget);
  });
}
