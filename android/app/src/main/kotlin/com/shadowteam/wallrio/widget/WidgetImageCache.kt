package com.shadowteam.wallrio.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

/**
 * Small dedicated on-disk cache for widget thumbnails, separate from the
 * Flutter-side cached_network_image/flutter_cache_manager cache (which is not
 * safely reachable from this native, engine-less process). Images are
 * downloaded, downscaled, and written under context.filesDir/widget_cache/ so
 * they can be exposed to RemoteViews via FileProvider content:// URIs.
 */
object WidgetImageCache {
    private const val TAG = "WidgetImageCache"
    private const val CONNECT_TIMEOUT_MS = 8000
    private const val READ_TIMEOUT_MS = 10000

    fun cacheDir(context: Context): File {
        val dir = File(context.filesDir, WidgetConstants.CACHE_DIR_NAME)
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    /**
     * Downloads [urlStr], downsamples it to at most [maxW]x[maxH], and saves it
     * as JPEG under the widget cache dir with name [fileName]. Returns the
     * absolute file path on success, or null on any failure (network, decode,
     * IO) - callers should treat null as "keep previous cached state".
     */
    fun downloadAndSave(context: Context, urlStr: String, fileName: String, maxW: Int, maxH: Int): String? {
        if (urlStr.isBlank() || maxW <= 0 || maxH <= 0) return null
        var connection: HttpURLConnection? = null
        var downloadFile: File? = null
        var decodedBitmap: Bitmap? = null
        var scaledBitmap: Bitmap? = null
        return try {
            val url = URL(urlStr)
            connection = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                doInput = true
                instanceFollowRedirects = true
            }
            connection.connect()
            if (connection.responseCode !in 200..299) {
                Log.w(TAG, "Non-2xx response ${connection.responseCode} for $urlStr")
                return null
            }

            val sourceFile = File.createTempFile("widget_image_", ".tmp", context.cacheDir)
            downloadFile = sourceFile
            sourceFile.outputStream().use { output ->
                connection.inputStream.use { input -> input.copyTo(output) }
            }

            // First pass: read bounds only to compute inSampleSize without
            // decoding the full-resolution bitmap into memory.
            val boundsOpts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(sourceFile.absolutePath, boundsOpts)
            boundsOpts.inSampleSize = calculateInSampleSize(boundsOpts.outWidth, boundsOpts.outHeight, maxW, maxH)
            boundsOpts.inJustDecodeBounds = false

            val bitmap = BitmapFactory.decodeFile(sourceFile.absolutePath, boundsOpts) ?: run {
                Log.w(TAG, "Failed to decode bitmap for $urlStr")
                return null
            }
            decodedBitmap = bitmap

            val scaled = scaleDownIfNeeded(bitmap, maxW, maxH)
            scaledBitmap = scaled

            val outFile = File(cacheDir(context), fileName)
            FileOutputStream(outFile).use { fos ->
                scaled.compress(Bitmap.CompressFormat.JPEG, 85, fos)
            }
            outFile.absolutePath
        } catch (e: Exception) {
            Log.w(TAG, "Failed to cache thumbnail for $urlStr: ${e.message}")
            null
        } finally {
            if (scaledBitmap !== decodedBitmap) scaledBitmap?.recycle()
            decodedBitmap?.recycle()
            downloadFile?.delete()
            connection?.disconnect()
        }
    }

    private fun calculateInSampleSize(width: Int, height: Int, reqWidth: Int, reqHeight: Int): Int {
        var inSampleSize = 1
        if (width <= 0 || height <= 0) return inSampleSize
        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while ((halfHeight / inSampleSize) >= reqHeight || (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    private fun scaleDownIfNeeded(bitmap: Bitmap, maxW: Int, maxH: Int): Bitmap {
        if (bitmap.width <= maxW && bitmap.height <= maxH) return bitmap
        val ratio = minOf(maxW.toFloat() / bitmap.width, maxH.toFloat() / bitmap.height)
        val targetW = (bitmap.width * ratio).toInt().coerceAtLeast(1)
        val targetH = (bitmap.height * ratio).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(bitmap, targetW, targetH, true)
    }

    /** Deletes any cached file not present in [keepPaths] so the cache never grows unbounded. */
    fun pruneUnused(context: Context, keepPaths: Set<String>) {
        try {
            val dir = cacheDir(context)
            val files = dir.listFiles() ?: return
            for (f in files) {
                if (!keepPaths.contains(f.absolutePath)) {
                    f.delete()
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to prune widget cache: ${e.message}")
        }
    }
}
