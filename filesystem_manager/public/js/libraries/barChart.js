/** Chart Legend **/
var barChartLegend = function(data,config)
{
	// chart color
	var color = d3.scale.ordinal().range(config.colors);

	var svgEl = d3.select('#' + config.chartId + ' svg');
	var legendWrap = svgEl.append("g").attr("class", "legendWrap")

	// legend position
	if (config.legend.position == 'top')
	{
		legendWrap.attr(
			"transform",
			"translate(" + (config.margin.left - 5) + ", 0)"
		);
	}
	else
	{
		legendWrap.attr(
			"transform",
			"translate("
				+ config.margin.left + ", "
				+ (config.height - config.margin.bottom + 25)
			+ ")"
		);
	}

	var legend = legendWrap.selectAll(".legend")
							.data(data)
							.enter().append("g")
							.attr("class", "legend");

	var legendShape;

	if (config.legend.shape == 'circle')
	{
		legendShape = legend.append("circle")
								.attr("cx", 5)
								.attr("cy", 10)
								.attr("r", 6);
	}
	else
	{
		legendShape = legend.append("rect")
								.attr("x", 0)
								.attr("y", 3)
								.attr("rx", 2)
								.attr("ry", 2)
								.attr("width", 12)
								.attr("height", 12);
	}

	legendShape
		.style("stroke", function (d) { return color(d); })
		.style("fill", function (d) { return color(d); });

	legend
		.append("text")
		.attr("x", 18)
		.attr("y", 8)
		.attr("dy", ".35em")
		.style("text-anchor", "start")
		.text(function (d) { return d; });

	var dataH=0

	legend.attr(
		'transform',
		function (d, i) {
			// 글자의 크기에 따라 간격을 설정한다.
			var offset = d3.select(this).select('text').node().getComputedTextLength() + 28;

			if (i === 0)
			{
				dataL = d.length + offset
				return "translate(0, 0)" // 첫번째 범례 위치
			}
			else
			{
				var newdataL = dataL

				dataL +=  d.length + offset;

				// 범례의 표시 위치가 캔버스의 크기를 벗어나면 줄바꿔주기를 하여 위치를 지정한다.
				if (dataL >= config.width)
				{
					newdataL=0;
					dataL = d.length + offset;
					dataH += 20;
				}

				return "translate(" + (newdataL) + ", " + (dataH) + ")"
			}
		}
	);
}

