import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/container_info.dart';
import '../models/container_profile.dart';
import '../models/image_info.dart';
import '../services/docker_service.dart';

enum StatusFilter { all, running, stopped, paused }

class DockerProvider extends ChangeNotifier {
  final DockerService _dockerService = DockerService();

  DockerHealthResult _health = DockerHealthResult(DockerHealthState.ok, 'Checking...');
  DockerHealthResult get health => _health;

  int _activeTabIndex = 0; // 0 = Containers, 1 = Images
  int get activeTabIndex => _activeTabIndex;

  List<ContainerInfo> _containers = [];
  List<ContainerInfo> get containers => _containers;

  List<DockerImageInfo> _images = [];
  List<DockerImageInfo> get images => _images;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _imageSearchQuery = '';
  String get imageSearchQuery => _imageSearchQuery;

  bool _isPullingImage = false;
  bool get isPullingImage => _isPullingImage;

  String? _pullStatusMessage;
  String? get pullStatusMessage => _pullStatusMessage;

  StatusFilter _selectedFilter = StatusFilter.all;
  StatusFilter get selectedFilter => _selectedFilter;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _autoRefreshEnabled = true;
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, String> _actionLoadingMap = {};
  Map<String, String> get actionLoadingMap => Map.unmodifiable(_actionLoadingMap);

  Timer? _pollingTimer;

  DockerProvider() {
    init();
  }

