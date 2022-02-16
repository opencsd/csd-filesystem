/*
 * 페이지 로드 시 실행 함수
 */
function MVR_raidLoad()
{
	// RAID 정보폼, 목록 받아오기
	MVR_raidGridStore.load();
};

// key, value type의 object를 배열로 변환해주는 함수
function json2array(obj)
{
	var keys = Object.getOwnPropertyNames(obj);
	var data = [];

	for (var i = 0 ; i < keys.length; i++)
	{
		var key = keys[i];
		var value = obj[key];

		if (value != null && typeof(value) == "object")
		{
			var tmp = json2array(value);

			for (var j = 0; j < tmp.length; j++)
			{
				data.push({
					type: tmp[j].type,
					value: tmp[j].value
				});
			}

			continue;
		}

		data.push ({
			type: key,
			value: value
		});
	}

	return data;
}

/** 선택된 RAID의 논리 디스크 정보 **/
// RAID의 논리 디스크 모델
Ext.define('MVR_raidLogicalModel', {
	extend: 'Ext.data.Model',
	fields: ['ID', 'Name' ,'RAID_Level', 'Size', 'State', 'NumOfPDs']
});

// RAID의 논리 디스크 스토어
var MVR_raidLogicalStore = Ext.create('Ext.data.Store', {
	model: 'MVR_raidLogicalModel',
	actionMethods: {
		read: 'POST'
	},
	proxy: {
		type: 'memory',
		reader: {
			type: 'json',
			root: 'entity'
		}
	}
});

