/* 챠트 관련 OBJ */
var fsUsageNodeChartObj;

var MNC_conditionCPUNum;
var MNC_conditionNetworkNum;
var MNC_conditionDiskNum;

/** Window Resize */
function MNC_conditionPanelResize()
{
	if (typeof(fsUsageNodeChartObj) != 'undefined')
	{
		fsUsageNodeChartObj.resize({
			width: Ext.get("AvailableNodeChartSvg").getWidth()
		});
	}
};

/** 노드 현황 데이터 로드 **/
function MNC_conditionDataLoad()
{
	GMS.Cors.request({
		url: '/api/cluster/general/nodedesc',
		method: 'POST',
		callback: function(options, success, response, decoded) {
			Ext.getCmp("MNC_conditionNodeTab").unmask();

			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				clearInterval(_nowCurrentConditionVar);
				_nowCurrentConditionVar = null;

				return;
			}

			// 노드 정보 데이터 로드
			var nodeInfo = decoded.entity.Descriptions;

			Ext.each(
				nodeInfo,
				function(record) {
					for (var property in record)
					{
						var value = record[property];
						var nodedata = '<li>' + property.toString()
										+ ': ' + value
										+ '</li><br>';

						if (property.toString() == 'Hostname')
						{
							Ext.getCmp('MNC_conditionNodeHostName').update(nodedata);
						}
						else if (property.toString() == 'Product Name')
						{
							Ext.getCmp('MNC_conditionNodeProductName').update(nodedata);
						}
						else if (property.toString() == 'Manufacturer')
						{
							Ext.getCmp('MNC_conditionNodeManufacturer').update(nodedata);
						}
						else if (property.toString() == 'CPU')
						{
							Ext.getCmp('MNC_conditionNodeCPU').update(nodedata);
						}
						else if (property.toString() == 'Memory')
						{
							Ext.getCmp('MNC_conditionNodeMemory').update(nodedata);
						}
						else if (property.toString() == 'Board')
						{
							Ext.getCmp('MNC_conditionNodeBoard').update(nodedata);
						}
						else if (property.toString() == 'AnyStor-E Version')
						{
							Ext.getCmp('MNC_conditionNodeVersion').update(nodedata);
						}
						else if (property.toString() == 'Status')
						{
							MNC_conditionNodeStatusStore.loadRawData(value, false);
						}
					}
				}
			);

			/** 주기적 갱신 **/
			clearInterval(_nowCurrentConditionVar);

			_nowCurrentConditionVar
				= setInterval(function() { MNC_conditionDataLoad() }, 10000);
		}
	});
};

/** 최근 이벤트 데이터 로드 **/
function MNC_conditionEventDataLoad()
{
	GMS.Ajax.request({
		url: '/api/cluster/event/list',
		method: 'POST',
		jsonData: {
			argument: {
				Scope: Ext.getCmp('content-main-node-combo').rawValue
			}
		},
		callback: function(options, success, response, decoded) {
			MNC_conditionEventGrid.unmask();

			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				clearInterval(_nowCurrentConditionEventVar);
				_nowCurrentConditionEventVar = null;

				return;
			}

			// 이벤트 스토어 로드
			MNC_conditionEventStore.loadRawData(decoded.entity, false);

			/** 주기적 갱신 **/
			clearInterval(_nowCurrentConditionEventVar);

			_nowCurrentConditionEventVar
				= setInterval(function() { MNC_conditionEventDataLoad() }, 10000);
		}
	});
};

