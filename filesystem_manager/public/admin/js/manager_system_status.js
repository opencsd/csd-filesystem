/**
시스템 상태 표시
시간주기 표시
아이콘 이미지 헤더에 출력 (깜빡이는 걸로)
**/
/*
	//시스템 상태 정보 모델
	Ext.define('MSS_statusModel',{
		extend: 'Ext.data.Model'
		,fields: ['error', 'message', 'time']
	});
	//시스템 상태 정보 스토어
	var MSS_statusStore = Ext.create('Ext.data.Store', {
		model: 'MSS_statusModel'
		,proxy: {
			type: 'memory'
			,reader: {
				root: 'msg'
			}
		}
	});
	//시스템 상태 정보 그리드
	var MSS_statusGrid = Ext.create('BaseGridPanel', {
		id: 'MSS_statusGrid'
		,store: MSS_statusStore
		,multiSelect: false
		,height: 160
		//,title: lang_admin[6]
		,columns: [{
			flex: 1
			,text: lang_admin[7]
			,sortable: true
			,menuDisabled: true
			,dataIndex: 'error'
			,renderer: function(v, m, r) {
				var status = v.toLowerCase();
				if(status == 'normal') return '<img src="/admin/images/icon-status-normal2.png"> '+ status;
				else if(status == 'warn') return '<img src="/admin/images/icon-status-warning2.png"> '+ status;
				else if(status == 'error') return '<img src="/admin/images/icon-status-error2.png"> '+ status;
				else if(status == 'fatal') return '<img src="/admin/images/icon-status-error2.png"> '+ status;
				else return '<img src="/admin/images/icon-status-warn2.png"> '+ status;
			}
		},{
			flex: 3
			,text: lang_admin[8]
			,sortable: true
			,menuDisabled: true
			,dataIndex: 'message'
		},{
			flex: 2
			,text: lang_mst_time[18]
			,sortable: true
			,menuDisabled: true
			,dataIndex: 'time'
		}]
	});

	var MSS_statusPanel = Ext.create('BasePanel', {
		id: 'MSS_statusPanel'
		,frame: false
		,items: [{
			xtype: 'panel'
			,border: false
			,items: [MSS_statusGrid]
		}]
	});

*/


/** 오버뷰 태스크 그리드 **/
// 태스크 ROW 선택 시 상세 보기
var MSS_statusWindow = Ext.create('BaseWindowPanel', {
	id: 'MSS_statusWindow',
	title: lang_mss_status[0],
	maximizable: false,
	autoHeight: true,
	border: false,
	width: 600,
	height: 550,
	bodyStyle: 'padding:0px;',
	items: [
		{
			xtype: 'label',
			id: 'MSS_statusWindowLabel'
		}
	],
	buttonAlign: 'center',
	buttons: [
		{
			id: 'MSS_statusWindowCloseBtn',
			text: lang_mss_status[1],
			handler: function() { MSS_statusWindow.hide(); }
		}
	]
});

// 태스크 모델
Ext.define('MSS_statusModel', {
	extend: 'Ext.data.Model',
	fields: [
		'ID', 'Scope', 'Type', 'Level',
		'Category', 'Message', 'Details',
		'Start', 'Finish', 'Progress'
	]
});

// 태스크 스토어
var MSS_statusStore = Ext.create('Ext.data.Store', {
	model: 'MSS_statusModel',
	actionMethods: {
		read: 'POST'
	},
	proxy: {
		type: 'memory',
		reader: {
			type: 'json'
		}
	}
});

// 태스크 그리드
var MSS_statusGrid = Ext.create('BaseGridPanel', {
	id: 'MSS_statusGrid',
	store: MSS_statusStore,
	multiSelect: false,
	height: 160,
	title: lang_mss_status[2],
	cls: 'line-break',
	columns: [
		{
			text: lang_mss_status[3],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Level',
			width: 50,
			align: 'center',
			renderer: function(value, metaData, record, rowIdx, colIdx, store, view) {
				if (value == 'OK' || value == 'INFO')
				{
					return '<img src="/admin/images/icon-status-normal2.png">';
				}
				else if (value == 'WARNING')
				{
					return '<img src="/admin/images/icon-status-warning2.png">';
				}
				else if (value == 'ERROR')
				{
					return '<img src="/admin/images/icon-status-error2.png">';
				}
			}
		},
		{
			flex: 1,
			text: lang_mss_status[4],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Start'
		},
		{
			flex: 1,
			text: lang_mss_status[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Finish'
		},
		{
			flex: 1,
			text: lang_mss_status[6],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Message'
		},
		{
			flex: 1,
			text: lang_mss_status[7],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Scope'
		},
		{
			flex: 1,
			text: lang_mss_status[8],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Category'
		},
		{
			flex: 1,
			text: lang_mss_status[9],
			sortable : true,
			menuDisabled : true,
			dataIndex: 'Progress',
			renderer: function (v, m, r) {
				var id = Ext.id();

				Ext.defer(function() {
					Ext.widget('progressbar', {
						renderTo: id,
						value: v / 100,
						width: '90%',
						text: v + '%'
					});
				}, 50);

				return Ext.String.format('<div id="{0}"></div>', id);
			}
		}
	],
	listeners: {
		itemclick: function(grid, record, item, index, e) {
			delete record.data.ID;
			delete record.data.Type;
			delete record.data.Progress;
			delete record.data.Quiet;

			Ext.defer(function() {
				MSS_statusWindow.show();
				Ext.getCmp("MSS_statusWindowLabel").update();

				var detailsObj = record.data;
				var prettyJson = library.json.prettyPrint(detailsObj);

				Ext.getCmp("MSS_statusWindowLabel").update(prettyJson);
			}, 200);
		}
	}
});

var MSS_statusPanel = Ext.create('BasePanel', {
	id: 'MSS_statusPanel',
	frame: false,
	items: [
		{
			xtype: 'panel',
			border: false,
			items: [MSS_statusGrid]
		}
	]
});
