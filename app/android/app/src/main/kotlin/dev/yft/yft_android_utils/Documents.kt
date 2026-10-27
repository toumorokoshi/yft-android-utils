package dev.yft.yft_android_utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.IOException

/** Storage Access Framework helpers shared by the app and the home screen widget. */
object Documents {
    /** Opens [Intent.getData] in the markdown editor. Sent by the widget. */
    const val ACTION_OPEN = "dev.yft.yft_android_utils.action.OPEN_DOCUMENT"

    private const val GRANT_FLAGS =
        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION

    /**
     * The system file picker. Any type is allowed because providers report markdown under
     * many MIME types (text/markdown, text/plain, application/octet-stream).
     */
    fun openIntent(): Intent =
        Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .addFlags(GRANT_FLAGS or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)

    fun createIntent(name: String): Intent =
        Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("text/markdown")
            .putExtra(Intent.EXTRA_TITLE, name)
            .addFlags(GRANT_FLAGS or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)

    /** Keeps read and write access to [uri] across restarts. Throws if it was not granted. */
    fun persist(context: Context, uri: Uri) {
        context.contentResolver.takePersistableUriPermission(uri, GRANT_FLAGS)
    }

    /** Whether the app holds a persisted write permission for [uri]. */
    fun isPersisted(context: Context, uri: Uri): Boolean =
        context.contentResolver.persistedUriPermissions.any {
            it.uri == uri && it.isReadPermission && it.isWritePermission
        }

    fun displayName(context: Context, uri: Uri): String =
        context.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            ?: uri.lastPathSegment
            ?: "document"

    /** The `{uri, name}` map that `Document.fromMap` in Dart reads. */
    fun describe(context: Context, uri: Uri): Map<String, String> =
        mapOf("uri" to uri.toString(), "name" to displayName(context, uri))

    fun read(context: Context, uri: Uri): String =
        context.contentResolver.openInputStream(uri)?.use { it.bufferedReader().readText() }
            ?: throw IOException("cannot read $uri")

    /** Replaces the file's contents; "wt" truncates, so shorter text leaves no tail behind. */
    fun write(context: Context, uri: Uri, text: String) {
        context.contentResolver.openOutputStream(uri, "wt")?.use { it.write(text.toByteArray()) }
            ?: throw IOException("cannot write $uri")
    }
}