/* 노드 가용량 챠트 */
function MNC_conditionFsUsageChart()
{
	GMS.Cors.request({
		url: '/api/dashboard/fsusage',
		method: 'POST',
		jsonData: {
			Scope: Ext.getCmp('content-main-node-combo').rawValue
		},
		callback: function(options, success, response, decoded) {
			MNC_conditionAvailableChart.unmask();

			if (!success || !decoded.success)
			{
				return;
			}

			// 노드 가용량 데이터가 없거나 가져올 수 없을 때
			if (decoded.entity.is_available == 'false')
			{
				Ext.getCmp('AvailableNodeChartSvg').hide();
				Ext.getCmp('AvailableNodeChartSvgNone').show();
			}
			else
			{
				Ext.getCmp('AvailableNodeChartSvg').show();
				Ext.getCmp('AvailableNodeChartSvgNone').hide();
			}

			var width = Ext.get('AvailableNodeChartSvg').getWidth() - 50;

			if (decoded.entity.data.length <= 0)
			{
				return;
			}

			var chartConfig = {
				chartId: 'AvailableNodeChartSvg-body',
				width: width,
				height: 230,
				margin: {
					left: 70,
					top: 10,
					right: 0,
					bottom: 35,
				},
				x: {
					grid: true
				},
				y: {
					label: lang_mnc_condition[30],
					tickformat: '%',
					grid: true,
				},
				legend: {
					position: 'bottom',
					shape: 'circle'
				},
				tooltip: {
					format: '.3s',
				},
				colors: ['#CCE386', '#4BDBAA'],
				barSpace: 0.2,
			};

			// 가용량 데이터 타입변경
			fsUsageNodeChartObj = new stackedBarChart(chartConfig);
			fsUsageNodeChartObj.drawChart(decoded.entity.data);
		},
	});
};

/** 클라이언트 접속 현황 데이터 로드 **/
function MNC_conditionClientDataLoad()
{
	GMS.Cors.request({
		url: '/api/cluster/general/clients',
		method: 'POST',
		callback: function(options, success, response, decoded) {
			MNC_conditionClientGrid.unmask();

			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				return;
			}

			// 클라이언트 접속 현황 데이터 로드
			MNC_conditionClientStore.loadRawData(decoded.entity, false);
		}
	});
};

function drawChart()
{
	// 출력할 현재 노드
	var currentNode    = Ext.getCmp('content-main-node-combo').rawValue.split('-');
	var currentNodeNum = parseInt(currentNode[1].replace(/[^\d]+/g, ''));

	// 챠트 범위 시간
	var from = Ext.getCmp('MNC_conditionAvailableType').getValue();

	// 챠트 주기
	var refresh = (from == 'now-1h' || from == 'now-24h') ? '10s' : '1d';

	/** 노드 현황 성능 챠트 **/

	/** CPU 성능 **/
	var MNC_conditionChartCPUObj
		= Ext.getCmp('MNC_conditionCPUNodeChartSvg')
			.child('#MNC_conditionCPUframe');

	if (!MNC_conditionChartCPUObj)
	{
		MNC_conditionCPUNum = parseInt(currentNodeNum) + 50 - 1;

		var url = getDashboardURI({
			ip: MASTER.host,
			name: 'anystor-node-graphs',
			panel_id: MNC_conditionCPUNum,
			from: from,
			refresh: refresh,
		});

		var frame = new Ext.ux.IFrame({
			id: 'MNC_conditionCPUframe',
			src: url,
			height: 220
		});

		Ext.getCmp('MNC_conditionCPUNodeChartSvg').add(frame);
	}

	/** 네트워크 성능 **/
	var MNC_conditionChartNetworkObj
		= Ext.getCmp('MNC_conditionNetworkNodeChartSvg')
			.child('#MNC_conditionNetworkframe');

	if (!MNC_conditionChartNetworkObj)
	{
		MNC_conditionNetworkNum = parseInt(currentNodeNum) + 100 - 1;

		var url = getDashboardURI({
			ip: MASTER.host,
			name: 'anystor-node-graphs',
			panel_id: MNC_conditionNetworkNum,
			from: from,
			refresh: refresh,
		});

		var frame = new Ext.ux.IFrame({
			id: 'MNC_conditionNetworkframe',
			src: url,
			height: 220,
		});

		Ext.getCmp('MNC_conditionNetworkNodeChartSvg').add(frame);
	}

	/** Disk I/O **/
	var MNC_conditionChartDiskObj
		= Ext.getCmp('MNC_conditionStorageNodeChartSvg')
			.child('#MNC_conditionDiskIOframe');

	if (!MNC_conditionChartDiskObj)
	{
		MNC_conditionDiskNum = parseInt(currentNodeNum) + 150 - 1;

		var url = getDashboardURI({
			ip: MASTER.host,
			name: 'anystor-node-graphs',
			panel_id: MNC_conditionDiskNum,
			from: from,
			refresh: refresh,
		});

		var frame = new Ext.ux.IFrame({
			id: 'MNC_conditionDiskIOframe',
			src: url,
			height: 220
		});

		Ext.getCmp('MNC_conditionStorageNodeChartSvg').add(frame);
	}
}

