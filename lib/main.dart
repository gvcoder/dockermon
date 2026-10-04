import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/docker_provider.dart';
import 'services/docker_service.dart';
import 'widgets/container_card.dart';
import 'widgets/images_tab_view.dart';
import 'widgets/permission_error_view.dart';
import 'widgets/search_filter_bar.dart';
import 'widgets/status_header.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DockerMonApp());
}

class DockerMonApp extends StatelessWidget {
  const DockerMonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DockerProvider()),
      ],
      child: MaterialApp(
        title: 'DockerMon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF141721),
          canvasColor: const Color(0xFF181B26),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF007ACC),
            secondary: Color(0xFF00B4DB),
            surface: Color(0xFF1E222D),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const MainDashboardScreen(),
      ),
    );
  }
}

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final healthState = provider.health.state;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Metrics & App Status
              const StatusHeader(),
              const SizedBox(height: 16),

              // Body: Error View OR Main List (Containers vs Images)
              Expanded(
                child: healthState != DockerHealthState.ok
                    ? const PermissionErrorView()
                    : provider.activeTabIndex == 0
                        ? Column(
                            children: [
                              // Search & Category Filter Bar
                              const SearchFilterBar(),
                              const SizedBox(height: 16),

                              // Container List
                              Expanded(
                                child: _buildContainerList(context, provider),
                              ),
                            ],
                          )
                        : const ImagesTabView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContainerList(BuildContext context, DockerProvider provider) {
    final containers = provider.filteredContainers;

    if (containers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.widgets_outlined,
              size: 56,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 14),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'No containers matching "${provider.searchQuery}"'
                  : 'No containers found on Docker engine',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'Try clearing the search query or changing filter parameters.'
              : 'Run containers using "docker run" or Docker Compose to see them here.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: containers.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final container = containers[index];
        return ContainerCard(key: ValueKey(container.id), container: container);
      },
    );
  }
}