  Future<void> init() async {
    await checkHealthAndRefresh();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_autoRefreshEnabled && !_isRefreshing && _health.state == DockerHealthState.ok) {
        if (_activeTabIndex == 0) {
          refreshContainers(silent: true);
        } else {
          refreshImages(silent: true);
        }
      }
    });
  }

  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    if (_autoRefreshEnabled) {
      _startPolling();
    } else {
      _pollingTimer?.cancel();
    }
    notifyListeners();
  }

  void setActiveTab(int index) {
    _activeTabIndex = index;
    if (index == 1) {
      refreshImages(silent: true);
    } else {
      refreshContainers(silent: true);
    }
    notifyListeners();
  }

  Future<void> checkHealthAndRefresh() async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _health = await _dockerService.checkHealth();
      if (_health.state == DockerHealthState.ok) {
        await refreshContainers(silent: true);
        await refreshImages(silent: true);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshContainers({bool silent = false}) async {
    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final updatedList = await _dockerService.getContainers();
      _containers = updatedList;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _health = await _dockerService.checkHealth();
    } finally {
      if (!silent) {
        _isRefreshing = false;
      }
      notifyListeners();
    }
  }

  Future<void> refreshImages({bool silent = false}) async {
    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final updatedList = await _dockerService.getImages();
      _images = updatedList;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!silent) {
        _isRefreshing = false;
      }
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setStatusFilter(StatusFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  List<ContainerInfo> get filteredContainers {
    return _containers.where((c) {
      // Status Filter
      if (_selectedFilter == StatusFilter.running && !c.isRunning) return false;
      if (_selectedFilter == StatusFilter.stopped && !c.isStopped) return false;
      if (_selectedFilter == StatusFilter.paused && c.state != ContainerState.paused) return false;

      // Text Search Filter (name, id, image, status)
      if (_searchQuery.isNotEmpty) {
        final matchesName = c.name.toLowerCase().contains(_searchQuery);
        final matchesId = c.id.toLowerCase().contains(_searchQuery);
        final matchesImage = c.image.toLowerCase().contains(_searchQuery);
        final matchesStatus = c.status.toLowerCase().contains(_searchQuery);
        return matchesName || matchesId || matchesImage || matchesStatus;
      }

      return true;
    }).toList();
  }

  int get totalCount => _containers.length;
  int get runningCount => _containers.where((c) => c.isRunning).length;
  int get stoppedCount => _containers.where((c) => c.isStopped).length;
  int get pausedCount => _containers.where((c) => c.state == ContainerState.paused).length;

  bool isActionLoading(String containerId) => _actionLoadingMap.containsKey(containerId);
  String? getActionType(String containerId) => _actionLoadingMap[containerId];

  Future<void> startContainer(String id) async {
    _actionLoadingMap[id] = 'starting';
    notifyListeners();

    try {
      await _dockerService.startContainer(id);
      await refreshContainers(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to start container $id: $e';
    } finally {
      _actionLoadingMap.remove(id);
      notifyListeners();
    }
  }

  Future<void> stopContainer(String id) async {
    _actionLoadingMap[id] = 'stopping';
    notifyListeners();

    try {
      await _dockerService.stopContainer(id);
      await refreshContainers(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to stop container $id: $e';
    } finally {
      _actionLoadingMap.remove(id);
      notifyListeners();
    }
  }

  Future<void> restartContainer(String id) async {
    _actionLoadingMap[id] = 'restarting';
    notifyListeners();

    try {
      await _dockerService.restartContainer(id);
      await refreshContainers(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to restart container $id: $e';
    } finally {
      _actionLoadingMap.remove(id);
      notifyListeners();
    }
  }

  Future<String> fetchLogs(String id) {
    return _dockerService.getLogs(id);
  }

  Future<String> fetchInspect(String id) {
    return _dockerService.inspectContainer(id);
  }

  final List<ContainerProfile> _customProfiles = [];
  List<ContainerProfile> get allProfiles => [
        ...ContainerProfile.builtInProfiles,
        ..._customProfiles,
      ];

  void saveCustomProfile(ContainerProfile profile) {
    _customProfiles.add(profile);
    notifyListeners();
  }

  Future<void> launchContainer(ContainerProfile profile, {String? customName}) async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dockerService.runContainer(profile, customName: customName);
      await refreshContainers(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to launch container: $e';
      rethrow;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> openContainerShell(String id) async {
    try {
      await _dockerService.openContainerShell(id);
    } catch (e) {
      _errorMessage = 'Failed to open terminal shell: $e';
      notifyListeners();
    }
  }

  Future<void> runInteractiveShell({required String image, String? customName, String command = 'sh'}) async {
    try {
      await _dockerService.runInteractiveShell(image: image, customName: customName, command: command);
    } catch (e) {
      _errorMessage = 'Failed to run interactive shell: $e';
      notifyListeners();
    }
  }

  Future<String> execCommand(String id, String command) {
    return _dockerService.execCommand(id, command);
  }

  Future<void> removeContainer(String id, {bool force = false}) async {
    _actionLoadingMap[id] = 'removing';
    notifyListeners();

    try {
      await _dockerService.removeContainer(id, force: force);
      await refreshContainers(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to remove container $id: $e';
    } finally {
      _actionLoadingMap.remove(id);
      notifyListeners();
    }
  }

  Future<void> pruneContainers() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await _dockerService.pruneContainers();
      await refreshContainers(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to prune containers: $e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void setImageSearchQuery(String query) {
    _imageSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<DockerImageInfo> get filteredImages {
    if (_imageSearchQuery.isEmpty) return _images;
    return _images.where((img) {
      final matchesRepo = img.repository.toLowerCase().contains(_imageSearchQuery);
      final matchesTag = img.tag.toLowerCase().contains(_imageSearchQuery);
      final matchesId = img.id.toLowerCase().contains(_imageSearchQuery);
      return matchesRepo || matchesTag || matchesId;
    }).toList();
  }

  Future<void> pullImage(String imageName) async {
    _isPullingImage = true;
    _pullStatusMessage = 'Pulling image "$imageName" from registry...';
    _errorMessage = null;
    notifyListeners();

    try {
      await _dockerService.pullImage(imageName);
      await refreshImages(silent: true);
      _pullStatusMessage = 'Successfully pulled "$imageName"!';
    } catch (e) {
      _errorMessage = 'Failed to pull image "$imageName": $e';
      rethrow;
    } finally {
      _isPullingImage = false;
      notifyListeners();
    }
  }

  Future<void> removeImage(String imageId, {bool force = false}) async {
    _actionLoadingMap[imageId] = 'removing_image';
    notifyListeners();

    try {
      await _dockerService.removeImage(imageId, force: force);
      await refreshImages(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to remove image $imageId: $e';
    } finally {
      _actionLoadingMap.remove(imageId);
      notifyListeners();
    }
  }

  Future<void> pruneImages() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await _dockerService.pruneImages();
      await refreshImages(silent: true);
    } catch (e) {
      _errorMessage = 'Failed to prune images: $e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

