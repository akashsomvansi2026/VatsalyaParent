package com.vrajranitech.solution

import android.content.ActivityNotFoundException
import android.content.Intent
import android.location.Address
import android.location.Geocoder
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val updater = ApkUpdateBridge(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vatsalya/app_update")
            .setMethodCallHandler { call, result -> updater.handle(call.method, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vatsalya/maps")
            .setMethodCallHandler { call, result ->
                if (call.method == "getApiKey") {
                    val info = packageManager.getApplicationInfo(packageName, android.content.pm.PackageManager.GET_META_DATA)
                    result.success(info.metaData?.getString("com.google.android.geo.API_KEY"))
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vatsalya/location")
            .setMethodCallHandler { call, result ->
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                if (latitude == null || longitude == null ||
                    latitude !in -90.0..90.0 || longitude !in -180.0..180.0) {
                    result.error("invalid_location", "Invalid coordinates", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "reverseGeocode" -> reverseGeocode(latitude, longitude, result)
                    "openInMaps" -> {
                        val uri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude")
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            result.success(true)
                        } catch (_: ActivityNotFoundException) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun reverseGeocode(lat: Double, lon: Double, result: MethodChannel.Result) {
        if (!Geocoder.isPresent()) {
            result.success(null)
            return
        }
        val geocoder = Geocoder(this, Locale.getDefault())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            geocoder.getFromLocation(lat, lon, 1, object : Geocoder.GeocodeListener {
                override fun onGeocode(addresses: MutableList<Address>) {
                    runOnUiThread { result.success(addresses.firstOrNull()?.toMap()) }
                }
                override fun onError(errorMessage: String?) {
                    runOnUiThread { result.success(null) }
                }
            })
        } else {
            Thread {
                val address = try {
                    @Suppress("DEPRECATION")
                    geocoder.getFromLocation(lat, lon, 1)?.firstOrNull()
                } catch (_: Exception) {
                    null
                }
                runOnUiThread { result.success(address?.toMap()) }
            }.start()
        }
    }

    private fun Address.toMap(): Map<String, String?> = mapOf(
        "street" to thoroughfare,
        "area" to (subLocality ?: locality ?: featureName),
        "city" to locality,
        "state" to adminArea,
        "postalCode" to postalCode,
    )
}