/** 성능 통계 챠트 **/
function MNC_conditionChartLoad()
{
	// 노드 관리 페이지
	var loadPage = 'manager_cluster_clusterNode';
	var record = Ext.getCmp('adminTreePanel').getStore().getNodeById(loadPage);

	// TREE 각 메뉴의 text값
	var treeText = record.raw.text;

	// TREE 각 메뉴의  ptext값
	var treePtext = record.raw.ptext;

	// 타이틀 버튼 제거
	Ext.getCmp('content-main-header-label')
		.update(treePtext + ' >> ' + '<span>' + treeText + '</span>' + ' >>');

	GMS.Ajax.request({
		url: '/api/cluster/general/master',
		method: 'POST',
		callback: function(options, success, response, decoded) {
			MNC_conditionChartPanel.unmask();

			if (!success || !decoded.success)
			{
				// 주기적 갱신 제거
				clearInterval(_nowCurrentConditionChartVar);
				_nowCurrentConditionChartVar = null;

				for (var i=0
					; i < Ext.getCmp('MCC_cnNodeTab').items.keys.length
					; i++)
				{
					Ext.getCmp('MCC_cnNodeTab').items.getAt(i)
						.setDisabled(false);
				}

				return;
			}

			var targets = [];

			targets.push(
				decoded.entity.Mgmt_IP,
				decoded.entity.Storage_IP);

			targets = targets.concat(decoded.entity.Service_IP);

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
							clearInterval(_nowCurrentConditionChartVar);

							_nowCurrentConditionChartVar = setInterval(
								function () { MNC_conditionChartLoad() },
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
								MNC_conditionChartPanel.unmask();

								for (var i=0
									; i<Ext.getCmp('MCC_cnNodeTab').items.keys.length
									; i++)
								{
									Ext.getCmp('MCC_cnNodeTab').items.getAt(i)
										.setDisabled(false);
								}

								Ext.getCmp('content-main-header-label').update(
									treePtext + ' >> '
									+ '<span class="header-link" onclick="pageChange()">'
									+ treeText
									+ '</span>' + ' >>'
								);

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
		}
	});
}

/** 노드별 현황 노드 정보 PANEL **/
var MNC_conditionNodePanel = Ext.create(
	'BasePanel',
	{
		id: 'MNC_conditionNodePanel',
		title: lang_mnc_condition[2],
		autoScroll: true,
		items: [
			{
				xtype: 'label',
				id: 'MNC_conditionNodeHostName',
			},
			{
				xtype: 'label',
				id: 'MNC_conditionNodeVersion',
			},
			{
				xtype: 'label',
				id: 'MNC_conditionNodeProductName',
			},
			{
				xtype: 'label',
				id: 'MNC_conditionNodeManufacturer',
			},
			{
				xtype: 'label',
				id: 'MNC_conditionNodeCPU',
			},
			{
				xtype: 'label',
				id: 'MNC_conditionNodeMemory',
			},
			{
				xtype: 'label',
				id: 'MNC_conditionNodeBoard',
			},
		]
	}
);

/** 이벤트 그리드 **/
//이벤트 ROW 선택시 상세 보기
var MNC_conditionEventWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNC_conditionEventWindow',
		title: lang_mnc_condition[37],
		maximizable: false,
		autoHeight: true,
		width: 600,
		minHeight: 300,
		layout: { type: 'vbox', align: 'stretch' },
		items: [
			{
				xtype: 'label',
				id: 'MNC_conditionEventWindowLabel',
				flex: 1,
			}
		],
		buttons: [
			{
				id: 'MNC_conditionEventWindowCloseBtn',
				text: lang_mnc_condition[38],
				handler: function () {
					MNC_conditionEventWindow.hide();
				}
			}
		],
	}
);

// 이벤트 모델
Ext.define(
	'MNC_conditionEventModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'ID', 'Scope', 'Category', 'Level',
			'Message', 'Details', 'Time', 'Quiet'
		]
	}
);

// 이벤트 스토어
var MNC_conditionEventStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNC_conditionEventModel',
		sorters: [
			{
				property: 'Time',
				direction: 'DESC',
			}
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
	}
);

