import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class ClearCacheWidget extends StatelessWidget {
  const ClearCacheWidget({super.key});

  void _clear(BuildContext context) {
    DefaultCacheManager().emptyCache();
    Navigator.pop(context);
    ToastWidget.showToast("Cache Cleared");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text("Clear Cache"),
      content: Text(
        "Clearing cache will free up some memory",
        style: Theme.of(context).textTheme.labelLarge,
      ),
      actions: Platform.isIOS
          ? [
              CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => _clear(context),
                  child: const Text("Clear")),
            ]
          : [
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              OutlinedButton(
                  onPressed: () => _clear(context),
                  child: const Text("Clear")),
            ],
    );
  }
}
