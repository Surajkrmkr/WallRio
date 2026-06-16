import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class AutoWallpaperSettingsPage extends StatefulWidget {
  const AutoWallpaperSettingsPage({super.key});

  @override
  State<AutoWallpaperSettingsPage> createState() => _AutoWallpaperSettingsPageState();
}

class _AutoWallpaperSettingsPageState extends State<AutoWallpaperSettingsPage> {
  bool _isChanging = false;

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
                child: Consumer2<AutoWallpaperProvider, WallRio>(
                  builder: (context, autoWall, wallRio, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroAction(autoWall, isDarkMode),
                        const SizedBox(height: 32),
                        
                        _sectionTitle('Configuration'),
                        _glassCard(
                          isDarkMode,
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Enable Auto Change', style: TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: const Text('Rotate wallpapers automatically'),
                                value: autoWall.isEnabled,
                                onChanged: (val) => autoWall.setEnabled(val),
                                activeColor: const Color(0xFF37C3A3),
                              ),
                              _divider(),
                              _tileHeader('Change Frequency'),
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
                        const SizedBox(height: 24),

                        _sectionTitle('Target Screens'),
                        _glassCard(
                          isDarkMode,
                          child: _buildChipGroup(
                            options: ['Home', 'Lock', 'Both'],
                            values: [1, 2, 3],
                            selectedValue: autoWall.wallLocation,
                            onSelected: (val) => autoWall.setLocation(val),
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle('Curated Sources'),
                        _glassCard(
                          isDarkMode,
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            title: const Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text('${autoWall.selectedCategories.length} selected', style: const TextStyle(fontSize: 12)),
                            children: [
                              _selectionList(
                                items: wallRio.categories?.keys.toList() ?? [],
                                selectedItems: autoWall.selectedCategories,
                                onToggle: (item) => autoWall.toggleCategory(item),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _glassCard(
                          isDarkMode,
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            title: const Text('Collections', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text('${autoWall.selectedCollections.length} selected', style: const TextStyle(fontSize: 12)),
                            children: [
                              _selectionList(
                                items: wallRio.collections.map((c) => c.name).toList(),
                                selectedItems: autoWall.selectedCollections,
                                onToggle: (item) => autoWall.toggleCollection(item),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _sectionTitle('Color Preference'),
                        _glassCard(
                          isDarkMode,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: wallRio.colors.map((color) {
                                final isSelected = autoWall.selectedColors.contains(color.value);
                                return GestureDetector(
                                  onTap: () => autoWall.toggleColor(color.value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF37C3A3) : Colors.white.withOpacity(0.2),
                                        width: isSelected ? 3 : 1,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: const Color(0xFF37C3A3).withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                      ],
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
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

  Widget _buildHeroAction(AutoWallpaperProvider provider, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : [Colors.white, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_motion_rounded, size: 48, color: Color(0xFF37C3A3)),
          const SizedBox(height: 16),
          const Text(
            'Keep it Fresh',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Instantly rotate to a new wallpaper from your selected sources.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _isChanging ? null : () async {
              setState(() => _isChanging = true);
              await provider.changeWallpaperNow();
              if (mounted) {
                setState(() => _isChanging = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wallpaper rotated successfully!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _isChanging ? Colors.grey : const Color(0xFF37C3A3),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  if (!_isChanging)
                    BoxShadow(
                      color: const Color(0xFF37C3A3).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isChanging)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else
                    const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isChanging ? 'ROTATING...' : 'CHANGE NOW',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey),
      ),
    );
  }

  Widget _glassCard(bool isDarkMode, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _tileHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 10,
        children: List.generate(options.length, (index) {
          final isSelected = values[index] == selectedValue;
          return ChoiceChip(
            label: Text(options[index]),
            selected: isSelected,
            onSelected: (_) => onSelected(values[index]),
            selectedColor: const Color(0xFF37C3A3),
            backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            showCheckmark: false,
          );
        }),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.white.withOpacity(0.05));
  }

  Widget _selectionList({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onToggle,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedItems.contains(item);
        return CheckboxListTile(
          title: Text(item, style: const TextStyle(fontSize: 14)),
          value: isSelected,
          onChanged: (_) => onToggle(item),
          activeColor: const Color(0xFF37C3A3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          controlAffinity: ListTileControlAffinity.trailing,
        );
      },
    );
  }
}
