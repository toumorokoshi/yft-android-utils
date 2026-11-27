package dev.yft.yft_android_utils

import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import java.io.IOException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

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

    fun treeOf(uri: Uri): Uri? =
        if (DocumentsContract.isTreeUri(uri)) {
            DocumentsContract.buildTreeDocumentUri(
                uri.authority,
                DocumentsContract.getTreeDocumentId(uri),
            )
        } else {
            null
        }

    /** Persisted read+write folder tree URIs held by this app. */
    fun persistedTreeUris(context: Context): List<Uri> =
        context.contentResolver.persistedUriPermissions
            .filter {
                it.isReadPermission &&
                    it.isWritePermission &&
                    DocumentsContract.isTreeUri(it.uri)
            }
            .map { it.uri }

    /**
     * Whether [uri] currently resolves to a readable document row on its provider.
     * Returns false when the file was deleted/replaced or the provider rejects access.
     */
    fun documentExists(context: Context, uri: Uri): Boolean =
        try {
            context.contentResolver
                .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { it.moveToFirst() } == true
        } catch (_: Exception) {
            false
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
        walkTree(context, treeUri, limit) { id, name, path ->
            val uri = DocumentsContract.buildDocumentUriUsingTree(treeUri, id)
            files.add(mapOf("uri" to uri.toString(), "name" to name, "path" to path))
            true
        }
        return files
    }

    /**
     * Finds the `(treeUri, relativePath)` pair for [uri] using either its own tree or any
     * persisted folder tree held by the app, up to [limit] files. Returns null if not found.
     */
    fun resolveTreePath(context: Context, uri: Uri, limit: Int): Pair<Uri, String>? {
        val targetId =
            try {
                DocumentsContract.getDocumentId(uri)
            } catch (_: IllegalArgumentException) {
                return null
            }
        val candidates = treeOf(uri)?.let { listOf(it) } ?: persistedTreeUris(context)
        for (treeUri in candidates) {
            if (treeUri.authority != uri.authority) continue
            var matchedPath: String? = null
            walkTree(context, treeUri, limit) { id, _, path ->
                if (id == targetId) {
                    matchedPath = path
                    false
                } else {
                    true
                }
            }
            if (matchedPath != null) return treeUri to matchedPath!!
        }
        return null
    }

    /**
     * Resolves [relativePath] (e.g. `work/notes.md`) below [treeUri] by walking only the path's
     * folder segments. Returns null if any segment is missing or not a directory/file as expected.
     */
    fun findInTreeByPath(context: Context, treeUri: Uri, relativePath: String): Uri? {
        val segments = relativePath.split('/').filter { it.isNotEmpty() }
        if (segments.isEmpty()) return null
        var folderId = DocumentsContract.getTreeDocumentId(treeUri)
        for ((index, segment) in segments.withIndex()) {
            val isLast = index == segments.lastIndex
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, folderId)
            var matchedId: String? = null
            context.contentResolver.query(children, CHILD_COLUMNS, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    val id = cursor.getString(0) ?: continue
                    val name = cursor.getString(1) ?: continue
                    if (name != segment) continue
                    val isDir = cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR
                    if (isLast && !isDir || !isLast && isDir) {
                        matchedId = id
                        break
                    }
                }
            }
            val nextId = matchedId ?: return null
            if (isLast) return DocumentsContract.buildDocumentUriUsingTree(treeUri, nextId)
            folderId = nextId
        }
        return null
    }

    private inline fun walkTree(
        context: Context,
        treeUri: Uri,
        limit: Int,
        onFile: (id: String, name: String, path: String) -> Boolean,
    ) {
        var count = 0
        val folders = ArrayDeque(listOf(DocumentsContract.getTreeDocumentId(treeUri) to ""))
        while (folders.isNotEmpty() && count < limit) {
            val (folderId, prefix) = folders.removeFirst()
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, folderId)
            queryChildren(context, children, waitForLoading = true)?.use { cursor ->
                val idIndex = columnIndex(cursor, DocumentsContract.Document.COLUMN_DOCUMENT_ID, 0)
                val nameIndex = columnIndex(cursor, DocumentsContract.Document.COLUMN_DISPLAY_NAME, 1)
                val mimeIndex = columnIndex(cursor, DocumentsContract.Document.COLUMN_MIME_TYPE, 2)
                while (cursor.moveToNext() && count < limit) {
                    val id = cursor.getString(idIndex)
                    val name = cursor.getString(nameIndex)
                    if (id != null && name != null && !name.startsWith(".")) {
                        val path = prefix + name
                        if (cursor.getString(mimeIndex) == DocumentsContract.Document.MIME_TYPE_DIR) {
                            folders.addLast(id to "$path/")
                        } else {
                            count++
                            if (!onFile(id, name, path)) return
                        }
                    }
                }
            }
        }
    }

    /**
     * Queries [childrenUri]. When [waitForLoading] is true and the provider sets
     * [DocumentsContract.EXTRA_LOADING] (common on cloud/sync providers returning a stale cache),
     * waits briefly for the provider's change notification and re-queries.
     */
    private fun queryChildren(
        context: Context,
        childrenUri: Uri,
        waitForLoading: Boolean = false,
    ): Cursor? {
        val cursor =
            context.contentResolver.query(childrenUri, CHILD_COLUMNS, null, null, null)
                ?: return null
        if (!waitForLoading || !isLoading(cursor)) return cursor
        val latch = CountDownLatch(1)
        val observer =
            object : ContentObserver(null) {
                override fun onChange(selfChange: Boolean) {
                    latch.countDown()
                }
            }
        cursor.registerContentObserver(observer)
        try {
            if (isLoading(cursor)) {
                latch.await(EXTRA_LOADING_TIMEOUT_MS, TimeUnit.MILLISECONDS)
            }
        } finally {
            cursor.unregisterContentObserver(observer)
        }
        cursor.close()
        return context.contentResolver.query(childrenUri, CHILD_COLUMNS, null, null, null)
    }

    private fun isLoading(cursor: Cursor): Boolean =
        cursor.extras?.getBoolean(DocumentsContract.EXTRA_LOADING, false) == true

    private fun columnIndex(cursor: Cursor, column: String, fallback: Int): Int =
        cursor.getColumnIndex(column).takeIf { it >= 0 } ?: fallback

    private const val EXTRA_LOADING_TIMEOUT_MS = 5_000L

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
