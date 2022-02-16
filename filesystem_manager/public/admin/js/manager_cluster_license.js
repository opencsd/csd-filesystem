/*
 * 페이지 로드 시 실행 함수
 */
function MCL_licenseLoad()
{
	// 라이선스 그리드 로드
	MCL_licenseListStore.load();
}

/*
 * 라이선스 등록
 */
// 라이선스 등록 Panel
var MCL_licenseRegisterPanel = Ext.create('BaseFormPanel', {
	id: 'MCL_licenseRegisterPanel',
	frame: false,
	bodyStyle: 'padding: 0',
	items: [
		{
			xtype: 'BaseWizardContentPanel',
			items: [
				{
					xtype: 'BasePanel',
					bodyStyle: 'padding: 0;',
					style: { marginBottom: '30px' },
					html: lang_mcl_license[14]
				},
				{
					xtype: 'BasePanel',
					bodyStyle: 'padding: 0;',
					layout: 'hbox',
					maskOnDisable: false,
					style: { marginBottom: '20px' },
					items: [
						{
							xtype: 'label',
							text: lang_mcl_license[15]+': ',
							width: 130
						},
						{
							xtype: 'label',
							id: 'MCL_licenseRegisterUniqKey',
							style: { marginLeft: '5px' }
						}
					]
				},
				{
					xtype: 'BasePanel',
					bodyStyle: 'padding: 0;',
					layout: 'hbox',
					maskOnDisable: false,
					items: [
						{
							xtype: 'textfield',
							id: 'MCL_licenseRegisterlicenseKey',
							fieldLabel: lang_mcl_license[16],
							allowBlank: false
						}
					]
				}
			]
		},
		{
			xtype: 'BaseWizardDescPanel',
			items: [
				{
					border: false,
					html: lang_mcl_license[17]
				}
			]
		}
	]
});

// 라이선스 등록 Window
var MCL_licenseRegisterWindow = Ext.create('BaseWindowPanel', {
	id: 'MCL_licenseRegisterWindow',
	title: lang_mcl_license[12],
	maximizable: false,
	autoHeight: true,
	width: 450,
	items: [ MCL_licenseRegisterPanel ],
	buttons: [
		{
			text: lang_mcl_license[9],
			handler: function() {
				if (!Ext.getCmp('MCL_licenseRegisterlicenseKey').isValid())
				{
					return false;
				}

				GMS.Ajax.request({
					url: '/api/system/license/register',
					method: 'POST',
					waitMsgBox: waitWindow(lang_mcl_license[0], lang_mcl_license[18]),
					jsonData: {
						entity: {
							LicenseKey: Ext.getCmp('MCL_licenseRegisterlicenseKey').getValue()
						}
					},
					callback: function(options, success, response, decoded) {
						if (!success || !decoded.succss)
							return;

						MCL_licenseRegisterWindow.hide();

						if (licenseCheck != 'yes')
						{
							Ext.MessageBox.show({
								title: lang_mcl_license[0],
								msg: lang_mcl_license[19],
								buttons: Ext.MessageBox.OK,
								fn: function(buttonId) {
									if (buttonId === "ok")
									{
										locationMain();
									}
								}
							});

							return;
						}

						MCL_licenseLoad();
						Ext.MessageBox.alert(lang_mcl_license[0], lang_mcl_license[19]);
					},
				});
			}
		}]
	});

/**
라이선스 목록
**/
// 라이선스 목록 모델
Ext.define('MCL_licenseListModel',{
	extend: 'Ext.data.Model',
	fields: ['Name', 'Activation' ,'Expiration', 'Licensed', 'Status', 'RegDate']
});

