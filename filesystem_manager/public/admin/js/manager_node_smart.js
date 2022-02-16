function MNS_smartLoad()
{
	// 디스크 정보 로드
	GMS.Cors.request({
		url: '/api/smart/devices/info',
		method: 'POST',
		callback: function(options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			MNS_smartAttrStore.removeAll();
			MNS_smartTestStore.removeAll();
			MNS_smartAttrGrid.setTitle(lang_mns_smart[1]);
			MNS_smartTestGrid.setTitle(lang_mns_smart[2]);

			MNS_smartListStore.loadRawData(decoded);

			// S.M.A.R.T. test 진행률
			clearInterval(_nowCurrentSmartTestVar);
			_nowCurrentSmartTestVar = null;
		}
	});
};

Ext.apply(Ext.data.SortTypes, {
	asNumber: function(val) {
		return parseInt(val, 10);
	}
});

/*
 * 디스크 목록
 */
// 디스크 목록 모델
Ext.define('MNS_smartListModel',{
	extend: 'Ext.data.Model',
	fields: [
		'id', 'status', 'mapped_device', 'serial',
		'model', 'temperature', 'capacity_human',
		'type', 'healthy', 'is_preserved', 'smart_support',
		'life_hours'
	]
});

// 디스크 목록 스토어
var MNS_smartListStore = Ext.create('Ext.data.Store', {
	model: 'MNS_smartListModel',
	sorters: [
		{ property: 'mapped_device', direction: 'ASC' }
	],
	proxy: {
		type: 'memory',
		reader: {
			type: 'json',
			root: 'entity',
			idProperty: 'id',
		}
	},
	listeners: {
		beforeload: function(store, operation, eOpts) {
			store.removeAll();
		}
	}
});

