package com.hardin.app

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Bridges the one native-only piece the app needs: handing a file
 * straight to WhatsApp (skipping the OS app chooser) via a
 * package-targeted ACTION_SEND intent. Flutter has no cross-platform
 * API for this — Android's FileProvider content:// URI has to be
 * generated on this side. Everything else in the app is pure Dart.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "har_din/whatsapp_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                result.success(shareToWhatsApp(path))
            } else {
                result.notImplemented()
            }
        }
    }

    private fun shareToWhatsApp(path: String): Boolean {
        return try {
            val file = File(path)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/*"
                putExtra(Intent.EXTRA_STREAM, uri)
                setPackage("com.whatsapp")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            // WhatsApp isn't installed — the Dart side falls back to the
            // normal share sheet, this is a normal outcome, not an error.
            false
        } catch (e: Exception) {
            false
        }
    }
}
