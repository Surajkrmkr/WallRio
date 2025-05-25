import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wallrio/services/export.dart';

class PrimaryBtnWidget extends StatelessWidget {
  final String btnText;
  final Function() onTap;
  final Widget? icon;
  final bool isLoading;
  final double? progress;

  const PrimaryBtnWidget({
    super.key,
    required this.btnText,
    required this.onTap,
    this.isLoading = false,
    this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: isLoading
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                          border: Border.all(color: whiteColor)),
                      child: LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(20),
                        minHeight: 50,
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(bgDarkAccentColor),
                      ),
                    ),
                    Center(
                      child: Text(
                        btnText,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: whiteColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            : icon != null
                ? OutlinedButton.icon(
                    icon: Container(
                      padding: const EdgeInsets.only(bottom: 4),
                      height: 20,
                      child: icon!,
                    ),
                    onPressed: onTap,
                    label: Text(
                      btnText,
                      maxLines: 1,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: whiteColor, fontSize: 14),
                    ),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    child: Center(
                      child: Text(
                        btnText,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: whiteColor, fontSize: 14),
                      ),
                    ),
                  ),
      ),
    );
  }
}