// 이벤트 그리드
var MNC_conditionEventGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNC_conditionEventGrid',
		store: MNC_conditionEventStore,
		multiSelect: false,
		height: 270,
		title: lang_mnc_condition[39],
		cls: 'line-break',
		header: {
			titlePosition: 0,
			items:[
				{
					xtype:'button',
					id: 'MNC_conditionEventBtn',
					style: { marginRight: '5px' },
					text: lang_mnc_condition[40],
					handler: function () {
						var record = Ext.getCmp('adminTreePanel')
										.getStore()
										.getNodeById('manager_cluster_event');

						Ext.getCmp('adminTreePanel')
							.getSelectionModel()
							.select(record);
					}
				}
			],
		},
		columns: [
			{
				text: lang_mnc_condition[36],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Level',
				width: 50,
				align: 'center',
				xtype: 'actioncolumn',
				items: [
					{
						getClass: function (v, meta, record)
						{
							if (record.get('Level') == 'OK'
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
					},
				],
			},
			{
				flex: 1,
				text: lang_mnc_condition[41],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Time'
			},
			{
				flex: 2,
				text: lang_mnc_condition[42],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Message',
			},
			{
				flex: 1,
				text: lang_mnc_condition[43],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Scope',
			},
			{
				flex: 1,
				text: lang_mnc_condition[44],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Category',
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () {
					MNC_conditionEventWindow.show();
					Ext.getCmp("MNC_conditionEventWindowLabel").update();
					var detailsObj = record.data;
					var prettyJson = library.json.prettyPrint(detailsObj);
					Ext.getCmp("MNC_conditionEventWindowLabel").update(prettyJson);
				}, 200);
			},
		},
	}
);

/** 노드별 현황 클라이언트 그리드 **/
// 클라이언트 모델
Ext.define(
	'MNC_conditionClientModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Type', 'Address']
	}
);

// 클라이언트 스토어
var MNC_conditionClientStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNC_conditionClientModel',
		actionMethods: {
			read: 'POST'
		},
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			}
		}
	}
);

// 클라이언트 그리드
var MNC_conditionClientGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNC_conditionClientGrid',
		store: MNC_conditionClientStore,
		multiSelect: false,
		height: 300,
		title: lang_mnc_condition[18],
		columns: [
			{
				flex: 1,
				text: lang_mnc_condition[19],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Type'
			},
			{
				flex: 1,
				text: lang_mnc_condition[20],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Address'
			}
		],
		listeners: {
			beforeselect: function () {
				return false;
			}
		}
	}
);

/** 노드 가용량 챠트 **/
var MNC_conditionAvailableChart = Ext.create(
	'BasePanel',
	{
		id: 'MNC_conditionAvailableChart',
		frame: true,
		title: lang_mnc_condition[30],
		height: 300,
		items: [
			{
				xtype: 'BasePanel',
				id: 'AvailableNodeChartSvg',
				height: 240,
				bodyStyle: { padding: 0 },
				layout: 'fit',
				overflowX: 'hidden',
				overflowY: 'hidden',
			},
			{
				xtype: 'BasePanel',
				id: 'AvailableNodeChartSvgNone',
				height:240,
				layout: 'fit',
				bodyStyle: { padding: 0 },
				hidden: true,
				overflowX: 'hidden',
				overflowY: 'hidden',
				bodyCls: 'm-panel-center',
				html: lang_mnc_condition[35],
			}
		],
	}
);