/** bar chat X축 레이블 글자 개수 처리 */
function wrap (text, width)
{
	text.each(
		function() {
			var text = d3.select(this),
				words = text.text().split(/\s+/).reverse(),
				word,
				result,
				wordLength,
				y = text.attr("y"),
				dy = parseFloat(text.attr("dy")),
				tspan = text.text(null).append("tspan")
						.attr("x", 0)
						.attr("y", y)
						.attr("dy", dy + "em");

			word = words.pop();
			tspan.text(word);

			if (tspan.node().getComputedTextLength() > width)
			{
				result = tspan.node().getComputedTextLength() / width;
				wordLength = word.length/result;

				if (wordLength > 3)
				{
					word = word.substr(0, wordLength - 2) + '...';
				}
				else
				{
					word = word.substr(0, 1) + '...';
				}

				tspan = tspan.attr("x", 0).attr("y", y).text(word);
			}
		}
	);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* single/multi bar chart */
function barChart (config)
{
	// 차트 기본값 설정
	config = initConfig(config);

	// 캔버스와 그래프영역 크기 설정
	var margin = config.margin,
		width = config.width - margin.left - margin.right,
		height = config.height - margin.top - margin.bottom;

	/* 눈금 표시를 위한 scale 설정 */
	// X축
	var x0Scale = d3.scale.ordinal().rangeRoundBands([0, width], config.barSpace);
	var x1Scale = d3.scale.ordinal();
	var xAxis = d3.svg.axis().scale(x0Scale).orient("bottom");

	// x축 포맷 지정
	/*if (config.x.tickformat!= '')
	{
		xAxis.tickFormat(d3.time.format(config.x.tickformat));
	}*/

	// x축 그리드
	if (config.x.grid === true)
	{
		xAxis.tickSize(-height, 0, 0) // x축 눈금 표시
	}

	// Y축
	var yScale = d3.scale.linear().range([height, 0]);
	var yAxis = d3.svg.axis().scale(yScale).orient("left");
	var yFormatData;

	if (typeof(config.y.tickformat) != 'undefined')
	{
		yAxis.tickFormat(d3.format(config.y.tickformat));

		var yFormatDataValue = d3.format(config.y.tickformat);
		yFormatData = function (d) { return yFormatDataValue(d); };
	}
	else
	{
		yFormatData = function (d) { return d.toFixed(2); };
	}

	// y축 그리드
	if (config.y.grid===true)
	{
		yAxis.tickSize(-width, 0, 0) // y축 눈금 표시
	}

	// tooltip data Format
	var tooltipFormatData;

	if (typeof(config.tooltip.format)!= 'undefined')
	{
		//var formatDataValue = d3.format(config.tooltip.format);
		var formatDataValue = function (d) {
			return bytesToString(config.tooltip.format, d);
		};

		tooltipFormatData = function (d) {
			return formatDataValue(d);
		};
	}
	else
	{
		tooltipFormatData = function (d) {
			return yFormatData(d);
		};
	}

	// chart color
	var color = d3.scale.ordinal().range(config.colors);

	// svgEl Object
	var svgEl = d3.select('#' + config.chartId).append("svg")
		.attr("width", config.width)
		.attr("height", config.height)
		.append("g")
		.attr(
			"transform",
			"translate(" + margin.left + ", " + margin.top + ")"
		);

	var infoBox = d3.select('#' + config.chartId)
		.append("div")
		.attr("class", "infoBox")
		.style("display", "none");

	var self = this;

	this.getData = function () {
		d3.json(
			config.dataSrc,
			function (error, data) {

				if (error)
					throw error;

				// 차트 그리기
				self.drawChart(data);
			}
		);
	}

	var dataSet = []; // global dataset

	// 초기화 차트 그리기
	this.drawChart = function (data) {
		// global data copy
		dataSet = data.slice();

		var labelNames = d3.keys(data[0]).filter(
			function (key) {
				return (key !== "key" && key !== "lableValues");
			}
		);

		// 지정 color보다 많은 label이 들어오면 glueColor(40가지색)로 color
		// range를 변경한다.
		if (color.range().length< labelNames.length)
		{
			config.colors = colorData.glueColor;
			color.range(config.colors);
		}

		data.forEach(
			function (d) {
				d.lableValues = labelNames.map(
					function (name) {
						return {
							name: name,
							value: +d[name]
						};
					}
				);
			}
		);

		// X,Y 축 그리기
		x0Scale.domain(data.map(function (d) { return d.key; }));
		x1Scale.domain(labelNames).rangeRoundBands([0, x0Scale.rangeBand()]);
		yScale.domain(
			[
				0,
				d3.max(
					data,
					function (d) {
						return d3.max(
							d.lableValues,
							function (d) { return d.value; }
						);
					}
				)
			]
		);

		svgEl.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0, " + height + ")")
			.call(xAxis)
			.append("text")
			.attr("x", width/2)
			.attr("dy", "2.5em")
			.style("text-anchor", "middle")
			.text(config.x.label);

		svgEl.append("g")
			.attr("class", "y axis")
			.call(yAxis)
			.append("text")
			.attr("transform", "rotate(-90)")
			.attr("x", -(height/2))
			.attr("dy", "-3.5em")
			.style("text-anchor", "middle")
			.text(config.y.label);

		var key = svgEl.selectAll(".key")
			.data(data)
			.enter().append("g")
			.attr("class", "key")
			.attr(
				"transform",
				function (d) {
					return "translate(" + x0Scale(d.key) + ", 0)";
				}
			);

		var chartBar = key.selectAll("rect")
			.data(function (d) { return d.lableValues; })
			.enter().append("rect")
			.attr("width", x1Scale.rangeBand())
			.attr("x", function (d) { return x1Scale(d.name); })
			.attr("y", function (d) { return yScale(d.value); })
			.attr("height", function (d) { return height - yScale(d.value); })
			.style("fill", function (d) { return color(d.name); });

		if (config.showValues===true)
		{
			var text = key.selectAll("text")
				.data(function (d) { return d.lableValues; })
				.enter().append("text")
				.text(function (d) { return tooltipFormatData(d.value); })
				.attr("x", function (d) { return x1Scale(d.name); })
				.attr("y", function (d) { return yScale(d.value) + 20; })
				.attr("class", 'barValue');
		}

		/* 메인 그래프 legend(범례) */
		if (config.legend.show == true)
			barChartLegend(labelNames,config);

		/* Tooltip */
		if (config.tooltip.show === true)
		{
			// 마우스 움직임에 따라 안내선 표시
			chartBar
				.on(
					"mousemove",
					function (d)
					{
						d3.select(this)
							.style("stroke", color(d.name))
							.style("stroke-width", "4px");

						var winMousePos = d3.mouse(document.getElementById(config.chartId));
						var xPosition = winMousePos[0]+10;
						var yPosition = winMousePos[1];
						var textColor = color(d.name);

						var infoHtml
							= "<div class='label' style='color: " + textColor
							+ "'>" + d.name + "</div>";

						infoHtml += "<div>" + tooltipFormatData(d.value) + "</div>";

						infoBox.style("display", null);

						var posX = winMousePos[0] + 20;
						var posY = winMousePos[1] - 10;

						// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
						if (config.width - posX < infoBox[0][0].clientWidth)
							posX = posX - infoBox[0][0].clientWidth - 40;

						// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
						if (config.height - posY < infoBox[0][0].clientHeight)
							posY = posY - infoBox[0][0].clientHeight;

						infoBox.style("left", posX + "px")
							.style("top", posY + "px")
							.style("display", null)
							.html(infoHtml);
					}
				)
				.on(
					"mouseout",
					function (d) {
						d3.select(this).style("stroke", "none");
						infoBox.style("display", "none");
					}
				);
		}
	};

	/* 차트 크기 변경 */
	this.resize = function (newConf) {
		config.width = newConf.width;

		/* 차트 Margin 설정 */
		if (typeof(newConf.margin) != 'undefined')
		{
			if (typeof(newConf.margin.top) != 'undefined')
				config.margin.top = newConf.margin.top;

			if (typeof(newConf.margin.right) != 'undefined')
				config.margin.right = newConf.margin.right;

			if (typeof(newConf.margin.bottom) != 'undefined')
				config.margin.bottom = newConf.margin.bottom;

			if (typeof(newConf.margin.left) != 'undefined')
				config.margin.left = newConf.margin.left;

			margin = config.margin;
		}

		/* bar chart 간격 설정 */
		if (typeof(newConf.barSpace) != 'undefined')
			config.barSpace = newConf.barSpace;

		width = config.width - margin.left - margin.right;

		// resize xScale
		x0Scale.rangeRoundBands([0, width], config.barSpace);

		// y축 그리드
		if (config.y.grid===true)
		{
			// y축 눈금 표시
			yAxis.tickSize(-width, 0, 0);
		}

		// 차트 다시 그리기
		var chart = d3.select('#' + config.chartId);

		chart.select('svg').remove();

		svgEl = chart.append("svg")
			.attr("width", config.width)
			.attr("height", config.height)
			.append("g")
			.attr(
				"transform",
				"translate(" + margin.left + ", " + margin.top + ")"
			);

		self.drawChart(dataSet);
	};
}