// RAID의 논리 디스크 그리드
var MVR_raidLogicalGrid = Ext.create('BaseGridPanel', {
	id: 'MVR_raidLogicalGrid',
	store: MVR_raidLogicalStore,
	multiSelect: false,
	title: lang_mnr_raid[3],
	height: 300,
	style: { marginBottom: '20px' },
	columns: [
		{
			flex: 1,
			text: lang_mnr_raid[4],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'ID'
		},
		{
			flex: 1,
			text: lang_mnr_raid[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Name'
		},
		{
			flex: 1,
			text: lang_mnr_raid[6],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'RAID_Level'
		},
		{
			flex: 1,
			text: lang_mnr_raid[7],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Size'
		},
		{
			flex: 1,
			text: lang_mnr_raid[8],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'State'
		},
		{
			flex: 1,
			text: lang_mnr_raid[9],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'NumOfPDs'
		}
	],
	listeners: {
		itemclick: function(grid, record, item, index, e) {
			Ext.defer(function() { MVR_raidLogicalDiskSelect(record) }, 200);
		}
	}
});

function MVR_raidLogicalDiskSelect(record)
{
	var selectCount = Ext.getCmp('MVR_raidLogicalGrid').getSelectionModel().getCount();

	// 선택된 어뎁트키
	var raidAdaptKey = MVR_raidGrid.getSelectionModel().getSelection()[0].get('ID');

	// 선택된 논리 디스크 식별자
	var raidLogicalKey = record.data.ID.toString();
	var title;

	// 논리 디스크 선택 시 물리 디스크 목록의 제목 변경
	if (selectCount == 1 && raidLogicalKey)
	{
		title = "["+record.data.ID+"]: "+lang_mnr_raid[10];
	}
	else
	{
		raidLogicalKey = '';
		title = lang_mnr_raid[10];
	}

	MVR_raidPhysicalGrid.setTitle(title);

	// 논리 디스크 선택 시 물리 디스크 정보 받아오기
	GMS.Cors.request({
		url: '/api/raid/pd/list',
		method: 'POST',
		jsonData: {
			entity: {
				Adp_ID: raidAdaptKey,
				LD_ID: raidLogicalKey
			}
		},
		callback: function(options, success, response) {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			var responseData = exceptionDataDecode(response.responseText);

			// 예외 처리에 따른 동작
			if (!success || responseData.return !== 'true')
			{
				if (response.responseText == ''
						|| typeof(response.responseText) == 'undefined')
					response.responseText = '{}';

				if (typeof(responseData.msg) === 'undefined')
					responseData.msg = '';

				if (typeof(responseData.code) === 'undefined')
					responseData.code = '';

				var checkValue = '{'
					+ '"title": "' + lang_mnr_raid[19] + '",'
					+ '"content": "' + lang_mnr_raid[11] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 논리 디스크 선택 시 물리 디스크 목록의 제목 변경
			//MVR_raidPhysicalGrid.setTitle("["+record.data.ID+"]: "+lang_mnr_raid[10]);

			// 물리 디스크 목록 로드
			MVR_raidPhysicalStore.loadRawData(responseData);
		},
	});
};

/*
 * 선택된 논리 디스크의 물리 디스크 정보
 */
// RAID의 물리 디스크 모델
Ext.define('MVR_raidPhysicalModel', {
	extend: 'Ext.data.Model',
	fields: ['Joined_VD', 'ID', 'Size', 'State', 'Position', 'IfType', 'DevType']
});

// RAID의 물리 디스크 스토어
var MVR_raidPhysicalStore = Ext.create('Ext.data.Store', {
	model: 'MVR_raidPhysicalModel',
	actionMethods: {
		read: 'POST'
	},
	proxy: {
		type: 'memory',
		reader: {
			type: 'json',
			root: 'entity'
		}
	}
});

// RAID의 물리 디스크 그리드
var MVR_raidPhysicalGrid = Ext.create('BaseGridPanel', {
	id: 'MVR_raidPhysicalGrid',
	store: MVR_raidPhysicalStore,
	multiSelect: false,
	title: lang_mnr_raid[10],
	height: 300,
	style: { marginBottom: '20px' },
	columns: [
		{
			flex: 1,
			text: lang_mnr_raid[4],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Joined_VD'
		},
		{
			flex: 1,
			text: lang_mnr_raid[12],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'ID'
		},
		{
			flex: 1,
			text: lang_mnr_raid[13],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Size'
		},
		{
			flex: 1,
			text: lang_mnr_raid[8],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'State'
		},
		{
			flex: 1,
			text: lang_mnr_raid[32],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Position'
		},
		{
			flex: 1,
			text: lang_mnr_raid[33],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'IfType'
		},
		{
			flex: 1,
			text: lang_mnr_raid[36],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'DevType'
		}
	]
});

// RAID 논리 디스크 윈도우
var MVR_raidLogicalWin = Ext.create('BaseWindowPanel', {
	id: 'MVR_raidLogicalWin',
	maximizable: false,
	border: false,
	width: 850,
	height: 710,
	title: lang_mnr_raid[14],
	items: [
		{
			xtype: 'BasePanel',
			items: [MVR_raidLogicalGrid]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding-left:15px; padding-top:0px; padding-right:15px; padding-bottom:5px;',
			items: [MVR_raidPhysicalGrid]
		}
	]
});

/*
 * 선택된 RAID 상세 정보
 */
// RAID의 상세 정보 모델
Ext.define('MVR_raidAdapterModel', {
	extend: 'Ext.data.Model',
	fields: [
		{ name: 'type', type: 'string' },
		{ name: 'value', type: 'string' },
	]
});

// RAID의 상세 정보 스토어
var MVR_raidAdapterStore = Ext.create('Ext.data.Store', {
	model: 'MVR_raidAdapterModel',
	actionMethods: {
		read: 'POST'
	},
	proxy: {
		type: 'memory',
		reader: {
			type: 'json',
			root: 'entity'
		}
	}
});

// RAID의 상세 정보 그리드
var MVR_raidAdapterGrid = Ext.create('BaseGridPanel', {
	id: 'MVR_raidAdapterGrid',
	store: MVR_raidAdapterStore,
	multiSelect: false,
	title: lang_mnr_raid[15],
	height: 320,
	style: {marginBottom: '20px'},
	columns: [
		{
			flex: 1,
			text: lang_mnr_raid[16],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'type'
		},
		{
			flex: 1,
			text: lang_mnr_raid[17],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'value'
		}
	]
});

var MVR_raidAdapterWin = Ext.create('BaseWindowPanel', {
	id: 'MVR_raidAdapterWin',
	layout: 'fit',
	maximizable: false,
	border: false,
	width: 800,
	height: 400,
	title: lang_mnr_raid[18],
	items: [
		{
			xtype: 'BasePanel',
			items: [MVR_raidAdapterGrid]
		}
	]
});

/*
 * RAID 정보 목록
 */
// RAID 정보 모델
Ext.define('MVR_raidGridModel', {
	extend: 'Ext.data.Model',
	fields: [
		'ID',
		'LD_Total', 'LD_Normal', 'LD_Abnormal',
		'PD_Total', 'PD_Normal', 'PD_Abnormal'
	]
});

// RAID 정보 스토어
var MVR_raidGridStore = Ext.create('Ext.data.Store', {
	model: 'MVR_raidGridModel',
	actionMethods: {
		read: 'POST'
	},
	proxy: {
		type: 'ajax',
		url: '/api/raid/adapter/list',
		reader: {
			type: 'json',
			root: 'entity'
		}
	},
	listeners: {
		beforeload: function(store, operation, eOpts) {
			store.removeAll();
		},
		load: function(store, records, success) {
			// 예외 처리에 따른 동작
			if (success != true)
			{
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof jsonText == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mnr_raid[19] + '",'
					+ '"content": "' + lang_mnr_raid[2] + '",'
					+ '"response": ' + jsonText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 그룹 정보 mask 제거
			//Ext.ux.DialogMsg.msg(lang_mnr_raid[19], lang_mnr_raid[1]);
		}
	}
});

// RAID 정보 그리드
var MVR_raidGrid = Ext.create('BaseGridPanel', {
	id: 'MVR_raidGrid',
	store: MVR_raidGridStore,
	multiSelect: false,
	title: lang_mnr_raid[19],
	height: 300,
	columns: [
		{
			flex: 1,
			dataIndex: 'ID',
			text: lang_mnr_raid[20],
			sortable: true,
			menuDisabled: true
		},
		{
			flex: 1,
			text: lang_mnr_raid[21],
			sortable: false,
			menuDisabled: true,
			width: 500,
			columns: [
				{
					flex: 1,
					dataIndex: 'LD_Total',
					text: lang_mnr_raid[22],
					width: 120,
					align: 'center',
					sortable: true,
					menuDisabled: true
				},
				{
					flex: 1,
					dataIndex: 'LD_Normal',
					text: lang_mnr_raid[34],
					width: 120,
					align: 'center',
					sortable: true,
					menuDisabled: true
				},
				{
					flex: 1,
					dataIndex: 'LD_Abnormal',
					text: lang_mnr_raid[35],
					width: 120,
					align: 'center',
					sortable: true,
					menuDisabled: true
				}
			]
		},
		{
			width: 500,
			text: lang_mnr_raid[25],
			sortable: false,
			menuDisabled: true,
			columns: [
				{
					flex: 1,
					dataIndex: 'PD_Total',
					text: lang_mnr_raid[22],
					width: 120,
					align: 'center',
					sortable: true,
					menuDisabled: true
				},
				{
					flex: 1,
					dataIndex: 'PD_Normal',
					text: lang_mnr_raid[34],
					width: 120,
					align: 'center',
					sortable: true,
					menuDisabled: true
				},
				{
					flex: 1,
					dataIndex: 'PD_Abnormal',
					text: lang_mnr_raid[35],
					width: 120,
					align: 'center',
					sortable: true,
					menuDisabled: true
				}
			]
		},
		{
			flex: 1,
			text: lang_mnr_raid[3],
			sortable: false,
			menuDisabled: true,
			xtype: 'componentcolumn',
			autoWidthComponents: false,
			renderer: function(value, metaData, record) {
				return {
					xtype: 'button',
					width: 160,
					text: lang_mnr_raid[26],
					iconCls: 'b-icon-detail-view',
					handler: function() {
						// 선택된 어댑터의 식별자
						var raidAdaptKey = record.data.ID;

						waitWindow(lang_mnr_raid[19], lang_mnr_raid[27]);

						// TODO: write two functions which receives callback
						//       as a closure parameter and then call it
						//       after reload each stores
						GMS.Cors.request({
							url: '/api/raid/ld/list',
							method: 'POST',
							jsonData: {
								entity: {
									Adp_ID: raidAdaptKey
								}
							},
							callback: function(options, success, response) {
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								var responseData = exceptionDataDecode(response.responseText);

								// 예외 처리에 따른 동작
								if (!success || responseData.return !== 'true')
								{
									if (response.responseText == ''
											|| typeof(response.responseText) == 'undefined')
										response.responseText = '{}';

									if (typeof(responseData.msg) === 'undefined')
										responseData.msg = '';

									if (typeof(responseData.code) === 'undefined')
										responseData.code = '';

									var checkValue = '{'
										+ '"title": "' + lang_mnr_raid[19] + '",'
										+ '"content": "' + lang_mnr_raid[28] + '",'
										+ '"msg": "' + responseData.msg + '",'
										+ '"code": "' + responseData.code + '",'
										+ '"response": ' + response.responseText
									+ '}';

									return exceptionDataCheck(checkValue);
								}

								// 논리 디스크 목록 로드
								MVR_raidLogicalStore.loadRawData(responseData);
								MVR_raidLogicalWin.show();
								MVR_raidGrid.getSelectionModel().select(record, true);
							},
						});

						GMS.Cors.request({
							url: '/api/raid/pd/list',
							method: 'POST',
							jsonData: {
								entity: {
									Adp_ID: raidAdaptKey
								}
							},
							callback: function(options, success, response) {
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								var responseData = exceptionDataDecode(response.responseText);

								// 예외 처리에 따른 동작
								if (!success || responseData.return !== 'true')
								{
									if (response.responseText == ''
											|| typeof(response.responseText) == 'undefined')
										response.responseText = '{}';

									if (typeof(responseData.msg) === 'undefined')
										responseData.msg = '';

									if (typeof(responseData.code) === 'undefined')
										responseData.code = '';

									var checkValue = '{'
										+ '"title": "' + lang_mnr_raid[19] + '",'
										+ '"content": "' + lang_mnr_raid[11] + '",'
										+ '"msg": "' + responseData.msg + '",'
										+ '"code": "' + responseData.code + '",'
										+ '"response": ' + response.responseText
									+ '}';

									return exceptionDataCheck(checkValue);
								}

								// 물리 디스크 목록 로드
								MVR_raidPhysicalStore.loadRawData(responseData.physicalList);
							},
						});
					}
				};
			}
		},
		{
			flex: 1,
			text: lang_mnr_raid[15],
			sortable: false,
			menuDisabled: true,
			xtype: 'componentcolumn',
			autoWidthComponents: false,
			renderer: function(value, metaData, record) {
				return {
					xtype: 'button',
					width: 110,
					text: lang_mnr_raid[15],
					iconCls: 'b-icon-detail-view',
					handler: function() {
						// 선택된 어댑터의 식별자
						var raidAdaptKey = record.data.ID;

						waitWindow(lang_mnr_raid[19], lang_mnr_raid[29]);

						GMS.Cors.request({
							url: '/api/raid/adapter/info',
							method: 'POST',
							jsonData: {
								entity: {
									Adp_ID: raidAdaptKey
								}
							},
							callback: function(options, success, response) {
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								var responseData = exceptionDataDecode(response.responseText);

								// 예외 처리에 따른 동작
								if (!success || responseData.return !== 'true')
								{
									if (response.responseText == ''
											|| typeof(response.responseText) == 'undefined')
										response.responseText = '{}';

									if (typeof(responseData.msg) === 'undefined')
										responseData.msg = '';

									if (typeof(responseData.code) === 'undefined')
										responseData.code = '';

									var checkValue = '{'
										+ '"title": "' + lang_mnr_raid[19] + '",'
										+ '"content": "' + lang_mnr_raid[30] + '",'
										+ '"msg": "' + responseData.msg + '",'
										+ '"code": "' + responseData.code + '",'
										+ '"response": ' + response.responseText
									+ '}';

									return exceptionDataCheck(checkValue);
								}

								// 어댑터 목록 로드
								var data = json2array(responseData.entity);

								// 중복 제거
								for (var i = 0; i < data.length; i++)
								{
									for (var j = data.length - 1; j > i; j--)
									{
										if (data[i].type == data[j].type
												&& data[i].value == data[j].value)
										{
											data.splice(j, 1);
											// 중복이 하나라는 보장이 없기에 break는 하지 않는다.
										}
									}
								}

								MVR_raidAdapterStore.loadRawData(data, false);
								MVR_raidAdapterWin.show();
							}
						});
					}
				};
			}
		}
	],
	viewConfig: {
		forceFit: true,
		loadMask: true,
		trackOver: false
	}
});

// 볼륨 -> RAID 구성 정보
Ext.define('/admin/js/manager_node_raid', {
	extend: 'BasePanel',
	id: 'manager_node_raid',
	load: function() {
		MVR_raidLoad();
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			flex: 1,
			bodyStyle: 'padding: 20px',
			items: [MVR_raidGrid]
		}
	]
});
