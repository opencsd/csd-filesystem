import {
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnChanges,
  OnInit,
  Output,
  ViewChild
} from '@angular/core';

import * as Chart from 'chart.js';
import _ from 'lodash';
import { PluginServiceGlobalRegistrationAndOptions } from 'ng2-charts';

import { CssHelper } from '~/app/shared/classes/css-helper';
import { ChartTooltip } from '~/app/shared/models/chart-tooltip';
import { DimlessBinaryPipe } from '~/app/shared/pipes/dimless-binary.pipe';
import { DimlessPipe } from '~/app/shared/pipes/dimless.pipe';

@Component({
  selector: 'cd-health-pie',
  templateUrl: './health-pie.component.html',
  styleUrls: ['./health-pie.component.scss']
})
export class HealthPieComponent implements OnChanges, OnInit {
  @ViewChild('chartCanvas', { static: true })
  chartCanvasRef: ElementRef;
  @ViewChild('chartTooltip', { static: true })
  chartTooltipRef: ElementRef;

  @Input()
  data: any;
  @Input()
  config = {};
  @Input()
  isBytesData = false;
  @Input()
  tooltipFn: any;
  @Input()
  showLabelAsTooltip = false;
  @Output()
  prepareFn = new EventEmitter();

  chartConfig: any = {
    chartType: 'doughnut',
    dataset: [
      {
        label: null,
        borderWidth: 0
      }
    ],
    colors: [
      {
        backgroundColor: [
          this.cssHelper.propertyValue('chart-color-green'),
          this.cssHelper.propertyValue('chart-color-yellow'),
          this.cssHelper.propertyValue('chart-color-orange'),
          this.cssHelper.propertyValue('chart-color-red'),
          this.cssHelper.propertyValue('chart-color-blue')
        ]
      }
    ],
    options: {
      cutoutPercentage: 90,
      events: ['click', 'mouseout', 'touchstart'],
      legend: {
        display: true,
        position: 'right',
        labels: {
          boxWidth: 10,
          usePointStyle: false
        }
      },
      plugins: {
        center_text: true
      },
      tooltips: {
        enabled: true,
        displayColors: false,
        backgroundColor: this.cssHelper.propertyValue('chart-color-tooltip-background'),
        cornerRadius: 0,
        bodyFontSize: 14,
        bodyFontStyle: '600',
        position: 'nearest',
        xPadding: 12,
        yPadding: 12,
        callbacks: {
          label: (item: Record<string, any>, data: Record<string, any>) => {
            let text = data.labels[item.index];
            if (!text.includes('%')) {
              text = `${text} (${data.datasets[item.datasetIndex].data[item.index]}%)`;
            }
            return text;
          }
        }
      },
      title: {
        display: false
      }
    }
  };

  public doughnutChartPlugins: PluginServiceGlobalRegistrationAndOptions[] = [
    {
      id: 'center_text',
      beforeDraw(chart: Chart) {
        const cssHelper = new CssHelper();
        const defaultFontFamily = 'Helvetica Neue, Helvetica, Arial, sans-serif';
        Chart.defaults.global.defaultFontFamily = defaultFontFamily;
        const ctx = chart.ctx;
        if (!chart.options.plugins.center_text || !chart.data.datasets[0].label) {
          return;
        }

        ctx.save();
        const label = chart.data.datasets[0].label.split('\n');

        const centerX = (chart.chartArea.left + chart.chartArea.right) / 2;
        const centerY = (chart.chartArea.top + chart.chartArea.bottom) / 2;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';

        ctx.font = `24px ${defaultFontFamily}`;
        ctx.fillStyle = cssHelper.propertyValue('chart-color-center-text');
        ctx.fillText(label[0], centerX, centerY - 10);

        if (label.length > 1) {
          ctx.font = `14px ${defaultFontFamily}`;
          ctx.fillStyle = cssHelper.propertyValue('chart-color-center-text-description');
          ctx.fillText(label[1], centerX, centerY + 10);
        }
        ctx.restore();
      }
    }
  ];

  constructor(
    private dimlessBinary: DimlessBinaryPipe,
    private dimless: DimlessPipe,
    private cssHelper: CssHelper
  ) {}

  ngOnInit() {
    const getStyleTop = (tooltip: any, positionY: number) => {
      return positionY + tooltip.caretY - tooltip.height - 10 + 'px';
    };

    const getStyleLeft = (tooltip: any, positionX: number) => {
      return positionX + tooltip.caretX + 'px';
    };

    const chartTooltip = new ChartTooltip(
      this.chartCanvasRef,
      this.chartTooltipRef,
      getStyleLeft,
      getStyleTop
    );

    chartTooltip.getBody = (body: any) => {
      return this.getChartTooltipBody(body);
    };

    _.merge(this.chartConfig, this.config);

    this.prepareFn.emit([this.chartConfig, this.data]);
  }

  ngOnChanges() {
    this.prepareFn.emit([this.chartConfig, this.data]);
    this.setChartSliceBorderWidth();
  }

  private getChartTooltipBody(body: string[]) {
    const bodySplit = body[0].split(': ');

    if (this.showLabelAsTooltip) {
      return bodySplit[0];
    }

    bodySplit[1] = this.isBytesData
      ? this.dimlessBinary.transform(bodySplit[1])
      : this.dimless.transform(bodySplit[1]);

    return bodySplit.join(': ');
  }

  private setChartSliceBorderWidth() {
    let nonZeroValueSlices = 0;
    _.forEach(this.chartConfig.dataset[0].data, function (slice) {
      if (slice > 0) {
        nonZeroValueSlices += 1;
      }
    });

    this.chartConfig.dataset[0].borderWidth = nonZeroValueSlices > 1 ? 1 : 0;
  }
}