// 클러스터 볼륨 목록 스토어
var MCL_licenseListStore = Ext.create('Ext.data.Store', {
	model: 'MCL_licenseListModel',
	sorters: [
		{
			property: 'Expiration',
			direction: 'ASC' 
		}
	],
	proxy: {
		type: 'ajax',
		url: '/api/system/license/list',
		reader: {
			type: 'json',
			root: 'entity',
			idProperty: 'Expiration'
		}
	},
	listeners: {
		beforeload: function(store, operation, eOpts) {
			store.removeAll();
			MCL_licenseListDetailStore.removeAll();
		},
		load: function(store, records, success) {
			if (waitMsgBox)
			{
				// 데이터 전송 완료 후: wait제거
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			if (success != true)
			{
				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mcl_license[0] + '",'
					+ '"content": "' + lang_mcl_license[2] + '",'
					+ '"response": ' + jsonText
				+ '}';

				exceptionDataCheck(checkValue);
			}

			//데이터로드 성공 메세지
			// Ext.ux.DialogMsg.msg(lang_mcl_license[0], lang_mcl_license[1]);
			
			// 스토어 필터 초기화
			store.clearFilter();
			MCL_licenseListDetailStore.clearFilter();

			// 서버로부터 받은 라이선스 스토어를 상세정보 스토어로 복사
			store.each(function(rec) {
				MCL_licenseListDetailStore.add({
					Name: rec.get('Name'),
					Licensed: rec.get('Licensed'),
					Status: rec.get('Status'),
					RegDate: rec.get('RegDate')
				});

				// 상세정보 페이지 폼의 값을 구성
				if (rec.get('Name') == 'Anystor-E')
				{
					Ext.getCmp('MCL_licenseName').setText(rec.get('Name'));
					Ext.getCmp('MCL_licenseStatus').setText(rec.get('Status'));
					Ext.getCmp('MCL_licenseLicensed').setText(rec.get('Licensed'));
					Ext.getCmp('MCL_licenseRegDate').setText(rec.get('RegDate'));
				}
			});

			// 상세정보 스토어에서 'CIFS', 'NFS', 'AFP', 'ADS', 'ISCSI',
			// 'HA', 'Replicator' 라이선스만 필터
			MCL_licenseListDetailStore.filter(
				'Name',
				/CIFS|NFS|FTP|AFP|ADS|ISCSI|HA|Replicator/
			);

			// 라이선스정보 스토어에서 'Anystor-E', 'Support', 'Demo' 라이선스만 필터
			store.filter('Name', /Anystor-E|Support|Demo/);
		}
	}
});

// 클러스터 볼륨 목록 그리드
var MCL_licenseListGrid = Ext.create('BaseGridPanel', {
	id: 'MCL_licenseListGrid',
	store: MCL_licenseListStore,
	multiSelect: false,
	title: lang_mcl_license[22],
	columnLines: true,
	cls: 'line-break',
	listeners: {
		beforeselect: function() {
			return false;
		}
	},
	columns: [
		{
			flex: 1,
			text: lang_mcl_license[3],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Name'
		},
		{
			flex: 1,
			text: lang_mcl_license[4],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Status'
		},
		{
			flex: 1,
			text: lang_mcl_license[6],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Expiration'
		},
		{
			flex: 1,
			text: lang_mcl_license[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Activation'
		},
		{
			flex: 1,
			text: lang_mcl_license[8],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'RegDate'
		},
		{
			flex: 1,
			text: lang_mcl_license[7],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Licensed'
		},
		{
			text: lang_mcl_license[25],
			width: 140,
			autoSizeColumn: true,
			minWidth: 140,
			sortable: false,
			menuDisabled: true,
			dataIndex: 'Detail',
			xtype: 'componentcolumn',
			renderer: function(value, metaData, record) {
				var scrollMenu = new Ext.menu.Menu();

				scrollMenu.add({
					text: 'VIEW',
					handler: function() { MCL_licenseViewWindow.show(); }
				});

				if (record.data.Name != 'Anystor-E')
				{
					return;
				}

				// 라이선스 이름이 'Anystore-E'일 때만 상세보기 버튼 생성
				// (Support|Demo 제외)
				return {
					xtype: 'button',
					text: lang_mcl_license[25],
					menu: scrollMenu
				};
			}
		}
	],
	tbar: [
		{
			text: lang_mcl_license[9],
			iconCls: 'b-icon-add',
			handler: function() {
				GMS.Ajax.request({
					url: '/api/system/license/uniq_key',
					waitMsgBox: waitWindow(lang_mcl_license[0], lang_mcl_license[10]),
					callback: function(options, success, response, decoded) {
						if (!success || !decoded.success)
							return;

						Ext.getCmp('MCL_licenseRegisterPanel').getForm().reset();
						Ext.getCmp('MCL_licenseRegisterUniqKey').setText(decoded.entity[0].Unique_Key);
						MCL_licenseRegisterWindow.show();
					},
				});
			}
		}
	],
	viewConfig: {
		markDirty: false,
		loadMask: true
	}
});

/**
프로토콜 라이선스 상세 페이지 
**/

// 프로토콜 라이선스 상세 모델
Ext.define('MCL_licenseListDetailModel',{
	extend: 'Ext.data.Model'
	,fields: ['Name', 'Licensed', 'Status', 'RegDate']
});

// 프로토콜 라이선스 상세 스토어
var MCL_licenseListDetailStore = Ext.create('Ext.data.Store', {
	model: 'MCL_licenseListDetailModel'
	,sorters: [{
		property: 'Name'
		,direction: 'ASC'
	}]
    ,proxy: {
        type: 'memory'
        ,reader: {
            type: 'json'
        }
    }
});

// 프로토콜 라이선스 상세 그리드패널
var MCL_licenseListDetailGrid = Ext.create('BaseGridPanel', {
    id: 'MCL_licenseListDetailGrid'
    ,store: MCL_licenseListDetailStore
    ,forcefit: true
    ,multiSelect: false
    ,title: lang_mcl_license[27] 
    ,height: 200
    ,columns: [{
		flex: 1
		,text: lang_mcl_license[3]
		,sortable: true
		,menuDisabled: true
		,dataIndex: 'Name'
    },{
		flex: 1
		,text: lang_mcl_license[4]
		,sortable: true
		,menuDisabled: true
		,dataIndex: 'Status'
    },{
		flex: 1
		,text: lang_mcl_license[8]
		,sortable: true
		,menuDisabled: true
		,dataIndex: 'RegDate'
    },{
		flex: 1
		,text: lang_mcl_license[7]
		,sortable: true
		,menuDisabled: true
		,dataIndex: 'Licensed'
    }]
});

// 프로토콜 라이선스 상세 패널
var MCL_licenseViewPanel = Ext.create('BasePanel', {
    id: 'MCL_licenseViewPanel'
    ,frame:false
    ,items:[{
		xtype: 'BasePanel'
		,bodyStyle: 'padding:0;'
		,layout: 'hbox'
		,maskOnDisable: false
		,style: {marginBottom: '20px'}
		,items: [{
			xtype: 'label'
			,text: lang_mcl_license[3] + ': '
			,width: '130px'
		},{
			xtype: 'label'
			,id: 'MCL_licenseName'
		}]
	},{
		xtype: 'BasePanel'
		,bodyStyle: 'padding:0;'
		,layout: 'hbox'
		,maskOnDisable: false
		,style: {marginBottom: '20px'}
		,items: [{
			xtype: 'label'
			,text: lang_mcl_license[4] + ': '
			,width: '130px'
		},{
			xtype: 'label'
			,id: 'MCL_licenseStatus'
		}]
	},{
		xtype: 'BasePanel'
		,bodyStyle: 'padding:0;'
		,layout: 'hbox'
		,maskOnDisable: false
		,style: {marginBottom: '20px'}
		,items: [{
			xtype: 'label'
			,text: lang_mcl_license[8] + ': '
			,width: '130px'
		},{
			xtype: 'label'
			,id: 'MCL_licenseRegDate'
		}]
	},{
		xtype: 'BasePanel'
		,bodyStyle: 'padding:0;'
		,layout: 'hbox'
		,maskOnDisable: false
		,style: {marginBottom: '20px'}
		,items: [{
			xtype: 'label'
			,text: lang_mcl_license[7] + ': '
			,width: '130px'
		},{
			xtype: 'label'
			,id: 'MCL_licenseLicensed'
		}]
	},{
		xtype: 'BasePanel'
		,bodyStyle: 'padding: 0;'
		,items: [MCL_licenseListDetailGrid]
    }]
});

// 프로토콜 라이선스 상세 윈도우
var MCL_licenseViewWindow = Ext.create('BaseWindowPanel', {
	id: 'MCL_licenseViewWindow'
	,title: lang_mcl_license[26]
	,maximizable: false
	,autoHeight: true
  	,width: 750
	,items: [MCL_licenseViewPanel]
	,buttons: [{
		id: 'MCV_licenseViewCloseBtn'
		,text: lang_mcl_license[28]
		,handler: function(){
			MCL_licenseViewWindow.hide();
		}
	}]
});

Ext.define('/admin/js/manager_cluster_license', {
	extend: 'BasePanel',
	id: 'manager_cluster_license',
	load: function() {
		MCL_licenseLoad();
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			layout: {
				type: 'vbox',
				align: 'stretch'
			},
			bodyStyle: 'padding: 0',
			items: [
				{
					xtype: 'BasePanel',
					id: 'MCL_licenseInfo',
					layout: 'fit',
					bodyCls: 'm-info-panel',
					hidden: true,
					html: '<img src="/admin/images/img_nodemgt.png" height="84" width="84"> <br>' + lang_mcl_license[21]
				},
				{
					xtype: 'BasePanel',
					id: 'MCL_licensePanel',
					layout: 'fit',
					flex: 1,
					bodyStyle: 'padding: 20px;',
					items: [ MCL_licenseListGrid ]
				}
			]
		}
	]
});
