import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:wallrio/services/theme_data.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class BackgroundReliabilityDialog extends StatefulWidget {
  const BackgroundReliabilityDialog({super.key});

  @override
  State<BackgroundReliabilityDialog> createState() => _BackgroundReliabilityDialogState();
}

class _BackgroundReliabilityDialogState extends State<BackgroundReliabilityDialog> with WidgetsBindingObserver {
  bool _isAutoStartAvailable = false;
  bool _hasClickedAutoStart = false;
  bool _isBatteryOptimizationDisabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    final available = await isAutoStartAvailable ?? false;
    final clicked = prefs.getBool('has_clicked_auto_start') ?? false;
    final batteryDisabled = await isBatteryOptimizationDisabled ?? false;

    if (mounted) {
      setState(() {
        _isAutoStartAvailable = available;
        _hasClickedAutoStart = clicked;
        _isBatteryOptimizationDisabled = batteryDisabled;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: bgDarkAccentColor));
    }

    return SimpleDialog(
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Boost Reliability"),
          CloseButton(),
        ],
      ),
      contentPadding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.bolt_rounded, size: 54, color: bgDarkAccentColor),
        const SizedBox(height: 16),
        Text(
          'Wallpapers change most reliably when these system settings are adjusted:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        
        if (_isAutoStartAvailable) ...[
          _buildStep(
            context,
            title: 'Enable Auto-start',
            description: 'Allow WallRio to start background sync.',
            isCompleted: _hasClickedAutoStart,
            onTap: () async {
              await getAutoStartPermission();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_clicked_auto_start', true);
              _checkStatus();
            },
          ),
          const SizedBox(height: 16),
        ],

        _buildStep(
          context,
          title: 'Battery: No Restrictions',
          description: 'Prevent system from killing the background task.',
          isCompleted: _isBatteryOptimizationDisabled,
          onTap: () async {
            await disableBatteryOptimization();
            _checkStatus();
          },
        ),

        const SizedBox(height: 32),
        PrimaryBtnWidget(
          btnText: "DONE",
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, {
    required String title, 
    required String description, 
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted 
              ? bgDarkAccentColor.withValues(alpha: 0.05) 
              : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? bgDarkAccentColor.withValues(alpha: 0.2) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? bgDarkAccentColor : (isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: isCompleted ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black54),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15, 
                      color: isCompleted ? bgDarkAccentColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted ? 'Configuration Complete' : description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
