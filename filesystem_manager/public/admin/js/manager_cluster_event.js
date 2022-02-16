/**
페이지로드시 실행함수
**/
function MCE_eventLoad()
{
	MCE_eventStore.load();
	MCE_eventTaskStore.load();
	MCE_nodeListStore.load();

	Ext.getCmp('MCE_eventLevel').reset();
	Ext.getCmp('MCE_eventType').reset();
	Ext.getCmp('MCE_eventCategory').reset();
	Ext.getCmp('MCE_eventScope').reset();
	Ext.getCmp('MCE_eventLevel').reset();
	Ext.getCmp('MCT_eventDateFrom').reset();
	Ext.getCmp('MCT_eventDateTo').reset();
	Ext.getCmp('MCE_eventLimitCount').reset();
	Ext.getCmp('MCE_eventSearchStr').reset();
};

// 노드명 정렬
Ext.apply(Ext.data.SortTypes, {
	asHostName: function (hostname){
		if(hostname == 'cluster')
		{
			return 0;
		}
		else
		{
			var hostnameData = hostname.split('-');
			var hostnameNumber = parseInt(hostnameData[1]);
			return hostnameNumber;
		}
	}
});

// 노드 관리 메뉴의 Combo Model, Store
Ext.define(
	'MCE_nodeListModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Mgmt_Hostname', sortType: 'asHostName' },
			'Mgmt_IP'
		]
	}
);

var MCE_nodeListStore = Ext.create('Ext.data.Store', {
	model: 'MCE_nodeListModel',
	sorters: [
		{
			property: 'Mgmt_Hostname',
			direction: 'ASC'
		}
	],
	proxy: {
		type: 'ajax',
		url: '/api/cluster/nodes',
		reader: {
			type: 'json',
			idProperty: 'Mgmt_Hostname',
			root: 'entity'
		}
	},
	listeners: {
		beforeload: function (store, operation, eOpts) {
			store.removeAll();
		},
		load: function (store, records, success) {
			if (success == true)
			{
				Ext.getCmp('MCE_eventScope').setDisabled(false);
			}
			else
			{
				Ext.getCmp('MCE_eventScope').setDisabled(true);
				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lanwg_mce_event[0] + '",'
					+ '"content": "' + lang_mce_event[33] + '",'
					+ '"response": ' + jsonText
				+ '}';

				exceptionDataCheck(checkValue);
			}
		}
	}
});

/**
이벤트 목록
**/
// 이벤트 ROW 선택 시 상세 보기
var MCE_eventWindow = Ext.create('BaseWindowPanel', {
	id: 'MCE_eventWindow',
	title: lang_mce_event[2],
	maximizable: false,
	autoHeight: true,
	width: 600,
	minHeight: 260,
	layout: { type: 'vbox', align: 'stretch' },
	items: [
		{
			xtype: 'label',
			id: 'MCE_eventWindowLabel',
			flex: 1
		}
	],
	buttons: [
		{
			id: 'MCE_eventWindowCloseBtn',
			text: lang_mce_event[3],
			handler: function () {
				MCE_eventWindow.hide();
			}
		}
	]
});

// 이벤트 목록 모델
Ext.define('MCE_eventModel',{
	extend: 'Ext.data.Model',
	fields: [
		'ID',
		{
			name: 'Scope',
			sortType: 'asHostName'
		},
		'Type',
		'Level',
		'Category',
		'Message',
		'Details',
		'Time',
		'Quiet'
	]
});

// 이벤트 목록 스토어
var MCE_eventStore = Ext.create('Ext.data.Store', {
	model: 'MCE_eventModel',
	remoteFilter: 'true',
	sorters: [
		{
			property: 'Time',
			direction: 'DESC'
		}
	],
	proxy: {
		type: 'ajax',
		url: '/api/cluster/event/list',
		reader: {
			type: 'json',
			root: 'entity',
			totalProperty: 'total',
		}
	},
	listeners: {
		beforeload: function (store, operation, eOpts) {
			store.removeAll();

			store.proxy.setExtraParam('level', Ext.getCmp('MCE_eventLevel').getValue());
			store.proxy.setExtraParam('type', Ext.getCmp('MCE_eventType').getValue());
			store.proxy.setExtraParam('category', Ext.getCmp('MCE_eventCategory').getValue());

			if (Ext.getCmp('MCE_eventScope').getValue() == lang_mce_event[22])
			{
				store.proxy.setExtraParam('scope', '');
			}
			else
			{
				store.proxy.setExtraParam('scope', Ext.getCmp('MCE_eventScope').getValue());
			}

			store.proxy.setExtraParam('from', Ext.getCmp('MCT_eventDateFrom').getValue());
			store.proxy.setExtraParam('to', calibrate_todate(Ext.getCmp('MCT_eventDateTo').getValue()));
			store.proxy.setExtraParam('limit', Ext.getCmp('MCE_eventLimitCount').getValue());

			MCE_eventStore.pageSize =  Ext.getCmp('MCE_eventLimitCount').value;
		},
		load: function (store, records, success) {
			if (success !== true)
			{
				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mce_event[0] + '",'
					+ '"content": "' + lang_mce_event[1] + '",'
					+ '"response": ' + jsonText
				+ '}';

				exceptionDataCheck(checkValue);
			}
		}
	}
});

