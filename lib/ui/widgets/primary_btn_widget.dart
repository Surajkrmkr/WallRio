import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallrio/services/export.dart';

class PrimaryBtnWidget extends StatelessWidget {
  final String btnText;
  final Function() onTap;
  final Widget? icon;
  final bool isLoading;
  final double? progress;
  // null = adaptive (uses primaryColorLight: white in dark mode, black in light mode)
  final Color? textColor;
  final bool forceDarkStyle;

  const PrimaryBtnWidget({
    super.key,
    required this.btnText,
    required this.onTap,
    this.isLoading = false,
    this.icon,
    this.progress,
    this.textColor,
    this.forceDarkStyle = false,
  });

  void _handleTap() {
    if (Platform.isIOS) HapticFeedback.lightImpact();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = forceDarkStyle || Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = textColor ?? (isDark ? whiteColor : blackColor);

    final customStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        isDark ? whiteColor.withValues(alpha: 0.1) : blackColor.withValues(alpha: 0.1),
      ),
      foregroundColor: WidgetStateProperty.all(resolvedColor),
      overlayColor: WidgetStateProperty.all(
        isDark ? blackColor.withValues(alpha: 0.1) : whiteColor.withValues(alpha: 0.4),
      ),
      side: WidgetStateProperty.all(
        BorderSide(
          color: isDark ? whiteColor.withValues(alpha: 0.2) : blackColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

    final content = _buildContent(context, isDark, resolvedColor, customStyle);
    // Material's spreading ink-splash ripple has no iOS equivalent — iOS
    // buttons just dim instantly on press instead. overlayColor above still
    // provides that dim; this only removes the ripple animation on top of it.
    final button = Platform.isIOS
        ? Theme(
            data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
            child: content,
          )
        : content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: button,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color resolvedColor,
      ButtonStyle customStyle) {
    return isLoading
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: resolvedColor.withValues(alpha: 0.25)),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0, end: (progress ?? 0).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => FractionallySizedBox(
                            widthFactor: progress == null ? 0 : value,
                            child: Container(
                              height: 50,
                              color: bgDarkAccentColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (progress == null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                bgDarkAccentColor),
                          ),
                        ),
                      ),
                    Text(
                      progress != null
                          ? '${(progress!.clamp(0.0, 1.0) * 100).round()}%'
                          : btnText,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: resolvedColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : icon != null
                ? OutlinedButton.icon(
                    style: customStyle,
                    icon: Container(
                      padding: const EdgeInsets.only(bottom: 4),
                      height: 20,
                      child: icon!,
                    ),
                    onPressed: _handleTap,
                    label: Text(
                      btnText,
                      maxLines: 1,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: resolvedColor, fontSize: 14),
                    ),
                  )
                : OutlinedButton(
                    style: customStyle,
                    onPressed: _handleTap,
                    child: Center(
                      child: Text(
                        btnText,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: resolvedColor, fontSize: 14),
                      ),
                    ),
                  );
  }
}
