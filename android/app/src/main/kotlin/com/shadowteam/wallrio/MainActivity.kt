package com.shadowteam.wallrio

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shadowteam.wallrio/app_icon"

    private val iconAliases = listOf(
        "com.shadowteam.wallrio.icon_default",
        "com.shadowteam.wallrio.icon_cosmic_galaxy",
        "com.shadowteam.wallrio.icon_aurora",
        "com.shadowteam.wallrio.icon_diamond",
        "com.shadowteam.wallrio.icon_electric_plasma",
        "com.shadowteam.wallrio.icon_emerald_energy",
        "com.shadowteam.wallrio.icon_gold_luxury",
        "com.shadowteam.wallrio.icon_holographic_crystal",
        "com.shadowteam.wallrio.icon_ice_crystal",
        "com.shadowteam.wallrio.icon_jelly_glass",
        "com.shadowteam.wallrio.icon_liquid_chrome",
        "com.shadowteam.wallrio.icon_liquid_glass",
        "com.shadowteam.wallrio.icon_marble",
        "com.shadowteam.wallrio.icon_molten_lava",
        "com.shadowteam.wallrio.icon_neon_glow",
        "com.shadowteam.wallrio.icon_obsidian_glass",
        "com.shadowteam.wallrio.icon_prism_glass",
        "com.shadowteam.wallrio.icon_rose_gold",
        "com.shadowteam.wallrio.icon_ruby_crystal",
        "com.shadowteam.wallrio.icon_titanium"
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
        val mainComponent = ComponentName(this, "com.shadowteam.wallrio.MainActivity")
        val targetAlias = "com.shadowteam.wallrio.$iconKey"
        val isDefault = iconKey == "icon_default" || iconKey == "default"

        val mainState = if (isDefault) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }

        if (pm.getComponentEnabledSetting(mainComponent) != mainState) {
            pm.setComponentEnabledSetting(
                mainComponent,
                mainState,
                PackageManager.DONT_KILL_APP
            )
        }

        for (alias in iconAliases) {
            val newState = if (!isDefault && alias == targetAlias) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }

            val component = ComponentName(this, alias)
            val currentState = pm.getComponentEnabledSetting(component)

            if (currentState != newState) {
                pm.setComponentEnabledSetting(
                    component,
                    newState,
                    PackageManager.DONT_KILL_APP
                )
            }
        }
    }
}
