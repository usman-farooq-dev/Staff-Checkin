package com.staff.checkin

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val KIOSK_CHANNEL = "com.staff.checkin/kiosk"
    private val LOCATION_CHANNEL = "com.staff.checkin/location"
    private var isKioskActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentLocation" -> {
                    try {
                        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                        var bestLocation: Location? = null
                        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                            val providers = locationManager.getProviders(true)
                            for (provider in providers) {
                                val l = locationManager.getLastKnownLocation(provider) ?: continue
                                if (bestLocation == null || l.accuracy < bestLocation.accuracy) {
                                    bestLocation = l
                                }
                            }
                        }
                        if (bestLocation != null) {
                            result.success(mapOf(
                                "lat" to bestLocation.latitude,
                                "lng" to bestLocation.longitude,
                                "accuracy" to bestLocation.accuracy.toDouble()
                            ))
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("LOCATION_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLockTask" -> {
                    isKioskActive = true
                    try {
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val isInLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                        } else {
                            @Suppress("DEPRECATION")
                            activityManager.isInLockTaskMode
                        }
                        if (!isInLock) {
                            startLockTask()
                        }
                    } catch (e: Exception) {
                        // ignore if pinning requires user confirmation or restriction
                    }
                    hideSystemUI()
                    result.success(true)
                }
                "stopLockTask" -> {
                    isKioskActive = false
                    try {
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val isInLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                        } else {
                            @Suppress("DEPRECATION")
                            activityManager.isInLockTaskMode
                        }
                        if (isInLock) {
                            stopLockTask()
                        }
                    } catch (e: Exception) {
                        // ignore
                    }
                    showSystemUI()
                    result.success(true)
                }
                "isLockTaskActive" -> {
                    val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val isInLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                    } else {
                        @Suppress("DEPRECATION")
                        activityManager.isInLockTaskMode
                    }
                    result.success(isInLock)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isKioskActive) {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (isKioskActive) {
            hideSystemUI()
            if (hasFocus) {
                try {
                    val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val isInLock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                    } else {
                        @Suppress("DEPRECATION")
                        activityManager.isInLockTaskMode
                    }
                    if (!isInLock) {
                        startLockTask()
                    }
                } catch (e: Exception) {
                    // ignore
                }
            }
        }
    }

    private fun hideSystemUI() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.insetsController?.let { controller ->
                    controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                    controller.systemBarsBehavior =
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                )
            }
        }
    }

    private fun showSystemUI() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.insetsController?.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                )
            }
        }
    }
}
