package dev.yft.yft_android_utils

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews

/** The file each placed markdown widget opens, keyed by app widget id. */
object MarkdownWidgets {
    private const val PREFERENCES = "markdown_widgets"
    const val EXTRA_NAME = "dev.yft.yft_android_utils.extra.NAME"

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun save(context: Context, widgetId: Int, uri: Uri, name: String) {
        preferences(context)
            .edit()
            .putString("uri_$widgetId", uri.toString())
            .putString("name_$widgetId", name)
            .apply()
    }

    private const val PIN_WINDOW_MILLIS = 60_000L

    /** Records that [widgetId] was just pinned from the app with its file already bound. */
    fun markPinned(context: Context, widgetId: Int) {
        preferences(context).edit().putLong("pinned_$widgetId", System.currentTimeMillis()).apply()
    }

    /** Whether [widgetId] was pinned within the last minute. Clears the record. */
    fun consumeRecentPin(context: Context, widgetId: Int): Boolean {
        val preferences = preferences(context)
        val pinnedAt = preferences.getLong("pinned_$widgetId", 0L)
        preferences.edit().remove("pinned_$widgetId").apply()
        return System.currentTimeMillis() - pinnedAt < PIN_WINDOW_MILLIS
    }

    /**
     * Asks the home screen to add a widget for [uri]. Once the user places it,
     * [MarkdownWidgetPinnedReceiver] binds the file to the new widget. Returns false when the
     * home screen cannot add widgets for apps (or Android is older than 8.0).
     */
    fun requestPin(context: Context, uri: Uri, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = AppWidgetManager.getInstance(context)
        if (!manager.isRequestPinAppWidgetSupported) return false
        val callback =
            Intent(context, MarkdownWidgetPinnedReceiver::class.java)
                .setData(uri)
                .putExtra(EXTRA_NAME, name)
        // Mutable so the home screen can add the new widget's id.
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) flags = flags or PendingIntent.FLAG_MUTABLE
        val pinned = PendingIntent.getBroadcast(context, uri.hashCode(), callback, flags)
        return manager.requestPinAppWidget(
            ComponentName(context, MarkdownWidgetProvider::class.java),
            null,
            pinned,
        )
    }

    fun remove(context: Context, widgetIds: IntArray) {
        val editor = preferences(context).edit()
        widgetIds.forEach { editor.remove("uri_$it").remove("name_$it").remove("pinned_$it") }
        editor.apply()
    }

    /** Draws the widget: the file's name, opening it in the editor when tapped. */
    fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val preferences = preferences(context)
        val uri = preferences.getString("uri_$widgetId", null)
        val name =
            preferences.getString("name_$widgetId", null)
                ?: context.getString(R.string.markdown_widget_unset)
        val intent =
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (uri != null) intent.setAction(Documents.ACTION_OPEN).setData(Uri.parse(uri))
        val tap =
            PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        val views =
            RemoteViews(context.packageName, R.layout.markdown_widget).apply {
                setTextViewText(R.id.markdown_widget_name, name)
                setOnClickPendingIntent(R.id.markdown_widget_root, tap)
            }
        manager.updateAppWidget(widgetId, views)
    }
}

/** A 1x1 home screen widget that opens one markdown file in the editor. */
class MarkdownWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, widgetIds: IntArray) {
        widgetIds.forEach { MarkdownWidgets.update(context, manager, it) }
    }

    override fun onDeleted(context: Context, widgetIds: IntArray) {
        MarkdownWidgets.remove(context, widgetIds)
    }
}

/** Binds the file to a widget the user placed from the editor's "add widget" button. */
class MarkdownWidgetPinnedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val widgetId =
            intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            )
        val uri = intent.data
        val name = intent.getStringExtra(MarkdownWidgets.EXTRA_NAME)
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID || uri == null || name == null) return
        MarkdownWidgets.save(context, widgetId, uri, name)
        MarkdownWidgets.markPinned(context, widgetId)
        MarkdownWidgets.update(context, AppWidgetManager.getInstance(context), widgetId)
    }
}

/**
 * Launched by the home screen when a markdown widget is placed (or reconfigured): shows the
 * system file picker and binds the chosen file to the widget. Cancelling removes the widget.
 */
class MarkdownWidgetConfigureActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        widgetId =
            intent?.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        // Some home screens also run this right after a widget is pinned from the app, which
        // already has its file.
        if (MarkdownWidgets.consumeRecentPin(this, widgetId)) {
            finishConfigured()
            return
        }
        if (savedInstanceState == null) {
            startActivityForResult(Documents.openIntent(), REQUEST_PICK)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val uri = data?.data
        if (requestCode == REQUEST_PICK && resultCode == RESULT_OK && uri != null) {
            try {
                Documents.persist(this, uri)
                MarkdownWidgets.save(this, widgetId, uri, Documents.displayName(this, uri))
                MarkdownWidgets.update(this, AppWidgetManager.getInstance(this), widgetId)
                finishConfigured()
                return
            } catch (error: SecurityException) {
                Log.w(TAG, "no write access to $uri", error)
            }
        }
        finish()
    }

    private fun finishConfigured() {
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }

    private companion object {
        const val TAG = "MarkdownWidget"
        const val REQUEST_PICK = 1
    }
}
