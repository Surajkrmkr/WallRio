package com.shadowteam.wallrio

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shadowteam.wallrio/app_icon"

    // Activity-alias names declared in AndroidManifest.xml (NOT including MainActivity)
    private val iconAliases = listOf(
        "com.shadowteam.wallrio.icon_default",
        "com.shadowteam.wallrio.icon_yellow",
        "com.shadowteam.wallrio.icon_black2",
        "com.shadowteam.wallrio.icon_color",
        "com.shadowteam.wallrio.icon_black"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    val iconKey = call.argument<String>("iconKey")
                    if (iconKey == null) {
                        result.error("INVALID", "iconKey is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        setAppIcon(iconKey)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setAppIcon(iconKey: String) {
        val pm = packageManager

        // Determine which alias to enable
        val targetAlias = "com.shadowteam.wallrio.$iconKey"

        // Toggle only the activity-aliases; never touch MainActivity itself
        // to avoid the system killing the running activity.
        for (alias in iconAliases) {
            val component = ComponentName(this, alias)
            val newState = if (alias == targetAlias) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            pm.setComponentEnabledSetting(
                component,
                newState,
                PackageManager.DONT_KILL_APP
            )
        }
    }
}