// 이벤트 목록 그리드
var MCE_eventGrid = Ext.create('BaseGridPanel', {
	id: 'MCE_eventGrid',
	store: MCE_eventStore,
	multiSelect: false,
	title: lang_mce_event[4],
	style: { marginBottom: '20px' },
	cls: 'line-break',
	viewConfig: {
		forceFit: true,
		loadMask: true,
		trackOver: false
	},
	columns: [
		{
			dataIndex: 'ID',
			hidden : true
		},
		{
			text: lang_mce_event[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Level',
			width: 50,
			align: 'center',
			xtype: 'actioncolumn',
			items: [
				{
					getClass: function (v, meta, record) {
						if (record.get('Level') == "OK" || record.get('Level') == 'INFO')
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
			text: lang_mce_event[8],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Time'
		},
		{
			flex: 3,
			text: lang_mce_event[9],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Message'
		},
		{
			flex: 1,
			text: lang_mce_event[6],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Scope'
		},
		{
			flex: 1,
			text: lang_mce_event[7],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Type'
		},
		{
			flex: 1,
			text: lang_mce_event[28],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Category'
		}
	],
	tbar: [
		lang_mce_event[17] + ': ',
		{
			xtype: 'BaseComboBox',
			hideLabel: true,
			id: 'MCE_eventLevel',
			hiddenName: 'eventLevel',
			name: 'eventLevel',
			width: 100,
			store: new Ext.data.SimpleStore({
				fields: ['LevelType', 'LevelCode', 'LevelImage'],
				data: [
					[lang_mce_event[22], '', ''],
					[lang_mce_event[18], 'INFO', '<i class="state_ok"/>'],
					[lang_mce_event[19], 'WARN', '<i class="state_warn"/>'],
					[lang_mce_event[20], 'ERR', '<i class="state_err"/>']
				]
			}),
			value: '',
			displayField: 'LevelType',
			valueField: 'LevelCode',
			listConfig: {
				getInnerTpl: function () {
					return '<table width="100%">'+
								'<tr>'+
									'<td style="vertical-align:top;width:100%">'+
										'<div><span style="float:left">{LevelType}&nbsp;&nbsp;</span><span style="float:right">{LevelImage}</span></div>'+
									'</td>'+
								'</tr>'+
							'</table>';
				}
			},
			listeners: {
				change: function (combo, newValue, oldValue){
					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			}
		},
		lang_mce_event[21] + ': ',
		{
			xtype: 'BaseComboBox',
			id: 'MCE_eventScope',
			displayField: 'Mgmt_Hostname',
			valueField: 'Mgmt_Hostname',
			value: lang_mce_event[22],
			store: MCE_nodeListStore,
			editable: false,
			width: 100,
			listeners: {
				change: function (combo, newValue, oldValue) {
					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			}
		},
		lang_mce_event[23] + ': ',
		{
			xtype: 'BaseComboBox',
			hideLabel: true,
			id: 'MCE_eventType',
			hiddenName: 'eventType',
			name: 'eventType',
			store: new Ext.data.SimpleStore({
				fields: ['TypeType', 'TypeCode'],
				data: [
					[lang_mce_event[22], ''],
					['COMMAND', 'COMMAND'],
					['MONITOR','MONITOR']
				]
			}),
			value: '',
			displayField: 'TypeType',
			valueField: 'TypeCode',
			width: 100,
			listeners: {
				change: function (combo, newValue, oldValue) {
					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			}
		},
		lang_mce_event[28] + ': ',
		{
			xtype: 'BaseComboBox',
			hideLabel: true,
			id: 'MCE_eventCategory',
			hiddenName: 'eventCategory',
			name: 'eventCategory',
			store: new Ext.data.SimpleStore({
				fields: ['CategoryType', 'CategoryCode'],
				data: [
					[lang_mce_event[22], ''],
					['ACCOUNT', 'ACCOUNT'],
					['NETWORK', 'NETWORK'],
					['SHARE', 'SHARE'],
					['VOLUME', 'VOLUME'],
					['INITIALIZE', 'INITIALIZE'],
					['DEFAULT', 'DEFAULT']
				]
			}),
			value: '',
			displayField: 'CategoryType',
			valueField: 'CategoryCode',
			width: 100,
			listeners: {
				change: function (combo, newValue, oldValue) {
					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			}
		},
		lang_mce_event[24] + ': ',
		{
			xtype: 'datefield',
			id: 'MCT_eventDateFrom',
			name: 'evnetDateFrom',
			hideLabel: true,
			format: 'Y/m/d',
			altFormats: 'Y-m-d',
			editable: false,
			width: 120,
			listeners: {
				change: function (combo, newValue, oldValue) {
					var from = Ext.getCmp('MCT_eventDateFrom').getValue();
					var to   = Ext.getCmp('MCT_eventDateTo').getValue();

					if (to - from < 0)
					{
						Ext.MessageBox.alert(lang_mce_event[0], lang_mce_event[29]);
						Ext.getCmp('MCT_eventDateFrom').setValue(to);
					}

					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			},
			onTriggerClick: function () {
				var dt1 = this;
				Ext.form.DateField.prototype.onTriggerClick.apply(dt1, arguments);

				if (Ext.isEmpty(dt1.clearBtn))
				{
					this.clearBtn = new Ext.Button({
						text: 'Clear',
						handler: function () {
							dt1.setValue('');
							dt1.picker.hide();
							dt1.collapse();
						},
						renderTo: dt1.picker.todayBtn.container,
						ownerCt: dt1.picker
					});
				}
			}
		},
		'~',
		{
			xtype: 'datefield',
			id: 'MCT_eventDateTo',
			name: 'eventDateTo',
			hideLabel: true,
			format: 'Y/m/d',
			altFormats: 'Y-m-d',
			editable: false,
			width: 120,
			value: Ext.Date.format(new Date(), 'Y/m/d'),
			listeners: {
				change: function (combo, newValue, oldValue) {
					var from = Ext.getCmp('MCT_eventDateFrom').getValue();
					var to   = Ext.getCmp('MCT_eventDateTo').getValue();

					if (to - from < 0)
					{
						Ext.MessageBox.alert(lang_mce_event[0], lang_mce_event[30]);
						Ext.getCmp('MCT_eventDateTo').setValue(from);
					}

					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			}
		},
		lang_mce_event[25] + ': ',
		{
			xtype: 'searchfield',
			id: 'MCE_eventSearchStr',
			store: MCE_eventStore,
			paramName: 'message',
			width: 180
		},
		'->',
		lang_mce_event[26] + ': ',
		{
			xtype: 'BaseComboBox',
			id: 'MCE_eventLimitCount',
			name: 'eventLimitCount',
			width: 80,
			store: new Ext.data.SimpleStore({
				fields: ['limitValue', 'limitView'],
				data: [
					['10', '10'],
					['25', '25'],
					['50', '50']
				]
			}),
			value: '10',
			displayField: 'limitView',
			valueField: 'limitValue',
			listeners: {
				change: function (combo, newValue, oldValue) {
					Ext.getCmp('MCE_eventPagingToolbar').doRefresh();
				}
			}
		}
	],
	bbar: new Ext.PagingToolbar({
		store: MCE_eventStore,
		id: 'MCE_eventPagingToolbar',
		displayInfo: true,
		displayMsg: '{0} - {1} of {2}',
		doRefresh : function () {
			var me = this;
			var current = me.store.currentPage;

			if (me.fireEvent('beforechange', me, current) !== false)
			{
				me.store.loadPage(1);
			}
		},
		listeners: {
			afterrender: function () {
				this.insert(
					this.items.length-2,
					new Ext.Button({
						id: 'MCT_eventDelete',
						name: 'eventDelete',
						iconCls: 'b-icon-format',
						text: lang_mce_event[33],
						width: 80,
						handler: function () {
							Ext.MessageBox.confirm(
								lang_mce_event[34],
								lang_mce_event[35],
								function (btnId, text, opt)
								{
									if (btnId !== 'yes')
									{
										/*
											* Ext.MessageBox.CANCEL이 정상
											* 표기 안됨
											*/
										Ext.MessageBox.show({
											title: lang_common[8],
											msg: lang_mce_event[37],
											buttons: Ext.Msg.OK,
											icon: Ext.MessageBox.CANCEL
										});

										return;
									}

									/* 이벤트 삭제 처리
										*
										* 1. API 요청을 통해 이벤트 삭제
										* 2. 스토어에 있는 이벤트 삭제
										*/
									waitWindow(lang_mce_event[34], lang_mce_event[38]);

									var from     = Ext.getCmp('MCT_eventDateFrom').getValue();
									var to       = Ext.getCmp('MCT_eventDateTo').getValue();
									var type     = Ext.getCmp('MCE_eventType').getValue();
									var category = Ext.getCmp('MCE_eventCategory').getValue();
									var scope    = Ext.getCmp('MCE_eventScope').getValue();
									var level    = Ext.getCmp('MCE_eventLevel').getValue();

									// MCE_eventScope의 경우, 기본값이
									// "전체"라는 문자열로 되어 있음. 왜?
									if (scope == lang_mce_event[22])
									{
										scope = '';
									}

									GMS.Ajax.request({
										url: '/api/cluster/event/delete',
										jsonData: {
											From: from,
											To: calibrate_todate(to),
											Type: type,
											Category: category,
											Scope: scope,
											Level: level,
										},
										callback: function (options, success, response, decoded) {
											if (waitMsgBox)
											{
												// 데이터 전송 완료 후 wait 제거
												waitMsgBox.hide();
												waitMsgBox = null;
											}

											// 요청은 했으나, API가 실패한
											// 경우에 대한 예외 처리 동작
											if (!success || !decoded.success)
											{
												if (typeof(response.responseText) == 'undefined'
													|| response.responseText == '')
												{
													response.responseText = '{}';
												}

												var checkValue = '{'
													+ '"title": "' + lang_mce_event[20] + '",'
													+ '"content": "' + lang_mce_event[40] + '",'
													+ '"response": ' + response.responseText
												+ '}';

												return exceptionDataCheck(checkValue);
											}

											MCE_eventLoad();

											Ext.MessageBox.show({
												title: lang_mce_event[34],
												msg: lang_mce_event[39] + ': ' + decoded.entity,
												buttons: Ext.Msg.OK,
												icon: Ext.MessageBox.INFO
											});
										},
									});
								}
							);
						}
					})
				);
			}
		}
	}),
	listeners: {
		cellclick: function (gridView, htmlElement, columnIndex, dataRecord) {
			if (columnIndex == 6)
				return;

			var record = dataRecord.data;

			delete record.ID;
			delete record.Quiet;

			Ext.defer(function () {
				MCE_eventWindow.show();
				Ext.getCmp("MCE_eventWindowLabel").update();

				var detailsObj = record;
				var prettyJson = library.json.prettyPrint(detailsObj);

				Ext.getCmp("MCE_eventWindowLabel").update(prettyJson);
			}, 200);
		}
	}
});

/** 오버뷰 태스크 그리드 **/
// 태스크 ROW 선택시 상세 보기
var MCE_eventTaskWindow = Ext.create('BaseWindowPanel', {
	id: 'MCE_eventTaskWindow',
	title: lang_mce_event[14],
	maximizable: false,
	autoHeight: true,
	width: 600,
	minHeight: 260,
	layout: { type: 'vbox', align: 'stretch' },
	items: [
		{
			xtype: 'label',
			id: 'MCE_eventTaskWindowLabel',
			flex: 1
		}
	],
	buttons: [
		{
			id: 'MCE_eventTaskWindowCloseBtn',
			text: lang_mce_event[3],
			handler: function () {
				MCE_eventTaskWindow.hide();
			}
		}
	]
});

// 태스크 모델
Ext.define('MCE_eventTaskModel', {
	extend: 'Ext.data.Model',
	fields: ['ID', 'Scope', 'Level', 'Category', 'Message', 'Details', 'Start', 'Finish', 'Progress', 'Quiet']
});

//태스크 스토어
var MCE_eventTaskStore = Ext.create('Ext.data.Store', {
	model: 'MCE_eventTaskModel',
	sorters: [
		{
			property: 'Time',
			direction: 'DESC'
		}
	],
	proxy: {
		type: 'ajax',
		url: '/api/cluster/task/list',
		reader: {
			type: 'json',
			root: 'entity',
			totalProperty: 'total'
		}
	},
	listeners: {
		beforeload: function (store, operation, eOpts) {
			store.removeAll();
		},
		load: function (store, records, success) {
			if (success == true)
				return;

			// 예외 처리에 따른 동작
			var jsonText = JSON.stringify(store.proxy.reader.rawData);

			if (typeof(jsonText) == 'undefined')
				jsonText = '{}';

			var checkValue = '{'
				+ '"title": "' + lang_mce_event[0] + '",'
				+ '"content": "' + lang_mce_event[32] + '",'
				+ '"response": ' + jsonText
			+ '}';

			exceptionDataCheck(checkValue);
	}
	}
});

// 태스크 그리드
var MCE_eventTaskGrid = Ext.create('BaseGridPanel', {
	id: 'MCE_eventTaskGrid',
	store: MCE_eventTaskStore,
	multiSelect: false,
	title: lang_mce_event[10],
	cls: 'line-break',
	viewConfig: {
		forceFit: true,
		loadMask: true,
		trackOver: false
	},
	columns: [
		{
			dataIndex: 'ID',
			hidden : true
		},
		{
			text: lang_mce_event[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Level',
			width: 50,
			align: 'center',
			xtype: 'actioncolumn',
			items: [
				{
					getClass: function (v, meta, record) {
						if (record.get('Level') == "OK" || record.get('Level') == 'INFO')
						{
							return 'state_ok';
						}
						else if(record.get('Level') == 'WARNING')
						{
							return 'state_warn';
						}
						else if(record.get('Level') == 'ERROR')
						{
							return 'state_err';
						}
					}
				}
			]
		},
		{
			flex: 1,
			text: lang_mce_event[11],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Start'
		},
		{
			flex: 1,
			text: lang_mce_event[12],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Finish'
		},
		{
			flex: 2.5,
			text: lang_mce_event[9],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Message'
		},
		{
			flex: 1,
			text: lang_mce_event[6],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Scope'
		},
		{
			flex: 1,
			text: lang_mce_event[7],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Category'
		},
		{
			xtype: 'componentcolumn',
			flex: 1,
			text: lang_mce_event[13],
			sortable : true,
			menuDisabled : true,
			dataIndex: 'Progress',
			renderer: function (v, m, r) {
				return { xtype: 'progressbar', value: parseFloat(v) /100, text: v+'%' };
			}
		},
	],
	bbar: new Ext.PagingToolbar({
		pageSize: 50,
		store: MCE_eventTaskStore,
		id: 'MCE_eventTaskPagingToolbar',
		displayInfo: true,
		displayMsg: '{0} - {1} of {2}'
	}),
	listeners: {
		itemclick: function (grid, record, item, index, e) {
			delete record.data.ID;
			delete record.data.Type;
			delete record.data.Progress;
			delete record.data.Quiet;

			Ext.defer(function () {
				MCE_eventTaskWindow.show();
				Ext.getCmp("MCE_eventTaskWindowLabel").update();

				//var detailsObj = eval("("+record.data.Details+")");
				var detailsObj = record.data;
				var prettyJson = library.json.prettyPrint(detailsObj);

				Ext.getCmp("MCE_eventTaskWindowLabel").update(prettyJson);
			}, 200);
		}
	}
});

// 이벤트 히스토리 검색/삭제 시, 범위 끝 시간에 대한 보정을 수행하는 함수
function calibrate_todate(to)
{
	// 선택된 시간 보정
	// - 시간 차이가 1일 초과일 경우 +1일 -1초
	// ex:
	//   now    : 2018-10-31 18:31:12
	//   to     : 2018-10-20 00:00:00
	//   result : 2018-10-20 23:59:59
	//
	// - 시간 차이가 1일 이하일 경우 현재 시간으로 보정
	// ex:
	//   now    : 2018-10-31 18:31:12
	//   to     : 2018-10-31 00:00:00
	//   result : 2018-10-31 18:31:12
	var now    = Date.now();
	var oneday = 86400 * 1000;

	var tdiff = now - to;
	var tmod  = tdiff % oneday;

	if (tdiff > oneday || to.getTime() > now)
	{
		to.setTime(to.getTime() + oneday - 1);
	}
	else if (to.getTime() <= now)
	{
		to.setTime(to.getTime() + tmod);
	}

	return to;
}

// 클러스터 관리-> 이벤트
Ext.define('/admin/js/manager_cluster_event', {
	extend: 'BasePanel',
	id: 'manager_cluster_event',
	bodyStyle: 'padding: 0;',
	load: function () { MCE_eventLoad(); },
	items: [
		{
			xtype: 'BasePanel',
			layout: { type: 'vbox', align : 'stretch' },
			bodyStyle: 'padding: 20px;',
			items: [
				{
					xtype: 'BasePanel',
					layout: 'fit',
					flex: 5,
					bodyStyle: 'padding: 0',
					items: [ MCE_eventGrid ]
				},
				{
					xtype: 'BasePanel',
					layout: 'fit',
					flex: 4,
					bodyStyle: 'padding: 0',
					items: [ MCE_eventTaskGrid ]
				}
			]
		}
	]
});
