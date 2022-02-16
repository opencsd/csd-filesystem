/* Objects to draw chart */
var clientChartObj;
var fsUsageChartObj;

/** Window resizing */
function MCO_overviewPanelResize()
{
	if (typeof(clientChartObj) != 'undefined')
	{
		clientChartObj.resize({ width: Ext.get("clientChartSvg").getWidth() });
	}

	if (typeof(fsUsageChartObj) != 'undefined')
	{
		fsUsageChartObj.resize({ width: Ext.get("AvailableChartSvg").getWidth() });
	}
};

/**
클러스터 상태 데이터 로드
**/
function MCO_overviewLoad()
{
	GMS.Ajax.request({
		url: '/api/cluster/status',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MCO_overviewStatusGrid.unmask();

			if (!success || !decoded.success)
			{
				clearInterval(_nowCurrentOverviewClstVar);
				_nowCurrentOverviewClstVar = null;
				return;
			}

			// 클러스터 상태 표시
			var statusValue = decoded.entity.Status;
			var statusMsg   = decoded.entity.Msg;

			// 클러스터 상태
			MCO_overviewStatusGrid.setTitle(
				'&nbsp' + lang_mco_overview[15] + ': ' + statusMsg);

			if (statusValue == 'OK')
			{
				MCO_overviewStatusGrid.setIconCls('state_ok');
			}
			else if (statusValue == 'WARN')
			{
				MCO_overviewStatusGrid.setIconCls('state_warn_blink');
			}
			else if (statusValue == 'ERR')
			{
				MCO_overviewStatusGrid.setIconCls('state_err_blank');
			}

			// 주기적 갱신
			clearInterval(_nowCurrentOverviewClstVar);

			_nowCurrentOverviewClstVar
				= setInterval(function() { MCO_overviewLoad() }, 10000);
		},
	});
};

function MCO_overviewNodeLoad()
{
	GMS.Ajax.request({
		url: '/api/cluster/nodes',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MCO_overviewStatusGrid.unmask();

			// 응답 데이터
			if (!success || !decoded.success)
			{
				// 주기적 갱신 제거
				clearInterval(_nowCurrentOverviewNodeVar);
				_nowCurrentOverviewNodeVar = null;

				return;
			}

			Ext.getCmp('MCO_overviewNodeTotal')
				.setText(lang_mco_overview[46] + ': ' + decoded.entity.length);

			// 노드 상태 스토어 로드
			MCO_overviewStatusStore.loadRawData(decoded.entity, false);

			// 주기적 갱신
			clearInterval(_nowCurrentOverviewNodeVar);

			_nowCurrentOverviewNodeVar
				= setInterval(function() { MCO_overviewNodeLoad() }, 10000);
		},
	});
}

function drawChart()
{
	// 챠트 범위 시간
	var from = Ext.getCmp('MCO_overviewPerformanceType').getValue();

	// 챠트 주기
	var refresh
		= (from == 'now-1h' || from == 'now-24h') ? '10s' : '1d';

	/** 오버뷰 성능 챠트 **/
	var MCO_overviewChartCPUObj
		= Ext.getCmp('MCO_overviewCPUChartSvg')
			.child('#MCO_overviewCPUframe');

	if (!MCO_overviewChartCPUObj)
	{
		/** Add CPU usage graph **/
		var url = getDashboardURI({
			ip: MASTER.host,
			name: 'anystor-cluster-graphs',
			panel_id: 1,
			from: from,
			refresh: refresh,
		});

		var graph = new Ext.ux.IFrame({
			id: 'MCO_overviewCPUframe',
			src: url,
			height: 220,
		});

		Ext.getCmp('MCO_overviewCPUChartSvg').add(graph);
	}

	var MCO_overviewChartNetworkObj
		= Ext.getCmp('MCO_overviewNetworkChartSvg')
			.child('#MCO_overviewNetworkframe');

	if (!MCO_overviewChartNetworkObj)
	{
		/** Add network throughput graph **/
		var url = getDashboardURI({
			ip: MASTER.host,
			name: 'anystor-cluster-graphs',
			panel_id: 2,
			from: from,
			refresh: refresh,
		});

		var graph = new Ext.ux.IFrame({
			id: 'MCO_overviewNetworkframe',
			src: url,
			height: 220,
		});

		Ext.getCmp('MCO_overviewNetworkChartSvg').add(graph);
	}

	var MCO_overviewChartDiskIOObj
		= Ext.getCmp('MCO_overviewDiskIOChartSvg')
			.child('#MCO_overviewDiskIOframe');

	if (!MCO_overviewChartDiskIOObj)
	{
		/** Add storage throughput graph **/
		var url = getDashboardURI({
			ip: MASTER.host,
			name: 'anystor-cluster-graphs',
			panel_id: 3,
			from: from,
			refresh: refresh,
		});

		var graph = new Ext.ux.IFrame({
			id: 'MCO_overviewDiskIOframe',
			src: url,
			height: 220,
		});

		Ext.getCmp('MCO_overviewDiskIOChartSvg').add(graph);
	}
}

