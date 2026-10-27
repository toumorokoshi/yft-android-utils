package dev.yft.yft_android_utils

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews

/** The file each placed markdown widget opens, keyed by app widget id. */
object MarkdownWidgets {
    private const val PREFERENCES = "markdown_widgets"

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun save(context: Context, widgetId: Int, uri: Uri, name: String) {
        preferences(context)
            .edit()
            .putString("uri_$widgetId", uri.toString())
            .putString("name_$widgetId", name)
            .apply()
    }

    fun remove(context: Context, widgetIds: IntArray) {
        val editor = preferences(context).edit()
        widgetIds.forEach { editor.remove("uri_$it").remove("name_$it") }
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
                setResult(
                    RESULT_OK,
                    Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
                )
            } catch (error: SecurityException) {
                Log.w(TAG, "no write access to $uri", error)
            }
        }
        finish()
    }

    private companion object {
        const val TAG = "MarkdownWidget"
        const val REQUEST_PICK = 1
    }
}
