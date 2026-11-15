package com.vrajranitech.solution

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Only exposes our private update file, never arbitrary caller-supplied paths. */
class ApkUpdateBridge(private val activity: FlutterActivity) {
    private val apk get() = File(activity.cacheDir, "app_updates/update.apk")

    fun handle(method: String, result: MethodChannel.Result) {
        try {
            when (method) {
                "prepare" -> {
                    apk.parentFile!!.mkdirs()
                    if (apk.exists() && !apk.delete()) error("Cannot replace previous download")
                    result.success(apk.absolutePath)
                }
                "validate" -> { validate(); result.success(null) }
                "install" -> {
                    validate()
                    if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
                        activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:${activity.packageName}")))
                        result.success(false)
                    } else {
                        val uri = FileProvider.getUriForFile(activity,
                            "${activity.packageName}.app_updates", apk)
                        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        })
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("update_failed", e.message ?: "Update failed", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun validate() {
        val pm = activity.packageManager
        val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES
            else PackageManager.GET_SIGNATURES
        val candidate = pm.getPackageArchiveInfo(apk.absolutePath, flags)
            ?: error("The download is not a valid APK")
        val installed = pm.getPackageInfo(activity.packageName, flags)
        require(candidate.packageName == activity.packageName) { "APK belongs to another app" }
        val candidateVersion = if (Build.VERSION.SDK_INT >= 28) candidate.longVersionCode else candidate.versionCode.toLong()
        val installedVersion = if (Build.VERSION.SDK_INT >= 28) installed.longVersionCode else installed.versionCode.toLong()
        require(candidateVersion > installedVersion) { "APK must have a newer version code" }
        // Conservatively require the same signing identity. Android validates again at install.
        val candidateSigners = if (Build.VERSION.SDK_INT >= 28)
            candidate.signingInfo?.apkContentsSigners else candidate.signatures
        val installedSigners = if (Build.VERSION.SDK_INT >= 28)
            installed.signingInfo?.apkContentsSigners else installed.signatures
        require(!candidateSigners.isNullOrEmpty() && !installedSigners.isNullOrEmpty() &&
            candidateSigners.toSet() == installedSigners.toSet()) { "APK signing identity does not match" }
    }
}
