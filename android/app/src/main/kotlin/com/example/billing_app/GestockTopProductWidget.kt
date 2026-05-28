package com.example.billing_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GestockTopProductWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val data = HomeWidgetPlugin.getData(context)
            val name = data.getString("top_product_name", "Aucune vente") ?: "Aucune vente"
            val qty  = data.getString("top_product_qty", "—") ?: "—"

            val views = RemoteViews(context.packageName, R.layout.widget_top_product).apply {
                setTextViewText(R.id.widget_top_product_name, name)
                setTextViewText(R.id.widget_top_product_qty, qty)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
