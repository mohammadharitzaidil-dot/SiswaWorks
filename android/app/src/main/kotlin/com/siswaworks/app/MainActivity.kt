package com.siswaworks.app

import android.app.Activity
import android.content.Intent
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private val saveTemplate = 7101
    private val pickEvidence = 7102

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "siswaworks/documents").setMethodCallHandler { call, result ->
            if (pending != null) { result.error("busy", null, null); return@setMethodCallHandler }
            if (call.method == "renderPage") {
                val bytes = call.argument<ByteArray>("bytes")
                val index = call.argument<Int>("page") ?: 0
                Thread {
                    val file = java.io.File.createTempFile("review-", ".pdf", cacheDir)
                    try {
                        file.writeBytes(requireNotNull(bytes))
                        android.os.ParcelFileDescriptor.open(file, android.os.ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                            android.graphics.pdf.PdfRenderer(fd).use { pdf ->
                                pdf.openPage(index).use { page ->
                                    val scale = 1600.0 / maxOf(page.width,page.height)
                                    val bitmap = android.graphics.Bitmap.createBitmap(maxOf(1,(page.width*scale).toInt()),maxOf(1,(page.height*scale).toInt()),android.graphics.Bitmap.Config.ARGB_8888)
                                    try {
                                        bitmap.eraseColor(android.graphics.Color.WHITE)
                                        page.render(bitmap,null,null,android.graphics.pdf.PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                        val out = ByteArrayOutputStream()
                                        bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,out)
                                        val data = mapOf("count" to pdf.pageCount,"image" to out.toByteArray())
                                        runOnUiThread { result.success(data) }
                                    } finally { bitmap.recycle() }
                                }
                            }
                        }
                    } catch(e:Exception){ runOnUiThread { result.error("pdf",null,null) } }
                    finally { file.delete() }
                }.start()
                return@setMethodCallHandler
            }
            val code = when (call.method) {
                "saveTemplate" -> saveTemplate
                "pickEvidence" -> pickEvidence
                else -> { result.notImplemented(); return@setMethodCallHandler }
            }
            val intent = Intent(if (code == saveTemplate) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE).setType("application/pdf")
            if (code == saveTemplate) intent.putExtra(Intent.EXTRA_TITLE, "SiswaWorks-template.pdf")
            pending = result
            try { startActivityForResult(intent, code) }
            catch (e: Exception) { pending = null; result.error("picker", null, null) }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveTemplate && requestCode != pickEvidence) return
        val result = pending ?: return
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { result.success(null); return }
        Thread {
            try {
                val value: Any = if (requestCode == saveTemplate) {
                    assets.open("organization-template.pdf").use { input ->
                        requireNotNull(contentResolver.openOutputStream(uri, "wt")).use { output -> input.copyTo(output) }
                    }
                    true
                } else {
                    val bytes = requireNotNull(contentResolver.openInputStream(uri)).use { input ->
                        val out = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            require(out.size() + count <= 900 * 1024)
                            out.write(buffer, 0, count)
                        }
                        out.toByteArray()
                    }
                    require(bytes.take(5).toByteArray().contentEquals("%PDF-".toByteArray()))
                    val name = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                        if (it.moveToFirst()) it.getString(0) else null
                    } ?: "document.pdf"
                    mapOf("name" to name.take(200), "bytes" to bytes)
                }
                runOnUiThread { result.success(value) }
            } catch (e: Exception) { runOnUiThread { result.error("file", null, null) } }
        }.start()
    }
}