/* 성능 통계 데이터 로드 */
function MCO_overviewChartLoad(params)
{
	params = params || {};

	GMS.Ajax.request({
		url: '/api/cluster/general/master',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MCO_overviewChartPanel.unmask();

			if (!success || !decoded.success)
			{
				// 주기적 갱신 제거
				clearInterval(_nowCurrentOverviewChartVar);
				_nowCurrentOverviewChartVar = null;

				return;
			}

			var targets = [];

			targets.push(
				decoded.entity.Mgmt_IP,
				decoded.entity.Storage_IP);

			targets = targets.concat(decoded.entity.Service_IP);

			console.debug('targets:', targets);

			var promises = [];

			targets.forEach(
				function (target)
				{
					var promise = ping({
						host: target,
						port: 8890,
						path: 'public/img/grafana_icon.svg',
					});

					promises.push(promise);
				}
			);

			Ext.ux.Deferred
				.when(...promises)
				.then(
					function (results) {
						console.debug('results:', results);
					},
					/* :TODO Tue 18 Aug 2020 09:59:24 AM KST: by P.G.
					 * we need to write below routine more reasonable again.
					 */
					function (errors) {
						console.debug('errors:', errors);

						// indicates trying to connect all targets failed
						if (Object.keys(errors).length == targets.length)
						{
							MASTER.online = false;
							MASTER.host   = null;

							/** 주기적 갱신 **/
							clearInterval(_nowCurrentOverviewChartVar);

							_nowCurrentOverviewChartVar = setInterval(
								function () { MCO_overviewChartLoad() },
								10000
							);

							return;
						}

						var failed = Object.values(errors).map(
							function (e) { return e.host; }
						);

						console.debug('failed:', failed);

						targets.some(
							function (target)
							{
								console.debug('target:', target);

								if (failed.includes(target))
								{
									return false;
								}

								// 마스크 제거
								MCO_overviewChartPanel.unmask();

								console.debug('MASTER:', MASTER);

								if (MASTER.host != target)
								{
									MASTER.host   = target;
									MASTER.online = true;
								}

								drawChart();

								return true;
							}
						);
					},
				);
		},
	});
};

/* 최근 이벤트 데이터 로드 */
function MCO_overviewEventLoad()
{
	GMS.Ajax.request({
		url: '/api/cluster/event/list',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MCO_overviewEventGrid.unmask();

			if (!success || !decoded.success)
			{
				// 주기적 갱신 제거
				clearInterval(_nowCurrentOverviewEventVar);
				_nowCurrentOverviewEventVar = null;

				return;
			}

			// 이벤트 스토어 로드
			MCO_overviewEventStore.loadRawData(decoded, false);

			/** 주기적 갱신 **/
			clearInterval(_nowCurrentOverviewEventVar);

			_nowCurrentOverviewEventVar = setInterval(
				function() { MCO_overviewEventLoad() },
				10000
			);
		}
	});
}

