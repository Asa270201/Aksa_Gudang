package com.example.aksa_gudang

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "aksa_gudang/export"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "saveToDownloads") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
					result.error(
						"UNSUPPORTED_ANDROID",
						"Menyimpan langsung ke Download membutuhkan Android 10 atau lebih baru",
						null,
					)
					return@setMethodCallHandler
				}

				val fileName = call.argument<String>("fileName")
				val bytes = call.argument<ByteArray>("bytes")
				val mimeType = call.argument<String>("mimeType") ?: "text/csv"
				if (fileName == null || bytes == null) {
					result.error("INVALID_DATA", "Data file tidak lengkap", null)
					return@setMethodCallHandler
				}

				val values = ContentValues().apply {
					put(MediaStore.Downloads.DISPLAY_NAME, fileName)
					put(MediaStore.Downloads.MIME_TYPE, mimeType)
					put(
						MediaStore.Downloads.RELATIVE_PATH,
						Environment.DIRECTORY_DOWNLOADS,
					)
					put(MediaStore.Downloads.IS_PENDING, 1)
				}

				val resolver = contentResolver
				val uri = resolver.insert(
					MediaStore.Downloads.EXTERNAL_CONTENT_URI,
					values,
				)
				if (uri == null) {
					result.error("SAVE_FAILED", "Gagal membuat file di Download", null)
					return@setMethodCallHandler
				}

				try {
					resolver.openOutputStream(uri)?.use { output ->
						output.write(bytes)
					} ?: throw IllegalStateException("Gagal membuka file")
					values.clear()
					values.put(MediaStore.Downloads.IS_PENDING, 0)
					resolver.update(uri, values, null, null)
					result.success(uri.toString())
				} catch (error: Exception) {
					resolver.delete(uri, null, null)
					result.error("SAVE_FAILED", error.message, null)
				}
			}
	}
}