// 디스크 목록 그리드
var MNS_smartListGrid = Ext.create('BaseGridPanel', {
	id: 'MNS_smartListGrid',
	store: MNS_smartListStore,
	multiSelect: false,
	title: lang_mns_smart[4],
	columnLines: true,
	cls: 'line-break',
	height: 350,
	columns: [
		{
			width: 40,
			text: lang_mns_smart[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'status',
			align: 'center',
			renderer: function(val, meta, record, rowIndex, colIndex, store) {
				if (val.toLowerCase() == 'err')
				{
					return '<img src="/admin/images/icon-status-error2.png">';
				}
				else if (val.toLowerCase() == 'warn')
				{
					return '<img src="/admin/images/icon-status-warning2.png">';
				}
				else
				{
					return '<img src="/admin/images/icon-status-normal2.png">';
				}
			}
		},
		{
			flex: 1,
			text: lang_mns_smart[6],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'mapped_device'
		},
		{
			flex: 1,
			text: lang_mns_smart[7],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'serial'
		},
		{
			flex: 2,
			text: lang_mns_smart[8],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'model'
		},
		{
			flex: 1,
			text: lang_mns_smart[9],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'temperature'
		},
		{
			flex: 1,
			text: lang_mns_smart[10],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'capacity_human'
		},
		{
			flex: 1,
			text: lang_mns_smart[26],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'type'
		},
		{
			flex: 1,
			text: 'Healthy',
			sortable: true,
			menuDisabled: true,
			dataIndex: 'healthy'
		},
		{
			flex: 1,
			text: lang_mns_smart[11],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'smart_support',
			renderer: function(val, meta, record, rowIndex, colIndex, store) {
				var smartSupportValue = val.toLowerCase();

				if (smartSupportValue == 'true')
				{
					return lang_mns_smart[12];
				}
				else
				{
					return lang_mns_smart[13];
				}
			}
		},
		{
			flex: 1,
			text: lang_mns_smart[20],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'is_preserved',
			renderer: function(val, meta, record, rowIndex, colIndex, store) {
				var diskType = lang_mns_smart[21];

				if (val != null)
				{
					switch(val.toUpperCase())
					{
						case 'OS':
							diskType = lang_mns_smart[32];
							break;
						case 'DATA':
							diskType = lang_mns_smart[33];
							break;
						case 'SPARE':
							diskType = lang_mns_smart[34];
							break;
						default:
							diskType = lang_mns_smart[21];
					}
				}

				return diskType;
			}
		},
		{
			flex: 1,
			text: lang_mns_smart[23],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'life_hours'
		},
		{
			dataIndex: 'id',
			hidden : true
		}
	],
	listeners: {
		beforedeselect: function(sm, record) {
			MNS_smartAttrStore.removeAll();
			MNS_smartTestStore.removeAll();
			MNS_smartAttrGrid.setTitle(lang_mns_smart[1]);
			MNS_smartTestGrid.setTitle(lang_mns_smart[2]);

			// S.M.A.R.T. test 진행률
			clearInterval(_nowCurrentSmartTestVar);
			_nowCurrentSmartTestVar = null;
		},
		beforeselect: function(sm, record) {
			MNS_smartAttrStore.removeAll();
			MNS_smartTestStore.removeAll();
			MNS_smartAttrGrid.setTitle(lang_mns_smart[1]);
			MNS_smartTestGrid.setTitle(lang_mns_smart[2]);

			// S.M.A.R.T. test 진행률
			clearInterval(_nowCurrentSmartTestVar);
			_nowCurrentSmartTestVar = null;

			// S.M.A.R.T. 지원하지 않을 경우
			if (record.data.smart_support.toLowerCase() != 'true')
				return false;
		},
		select: function(grid, record, index, eOpts) {
			// 디스크 속성
			var smartAttrLoadMask = new Ext.LoadMask(
				Ext.getCmp('MNS_smartAttrGrid'),
				{ msg: (lang_common[30]) });

			smartAttrLoadMask.show();

			// S.M.A.R.T. test
			var smartTestLoadMask = new Ext.LoadMask(
				Ext.getCmp('MNS_smartTestGrid'),
				{ msg: (lang_common[30]) });

			smartTestLoadMask.show();

			GMS.Cors.request({
				url: '/api/smart/devices/attrs',
				method: 'POST',
				jsonData: {
					argument: {
						id: record.data.id
					}
				},
				callback: function(options, success, response, decoded) {
					if (!success || !decoded.success)
						return;

					smartAttrLoadMask.hide();
					smartTestLoadMask.hide();

					// S.M.A.R.T. Attr
					MNS_smartAttrGrid.setTitle(lang_mns_smart[1]+' ('+record.data.serial+')');
					for (var i = 0; i < decoded.entity.length; i++)
					{
						if (decoded.entity[i].id == record.data.id)
						{
							MNS_smartAttrStore.loadRawData(decoded.entity[i].attrs, false);
							break;
						}
					}
				}
			});

			GMS.Cors.request({
				url: '/api/smart/devices/tests/list',
				method: 'POST',
				jsonData: {
					argument: {
						id: record.data.id
					}
				},
				callback: function(options, success, response, decoded) {
					if (!success || !decoded.success)
						return;

					smartAttrLoadMask.hide();
					smartTestLoadMask.hide();

					// S.M.A.R.T. Test
					MNS_smartTestGrid.setTitle(lang_mns_smart[2]+' ('+record.data.serial+')');
					for (var i = 0; i < decoded.entity.length; i++)
					{
						if (decoded.entity[i].id == record.data.id)
						{
							MNS_smartTestStore.loadRawData(decoded.entity[i].test_list, false);
							break;
						}
					}
				}
			});
		}
	},
	viewConfig: {
		forceFit: true,
		getRowClass: function(record, rowIndex, p, store) {
			var statusRowValue = record.data.healthy.toLowerCase();

			// healthy 상태가 failed 일경우
			if (statusRowValue == 'failed')
			{
				return 'm-custom-user-bundle';
			}

			// S.M.A.R.T. 지원하지 않을 경우
			if (record.data.smart_support.toLowerCase() != 'true')
			{
				return 'disabled-row';
			}
		}
	}
});

/*
 * S.M.A.R.T. Attr 목록
 */

// S.M.A.R.T. Attr 목록 모델
Ext.define('MNS_smartAttrModel',{
	extend: 'Ext.data.Model',
	fields: [
		{ name:'id', sortType: 'asNumber' },
		'name', 'current_value', 'worst_value', 'threshold',
		'raw_value', 'type', 'warning'
	]
});

// S.M.A.R.T. Attr 목록 스토어
var MNS_smartAttrStore = Ext.create('Ext.data.Store', {
	model: 'MNS_smartAttrModel',
	proxy: {
		type: 'memory',
		reader: {
			type: 'json'
		}
	},
	sorters: [
		{ property: 'id', direction: 'ASC' }
	],
	listeners: {
		beforeload: function( store, operation, eOpts ) {
			store.removeAll();
		}
	}
});

// S.M.A.R.T. Attr 그리드
var MNS_smartAttrGrid = Ext.create('BaseGridPanel', {
	id: 'MNS_smartAttrGrid',
	store: MNS_smartAttrStore,
	multiSelect: false,
	title: lang_mns_smart[1],
	columnLines: true,
	cls: 'line-break',
	height: 350,
	columns: [
		{
			width: 40,
			text: lang_mns_smart[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'warning',
			align: 'center',
			renderer: function(val, meta, record, rowIndex, colIndex, store) {
				var warn = val.toLowerCase();

				if (warn == 'true')
				{
					return '<img src="/admin/images/icon-status-warning2.png">';
				}
				else
				{
					return '<img src="/admin/images/icon-status-normal2.png">';
				}
			}
		},
		{
			width: 40,
			text: 'ID',
			sortable: true,
			menuDisabled: true,
			dataIndex: 'id'
		},
		{
			flex: 1,
			text: lang_mns_smart[15],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'name'
		},
		{
			flex: 1,
			text: lang_mns_smart[27],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'current_value'
		},
		{
			flex: 1,
			text: lang_mns_smart[28],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'worst_value'
		},
		{
			flex: 1,
			text: lang_mns_smart[29],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'threshold'
		},
		{
			flex: 1,
			text: lang_mns_smart[30],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'raw_value'
		},
		{
			flex: 1,
			text: lang_mns_smart[31],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'type'
		}
	]
});

/*
 * S.M.A.R.T. Test 목록
**/
// S.M.A.R.T. Test 목록 모델
Ext.define('MNS_smartTestModel', {
	extend: 'Ext.data.Model',
	fields: [
		{ name:'number', sortType: 'asNumber' },
		'progress' ,'lba_first_error', 'life_hours', 'type', 'result'
	]
});

// S.M.A.R.T. Test 목록 스토어
var MNS_smartTestStore = Ext.create('Ext.data.Store', {
	model: 'MNS_smartTestModel',
	proxy: {
		type: 'memory',
		reader: {
			type: 'json'
		}
	},
	sorters: [
		{ property: 'number', direction: 'ASC' }
	],
	listeners: {
		beforeload: function( store, operation, eOpts ) {
			store.removeAll();
		}
	}
});

// S.M.A.R.T. test grid
var MNS_smartTestGrid = Ext.create('BaseGridPanel', {
	id: 'MNS_smartTestGrid',
	store: MNS_smartTestStore,
	multiSelect: false,
	title: lang_mns_smart[2],
	columnLines: true,
	cls: 'line-break',
	height: 350,
	columns: [
		{
			width: 50,
			text: lang_mns_smart[16],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'number'
		},
		{
			flex: 1,
			text: lang_mns_smart[17],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'progress',
			renderer: function(val, meta, record, rowIndex, colIndex, store) {
				if (val == 100)
					return lang_mns_smart[18];

				clearInterval(_nowCurrentSmartTestVar);

				_nowCurrentSmartTestVar
					= setInterval(function() {
						smartTestProcess(rowIndex);
					}, 5000);

				var id = Ext.id();

				Ext.defer(function () {
					Ext.widget('progressbar', {
						renderTo: id,
						value: val / 100,
						width: '90%',
						text: val+'%'
					});
				}, 50);

				return Ext.String.format('<div id="{0}"></div>', id);
			}
		},
		{
			flex: 1,
			text: lang_mns_smart[22],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'lba_first_error'
		},
		{
			flex: 1,
			text: lang_mns_smart[23],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'life_hours'
		},
		{
			flex: 1,
			text: lang_mns_smart[24],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'type'
		},
		{
			flex: 1,
			text: lang_mns_smart[25],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'result'
		}
	],
	viewConfig: {
		markDirty: false
	}
});

// S.M.A.R.T. Test process
function smartTestProcess(rowIndex)
{
	GMS.Cors.request({
		url: '/api/smart/devices/tests/list',
		method: 'POST',
		jsonData: {
			argument: {
				id: MNS_smartListGrid.getSelectionModel().getSelection()[0].get('id'),
				latest: 1
			}
		},
		callback: function(options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			var record = MNS_smartTestStore.getAt(rowIndex);

			if (decoded.entity[0].test_list[0].progress == 100)
			{
				clearInterval(_nowCurrentSmartTestVar);
				_nowCurrentSmartTestVar = null;
				record.set('progress', '100');
			}
			else
			{
				record.set('progress', decoded.entity[0].test_list[0].progress);
			}
		},
	});
};

/*
 * S.M.A.R.T. Attributes, Test panel
**/
var MNS_smartDetailPanel = Ext.create('BasePanel', {
	id: 'MNS_smartDetailPanel',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0',
	items: [
		{
			flex: 1,
			layout: 'fit',
			border: false,
			items: MNS_smartAttrGrid
		},
		{
			border: false,
			width: 20,
			html:'&nbsp'
		},
		{
			flex: 1,
			layout: 'fit',
			border: false,
			items: MNS_smartTestGrid
		}
	]
});

// 클러스터 노드 관리 -> SMART
Ext.define('/admin/js/manager_node_smart', {
	extend: 'BasePanel',
	id: 'manager_node_smart',
	bodyStyle: 'padding: 0;',
	load: function() {
		MNS_smartLoad();
	},
	items: [
		{
			xtype: 'BasePanel',
			layout: {
				type: 'vbox',
				align : 'stretch'
			},
			autoScroll: true,
			bodyStyle: 'padding: 20px;',
			items: [
				{
					xtype: 'BasePanel',
					bodyStyle: 'padding-bottom: 20px',
					items: [MNS_smartListGrid]
				},
				{
					xtype: 'BasePanel',
					layout: 'fit',
					flex: 1,
					minHeight: 250,
					bodyStyle: 'padding: 0',
					items: [MNS_smartDetailPanel]
				}
			]
		}
	]
});