/* 클라이언트 접속현황 데이터 로드 */
function MCO_overviewClientChart()
{
	GMS.Ajax.request({
		url: '/api/cluster/dashboard/clientgraph',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MCO_overviewClientChartPanel.unmask();

			if (!success || !decoded.success)
			{
				if (waitMsgBox)
				{
					// 데이터 전송 완료 후 wait 제거
					waitMsgBox.hide();
					waitMsgBox = null;
				}

				return;
			}

			// 클라이언트 접속 현황
			var clientChartSvgPanel = Ext.get("clientChartSvg").getWidth();
			var clientChartWidth = clientChartSvgPanel;

			if (!decoded.entity.length)
			{
				return;
			}

			var clientChartConfig = {
				chartId:'clientChartSvg-body',
				width: clientChartWidth,
				height: 260,
				margin: {
					left: 65,
					right: 90,
					bottom: 50,
					top: 10
				},
				leftY: {
					tickformat: 'd',
					label: lang_mco_overview[17]
				},
				rightY: {
					tickformat: '.2s',
					ticks: 5,
					toolTipformat: '.3s',
					label: lang_mco_overview[18]
				},
				legend: {
					position :'bottom',
					shape :'circle'
				},
				colors: 'category10',
				showValues: false,
				tickformat:'.3s',
				colors: ['#5090F7', '#64D4E4']
			};

			// 클라이언트 접속 현황 데이터 타입 변경
			clientChartObj = new dualScaleBarChart(clientChartConfig);
			clientChartObj.drawChart(decoded.entity);
		},
	});
};

/* 가용량 챠트 데이터 로드 */
function MCO_overviewFsUsageChart()
{
	GMS.Ajax.request({
		url: '/api/cluster/dashboard/fsusage',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MCO_overviewAvailableChartPanel.unmask();

			if (!success || !decoded.success)
			{
				return;
			}

			// 클러스터 가용량 데이터가 없거나 가져올 수 없을 때
			if (decoded.entity.is_available == 'false')
			{
				Ext.getCmp('AvailableChartSvg').hide();
				Ext.getCmp('AvailableChartSvgNone').show();
				Ext.getCmp('AvailableChartSvgNone').update(lang_mco_overview[27]);
			}
			else
			{
				Ext.getCmp('AvailableChartSvgNone').hide();
				Ext.getCmp('AvailableChartSvg').show();
			}

			var fsUsageChartPanel = Ext.get('AvailableChartSvg').getWidth();
			var fsUsageChartWidth = fsUsageChartPanel - 50;

			if (decoded.entity.data.length <= 0)
			{
				return;
			}

			var chartConfig = {
				chartId: 'AvailableChartSvg-body',
				width: fsUsageChartWidth,
				height: 275,
				margin: { left: 60, top: 20, right: 0, bottom: 60 },
				y: {
					label: lang_mco_overview[37],
					tickformat: '%',
					grid: true
				},
				x: { grid:true },
				legend: { position: 'bottom', shape: 'circle' },
				tooltip: { format: '.3s' },
				barSpace: .2,
				colors: ["#CCE386", "#4BDBAA"]
			};

			// 가용량 데이터 타입 변경
			var fsUsage = decoded.entity.data;

			fsUsageChartObj = new stackedBarChart(chartConfig);
			fsUsageChartObj.drawChart(fsUsage);
		},
	});
};

/**
오버뷰 상태 목록
**/
// 노드 ID 정렬
Ext.apply(Ext.data.SortTypes, {
	asHostName: function(hostname) {
		var hostnameData   = hostname.split('-');
		var hostnameNumber = parseInt(hostnameData[1]);

		return hostnameNumber;
	}
});

// 오버뷰 상태 모델
Ext.define(
	'MCO_overviewStatusModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Status',
			{
				name: 'Mgmt_Hostname',
				sortType: 'asHostName'
			},
			{
				name: 'Mgmt_IP',
				type: 'string',
				mapping: 'Mgmt_IP.ip',
			},
			'Service_IP',
			'Netw_In_Byte_Sec',
			'Netw_Out_Byte_Sec',
			'Strg_In_Byte_Sec',
			'Strg_Out_Byte_Sec',
			'Node_Used_Size',
			'Node_All_Size',
			'Node_Usage',
			'Stage'
		]
	}
);

// 오버뷰 상태 스토어
var MCO_overviewStatusStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCO_overviewStatusModel',
		sorters: [
			{
				property: 'Mgmt_Hostname',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'memory',
			reader: { type: 'json' },
		},
	}
);

