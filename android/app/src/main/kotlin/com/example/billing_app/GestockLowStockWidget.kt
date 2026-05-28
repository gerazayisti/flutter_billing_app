package com.example.billing_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GestockLowStockWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val data = HomeWidgetPlugin.getData(context)
            val count = data.getString("low_stock_count", "0") ?: "0"
            val label = data.getString("low_stock_label", "Stock OK") ?: "Stock OK"

            val views = RemoteViews(context.packageName, R.layout.widget_low_stock).apply {
                setTextViewText(R.id.widget_low_stock_count, count)
                setTextViewText(R.id.widget_low_stock_sublabel, label)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