/* Stacked bar chart */
function stackedBarChart (config)
{
	// 차트 기본값 설정
	config = initConfig(config);

	// 캔버스와 그래프영역 크기 설정
	var margin = config.margin,
		width = config.width - margin.left - margin.right,
		height = config.height - margin.top - margin.bottom;

	/* 눈금 표시를 위한 scale 설정 */
	// X축
	var xScale = d3.scale.ordinal().rangeRoundBands([0, width], config.barSpace);
	var xAxis = d3.svg.axis().scale(xScale).orient("bottom");

	// x축 그리드
	if (config.x.grid === true)
	{
		// X축 눈금 표시
		xAxis.tickSize(-height, 0, 0);
	}

	// Y축
	var yScale = d3.scale.linear().range([height, 0]);
	var yAxis = d3.svg.axis().scale(yScale).orient("left");

	// Y축 데이터 포멧
	var yFormatData;

	if (typeof(config.y.tickformat) != 'undefined')
	{
		yAxis.tickFormat(d3.format(config.y.tickformat));

		var yFormatDataValue = d3.format(config.y.tickformat);

		yFormatData = function (d) { return yFormatDataValue(d); };
	}
	else
	{
		yFormatData = function (d) { return d; };
	}

	// Y축 그리드
	if (config.y.grid === true)
	{
		// Y축 눈금 표시
		yAxis.tickSize(-width, 0, 0)
	}

	// tooltip data Format
	var tooltipFormatData;

	if (typeof(config.tooltip.format) != 'undefined')
	{
		//var formatDataValue = d3.format(config.tooltip.format);
		var formatDataValue = function (d) {
			return bytesToString(config.tooltip.format, d);
		};

		tooltipFormatData = function (d) {
			return formatDataValue(d);
		};
	}
	else
	{
		tooltipFormatData = function (d) {
			return yFormatData(d);
		};
	}

	// bar color
	var color = d3.scale.ordinal().range(config.colors);

	// svgEl Object
	var svgEl = d3.select('#' + config.chartId)
		.append("svg")
		.attr("width", config.width)
		.attr("height", config.height)
		.append("g")
		.attr(
			"transform",
			"translate(" + margin.left + ", " + margin.top + ")"
		);

	// Tooltip info box Object
	var infoBox = d3.select('#' + config.chartId)
		.append("div")
		.attr("class", "infoBox")
		.style("display", "none");

	var self = this;

	/* 파일에서 직접 데이터 가져 오기 */
	this.getData = function () {
		d3.json(
			config.dataSrc,
			function (error, data) {

				if (error)
					throw error;

				// 차트 그리기
				self.drawChart(data);
			}
		);
	}

	this.drawChart = function (data) {
		if (typeof(config.y.tickformat) != 'undefined'
			&& config.y.tickformat == '%')
		{
			self.drawPercentChart(data);
		}
		else
		{
			self.drawStackedChart(data);
		}
	}

	// 퍼센트 차트 그리기
	this.drawPercentChart = function (data) {
		dataSet = data.slice(); // global data copy

		// data의 lable 추출
		var labelNames = d3.keys(data[0]).filter(
			function (key) {
				return (key !== "key" && key !== "lableValues");
			}
		);

		// 지정 color보다 많은 label이 들어오면 glueColor(40가지색)로 color
		// range를 변경한다.
		if (color.range().length < labelNames.length)
		{
			config.colors = colorData.glueColor;
			color.range(config.colors);
		}

		// lable에 따라 차트 컬러 지정
		color.domain(labelNames);

		// bar chart용 데이터 가공
		data.forEach(
			function (d) {
				var y0 = 0;

				d.lableValues = color.domain().map(
					function (name) {
						return {
							barname: d.key,
							name: name,
							y0: y0,
							y1: y0 += +d[name],
							value: +d[name]
						};
					}
				);

				d.lableValues.forEach(
					function (d) {
						d.y0 /= y0;
						d.y1 /= y0;
					}
				);
			}
		);

		// X, Y 축 그리기
		xScale.domain(data.map(function (d) { return d.key; }));

		svgEl.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0, " + height + ")")
			.call(xAxis)
			.append("text")
			.attr("x", width / 2)
			.attr("dy", "2.5em")
			.style("text-anchor", "middle")
			.text(config.x.label);

		svgEl.selectAll(".tick text").call(wrap, xScale.rangeBand());

		// 마우스 움직임에 따라 안내선 표시
		svgEl.selectAll(".tick text")
			.on(
				"mousemove",
				function (d) {
					d3.select(this).style("font-weight", "bold");

					var winMousePos = d3.mouse(document.getElementById(config.chartId));
					var posX = winMousePos[0] + 20;
					var posY = winMousePos[1] - 10;

					var infoHtml = "<div>" + d + "</div>";

					infoBox.style("display", null);

					// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
					if (config.width - posX < infoBox[0][0].clientWidth)
						posX = posX - infoBox[0][0].clientWidth - 40;

					// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
					if (config.height - posY < infoBox[0][0].clientHeight)
						posY = posY - infoBox[0][0].clientHeight;

					infoBox.style("left", posX + "px")
						.style("top", posY + "px")
						.style("display", null)
						.html(infoHtml);
				}
			)
			.on(
				"mouseout",
				function (d) {
					d3.select(this).style("font-weight", "normal");
					infoBox.style("display", "none");
				}
			);

		svgEl.append("g")
				.attr("class", "y axis")
				.call(yAxis)
				.append("text")
				.attr("transform", "rotate(-90)")
				.attr("x", -(height / 2))
				.attr("dy", "-3.5em")
				.style("text-anchor", "middle")
				.text(config.y.label);

		// 차트 그리기
		var layer = svgEl.selectAll(".layer")
			.data(data)
			.enter().append("g")
			.attr("class", "layer")
			.attr(
				"transform",
				function (d) {
					return "translate(" + xScale(d.key) + ", 0)";
				}
			);

		var chartBar = layer.selectAll("rect")
			.data(function (d) { return d.lableValues; })
			.enter();

		var chartEachBar = chartBar.append("rect")
			.attr("width", xScale.rangeBand())
			.attr("y", function (d) { return yScale(d.y1); })
			.attr("height", function (d) { return yScale(d.y0) - yScale(d.y1); })
			.style("fill", function (d) { return color(d.name); });

		if (config.showValues === true)
		{
			chartBar.append("text")
				.text(
					function (d) {
						return ((d.y1 - d.y0) * 100).toFixed(1) + "%";
					}
				)
				.attr(
					"y",
					function (d) {
						return yScale(d.y1) + (yScale(d.y0) - yScale(d.y1)) / 2;
					}
				)
				.attr("x", xScale.rangeBand() / 3)
				.attr("class", 'barValue');
		}

		/* 메인 그래프 legend(범례) */
		if (config.legend.show == true)
			barChartLegend(labelNames,config);

		/* Tooltip */
		if (config.tooltip.show === true)
		{
			// 마우스 움직임에 따라 안내선 표시
			chartEachBar.on(
				"mousemove",
				function (d) {
					var selectdColor = color(d.name);

					d3.select(this)
						.style("stroke", selectdColor)
						.style("stroke-width", "2px");

					var winMousePos = d3.mouse(document.getElementById(config.chartId));
					var xPosition = winMousePos[0] + 10;
					var yPosition = winMousePos[1];

					if (typeof(config.tooltip.format) == 'undefined')
					{
						var elements = document.querySelectorAll(':hover');

						l = elements.length
						l = l-1

						element = elements[l].__data__
						value = ((element.y1 - element.y0) * 100).toFixed(1);
						value += '%';
					}
					else
					{
						value = tooltipFormatData(d.value);
					}

					var infoHtml = "<div class='label' style='color:" + selectdColor + "'>"
						+ d.barname + ":" + d.name
						+ "</div>";

					infoHtml += "<div>" + value + "</div>";

					infoBox.style("display", null);

					var posX = winMousePos[0] + 20;
					var posY = winMousePos[1] - 10;

					// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
					if (config.width - posX < infoBox[0][0].clientWidth)
						posX = posX - infoBox[0][0].clientWidth - 40;

					// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
					if (config.height - posY < infoBox[0][0].clientHeight)
						posY = posY - infoBox[0][0].clientHeight;

					infoBox.style("left", posX + "px")
						.style("top", posY + "px")
						.style("display", null)
						.html(infoHtml);
				}
			);

			chartEachBar.on(
				"mouseout",
				function (d) {
					d3.select(this).style("stroke", "none");
					infoBox.style("display", "none");
				}
			);
		}
	}

	// 일반 Stacked Chart 그리기
	this.drawStackedChart = function (data) {
		// global data copy
		dataSet = data.slice();

		var labelNames = d3.keys(data[0]).filter(
			function (key) {
				return (key !== "key" && key !== "lableValues");
			}
		);

		// 지정 color보다 많은 label이 들어오면 glueColor(40가지색)로 color
		// range를 변경한다.
		if (color.range().length< labelNames.length)
		{
			config.colors = colorData.glueColor;
			color.range(config.colors);
		}

		var layers = d3.layout.stack()(
			labelNames.map(
				function (name) {
					return data.map(
						function (d) {
							return {
								x: d.key,
								y: d[name],
								name: name,
								value: +d[name]
							};
						}
					);
				}
			)
		);

		// X,Y 축 그리기
		xScale.domain(layers[0].map(function (d) { return d.x; }));
		yScale.domain(
			[
				0,
				d3.max(
					layers[layers.length - 1],
					function (d) { return d.y0 + d.y; }
				)
			]
		).nice();

		svgEl.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0, " + height + ")")
			.call(xAxis)
			.append("text")
			.attr("x", width / 2)
			.attr("dy", "2.5em")
			.style("text-anchor", "middle")
			.text(config.x.label);

		svgEl.append("g")
			.attr("class", "y axis")
			.call(yAxis)
			.append("text")
			.attr("transform", "rotate(-90)")
			.attr("x", -(height / 2))
			.attr("dy", "-4em")
			.style("text-anchor", "middle")
			.text(config.y.label);

		// bar 그래프 그리기
		var layer = svgEl.selectAll(".layer")
			.data(layers)
			.enter().append("g")
			.attr("class", "layer")
			.style("fill", function (d, i) { return color(i); });

		var chartBar = layer.selectAll("rect")
			.data(function (d) { return d; })
			.enter();

		var chartEachBar = chartBar.append("rect")
			.attr("x", function (d) { return xScale(d.x); })
			.attr("y", function (d) { return yScale(d.y + d.y0); })
			.attr("height", function (d) { return yScale(d.y0) - yScale(d.y + d.y0); })
			.attr("width", xScale.rangeBand() - 1);

		if (config.showValues===true)
		{
			chartBar.append("text")
				.text(function (d) { return yFormatData(d.y); })
				.attr("y", function (d) { return  yScale(d.y0) - 2; })
				.attr("x", function (d) { return xScale.rangeBand() / 3 + xScale(d.x);})
				.attr("class", 'barValue');
		}

		/* 메인그래프 legend(범례) */
		if (config.legend.show == true)
			barChartLegend(labelNames,config);

		/* Tooltip */
		if (config.tooltip.show === true)
		{
			// 마우스 움직임에 따라 안내선 표시
			chartEachBar.on(
				"mousemove",
				function (d) {
					var lineColor = d3.select(this).style("fill");

					d3.select(this)
						.style("stroke", lineColor)
						.style("stroke-width", "2px");

					var winMousePos = d3.mouse(document.getElementById(config.chartId));
					var xPosition = winMousePos[0] + 10;
					var yPosition = winMousePos[1];

					value = tooltipFormatData(d.value);

					var infoHtml ="<div class='label' style='color:" + lineColor + "'>"
						+ d.name
						+ "</div>";

					infoHtml += "<div>" + value + "</div>";

					infoBox.style("display", null);

					var posX = winMousePos[0] + 20;
					var posY = winMousePos[1] - 10;

					// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
					if (config.width - posX < infoBox[0][0].clientWidth)
						posX = posX - infoBox[0][0].clientWidth - 40;

					// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
					if (config.height - posY < infoBox[0][0].clientHeight)
						posY = posY - infoBox[0][0].clientHeight;

					infoBox.style("left", posX + "px")
						.style("top", posY + "px")
						.style("display", null)
						.html(infoHtml);
				}
			);

			chartEachBar.on(
				"mouseout",
				function (d) {
					d3.select(this).style("stroke", "none");
					infoBox.style("display", "none");
				}
			);
		}
	}

	/* 차트 크기 변경 */
	this.resize = function (newConf) {
		config.width = newConf.width;

		/* 차트 Margin 설정 */
		if (typeof(newConf.margin) != 'undefined')
		{
			if (typeof(newConf.margin.top) != 'undefined')
				config.margin.top = newConf.margin.top;

			if (typeof(newConf.margin.right) != 'undefined')
				config.margin.right = newConf.margin.right;

			if (typeof(newConf.margin.bottom) != 'undefined')
				config.margin.bottom = newConf.margin.bottom;

			if (typeof(newConf.margin.left) != 'undefined')
				config.margin.left = newConf.margin.left;

			margin = config.margin;
		}

		/* bar chart 간격 설정 */
		if (typeof(newConf.barSpace) != 'undefined')
			config.barSpace = newConf.barSpace;

		width = config.width - margin.left - margin.right;

		// resize xScale
		xScale.rangeRoundBands([0, width], config.barSpace);

		// Y축 그리드
		if (config.y.grid===true)
		{
			// Y축 눈금 표시
			yAxis.tickSize(-width, 0, 0)
		}

		// 차트 다시 그리기
		var chart = d3.select('#' + config.chartId);

		chart.select('svg').remove();

		svgEl = chart.append("svg")
			.attr("width", config.width)
			.attr("height", config.height)
			.append("g")
			.attr(
				"transform",
				"translate(" + margin.left + ", " + margin.top + ")"
			);

		// 차트 그리기
		self.drawChart(dataSet);
	}
}