// 오버뷰 상태 그리드
var MCO_overviewStatusGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCO_overviewStatusGrid',
		store: MCO_overviewStatusStore,
		multiSelect: false,
		title: lang_mco_overview[3],
		features: [
			{
				ftype: 'summary',
				dock: 'bottom'
			}
		],
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'label',
					id: 'MCO_overviewNodeTotal',
					style: 'padding-right: 5px;'
				}
			]
		},
		columns: [
			{
				text: lang_mco_overview[2],
				sortable: true,
				menuDisabled: true,
				columns: [
					{
						text: lang_mco_overview[3],
						menuDisabled: true,
						columns: [
							{
								dataIndex: 'Status',
								menuDisabled: true,
								width: 40,
								height: 0,
								style: { border: 0 },
								align: 'center',
								xtype: 'actioncolumn',
								items: [
									{
										getClass: function(v, meta, record) {
											if (record.get('Status') == "OK")
											{
												return 'state_ok';
											}
											else if (record.get('Status') == 'WARN')
											{
												return 'state_warn';
											}
											else if (record.get('Status') == 'ERR')
											{
												return 'state_err';
											}
										}
									}
								],
								summaryRenderer: function(value, summaryData, dataIndex)
								{
									return '<span style="padding: 6px 0px;">Total</span>';
								}
							},
							{
								dataIndex: 'Stage',
								height: 0,
								style: { border: 0 },
								menuDisabled: true
							}
						]
					},
					{
						text: lang_mco_overview[4],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Mgmt_Hostname',
						renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
							var stage = record.data.Stage;

							return stage == 'running'
										? '<span class="node-link">' + value + '</span>'
										: '<span>' + value + '</span>';
						},
						summaryRenderer: function(value, summaryData, dataIndex) {
							return '<span></span>';
						}
					},
					{
						text: lang_mco_overview[5],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Mgmt_IP',
					},
					{
						text: lang_mco_overview[6],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Service_IP'
					}
				]
			},
			{
				text: lang_mco_overview[7],
				sortable: true,
				menuDisabled: true,
				columns: [
					{
						text: lang_mco_overview[8],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Netw_In_Byte_Sec',
						summaryType: 'sum',
						renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
							return byteConvertor(value);
						},
						summaryRenderer: function(value, summaryData, dataIndex) {
							return byteConvertor(value);
						}
					},
					{
						text: lang_mco_overview[9],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Netw_Out_Byte_Sec',
						summaryType: 'sum',
						renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
							return byteConvertor(value);
						},
						summaryRenderer: function(value, summaryData, dataIndex) {
							return byteConvertor(value);
						}
					}
				]
			},
			{
				text: lang_mco_overview[10],
				sortable: true,
				menuDisabled: true,
				columns: [
					{
						text: lang_mco_overview[8],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Strg_In_Byte_Sec',
						summaryType: 'sum',
						renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
							return byteConvertor(value);
						},
						summaryRenderer: function(value, summaryData, dataIndex) {
							return byteConvertor(value);
						}
					},
					{
						text: lang_mco_overview[9],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Strg_Out_Byte_Sec',
						summaryType: 'sum',
						renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
							return byteConvertor(value);
						},
						summaryRenderer: function(value, summaryData, dataIndex) {
							return byteConvertor(value);
						}
					}
				]
			},
			{
				text: lang_mco_overview[11],
				sortable: true,
				menuDisabled: true,
				columns: [
					{
						text: lang_mco_overview[12],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Node_Used_Size',
						summaryType: 'sum',
						renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
							let used = byteConvertor(value).split(' ');
							return used[0]+' '+used[1];
						},
						summaryRenderer: function(value, summaryData, dataIndex) {
							return byteConvertor(value);
						}
					},
					{
						text: lang_mco_overview[13],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Node_All_Size',
						summaryType: 'sum',
						renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
							let used_all = byteConvertor(value).split(' ');
							return used_all[0]+' '+used_all[1];
						},
						summaryRenderer: function (value, summaryData, dataIndex) {
							return byteConvertor(value);
						}
					},
					{
						text: lang_mco_overview[14],
						sortable: true,
						menuDisabled: true,
						dataIndex: 'Node_Usage',
						summaryType: 'sum',
						summaryRenderer: function (value, summaryData, dataIndex) {
							var used  = this.up('gridcolumn').down('[dataIndex=Node_Used_Size]');
							var total = this.up('gridcolumn').down('[dataIndex=Node_All_Size]');

							return (summaryData[used.id] / summaryData[total.id] * 100).toFixed(2)+' %';
						}
					}
				]
			}
		],
		listeners: {
			cellclick: {
				fn: function (o, idx, column, e) {
					var stage = e.get('Stage');

					if (column == 2
						&& (stage == 'running' || stage == 'expanding'
							|| stage == 'detaching'))
					{
						// 기존 생성 차트 제거
						if (typeof(clientChartObj) != 'undefined')
						{
							d3.select("#clientChartSvg-body svg").remove();
						}

						if (typeof(fsUsageChartObj) != 'undefined')
						{
							d3.select("#AvailableChartSvg-body svg").remove();
						}

						$.cookie('gms_page', 'manager_node_condition');
						selectClusterNode(e.get('Mgmt_IP'));
					}
				}
			},
			resize: function(grid, width, height) {
				// 그룹 헤더를 사용할 경우 셀 크기 지정 문제
				var columns     = grid.columns;
				var length      = columns.length;
				var columnWidth = (width - 40) / (length - 1);

				for (var i=1; i<length; i++)
				{
					columns[i].setWidth(columnWidth);
				}
			},
			beforeselect: function() {
				return false;
			}
		},
		viewConfig: {
			forceFit: true,
			trackOver: false
		}
	}
);