/** 성능통계 PANEL **/
var MNC_conditionChartPanel = Ext.create(
	'BasePanel',
	{
		id: 'MNC_conditionChartPanel',
		title: lang_mnc_condition[23],
		frame: true,
		height: 290,
		style: {
			marginBottom: '20px'
		},
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'BaseComboBox',
					hideLabel: true,
					id: 'MNC_conditionAvailableType',
					name: 'conditionAvailableType',
					store: new Ext.data.SimpleStore({
							fields: ['Type', 'Code'],
							data: [
								[lang_mnc_condition[24], 'now-1h'],
								[lang_mnc_condition[25], 'now-24h'],
								[lang_mnc_condition[26], 'now-7d'],
								[lang_mnc_condition[27], 'now-1M'],
								[lang_mnc_condition[28], 'now-6M'],
								[lang_mnc_condition[29], 'now-1y']
							]
					}),
					value: 'now-1h',
					displayField: 'Type',
					valueField: 'Code',
					listeners: {
						change: function (combo, newValue, oldValue) {
							if (!newValue || !oldValue)
								return;

							var refresh
								= (newValue == 'now-1h' || newValue == 'now-24h')
									? '10s' : '1d';

							Ext.getCmp('MNC_conditionCPUframe').iframeEl.dom.src
								= getDashboardURI({
									ip: MASTER.host,
									name: 'anystor-node-graphs',
									panel_id: MNC_conditionCPUNum,
									from: newValue,
									refresh: refresh,
								});

							Ext.getCmp('MNC_conditionNetworkframe').iframeEl.dom.src
								= getDashboardURI({
									ip: MASTER.host,
									name: 'anystor-node-graphs',
									panel_id: MNC_conditionNetworkNum,
									from: newValue,
									refresh: refresh,
								});

							Ext.getCmp('MNC_conditionDiskIOframe').iframeEl.dom.src
								= getDashboardURI({
									ip: MASTER.host,
									name: 'anystor-node-graphs',
									panel_id: MNC_conditionDiskNum,
									from: newValue,
									refresh: refresh,
								});
						}
					}
				},
			],
		},
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		items: [
			{
				xtype: 'BasePanel',
				id: 'MNC_conditionCPUNodeChartSvg',
				flex: 1,
				bodyStyle: { padding: 0 },
				overflowX: 'hidden',
				overflowY: 'hidden',
			},
			{
				xtype: 'BasePanel',
				id: 'MNC_conditionCPUNodeChartSvgNone',
				width: 20,
				bodyStyle: { padding: 0 },
				html: '&nbsp;',
			},
			{
				xtype: 'BasePanel',
				id: 'MNC_conditionStorageNodeChartSvg',
				flex: 1,
				bodyStyle: { padding: 0 },
				overflowX: 'hidden',
				overflowY: 'hidden',
			},
			{
				xtype: 'BasePanel',
				id: 'MNC_conditionStorageNodeChartSvgNone',
				width: 20,
				bodyStyle: { padding: 0 },
				html: '&nbsp;',
			},
			{
				xtype: 'BasePanel',
				id: 'MNC_conditionNetworkNodeChartSvg',
				flex: 1,
				bodyStyle: { padding: 0 },
				overflowX: 'hidden',
				overflowY: 'hidden',
			},
		],
		listeners: {
			resize: {
				fn: function (el) {
					MNC_conditionPanelResize();
				}
			}
		}
	}
);

// 노드 상태 모델
Ext.define(
	'MNC_conditionNodeStatusModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Status', 'Category', 'Resource']
	}
);

// 노드 상태 스토어
var MNC_conditionNodeStatusStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNC_conditionNodeStatusModel',
		groupDir : 'ASC',
		groupField: 'Category',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			},
		}
	}
);

// 노드 상태 그리드
var MNC_conditionNodeStatusGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNC_conditionNodeStatusGrid',
		title: lang_mnc_condition[48],
		store: MNC_conditionNodeStatusStore,
		multiSelect: false,
		frame: false,
		cls: 'line-break',
		border: true,
		features: [
			Ext.create(
				'Ext.grid.feature.Grouping',
				{
					groupHeaderTpl: '{name}'
				}
			)
		],
		listeners: {
			beforeselect: function () {
				return false;
			}
		},
		columns: [
			{
				text: lang_mnc_condition[36],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Status',
				width: 50,
				align: 'center',
				xtype: 'actioncolumn',
				items: [
					{
						getClass: function (v, meta, record) {
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
			},
			{
				flex: 1,
				text: lang_mnc_condition[49],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Resource',
			},
		],
	}
);

var MNC_conditionPanel = Ext.create(
	'BasePanel',
	{
		id: 'MNC_conditionPanel',
		layout: {
			type: 'vbox',
			align : 'stretch',
		},
		bodyStyle: {
			padding: 0,
		},
		items: [
			{
				xtype: 'BasePanel',
				layout: 'fit',
				bodyStyle: {
					padding: 0,
				},
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						layout: {
							type: 'hbox',
							pack: 'start',
							align : 'stretch',
						},
						bodyStyle: {
							padding: 0,
						},
						items: [
							{
								xtype: 'tabpanel',
								id: 'MNC_conditionNodeTab',
								layout: 'fit',
								style: { marginRight: '20px' },
								height: 590,
								width: 400,
								activeTab: 0,
								frame: true,
								bodyStyle: {
									padding: 0,
									border: '1px solid #d0d0d0',
								},
								items: [
									MNC_conditionNodeStatusGrid,
									MNC_conditionNodePanel,
								],
								listeners: {
									tabchange: function () {
										Ext.getCmp('MNC_conditionNodeStatusGrid')
											.view.getEl().scrollTo('top', 0);
									},
								},
							},
							{
								xtype: 'BasePanel',
								layout: {
									type: 'vbox',
									align : 'stretch',
								},
								bodyStyle: {
									padding: 0,
								},
								flex: 1,
								defaults: { bodyStyle: { padding: 0 } },
								items: [
									{
										xtype: 'BasePanel',
										style: { marginBottom: '20px' },
										items: [ MNC_conditionEventGrid ],
									},
									{
										xtype: 'BasePanel',
										layout: {
											type: 'hbox',
											pack: 'start',
											align : 'stretch',
										},
										bodyStyle: {
											padding: 0,
										},
										items: [
											{
												xtype: 'BasePanel',
												bodyStyle: {
													padding: 0,
												},
												flex: 2,
												style: { marginRight: '20px' },
												items: [ MNC_conditionClientGrid ],
											},
											{
												xtype: 'BasePanel',
												layout: 'fit',
												bodyStyle: {
													padding: 0,
												},
												flex: 5,
												items: [ MNC_conditionAvailableChart ],
											},
										]
									}
								]
							}
						]
					}
				],
			},
			{
				xtype: 'BasePanel',
				layout: 'fit',
				flex: 1,
				bodyStyle: {
					padding: 0,
				},
				items: [ MNC_conditionChartPanel ]
			}
		],
	}
);

