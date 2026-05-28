package com.example.billing_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GestockSummaryWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val data = HomeWidgetPlugin.getData(context)
            val total = data.getString("summary_total", "— FCFA") ?: "— FCFA"
            val count = data.getString("summary_count", "0 vente") ?: "0 vente"

            val views = RemoteViews(context.packageName, R.layout.widget_summary).apply {
                setTextViewText(R.id.widget_summary_total, total)
                setTextViewText(R.id.widget_summary_count, count)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