/** 클라이언트 접속 현황 **/
var MCO_overviewClientChartPanel = Ext.create('BasePanel', {
	id: 'MCO_overviewClientChartPanel',
	frame: true,
	title: lang_mco_overview[41],
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			id: 'clientChartSvg',
			height: 290,
			layout: 'fit',
			overflowX: 'hidden',
			overflowY: 'hidden'
		}
	],
	listeners: {
		resize: {
			fn: function(el) {
				MCO_overviewPanelResize();
			}
		}
	}
});

/** 오버뷰 이벤트 그리드 **/
//이벤트 ROW 선택시 상세 보기
var MCO_overviewEventWindow = Ext.create('BaseWindowPanel', {
	id: 'MCO_overviewEventWindow',
	title: lang_mco_overview[19],
	maximizable: false,
	autoHeight: true,
	width: 600,
	minHeight: 300,
	layout: { type: 'vbox', align: 'stretch'},
	items: [
		{
			xtype: 'label',
			id: 'MCO_overviewEventWindowLabel',
			flex: 1
		}
	],
	buttons: [
		{
			id: 'MCO_overviewEventWindowCloseBtn',
			text: lang_mco_overview[20],
			handler: function() {
				MCO_overviewEventWindow.hide();
			}
		}
	]
});

// 이벤트 모델
Ext.define('MCO_overviewEventModel', {
	extend: 'Ext.data.Model',
	fields: [
		'ID', 'Scope', 'Category', 'Level', 'Category', 'Message', 'Details',
		'Time', 'Quiet'
	]
});

// 이벤트 스토어
var MCO_overviewEventStore = Ext.create('Ext.data.Store', {
	model: 'MCO_overviewEventModel',
	sorters: [
		{
			property: 'Time',
			direction: 'DESC'
		}
	],
	proxy: {
		type: 'memory',
		reader: {
			type: 'json',
			root: 'entity',
			totalProperty: 'total',
		}
	}
});