// 노드별 현황
Ext.define(
	'/admin/js/manager_node_condition',
	{
		extend: 'BasePanel',
		id: 'manager_node_condition',
		load: function() {
			// 최근 이벤트 제거
			MNC_conditionEventStore.removeAll();

			// 클라이언트 접속 현황 제거
			MNC_conditionClientStore.removeAll();

			//기존 가용량 챠트 제거
			if (typeof(fsUsageNodeChartObj) != 'undefined')
			{
				d3.select("#AvailableNodeChartSvg-body svg").remove();
			}

			//노드 상태 선택
			Ext.getCmp("MNC_conditionNodeTab").setActiveTab(0);
			Ext.getCmp("MNC_conditionNodeTab").mask(lang_mnc_condition[52]);
			MNC_conditionDataLoad();

			// 클라이언트 접속 현황
			MNC_conditionClientGrid.mask(lang_mnc_condition[52]);
			MNC_conditionClientDataLoad();

			// 최신 이벤트
			MNC_conditionEventGrid.mask(lang_mnc_condition[52]);
			MNC_conditionEventDataLoad();

			//가용량 챠트
			MNC_conditionAvailableChart.mask(lang_mnc_condition[52]);
			MNC_conditionFsUsageChart();

			//성능 통계 차트
			//기존 챠트 OBJ 제거
			if (Ext.getCmp('MNC_conditionCPUframe'))
			{
				Ext.getCmp('MNC_conditionCPUNodeChartSvg')
					.remove(Ext.getCmp('MNC_conditionCPUframe'), true);
			}

			if (Ext.getCmp('MNC_conditionNetworkframe'))
			{
				Ext.getCmp('MNC_conditionNetworkNodeChartSvg')
					.remove(Ext.getCmp('MNC_conditionNetworkframe'), true);
			}

			if (Ext.getCmp('MNC_conditionDiskIOframe'))
			{
				Ext.getCmp('MNC_conditionStorageNodeChartSvg')
					.remove(Ext.getCmp('MNC_conditionDiskIOframe'), true);
			}

			// 성능 통계 주기를 기본으로 설정
			var MNC_conditionAvailableObj = Ext.getCmp('MNC_conditionAvailableType');

			MNC_conditionAvailableObj.setValue(
				MNC_conditionAvailableObj.getStore()
					.getAt(0)
					.get(MNC_conditionAvailableObj.valueField),
				true
			);

			MNC_conditionChartPanel.mask(lang_mnc_condition[52]);

			MNC_conditionChartLoad();
		},
		bodyStyle: {
			padding: 0,
		},
		items: [
			{
				xtype: 'BasePanel',
				id: 'manager_node_condition_panel',
				layout: 'absolute',
				autoScroll: true,
				bodyStyle: {
					padding: '20px',
				},
				items: [MNC_conditionPanel],
			}
		]
	}
);
