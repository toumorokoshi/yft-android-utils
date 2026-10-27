package dev.yft.yft_android_utils

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Serves `dev.yft.yft_android_utils/documents` (lib/src/documents/platform_documents.dart).
 * File access runs on one background thread, so writes reach a file in the order Dart sent
 * them.
 */
class DocumentsChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, NAME)
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val context = activity.applicationContext
    private var pendingPick: MethodChannel.Result? = null
    private var initialDocumentSent = false

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> startPicker(Documents.openIntent(), result)
            "create" ->
                startPicker(Documents.createIntent(call.argument<String>("name") ?: "notes.md"), result)
            "read" -> onIo(result) { Documents.read(context, uriArgument(call)) }
            "write" ->
                onIo(result) {
                    Documents.write(context, uriArgument(call), call.argument<String>("text") ?: "")
                    null
                }
            "initialDocument" -> {
                val intent = if (initialDocumentSent) null else activity.intent
                initialDocumentSent = true
                onIo(result) { intent?.let { launchDocument(it) } }
            }
            else -> result.notImplemented()
        }
    }

    /** Sends a document opened while the app is running, such as a widget tap, to Dart. */
    fun onNewIntent(intent: Intent) {
        io.execute {
            val document = launchDocument(intent) ?: return@execute
            main.post { channel.invokeMethod("openDocument", document) }
        }
    }

    /** Returns true when the result was for a picker this channel started. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
        } else {
            onIo(result) {
                Documents.persist(context, uri)
                Documents.describe(context, uri)
            }
        }
        return true
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    /**
     * The document [intent] asks to open, if it is one the user picked: other apps can send
     * the same action to the exported activity, so only persisted URIs are accepted.
     */
    private fun launchDocument(intent: Intent): Map<String, String>? {
        val uri = intent.data
        if (intent.action != Documents.ACTION_OPEN || uri == null) return null
        return if (Documents.isPersisted(context, uri)) Documents.describe(context, uri) else null
    }

    private fun startPicker(intent: Intent, result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "a file picker is already open", null)
            return
        }
        pendingPick = result
        activity.startActivityForResult(intent, REQUEST_PICK)
    }

    private fun uriArgument(call: MethodCall): Uri =
        Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("missing uri"))

    private fun onIo(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (error: Exception) {
                main.post { result.error("io", error.message, error.javaClass.name) }
            }
        }
    }

    private companion object {
        const val NAME = "dev.yft.yft_android_utils/documents"
        const val REQUEST_PICK = 0x4d44
    }
}
