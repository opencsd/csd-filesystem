/* chart color */
var colorData = {
	 glueColor1: ["#5974D9","#38B4EE","#19C395","#C3DE71","#F1D44B","#3C52A5","#1FAEBF","#88BD6B","#D1A756","#E573739"]
	,glueColor2: ["#3497DA","#CBD842","#88BFAF","#113D62","#55B5C3","#F1C82E","#DE932E","#D04F4A","#8C1123","#CA0088"]
	,glueColor3: ["#B68DD1","#FFA184","#F381A8","#83CCC5","#55B5C3","#464960","#81C784","#64B5F6","#FFB74D","#E57373"]
	,glueColor : ["#5974D9","#38B4EE","#19C395","#C3DE71","#F1D44B","#3C52A5","#1FAEBF","#88BD6B","#D1A756","#E573739","#3497DA","#CBD842","#88BFAF","#113D62","#55B5C3","#F1C82E","#DE932E","#D04F4A","#8C1123","#CA0088","#B68DD1","#FFA184","#F381A8","#83CCC5","#55B5C3","#464960","#81C784","#64B5F6","#FFB74D","#E57373","#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]
	,category10: ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]
	,category20: ["#1f77b4", "#aec7e8", "#ff7f0e", "#ffbb78", "#2ca02c", "#98df8a", "#d62728", "#ff9896", "#9467bd", "#c5b0d5", "#8c564b", "#c49c94", "#e377c2", "#f7b6d2", "#7f7f7f", "#c7c7c7", "#bcbd22", "#dbdb8d", "#17becf", "#9edae5"]
};

/* Chart Config init */
var initConfig = function(config)
{
	/* 차트 캔버스 크기 기본값 설정 */
	if (typeof(config.width)== 'undefined') config.width = 500;
	if (typeof(config.height)== 'undefined') config.height = 300;
	/* x축 기본값 설정 */
	if (typeof(config.x)== 'undefined') config.x={label:''};
	if (typeof(config.x.label)== 'undefined') config.x.label='';
	if (typeof(config.x.grid)== 'undefined') config.x.grid=false;
	if (typeof(config.x.tickformat)== 'undefined') config.x.tickformat = "%H:%M";
	/* y축 기본값 설정 */
	if (typeof(config.y)== 'undefined') config.y={label:''};
	if (typeof(config.y.label)== 'undefined') config.y.label='';
	if (typeof(config.y.grid)== 'undefined') config.y.grid=false;
	if (typeof(config.y.tickdateformat)== 'undefined') config.y.tickdateformat = config.x.tickformat;
	/* 차트 Margin 설정 */
	if (typeof(config.margin) == 'undefined') config.margin ={top: 40, right: 20, bottom: 30, left: 40};
	if (typeof(config.margin.top) == 'undefined') config.margin.top=30;
	if (typeof(config.margin.right) == 'undefined') config.margin.right=30;
	if (typeof(config.margin.bottom) == 'undefined') config.margin.bottom=30;
	if (typeof(config.margin.left) == 'undefined') config.margin.left=40;
	/* Tooltip */
	if (typeof(config.tooltip) == 'undefined') config.tooltip={show:true};
	if (typeof(config.tooltip.show) == 'undefined') config.tooltip.show=true;
	/* 범례 */
	if (typeof(config.legend) == 'undefined') config.legend={legend:true};
	if (typeof(config.legend.show) == 'undefined') config.legend.show=true;
	if (typeof(config.legend.position) == 'undefined') config.legend.position='bottom';
	if (typeof(config.legend.shape) == 'undefined') config.legend.shape='rect';
	/* 바차트 value */
	if (typeof(config.showValues) == 'undefined') config.showValues=false;
	/* 바차트 바 간격 */
	if (typeof(config.barSpace) == 'undefined') config.barSpace=.1;
	
	/* chart color*/
	if(typeof(config.colors)=='undefined') config.colors=colorData.glueColor1; //default chart color
	else {
		//color의 index명일 경우 color 지정
		if(Array.isArray(config.colors) === false){
			if(colorData.hasOwnProperty(config.colors))		config.colors = colorData[config.colors];
			else  config.colors=colorData.glueColor1; //지정한 color 레이블이 아니면 default chart color 사용
		}
	}
	return config;
}

/* 데이터 포멧 */
var bytesToString = function (format, bytes) {
    var fmt = d3.format(format);
    if(bytes < 1024) 
	{
        return fmt(bytes) + 'B';
    }
	else if(bytes < 1024 * 1024) 
	{
        return fmt(bytes / 1024) + 'k';
    } 
	else if(bytes < 1024 * 1024 * 1024)
	{
        return fmt(bytes / 1024 / 1024) + 'M';
    } 
	else if(bytes < 1024 * 1024 * 1024 * 1024)
	{
        return fmt(bytes / 1024 / 1024 / 1024) + 'G';
    }
	else 
	{
        return fmt(bytes / 1024 / 1024 / 1024 / 1024) + 'T';
    }
}