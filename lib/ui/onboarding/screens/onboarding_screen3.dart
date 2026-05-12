import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';

class OnboardingScreen3 extends StatefulWidget {
  final VoidCallback onNext;
  const OnboardingScreen3({super.key, required this.onNext});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  final Set<String> _selectedVibes = {};

  void _toggleVibe(String vibe) {
    setState(() {
      if (_selectedVibes.contains(vibe)) {
        _selectedVibes.remove(vibe);
      } else {
        _selectedVibes.add(vibe);
      }
    });
  }

  void _onContinue() async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    final wallRio = Provider.of<WallRio>(context, listen: false);
    await onboardingProvider.saveVibes(_selectedVibes.toList());
    wallRio.applyVibesFilter(_selectedVibes.toList());
    widget.onNext();
  }

  void _onSkip() async {
    await Provider.of<OnboardingProvider>(context, listen: false).saveVibes([]);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Consumer<WallRio>(builder: (context, wallRio, _) {
        final categories = wallRio.categories ?? {};
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(child: _buildCategoryGrid(context, categories)),
              _buildCTA(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            "Choose your vibe",
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: whiteColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Pick a few styles to personalize WallRio",
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: whiteColor.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
      BuildContext context, Map<String, List<Walls?>> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: bgDarkAccentColor),
      );
    }
    final names = categories.keys.toList();
    final rowCount = _rowCount(names.length);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        if (rowIndex == 0) {
          return _buildRow(context, names, categories, 0, 2, 360.0);
        }
        final startIndex = 2 + (rowIndex - 1) * 3;
        return _buildRow(context, names, categories, startIndex, 3, 110.0);
      },
    );
  }

  int _rowCount(int total) {
    if (total <= 0) return 0;
    if (total <= 2) return 1;
    final remaining = total - 2;
    return 1 + ((remaining + 2) ~/ 3);
  }

  Widget _buildRow(
    BuildContext context,
    List<String> names,
    Map<String, List<Walls?>> categories,
    int startIndex,
    int count,
    double height,
  ) {
    final end = (startIndex + count).clamp(0, names.length);
    if (startIndex >= names.length) return const SizedBox.shrink();
    final items = names.sublist(startIndex, end);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _buildCategoryCard(
                context,
                items[i],
                (categories[items[i]]?.isNotEmpty ?? false)
                    ? categories[items[i]]!.first?.thumbnail ?? ''
                    : '',
                _selectedVibes.contains(items[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, String name, String thumbnail, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleVibe(name),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: bgDark2Color),
                    errorWidget: (_, __, ___) => Container(color: bgDark2Color),
                  )
                : Container(color: bgDark2Color),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? bgDarkAccentColor
                      : Colors.black.withValues(alpha: 0.25),
                  border: Border.all(
                    color: isSelected
                        ? bgDarkAccentColor
                        : whiteColor.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: whiteColor, size: 14)
                    : null,
              ),
            ),
            Positioned(
              bottom: 10,
              left: 12,
              right: 36,
              child: Text(
                name,
                style: const TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  shadows: [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1))
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    final canProceed = _selectedVibes.length >= 3;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canProceed ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: whiteColor,
                  foregroundColor: Colors.black87,
                  disabledForegroundColor: whiteColor.withValues(alpha: 0.65),
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                  elevation: canProceed ? 4 : 0,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  canProceed ? "Continue" : "Pick at least 3",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            TextButton(
              onPressed: _onSkip,
              child: Text(
                "Skip",
                style: TextStyle(
                    color: whiteColor.withValues(alpha: 0.45), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