/* Multi Scale Bar Chart */
function dualScaleBarChart (config)
{
	// 차트 기본값 설정
	config = initConfig(config);

	/* Y축 기본값 설정 */
	if (typeof(config.leftY) == 'undefined')
		config.leftY = { label: '' };

	if (typeof(config.rightY) == 'undefined')
		config.rightY = { label: '' };

	// 캔버스와 그래프영역 크기 설정
	var margin = config.margin,
		width = config.width - margin.left - margin.right,
		height = config.height - margin.top - margin.bottom;

	/* 눈금 표시를 위한 scale 설정 */
	// X축
	var xScale = d3.scale.ordinal().rangeRoundBands([0, width], config.barSpace);
	var xAxis = d3.svg.axis().scale(xScale).orient("bottom");

	// X축 포맷 지정
	/*if (config.x.tickformat!= '')
	{
		xAxis.tickFormat(d3.time.format(config.x.tickformat));
	}*/

	// X축 그리드
	if (config.x.grid===true)
	{
		// X축 눈금 표시
		xAxis.tickSize(-height, 0, 0);
	}

	// Left Y축
	var leftYScale = d3.scale.linear().range([height, 0]);
	var leftYAxis = d3.svg.axis().scale(leftYScale).orient("left");
	var leftYFormatData;

	if (typeof(config.leftY.tickformat) != 'undefined')
	{
		leftYAxis.tickFormat(d3.format(config.leftY.tickformat));

		var leftYFormatDataValue = d3.format(config.leftY.tickformat);

		leftYFormatData = function (d) {
			return leftYFormatDataValue(d);
		};
	}
	else
	{
		leftYFormatData = function (d) { return d; };
	}

	// Left tooltip data Format
	var leftTooltipFormatData;

	if (typeof(config.leftY.toolTipformat) != 'undefined')
	{
		//var leftFormatDataValue = d3.format(config.leftY.toolTipformat);
		var leftFormatDataValue = function (d) {
			return bytesToString(config.leftY.toolTipformat, d);
		};

		leftTooltipFormatData = function (d) {
			return leftFormatDataValue(d);
		};
	}
	else
	{
		leftTooltipFormatData = function (d) {
			return leftYFormatData(d);
		};
	}

	// Right Y축========================================
	var rightYScale = d3.scale.linear().range([height, 0]);
	var rightYAxis = d3.svg.axis().scale(rightYScale).orient("right");

	// Y축 간격 지정
	if (typeof(config.rightY.ticks) != 'undefined')
	{
		rightYAxis.ticks(config.rightY.ticks);
	}

	var rightYFormatData;

	if (typeof(config.rightY.tickformat) != 'undefined')
	{
		rightYAxis.tickFormat(d3.format(config.rightY.tickformat));

		var rightYFormatDataValue = d3.format(config.rightY.tickformat);

		rightYFormatData = function (d) {
			return rightYFormatDataValue(d);
		};
	}
	else
	{
		rightYFormatData = function (d) { return d; };
	}

	// Right tooltip data Format
	var rightTooltipFormatData;

	if (typeof(config.rightY.toolTipformat) != 'undefined')
	{
		//var rightFormatDataValue = d3.format(config.rightY.toolTipformat);
		var rightFormatDataValue = function (d) {
			return bytesToString(config.rightY.toolTipformat, d);
		};

		rightTooltipFormatData = function (d) {
			return rightFormatDataValue(d);
		};
	}
	else
	{
		rightTooltipFormatData = function (d) {
			return rightYFormatData(d);
		};
	}

	// bar color
	var color = d3.scale.ordinal().range(config.colors);

	// svgEl Object
	var svgEl = d3.select('#' + config.chartId).append("svg")
		.attr("width", config.width)
		.attr("height", config.height)
		.append("g")
		.attr(
			"transform",
			"translate(" + margin.left + ", " + margin.top + ")"
		);

	var infoBox = d3.select('#' + config.chartId)
		.append("div")
		.attr("class", "infoBox")
		.style("display", "none");

	var self = this;

	this.getData = function () {
		d3.json(
			config.dataSrc,
			function (error, data) {

				if (error)
					throw error;

				// 차트 그리기
				self.drawChart(data);
			}
		);
	}

	var dataSet = [];

	// 초기화 차트 그리기
	this.drawChart = function (data) {
		dataSet = data.slice();

		var labelNames = d3.keys(data[0]).filter(
			function (key) { return key !== "key"; }
		);

		// 지정 color보다 많은 label이 들어오면 glueColor(40가지색)로 color
		// range를 변경한다.
		if (color.range().length < labelNames.length)
		{
			config.colors = colorData.glueColor;
			color.range(config.colors);
		}

		// lable에 따라 차트 컬러 지정
		color.domain(labelNames);

		var leftData = [], rightData = [];

		data.forEach(
			function (d, i) {
				labelNames.map(
					function (name) {
						if (name == labelNames[0])
						{
							leftData.push({ name: d.key, value: d[name] });
						}
						else
						{
							rightData.push({ name: d.key, value: d[name] });
						}
					}
				);
			}
		);

		// X축 그리기
		xScale.domain(data.map(function (d) { return d.key; }));

		svgEl.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0, " + height + ")")
			.call(xAxis)
			.append("text")
			.attr("x", width-margin.right)
			.attr("y", 30)
			.attr("dx", ".71em")
			.style("text-anchor", "middle")
			.style("white-space", "pre");
			//.text(config.x.label);

		svgEl.selectAll(".tick text").call(wrap, xScale.rangeBand());

		// 마우스 움직임에 따라 안내선 표시
		svgEl.selectAll(".tick text")
			.on(
				"mousemove",
				function (d) {
					d3.select(this).style("font-weight", "bold");

					var winMousePos = d3.mouse(document.getElementById(config.chartId));
					var posX = winMousePos[0] + 20;
					var posY = winMousePos[1] - 10;

					var infoHtml = "<div>" + d + "</div>";

					infoBox.style("display", null);

					// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
					if (config.width - posX < infoBox[0][0].clientWidth)
						posX = posX - infoBox[0][0].clientWidth - 40;

					// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
					if (config.height - posY < infoBox[0][0].clientHeight)
						posY = posY - infoBox[0][0].clientHeight;

					infoBox.style("left", posX + "px")
						.style("top", posY + "px")
						.style("display", null)
						.html(infoHtml);
				}
			)
			.on(
				"mouseout",
				function (d) {
					d3.select(this).style("font-weight", "normal");
					infoBox.style("display", "none");
				}
			);

		// Left Y축 그리기
		var leftYMax = d3.max(leftData, function (d) { return d.value; });

		if (leftYMax < 10)
		{
			leftYMax = 10;
		}
		else
		{
			leftYMax = parseInt(leftYMax + ((leftYMax / 100) * 20));
		}

		leftYScale.domain([0, leftYMax]);
		svgEl.append("g")
			.attr("class", "y axis axisLeft")
			.attr("transform", "translate(0, 0)")
			.style("fill", color(labelNames[0]))
			.call(leftYAxis)
			.append("text")
			.attr("transform", "rotate(-90)")
			.attr("x", -(height / 2))
			.attr("dy", "-4em")
			.style("text-anchor", "middle")
			.style("fill", color(labelNames[0]))
			.text(labelNames[0]);

		// right Y축 값 설정
		//var maxRightYData = (d3.max(rightData, function(c) { return d3.max(c.values, function(v) { return v.indexValue; }); }));
		var maxRightYData = d3.max(rightData, function (d) { return d.value; });

		if (maxRightYData < 1024 * 1024 * 10)
		{
			maxRightYData = 1024 * 1024 * 10;
		}
		else
		{
			// 최대값 보다 20% 더 여유있게 출력
			var maxRightYDataAdd = (maxRightYData / 100) * 20;
			maxRightYData = maxRightYData + maxRightYDataAdd;
		}

		maxRightYData = parseInt(maxRightYData);

		// Right Y축 그리기
		rightYScale.domain([0, maxRightYData]);

		svgEl.append("g")
			.attr("class", "y axis axisRight")
			.attr("transform", "translate(" + (width) + ", 0)")
			.style("fill", color(labelNames[1]))
			.call(rightYAxis)
			.append("text")
			.attr("transform", "rotate(90)")
			.attr("x", (height / 2))
			.attr("dy", "-4em")
			.style("text-anchor", "middle")
			.style("fill", color(labelNames[1]))
			.text(labelNames[1]);

		// bar chart 그리기
		leftBars = svgEl.selectAll(".leftBar").data(leftData).enter();

		var eachLeftBar = leftBars.append("rect")
			.attr("class", "leftBar")
			.attr("x", function (d) { return xScale(d.name); })
			.attr("width", xScale.rangeBand() / 2)
			.attr("y", function (d) { return leftYScale(d.value); })
			.attr("height", function (d) { return height - leftYScale(d.value); })
			.style("fill", color(labelNames[0]));

		rightBars = svgEl.selectAll(".rightBar").data(rightData).enter();

		var eachRightBar = rightBars.append("rect")
			.attr("class", "rightBar")
			.attr("x", function (d) { return xScale(d.name) + xScale.rangeBand() / 2; })
			.attr("width", xScale.rangeBand() / 2)
			.attr("y", function (d) { return rightYScale(d.value); })
			.attr("height", function (d) { return height - rightYScale(d.value); })
			.style("fill", color(labelNames[1]));

		// bar value
		if (config.showValues === true)
		{
			leftBars.append("text")
				.text(function (d) { return d.value; })
				.attr("x", function (d) { return xScale(d.name) + 2; })
				.attr("y", function (d) { return leftYScale(d.value) + 20; })
				.attr("class", 'barValue');

			rightBars.append("text")
				.text(function (d) { return d.value; })
				.attr("x", function (d) { return xScale(d.name) + 2 + xScale.rangeBand() / 2; })
				.attr("y", function (d) { return rightYScale(d.value) + 20; })
				.attr("class", 'barValue');
		}

		/* 메인 그래프 legend(범례) */
		if (config.legend.show == true)
			barChartLegend(labelNames,config);

		/* Tooltip */
		if (config.tooltip.show === true)
		{
			// 마우스 움직임에 따라 안내선 표시
			eachLeftBar
				.on(
					"mousemove",
					function (d) {
						d3.select(this)
							.style("stroke", color(labelNames[0]))
							.style("stroke-width", "4px");

						var winMousePos = d3.mouse(document.getElementById(config.chartId));
						var xPosition = winMousePos[0] + 10;
						var yPosition = winMousePos[1];

						var textColor = color(labelNames[0]);

						var infoHtml ="<div class='label' style='color: "+textColor+"'>"
							+ d.name + ": " + labelNames[0]
							+ "</div>";

						infoHtml += "<div>" + leftTooltipFormatData(d.value) + "</div>";

						infoBox.style("display", null);

						var posX = winMousePos[0] + 20;
						var posY = winMousePos[1] - 10;

						// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
						if (config.width - posX < infoBox[0][0].clientWidth)
							posX = posX - infoBox[0][0].clientWidth - 40;

						// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
						if (config.height - posY < infoBox[0][0].clientHeight)
							posY = posY - infoBox[0][0].clientHeight;

						infoBox.style("left", posX + "px")
							.style("top", posY + "px")
							.style("display", null)
							.html(infoHtml);
					}
				)
				.on(
					"mouseout",
					function (d) {
						d3.select(this).style("stroke", "none");
						infoBox.style("display", "none");
					}
				);

			eachRightBar
				.on(
					"mousemove",
					function (d) {
						d3.select(this)
							.style("stroke", color(labelNames[1]))
							.style("stroke-width", "4px");

						var winMousePos = d3.mouse(document.getElementById(config.chartId));
						var xPosition = winMousePos[0] + 10;
						var yPosition = winMousePos[1];
						var textColor = color(labelNames[1]);
						var infoHtml = "<div class='label' style='color: " + textColor + "'>"
							+ d.name + ": " + labelNames[1]
							+ "</div>";

						infoHtml += "<div>" + rightTooltipFormatData(d.value) + "</div>";

						infoBox.style("display", null);

						var posX = winMousePos[0] + 20;
						var posY = winMousePos[1] - 10;

						// 툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
						if (config.width - posX < infoBox[0][0].clientWidth)
							posX = posX - infoBox[0][0].clientWidth - 40;

						// 툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
						if (config.height - posY < infoBox[0][0].clientHeight)
							posY = posY - infoBox[0][0].clientHeight;

						infoBox.style("left", posX + "px")
							.style("top", posY + "px")
							.style("display", null)
							.html(infoHtml);
					}
				)
				.on(
					"mouseout",
					function (d) {
						d3.select(this).style("stroke", "none");
						infoBox.style("display", "none");
					}
				);
		}
	}

	/* 차트 크기 변경 */
	this.resize = function (newConf)
	{
		config.width = newConf.width;

		/* 차트 Margin 설정 */
		if (typeof(newConf.margin) != 'undefined')
		{
			if (typeof(newConf.margin.top) != 'undefined')
				config.margin.top = newConf.margin.top;

			if (typeof(newConf.margin.right) != 'undefined')
				config.margin.right = newConf.margin.right;

			if (typeof(newConf.margin.bottom) != 'undefined')
				config.margin.bottom = newConf.margin.bottom;

			if (typeof(newConf.margin.left) != 'undefined')
				config.margin.left = newConf.margin.left;

			margin = config.margin;
		}

		/* bar chart 간격 설정 */
		if (typeof(newConf.barSpace) != 'undefined')
			config.barSpace = newConf.barSpace;

		width = config.width - margin.left - margin.right;

		// resize xScale
		xScale.rangeRoundBands([0, width], config.barSpace);

		// 차트 다시 그리기
		var chart= d3.select('#' + config.chartId);

		chart.select('svg').remove();

		svgEl = chart
			.append("svg")
			.attr("width", config.width)
			.attr("height", config.height)
			.append("g")
			.attr(
				"transform",
				"translate(" + margin.left + ", " + margin.top + ")"
			);

		self.drawChart(dataSet);
	}
}
