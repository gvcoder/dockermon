import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/container_profile.dart';
import '../providers/docker_provider.dart';

class LaunchContainerDialog extends StatefulWidget {
  const LaunchContainerDialog({super.key});

  @override
  State<LaunchContainerDialog> createState() => _LaunchContainerDialogState();
}

class _LaunchContainerDialogState extends State<LaunchContainerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _commandController = TextEditingController();
  final _portsController = TextEditingController();
  final _envVarsController = TextEditingController();
  final _profileNameController = TextEditingController();

  String _restartPolicy = 'no';
  bool _keepAlive = false;
  bool _isLaunching = false;
  String? _errorMsg;

  ContainerProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    // Default to first built-in profile (Alpine Keep-Alive)
    final profiles = ContainerProfile.builtInProfiles;
    if (profiles.isNotEmpty) {
      _applyProfile(profiles.first);
    }
  }

  void _applyProfile(ContainerProfile profile) {
    setState(() {
      _selectedProfile = profile;
      _imageController.text = profile.image;
      _commandController.text = profile.command;
      _portsController.text = profile.ports;
      _envVarsController.text = profile.envVars;
      _restartPolicy = profile.restartPolicy;
      _keepAlive = profile.keepAlive;
    });
  }

  Future<void> _submitLaunch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLaunching = true;
      _errorMsg = null;
    });

    final profile = ContainerProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileName: _selectedProfile?.profileName ?? 'Custom Launch',
      image: _imageController.text.trim(),
      command: _commandController.text.trim(),
      ports: _portsController.text.trim(),
      envVars: _envVarsController.text.trim(),
      restartPolicy: _restartPolicy,
      keepAlive: _keepAlive,
    );

    try {
      final provider = context.read<DockerProvider>();
      await provider.launchContainer(profile, customName: _nameController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Container "${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : profile.image}" launched!'),
            backgroundColor: const Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
          _isLaunching = false;
        });
      }
    }
  }

  void _saveCustomProfile() {
    if (_imageController.text.trim().isEmpty) return;

    final name = _profileNameController.text.trim().isNotEmpty
        ? _profileNameController.text.trim()
        : 'Profile ${_imageController.text.trim()}';

    final customProfile = ContainerProfile(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      profileName: name,
      image: _imageController.text.trim(),
      command: _commandController.text.trim(),
      ports: _portsController.text.trim(),
      envVars: _envVarsController.text.trim(),
      restartPolicy: _restartPolicy,
      keepAlive: _keepAlive,
      isBuiltIn: false,
    );

    context.read<DockerProvider>().saveCustomProfile(customProfile);
    _applyProfile(customProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile "$name" saved!'),
        backgroundColor: const Color(0xFF007ACC),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _commandController.dispose();
    _portsController.dispose();
    _envVarsController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DockerProvider>();
    final allProfiles = provider.allProfiles;

    return Dialog(
      backgroundColor: const Color(0xFF181B26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF00E676), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Launch New Container',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Parameter Profile Selector Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141721),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ContainerProfile>(
                      value: _selectedProfile,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E222D),
                      hint: const Text('Select Launch Preset Profile', style: TextStyle(color: Colors.white54)),
                      items: allProfiles.map((profile) {
                        return DropdownMenuItem<ContainerProfile>(
                          value: profile,
                          child: Row(
                            children: [
                              Icon(
                                profile.isBuiltIn ? Icons.bookmark_rounded : Icons.person_pin_rounded,
                                size: 16,
                                color: profile.isBuiltIn ? const Color(0xFF00B4DB) : const Color(0xFFFFAB40),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                profile.profileName,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${profile.image})',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (profile) {
                        if (profile != null) _applyProfile(profile);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Input Fields Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'Container Name (Optional)',
                        hint: 'e.g. my-alpine-app',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _imageController,
                        label: 'Docker Image *',
                        hint: 'e.g. alpine:latest',
                        icon: Icons.layers_outlined,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Keep Alive Switch Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _keepAlive
                        ? const Color(0xFF00E676).withOpacity(0.1)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _keepAlive
                          ? const Color(0xFF00E676).withOpacity(0.4)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            color: _keepAlive ? const Color(0xFF00E676) : Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keep-Alive Daemon Mode',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Keeps shell images (Alpine, Ubuntu) running continuously in background',
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _keepAlive,
                        activeColor: const Color(0xFF00E676),
                        onChanged: (val) => setState(() => _keepAlive = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Override Command & Ports
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _commandController,
                        label: 'Override Command',
                        hint: 'e.g. sh -c "while true; do sleep 3600; done"',
                        icon: Icons.code_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _portsController,
                        label: 'Port Mapping',
                        hint: 'e.g. 8080:80',
                        icon: Icons.input_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Env Vars & Restart Policy
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _envVarsController,
                        label: 'Environment Variables',
                        hint: 'KEY=VAL (comma or newline separated)',
                        icon: Icons.settings_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restart Policy',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141721),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _restartPolicy,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E222D),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: const [
                                  DropdownMenuItem(value: 'no', child: Text('No restart')),
                                  DropdownMenuItem(value: 'always', child: Text('Always restart')),
                                  DropdownMenuItem(value: 'unless-stopped', child: Text('Unless stopped')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _restartPolicy = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Footer Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Save as Custom Profile Button
                    OutlinedButton.icon(
                      onPressed: _saveCustomProfile,
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Save Preset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00B4DB),
                        side: BorderSide(color: const Color(0xFF00B4DB).withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    Row(
                      children: [
                        // Open Interactive Shell in Terminal Window (-it)
                        ElevatedButton.icon(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            context.read<DockerProvider>().runInteractiveShell(
                                  image: _imageController.text.trim(),
                                  customName: _nameController.text.trim(),
                                  command: _commandController.text.trim(),
                                );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.computer_rounded, size: 18),
                          label: const Text('Launch Terminal (-it)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4DB),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Launch Daemon Container Button
                        ElevatedButton.icon(
                          onPressed: _isLaunching ? null : _submitLaunch,
                          icon: _isLaunching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: Text(_isLaunching ? 'Launching...' : 'Launch Container'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141721),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              prefixIcon: Icon(icon, size: 16, color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
