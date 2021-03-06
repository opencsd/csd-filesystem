local g = import 'grafonnet/grafana.libsonnet';

{
  dashboardSchema(title,
                  description,
                  uid,
                  time_from,
                  refresh,
                  schemaVersion,
                  tags,
                  timezone,
                  timepicker)::
    g.dashboard.new(title=title,
                    description=description,
                    uid=uid,
                    time_from=time_from,
                    refresh=refresh,
                    schemaVersion=schemaVersion,
                    tags=tags,
                    timezone=timezone,
                    timepicker=timepicker),

  graphPanelSchema(aliasColors,
                   title,
                   description,
                   nullPointMode,
                   stack,
                   formatY1,
                   formatY2,
                   labelY1,
                   labelY2,
                   min,
                   fill,
                   datasource,
                   legend_alignAsTable=false,
                   legend_avg=false,
                   legend_min=false,
                   legend_max=false,
                   legend_current=false,
                   legend_values=false)::
    g.graphPanel.new(aliasColors=aliasColors,
                     title=title,
                     description=description,
                     nullPointMode=nullPointMode,
                     stack=stack,
                     formatY1=formatY1,
                     formatY2=formatY2,
                     labelY1=labelY1,
                     labelY2=labelY2,
                     min=min,
                     fill=fill,
                     datasource=datasource,
                     legend_alignAsTable=legend_alignAsTable,
                     legend_avg=legend_avg,
                     legend_min=legend_min,
                     legend_max=legend_max,
                     legend_current=legend_current,
                     legend_values=legend_values),


  addTargetSchema(expr, intervalFactor, format, legendFormat)::
    g.prometheus.target(expr=expr,
                        intervalFactor=intervalFactor,
                        format=format,
                        legendFormat=legendFormat),

  addTemplateSchema(name,
                    datasource,
                    query,
                    refresh,
                    includeAll,
                    sort,
                    label,
                    regex)::
    g.template.new(name=name,
                   datasource=datasource,
                   query=query,
                   refresh=refresh,
                   includeAll=includeAll,
                   sort=sort,
                   label=label,
                   regex=regex),

  addAnnotationSchema(builtIn,
                      datasource,
                      enable,
                      hide,
                      iconColor,
                      name,
                      type)::
    g.annotation.datasource(builtIn=builtIn,
                            datasource=datasource,
                            enable=enable,
                            hide=hide,
                            iconColor=iconColor,
                            name=name,
                            type=type),

  addRowSchema(collapse, showTitle, title)::
    g.row.new(collapse=collapse, showTitle=showTitle, title=title),

  addSingleStatSchema(colors,
                      datasource,
                      format,
                      title,
                      description,
                      valueName,
                      colorValue,
                      gaugeMaxValue,
                      gaugeShow,
                      sparklineShow,
                      thresholds)::
    g.singlestat.new(colors=colors,
                     datasource=datasource,
                     format=format,
                     title=title,
                     description=description,
                     valueName=valueName,
                     colorValue=colorValue,
                     gaugeMaxValue=gaugeMaxValue,
                     gaugeShow=gaugeShow,
                     sparklineShow=sparklineShow,
                     thresholds=thresholds),

  addPieChartSchema(aliasColors,
                    datasource,
                    description,
                    legendType,
                    pieType,
                    title,
                    valueName)::
    g.pieChartPanel.new(aliasColors=aliasColors,
                        datasource=datasource,
                        description=description,
                        legendType=legendType,
                        pieType=pieType,
                        title=title,
                        valueName=valueName),

  addTableSchema(datasource, description, sort, styles, title, transform)::
    g.tablePanel.new(datasource=datasource,
                     description=description,
                     sort=sort,
                     styles=styles,
                     title=title,
                     transform=transform),

  addStyle(alias,
           colorMode,
           colors,
           dateFormat,
           decimals,
           mappingType,
           pattern,
           thresholds,
           type,
           unit,
           valueMaps)::
    {
      alias: alias,
      colorMode: colorMode,
      colors: colors,
      dateFormat: dateFormat,
      decimals: decimals,
      mappingType: mappingType,
      pattern: pattern,
      thresholds: thresholds,
      type: type,
      unit: unit,
      valueMaps: valueMaps,
    },
}
