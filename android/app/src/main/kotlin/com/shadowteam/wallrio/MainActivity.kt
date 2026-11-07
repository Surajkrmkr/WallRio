package com.shadowteam.wallrio

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import com.shadowteam.wallrio.widget.DesktopWallpaperWidgetProvider
import com.shadowteam.wallrio.widget.StaticWallpaperWidgetProvider
import com.shadowteam.wallrio.widget.VideoWallpaperWidgetProvider
import com.shadowteam.wallrio.widget.WidgetConstants
import com.shadowteam.wallrio.widget.WidgetPrefsStore
import com.shadowteam.wallrio.widget.WidgetScheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shadowteam.wallrio/app_icon"
    private val WIDGET_CHANNEL = "com.shadowteam.wallrio/home_widget"

    // Pending widget-launch extras captured from the launch/new Intent, consumed
    // (and cleared) exactly once by the Dart side via WIDGET_CHANNEL so a later
    // read (e.g. hot restart) doesn't re-trigger the same navigation.
    private var pendingWidgetType: String? = null
    private var pendingWidgetAction: String? = null
    private var pendingWidgetItemId: Int? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Idempotent: enqueueUniquePeriodicWork + KEEP policy no-ops if already scheduled.
        WidgetScheduler.schedule(applicationContext)
        captureWidgetLaunchExtras(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureWidgetLaunchExtras(intent)
    }

    private fun captureWidgetLaunchExtras(intent: Intent?) {
        val type = intent?.getStringExtra(WidgetConstants.EXTRA_WIDGET_TYPE) ?: return
        val action = intent.getStringExtra(WidgetConstants.EXTRA_WIDGET_ACTION) ?: return
        pendingWidgetType = type
        pendingWidgetAction = action
        pendingWidgetItemId = if (intent.hasExtra(WidgetConstants.EXTRA_WIDGET_ITEM_ID)) {
            intent.getIntExtra(WidgetConstants.EXTRA_WIDGET_ITEM_ID, 0)
        } else {
            null
        }
    }

    private val iconAliases = listOf(
        "com.shadowteam.wallrio.icon_default",
        "com.shadowteam.wallrio.icon_diwali",
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchWidgetAction" -> {
                    val type = pendingWidgetType
                    val action = pendingWidgetAction
                    if (type == null || action == null) {
                        result.success(null)
                    } else {
                        val map = HashMap<String, Any?>()
                        map["type"] = type
                        map["action"] = action
                        map["itemId"] = pendingWidgetItemId
                        // Clear immediately so a subsequent call doesn't double-navigate.
                        pendingWidgetType = null
                        pendingWidgetAction = null
                        pendingWidgetItemId = null
                        result.success(map)
                    }
                }
                "requestPinWidget" -> {
                    val type = call.argument<String>("type")
                    if (type == null) {
                        result.error("INVALID", "type is required", null)
                        return@setMethodCallHandler
                    }
                    result.success(requestPinWidget(type))
                }
                "getCachedWidgetItems" -> {
                    val type = call.argument<String>("type")
                    if (type == null) {
                        result.error("INVALID", "type is required", null)
                        return@setMethodCallHandler
                    }
                    // Items and thumbnail files live in this app's own private
                    // storage (widget_cache/), so Flutter can read them
                    // directly via dart:io File — no FileProvider/content-URI
                    // dance needed here (that's only required for the
                    // cross-process RemoteViews the launcher renders).
                    try {
                        val items = WidgetPrefsStore.loadItems(this, type).map { item ->
                            mapOf(
                                "id" to item.id,
                                "name" to item.name,
                                "thumbPath" to item.thumbPath,
                                "isPremium" to item.isPremium
                            )
                        }
                        result.success(items)
                    } catch (e: Exception) {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Asks the current launcher to place one of our widgets on the home
     * screen directly (Android 8.0+ / API 26+ only — `requestPinAppWidget`
     * doesn't exist below that, and not every launcher supports it even on
     * newer Android). Returns false (never throws) when unsupported so the
     * Dart side can show a normal "long-press home screen to add a widget"
     * fallback message instead of a broken button.
     */
    private fun requestPinWidget(type: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val appWidgetManager = AppWidgetManager.getInstance(this)
        if (!appWidgetManager.isRequestPinAppWidgetSupported) return false

        val providerClass = when (type) {
            WidgetConstants.TYPE_VIDEO -> VideoWallpaperWidgetProvider::class.java
            WidgetConstants.TYPE_DESKTOP -> DesktopWallpaperWidgetProvider::class.java
            else -> StaticWallpaperWidgetProvider::class.java
        }
        val provider = ComponentName(this, providerClass)
        return try {
            appWidgetManager.requestPinAppWidget(provider, null, null)
        } catch (e: Exception) {
            false
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