// 이벤트 그리드
var MCO_overviewEventGrid = Ext.create('BaseGridPanel', {
	id: 'MCO_overviewEventGrid',
	store: MCO_overviewEventStore,
	multiSelect: false,
	title: lang_mco_overview[21],
	cls: 'line-break',
	header: {
		titlePosition: 0,
		items:[
			{
				xtype: 'button',
				id: 'MCO_overviewEventBtn',
				style: { marginRight: '5px' },
				text: lang_mco_overview[22],
				handler: function() {
					var record = Ext.getCmp('adminTreePanel').getStore().getNodeById('manager_cluster_event');
					Ext.getCmp('adminTreePanel').getSelectionModel().select(record);
				}
			}
		]
	},
	columns: [
		{
			text: lang_mco_overview[3],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Level',
			width: 50,
			align: 'center',
			xtype: 'actioncolumn',
			items: [
				{
					getClass: function(v, meta, record) {
						if (record.get('Level') == "OK"
							|| record.get('Level') == 'INFO')
						{
							return 'state_ok';
						}
						else if (record.get('Level') == 'REPAIRED')
						{
							return 'state_ok';
						}
						else if (record.get('Level') == 'WARNING')
						{
							return 'state_warn';
						}
						else if (record.get('Level') == 'ERROR')
						{
							return 'state_err';
						}
					}
				}
			]
		},
		{
			flex: 1,
			text: lang_mco_overview[23],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Time'
		},
		{
			flex: 2,
			text: lang_mco_overview[24],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Message'
		},
		{
			flex: 1,
			text: lang_mco_overview[25],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Scope'
		},
		{
			flex: 1,
			text: lang_mco_overview[26],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Category'
		}
	],
	listeners: {
		itemclick: function(grid, record, item, index, e) {
			Ext.defer(function () {
				MCO_overviewEventWindow.show();
				Ext.getCmp("MCO_overviewEventWindowLabel").update();
				Ext.getCmp("MCO_overviewEventWindowLabel")
					.update(library.json.prettyPrint(record.data));
			}, 200);
		}
	}
});

/** 성능 통계 챠트 **/
/** 클러스터 가용량 PANEL **/
var MCO_overviewAvailableChartPanel = Ext.create('BasePanel', {
	id: 'MCO_overviewAvailablePanel',
	layout: 'fit',
	frame: true,
	title: lang_mco_overview[37],
	shadow: false,
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			id: 'AvailableChartSvg',
			height: 275,
			layout: 'fit',
			bodyStyle: 'padding: 15px;',
			overflowX: 'hidden',
			overflowY: 'hidden'
		},
		{
			xtype: 'BasePanel',
			id: 'AvailableChartSvgNone',
			height: 275,
			layout: 'fit',
			bodyStyle: { padding: 0 },
			overflowX: 'hidden',
			overflowY: 'hidden',
			bodyCls: 'm-panel-center',
			html: lang_mco_overview[27]
		}
	]
});

/** 성능 통계 PANEL **/
var MCO_overviewChartPanel = Ext.create('BasePanel', {
	id: 'MCO_overviewChartPanel',
	title: lang_mco_overview[30],
	frame: true,
	header: {
		titlePosition: 0,
		items: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MCO_overviewPerformanceType',
				name: 'overviewPerformanceType',
				store: new Ext.data.SimpleStore({
					fields: ['Type', 'Code'],
					data: [
						[lang_mco_overview[31], 'now-1h'],
						[lang_mco_overview[32], 'now-24h'],
						[lang_mco_overview[33], 'now-7d'],
						[lang_mco_overview[34], 'now-1M'],
						[lang_mco_overview[35], 'now-6M'],
						[lang_mco_overview[36], 'now-1y']
					]
				}),
				// 초기값
				value: 'now-1h',
				displayField: 'Type',
				valueField: 'Code',
				width: 120,
				listeners: {
					change: function(combo, newValue, oldValue) {
						if (newValue && oldValue)
						{
							var refresh
								= (newValue == 'now-1h' || newValue == 'now-24h')
									? '10s' : '1d';

							Ext.getCmp('MCO_overviewCPUframe').iframeEl.dom.src
								= getDashboardURI({
									ip: MASTER.host,
									name: 'anystor-cluster-graphs',
									panel_id: 1,
									from: newValue,
									refresh: '10s',
								});

							Ext.getCmp('MCO_overviewNetworkframe').iframeEl.dom.src
								= getDashboardURI({
									ip: MASTER.host,
									name: 'anystor-cluster-graphs',
									panel_id: 2,
									from: newValue,
									refresh: '10s',
								});

							Ext.getCmp('MCO_overviewDiskIOframe').iframeEl.dom.src
								= getDashboardURI({
									ip: MASTER.host,
									name: 'anystor-cluster-graphs',
									panel_id: 2,
									from: newValue,
									refresh: '10s',
								});
						}
					}
				}
			}
		]
	},
	items: [
		{
			xtype: 'BasePanel',
			id: 'MCO_overviewCPUChartSvg',
			bodyStyle: { padding: 0 },
			overflowX: 'hidden',
			overflowY: 'hidden'
		},
		{
			xtype: 'BasePanel',
			id: 'MCO_overviewCPUChartSvgNone',
			bodyStyle: { padding: 0 },
			html: '&nbsp;'
		},
		{
			xtype: 'BasePanel',
			id: 'MCO_overviewNetworkChartSvg',
			bodyStyle: { padding: 0 },
			overflowX: 'hidden',
			overflowY: 'hidden'
		},
		{
			xtype: 'BasePanel',
			id: 'MCO_overviewNetworkChartSvgNone',
			bodyStyle: { padding: 0 },
			html: '&nbsp;'
		},
		{
			xtype: 'BasePanel',
			id: 'MCO_overviewDiskIOChartSvg',
			bodyStyle: { padding: 0 },
			overflowX: 'hidden',
			overflowY: 'hidden'
		}
	]
});

