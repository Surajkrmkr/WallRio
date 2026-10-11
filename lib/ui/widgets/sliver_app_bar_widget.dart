import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/ui/onboarding/export.dart';
import 'package:wallrio/ui/views/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class SliverAppBarWidget extends StatelessWidget {
  final bool showLogo;
  final bool showSearchBtn;
  final String text;
  final String secondaryText;
  final bool showBackBtn;
  final bool clearSearchedData;
  final bool centeredTitle;
  final bool showUserProfileIcon;
  // Defaults to [showUserProfileIcon] so every main tab gets the shortcut.
  final bool? showFavouriteBtn;
  final bool showSaleChip;
  const SliverAppBarWidget(
      {super.key,
      required this.showLogo,
      required this.text,
      this.secondaryText = '',
      required this.showSearchBtn,
      this.showBackBtn = false,
      this.clearSearchedData = false,
      this.centeredTitle = false,
      this.showUserProfileIcon = false,
      this.showFavouriteBtn,
      this.showSaleChip = false});

  bool get _showFavourite => showFavouriteBtn ?? showUserProfileIcon;

  void _onLongPressHandler(BuildContext context) {
    CNBottomSheet.show(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        isDismissible: true,
        showDragHandle: Platform.isIOS,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        backgroundColor: Colors.transparent,
        builder: (context) => const UserBottomSheet());
  }

  @override
  Widget build(BuildContext context) {
    final double toolbarHeight =
        (MediaQuery.of(context).size.height * 0.08).clamp(56, 76);
    final bar = AppBar(
      primary: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: showBackBtn ? 56 : 0,
      leading: showBackBtn
          ? BackBtnWidget(
              color: Theme.of(context).primaryColorLight,
              isActionReset: clearSearchedData)
          : const SizedBox.shrink(),
      titleSpacing: showBackBtn ? 0 : 20,
      toolbarHeight: toolbarHeight,
      centerTitle: centeredTitle,
      title: Consumer<DarkThemeProvider>(
        builder: (context, provider, _) {
          final isBrand = text == 'Wall' && secondaryText == 'Rio';
          final titleWidget = isBrand
              ? _buildBrandWordmark(context)
              : secondaryText.isEmpty
                  ? Text(text, style: Theme.of(context).textTheme.displayLarge)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text,
                            style: Theme.of(context).textTheme.displayLarge),
                        Text(
                          secondaryText,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge!
                              .copyWith(
                                  color: gradientColorMap[provider.gradType]!
                                      .first),
                        ),
                      ],
                    );
          return FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  centeredTitle ? Alignment.center : Alignment.centerLeft,
              child: titleWidget);
        },
      ),
      actions: [
        if (showSaleChip) _buildSaleChip(context),
        if (showSearchBtn)
          TopBarIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Search',
            label: 'Search',
            onTap: () => _hapticTap(() => Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchPage()))),
          ),
        if (_showFavourite) ...[
          const SizedBox(width: 8),
          _buildFavouriteIcon(context),
        ],
        if (showUserProfileIcon) ...[
          const SizedBox(width: 8),
          _buildUserProfileIcon(context),
        ],
        const SizedBox(width: 16),
      ],
    );
    return SliverPersistentHeader(
      pinned: true,
      floating: true,
      delegate: _FloatingTopBarDelegate(
        topPadding: MediaQuery.paddingOf(context).top,
        toolbarHeight: toolbarHeight,
        background: Theme.of(context).scaffoldBackgroundColor,
        bar: bar,
      ),
    );
  }

  Widget _buildBrandWordmark(BuildContext context) {
    final colors = context.appColors;
    final base = Theme.of(context).textTheme.displayLarge!.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
          height: 1.05,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Wall', style: base),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [colors.accent, colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text('Rio', style: base),
        ),
        Text('.', style: base.copyWith(color: colors.accent)),
      ],
    );
  }

  Widget _buildSaleChip(BuildContext context) {
    return Consumer2<WallRio, SubscriptionProvider>(
      builder: (context, wallRio, subProvider, _) {
        if (UserProfile.plusMember ||
            subProvider.subscriptionDaysLeft.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            final nav = Navigator.of(context);
            nav.push(
              MaterialPageRoute(
                builder: (_) => OnboardingScreen4(
                  onComplete: () => nav.pop(),
                ),
              ),
            );
          },
          child: Tooltip(
            message: 'Get WallRio Pro',
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE08A), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFF5A3200), size: 22),
            ),
          ),
        );
      },
    );
  }

  void _hapticTap(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }

  Widget _buildFavouriteIcon(BuildContext context) {
    return Consumer<FavouriteProvider>(
      builder: (context, favourites, _) {
        final count = favourites.wallList.length;
        return TopBarIconButton(
          icon: count > 0
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: 'Favourites',
          badge: count > 0 ? (count > 99 ? '99+' : '$count') : null,
          onTap: () => _hapticTap(() => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FavouritePage()))),
        );
      },
    );
  }

  Widget _buildUserProfileIcon(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, provider, _) => PremiumAvatar(
        imageUrl: provider.photoUrl,
        radius: 18,
        onTap: () => _hapticTap(() => _onLongPressHandler(context)),
      ),
    );
  }
}

/// Floats the toolbar away on scroll while the status-bar strip stays pinned
/// and opaque, so content never runs under the system icons.
class _FloatingTopBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final double toolbarHeight;
  final Color background;
  final Widget bar;

  _FloatingTopBarDelegate({
    required this.topPadding,
    required this.toolbarHeight,
    required this.background,
    required this.bar,
  });

  @override
  double get minExtent => topPadding;

  @override
  double get maxExtent => topPadding + toolbarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / toolbarHeight).clamp(0.0, 1.0);
    return ColoredBox(
      color: background,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            minHeight: toolbarHeight,
            maxHeight: toolbarHeight,
            child: Opacity(
              opacity: 1 - t,
              // Status bar inset is already applied above; stop SafeArea-wrapped
              // children (e.g. BackBtnWidget) from adding it again.
              child: MediaQuery.removePadding(
                  context: context, removeTop: true, child: bar),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_FloatingTopBarDelegate oldDelegate) => true;
}

/// Circular, softly tinted top bar action with a press-scale animation.
class TopBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final String? badge;
  final double size;
  // When set, renders as a pill with the icon followed by this text.
  final String? label;

  const TopBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge,
    this.size = 40,
    this.label,
  });

  @override
  State<TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<TopBarIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? whiteColor : const Color(0xFF1C1C1E);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? (widget.label != null ? 0.95 : 0.88) : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.label != null ? null : widget.size,
                height: widget.size,
                padding: widget.label != null
                    ? const EdgeInsets.only(left: 12, right: 16)
                    : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  color: fg.withValues(alpha: _pressed ? 0.14 : 0.07),
                  border: Border.all(color: fg.withValues(alpha: 0.06)),
                ),
                child: widget.label != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 20, color: fg),
                          const SizedBox(width: 6),
                          Text(
                            widget.label!,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: fg.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(widget.icon,
                            key: ValueKey(widget.icon), size: 21, color: fg),
                      ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: -3,
                  right: -4,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: whiteColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
