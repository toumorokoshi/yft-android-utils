package dev.yft.yft_android_utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
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

    /** The system folder picker; the grant covers every document below the folder. */
    fun openTreeIntent(): Intent =
        Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .addFlags(
                GRANT_FLAGS or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )

    /** Keeps read and write access to [uri] across restarts. Throws if it was not granted. */
    fun persist(context: Context, uri: Uri) {
        context.contentResolver.takePersistableUriPermission(uri, GRANT_FLAGS)
    }

    /**
     * Whether the app holds a persisted write permission for [uri], either for the file itself
     * or for the folder tree it was found in. The provider checks that a tree document is below
     * its tree, so a URI naming a granted tree cannot reach files outside it.
     */
    fun isPersisted(context: Context, uri: Uri): Boolean {
        val granted =
            context.contentResolver.persistedUriPermissions
                .filter { it.isReadPermission && it.isWritePermission }
                .map { it.uri }
        return uri in granted || treeOf(uri)?.let { it in granted } == true
    }

    private fun treeOf(uri: Uri): Uri? =
        if (DocumentsContract.isTreeUri(uri)) {
            DocumentsContract.buildTreeDocumentUri(
                uri.authority,
                DocumentsContract.getTreeDocumentId(uri),
            )
        } else {
            null
        }

    /** The `{uri, name}` map for a folder tree from [openTreeIntent]. */
    fun describeTree(context: Context, treeUri: Uri): Map<String, String> {
        val root =
            DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            )
        return mapOf("uri" to treeUri.toString(), "name" to displayName(context, root))
    }

    /**
     * Every file below [treeUri], breadth first, as `{uri, name, path}` maps for
     * `FolderFile.fromMap` in Dart. Hidden files and folders (names starting with `.`) are
     * skipped, and listing stops after [limit] files.
     */
    fun listTree(context: Context, treeUri: Uri, limit: Int): List<Map<String, String>> {
        val files = mutableListOf<Map<String, String>>()
        val folders = ArrayDeque(listOf(DocumentsContract.getTreeDocumentId(treeUri) to ""))
        while (folders.isNotEmpty() && files.size < limit) {
            val (folderId, prefix) = folders.removeFirst()
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, folderId)
            context.contentResolver.query(children, CHILD_COLUMNS, null, null, null)?.use { cursor ->
                while (cursor.moveToNext() && files.size < limit) {
                    val id = cursor.getString(0)
                    val name = cursor.getString(1)
                    if (id != null && name != null && !name.startsWith(".")) {
                        val path = prefix + name
                        if (cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR) {
                            folders.addLast(id to "$path/")
                        } else {
                            val uri = DocumentsContract.buildDocumentUriUsingTree(treeUri, id)
                            files.add(mapOf("uri" to uri.toString(), "name" to name, "path" to path))
                        }
                    }
                }
            }
        }
        return files
    }

    private val CHILD_COLUMNS =
        arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
        )

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
