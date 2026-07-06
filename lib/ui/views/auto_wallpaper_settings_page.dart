import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/theme_data.dart';
import 'package:wallrio/ui/widgets/export.dart';

class AutoWallpaperSettingsPage extends StatefulWidget {
  const AutoWallpaperSettingsPage({super.key});

  @override
  State<AutoWallpaperSettingsPage> createState() => _AutoWallpaperSettingsPageState();
}

class _AutoWallpaperSettingsPageState extends State<AutoWallpaperSettingsPage> with WidgetsBindingObserver {
  bool _isBatteryOptimizationDisabled = true;
  bool _isAutoStartAvailable = false;
  bool _hasClickedAutoStart = true;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemStatus();
    }
  }

  Future<void> _checkSystemStatus() async {
    if (!Platform.isAndroid) return;
    final batteryDisabled = await isBatteryOptimizationDisabled ?? false;
    final autoStartAvailable = await isAutoStartAvailable ?? false;
    final prefs = await SharedPreferences.getInstance();
    final autoStartClicked = prefs.getBool('has_clicked_auto_start') ?? false;

    if (mounted) {
      setState(() {
        _isBatteryOptimizationDisabled = batteryDisabled;
        _isAutoStartAvailable = autoStartAvailable;
        _hasClickedAutoStart = autoStartClicked;
        _isCheckingStatus = false;
      });
    }
  }

  bool get _isReliabilityHealthy {
    if (!_isBatteryOptimizationDisabled) return false;
    if (_isAutoStartAvailable && !_hasClickedAutoStart) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverAppBarWidget(
              showLogo: false,
              showSearchBtn: false,
              centeredTitle: true,
              showBackBtn: true,
              text: 'Auto Rotation',
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                child: Consumer3<AutoWallpaperProvider, WallRio, SubscriptionProvider>(
                  builder: (context, autoWall, wallRio, subProvider, _) {
                    final isPlusMember = UserProfile.plusMember;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (autoWall.isEnabled && !_isCheckingStatus) 
                           _buildStatusBanner(isDarkMode),
                        const SizedBox(height: 16),
                        
                        _sectionTitle(context, 'Configuration'),
                        _sectionCardStyle(
                          context,
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text('Auto Change', style: Theme.of(context).textTheme.titleMedium),
                                subtitle: Text('Rotate automatically', style: Theme.of(context).textTheme.labelSmall),
                                value: autoWall.isEnabled,
                                onChanged: (val) {
                                  autoWall.setEnabled(val);
                                  if (val) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const BackgroundReliabilityDialog(),
                                    ).then((_) => _checkSystemStatus());
                                  }
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              Opacity(
                                opacity: autoWall.isEnabled ? 1.0 : 0.5,
                                child: AbsorbPointer(
                                  absorbing: !autoWall.isEnabled,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _divider(context),
                                      _tileHeader(context, 'Change Frequency'),
                                      _buildChipGroup(
                                        options: ['1H', '6H', '12H', '1D'],
                                        values: [60, 360, 720, 1440],
                                        selectedValue: autoWall.interval,
                                        onSelected: (val) => autoWall.setInterval(val),
                                        isDarkMode: isDarkMode,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle(context, 'Behavior'),
                        Opacity(
                          opacity: autoWall.isEnabled ? 1.0 : 0.5,
                          child: AbsorbPointer(
                            absorbing: !autoWall.isEnabled,
                            child: _sectionCardStyle(
                              context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _tileHeader(context, 'Target Screens'),
                                  _buildChipGroup(
                                    options: ['Home', 'Lock', 'Both'],
                                    values: [1, 2, 3],
                                    selectedValue: autoWall.wallLocation,
                                    onSelected: (val) => autoWall.setLocation(val),
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle(context, 'Curated Sources', isPro: !isPlusMember),
                        Opacity(
                          opacity: autoWall.isEnabled ? 1.0 : 0.5,
                          child: AbsorbPointer(
                            absorbing: !autoWall.isEnabled,
                            child: _sectionCardStyle(
                              context,
                              child: Opacity(
                                opacity: isPlusMember ? 1.0 : 0.5,
                                child: AbsorbPointer(
                                  absorbing: !isPlusMember,
                                  child: Column(
                                    children: [
                                      _buildSourceExpansion(
                                        context,
                                        title: 'Categories',
                                        count: autoWall.selectedCategories.length,
                                        children: [
                                          _selectionList(
                                            context,
                                            items: wallRio.categories?.keys.toList() ?? [],
                                            selectedItems: autoWall.selectedCategories,
                                            onToggle: (item) => autoWall.toggleCategory(item),
                                          ),
                                        ],
                                      ),
                                      _divider(context),
                                      _buildSourceExpansion(
                                        context,
                                        title: 'Collections',
                                        count: autoWall.selectedCollections.length,
                                        children: [
                                          _selectionList(
                                            context,
                                            items: wallRio.collections.map((c) => c.name).toList(),
                                            selectedItems: autoWall.selectedCollections,
                                            onToggle: (item) => autoWall.toggleCollection(item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!isPlusMember)
                          Opacity(
                            opacity: autoWall.isEnabled ? 1.0 : 0.5,
                            child: _proUpgradeHint('Upgrade to Pro to filter by categories & collections'),
                          ),
                        const SizedBox(height: 24),

                        _sectionTitle(context, 'Color Preference', isPro: !isPlusMember),
                        Opacity(
                          opacity: autoWall.isEnabled ? 1.0 : 0.5,
                          child: AbsorbPointer(
                            absorbing: !autoWall.isEnabled,
                            child: _sectionCardStyle(
                              context,
                              child: Opacity(
                                opacity: isPlusMember ? 1.0 : 0.5,
                                child: AbsorbPointer(
                                  absorbing: !isPlusMember,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: wallRio.colors.map((color) {
                                        final isSelected = autoWall.selectedColors.contains(color.toARGB32());
                                        return GestureDetector(
                                          onTap: () => autoWall.toggleColor(color.toARGB32()),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFF37C3A3) : Colors.white.withValues(alpha: 0.1),
                                                width: isSelected ? 3 : 1,
                                              ),
                                              boxShadow: [
                                                if (isSelected)
                                                  BoxShadow(
                                                    color: const Color(0xFF37C3A3).withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  )
                                              ],
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                                : null,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!isPlusMember)
                          Opacity(
                            opacity: autoWall.isEnabled ? 1.0 : 0.5,
                            child: _proUpgradeHint('PRO members can filter by specific color vibes'),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isDarkMode) {
    final healthy = _isReliabilityHealthy;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const BackgroundReliabilityDialog(),
          ).then((_) => _checkSystemStatus());
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: healthy 
                ? const Color(0xFF37C3A3).withValues(alpha: 0.1) 
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: healthy 
                  ? const Color(0xFF37C3A3).withValues(alpha: 0.2) 
                  : Colors.orange.withValues(alpha: 0.2)
            ),
          ),
          child: Row(
            children: [
              Icon(
                healthy ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                size: 20,
                color: healthy ? const Color(0xFF37C3A3) : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    healthy 
                        ? 'Background auto-rotation is fully optimized' 
                        : 'Tap here to fix background rotation issues',
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w700,
                      color: healthy ? const Color(0xFF37C3A3) : Colors.orange,
                    ),
                  ),
                ),
              ),
              if (!healthy)
                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }



  Widget _sectionTitle(BuildContext context, String title, {bool isPro = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: bgDarkAccentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
          ),
          if (isPro) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[400],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _proUpgradeHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 10),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, size: 12, color: Colors.orange[300]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: Colors.orange[300], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _sectionCardStyle(BuildContext context, {required Widget child}) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? bgDark2Color
          : const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _tileHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
        ),
      ),
    );
  }

  Widget _buildChipGroup({
    required List<String> options,
    required List<int> values,
    required int selectedValue,
    required Function(int) onSelected,
    required bool isDarkMode,
  }) {
    List<Widget> rows = [];
    for (int i = 0; i < options.length; i += 3) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < 3; j++) {
        if (i + j < options.length) {
          final index = i + j;
          final isSelected = values[index] == selectedValue;
          rowChildren.add(
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: j < 2 ? 8.0 : 0.0),
                child: ChoiceChip(
                  label: Center(child: Text(options[index])),
                  selected: isSelected,
                  onSelected: (_) => onSelected(values[index]),
                  selectedColor: const Color(0xFF37C3A3),
                  backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                  side: BorderSide.none,
                ),
              ),
            ),
          );
        } else {
          rowChildren.add(const Expanded(child: SizedBox()));
        }
      }
      rows.add(Row(children: rowChildren));
      if (i + 3 < options.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _buildSourceExpansion(BuildContext context, {required String title, required int count, required List<Widget> children}) {
    return ExpansionTile(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text('$count selected', style: Theme.of(context).textTheme.labelSmall),
      childrenPadding: EdgeInsets.zero,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      children: children,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).primaryColorLight.withValues(alpha: 0.08),
    );
  }

  Widget _selectionList(
    BuildContext context, {
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onToggle,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        padding: const EdgeInsets.only(bottom: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItems.contains(item);
          return CheckboxListTile(
            title: Text(item, style: Theme.of(context).textTheme.bodyMedium),
            value: isSelected,
            onChanged: (_) => onToggle(item),
            activeColor: const Color(0xFF37C3A3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            controlAffinity: ListTileControlAffinity.trailing,
            dense: true,
          );
        },
      ),
    );
  }
}