/**
(상태,클라이언트, 이벤트) 판넬, 성능통계 판넬
**/
var MCO_overviewPanel = Ext.create(
	'BasePanel',
	{
		id: 'MCO_overviewPanel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'BasePanel',
				layout: { type: 'vbox', align : 'stretch' },
				flex: 5,
				bodyStyle: 'padding: 0;',
				style: { marginRight: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '20px' },
						height: 330,
						items: [ MCO_overviewStatusGrid ]
					},
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '20px' },
						height: 330,
						items: [ MCO_overviewClientChartPanel ]
					},
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '20px' },
						height: 400,
						items: [ MCO_overviewEventGrid ]
					}
				]
			},
			{
				xtype: 'BasePanel',
				layout: { type: 'vbox', align : 'stretch' },
				flex: 2,
				bodyStyle: 'padding: 0;',
				items: [
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '20px' },
						height: 330,
						items: [ MCO_overviewAvailableChartPanel ]
					},
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '20px' },
						height: 750,
						items: [ MCO_overviewChartPanel ]
					}
				]
			}
		]
	}
);

// overview
Ext.define(
	'/admin/js/manager_cluster_overview',
	{
		extend: 'BasePanel',
		id: 'manager_cluster_overview',
		bodyStyle: 'padding: 0;',
		load: function() {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			// 오버뷰 제거
			MCO_overviewStatusStore.removeAll();

			// 최근 이벤트 제거
			MCO_overviewEventStore.removeAll();

			// 클러스터 상태
			MCO_overviewStatusGrid.mask(lang_mco_overview[47]);
			MCO_overviewLoad();

			// 노드 상태
			MCO_overviewNodeLoad();

			// 성능 통계
			MCO_overviewChartPanel.mask(lang_mco_overview[47]);
			MCO_overviewChartLoad();

			// 최근 이벤트
			MCO_overviewEventGrid.mask(lang_mco_overview[47]);
			MCO_overviewEventLoad();

			// 기존 챠트 제거
			if (typeof(clientChartObj) != 'undefined')
			{
				d3.select("#clientChartSvg-body svg").remove();
			}

			if (typeof(fsUsageChartObj) != 'undefined')
			{
				d3.select("#AvailableChartSvg-body svg").remove();
			}

			// 클라이언트 접속 현황
			MCO_overviewClientChartPanel.mask(lang_mco_overview[47]);
			MCO_overviewClientChart();

			// 클러스터 가용량
			Ext.getCmp('AvailableChartSvgNone').update('');
			MCO_overviewAvailableChartPanel.mask(lang_mco_overview[47]);
			MCO_overviewFsUsageChart();
		},
		items: [
			{
				xtype: 'BasePanel',
				layout: 'absolute',
				bodyStyle: 'padding: 20px;',
				autoScroll: true,
				items: [ MCO_overviewPanel ]
			}
		]
	}
);
