/** Chart Legend **/
var lineChartLegend = function(data,config)
{
	//chart color
	var color = d3.scale.ordinal().range(config.colors);

	var svgEl =  d3.select('#'+config.chartId+ ' svg');
	var legendWrap = svgEl.append("g")
								.attr("class", "legendWrap")
	//범례 위치 지정
	if(config.legend.position=='top') legendWrap.attr("transform", "translate("+(config.margin.left-5)+",0)");
	else legendWrap.attr("transform", "translate("+config.margin.left+","+(config.height-config.margin.bottom+25)+")");
	var legend = legendWrap.selectAll(".legend")
							.data(data)
							.enter().append("g")
							.attr("class", "legend");
	if(config.legend.shape=='circle')
	{
		var legendShape = legend.append("circle")
								.attr("cx", 5)
								.attr("cy", 10)
								.attr("r", 6);
	}
	else
	{
		var legendShape = legend.append("rect")
								.attr("x", 0)
								.attr("y", 3)
								.attr("rx",2)
								.attr("ry",2)
								.attr("width", 12)
								.attr("height", 12);
	}
	legendShape.style("stroke", function(d) {return color(d.name);})
				.style("fill", function(d) {return color(d.name);});
	legend.append("text")
					.attr("x", 18)
					.attr("y", 8)
					.attr("dy", ".35em")
					.style("text-anchor", "start")
					.text(function(d) { return d.name; });

	var dataH=0;
	legend.attr('transform', function(d, i) {
									//글자의 크기에 따라 간격을 설정한다.
									var offset = d3.select(this).select('text').node().getComputedTextLength() + 28;
									if (i === 0) {
										dataL = d.name.length + offset
										return "translate(0,0)" //첫번째 범례위치
									} else { 
										var newdataL = dataL
										dataL +=  d.name.length + offset;
										//범례의 표시 위치가 캔버스의 크기를 벗어나면 줄바꿔주기를 하여 위치를 지정한다.
										if(dataL>=config.width) {newdataL=0;dataL = d.name.length + offset; dataH+=20}

										return "translate(" + (newdataL) + ","+(dataH)+")"
									}
				});
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* sigle/multi line chart */
function lineChart(config)
{
	//차트 기본값 설정
	config = initConfig(config);

	//타이머
	this.second = false;
	if (typeof(config.timer) != 'undefined') this.second = config.timer * 1000;
	
	//켄버스와 그래프영역 크기 설정
	var margin = config.margin,
		width = config.width - margin.left - margin.right,
		height = config.height - margin.top - margin.bottom;

	// X축========================================
	//x축형변환 함수 : date
	var formatDataValue =d3.time.format(config.x.tickformat);
	var formatData = function(d){ return formatDataValue(d);};

	/*눈금 표시를 위한 scale 설정*/
	// X축 : date형
	var xScale = d3.time.scale().range([0, width]),
		xAxis = d3.svg.axis().scale(xScale).orient("bottom");
	//x축 포맷 지정
	if (config.x.tickformat!= '')
	{
		xAxis.tickFormat(d3.time.format(config.x.tickformat));
	}
	//x축 간격 지정
	if (typeof(config.x.ticks)!= 'undefined')
	{
		xAxis.ticks(config.x.ticks);
	}
	//x축 그리드
	if(config.x.grid===true)
	{
		xAxis.tickSize(-height, 0, 0) //x축 눈금 표시
	}
	// Y축========================================
	var formatYDateValue = d3.time.format(config.y.tickdateformat);
	var formatYDate = function(d){return formatYDateValue(d);};

	var yScale	= d3.scale.linear().range([height, 0]),
		yAxis	= d3.svg.axis().scale(yScale).orient("left");

	//y축 간격 지정
	if (typeof(config.y.ticks)!= 'undefined')
	{
		yAxis.ticks(config.y.ticks);
	}


	//y축 포맷 지정
	if (typeof(config.y.tickformat)!= 'undefined')
	{
		if(config.y.tickformat == '%')
		{
			yAxis.tickFormat(d3.format(config.y.tickformat));
			var yFormatDataValue = d3.format(config.y.tickformat);
		}
		else
		{
			yAxis.tickFormat(function(d){ return (bytesToString(config.y.tickformat, d))});
			var yFormatDataValue = function(d){ return bytesToString(config.y.tickformat, d);}
		}
		var yFormatData=function(d){ return yFormatDataValue(d);}
	}
	else
	{
		var yFormatData=function(d){ return d.toFixed(2);}
	}
	//y축 그리드
	if(config.y.grid===true)
	{
		yAxis.tickSize(-width, 0, 0) //y축 눈금 표시
	}

	//chart color
	var color = d3.scale.ordinal().range(config.colors);
	
	//line 메서드
	var line = d3.svg.line()
				    .defined(function(d) { return !isNaN(d.indexValue); })
					.interpolate("linear")
					//.interpolate("basis")
					.x(function(d) { return xScale(d.key); })
					.y(function(d) { return yScale(d.indexValue); });

	//svgEl Object
	var svgEl = d3.select('#'+config.chartId).append("svg")
					.attr("width", config.width)
					.attr("height", config.height);
	var focus = svgEl.append("g")
					.attr("class", "focus")
				    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
	var infoBox = d3.select('#'+config.chartId)
						.append("div")
						.attr("class","infoBox")
						.style("display","none");
	var self = this;
	var dataSet=[];
	var winMousePos=false;
	this.mouse=false;
	this.getData=function()
	{
		d3.json(config.dataSrc,function(error,data){
		
			if (error) throw error;
			
			//차트 그리기
			self.drawChart(data);
			//타이머를 사용하여 갱신
			if (self.second !==false)		setTimeout(function(){ self.updateData(); }, self.second);
		});
	}
	
	//초기화 차트 그리기
	this.drawChart=function(data)
	{
		dataSet=data;

		color.domain(d3.keys(data[0]).filter(function(key) {return key !== "key"; }));

		//지정 color보다 많은 label이 들어오면 glueColor(40가지색)로 color range를 변경한다.
		if(color.range().length< color.domain().length)
		{
			config.colors=colorData.glueColor;
			color.range(config.colors);
		}

		data.forEach(function(d){
			d.key =new Date(d.key * 1000)
		});

		var linedata = color.domain().map(function(name) {
			return {
				name: name,
				values: data.map(function(d) {
					return {key: d.key, indexValue: +d[name]};
				})
			};
		});
		
		/* 메인 그래프 */
		// 메인 그래프 X,Y 축 크기 설정
		xScale.domain(d3.extent(data, function(d) { return d.key; }));
		
		if(config.y.tickformat == '%')
		{
			//Y축 100%
			yScale.domain([0,1]);
		}
		else
		{
			var maxYData = (d3.max(linedata, function(c) { return d3.max(c.values, function(v) { return v.indexValue; }); }));
			if(maxYData < 1024*1024*10)
			{
				maxYData = 1024*1024*10;
			}
			else
			{
				//최대값 보다 20% 더 여유있게 출력
				var maxYDataAdd = (maxYData / 100) * 20;
				maxYData = maxYData + maxYDataAdd;
			}
			maxYData = parseInt(maxYData);

			yScale.domain([
				d3.min(linedata, function(c) { return d3.min(c.values, function(v) { return v.indexValue; }); }),maxYData
			]);
		}
		
		
		//chart 그리기
		var focuslineGroups = focus.selectAll("g")
										.data(linedata)
										.enter().append("g")
										.attr("class","linegroup");

		var focuslines = focuslineGroups.append("path")
											.attr("class","line")
											.attr("d", function(d) {return line(d.values); })
											.attr("data-legend",function(d) { return d.name})
											.style("stroke", function(d) {return color(d.name);})
											.attr("clip-path", "url(#clip)")
		//x축 그리기
		focus.append("g")
					.attr("class", "x axis")
					.attr("transform", "translate(0," + height + ")")
					.call(xAxis)
					.append("text")
					.attr("x", width/2)
					.attr("dy", "2.5em")
					.style("text-anchor", "middle")
					.text(config.x.label);
		//y축 그리기
		focus.append("g")
					.attr("class", "y axis")
					.call(yAxis)
					.append("text")
					.attr("transform", "rotate(-90)")
					.attr("x", -(height/2))
					.attr("dy", "-4em")
					.style("text-anchor", "middle")
					.text(config.y.label);
		////////////////////////////////////////////////////////////////////////
		/* 메인그래프 legend(범례) */
		if(config.legend.show==true) lineChartLegend(linedata,config);
		///////////////////////////////////////////////////////////////////////
		/* Tooltip */
		if(config.tooltip.show===true)
		{
			//마우스 움직임에 따라 안내선 표시
			var tooltipGroup = focus.append("g")
									.attr("class", "tooltip");
			tooltipGroup.append("path") // this is the black vertical line to follow mouse
					.attr("class", "tooltipLine")
			var tooltipPerLine = tooltipGroup.selectAll('.tooltipPerLine')
												.data(linedata)
												.enter()
												.append("g")
												.attr("class", "tooltipPerLine");
			tooltipPerLine.append("circle")
							.attr("r", 5.5)
							.style("stroke", function(d) {return color(d.name);})
							.style("fill", function(d) {return color(d.name);})
			tooltipPerLine.append("text")
							.attr("transform", "translate(10,3)");
			focus.append("rect")// 마우스의 움직임을 캐치 하기 위한 Rect
							.attr("class", "overlay")
							.attr("width", width)
							.attr("height", height)
							.on("mouseover", self.mouseover)
							.on("mouseout", self.mouseout)
							.on("mousemove", function(){
								//winMousePos=d3.mouse(document.body)[0];
								winMousePos=d3.mouse(document.getElementById(config.chartId));
								var mouse=d3.mouse(this);
								self.mouse=mouse;
								self.mousemove(mouse)});
		}
	}
	this.mouseout = function(){
		// on mouse out hide line, circles
		d3.select("#"+config.chartId+" .tooltipLine").style("opacity", "0");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine circle").style("opacity", "0");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine text").style("opacity", "0");
		infoBox.style("display","none");
	}
	this.mouseover = function(){
		// on mouse in show line, circles
		d3.select("#"+config.chartId+" .tooltipLine").style("opacity", "1");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine circle").style("opacity", "1");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine text").style("opacity", "1");
		infoBox.style("display",null);
	}
	this.mousemove=function(mouse) {
		// mouse moving over canvas
		//tooltip line moving
		d3.select("#"+config.chartId+" .tooltipLine")
			.attr("d", function() {
						var d = "M" + mouse[0] + "," + height;
						d += " " + mouse[0] + "," + 0;
						return d;
			});
		
		var chartDoc =document.getElementById(config.chartId);
		var lines = chartDoc.getElementsByClassName('line');
		//tooltip info box layout
		var xDate = xScale.invert(mouse[0]);
		var infoHtml ="<div class='aass'>"+formatYDate(xDate)+"</div>";
		infoHtml +="<ul>"
		//tooltip circle moving
		d3.selectAll("#"+config.chartId+" .tooltipPerLine")
			.attr("transform", function(d, i) {
					var beginning = 0,
						end = lines[i].getTotalLength(),
						target = null;

					while (true){
						target = Math.floor((beginning + end) / 2);
						pos = lines[i].getPointAtLength(target);
						if ((target === end || target === beginning) && pos.x !== mouse[0]) {
							break;
						}
						if (pos.x > mouse[0])      end = target;
						else if (pos.x < mouse[0]) beginning = target;
						else break; //position found
					}
					infoHtml+="<li style='color:"+color(d.name)+"'>"+d.name+" : <span>"+yFormatData(yScale.invert(pos.y))+"</span></li>"
					return "translate(" + mouse[0] + "," + pos.y +")";
			});
		infoHtml +="</ul>";
		var posX=winMousePos[0]+20;
		var posY=winMousePos[1]-10;

		//툴팁이 챠트 오른쪽으로 넘어갈때 위치 이동
		if(config.width - posX < infoBox[0][0].clientWidth) posX = posX - infoBox[0][0].clientWidth - 40;
		//툴팁이 챠트 위쪽으로 넘어갈때 위치 이동
		if(config.height - posY < infoBox[0][0].clientHeight) posY = posY - infoBox[0][0].clientHeight;

		infoBox.style("left",posX+"px")
				.style("top",posY+"px")
				.style("display",null)
				.html(infoHtml);
	}
	/* data 갱신 */
	this.updateData = function() {
		// Get the data again
		d3.json(config.dataSrc, function(error, data) {
			self.reDrawChart(data);

			//타이머를 사용하여 갱신
			if (self.second !==false)		setTimeout(function(){ self.updateData(); }, self.second);
		});
	}

	this.reDrawChart=function(data)
	{
		var dataCnt = data.length;
		while(dataCnt > 0)
		{
			dataSet.shift();
			--dataCnt;
		}

		data.forEach(function(d){
			d.key =new Date(d.key * 1000)
			dataSet.push(d);
		});
		var linedata = color.domain().map(function(name) {
			return {
				name: name,
				values: dataSet.map(function(d) {
					return {key: d.key, indexValue: +d[name]};
				})
			};
		});

		/* 메인 그래프 */
		// 메인 그래프 X,Y 축 크기 설정
		xScale.domain(d3.extent(dataSet, function(d) { return d.key; }));
		if(config.y.tickformat == '%')
		{
			//Y축 100%
			yScale.domain([0,1]);
		}
		else
		{
			var maxYData = (d3.max(linedata, function(c) { return d3.max(c.values, function(v) { return v.indexValue; }); }));
			if(maxYData < 1024*1024*10)
			{
				maxYData = 1024*1024*10;
			}
			else
			{
				//최대값 보다 20% 더 여유있게 출력
				var maxYDataAdd = (maxYData / 100) * 20;
				maxYData = maxYData + maxYDataAdd;
			}
			maxYData = parseInt(maxYData);

			yScale.domain([
				d3.min(linedata, function(c) { return d3.min(c.values, function(v) { return v.indexValue; }); }),maxYData
			]);
		}

		// Select the section we want to apply our changes to
		var svg = d3.select("#"+config.chartId).transition();
		svg.select(".x.axis") // change the x axis
				.duration(750)
				.call(xAxis);
		svg.select(".y.axis") // change the y axis
				.duration(750)
				.call(yAxis);

		//그래프 갱신
		var focuslineGroups = focus.selectAll("g").data(linedata)
		focuslineGroups.select(".line").attr("d",  function(d){return line(d.values)});

		if(config.tooltip.show===true && self.mouse!==false && d3.select("#"+config.chartId+" .tooltipLine").style("opacity")!=0)self.mousemove(self.mouse);
    }
	
	/* 차트 크기 변경 */
	this.resize=function(newConf)
	{
		config.width = newConf.width;
		/* 차트 Margin 설정 */
		if (typeof(newConf.margin) != 'undefined')
		{
			if (typeof(newConf.margin.top) != 'undefined') config.margin.top = newConf.margin.top;
			if (typeof(newConf.margin.right) != 'undefined') config.margin.right = newConf.margin.right;
			if (typeof(newConf.margin.bottom) != 'undefined') config.margin.bottom=newConf.margin.bottom;
			if (typeof(newConf.margin.left) != 'undefined') config.margin.left=newConf.margin.left;
			margin = config.margin;
		}

		width = config.width - margin.left - margin.right;

		//resize xScale
		xScale.range([0, width]);
		//x축 간격 지정
		if (typeof(newConf.x)!= 'undefined' && typeof(newConf.x.ticks)!= 'undefined')
		{
			xAxis.ticks(newConf.x.ticks);
		}
		//y축 그리드
		if(config.y.grid===true)
		{
			yAxis.tickSize(-width, 0, 0) //y축 눈금 표시
		}
		// Select the section we want to apply our changes to
		var svg = d3.select("#"+config.chartId).transition();
		//resize svg width
		svg.select('svg').attr("width", config.width);
		//resize tooltip overlay
		svg.select('rect.overlay').attr("width", width);
		
		//X축 도메인 재설정
		var linedata = color.domain().map(function(name) {
			return {
				name: name,
				values: dataSet.map(function(d) {
					return {key: d.key, indexValue: +d[name]};
				})
			};
		});
		xScale.domain(d3.extent(dataSet, function(d) { return d.key; }));
		
		svg.select(".x.axis") // change the x axis
				.duration(750)
				.call(xAxis);

		//그래프 갱신
		var focuslineGroups = focus.selectAll("g").data(linedata)
		focuslineGroups.select(".line").attr("d",  function(d){return line(d.values)});

		if(config.tooltip.show===true && self.mouse!==false && d3.select("#"+config.chartId+" .tooltipLine").style("opacity")!=0)self.mousemove(self.mouse);
	}
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* time line chart */
function timeLineChart(config)
{
	//차트 기본값 설정
	config = initConfig(config);

	//타이머
	var timer=2;
	this.second = false;
	if (typeof(config.timer) != 'undefined')
	{
		this.second = config.timer * 1000;
		timer = config.timer;
	}
	
	//켄버스와 그래프영역 크기 설정
	var margin = config.margin,
		width = config.width - margin.left - margin.right,
		height = config.height - margin.top - margin.bottom;

	/*눈금 표시를 위한 scale 설정*/
	// X축
	var xScale = d3.scale.linear().range([0, width]);
		xAxis	= d3.svg.axis().scale(xScale).orient("bottom");
	//x축 포맷 지정
	if (config.x.tickformat!= '')
	{
		xAxis.tickFormat(d3.time.format(config.x.tickformat));
	}
	//x축 간격 지정
	if (typeof(config.x.ticks)!= 'undefined')
	{
		xAxis.ticks(config.x.ticks);
	}
	//x축 그리드
	if(config.x.grid===true)
	{
		xAxis.tickSize(-height, 0, 0) //x축 눈금 표시
	}
	// Y축========================================
	var yScale	= d3.scale.linear().range([height, 0]),
		yAxis	= d3.svg.axis().scale(yScale).orient("left");
	//y축 간격 지정
	if (typeof(config.y.ticks)!= 'undefined')
	{
		yAxis.ticks(config.y.ticks);
	}
	//y축 포맷 지정
	if (typeof(config.y.tickformat)!= 'undefined')
	{
		if(config.y.tickformat == '%')
		{
			yAxis.tickFormat(d3.format(config.y.tickformat));
			var yFormatDataValue = d3.format(config.y.tickformat);
		}
		else
		{
			yAxis.tickFormat(function(d){ return (bytesToString(config.y.tickformat, d))});
			var yFormatDataValue = function(d){ return bytesToString(config.y.tickformat, d);}
		}
		var yFormatData=function(d){ return yFormatDataValue(d);}
	}
	else
	{
		var yFormatData=function(d){ return d.toFixed(2);}
	}
	//y축 그리드
	if(config.y.grid===true)
	{
		yAxis.tickSize(-width, 0, 0) //y축 눈금 표시
	}

	//chart color
	var color = d3.scale.ordinal().range(config.colors);
	
	//line 메서드
	var line = d3.svg.line()
				    .defined(function(d) { return !isNaN(d.indexValue); })
					.interpolate("linear")
					//.interpolate("basis")
					.x(function(d) { return xScale(d.key); })
					.y(function(d) { return yScale(d.indexValue); });

	//svgEl Object
	var svgEl = d3.select('#'+config.chartId).append("svg")
					.attr("width", config.width)
					.attr("height", config.height);
	var focus = svgEl.append("g")
					.attr("class", "focus")
				    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
	var infoBox = d3.select('#'+config.chartId)
						.append("div")
						.attr("class","infoBox")
						.style("display","none");
	var self = this;
	var dataSet=[];
	var pointer=0;
	this.mouse=false;
	var winMousePos=false;
	this.getData=function()
	{
		d3.json(config.dataSrc,function(error,data){
		
			if (error) throw error;
			
			//그리프 그리기
			self.drawChart(data);
			//타이머를 사용하여 갱신
			if (self.second !==false)		setTimeout(function(){ self.updateData(); }, self.second);
		});
	}
	
	this.drawChart=function(data)
	{
		color.domain(d3.keys(data[0]).filter(function(key) {return key !== "key"; }));
		
		//지정 color보다 많은 label이 들어오면 glueColor(40가지색)로 color range를 변경한다.
		if(color.range().length< color.domain().length)
		{
			config.colors=colorData.glueColor;
			color.range(config.colors);
		}

		data.forEach(function(d){
			if(dataSet.length==0) 
			{
				var firstEl = (JSON.parse(JSON.stringify(d)));; 
				Object.keys(firstEl).forEach(function(label){
					firstEl[label]=0;
				});
				firstEl.key=timer;
				dataSet.push(firstEl);
			}
			d.key =pointer*timer;
			dataSet.push(d);
			++pointer;
		});
		var linedata = color.domain().map(function(name) {
			return {
				name: name,
				values: dataSet.map(function(d) {
					return {key: d.key, indexValue: +d[name]};
				})
			};
		});

		/* 메인 그래프 */
		// 메인 그래프 X,Y 축 크기 설정
		xScale.domain([60, 0]);
		yScale.domain([config.y.min, config.y.max]);
		
		//chart 그리기
		var focuslineGroups = focus.selectAll("g")
										.data(linedata)
										.enter().append("g");
		var focuslines = focuslineGroups.append("path")
											.attr("class","line")
											.attr("d", function(d) { return line(d.values); })
											.attr("data-legend",function(d) { return d.name})
											.style("stroke", function(d) {return color(d.name);})
											.attr("clip-path", "url(#clip)");
		//x축 그리기
		focus.append("g")
					.attr("class", "x axis")
					.attr("transform", "translate(0," + height + ")")
					.call(xAxis)
					.append("text")
					.attr("x", width/2)
					.attr("dy", "2.5em")
					.style("text-anchor", "middle")
					.text(config.x.label);
		//y축 그리기
		focus.append("g")
					.attr("class", "y axis")
					.call(yAxis)
					.append("text")
					.attr("transform", "rotate(-90)")
					.attr("x", -(height/2))
					.attr("dy", "-3em")
					.style("text-anchor", "middle")
					.text(config.y.label);
		////////////////////////////////////////////////////////////////////////
		/* 메인그래프 legend(범례) */
		if(config.legend.show==true) lineChartLegend(linedata,config);
		///////////////////////////////////////////////////////////////////////
		/* Tooltip */
		if(config.tooltip.show===true)
		{
			//마우스 움직임에 따라 안내선 표시
			var tooltipGroup = focus.append("g")
									.attr("class", "tooltip");
			tooltipGroup.append("path") // this is the black vertical line to follow mouse
					.attr("class", "tooltipLine")
			var tooltipPerLine = tooltipGroup.selectAll('.tooltipPerLine')
												.data(linedata)
												.enter()
												.append("g")
												.attr("class", "tooltipPerLine");
			tooltipPerLine.append("circle")
							.attr("r", 7)
							.style("stroke", function(d) {return color(d.name);})
							.style("fill", function(d) {return color(d.name);})
			tooltipPerLine.append("text")
							.attr("transform", "translate(10,3)");
			focus.append("rect")// 마우스의 움직임을 캐치 하기 위한 Rect
							.attr("class", "overlay")
							.attr("width", width)
							.attr("height", height)
							.on("mouseover", self.mouseover)
							.on("mouseout", self.mouseout)
							.on("mousemove", function(){
								winMousePos=d3.mouse(document.getElementById(config.chartId));
								var mouse=d3.mouse(this);
								self.mouse=mouse;
								self.mousemove(mouse)});
		}
	}
	this.mouseout = function(){
		// on mouse out hide line, circles
		d3.select("#"+config.chartId+" .tooltipLine").style("opacity", "0");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine circle").style("opacity", "0");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine text").style("opacity", "0");
		infoBox.style("display","none");
	}
	this.mouseover = function(){
		if(dataSet.length==0) return;
		// on mouse in show line, circles
		d3.select("#"+config.chartId+" .tooltipLine").style("opacity", "1");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine circle").style("opacity", "1");
		d3.selectAll("#"+config.chartId+" .tooltipPerLine text").style("opacity", "1");
		infoBox.style("display",null);
	}
	this.mousemove=function(mouse) {
		var x0 = xScale.invert(mouse[0])
		//tooltip line moving
		d3.select("#"+config.chartId+" .tooltipLine")
			.attr("d", function() {
						var d = "M" + mouse[0] + "," + height;
						d += " " + mouse[0] + "," + 0;
						return d;
			});
		var chartDoc =document.getElementById(config.chartId);
		var lines = chartDoc.getElementsByClassName('line');
		//tooltip info box layout
		var infoHtml ="<div>"+x0.toFixed(2)+"</div>";
		infoHtml +="<ul>"
		//tooltip circle moving
		d3.selectAll("#"+config.chartId+" .tooltipPerLine")
			.attr("transform", function(d, i) {
					var beginning = 0,
						end = lines[i].getTotalLength(),
						target = null;

					while (true){
						target = Math.floor((beginning + end) / 2);
						pos = lines[i].getPointAtLength(target);
						if ((target === end || target === beginning) && pos.x !== mouse[0]) {
							break;
						}
						if (pos.x > mouse[0])      end = target;
						else if (pos.x < mouse[0]) beginning = target;
						else break; //position found
					}
					infoHtml+="<li style='color:"+color(d.name)+"'>"+d.name+":<span>"+yFormatData(yScale.invert(pos.y))+"</span></li>"
					return "translate(" + mouse[0] + "," + pos.y +")";
			});
		infoHtml +="</ul>";
		var posX=winMousePos[0]+20,posY=winMousePos[1]-10;
			//posY=height/2;
		infoBox.style("left",posX+"px")
				.style("top",posY+"px")
				.style("display",null)
				.html(infoHtml);
	}
	/* data 갱신 */
	this.updateData = function() {
		// Get the data again
		d3.json(config.dataSrc+'?update', function(error, data) {
			self.reDrawChart(data);

			//타이머를 사용하여 갱신
			if (self.second !==false)		setTimeout(function(){ self.updateData(); }, self.second);
		});
	}

	this.reDrawChart=function(data)
	{
		//데이터 한칸씩 당겨주기
		if(pointer*timer>=60) dataSet.shift();
	
		//data key값 갱신
		dataSet.forEach(function(d){
			d.key=d.key+timer;
		})

		data.forEach(function(d){
			d.key=0
			dataSet.push(d);
			++pointer;
		});

		var linedata = color.domain().map(function(name) {
			return {
				name: name,
				values: dataSet.map(function(d) {
					return {key: d.key, indexValue: +d[name]};
				})
			};
		});
		/* Scale 설정 */
		var yMaxVal = d3.max(linedata, function(c) { return d3.max(c.values, function(v) { return v.indexValue; }); })
		if(yMaxVal>config.y.max)
		{
			yScale.domain([config.y.min, yMaxVal]);
		}
		/* 메인 그래프 */
		// Select the section we want to apply our changes to
		var svg = d3.select("#"+config.chartId).transition();
		svg.select(".x.axis") // change the x axis
				.duration(750)
				.call(xAxis);
		svg.select(".y.axis") // change the y axis
				.duration(750)
				.call(yAxis);
		
		//그래프 갱신
		var focuslineGroups = focus.selectAll("g").data(linedata);
		focuslineGroups.select(".line").attr("d",  function(d){return line(d.values)});
		if(config.tooltip.show===true && self.mouse!==false && d3.select("#"+config.chartId+" .tooltipLine").style("opacity")!=0)self.mousemove(self.mouse);
	}

	this.resize=function(newConf)
	{
		config.width = newConf.width;
		/* 차트 Margin 설정 */
		if (typeof(newConf.margin) != 'undefined')
		{
			if (typeof(newConf.margin.top) != 'undefined') config.margin.top = newConf.margin.top;
			if (typeof(newConf.margin.right) != 'undefined') config.margin.right = newConf.margin.right;
			if (typeof(newConf.margin.bottom) != 'undefined') config.margin.bottom=newConf.margin.bottom;
			if (typeof(newConf.margin.left) != 'undefined') config.margin.left=newConf.margin.left;
			margin = config.margin;
		}

		width = config.width - margin.left - margin.right;

		//resize xScale
		xScale.range([0, width]);
		//x축 간격 지정
		if (typeof(newConf.x)!= 'undefined' && typeof(newConf.x.ticks)!= 'undefined')
		{
			xAxis.ticks(newConf.x.ticks);
		}
		//y축 그리드
		if(config.y.grid===true)
		{
			yAxis.tickSize(-width, 0, 0) //y축 눈금 표시
		}
		// Select the section we want to apply our changes to
		var svg = d3.select("#"+config.chartId).transition();
		//resize svg width
		svg.select('svg')
					.attr("width", config.width);
		//resize tooltip overlay
		svg.select('rect.overlay').attr("width", width);
		svg.select(".x.axis") // change the x axis
				.duration(750)
				.call(xAxis);
	}
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
