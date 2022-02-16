/****************************************************************************
 * SortTypes
 ****************************************************************************/

/**
 * Hostname sorting
 * @param {String} hostname The value being converted
 * @return {Number} The comparison value
 */
Ext.apply(
	Ext.data.SortTypes,
	{
		asHostName: function (hostname) {
			var hostnameData   = hostname.split('-');
			var hostnameNumber = parseInt(hostnameData[1]);

			return hostnameNumber;
		}
	}
);

/*
 * Models
 */
// 볼륨풀 목록 모델
Ext.define(
	'MCV_volumePoolModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Pool_Name', 'Pool_Purpose', 'Pool_Type', 'Pool_Status',
			'Pool_Size', 'Pool_Used', 'Management', 'Provision',
			'Thin_Allocation', 'Node_List', 'Nodes', 'Base_Pool',
			'Volume_Count',
			'External_IP', 'External_Type', 'Pool_Free_Size',
		]
	}
);

// 클러스터 볼륨 목록 모델
Ext.define(
	'MCV_volumeModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Pool_Type', mapping: 'Volume_Type' },
			'Pool_Name', 'Volume_Name', 'Size', 'Size_Bytes', 'Volume_Used',
			'Node_List', 'Status_Code', 'Dist_Node_Count', 'Replica_Count',
			'Code_Count', 'Provision', 'Policy', 'Management',
			'Arbiter', 'Arbiter_Count', 'Hot_Tier', 'Chaining',
			'Oper_Stage',
		]
	}
);

// 노드 목록 모델
Ext.define('MCV_volumeCreateNodeGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Hostname', sortType: 'asHostName' },
			'HW_Status', 'SW_Status', 'Used', 'Free_Size',
			'Storage_IP'
		]
	}
);

// 클러스터 볼륨 정보 VIEW GRID 모델
Ext.define(
	'MCV_volumeViewNodeModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Hostname', sortType: 'asHostName' },
			'Used' ,'HW_Status', 'SW_Status','Tp_List'
		]
	}
);

// 클러스터 볼륨 정보 Expand GRID 모델
Ext.define(
	'MCV_volumeExpandNodeModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Hostname', sortType: 'asHostName' },
			'Storage_IP', 'Brick_Size', 'Brick_Size_Bytes', 'HW_Status', 'SW_Status',
			'Free_Size', 'Free_Size_Bytes', 'Total_Size', 'Used',
			'inclusion', 'expandable'
		]
	}
);

/*
// 티어링 볼륨 풀 리스트 모델
Ext.define(
	'MCV_volumeTieringCreatePoolListModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Pool_Name', 'Pool_Type', 'Pool_Size', 'Pool_Free_Size',
			'Nodes', 'Pool_Purpose'
		]
	}
);

// 티어링 노드 목록 모델
Ext.define(
	'MCV_volumeTieringCreateNodeGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Hostname', sortType: 'asHostName' },
			'HW_Status', 'SW_Status' ,'Used', 'Free_Size',
			'LV_Used','LV_Size','Total_Size'
		]
	}
);
*/

/****************************************************************************
 * Stores
 ****************************************************************************/
// 볼륨 풀 스토어
var MCV_volumePoolStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumePoolModel',
		sorters: [
			{ property: 'Pool_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/volume/pool/list',
			reader: {
				type: 'json',
				root: 'entity'
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
					+ '"title": "' + lang_mcv_volume[0] + '",'
					+ '"content": "' + lang_mcv_volume[93] + '",'
					+ '"response": ' + jsonText
					+ '}';

				exceptionDataCheck(checkValue);
			}
		}
	}
);

// 클러스터 볼륨 목록 스토어
var MCV_volumeGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumeModel',
		sorters: [
			{ property: 'Volume_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/volume/list',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Volume_Name',
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 데이터 전송 완료 후 wait 제거
				if (waitMsgBox)
				{
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
						+ '"title": "' + lang_mcv_volume[0] + '",'
						+ '"content": "' + lang_mcv_volume[36] + '",'
						+ '"response": ' + jsonText
						+ '}';

					return exceptionDataCheck(checkValue);
				}

				// 데이터 로드 성공 메세지
				//Ext.ux.DialogMsg.msg(lang_mcv_volume[0], lang_mcv_volume[70]);
			}
		}
	}
);

// 노드 목록 스토어
var MCV_volumeCreateNodeGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumeCreateNodeGridModel',
		sorters: [
			{ property: 'Hostname', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 예외 처리에 따른 동작
				if (success != true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcv_volume[0] + '", '
						+ '"content": "' + lang_mcv_volume[172] + '", '
						+ '"response": ' + jsonText
					+ '}';

					exceptionDataCheck(checkValue);
				}
			}
		}
	}
);

// 클러스터 볼륨 정보 VIEW GRID 스토어
var MCV_volumeViewNodeStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumeViewNodeModel',
		sorters: [
			{
				property: 'Hostname',
				direction: 'ASC'
			}
		],
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
	});

// 클러스터 볼륨 정보 Expand GRID 스토어
var MCV_volumeExpandNodeStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumeExpandNodeModel',
		sorters: [
			{
				property: 'Hostname',
				direction: 'ASC'
			}
		],
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

/*
// 티어링 볼륨 풀 리스트 스토어
var MCV_volumeTieringCreatePoolListStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumeTieringCreatePoolListModel',
		sorters: [
			{ property: 'Pool_Name', direction: 'ASC' }
		],
		sortOnLoad: true,
		proxy: {
			type: 'ajax',
			url: '/api/cluster/volume/pool/list',
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 예외 처리에 따른 동작
				if (success != true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcv_volume[0] + '",'
						+ '"content": "' + lang_mcv_volume[93] + '",'
						+ '"response": ' + jsonText
						+ '}';

					exceptionDataCheck(checkValue);
				}
			}
		}
	}
);

// 티어링 노드 목록 스토어
var MCV_volumeTieringCreateNodeGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumeTieringCreateNodeGridModel',
		sorters: [
			{ property: 'Hostname', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 예외 처리에 따른 동작
				if (success != true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcv_volume[0] + '", '
						+ '"content": "' + lang_mcv_volume[172] + '", '
						+ '"response": ' + jsonText
					+ '}';

					exceptionDataCheck(checkValue);
				}
			}
		}
	}
);
*/

/****************************************************************************
 * Panels
 ****************************************************************************/

/*
 * 클러스터 볼륨 생성
 */
/** 클러스터 볼륨 생성 step 1 **/
var MCV_volumeCreateStep1Panel = Ext.create(
	'BasePanel',
	{
		id: 'MCV_volumeCreateStep1Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch',
		},
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'image',
				src: '/admin/images/bg_wizard.jpg',
				height: 540,
				width: 150
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mcv_volume[1]
					},
					{
						xtype: 'BaseWizardContentPanel',
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mcv_volume[9] + '(1/5)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volume[3]
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mcv_volume[24] + ', ' + lang_mcv_volume[25] + '(2/5)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volume[5]
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mcv_volume[89] + '(3/5)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volume[7]
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mcv_volume[71] + ', ' + lang_mcv_volume[21] + '(4/5)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volume[219]
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mcv_volume[220] + '(5/5)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volume[221]
							}
						]
					}
				]
			}
		]
	}
);

// 클러스터 생성2 - 볼륨풀 목록
// 볼륨풀 그리드
var MCV_volumeCreatePoolGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumeCreatePoolGrid',
		store: MCV_volumePoolStore,
		multiSelect: false,
		title: lang_mcv_volume[244],
		height: 160,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			checkOnly: 'true',
			allowDeselect: true
		},
		columns: [
			{
				flex: 1,
				text: lang_mcv_volume[245],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Pool_Name'
			},
			{
				flex: 1,
				text: lang_mcv_volume[246],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Pool_Type'
			},
			{
				flex: 1,
				text: lang_mcv_volume[247],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Pool_Status'
			},
			{
				flex: 1,
				text: lang_mcv_volume[248],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Pool_Size'
			},
			{
				flex: 1,
				text: lang_mcv_volume[249],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Pool_Used'
			},
			{
				dataIndex: 'Node_List',
				hidden: true
			},
			{
				dataIndex: 'Nodes',
				hidden: true
			}
		],
		listeners: {
			cellclick: function (gridView, htmlElement, columnIndex, record) {
				if (columnIndex == 0)
				{
					Ext.defer(function () { 
						MCV_volumeCreatePoolGrid.getSelectionModel().select(record, true);
						updatePoolGrid(record);
					}, 100);
				}
			}
		}
	}
);

// 클러스터 생성2 - 볼륨 타입
var MCV_volumeCreateStep2Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeCreateStep2Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		border: false,
		frame: false,
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mcv_volume[9]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[24] + ', ' + lang_mcv_volume[25]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[89]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[71] + ', ' + lang_mcv_volume[21]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[220]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mcv_volume[3]
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align: 'stretch'
						},
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding:0;',
								style: { marginBottom: '20px' },
								items: [ MCV_volumeCreatePoolGrid ]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateStep2TypePanel',
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								hidden: true,
								items: [
									{
										xtype: 'label',
										text: lang_mcv_volume[9] + ': ',
										style: { marginTop: '5px' },
										width: '125px'
									},
									{
										xtype: 'radiogroup',
										anchor: 'none',
										layout: {
											autoFlex: false
										},
										defaults: {
											margin: '2 50 0 0'
										},
										items: [
											{
												boxLabel: lang_mcv_volume[129],
												name: 'volumeType',
												inputValue: 'thick',
												id: 'MCV_volumeCreateTypeThick',
												checked: true
											},
											{
												boxLabel: lang_mcv_volume[128],
												name: 'volumeType',
												inputValue: 'thin',
												id: 'MCV_volumeCreateTypeThin',
												width: 130
											}
										],
										listeners: {
											change: function (field, newValue, oldValue) {
												Ext.getCmp('MCV_volumeCreatePolicy').setValue('Distributed');
												Ext.getCmp('MCV_volumeCreateReplica').show();
												Ext.getCmp('MCV_volumeCreateReplica').setValue(2);
												Ext.getCmp('MCV_volumeCreateCodeCount').hide();
												Ext.getCmp('MCV_volumeCreateChaining').show();
												Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
												Ext.getCmp('MCV_volumeCreateArbiter').show();
												Ext.getCmp('MCV_volumeCreateNodeTotal').setText(lang_mcv_volume[237] + ': 0');
											}
										}
									}
								]
							}
						]
					},
					{
						xtype: 'BaseWizardDescPanel',
						id: 'MCV_volumeCreateStep2DescPanel',
						hidden: true,
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '[ ' + lang_mcv_volume[129] + ' ]<br><br>' + lang_mcv_volume[4]
							},
							{
								border: false,
								html: '[ ' + lang_mcv_volume[128] + ' ]<br><br>' + lang_mcv_volume[2]
							}
						]
					}
				]
			}
		]
	}
);

// 클러스터 생성3 - 볼륨명, 전송 유형
var MCV_volumeCreateStep3Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeCreateStep3Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		border: false,
		frame: false,
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[9]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(1);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mcv_volume[24] + ', ' + lang_mcv_volume[25]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[89]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[71] + ', ' + lang_mcv_volume[21]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[220]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mcv_volume[5]
					},
					{
						xtype: 'BaseWizardContentPanel',
						height: 220,
						items: [
							{
								xtype: 'BasePanel',
								layout: 'vbox',
								bodyStyle: 'padding: 0;',
								flex: 1,
								items: [
									{
										xtype: 'textfield',
										id: 'MCV_volumeCreateName',
										fieldLabel: lang_mcv_volume[24],
										allowBlank: false,
										vtype: 'reg_ID',
										style: { marginBottom: '20px' }
									},
									{
										xtype: 'BaseComboBox',
										id: 'MCV_volumeCreateSendType',
										fieldLabel: lang_mcv_volume[25],
										hidden: true,
										store: new Ext.data.SimpleStore({
											fields: ['VolumeSendType', 'VolumeTypeSendCode'],
											data: [
												['tcp', 'tcp'],
												['rdma', 'rdma'],
												['tcp,rdma', 'tcp,rdma']
											]
										}),
										value: 'tcp',
										displayField: 'VolumeSendType',
										valueField: 'VolumeTypeSendCode'
									},
									{
										// 마운트 대상
										xtype: 'textfield',
										id: 'MCV_volumeCreateExtTarget',
										hidden: true,
										fieldLabel: lang_mcv_volume[242],
										labelStyle: 'vertical-align: middle',
										style: { marginBottom: '20px' }
									},
									{
										// 마운트 옵션
										xtype: 'textfield',
										id: 'MCV_volumeCreateExtOpts',
										hidden: true,
										fieldLabel: lang_mcv_volume[243],
										labelStyle: 'vertical-align: middle',
										style: { marginBottom: '20px' }
									}
								]
							}
						]
					},
					{
						xtype: 'BaseWizardDescPanel',
						id: 'MCV_volumeCreateStep3DescPanel',
						hidden: true,
						items: [
							{
								border: false,
								style: {marginBottom: '20px'},
								html: '[ tcp ]<br><br>' + lang_mcv_volume[26]
							},
							{
								border: false,
								style: {marginBottom: '20px'},
								html: '[ rdma ]<br><br>' + lang_mcv_volume[27]
							},
							{
								border: false,
								html: '[ tcp,rdma ]<br><br>' + lang_mcv_volume[28]
							}
						]
					}
				]
			}
		]
	});

// 클러스터 생성4 - 분산 정책
var MCV_volumeCreateStep4Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeCreateStep4Panel',
		bodyStyle: 'padding:0;',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		border: false,
		frame: false,
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[9]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(1);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[24]
								+ ', '
								+ lang_mcv_volume[25] + '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(2);
									updateCreatewWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mcv_volume[89]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[71] + ', ' + lang_mcv_volume[21]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[220]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				autoScroll: false,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mcv_volume[7]
					},
					{
						xtype: 'BaseWizardContentPanel',
						height: 220,
						items: [
							{
								xtype: 'BaseComboBox',
								id: 'MCV_volumeCreatePolicy',
								fieldLabel: lang_mcv_volume[89],
								labelWidth: 130,
								width: 280,
								store: new Ext.data.SimpleStore({
									fields: ['PolicyType', 'PolicyCode'],
									data: [
										['Distributed', 'Distributed'],
										['Network RAID', 'NetworkRAID'],
										['Shard', 'Shard']
									]
								}),
								value: 'Distributed',
								displayField: 'PolicyType',
								valueField: 'PolicyCode',
								listeners: {
									change: function (combo, newValue, oldValue) {
										if (newValue == 'NetworkRAID')
										{
											Ext.getCmp('MCV_volumeCreateCodeCount').show();
											Ext.getCmp('MCV_volumeCreateReplica').hide();
											Ext.getCmp('MCV_volumeCreateReplicaChain').hide();
											Ext.getCmp('MCV_volumeCreateChaining').hide();
											Ext.getCmp('MCV_volumeCreateArbiter').hide();
											Ext.getCmp('MCV_volumeCreateShardBlockSize').hide();
										}
										else if (newValue == 'Distributed')
										{
											Ext.getCmp('MCV_volumeCreateCodeCount').hide();
											Ext.getCmp('MCV_volumeCreateReplica').show();
											Ext.getCmp('MCV_volumeCreateReplica').setValue(2);
											Ext.getCmp('MCV_volumeCreateChaining').show();
											Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
											Ext.getCmp('MCV_volumeCreateArbiter').show();
											Ext.getCmp('MCV_volumeCreateShardBlockSize').hide();

											// 볼륨 풀 명
											var pool = MCV_volumeCreatePoolGrid.getSelectionModel().getSelection()[0];

											if (pool.get('Nodes').length >= 3)
											{
												// 체인 모드
												Ext.getCmp('MCV_volumeCreateChaining').setDisabled(false);

												// 체인 모드 비활성화 설명 제거
												Ext.defer(function () {
													Ext.QuickTips.unregister(
														Ext.getCmp('MCV_volumeCreateChaining')
													);
												}, 100);

												// 아비터
												Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);

												// 아비터 비활성화 설명 제거
												Ext.defer(function () {
													Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateArbiter'));
												}, 100);
											}
											else
											{
												// 체인 모드 X
												Ext.getCmp('MCV_volumeCreateChaining').setDisabled(true);

												// 체인 모드 비활성화 설명
												Ext.defer(function () {
													Ext.QuickTips.register({
														target: 'MCV_volumeCreateChaining',
														text: lang_mcv_volume[228]
													});
												}, 100);

												// 아비터
												Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);

												// 아비터 비활성화 설명
												Ext.defer(function () {
													Ext.QuickTips.register({
														target: 'MCV_volumeCreateArbiter',
														text: lang_mcv_volume[228]
													});
												}, 100);
											}
										}
										else
										{
											Ext.getCmp('MCV_volumeCreateCodeCount').hide();
											Ext.getCmp('MCV_volumeCreateReplica').show();
											Ext.getCmp('MCV_volumeCreateReplicaChain').hide();
											Ext.getCmp('MCV_volumeCreateChaining').hide();
											Ext.getCmp('MCV_volumeCreateArbiter').hide();
											Ext.getCmp('MCV_volumeCreateShardBlockSize').show();
											Ext.getCmp('MCV_volumeCreateShardBlockSize').reset();
										}
									}
								}
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeCreateCodeCount',
								allowBlank: false,
								fieldLabel: lang_mcv_volume[10],
								labelWidth: 130,
								width: 280,
								hidden: true,
								style: { marginTop: '20px' }
							},
							{
								xtype: 'BaseComboBox',
								id: 'MCV_volumeCreateReplica',
								fieldLabel: lang_mcv_volume[11],
								labelWidth: 130,
								width: 280,
								store: new Ext.data.SimpleStore({
									fields: ['VolumeDupView', 'VolumeDupCode'],
									data: [
										[1, 1],
										[2, 2],
										[3, 3],
										[4, 4]
									]
								}),
								value: 2,
								displayField: 'VolumeDupView',
								valueField: 'VolumeDupCode',
								style: { marginTop: '20px' },
								listeners: {
									change: function (combo, newValue, oldValue) {
										// 볼륨 풀 명
										var nodes  = MCV_volumeCreatePoolGrid.getSelectionModel().getSelection()[0].get('Node_List');
										var policy = Ext.getCmp('MCV_volumeCreatePolicy').getValue();

										// 체인 모드 체크박스
										if (policy == 'Distributed'
											&& nodes.length >= 3 && newValue == 2)
										{
											// 체인 모드
											Ext.getCmp('MCV_volumeCreateChaining').show(true);
											Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
											Ext.getCmp('MCV_volumeCreateChaining').setDisabled(false);

											// 아비터
											Ext.getCmp('MCV_volumeCreateArbiter').show(true);
											Ext.getCmp('MCV_volumeCreateArbiter').setValue(true);
											Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);

											// 아비터 비활성화 설명 제거
											Ext.defer(function () {
												Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateArbiter'));
											}, 100);
										}
										else if (policy == 'Distributed'
											&& nodes.length < 3 && newValue == 2)
										{
											// 체인 모드
											Ext.getCmp('MCV_volumeCreateChaining').show(true);
											Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
											Ext.getCmp('MCV_volumeCreateChaining').setDisabled(true);

											// 아비터
											Ext.getCmp('MCV_volumeCreateArbiter').show(true);
											Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);
											Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);

											// 아비터 비활성화 설명
											Ext.defer(function () {
												Ext.QuickTips.register({
													target: 'MCV_volumeCreateArbiter',
													text: lang_mcv_volume[228]
												}) ;
											}, 100);
										}
										else
										{
											// 체인 모드
											Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
											Ext.getCmp('MCV_volumeCreateChaining').hide();

											// 아비터
											Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);
											Ext.getCmp('MCV_volumeCreateArbiter').hide();
										}
									}
								}
							},
							{
								xtype: 'BaseComboBox',
								id: 'MCV_volumeCreateShardBlockSize',
								fieldLabel: lang_mcv_volume[235],
								labelWidth: 130,
								width: 280,
								store: new Ext.data.SimpleStore({
									fields: ['ShardBlockSizeView', 'ShardBlockSizeCode'],
									data: [
										['512MiB', '512MB'],
										['1GiB', '1GB'],
										['2GiB', '2GB'],
										['4GiB', '4GB']
									]
								}),
								value: '512MB',
								displayField: 'ShardBlockSizeView',
								valueField: 'ShardBlockSizeCode',
								style: { marginTop: '20px' }
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateReplicaChain',
								bodyStyle: 'padding: 0;',
								layout: 'hbox',
								maskOnDisable: false,
								hidden: true,
								style: { marginTop: '24px', marginBottom: '7px' },
								items: [
									{
										xtype: 'label',
										disabledCls: 'm-label-disable-mask',
										width: 135,
										html: lang_mcv_volume[11] + ': '
									},
									{
										xtype: 'label',
										html: '2'
									}
								]
							},
							{
								xtype: 'checkbox',
								id: 'MCV_volumeCreateChaining',
								fieldLabel: lang_mcv_volume[188],
								labelWidth: 130,
								style: { marginTop: '20px' },
								inputValue: false,
								listeners: {
									change: function () {
										if (this.getValue())
										{
											Ext.getCmp('MCV_volumeCreateReplica').setValue(2);
											Ext.getCmp('MCV_volumeCreateReplica').hide();
											Ext.getCmp('MCV_volumeCreateReplicaChain').show();
											Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);
											Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);
										}
										else
										{
											Ext.getCmp('MCV_volumeCreateReplica').show();
											Ext.getCmp('MCV_volumeCreateReplicaChain').hide();

											if (Ext.getCmp('MCV_volumeCreateReplica').getValue() == 2)
											{
												Ext.getCmp('MCV_volumeCreateArbiter').setValue(true);
												Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);
											}
										}

										/*
										/* 아비터 검사

										// 볼륨 풀에 속한 노드 목록
										var nodes = MCV_volumeCreatePoolGrid
															.getSelectionModel()
															.getSelection()[0]
															.get('Nodes');

										// 풀에 속한 노드가 셋 이상이면 아비터 활성화 가능
										if (nodes.length >= 3)
										{
											Ext.getCmp('MCV_volumeCreateArbiter').setValue(true);
											Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);

											// 아비터 비활성화 설명 제거
											Ext.defer(function () {
												Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateArbiter'));
											}, 100);
										}
										else
										{
											Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);
											Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);

											// 아비터 비활성화 설명
											Ext.defer(function () {
												Ext.QuickTips.register({
													target: 'MCV_volumeCreateArbiter',
													text: lang_mcv_volume[228]
												}) ;
											}, 100);
										}
										*/
									}
								}
							},
							{
								xtype: 'checkbox',
								id: 'MCV_volumeCreateArbiter',
								name: 'arbiterAvail',
								fieldLabel: lang_mcv_volume[222],
								labelWidth: 130,
								style: { marginTop: '20px' },
								inputValue: true,
								listeners: {
									change: function (newValue, oldValue, eOpts) {
										if (this.getValue() == true)
											return;

										var currentStepPanel = MCV_volumeCreateWindow.layout.activeItem;
										var currentStepIndex = MCV_volumeCreateWindow.items.indexOf(currentStepPanel);

										if (currentStepIndex == 3
											&& Ext.getCmp('MCV_volumeCreateArbiter').disabled == false
											&& Ext.getCmp('MCV_volumeCreatePolicy').getValue() == 'Distributed'
											&& Ext.getCmp('MCV_volumeCreateReplica').getValue() == 2
											&& Ext.getCmp('MCV_volumeCreateChaining').getValue() == false)
										{
											Ext.MessageBox.show({
												title:lang_mcv_volume[0],
												msg: lang_mcv_volume[234],
												buttons: Ext.MessageBox.OK,
												icon: Ext.MessageBox.WARNING
											});
										}
									}
								}
							}
						]
					},
					{
						xtype: 'BaseWizardDescPanel',
						items: [
							{
								border: false,
								style: {marginBottom: '20px'},
								html: '[ Distributed ]<br><br>' + lang_mcv_volume[13]
							},
							{
								border: false,
								style: {marginBottom: '20px'},
								html: '[ Network RAID ]<br><br>' + lang_mcv_volume[12]
							},
							{
								border: false,
								html: '[ Shard ]<br><br>' + lang_mcv_volume[14]
							}
						]
					}
				]
			},
		]
	}
);

/** 클러스터 볼륨 생성 step 5 **/

// 클러스터 볼륨 목록 그리드
var MCV_volumeCreateNodeGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumeCreateNodeGrid',
		store: MCV_volumeCreateNodeGridStore,
		title: lang_mcv_volume[15],
		height: 340,
		loadMask: true,
		frame: true,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				select: updateCreateMaxSize,
				selectall: updateCreateMaxSize,
				deselect: updateCreateMaxSize,
				deselectall: updateCreateMaxSize,
			}
		},
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'label',
					id: 'MCV_volumeCreateNodeTotal',
					style: 'padding-right: 5px;'
				}
			]
		},
		columns: [
			{
				flex: 4,
				text: lang_mcv_volume[16],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Hostname'
			},
			{
				flex: 3,
				text: lang_mcv_volume[52],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'HW_Status'
			},
			{
				flex: 3,
				text: lang_mcv_volume[53],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'SW_Status'
			},
			{
				flex: 4,
				text: lang_mcv_volume[18],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Used'
			},
			{
				flex: 4,
				text: lang_mcv_volume[19],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Free_Size'
			},
			{
				dataIndex: 'Storage_IP',
				hidden: true
			}
		]
	}
);

// 클러스터 생성5 - 노드, 볼륨 크기 설정
var MCV_volumeCreateStep5Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeCreateStep5Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		border: false,
		frame: false,
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[9]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(1);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[24]
								+ ', '
								+ lang_mcv_volume[25] + '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(2);
									updateCreatewWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[89]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(3);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mcv_volume[71] + ', ' + lang_mcv_volume[21]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mcv_volume[220]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mcv_volume[219]
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align: 'stretch'
						},
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding:0;',
								style: { marginBottom: '10px' },
								items: [MCV_volumeCreateNodeGrid]
							},
							{
								xtype: 'BasePanel',
								layout: 'vbox',
								bodyStyle: 'padding:0;',
								maskOnDisable: false,
								items: [
									{
										xtype: 'BasePanel',
										id: 'MCV_volumeCreateAssignMax',
										bodyStyle: { padding: 0 },
										style: {marginBottom: '10px'},
										layout: 'hbox',
										maskOnDisable: false,
										items: [
											{
												xtype: 'label',
												text: lang_mcv_volume[22] + ': ',
												style: { marginTop: '5px' },
												minWidth: 130
											},
											{
												xtype: 'label',
												id: 'MCV_volumeCreateAssignMaxSize',
												style: { marginTop: '5px', marginLeft: '10px' }
											}
										]
									},
									{
										xtype: 'BasePanel',
										id: 'MCV_volumeCreateAssignArbiter',
										bodyStyle: { padding: 0 },
										style: { marginBottom: '10px' },
										layout: 'hbox',
										maskOnDisable: false,
										items: [
											{
												xtype: 'label',
												text: lang_mcv_volume[253],
												style: { marginTop: '5px' },
												minWidth: 130
											},
											{
												xtype: 'label',
												id: 'MCV_volumeCreateAssignArbiterSize',
												style: { marginTop: '1px', marginLeft: '10px' }
											}
										]
									},
									{
										xtype: 'BasePanel',
										bodyStyle: { padding: 0 },
										layout: 'hbox',
										maskOnDisable: false,
										items: [
											{
												xtype: 'textfield',
												id: 'MCV_volumeCreateAssign',
												fieldLabel: lang_mcv_volume[21],
												allowBlank: false,
												vtype: 'reg_realNumber',
												enableKeyEvents: true
											},
											{
												xtype: 'BaseComboBox',
												id: 'MCV_volumeCreateAssignType',
												hideLabel: true,
												style: { marginLeft: '10px' },
												width: 70,
												store: new Ext.data.SimpleStore({
													fields: ['AssignType', 'AssignCode'],
													data:[
														['GiB', 'GiB'],
														['TiB', 'TiB']
													]
												}),
												value: 'GiB',
												displayField: 'AssignType',
												valueField: 'AssignCode'
											}
										]
									}
								]
							}
						]
					}
				]
			}
		]
	}
);

// 클러스터 생성6 - 입력 내용 확인
var MCV_volumeCreateStep6Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeCreateStep6Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		border: false,
		frame: false,
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[9]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(1);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[24]
								+ ', '
								+ lang_mcv_volume[25]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(2);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[89]
								+ '</span>',
						listeners:{
							afterrender: function (){
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(3);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						html: '<span class="m-wizard-side-link">'
								+ lang_mcv_volume[71]
								+ ', '
								+ lang_mcv_volume[21]
								+ '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MCV_volumeCreateWindow.layout.setActiveItem(4);
									updateCreateWindow();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mcv_volume[220]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mcv_volume[221]
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align: 'stretch',
						},
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[241] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreatePoolCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateStep6TypePanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[9] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateTypeCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
									items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[24] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateNameCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateStep6SendTypePanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[25] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateSendTypeCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateStep6PolicyPanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[89] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreatePolicyCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateStep6DuplicatePanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										id: 'MCV_volumeCreateReplicaLabel',
										html: lang_mcv_volume[11] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateReplicaCheck',
										style: {marginBottom: '20px'}
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateChainLabel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[188] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateChainCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateArbiterLabel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[222] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateArbiterCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateShardBlockSizeLabel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[235] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateShardBlockSizeCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateNodePanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								autoHeight: true,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[15] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateNodeCheck',
										flex: 1,
										cls: 'line-break',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateSizePanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[21] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateSizeCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateTargetPanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[242] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateTargetCheck',
										style: { marginBottom: '20px' }
									}
								]
							},
							{
								xtype: 'BasePanel',
								id: 'MCV_volumeCreateTargetOptPanel',
								hidden: true,
								bodyStyle: 'padding:0;',
								layout: 'hbox',
								maskOnDisable: false,
								items: [
									{
										xtype: 'label',
										html: lang_mcv_volume[243] + ': ',
										width: 130
									},
									{
										xtype: 'label',
										id: 'MCV_volumeCreateTargetOptCheck',
										style: { marginBottom: '20px' }
									}
								]
							}
						]
					}
				]
			}
		]
	}
);

/** 클러스터 볼륨 생성 WINDOW **/
var MCV_volumeCreateWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCV_volumeCreateWindow',
		layout: 'card',
		title: lang_mcv_volume[29],
		maximizable: false,
		autoHeight: true,
		width: 770,
		height: 610,
		activeItem: 0,
		tools: [
			{
				type: 'help',
				handler: function (event, toolEl, panel) {
					if ($.cookie('language') == 'ko')
					{
						manualWindowOpen('clusterVolume', '#2332-볼륨-생성');
					}
					else
					{
						manualWindowOpen('clusterVolume', '#2332-Creating-Cluster-Volume');
					}
				}
			}
		],
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MCV_volumeCreateStep1',
				items: [MCV_volumeCreateStep1Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MCV_volumeCreateStep2',
				items: [MCV_volumeCreateStep2Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MCV_volumeCreateStep3',
				items: [MCV_volumeCreateStep3Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MCV_volumeCreateStep4',
				items: [MCV_volumeCreateStep4Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MCV_volumeCreateStep5',
				items: [MCV_volumeCreateStep5Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MCV_volumeCreateStep6',
				items: [MCV_volumeCreateStep6Panel]
			}
		],
		fbar: [
			{
				text: lang_mcv_volume[30],
				id: 'MCV_volumeCreateWindowCancelBtn',
				width: 70,
				disabled: false,
				border: true,
				handler: function () {
					MCV_volumeCreateWindow.close();
				}
			},
			'->',
			{
				text: lang_mcv_volume[31],
				id: 'MCV_volumeCreateWindowPreviousBtn',
				width: 70,
				disabled: false,
				handler: function () {
					var curr_step = MCV_volumeCreateWindow.layout.activeItem;
					var curr_idx  = MCV_volumeCreateWindow.items.indexOf(curr_step);
					var mv_idx    = 1;

					// MCV_volumeCreateStep4 이후부터의 페이지
					if (curr_idx > 3)
					{
						var pool = MCV_volumeCreatePoolGrid.getSelectionModel().getSelection()[0];
						
						//LOCAl유형일때 MCV_volumeCreateStep2로 이동, EXTERNAM유형일때 MCV_volumeCreateStep3로 이동
						if(pool.get('Pool_Type').toUpperCase() == 'LOCAL')
						{
							mv_idx = 2;
						}
						else if (pool.get('Pool_Type').toUpperCase() == 'EXTERNAL')
						{
							mv_idx = 3;
						}
					}

					MCV_volumeCreateWindow.layout.setActiveItem(curr_idx - mv_idx);
					updateCreateWindow();
				}
			},
			{
				text: lang_mcv_volume[32],
				id: 'MCV_volumeCreateWindowNextBtn',
				width: 70,
				disabled: false,
				handler: function () {
					var curr_step = MCV_volumeCreateWindow.layout.activeItem;
					var curr_idx  = MCV_volumeCreateWindow.items.indexOf(curr_step);

					MCV_volumeCreateWindow.layout.setActiveItem(curr_idx + 1);
					updateCreateWindow();
				}
			},
			{
				text: lang_mcv_volume[86],
				id: 'MCV_volumeCreateWindowOKBtn',
				width: 70,
				disabled: false,
				handler: function () {
					// 선택된 그리드의 전송값 추출
					var node_selected = MCV_volumeCreateNodeGrid.getSelectionModel().getSelection();
					var pool_selected = MCV_volumeCreatePoolGrid.getSelectionModel().getSelection()[0];

					Ext.MessageBox.wait(lang_mcv_volume[34], lang_mcv_volume[0]);

					// 볼륨 생성 유형
					var vol_name    = Ext.getCmp('MCV_volumeCreateName').getValue();
					var pool_name   = pool_selected.get('Pool_Name');
					var pool_type   = pool_selected.get('Pool_Type');
					var provision   = Ext.getCmp('MCV_volumeCreateTypeThick').getValue() ? 'thick' : 'thin';
					var transport   = Ext.getCmp('MCV_volumeCreateSendType').getValue();
					var policy      = Ext.getCmp('MCV_volumeCreatePolicy').getValue();
					var replica_num = Ext.getCmp('MCV_volumeCreateReplica').getValue();
					var shard       = policy == 'Shard' ? true : false;
					var shard_bsize = Ext.getCmp('MCV_volumeCreateShardBlockSize').getValue();
					var arbiter     = Ext.getCmp('MCV_volumeCreateArbiter').getValue();
					var code_count  = Ext.getCmp('MCV_volumeCreateCodeCount').getValue();

					// 크기
					var size = Ext.getCmp('MCV_volumeCreateAssign').getValue();
					var unit = Ext.getCmp('MCV_volumeCreateAssignType').getValue();

					var percent = '';
					var max_size = convertSizeToMB(
							document.getElementById('MCV_volumeCreateAssignMaxSize').innerHTML
							);
					var vol_size
						= convertSizeToMB(
								Ext.getCmp('MCV_volumeCreateAssign').getValue()
								+ ' '
								+ Ext.getCmp('MCV_volumeCreateAssignType').getValue());

					percent = Math.floor(vol_size / max_size * 100);

					if (percent == 100)
					{
						percent = percent + '%FREE';
					}
					else
					{
						percent = null;
					}
					
					if (unit == 'GiB')
					{
						size = size + 'G';
					}
					else if (unit == 'TiB')
					{
						size = size + 'T';
					}
					else if (unit == 'PiB')
					{
						size = size + 'P';
					}

					// 노드
					var node_list = node_selected.map(
						function (record) {
							return record.get('Storage_IP');
						}
					);

					GMS.Ajax.request({
						url: '/api/cluster/volume/create',
						method: 'POST',
						timeout: 120000,
						jsonData: {
							argument: {
								// 볼륨풀 유형
								Pool_Type: pool_type,
								// 볼륨풀 이름
								Pool_Name: pool_name,
								// 프로비저닝(thick, thin)
								Provision: provision,
								// 볼륨 이름
								Volume_Name: vol_name,
								// 전송 유형,
								Transport_Type: transport,
								// 분산 정책
								Volume_Policy: {
									// 분산
									Distributed: policy == 'Distributed' || policy == 'Shard' ? 'true' : 'false',
									// 소거 코드 노드 수
									NetworkRAID: code_count,
								},
								// 체인 모드
								Chaining: Ext.getCmp('MCV_volumeCreateChaining').getValue() ? 'true' : 'false',
								// 샤딩 여부
								Shard: shard ? 'true' : 'false',
								// 샤딩할 단위 블록 크기
								Shard_Block_Size: shard ? shard_bsize : '',
								// 복제수
								Replica: replica_num,
								// 노드 목록
								Node_List: node_list,
								// 노드별 할당 용량
								Capacity: size,
								// lvcreate --extents 용도
								Capacity_Percent: percent,
								// 외부 볼륨 마운트 타겟
								External_Target: Ext.getCmp('MCV_volumeCreateExtTarget').getValue(),
								// 외부 볼륨 마운트 옵션
								External_Options: Ext.getCmp('MCV_volumeCreateExtOpts').getValue(),
							}
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							// 아비터
							if (pool_type.toUpperCase() != 'EXTERNAL'
								&& policy != 'NetworkRAID'
								&& replica_num == 2
								&& arbiter == true
								|| (policy == 'Shard' && replica_num == 2))
							{
								GMS.Ajax.request({
									url: '/api/cluster/volume/arbiter/attach',
									timeout: 60000,
									method: 'POST',
									jsonData: {
										argument: {
											Pool_Type: pool_type,
											Volume_Name: vol_name,
											Shard: shard,
											Shard_Block_Size: shard_bsize,
										}
									},
									callback: function (options, success, response, decoded) {
										loadVolumeStore();

										// 생성 창 닫기
										MCV_volumeCreateWindow.hide();

										if (!success || !decoded.success)
											return;

										Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[35]);
									}
								});
							}
							else
							{
								loadVolumeStore();

								// 생성 창 닫기
								MCV_volumeCreateWindow.hide();

								Ext.MessageBox.alert(
									lang_mcv_volume[0],
									decoded.success ? lang_mcv_volume[35] : decoded.msg);
							}
						},
					});
				}
			},
			{
				text: lang_mcv_volume[37],
				id: 'MCV_volumeCreateWindowCloseBtn',
				width: 70,
				disabled: false,
				handler: function () {
					MCV_volumeCreateWindow.close();
				}
			},
		]
	}
);

/*
 * 클러스터 볼륨 정보 VIEW
 */

// 클러스터 볼륨 정보 VIEW GRID
var MCV_volumeViewNodeGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumeViewNodeGrid',
		store: MCV_volumeViewNodeStore,
		multiSelect: false,
		title: lang_mcv_volume[15],
		height: 200,
		columns: [
			{
				flex: 1,
				text: lang_mcv_volume[16],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Hostname'
			},
			{
				flex: 1,
				text: lang_mcv_volume[72],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Used'
			},
			{
				flex: 1,
				text: lang_mcv_volume[52],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'HW_Status'
			},
			{
				flex: 1,
				text: lang_mcv_volume[53],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'SW_Status'
			}
		]
	}
);

// 클러스터 볼륨 정보 VIEW Panel
var MCV_volumeViewPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeViewPanel',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[90] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewPool'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[24] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewName'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[17] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewStatus'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[59] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewSize'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[9] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewProvision'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[89] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewPolicy'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[11] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewReplica'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[55] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewDistributed'
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeViewCodeCountPanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[10] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewCodeCount'
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeViewShardPanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[235] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewShard'
					}
				]
			},
			/*
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeViewTierPanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				hidden: true,
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[130] + ': ',
						width: '130px'
					},
					{
						xtype: 'button',
						id: 'MCV_volumeViewTierCreate',
						text: lang_mcv_volume[229],
						handler: function () {
							// 볼륨명
							var name = document.getElementById('MCV_volumeViewName').innerHTML;

							// 프로비저닝
							var provision;

							if (document.getElementById('MCV_volumeViewProvision').innerHTML
								== lang_mcv_volume[128])
							{
								provision = 'thin';
							}
							else
							{
								provision = 'thick';
							}

							// 티어링 생성 팝업
							showTieringWindow(name, 'Create', provision);
						}
					},
					{
						xtype: 'button',
						id: 'MCV_volumeViewTierInfo',
						text: lang_mcv_volume[230],
						handler: function () {
							// 볼륨명
							var name = document.getElementById('MCV_volumeViewName').innerHTML;

							// 프로비저닝
							var provision;

							if (document.getElementById('MCV_volumeViewProvision').innerHTML
								== lang_mcv_volume[128])
							{
								provision = 'thin';
							}
							else
							{
								provision = 'thick';
							}

							// 티어링 관리 팝업
							showTieringWindow(name, 'Change', provision);
						}
					}
				]
			},
			*/
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeViewArbiterPanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[222] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeViewArbiterAvail',
						text: lang_mcv_volume[97]
					},
					{
						xtype: 'button',
						id: 'MCV_volumeViewArbiterButton',
						text: lang_mcv_volume[223],
						handler: function () {
							var me = this;

							// 볼륨명
							var name = document.getElementById('MCV_volumeViewName').innerHTML;
							var pool_name;
							var pool_type;
							var pool_free_size;
							var volume_size;

							MCV_volumeGridStore.each(
								function (record)
								{
									if (record.get('Volume_Name') == name)
									{
										pool_type   = record.data.Pool_Type;
										pool_name   = record.data.Pool_Name;
										volume_size = record.data.Size+'iB';

										return false;
									}
								}
							);

							MCV_volumePoolStore.each(
								function(record)
								{
									if (record.data.Pool_Name == pool_name)
									{
										pool_free_size = record.data.Pool_Free_Size;
										return false;
									}
								}
							);

							// 볼륨풀 남은 크기 
							var pool_free_size_mb = convertSizeToMB(pool_free_size);
							// 아비터 활성화를위해 필요한 디스크 크기 
							var volume_size_mb    = convertSizeToMB(volume_size);
							var arbiter_size_mb   = getArbiterSizeMB(volume_size_mb);

							// 아비터 활성화
							Ext.MessageBox.confirm(
								lang_mcv_volume[0],
								lang_mcv_volume[224],
								function (btn, text) {
									if (btn != 'yes')
										return;

									// 볼륨풀 남은 크기와 아비터 활성화를 위해 필요한 크기 비교
									if (pool_free_size_mb > arbiter_size_mb)
									{
										Ext.MessageBox.wait(lang_mcv_volume[225], lang_mcv_volume[0]);

										GMS.Ajax.request({
											url: '/api/cluster/volume/arbiter/attach',
											timeout: 60000,
											jsonData: {
												argument: {
													Volume_Name: name,
													Pool_Type: pool_type,
												}
											},
											callback: function (options, success, response, decoded) {
												if (!success || !decoded.success)
													return;

												loadVolumeStore();
												MCV_volumeViewWindow.hide();
												Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[226]);
											}
										});
									}
									else
									{
										Ext.MessageBox.alert(lang_mcv_volume[223], lang_mcv_volume[253]);
									}
								}
							);
						}
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[25] + ': ',
						width: '130px'
					},
					{
							xtype: 'label',
							id: 'MCV_volumeViewTransport'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				items: [MCV_volumeViewNodeGrid]
			}
		]
	});

// 클러스터 볼륨 정보 VIEW WINDOW
var MCV_volumeViewWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCV_volumeViewWindow',
		title: lang_mcv_volume[54],
		maximizable: false,
		autoHeight: true,
		width: 600,
		items: [MCV_volumeViewPanel],
		buttons: [
			{
				id: 'MCV_volumeViewCloseBtn',
				text: lang_mcv_volume[37],
				handler: function () {
					MCV_volumeViewWindow.hide();
				}
			}
		]
	});

/*
 * 클러스터 볼륨 Expand
 */

// 클러스터 볼륨 정보 Expand GRID
var MCV_volumeExpandNodeGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumeExpandNodeGrid',
		store: MCV_volumeExpandNodeStore,
		multiSelect: false,
		title: lang_mcv_volume[15],
		height: 200,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				selectall: function () {
					// 최대 볼륨 크기 계산
					Ext.defer(function () { updateExpandMaxSize() }, 100);
				},
				deselectall: function () {
					// 최대 볼륨 크기 계산
					Ext.defer(function () {
						// 볼륨 상태
						var volumeStatus = Ext.getCmp('MCV_volumeExpandStatus').text;

						// 노드 추가 실패 시
						if (volumeStatus == lang_mcv_volume[214])
						{
							Ext.getCmp('MCV_volumeExpandAssignSize')
								.setText(Ext.getCmp('MCV_volumeExpandSize').text);
						}
						else
						{
							updateExpandMaxSize();
						}
					}, 100);
				}
			}
		},
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'label',
					id: 'MCV_volumeExpandNodeTotal',
					style: 'padding-right: 5px;'
				}
			]
		},
		columns: [
			{
				flex: 1.2,
				text: lang_mcv_volume[16],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Hostname'
			},
			{
				flex: 1.2,
				text: lang_mcv_volume[201],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Brick_Size'
			},
			{
				flex: 1.2,
				text: lang_mcv_volume[18],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Used',
				hidden: true
			},
			{
				flex: 1,
				text: lang_mcv_volume[52],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'HW_Status'
			},
			{
				flex: 1,
				text: lang_mcv_volume[53],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'SW_Status'
			},
			{
				flex: 1.4,
				text: lang_mcv_volume[19],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Free_Size'
			},
			{
				dataIndex: 'inclusion',
				hidden: true
			},
			{
				dataIndex: 'Storage_IP',
				hidden: true
			},
			{
				dataIndex: 'expandable',
				hidden: true
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				//최대 볼륨크기 계산
				if (record.get('inclusion') != "true")
				{
					Ext.defer(function () { updateExpandMaxSize() }, 100);
				}
			},
			selectionchange: function (model, records) {
				if (Ext.getCmp('MCV_volumeExpandNodeAdd').getValue() == true)
				{
					if (Ext.getCmp('MCV_volumeExpandType').text == lang_mcv_volume[129])
					{
						// 볼륨 타입이 고정 할당 일 때
						Ext.each(
							records,
							function (record) {
								if (record.get('expandable') != 'true')
								{
									var expandVolumeCheck = lang_mcv_volume[88]
										.replace('@', Ext.getElementById('MCV_volumeExpandSize').innerHTML);

									Ext.MessageBox.alert(lang_mcv_volume[0], expandVolumeCheck);

									MCV_volumeExpandNodeGrid.getSelectionModel().deselect(record, false, false);
								}
							});
					}
					else
					{
						// 볼륨 타입이 동적 할당 일 때
						Ext.each(records, function (record) {
							if (record.get('expandable') != 'true')
							{
								// 볼륨 풀 사용률
								var selectNodeUsed = record.get('Used').substring(0, record.get('Used').length-1);

								if (selectNodeUsed >= 90)
								{
									Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[181]);
								}
								else if (selectNodeUsed == 100)
								{
									Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[182]);
									MCV_volumeExpandNodeGrid.getSelectionModel().deselect(record, false, false);
								}
							}
						});
					}

					// 선택한 노드릴스트 배열
					var selectedRecords = [];

					// 추가로 선택된 노드리스트 OBJ
					var nodeSelectedRec = MCV_volumeExpandNodeGrid.getSelectionModel().getSelection();

					// 추가로 선택한 노드 리스트
					Ext.each(nodeSelectedRec, function (item) {
						selectedRecords.push(item);
					});

					// 볼륨 생성 시 추가한 노드 리스트
					MCV_volumeExpandNodeGrid.store.each(
						function (record) {
							if (record.get('inclusion') == 'true')
							{
								selectedRecords.push(record);
							}
						}
					);

					// 추가로 선택한 노드 + 볼륨 생성 시 추가한 노드 선택
					MCV_volumeExpandNodeGrid.getSelectionModel().select(selectedRecords, false, false);
				}
			}
		},
		viewConfig: {
			forceFit: true,
			getRowClass: function (record, rowIndex, p, store) {
				if (Ext.getCmp('MCV_volumeExpandType').text == lang_mcv_volume[129])
				{
					var statusRowValue = record.get('expandable').toLowerCase();

					if (statusRowValue == 'false')
					{
						return 'disabled-row';
					}
				}
				else
				{
					var statusRowValue = record.get('expandable').toLowerCase();

					if (statusRowValue == 'false')
					{
						var used = record.get('Used').substring(0, record.get('Used').length-1);

						if (used == 100)
						{
							return 'disabled-row';
						}
					}
				}
			},
			markDirty: false
		}
	}
);

// Gluster 볼륨 정보 Expand Panel
var MCV_volumeExpandPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeExpandPanel',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[24] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandName'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[17] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandStatus'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[9] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandType'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[89] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandPolicy'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[11] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandReplica'
					}
				]
			},
			{
				xtype: 'label',
				id: 'MCV_volumeExpandCodeCount',
				hidden: true
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[55] + ': ',
						minWidth: 120
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandDistributed',
						style: { marginLeft: '10px' }
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandDisperseCount',
						hidden: true
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeExpandShardBlockSizePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[235] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandShardBlockSize'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				hidden: true,
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[188] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandChaining'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				hidden: true,
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[222] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandArbiter'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[192] + ': ',
						width: '130px'
					},
					{
						xtype: 'radiogroup',
						anchor: 'none',
						layout: { autoFlex: false },
						defaults: {
							margin: '0 40 0 0'
						},
						items: [
							{
								boxLabel: lang_mcv_volume[193],
								id: 'MCV_volumeExpandSizeChange',
								name: 'expandType',
								inputValue: 'volumeExtendSize',
								checked: true,
								width: '110px'
							},
							{
								boxLabel: lang_mcv_volume[194],
								id: 'MCV_volumeExpandNodeAdd',
								name: 'expandType',
								inputValue: 'nodeAdd'
							}
						],
						listeners: {
							change: function (field, newValue, oldValue) {
								switch (newValue['expandType'])
								{
									case 'volumeExtendSize':
										MCV_volumeExpandNodeStore.clearFilter();

										// 볼륨 확장 시 선택된 노드리스트
										MCV_volumeExpandNodeStore.filter(function (record) {
											return record.get('inclusion') == 'true';
										});

										MCV_volumeExpandNodeGrid.getSelectionModel().select(false);

										// 체크박스 숨김
										MCV_volumeExpandNodeGrid.headerCt.items.getAt(0).hide();

										// 확장할 볼륨 크기 입력창
										Ext.getCmp('MCV_volumeExtendSize').show();
										Ext.getCmp('MCV_volumeExtendSizeUnit').show();

										var provision = document.getElementById('MCV_volumeExpandType').innerHTML;

										// Static allocation
										if (provision == lang_mcv_volume[129])
										{
											Ext.getCmp('MCV_volumeExpandAssignMax').show();
											Ext.getCmp('MCV_volumeExpandAssignMaxSizeBytes').hide();
										}
										// Dynamic allocation
										else if (provision == lang_mcv_volume[128])
										{
											Ext.getCmp('MCV_volumeExpandAssignMax').hide();
										}

										// 확장 후 볼륨 크기 라벨
										Ext.getCmp('MCV_volumeExpandAssignSize').hide();

										// 브릭 크기
										Ext.getCmp('MCV_volumeExpandNodeGrid').down('[dataIndex=Brick_Size]').setVisible(true);

										// 볼륨 풀 사용률
										Ext.getCmp('MCV_volumeExpandNodeGrid').down('[dataIndex=Used]').setVisible(false);

										// 선택한 노드 개수
										Ext.getCmp('MCV_volumeExpandNodeTotal').setText('');

										// 노드 목록 그리드 제목
										Ext.getCmp('MCV_volumeExpandNodeGrid').setTitle(lang_mcv_volume[15]);
										MCV_volumeExpandPanel.doLayout();

										// 최대 생성 가능한 볼륨 용량
										updateExpandMaxAssignSize()

										break;
									case 'nodeAdd':
										MCV_volumeExpandNodeStore.clearFilter();

										// 볼륨 확장 시 선택된 노드 리스트
										var selected = [];

										MCV_volumeExpandNodeGrid.store.each(
											function (record) {
												// inclusion가 true인 record 선택
												if (record.get('inclusion') == 'true')
												{
													selected.push(record);
												}
											}
										);

										// 체크박스 보임
										MCV_volumeExpandNodeGrid.headerCt.items.getAt(0).show();
										MCV_volumeExpandNodeGrid.getSelectionModel().select(selected, true);
										//MCV_volumeExpandNodeStore.sort('inclusion', 'ASC');

										// 확장할 볼륨 크기 입력창
										Ext.getCmp('MCV_volumeExtendSize').reset();
										Ext.getCmp('MCV_volumeExtendSizeUnit').reset();
										Ext.getCmp('MCV_volumeExtendSize').hide();
										Ext.getCmp('MCV_volumeExtendSizeUnit').hide();
										Ext.getCmp('MCV_volumeExpandAssignMax').hide();

										// 확장 후 볼륨 크기 라벨
										Ext.getCmp('MCV_volumeExpandAssignSize').show();

										// 볼륨 풀 사용률
										Ext.getCmp('MCV_volumeExpandNodeGrid').down('[dataIndex=Used]').setVisible(true);

										// 브릭 크기
										Ext.getCmp('MCV_volumeExpandNodeGrid').down('[dataIndex=Brick_Size]').setVisible(false);

										// 선택한 노드 개수
										Ext.getCmp('MCV_volumeExpandNodeTotal').setText(lang_mcv_volume[237] + ': 0');

										// 복제 수
										var replica_num = Ext.getCmp('MCV_volumeExpandReplica').text;

										// code 노드 수
										var code_count = Ext.getCmp('MCV_volumeExpandCodeCount').text;

										// 노드 선택 조건
										var title;

										if (Ext.getCmp('MCV_volumeExpandPolicy').text == 'NetworkRAID')
										{
											title = lang_mcv_volume[15] + ' ('
													+ lang_mcv_volume[42].replace('@', (code_count * 2) + 1)
													+ ')';
										}
										else if (Ext.getCmp('MCV_volumeExpandPolicy').text == 'Distributed')
										{
											if (Ext.getCmp('MCV_volumeExpandChaining').text == true)
											{
												title = lang_mcv_volume[15] + ' (' + lang_mcv_volume[39] + ')';
											}
											else if (Ext.getCmp('MCV_volumeExpandArbiter').text == true)
											{
												title = lang_mcv_volume[15] + ' ('
														+ lang_mcv_volume[47]
															.replace('@', (replica_num * 2))
															.replace('*', replica_num)
														+ ')';
											}
											else
											{
												if (replica_num == 1)
												{
													title = lang_mcv_volume[15] + ' (' + lang_mcv_volume[38] + ')';
												}
												else if (replica_num == 2)
												{
													title = lang_mcv_volume[15] + ' (' + lang_mcv_volume[43] + ')';
												}
												else if (replica_num == 3)
												{
													title = lang_mcv_volume[15] + ' (' + lang_mcv_volume[44] + ')';
												}
												else if (replica_num == 4)
												{
													title = lang_mcv_volume[15] + ' (' + lang_mcv_volume[45] + ')';
												}
											}
										}
										else if (Ext.getCmp('MCV_volumeExpandPolicy').text == 'Shard')
										{
											if (replica_num == 1)
											{
												title = lang_mcv_volume[15] + ' (' + lang_mcv_volume[46] + ')';
											}
											else if (replica_num >= 2)
											{
												title = lang_mcv_volume[15] + ' ('
													+ lang_mcv_volume[47]
														.replace('@', (replica_num * 2))
														.replace('*', replica_num)
													+ ')';
											}
										}

										Ext.getCmp('MCV_volumeExpandNodeGrid').setTitle(title);

										MCV_volumeExpandPanel.doLayout();

										// 클러스터 볼륨 확장 시 생성될 볼륨 크기 계산
										updateExpandMaxSize();

										break;
								}
							}
						}
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[238] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandSize'
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeExpandAssignMax',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[196] + ': ',
						minWidth: 130
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandAssignMaxSize',
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandAssignMaxSizeBytes',
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[60] + ': ',
						minWidth: 130
					},
					{
						xtype: 'label',
						id: 'MCV_volumeExpandAssignSize',
						style: { color: 'red' }
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'textfield',
								id: 'MCV_volumeExtendSize',
								allowBlank: false,
								vtype: 'reg_realNumber',
								enableKeyEvents: true,
								width: 120
							},
							{
								xtype: 'BaseComboBox',
								id: 'MCV_volumeExtendSizeUnit',
								hideLabel: true,
								style: { marginLeft: '10px' },
								width: 70,
								store: new Ext.data.SimpleStore({
									fields: ['SizeUnit', 'SizeCode'],
									data: [
										['GiB', 'G'],
										['TiB', 'T']
									]
								}),
								value: 'G',
								displayField: 'SizeUnit',
								valueField: 'SizeCode'
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				items: [MCV_volumeExpandNodeGrid]
			}
		]
	}
);

// 클러스터 볼륨정보 Expand WINDOW
var MCV_volumeExpandWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCV_volumeExpandWindow',
		title: lang_mcv_volume[198],
		maximizable: false,
		width: 600,
		autoHeight:true,
		autoScroll: false,
		items: [MCV_volumeExpandPanel],
		buttons: [
			{
				id: 'MCV_volumeExpandBtn',
				text: lang_mcv_volume[61],
				handler: function () {
					if (Ext.getCmp('MCV_volumeExpandSizeChange').getValue() == true)
					{
						extendVolume();
					}
					else if (Ext.getCmp('MCV_volumeExpandNodeAdd').getValue() == true)
					{
						expandVolume();
					}
				}
			}
		],
		listeners: {
			show: function (win, eOpts) {
				win.center();
			},
			hide: function (win, eOpts) {
				loadVolumeStore();
			},
		}
	}
);

/*
 * 클러스터 볼륨 삭제
 */
// 클러스터 볼륨 삭제 WINDOW
var MCV_volumeDeleteWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCV_volumeDeleteWindow',
		title: lang_mcv_volume[54],
		maximizable: false,
		autoHeight: true,
		width: 400,
		items: [
			{
				xtype: 'BaseFormPanel',
				id: 'MCV_volumeDeletePanel',
				frame: false,
				defaults: {
					style: {
						marginBottom: '20px'
					}
				},
				items: [
					{
						xtype: 'BasePanel',
						layout: 'column',
						bodyStyle: 'padding: 0;',
						style: { marginLeft: '15px', marginBottom: '20px' },
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[24] + ': ',
								width: 85
							},
							{
								xtype: 'label',
								id: 'MCV_volumeDeleteName',
								width: 130
							}
						]
					},
					{
						xtype: 'textfield',
						fieldLabel: lang_mcv_volume[65],
						id: 'MCV_volumeDeleteReason',
						name: 'volumeDeleteReason',
						allowBlank: false,
						labelWidth: 80,
						width: 300,
						style: { marginLeft: '15px', marginBottom: '20px' }
					},
					{
						xtype: 'textfield',
						fieldLabel: lang_mcv_volume[66],
						id: 'MCV_volumeDeletePassword',
						name: 'volumeDeletePassword',
						inputType: 'password',
						allowBlank: false,
						labelWidth: 80,
						width: 300,
						style: { marginLeft: '15px' }
					},
					/*
					{
						xtype: 'textfield',
						id: 'MCV_volumeDeleteTier',
						name: 'volumeDeleteTier',
						style: { marginLeft: '15px' },
						hidden: true
					}
					*/
				]
			}
		],
		buttons: [
			{
				id: 'MCV_volumeDeleteCloseBtn',
				text: lang_mcv_volume[33],
				handler: function () {
					if (!Ext.getCmp('MCV_volumeDeleteReason').isValid())
					{
						return false;
					}

					if (!Ext.getCmp('MCV_volumeDeletePassword').isValid())
					{
						return false;
					}

					var vol_name = document.getElementById('MCV_volumeDeleteName').innerHTML;

					var is_shared = false;
					GMS.Ajax.request({
						url: '/api/cluster/share/list',
						method: 'POST',
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							decoded.entity.forEach((e) => {
								if (vol_name == e.Volname)
								{
									is_shared = true;
								}
							});
						}
					});

					if (is_shared == true)
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[254]);
						return false;
					}

					requestVolumeDelete(vol_name);

					/*
					if (Ext.getCmp('MCV_volumeDeleteTier').getValue() == 'none')
					{
						requestVolumeDelete(vol_name);
						return;
					}

					Ext.Ajax.request({
						url: '/api/cluster/volume/tier/detach',
						jsonData: {
							argument: {
								Volume_Name: vol_name,
							}
						},
						callback: function (options, success, response) {
							var responseData = Ext.decode(response.responseText);

							if (!success || !responseData.success)
							{
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								Ext.MessageBox.alert(lang_mcv_volume[0], responseData.msg);

								return;
							}

							requestVolumeDelete(vol_name);
						},
					});
					*/
				}
			}
		]
	}
);

/*
 * 티어링

// 티어링 노드 목록 그리드
var MCV_volumeTieringCreateNodeGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumeTieringCreateNodeGrid',
		store: MCV_volumeTieringCreateNodeGridStore,
		title: lang_mcv_volume[15],
		height: 260,
		loadMask: true,
		cls: 'line-break',
		multiSelect: false,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				selectall: function () {
					// 최대 티어링 크기 계산
					Ext.defer(
						function () {
							if (Ext.getCmp('MCV_volumeTieringCreatePoolName')
								.valueModels[0].get('Pool_Type') == 'thick')
							{
								updateTieringCreateMaxSize();
							}
						},
						100
					);
				},
				deselectall: function () {
					// 최대 티어링 크기 계산
					Ext.defer(
						function () {
							if (Ext.getCmp('MCV_volumeTieringCreatePoolName')
								.valueModels[0].get('Pool_Type') == 'thick')
							{
								updateTieringCreateMaxSize();
							}
						},
						100
				);
				}
			}
		},
		columns: [
			{
				flex: 1.3,
				text: lang_mcv_volume[16],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Hostname'
			},
			{
				flex: 1,
				text: lang_mcv_volume[52],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'HW_Status'
			},
			{
				flex: 1,
				text: lang_mcv_volume[53],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'SW_Status'
			},
			{
				flex: 1,
				text: lang_mcv_volume[140],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LV_Used'
			},
			{
				flex: 1,
				text: lang_mcv_volume[141],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LV_Size'
			},
			{
				flex: 1,
				text: lang_mcv_volume[18],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Used'
			},
			{
				flex: 1.3,
				text: lang_mcv_volume[19],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Free_Size'
			}
		],
		listeners: {
			selectionchange: function (model, records) {
				if (Ext.getCmp('MCV_volumeTieringCreatePoolName')
					.valueModels[0].get('Pool_Type') == 'thick')
				{
					updateTieringCreateMaxSize();
				}
			}
		},
		viewConfig: {
			markDirty: false
		}
	}
);

// 티어링 생성 PANEL
var MCV_volumeTieringCreatePanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeTieringCreatePanel',
		frame: false,
		layout: { type:'vbox', align:'stretch' },
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				style: {marginBottom: '30px'},
				html: lang_mcv_volume[131]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[24] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeTieringCreateName'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				hidden: true,
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[90] + ': ',
						width: '130px'
					},
					{
						xtype: 'BaseComboBox',
						id: 'MCV_volumeTieringCreatePoolName',
						width: 120,
						store: MCV_volumeTieringCreatePoolListStore,
						displayField: 'Pool_Name'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[11] + ': ',
						width: '130px',
						style: { marginTop: '5px' }
					},
					{
						xtype: 'BaseComboBox',
						id: 'MCV_volumeTieringCreateReplicaCount',
						allowBlank: false,
						vtype: 'reg_realNumber',
						enableKeyEvents: true,
						width: 120,
						store: new Ext.data.SimpleStore({
							fields: ['VolumeDupView', 'VolumeDupCode'],
							data: [
								[1, 1],
								[2, 2],
								[3, 3],
								[4, 4]
							]
						}),
						value: 2,
						displayField: 'VolumeDupView',
						valueField: 'VolumeDupCode',
						listeners: {
							change: function (combo, newValue, oldValue) {
								updateTieringCreateMaxSize();
							}
						}
					},
					{
						xtype: 'label',
						id: 'MCV_volumeTieringCreateReplicaCountLabel'
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeTieringCreateTieringSizeMax',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[135] + ': ',
						minWidth: 130
					},
					{
						xtype: 'label',
						id: 'MCV_volumeTieringCreateTieringSizeMaxSize',
						style: { marginLeft: '10px' }
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[134] + ': ',
								width: '130px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringCreateTieringSize',
								allowBlank: false,
								vtype: 'reg_realNumber',
								enableKeyEvents: true,
								width: 120
							},
							{
								xtype: 'BaseComboBox',
								id: 'MCV_volumeTieringCreateTieringSizeUnit',
								hideLabel: true,
								style: { marginLeft: '10px' },
								width: 70,
								store: new Ext.data.SimpleStore({
									fields: ['AssignType', 'AssignCode'],
									data: [
										['GiB', 'GiB'],
										['TiB', 'TiB']
									]
								}),
								value: 'GiB',
								displayField: 'AssignType',
								valueField: 'AssignCode'
							},
							{
								xtype: 'label',
								id: 'MCV_volumeTieringCreateTieringSizeLabel'
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCV_volumeTieringOptionBtn',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[138] + ': ',
						width: '130px'
					},
					{
						xtype: 'button',
						text: lang_mcv_volume[139],
						iconCls: 'b-icon-admin_user',
						handler: function () {
							var me = this;

							// 볼륨명
							var Volume_Name = document.getElementById('MCV_volumeTieringCreateName').innerHTML;

							// 티어링 옵션 조회 API
							waitWindow(lang_mcv_volume[0], lang_mcv_volume[167]);

							Ext.Ajax.request({
								url: '/api/cluster/volume/tier/opts',
								jsonData: {
									argument: {
										Volume_Name: Volume_Name
									}
								},
								callback: function (options, success, response) {
									// 데이터 전송 완료 후 wait 제거
									if (waitMsgBox)
									{
										waitMsgBox.hide();
										waitMsgBox = null;
									}

									var responseData = Ext.JSON.decode(response.responseText);

									// 예외 처리에 따른 동작
									if (!success || !responseData.success)
									{
										if (response.responseText == ''
												|| typeof(response.responseText) == 'undefined')
											response.responseText = '{}';

										if (typeof(responseData.msg) === 'undefined')
											responseData.msg = '';

										if (typeof(responseData.code) === 'undefined')
											responseData.code = '';

										var checkValue = '{'
											+ '"title": "' + lang_mcv_volume[0] + '",'
											+ '"content": "' + lang_mcv_volume[51] + '",'
											+ '"msg": "' + responseData.msg + '",'
											+ '"code": "' + responseData.code + '",'
											+ '"response": ' + response.responseText
										+ '}';

										return exceptionDataCheck(checkValue);
									}

									// 티어링 옵션 정보
									var Tier_Opts = responseData.tierOptsGet.Tier_Opts;

									// 볼륨명
									Ext.getCmp('MCV_volumeTieringOptionName').setText(Volume_Name);

									// Tier 동작 모드
									if (Tier_Opts.Tier_Mode == 'cache')
									{
										Ext.getCmp('MCV_volumeTieringOptionTierModeCache').setValue(true);
									}
									else
									{
										Ext.getCmp('MCV_volumeTieringOptionTierModeTest').setValue(true);
									}

									// File migration 시 최대 데이터 양 (1회 시)
									Ext.getCmp('MCV_volumeTieringOptionTierMaxMB').setValue(Tier_Opts.Tier_Max_MB);

									// File migration 시 최대 파일 수 (1회 시)
									Ext.getCmp('MCV_volumeTieringOptionTierMaxFiles').setValue(Tier_Opts.Tier_Max_Files);

									// Promote 수행 사용률
									Ext.getCmp('MCV_volumeTieringOptionTierWatermarkHigh').setValue(Tier_Opts.Watermark.High);

									// Demote 수행 방지 사용률
									Ext.getCmp('MCV_volumeTieringOptionTierWatermarkLow').setValue(Tier_Opts.Watermark.Low);

									// Promote 수행 읽기 기준 횟수
									Ext.getCmp('MCV_volumeTieringOptionIOThresholdReadFreq').setValue(Tier_Opts.IO_Threshold.Read_Freq);

									// Promote 수행 쓰기 기준 횟수
									Ext.getCmp('MCV_volumeTieringOptionIOThresholdWriteFreq').setValue(Tier_Opts.IO_Threshold.Write_Freq);

									// Promote 수행 주기
									Ext.getCmp('MCV_volumeTieringOptionMigrationFreqPromote').setValue(Tier_Opts.Migration_Freq.Promote);

									// Demote 수행 주기
									Ext.getCmp('MCV_volumeTieringOptionMigrationFreqDemote').setValue(Tier_Opts.Migration_Freq.Demote);

									MCV_volumeTieringOptionWindow.show();
								}
							});
						}
					}
				]
			},
			{
				xtype: 'textfield',
				id: 'MCV_volumeTieringCreateType',
				hidden: true
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				items: [MCV_volumeTieringCreateNodeGrid]
			}
		]
	}
);

// 티어링 생성 WINDOW
var MCV_volumeTieringCreateWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCV_volumeTieringCreateWindow',
		title: lang_mcv_volume[132],
		maximizable: false,
		autoHeight: true,
		width: 730,
		items: [MCV_volumeTieringCreatePanel],
		fbar:[
			{
				id: 'MCV_volumeTieringCreateBtn',
				text: lang_mcv_volume[86],
				width: 70,
				disabled: false,
				handler: function () {
					createVolumeTiering();
				}
			},
			{
				id: 'MCV_volumeTieringDeleteBtn',
				text: lang_mcv_volume[136],
				width: 70,
				disabled: false,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mcv_volume[0],
						lang_mcv_volume[183],
						function (btn, text) {
							if (btn != 'yes')
								return;

							var vol_name = document.getElementById('MCV_volumeTieringCreateName').innerHTML;
							deleteVolumeTiering(vol_name);
					});
				}
			}
		]
	}
);

// 티어링 옵션 PANEL
var MCV_volumeTieringOptionPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCV_volumeTieringOptionPanel',
		frame: false,
		layout: {type:'vbox', align:'stretch'},
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[24] + ': ',
						width: '130px'
					},
					{
						xtype: 'label',
						id: 'MCV_volumeTieringOptionName'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcv_volume[155] + ': ',
						width: '130px'
					},
					{
						xtype: 'radiogroup',
						id: 'MCV_volumeTieringOptionTierMode',
						anchor: 'none',
						layout: { autoFlex: false },
						defaults: { margin: '0 50 0 0' },
						items: [
							{
								boxLabel: 'Cache',
								id: 'MCV_volumeTieringOptionTierModeCache',
								name: 'tierMode',
								inputValue: 'cache',
								checked: true
							},
							{
								boxLabel: 'Test',
								id: 'MCV_volumeTieringOptionTierModeTest',
								name: 'tierMode',
								inputValue: 'test'
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								html: lang_mcv_volume[156] + ' ' + lang_mcv_volume[218] + ': ',
								width: '280px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionTierMaxMB',
								value: '4000',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[1-9]{1}$|^[1-9]{1}[0-9]{1,4}$|^100000$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","1~100000"));
								},
								enableKeyEvents: true,
								width: 120
							},
							{
								xtype: 'label',
								text: 'MB',
								style: {
									marginTop: '5px',
									marginLeft: '10px'
								}
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								html: lang_mcv_volume[157] + ' ' + lang_mcv_volume[218] + ': ',
								width: '280px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionTierMaxFiles',
								value: '10000',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[1-9]{1}$|^[1-9]{1}[0-9]{1,4}$|^100000$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","1~100000"));
								},
								enableKeyEvents: true,
								width: 120
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				border: false,
				style: { marginBottom: '20px' },
				html: 'Watermark'
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginBottom: '20px',
					marginLeft: '20px'
				},
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[158] + ': ',
								width: '230px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionTierWatermarkHigh',
								value: '90',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[1-9]{1}$|^[1-9]{1}[0-9]{1}$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","1~99"));
								},
								enableKeyEvents: true,
								width: 120
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginBottom: '20px',
					marginLeft: '20px'
				},
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[159] + ': ',
								width: '230px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionTierWatermarkLow',
								value: '75',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[1-9]{1}$|^[1-9]{1}[0-9]{1}$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","1~99"));
								},
								enableKeyEvents: true,
								width: 120,
								listeners: {
									keyup: function (form, e) {
										var WatermarkHigh = Ext.getCmp('MCV_volumeTieringOptionTierWatermarkHigh').getValue();
										var WatermarkLow = Ext.getCmp('MCV_volumeTieringOptionTierWatermarkLow').getValue();

										if (WatermarkLow >= WatermarkHigh)
										{
											Ext.getCmp('MCV_volumeTieringOptionTierWatermarkLow').setValue('');
											Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[174]);
										}
									}
								}
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				border: false,
				style: { marginBottom: '20px' },
				html: 'IO Threshold'
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginBottom: '20px',
					marginLeft: '20px'
				},
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[160] + ': ',
								width: '230px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionIOThresholdReadFreq',
								value: '0',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[0-9]$|^1[0-9]$|^20$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","0~20"));
								},
								enableKeyEvents: true,
								width: 120
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginBottom: '20px',
					marginLeft: '20px'
				},
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[161] + ': ',
								width: '230px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionIOThresholdWriteFreq',
								value: '0',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^([0-9]|1[0-9]|20)$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","0~20"));
								},
								enableKeyEvents: true,
								width: 120
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				border: false,
				style: { marginBottom: '20px' },
				html: 'Migration Frequency'
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginBottom: '20px',
					marginLeft: '20px'
				},
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[162] + ': ',
								width: '230px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionMigrationFreqPromote',
								value: '120',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[1-9]{1}$|^[1-9]{1}[0-9]{1,4}$|^1[0-6]{1}[0-9]{4}$|^17[0-1]{1}[0-9]{3}$|^172[0-7]{1}[0-9]{2}$|^172800$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","1~172800"));
								},
								enableKeyEvents: true,
								width: 120
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginLeft: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding:0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								text: lang_mcv_volume[163] + ': ',
								width: '230px'
							},
							{
								xtype: 'textfield',
								id: 'MCV_volumeTieringOptionMigrationFreqDemote',
								value: '3600',
								allowBlank: false,
								maskRe: /[0-9]/,
								validator: function (v) {
									return /^[1-9]{1}$|^[1-9]{1}[0-9]{1,4}$|^1[0-6]{1}[0-9]{4}$|^17[0-1]{1}[0-9]{3}$|^172[0-7]{1}[0-9]{2}$|^172800$/.test(v)? true : (lang_vtype[0] + '<br>' + lang_vtype[1] + ': ' + lang_vtype[12] + '<br>' + lang_vtype[2] + ': ' + lang_vtype[15].replace("@","1~172800"));
								},
								enableKeyEvents: true,
								width: 120
							}
						]
					}
				]
			}
		]
	}
);

// 티어링 옵션 WINDOW
var MCV_volumeTieringOptionWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCV_volumeTieringOptionWindow',
		title: lang_mcv_volume[138],
		maximizable: false,
		autoHeight: true,
		width: 500,
		items: [MCV_volumeTieringOptionPanel],
		buttons:[
			{
				id: 'MCV_volumeTieringOptionOKBtn',
				text: lang_mcv_volume[137],
				width: 70,
				disabled: false,
				handler: function () {
					changeTieringOption();
				}
			}
		]
	}
);
*/

/*
 * 클러스터 볼륨 목록
 */
// 클러스터 볼륨 목록 그리드
var MCV_volumeGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumeGrid',
		store: MCV_volumeGridStore,
		multiSelect: false,
		title: lang_mcv_volume[0],
		height: 300,
		columnLines: true,
		cls: 'line-break',
		columns: [
			{
				flex: 1,
				text: lang_mcv_volume[241],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Pool_Name'
			},
			{
				flex: 1,
				text: lang_mcv_volume[24],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Volume_Name'
			},
			{
				flex: 3,
				text: lang_mcv_volume[71],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Node_List',
				renderer: function (value) {
					return value.sort();
				}
			},
			{
				flex: 1,
				text: lang_mcv_volume[17],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Oper_Stage',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					if (value == 'CREATE')
					{
						return lang_mcv_volume[207];
					}
					else if (value == 'CREATE_FAIL')
					{
						return lang_mcv_volume[208];
					}
					else if (value == 'DELETE')
					{
						return lang_mcv_volume[209];
					}
					else if (value == 'DELETE_FAIL')
					{
						return lang_mcv_volume[210];
					}
					else if (value == 'EXPAND' || value == 'EXTEND')
					{
						return lang_mcv_volume[211];
					}
					else if (value == 'EXPAND_FAIL' || value == 'EXTEND_FAIL')
					{
						return lang_mcv_volume[212];
					}
					else if (value == 'SNAPSHOT_CREATE')
					{
						return lang_mcv_volume[213];
					}
					else
					{
						return record.get('Status_Code');
					}
				}
			},
			{
				flex: 1,
				text: lang_mcv_volume[59],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Size'
			},
			{
				xtype: 'componentcolumn',
				flex: 1,
				text: lang_mcv_volume[72],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Volume_Used',
				renderer: function (v, m, r) {
					var rateValue = parseFloat(v);

					return {
						xtype: 'progressbar',
						cls: 'used-progress',
						value: (rateValue * 100).toFixed(0) / 100 / 100,
						text: ((rateValue * 100).toFixed(0) / 100).toFixed(2) + '%'
					}
				}
			},
			{
				flex: 1,
				text: lang_mcv_volume[9],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Provision',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					if (record.get('Pool_Type').toUpperCase() == 'EXTERNAL')
					{
						return lang_mcv_volume[251];
					}

					if (record.get('Provision') == 'thin')
					{
						return lang_mcv_volume[128];
					}
					else if (record.get('Provision') == 'thick')
					{
						return lang_mcv_volume[129];
					}
				}
			},
			{
				flex: 1,
				text: lang_mcv_volume[89],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Policy'
			},
			{
				flex: 1,
				text: lang_mcv_volume[11],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Replica_Count',
				renderer: function (value) {
					if (value == '1')
					{
						return 'N/A';
					}
					return value;
				},
			},
			{
				flex: 1,
				text: lang_mcv_volume[55],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Dist_Node_Count',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					if (record.get('Type') == "NetworkRAID")
					{
						return value + "&nbsp(d" + value + '+c' + record.get('Code_Count') + ")";
					}
					else
					{
						return value;
					}
				}
			},
			{
				text: lang_mcv_volume[189],
				menuDisabled: true,
				columns: [
					{
						dataIndex: 'Arbiter',
						xtype: 'actioncolumn',
						menuDisabled: true,
						width: 45,
						height: 0,
						style: { border: 0 },
						align: 'center',
						items: [
							{
								iconCls: 'b-icon-arbiter',
								handler: function (grid, rowIndex, colIndex) {
									// 선택된 볼륨 정보 전달
									var record = grid.getStore().getAt(rowIndex);

									// Arbiter is only available for 'Gluster' pool
									if (record.get('Pool_Type') != 'Gluster')
									{
										return false;
									}

									// 티어링을 사용 중인 볼륨은 아비터를 활성화할 수 없음
									if (record.get('Hot_Tier') == 'true')
									{
										return false;
									}

									// 볼륨명
									var Volume_Name = record.get('Volume_Name');

									var Pool_Type;

									MCV_volumeGridStore.each(
										function (record)
										{
											if (record.get('Volume_Name') == Volume_Name)
											{
												Pool_Type = record.get('Pool_Type');
												return false;
											}
										}
									);

									// 아비터 활성화
									Ext.MessageBox.confirm(
										lang_mcv_volume[0],
										lang_mcv_volume[224],
										function (btn, text) {
											if (btn != 'yes')
												return;

											Ext.MessageBox.wait(lang_mcv_volume[225], lang_mcv_volume[0]);

											Ext.Ajax.request({
												url: '/api/cluster/volume/arbiter/attach',
												timeout: 60000,
												jsonData: {
													argument: {
														Volume_Name: Volume_Name,
														Pool_Type: Pool_Type,
													}
												},
												callback: function (options, success, response) {
													// 데이터 전송 완료 후 wait 제거
													if (waitMsgBox)
													{
														waitMsgBox.hide();
														waitMsgBox = null;
													}

													var responseData = Ext.JSON.decode(response.responseText);

													// 예외 처리에 따른 동작
													if (!success || !responseData.success)
													{
														if (response.responseText == ''
																|| typeof(response.responseText) == 'undefined')
															response.responseText = '{}';

														if (typeof(responseData.msg) === 'undefined')
															responseData.msg = '';

														if (typeof(responseData.code) === 'undefined')
															responseData.code = '';

														var checkValue = '{'
															+ '"title": "' + lang_mcv_volume[0] + '", '
															+ '"content": "' + lang_mcv_volume[227] + '", '
															+ '"msg": "' + responseData.msg + '", '
															+ '"code": "' + responseData.code + '"'
														+ '}';

														return exceptionDataCheck(checkValue);
													}

													loadVolumeStore();
													MCV_volumeViewWindow.hide();
													Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[226]);
												}
											});
										}
									);
								},
								isDisabled: function (view, rowIndex, colIndex, item, record) {
									return record.get('Arbiter') !== 'false';
								},
								getClass: function (v, meta, record) {
									if (record.get('Policy') == 'Local')
									{
										return 'x-item-disabled disabled-click';
									}
									else if (record.get('Arbiter') == 'true')
									{
										meta.tdAttr = 'data-qtip="' + lang_mcv_volume[222] + '"';
										return 'x-action-col-icon x-action-col-0 b-icon-arbiter disabled-click';
									}
									else if (record.get('Hot_Tier') == "true" && record.get('Arbiter') == 'false')
									{
										meta.tdAttr = 'data-qtip="' + lang_mcv_volume[233] + '"';
										return 'x-action-col-icon x-action-col-0 b-icon-arbiter x-item-disabled disabled-click';
									}
									else if (record.get('Arbiter') == 'false')
									{
										meta.tdAttr = 'data-qtip="' + lang_mcv_volume[222] + '"';
										return 'x-action-col-icon x-action-col-0 b-icon-arbiter x-item-disabled';
									}
									// else if (record.get('Arbiter') == 'na')
									// {
									// 	meta.tdAttr = 'data-qtip="' + lang_mcv_volume[222] + '"';
									// 	return 'x-action-col-icon x-action-col-0 b-icon-arbiter x-item-disabled disabled-click';
									// }
									else
									{
										return 'x-item-disabled disabled-click';
									}
								}
							}
						]
					},
					{
						dataIndex: 'Chaining',
						xtype: 'actioncolumn',
						menuDisabled: true,
						width: 45,
						height: 0,
						style: { border: 0 },
						align: 'center',
						items: [
							{
								iconCls: 'b-icon-chain',
								getClass: function (v, meta, record) {
									if (record.get('Policy') == 'Distributed'
										&& record.get('Replica_Count') == 2)
									{
										meta.tdAttr = 'data-qtip="' + lang_mcv_volume[188] + '"';

										if (record.get('Chaining') == "optimal")
										{
											return 'x-action-col-icon x-action-col-0 b-icon-chain disabled-click';
										}
										else if (record.get('Chaining') == "partially")
										{
											return 'x-action-col-icon x-action-col-0 b-icon-chain_exclamation disabled-click';
										}
										else
										{
											return 'x-action-col-icon x-action-col-0 b-icon-chain x-item-disabled disabled-click';
										}
									}
									else
									{
										return 'x-action-col-icon x-action-col-0 x-item-disabled disabled-click';
									}
								}
							}
						]
					}
				]
			},
			{
				dataIndex: 'Pool_Type',
				hidden: true
			},
			{
				dataIndex: 'Pool_Name',
				hidden: true
			},
			{
				text: lang_mcv_volume[73],
				width: 140,
				autoSizeColumn: true,
				minWidth: 140,
				sortable: false,
				menuDisabled: true,
				dataIndex: 'Management',
				xtype: 'componentcolumn',
				renderer: function (value, metaData, record) {
					/* 동작 버튼 */
					// 볼륨 생성 수행 중: VIEW
					// 볼륨 생성 실패: VIEW, DELETE
					// 볼륨 삭제 수행 중: VIEW
					// 볼륨 삭제 실패: VIEW, DELETE
					// 볼륨 확장 (노드 추가, 볼륨 크기 변경) 수행 중: VIEW
					// 볼륨 확장 (노드 추가, 볼륨 크기 변경) 실패: VIEW, DELETE, EXPAND
					// 스냅샷 생성 중: VIEW, DELETE, EXPAND(비활성화), TIERING(비활성화), SNAPSHOT(비활성화)

					var scrollMenu = new Ext.menu.Menu();

					// 작업 수행 메세지
					var operStage = record.get('Oper_Stage');

					/** VIEW **/
					if (record.get('Pool_Type').toUpperCase() != 'EXTERNAL')
					{
						scrollMenu.add({
							text: lang_mcv_volume[74],
							handler: function () {
								var me = this;
								me.up('button').setText(lang_mcv_volume[74]);

								// VIEW 호출 :: 클러스터 볼륨 정보 호출
								MCV_volumePoolStore.load({
									callback: function(records, operation, success) {
										if (waitMsgBox)
										{
											waitMsgBox.hide();
											waitMsgBox = null;
										}

										if (!success)
										{
											var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

											if (typeof(jsonText) == 'undefined')
												jsonText = '{}';

											var checkValue = '{'
												+ '"title": "' + lang_mcv_volume[0] + '", '
												+ '"content": "' + lang_mcv_volume[126] + '", '
												+ '"response": ' + jsonText
												+ '}';

											return exceptionDataCheck(checkValue);
										}
										showVolumeInfo(record.get('Volume_Name'));
									}
								});

								Ext.defer(function () {
									me.up('button').setText(lang_mcv_volume[73]);
								}, 500);
							}
						});
					}

					/* EXPAND */
					if (operStage == 'SNAPSHOT_CREATE'
						&& record.get('Pool_Type').toUpperCase() != 'EXTERNAL')
					{
						scrollMenu.add({
							text: lang_mcv_volume[78],	//EXPAND
							disabled: true
						});
					}
					else if ((operStage == null
						|| operStage == 'EXPAND_FAIL' || operStage == 'EXTEND_FAIL')
						&& record.get('Pool_Type').toUpperCase() != 'EXTERNAL')
					{
						scrollMenu.add({
							text: lang_mcv_volume[78],
							handler: function () {
								var me = this;

								me.up('button').setText(lang_mcv_volume[78]);

								Ext.defer(function () {
									me.up('button').setText(lang_mcv_volume[73]);
								}, 500);

								// 클러스터 볼륨 확장 ajax 호출
								loadVolumeExpand({
									volume_name: record.get('Volume_Name'),
									pool_name: record.get('Pool_Name'),
									pool_type: record.get('Pool_Type'),
								});
							}
						});
					}

					/** Unmount **/
					if (record.get('Pool_Type').toUpperCase() == 'EXTERNAL')
					{
						scrollMenu.add({
							text: lang_mnv_volume[32],
							handler: function () {
								var me = this;
								me.up('button').setText(lang_mnv_volume[32]);

								Ext.defer(function () {
									me.up('button').setText(lang_mcv_volume[73]);
								}, 500);

								Ext.MessageBox.confirm(
									lang_mcv_volume[0],
									lang_mcv_volume[239],
									function (btn, text) {
										if (btn !== 'yes')
											return;

										// 클러스터 볼륨 삭제
										Ext.getCmp('MCV_volumeDeleteReason').setValue();
										Ext.getCmp('MCV_volumeDeletePassword').setValue();
										//Ext.getCmp('MCV_volumeDeleteTier').setValue();
										Ext.getCmp('MCV_volumeDeletePanel').getForm().reset();

										/*
										if (!(record.get('Hot_Tier') == 'true'
											&& operStage == null))
										{
											Ext.getCmp('MCV_volumeDeleteTier').setValue('none');
										}
										*/

										MCV_volumeDeleteWindow.show();
										Ext.getCmp('MCV_volumeDeleteName')
											.setText(record.get('Volume_Name'));
									}
								);
							}
						});
					}

					/** DELETE **/
					if ((operStage == null
							|| operStage == 'CREATE_FAIL' || operStage == 'DELETE_FAIL'
							|| operStage == 'EXPAND_FAIL' || operStage == 'EXTEND_FAIL')
						&& record.get('Pool_Type').toUpperCase() != 'EXTERNAL')
					{
						scrollMenu.add({
							text: lang_mcv_volume[75],
							handler: function () {
								var me = this;

								me.up('button').setText(lang_mcv_volume[75]);

								Ext.defer(function () {
									me.up('button').setText(lang_mcv_volume[73]);
								}, 500);

								// 클러스터 볼륨 삭제 ajax 호출
								Ext.MessageBox.confirm(
									lang_mcv_volume[0],
									lang_mcv_volume[76],
									function (btn, text) {
										if (btn !== 'yes')
											return;

										// 클러스터 볼륨 삭제
										Ext.getCmp('MCV_volumeDeleteReason').setValue();
										Ext.getCmp('MCV_volumeDeletePassword').setValue();
										//Ext.getCmp('MCV_volumeDeleteTier').setValue();
										Ext.getCmp('MCV_volumeDeletePanel').getForm().reset();

										/*
										if (!(record.get('Hot_Tier') == 'true' && operStage == null))
										{
											Ext.getCmp('MCV_volumeDeleteTier').setValue('none');
										}
										*/

										MCV_volumeDeleteWindow.show();
										Ext.getCmp('MCV_volumeDeleteName').setText(record.get('Volume_Name'));
									}
								);
							}
						});
					}
					else if (operStage == 'SNAPSHOT_CREATE'
							&& record.get('Pool_Type').toUpperCase() != 'EXTERNAL')
					{
						scrollMenu.add({
							text: lang_mcv_volume[75],
							disabled: true
						});
					}

					return {
						xtype: 'button',
						text: lang_mcv_volume[73],
						menu: scrollMenu
					};
				}
			}
		],
		tbar: [
			{
				text: lang_mcv_volume[86],
				id: 'MCV_volumeCreateBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					waitWindow(lang_mcv_volume[0], lang_mcv_volume[125]);

					loadVPoolStore(
						{
							callback: function () {
								// 클러스터 볼륨 생성 OPEN
								MCV_volumeCreateWindow.animateTarget = Ext.getCmp('MCV_volumeCreateBtn');
								MCV_volumeCreateWindow.show();
							}
						}
					);
				}
			}
		],
		listeners: {
			cellclick: function (gridView, htmlElement, columnIndex, record) {
				if (columnIndex == 14)
				{
					Ext.defer(function () {
						MCV_volumeGrid.getSelectionModel().deselectAll();
						MCV_volumeGrid.getSelectionModel().select(record, true);
					}, 100);
				}
			}
		},
		viewConfig: {
			stripeRows: false,
			getRowClass: function (record) {
				// 작업 수행 메세지
				var operStage = record.get('Oper_Stage');

				if (operStage == 'CREATE'
					|| operStage == 'DELETE'
					|| operStage == 'EXPAND'
					|| operStage == 'EXTEND'
					|| operStage == 'SNAPSHOT_CREATE')
				{
					// 작업이 진행 중일 때
					return 'warn-row';
				}
				else if (operStage == 'CREATE_FAIL'
					|| operStage == 'DELETE_FAIL'
					|| operStage == 'EXPAND_FAIL'
					|| operStage == 'EXTEND_FAIL')
				{
					// 작업이 실패일 때
					return 'err-row';
				}
			},
			loadMask: true
		}
	}
);

/*
 * Functions
 */
function loadVPoolStore(params)
{
	params = params || {};

	// 볼륨 풀 리스트 로드
	MCV_volumePoolStore.load({
		callback: function (records, operation, success) {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			// 예외 처리에 따른 동작
			if (!success)
			{
				var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mcv_volume[0] + '", '
					+ '"content": "' + lang_mcv_volume[126] + '", '
					+ '"response": ' + jsonText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 첫번째 페이지 로드
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep1');

			/** 클러스터 볼륨 생성시 초기 페이지 show/hide */
			Ext.getCmp('MCV_volumeCreateStep2TypePanel').hide();

			// 볼륨 타입 설명
			Ext.getCmp('MCV_volumeCreateStep2DescPanel').hide();

			// 전송 타입
			Ext.getCmp('MCV_volumeCreateSendType').hide();

			// 전송 타입 설명
			Ext.getCmp('MCV_volumeCreateStep3DescPanel').hide();

			// 마운트 대상
			Ext.getCmp('MCV_volumeCreateExtTarget').show();

			// 마운트 옵션
			Ext.getCmp('MCV_volumeCreateExtOpts').show();

			/** 버튼 컨트롤 */
			// 취소
			Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
			Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

			// 이전
			Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').hide();
			Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').disable();

			// 다음
			Ext.getCmp('MCV_volumeCreateWindowNextBtn').show();
			Ext.getCmp('MCV_volumeCreateWindowNextBtn').enable();

			// 확인
			Ext.getCmp('MCV_volumeCreateWindowOKBtn').hide();
			Ext.getCmp('MCV_volumeCreateWindowOKBtn').disable();

			// 닫기
			Ext.getCmp('MCV_volumeCreateWindowCloseBtn').hide();
			Ext.getCmp('MCV_volumeCreateWindowCloseBtn').disable();

			/** OPEN 시 초기화 - 입력 폼 초기화 */
			Ext.getCmp('MCV_volumeCreateStep3Panel').getForm().reset();
			Ext.getCmp('MCV_volumeCreateStep5Panel').getForm().reset();

			// 노드별 할당 용량
			Ext.getCmp('MCV_volumeCreateAssign').setValue('');

			// 노드별 할당 용량 단위
			Ext.getCmp('MCV_volumeCreateAssignType').setValue('GiB');

			// 볼륨명
			Ext.getCmp('MCV_volumeCreateName').setValue();

			// 전송 유형
			Ext.getCmp('MCV_volumeCreateSendType').setValue('tcp');

			MCV_volumePoolStore.clearFilter();

			// thin 볼륨 풀 목록 숨김
			MCV_volumePoolStore.filter(
				function (record) {
					return (record.get('Pool_Name').slice(0, 3) != 'tp_' );
				}
			);

			// 볼륨 타입 - 동적 할당: 비활성화
			Ext.getCmp('MCV_volumeCreateTypeThin').disable();
			
			// 최대 생성 가능한 볼륨 크기
			Ext.getCmp('MCV_volumeCreateAssignMax').show();
			Ext.getCmp('MCV_volumeCreateAssignMaxSize').setText('0.00 Byte');

			if ('callback' in params)
			{
				params.callback();
			}
		}
	});
}

function loadVolumeStore()
{
	// 클러스터 볼륨 목록 그리드 로드
	MCV_volumeGridStore.load();
};

function getArbiterSizeMB(max_size_mb)
{
	var arbiter_size_mb = 0;
	if (max_size_mb <= 1048576)
	{
		arbiter_size_mb = max_size_mb * 0.05;
	}
	else
	{
		arbiter_size_mb = 40960;
	}

	return arbiter_size_mb;
}

function convertMBToSize(size)
{
	var size_str;
	var size_type;

	if (size > 1024 * 1024 * 1024)
	{
		size_str = Math.round((size / 1024 / 1024 / 1024) * 100) / 100;
		size_type = 'PiB';
	}
	else if (size > 1024 * 1024)
	{
		size_str = Math.round((size / 1024 / 1024) * 100) / 100;
		size_type = 'TiB';
	}
	else if (size > 1024)
	{
		size_str = Math.round((size / 1024) * 100) / 100;
		size_type = 'GiB';
	}
	else
	{
		size_str = Math.round(size * 100) / 100;
		size_type = 'MiB';
	}

	return size_str.toFixed(2) + size_type;
}

function convertSizeToMB(size_str)
{
	var match = size_str.match(/^([\d\.]+)\s*([^\s]+)$/);
	var size  = match[1];
	var unit  = match[2];

	if (unit.match(/^(M|MiB)$/i))
	{
		size = size;
	}
	else if (unit.match(/^(G|GiB)$/i))
	{
		size = size * 1024;
	}
	else if (unit.match(/^(T|TiB)$/i))
	{
		size = size * 1024 * 1024;
	}
	else if (unit.match(/^(P|PiB)$/i))
	{
		size = size * 1024 * 1024 * 1024;
	}

	return size;
}

function getSelectedNodes(selection)
{
	var inclusion = new Array();
	var selected  = new Array();

	for (var i=0, len=selection.length; i<len; i++)
	{
		if (selection[i].get('inclusion') == "true")
		{
			inclusion.push(selection[i].get('Storage_IP'));
		}
		else
		{
			selected.push(selection[i].get('Storage_IP'));
		}
	}

	return {
		selected: selected,
		inclusion: inclusion
	};
}

function getVPool(name)
{
	var found = null;

	MCV_volumePoolStore.clearFilter();
	MCV_volumePoolStore.each(
		function (record, id)
		{
			if (record.get('Pool_Name') == name)
			{
				found = record;
				return false;
			}

			return true;
		}
	);

	return found;
}

function showVolumeInfo(vol_name)
{
	GMS.Ajax.request({
		url: '/api/cluster/volume/list',
		waitMsgBox: waitWindow(lang_mcv_volume[0], lang_mcv_volume[217]),
		jsonData: {
			argument: {
				Volume_Name: vol_name
			}
		},
		callback: function (options, success, response, decoded) {
			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
				return;

			var volumes = decoded.entity;
			var volume  = null;
			var vpool   = getVPool(volumes[0].Pool_Name);

			for (j=0; j<volumes.length; j++)
			{
				if (vol_name == volumes[j].Volume_Name)
				{
					volume = volumes[j];
					break;
				}
			}

			if (volume == null)
			{
				Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[255]);
				return;
			}

			// 볼륨명
			Ext.getCmp('MCV_volumeViewPool').setText(volume.Pool_Name);
			Ext.getCmp('MCV_volumeViewName').setText(volume.Volume_Name);

			// 작업 상태 메시지
			var operStage = volume.Oper_Stage;
			var status    = volume.Status_Code;

			if (operStage == 'CREATE')
			{
				status = lang_mcv_volume[207];
			}
			else if (operStage == 'CREATE_FAIL')
			{
				status = lang_mcv_volume[208];
			}
			else if (operStage == 'DELETE')
			{
				status = lang_mcv_volume[209];
			}
			else if (operStage == 'DELETE_FAIL')
			{
				status = lang_mcv_volume[210];
			}
			else if (operStage == 'EXPAND' || operStage == 'EXTEND')
			{
				status = lang_mcv_volume[211];
			}
			else if (operStage == 'EXPAND_FAIL' || operStage == 'EXTEND_FAIL')
			{
				status = lang_mcv_volume[212];
			}
			else if (operStage == 'SNAPSHOT_CREATE')
			{
				status = lang_mcv_volume[213];
			}

			// 상태
			Ext.getCmp('MCV_volumeViewStatus').setText(status);

			// 볼륨 크기
			Ext.getCmp('MCV_volumeViewSize').setText(volume.Size);

			// 프로비저닝
			if (volume.Provision == 'thin')
			{
				Ext.getCmp('MCV_volumeViewProvision').setText(lang_mcv_volume[128]);
			}
			else
			{
				Ext.getCmp('MCV_volumeViewProvision').setText(lang_mcv_volume[129]);
			}

			// 분산 정책
			Ext.getCmp('MCV_volumeViewPolicy').setText(volume.Policy);

			MCV_volumeViewNodeStore.loadRawData(vpool.get('Nodes'));

			if (vpool.get('Pool_Type') == 'Gluster')
			{
				if (Ext.getCmp('MCV_volumeViewTransport').up().isHidden())
				{
					Ext.getCmp('MCV_volumeViewTransport').up().show();
				}

				if (Ext.getCmp('MCV_volumeViewReplica').up().isHidden())
				{
					Ext.getCmp('MCV_volumeViewReplica').up().show();
				}

				if (Ext.getCmp('MCV_volumeViewDistributed').up().isHidden())
				{
					Ext.getCmp('MCV_volumeViewDistributed').up().show();
				}

				// 전송 유형
				Ext.getCmp('MCV_volumeViewTransport').setText(volume.Transport_Type);

				// 분산 노드수
				if (volume.Policy == "NetworkRAID")
				{
					// NetworkRAID 볼륨: 분산 노드 수 + 소거 코드 수
					Ext.getCmp('MCV_volumeViewDistributed').setText(volume.Dist_Node_Count);
					Ext.getCmp('MCV_volumeViewCodeCountPanel').show();
					Ext.getCmp('MCV_volumeViewCodeCount').setText(volume.Code_Count);
				}
				else
				{
					// Distributed, Shard 볼륨: 분산 노드 수
					Ext.getCmp('MCV_volumeViewDistributed').setText(volume.Dist_Node_Count);
					Ext.getCmp('MCV_volumeViewCodeCountPanel').hide();
				}

				if (volume.Policy == "Shard")
				{
					// 샤딩할 단위 블록 크기
					Ext.getCmp('MCV_volumeViewShardPanel').show();
					Ext.getCmp('MCV_volumeViewShard').setText(volume.Shard_Block_Size);
				}
				else
				{
					// 샤딩할 단위 블록 크기
					Ext.getCmp('MCV_volumeViewShardPanel').hide();
				}

				// 복제 수
				Ext.getCmp('MCV_volumeViewReplica').setText(volume.Replica_Count);

				if (volume.Status_Code == 'OK')
				{
					if (volume.Arbiter == 'true')
					{
						Ext.getCmp('MCV_volumeViewArbiterPanel').show();
						Ext.getCmp('MCV_volumeViewArbiterAvail').show();
						Ext.getCmp('MCV_volumeViewArbiterButton').hide();
					}
					else if (volume.Arbiter == 'false' && volume.Replica_Count == 2)
					{
						Ext.getCmp('MCV_volumeViewArbiterPanel').show();
						Ext.getCmp('MCV_volumeViewArbiterAvail').hide();
						Ext.getCmp('MCV_volumeViewArbiterButton').show();

						/*
						if (volume.Hot_Tier == 'true')
						{
							Ext.getCmp('MCV_volumeViewArbiterButton').setDisabled(true);
							Ext.defer(function () {
								Ext.QuickTips.register({
									target: 'MCV_volumeViewArbiterButton',
									text: lang_mcv_volume[233]
								});
							}, 100);
						}
						else
						{
							Ext.getCmp('MCV_volumeViewArbiterButton').setDisabled(false);
							Ext.defer(function () {
								Ext.QuickTips.unregister(
									Ext.getCmp('MCV_volumeViewArbiterButton'));
							}, 100);
						}
						*/
					}
					else
					{
						Ext.getCmp('MCV_volumeViewArbiterPanel').hide();
					}

					/*
					if (volume.Hot_Tier == 'true')
					{
						//Ext.getCmp('MCV_volumeViewTierPanel').show();
						//Ext.getCmp('MCV_volumeViewTierCreate').hide();
						Ext.getCmp('MCV_volumeViewTierInfo').show();
					}
					else if (volume.Hot_Tier == 'false')
					{
						//Ext.getCmp('MCV_volumeViewTierPanel').show();
						//Ext.getCmp('MCV_volumeViewTierCreate').show();
						Ext.getCmp('MCV_volumeViewTierInfo').hide();

						if (volume.Arbiter == 'true')
						{
							Ext.getCmp('MCV_volumeViewTierCreate').setDisabled(true);
							Ext.defer(function () {
								Ext.QuickTips.register({
									target: 'MCV_volumeViewTierCreate',
									text: lang_mcv_volume[232]
								});
							}, 100);
						}
						else if (volume.Policy == 'Shard')
						{
							Ext.getCmp('MCV_volumeViewTierCreate').setDisabled(true);

							Ext.defer(function () {
								Ext.QuickTips.register({
									target: 'MCV_volumeViewTierCreate',
									text: lang_mcv_volume[236]
								});
							}, 100);
						}
						else
						{
							Ext.getCmp('MCV_volumeViewTierCreate').setDisabled(false);
							Ext.defer(function () {
								Ext.QuickTips.unregister(
									Ext.getCmp('MCV_volumeViewTierCreate'));
							}, 100);
						}
					}
					else
					{
						Ext.getCmp('MCV_volumeViewTierPanel').hide();
					}
					*/
				}
			}
			else
			{
				//Ext.getCmp('MCV_volumeViewPolicy').up().hide();
				Ext.getCmp('MCV_volumeViewTransport').up().hide();
				Ext.getCmp('MCV_volumeViewReplica').up().hide();
				Ext.getCmp('MCV_volumeViewDistributed').up().hide();
				Ext.getCmp('MCV_volumeViewCodeCountPanel').hide();
				Ext.getCmp('MCV_volumeViewShardPanel').hide();
				Ext.getCmp('MCV_volumeViewArbiterPanel').hide();
				//Ext.getCmp('MCV_volumeViewTierPanel').hide();
			}

			MCV_volumeViewWindow.show();
		}
	});
};

// 최대 생성 가능한 볼륨 용량
function updateCreateMaxSize()
{
	// 선택한 노드(노드)
	var selected   = MCV_volumeCreateNodeGrid.getSelectionModel().getSelection();
	var each_sizes = [];

	// 선택한 노드 리스트의 최소 남은 용량
	var min_size = 0;

	Ext.getCmp('MCV_volumeCreateNodeTotal')
		.setText(lang_mcv_volume[237] + ': ' + selected.length);

	for (var i=0; i<selected.length; i++)
	{
		// 선택한 노드의 남은 볼륨 크기
		each_sizes.push(convertSizeToMB(selected[i].get('Free_Size')));
	}

	if (each_sizes.length)
	{
		min_size = each_sizes.reduce(
			function (previous, current) {
				return previous > current ? current:previous;
			}
		);
	}

	// 볼륨 생성 타입에 따른 볼륨 최대 용량 계산
	var pool_type   = Ext.getCmp('MCV_volumeCreatePoolGrid').getSelectionModel()   
		.getSelection()[0]
		.get('Pool_Type');

	var policy      = Ext.getCmp('MCV_volumeCreatePolicy').getValue();
	var code_count  = Ext.getCmp('MCV_volumeCreateCodeCount').getValue();
	var replica_num = Ext.getCmp('MCV_volumeCreateReplica').getValue();

	// 볼륨 최대 크기
	var max_size_mb;

	if (pool_type == 'Gluster')
	{
		if (policy == 'NetworkRAID')
		{
			max_size_mb = (selected.length - code_count) * min_size;
		}
		else if (policy == 'Distributed' )
		{
			max_size_mb = (selected.length * min_size) / replica_num;
			var arbiter_size_mb = 0;
			if (Ext.getCmp('MCV_volumeCreateArbiter').getValue() == true)
			{
				// 전체 가용량 기준 아비터 사이즈
				arbiter_size_mb = getArbiterSizeMB(max_size_mb);
				// 각 노드에 할당될 아비터 사이즈
				arbiter_size_mb = arbiter_size_mb * (selected.length / 2);
				var arbiter_size = max_size_mb > 0 ? convertMBToSize(arbiter_size_mb) : '0.00 Byte';
				Ext.getCmp('MCV_volumeCreateAssignArbiterSize').setText(arbiter_size);
			}
			max_size_mb = max_size_mb - arbiter_size_mb;
		}
		else if (policy == 'Shard')
		{
			max_size_mb = (selected.length * min_size) / replica_num;
		}
	}
	else
	{
		max_size_mb = selected.length * min_size;
	}

	// 볼륨 최대 크기 단위 변환
	var max_size = max_size_mb > 0 ? convertMBToSize(max_size_mb) : '0.00 Byte';

	Ext.getCmp('MCV_volumeCreateAssignMaxSize').setText(max_size);
};

function updatePoolGrid(record)
{
	var selected_count = MCV_volumeCreatePoolGrid.getSelectionModel().getCount();
	var pool_type      = record.get('Pool_Type').toUpperCase();

	if (selected_count != 1
		|| (pool_type != 'GLUSTER' && pool_type != 'LOCAL'))
	{
		// 볼륨 타입 - 고정, 동적
		Ext.getCmp('MCV_volumeCreateStep2TypePanel').hide();

		// 볼륨 타입 설명
		Ext.getCmp('MCV_volumeCreateStep2DescPanel').hide();

		// 전송 타입
		Ext.getCmp('MCV_volumeCreateSendType').hide();

		// 전송 타입 설명
		Ext.getCmp('MCV_volumeCreateStep3DescPanel').hide();

		// 마운트 대상
		Ext.getCmp('MCV_volumeCreateExtTarget').show();

		// 마운트 옵션
		Ext.getCmp('MCV_volumeCreateExtOpts').show();

		return;
	}

	// 볼륨 타입 - 고정, 동적
	Ext.getCmp('MCV_volumeCreateStep2TypePanel').show();
	
	// 볼륨 동적 할당
	var provision = record.get('Thin_Allocation');

	if (provision == null || provision == '')
	{
		provision = "0M";
	}

	var conv_prov_to_byte = convertSizeToMB(provision) * 1024 * 1024;

	if (conv_prov_to_byte > 0)
	{
		// 동적 할당: 활성화
		Ext.getCmp('MCV_volumeCreateTypeThin').enable();
		Ext.defer(function () {
			Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateTypeThin'));
		}, 100);
	}
	else
	{
		// 동적 할당: 비활성화
		var desc = lang_mcv_volume[173].replace('@', record.get('Pool_Name'));

		Ext.getCmp('MCV_volumeCreateTypeThin').disable();

		Ext.defer(function () {
			Ext.QuickTips.register({
				target: 'MCV_volumeCreateTypeThin',
				text: desc,
				width: 310,
				dismissDelay: 5000
			});
		}, 100);
	}

	// 볼륨 타입 설명
	Ext.getCmp('MCV_volumeCreateStep2DescPanel').show();

	// 전송 타입
	Ext.getCmp('MCV_volumeCreateSendType').show();

	// 전송 타입 설명
	Ext.getCmp('MCV_volumeCreateStep3DescPanel').show();

	// 마운트 대상
	Ext.getCmp('MCV_volumeCreateExtTarget').hide();

	// 마운트 옵션
	Ext.getCmp('MCV_volumeCreateExtOpts').hide();

	// 볼륨 타입 - 동적, 고정
	Ext.getCmp('MCV_volumeCreateTypeThick').setValue(true);

	// 선택한 노드 개수
	Ext.getCmp('MCV_volumeCreateNodeTotal').setText(lang_mcv_volume[237] + ': 0');

	// 볼륨 유형
	Ext.getCmp('MCV_volumeCreatePolicy').setValue('Distributed');

	// code 노드 수
	Ext.getCmp('MCV_volumeCreateCodeCount').setValue('');

	// 복제 수
	Ext.getCmp('MCV_volumeCreateReplica').setValue(2);

	// 샤딩할 단위 블록 크기
	Ext.getCmp('MCV_volumeCreateShardBlockSize').hide();

	// 노드 목록
	var selected = MCV_volumeCreatePoolGrid.getSelectionModel().getSelection()[0].get('Nodes');

	if (selected.length == 2)
	{
		// 체인 모드
		Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
		Ext.getCmp('MCV_volumeCreateChaining').setDisabled(false);

		// 체인 모드 비활성화 설명 제거
		Ext.defer(function () {
			Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateChaining'));
		}, 100);

		// 아비터
		Ext.getCmp('MCV_volumeCreateArbiter').setValue(true);
		Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);

		// 아비터 비활성화 설명 제거
		Ext.defer(function () {
			Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateArbiter'));
		}, 100);
	}
	else
	{
		// 체인 모드 X
		Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
		Ext.getCmp('MCV_volumeCreateChaining').setDisabled(true);

		// 체인 모드 비활성화 설명
		Ext.defer(function () {
			Ext.QuickTips.register({
				target: 'MCV_volumeCreateChaining',
				text: lang_mcv_volume[228]
			}) ;
		}, 100);

		// 아비터
		Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);
		Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);

		// 아비터 비활성화 설명
		Ext.defer(function () {
			Ext.QuickTips.register({
				target: 'MCV_volumeCreateArbiter',
				text: lang_mcv_volume[228]
			}) ;
		}, 100);
	}

	// 최대 생성 가능한 볼륨 크기
	Ext.getCmp('MCV_volumeCreateAssignMax').show();
	Ext.getCmp('MCV_volumeCreateAssignMaxSize').setText('0.00 Byte');
}

/** 클러스터 생성 버튼 컨트롤 **/
function updateCreateWindow()
{
	// 버튼 컨트롤 - 취소
	Ext.getCmp('MCV_volumeCreateWindowCancelBtn').hide();
	Ext.getCmp('MCV_volumeCreateWindowCancelBtn').disable();

	// 버튼 컨트롤 - 이전
	Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').hide();
	Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').disable();

	// 버튼 컨트롤 - 다음
	Ext.getCmp('MCV_volumeCreateWindowNextBtn').hide();
	Ext.getCmp('MCV_volumeCreateWindowNextBtn').disable();

	// 버튼 컨트롤 - 확인
	Ext.getCmp('MCV_volumeCreateWindowOKBtn').hide();
	Ext.getCmp('MCV_volumeCreateWindowOKBtn').disable();

	// 버튼 컨트롤 - 닫기
	Ext.getCmp('MCV_volumeCreateWindowCloseBtn').hide();
	Ext.getCmp('MCV_volumeCreateWindowCloseBtn').disable();

	var active_win = MCV_volumeCreateWindow.layout.getActiveItem().id;
	var volume_pools = MCV_volumeCreatePoolGrid.getSelectionModel().getSelection();

	if (active_win == 'MCV_volumeCreateStep1')
	{
		// 버튼 컨트롤 - 취소
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

		// 버튼 컨트롤 - 다음
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').enable();
	}
	else if (active_win == 'MCV_volumeCreateStep2')
	{
		// 버튼 컨트롤 - 취소
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

		// 버튼 컨트롤 - 이전
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').enable();

		// 버튼 컨트롤 - 다음
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').enable();
	}
	else if (active_win == 'MCV_volumeCreateStep3')
	{
		// 볼륨풀 선택 확인
		if (volume_pools.length < 1)
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep2');
			updateCreateWindow();
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[256]);
			return false;
		}

		var pool_type = volume_pools[0].get('Pool_Type');

		if (pool_type.toUpperCase() == 'LOCAL')
		{
			Ext.getCmp('MCV_volumeCreateSendType').hide();
			Ext.getCmp('MCV_volumeCreateStep3DescPanel').hide();
		}

		// 버튼 컨트롤 - 취소
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

		// 버튼 컨트롤 - 이전
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').enable();

		// 버튼 컨트롤 - 다음
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').enable();
	}
	else if (active_win == 'MCV_volumeCreateStep4')
	{
		// 볼륨 풀이 EXTERNAL일 경우
		var pool_type = volume_pools[0].get('Pool_Type');

		if (pool_type.toUpperCase() == 'EXTERNAL')
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep6');
			updateCreateWindow();
			return false;
		}

		// 볼륨명 체크
		if (!Ext.getCmp('MCV_volumeCreateName').isValid())
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep3');
			updateCreateWindow();
			return false;
		}

		var vol_name = Ext.getCmp('MCV_volumeCreateName').getValue();

		/*
		 * 볼륨명 사용 불가: volume, snapshot
		 */
		if (vol_name == 'volume')
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep3');
			updateCreateWindow();
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[185]);
			return false;
		}

		if (vol_name == 'snapshot')
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep3');
			updateCreateWindow();
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[186]);
			return false;
		}

		// 볼륨명 중복 체크
		var duplicated = false;

		MCV_volumeGrid.store.each(
			function (record) {
				if (record.get('Volume_Name') == vol_name)
				{
					duplicated = true;
					return false;
				}
			}
		);

		if (duplicated)
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep3');
			updateCreateWindow();

			Ext.MessageBox.alert(
				lang_mcv_volume[0],
				lang_mcv_volume[127].replace('@', vol_name));

			return false;
		}

		// 프로비저닝별 정책 검사
		var pool_nodes = volume_pools[0].get('Nodes');

		var thick_prov = Ext.getCmp('MCV_volumeCreateTypeThick').getValue();
		var thin_prov  = Ext.getCmp('MCV_volumeCreateTypeThin').getValue();

		if (thick_prov)
		{
			// thick 볼륨 풀 선택
			MCV_volumeCreateNodeGridStore.loadRawData(pool_nodes);

			// 체인 모드 체크박스
			if (pool_nodes.length >= 3)
			{
				// 체인 모드
				Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
				Ext.getCmp('MCV_volumeCreateChaining').setDisabled(false);

				// 체인 모드 비활성화 설명 제거
				Ext.defer(function () {
					Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateChaining'));
				}, 100);

				// 아비터
				Ext.getCmp('MCV_volumeCreateArbiter').setValue(true);
				Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);

				// 아비터 비활성화 설명 제거
				Ext.defer(function () {
					Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateArbiter'));
				}, 100);
			}
			else
			{
				// 체인 모드 X
				Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
				Ext.getCmp('MCV_volumeCreateChaining').setDisabled(true);

				// 체인 모드 비활성화 설명
				Ext.defer(function () {
					Ext.QuickTips.register({
						target: 'MCV_volumeCreateChaining',
						text: lang_mcv_volume[228]
					});
				}, 100);

				// 아비터
				Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);
				Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);

				// 아비터 비활성화 설명
				Ext.defer(function () {
					Ext.QuickTips.register({
						target: 'MCV_volumeCreateArbiter',
						text: lang_mcv_volume[228]
					});
				}, 100);
			}

			// 생성 가능한 볼륨 크기
			Ext.getCmp('MCV_volumeCreateAssignMax').show();
			Ext.getCmp('MCV_volumeCreateAssignMaxSize').setText('0.00 Byte');
		}
		else if (thin_prov)
		{
			// select thin-pool nodes
			var thin_nodes = [];

			for (var i=0; i<pool_nodes.length; i++)
			{
				var pv_length = pool_nodes[i].PVs.length;
				
				for (var j=0; j<pv_length; j++)
				{
					if (pool_nodes[i].PVs[j].In_Use == 1)
					{
						thin_nodes.push(pool_nodes[i]);
						break;
					}
				}
			}

			pool_nodes = thin_nodes;

			// thin 볼륨 풀 로드
			MCV_volumeCreateNodeGridStore.loadRawData(pool_nodes);

			// 체인 모드 체크박스
			if (pool_nodes.length >= 3)
			{
				// 체인 모드
				Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
				Ext.getCmp('MCV_volumeCreateChaining').setDisabled(false);

				// 체인 모드 비활성화 설명 제거
				Ext.defer(function () {
					Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateChaining'));
				}, 100);

				// 아비터
				Ext.getCmp('MCV_volumeCreateArbiter').setValue(true);
				Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(false);

				// 아비터 비활성화 설명 제거
				Ext.defer(function () {
					Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeCreateArbiter'));
				}, 100);
			}
			else
			{
				// 체인 모드 X
				Ext.getCmp('MCV_volumeCreateChaining').setValue(false);
				Ext.getCmp('MCV_volumeCreateChaining').setDisabled(true);

				// 체인 모드 비활성화 설명
				Ext.defer(function () {
					Ext.QuickTips.register({
						target: 'MCV_volumeCreateChaining',
						text: lang_mcv_volume[228]
					});
				}, 100);

				// 아비터
				Ext.getCmp('MCV_volumeCreateArbiter').setDisabled(true);
				Ext.getCmp('MCV_volumeCreateArbiter').setValue(false);

				// 아비터 비활성화 설명
				Ext.defer(function () {
					Ext.QuickTips.register({
						target: 'MCV_volumeCreateArbiter',
						text: lang_mcv_volume[228]
					});
				}, 100);
			}

			// 생성 가능한 볼륨 크기
			Ext.getCmp('MCV_volumeCreateAssignMaxSize').setText('0.00 Byte');
			Ext.getCmp('MCV_volumeCreateAssignMax').hide();
		}

		// 정책
		var policy = Ext.getCmp('MCV_volumeCreatePolicy').getValue();

		// 복제수
		var replica_num = Ext.getCmp('MCV_volumeCreateReplica').getValue();

		// 코드수
		var code_count = Ext.getCmp('MCV_volumeCreateCodeCount').getValue();

		if (policy == 'NetworkRAID')
		{
			Ext.getCmp('MCV_volumeCreateNodeGrid').setTitle(
				lang_mcv_volume[15]
				+ ' ('
				+ lang_mcv_volume[42].replace('@', (code_count * 2) + 1)
				+ ')'
			);
		}
		else if (policy == 'Distributed')
		{
			if (Ext.getCmp('MCV_volumeCreateChaining').getValue() == true)
			{
				Ext.getCmp('MCV_volumeCreateNodeGrid').setTitle(
					lang_mcv_volume[15] + ' (' + lang_mcv_volume[39] + ')'
				);
			}
			else
			{
				if (replica_num == 1)
				{
					Ext.getCmp('MCV_volumeCreateNodeGrid').setTitle(
						lang_mcv_volume[15] + ' (' + lang_mcv_volume[38] + ')'
					);
				}
				else
				{
					Ext.getCmp('MCV_volumeCreateNodeGrid').setTitle(
						lang_mcv_volume[15] + ' (' + lang_mcv_volume[41 + replica_num] + ')'
					);
				}
			}
		}
		else if (policy == 'Shard')
		{
			if (replica_num == 1)
			{
				Ext.getCmp('MCV_volumeCreateNodeGrid').setTitle(
					lang_mcv_volume[15] + ' (' + lang_mcv_volume[46] + ')'
				);
			}
			else if (replica_num >= 2)
			{
				Ext.getCmp('MCV_volumeCreateNodeGrid').setTitle(
					lang_mcv_volume[15]
					+ ' ('
					+ lang_mcv_volume[47]
						.replace('@', (replica_num * 2))
						.replace('*', replica_num)
					+ ')'
				);
			}
		}

		if (pool_type.toUpperCase() == 'LOCAL')
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
			updateCreateWindow();
			return false;
		}

		// 버튼 컨트롤 - 취소
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

		// 버튼 컨트롤 - 이전
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').enable();

		// 버튼 컨트롤 - 다음
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').enable();
	}
	else if (active_win == 'MCV_volumeCreateStep5')
	{
		if (Ext.getCmp('MCV_volumeCreateArbiter').getValue() == true
			&& Ext.getCmp('MCV_volumeCreatePolicy').getValue() == 'Distributed')
		{
			Ext.getCmp('MCV_volumeCreateAssignArbiterSize').setText('0.00 Byte');
			Ext.getCmp('MCV_volumeCreateAssignArbiter').show();
			Ext.getCmp('MCV_volumeCreateAssignArbiter').setDisabled(false);
		}
		else
		{
			Ext.getCmp('MCV_volumeCreateAssignArbiter').hide();
			Ext.getCmp('MCV_volumeCreateAssignArbiter').setDisabled(true);
		}

		var pool_type = volume_pools[0].get('Pool_Type');

		if (pool_type.toUpperCase() == 'GLUSTER')
		{
			var policy = Ext.getCmp('MCV_volumeCreatePolicy').getValue();

			// code 노드 수
			if (policy == 'NetworkRAID'
				&& !Ext.getCmp('MCV_volumeCreateCodeCount').isValid())
			{
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep4');
				updateCreateWindow();
				return false;
			}
		}
		else if (pool_type.toUpperCase() == 'EXTERNAL')
		{
			MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep6');
			updateCreateWindow();
			return false;
		}

		// 버튼 컨트롤 - 취소
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

		// 버튼 컨트롤 - 이전
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').enable();

		// 버튼 컨트롤 - 다음
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowNextBtn').enable();
	}
	else if (active_win == 'MCV_volumeCreateStep6')
	{
		// 볼륨 타입
		Ext.getCmp('MCV_volumeCreateStep2TypePanel').show();

		// 전송 유형
		Ext.getCmp('MCV_volumeCreateStep6SendTypePanel').show();

		// 분산 정책
		Ext.getCmp('MCV_volumeCreateStep6PolicyPanel').show();

		// 복제 수
		Ext.getCmp('MCV_volumeCreateStep6DuplicatePanel').show();

		// 체인 모드
		Ext.getCmp('MCV_volumeCreateChainLabel').show();

		// 아비터
		Ext.getCmp('MCV_volumeCreateArbiterLabel').show();

		// 샤드 크기
		Ext.getCmp('MCV_volumeCreateShardBlockSizeLabel').show();

		// 노드 목록
		Ext.getCmp('MCV_volumeCreateNodePanel').show();

		// 볼륨 크기
		Ext.getCmp('MCV_volumeCreateSizePanel').show();

		var pool_type = volume_pools[0].get('Pool_Type');

		if (!pool_type.toUpperCase().match(/^(EXTERNAL|LOCAL)$/))
		{
			var nodes = MCV_volumeCreateNodeGrid.getSelectionModel().getSelection();

			if (nodes.length <= 0)
			{
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
				updateCreateWindow();

				Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[8]);

				return false;
			}

			// 복제 수
			var replica_num = Ext.getCmp('MCV_volumeCreateReplica').getValue();

			// 코드 수
			var code_count = Ext.getCmp('MCV_volumeCreateCodeCount').getValue();

			var policy = Ext.getCmp('MCV_volumeCreatePolicy').getValue();

			if (policy == 'NetworkRAID')
			{
				if (nodes.length < (code_count * 2) + 1)
				{
					MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
					updateCreateWindow();

					Ext.MessageBox.alert(
						lang_mcv_volume[0],
						lang_mcv_volume[42].replace('@', (code_count * 2) + 1));

					return false;
				}
			}
			else if (policy == 'Distributed')
			{
				if (Ext.getCmp('MCV_volumeCreateChaining').getValue() == true)
				{
					if (nodes.length < 3)
					{
						MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
						updateCreateWindow();
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[39]);
						return false;
					}
				}
				else
				{
					if (replica_num == 1 && nodes.length < 1)
					{
						MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
						updateCreateWindow();

						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[38]);

						return false;
					}
					else if (nodes.length % replica_num != 0)
					{
						MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
						updateCreateWindow();

						Ext.MessageBox.alert(
							lang_mcv_volume[0],
							lang_mcv_volume[41 + replica_num]);

						return false;
					}
				}
			}
			else if (policy == 'Shard')
			{
				if (replica_num == 1 && nodes.length < 2)
				{
					MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
					updateCreateWindow();
					Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[46]);
					return false;
				}
				else if (replica_num >= 2)
				{
					if (nodes.length % replica_num != 0
						|| nodes.length < replica_num * 2)
					{
						MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
						updateCreateWindow();

						Ext.MessageBox.alert(
							lang_mcv_volume[0],
							lang_mcv_volume[47]
								.replace('@', (replica_num * 2))
								.replace('*', replica_num));

						return false;
					}
				}
			}

			// 노드별 용량, 노드 목록 체크 확인
			if (!Ext.getCmp('MCV_volumeCreateAssign').isValid())
			{
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
				updateCreateWindow();
				return false;
			}

			// 최대 생성 가능 용량 확인
			var max_vol_size = convertSizeToMB(
				document.getElementById('MCV_volumeCreateAssignMaxSize').innerHTML
			);

			// 입력한 용량 확인
			var vol_size
				= convertSizeToMB(
					Ext.getCmp('MCV_volumeCreateAssign').getValue()
					+ ' '
					+ Ext.getCmp('MCV_volumeCreateAssignType').getValue());

			// 볼륨 타입이 고정 할당일 때
			if (Ext.getCmp('MCV_volumeCreateTypeThin').getValue() != true)
			{
				if (vol_size > max_vol_size)
				{
					MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
					updateCreateWindow();
					Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[50]);
					return false;
				}
			}

			var thin_prov = Ext.getCmp('MCV_volumeCreateTypeThin').getValue();

			Ext.getCmp('MCV_volumeCreateTypeCheck')
				.update(lang_mcv_volume[thin_prov ? 128 : 129]);

			var transport = Ext.getCmp('MCV_volumeCreateSendType').getValue();

			Ext.getCmp('MCV_volumeCreateSendTypeCheck').update(transport);

			var policy = Ext.getCmp('MCV_volumeCreatePolicy').getValue();

			Ext.getCmp('MCV_volumeCreatePolicyCheck').update(policy);

			if (policy == 'NetworkRAID')
			{
				Ext.getCmp('MCV_volumeCreateReplicaLabel').update(lang_mcv_volume[10] + ': ');
				Ext.getCmp('MCV_volumeCreateReplicaCheck')
					.update(Ext.getCmp('MCV_volumeCreateCodeCount').getValue());
				Ext.getCmp('MCV_volumeCreateChainLabel').hide();
				Ext.getCmp('MCV_volumeCreateArbiterLabel').hide();
				Ext.getCmp('MCV_volumeCreateShardBlockSizeLabel').hide();
			}
			else if (policy == 'Distributed')
			{
				Ext.getCmp('MCV_volumeCreateChainLabel').show();
				Ext.getCmp('MCV_volumeCreateArbiterLabel').show();
				Ext.getCmp('MCV_volumeCreateShardBlockSizeLabel').hide();

				var chain   = Ext.getCmp('MCV_volumeCreateChaining').getValue();
				var arbiter = Ext.getCmp('MCV_volumeCreateArbiter').getValue();

				// 복제 수
				Ext.getCmp('MCV_volumeCreateReplicaLabel')
					.update(lang_mcv_volume[11] + ': ');

				Ext.getCmp('MCV_volumeCreateReplicaCheck')
					.update(Ext.getCmp('MCV_volumeCreateReplica').getValue());

				// 체인 모드
				Ext.getCmp('MCV_volumeCreateChainCheck')
					.update(lang_mcv_volume[chain ? 97 : 103]);

				// 아비터
				Ext.getCmp('MCV_volumeCreateArbiterCheck')
					.update(lang_mcv_volume[arbiter ? 97 : 103]);
			}
			else
			{
				Ext.getCmp('MCV_volumeCreateReplicaLabel').update(lang_mcv_volume[11] + ': ');
				Ext.getCmp('MCV_volumeCreateReplicaCheck')
					.update(Ext.getCmp('MCV_volumeCreateReplica').getValue());
				Ext.getCmp('MCV_volumeCreateChainLabel').hide();
				Ext.getCmp('MCV_volumeCreateArbiterLabel').hide();
				Ext.getCmp('MCV_volumeCreateShardBlockSizeLabel').show();
				Ext.getCmp('MCV_volumeCreateShardBlockSizeCheck')
					.update(Ext.getCmp('MCV_volumeCreateShardBlockSize').getValue());
			}

			var nodes     = MCV_volumeCreateNodeGrid.getSelectionModel().getSelection();
			var hostnames = nodes.map( function (v) { return v.get('Hostname'); });

			Ext.getCmp('MCV_volumeCreateNodeCheck').update(hostnames);
			Ext.getCmp('MCV_volumeCreateSizeCheck').update(
				Ext.getCmp('MCV_volumeCreateAssign').getValue()
				+ Ext.getCmp('MCV_volumeCreateAssignType').getValue()
			);

			// 마운트 대상
			Ext.getCmp('MCV_volumeCreateTargetPanel').hide();

			// 마운트 옵션
			Ext.getCmp('MCV_volumeCreateTargetOptPanel').hide();
		}
		else if (pool_type.toUpperCase().match(/^(LOCAL)$/))
		{
			// 볼륨 명 중복 체크
			var duplicated = false;

			MCV_volumeGrid.store.each(
				function (record) {
					if (record.get('Volume_Name')
						== Ext.getCmp('MCV_volumeCreateName').getValue())
					{
						duplicated = true;
						return false;
					}
				}
			);

			if (duplicated)
			{
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep3');
				updateCreateWindow();

				Ext.MessageBox.alert(
					lang_mcv_volume[0],
					lang_mcv_volume[127].replace('@', Ext.getCmp('MCV_volumeCreateName').getValue())
				);

				return false;
			}
		
			// Node selection confirmation
			var volume_nodes = MCV_volumeCreateNodeGrid.getSelectionModel().getSelection();

			if (volume_nodes.length < 1)
			{	
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
				updateCreateWindow();
				Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[8]);
				return false;
			}

			// 노드별 용량, 노드 목록 체크 확인
			if (!Ext.getCmp('MCV_volumeCreateAssign').isValid())
			{
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
				updateCreateWindow();
				return false;
			}

			// 최대 생성 가능 용량 확인
			var max_vol_size = convertSizeToMB(
				document.getElementById('MCV_volumeCreateAssignMaxSize').innerHTML
			);

			// 입력한 용량 확인
			var vol_size
				= convertSizeToMB(
					Ext.getCmp('MCV_volumeCreateAssign').getValue()
					+ ' '
					+ Ext.getCmp('MCV_volumeCreateAssignType').getValue());

			// 볼륨 타입이 고정 할당일 때
			if (Ext.getCmp('MCV_volumeCreateTypeThin').getValue() != true)
			{
				if (vol_size > max_vol_size)
				{
					MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep5');
					updateCreateWindow();
					Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[50]);
					return false;
				}
			}

			// 입력 내용 확인 스탭을 위한
			var nodes     = MCV_volumeCreateNodeGrid.getSelectionModel().getSelection();
			var hostnames = nodes.map( function (v) { return v.get('Hostname'); });

			Ext.getCmp('MCV_volumeCreateNodeCheck').update(hostnames);
			Ext.getCmp('MCV_volumeCreateSizeCheck').update(
				Ext.getCmp('MCV_volumeCreateAssign').getValue()
				+ Ext.getCmp('MCV_volumeCreateAssignType').getValue()
			);

			// 볼륨 타입
			Ext.getCmp('MCV_volumeCreateStep2TypePanel').hide();

			// 전송 유형
			Ext.getCmp('MCV_volumeCreateStep6SendTypePanel').hide();

			// 분산 정책
			Ext.getCmp('MCV_volumeCreateStep6PolicyPanel').hide();

			// 복제 수
			Ext.getCmp('MCV_volumeCreateStep6DuplicatePanel').hide();

			// 체인 모드
			Ext.getCmp('MCV_volumeCreateChainLabel').hide();

			// 아비터
			Ext.getCmp('MCV_volumeCreateArbiterLabel').hide();

			// 샤드 크기
			Ext.getCmp('MCV_volumeCreateShardBlockSizeLabel').hide();

			// 노드 목록
			//Ext.getCmp('MCV_volumeCreateNodePanel').hide();

			// 볼륨 크기
			//Ext.getCmp('MCV_volumeCreateSizePanel').hide();

			// 마운트 대상
			Ext.getCmp('MCV_volumeCreateTargetPanel').hide();

			// 마운트 옵션
			Ext.getCmp('MCV_volumeCreateTargetOptPanel').hide();
		}
		else
		{
			// 볼륨 명 중복 체크
			var duplicated = false;

			MCV_volumeGrid.store.each(
				function (record) {
					if (record.get('Volume_Name')
						== Ext.getCmp('MCV_volumeCreateName').getValue())
					{
						duplicated = true;
						return false;
					}
				}
			);

			if (duplicated)
			{
				MCV_volumeCreateWindow.layout.setActiveItem('MCV_volumeCreateStep3');
				updateCreateWindow();

				Ext.MessageBox.alert(
					lang_mcv_volume[0],
					lang_mcv_volume[127].replace('@', Ext.getCmp('MCV_volumeCreateName').getValue())
				);

				return false;
			}

			// 마운트 대상
			var mnt_target = Ext.getCmp('MCV_volumeCreateExtTarget').getValue();

			Ext.getCmp('MCV_volumeCreateTargetPanel').show();
			Ext.getCmp('MCV_volumeCreateTargetCheck').update(mnt_target);

			// 마운트 옵션
			var mnt_opts = Ext.getCmp('MCV_volumeCreateExtOpts').getValue();

			Ext.getCmp('MCV_volumeCreateTargetOptPanel').show();
			Ext.getCmp('MCV_volumeCreateTargetOptCheck').update(mnt_opts);
			
			// 볼륨 타입
			Ext.getCmp('MCV_volumeCreateStep2TypePanel').hide();

			// 전송 유형
			Ext.getCmp('MCV_volumeCreateStep6SendTypePanel').hide();

			// 분산 정책
			Ext.getCmp('MCV_volumeCreateStep6PolicyPanel').hide();

			// 복제 수
			Ext.getCmp('MCV_volumeCreateStep6DuplicatePanel').hide();

			// 체인 모드
			Ext.getCmp('MCV_volumeCreateChainLabel').hide();

			// 아비터
			Ext.getCmp('MCV_volumeCreateArbiterLabel').hide();

			// 샤드 크기
			Ext.getCmp('MCV_volumeCreateShardBlockSizeLabel').hide();

			// 노드 목록
			Ext.getCmp('MCV_volumeCreateNodePanel').hide();

			// 볼륨 크기
			Ext.getCmp('MCV_volumeCreateSizePanel').hide();

			if (pool_type.toUpperCase() == 'LOCAL')
			{
				// 마운트 대상
				Ext.getCmp('MCV_volumeCreateTargetPanel').hide();

				// 마운트 옵션
				Ext.getCmp('MCV_volumeCreateTargetOptPanel').hide();
			}
		}

		// 볼륨 풀 명
		var pool_name = volume_pools[0].get('Pool_Name');

		Ext.getCmp('MCV_volumeCreatePoolCheck').update(pool_name);

		// 볼륨명 출력
		var volume_name = Ext.getCmp('MCV_volumeCreateName').getValue();

		Ext.getCmp('MCV_volumeCreateNameCheck').update(volume_name);

		// 버튼 컨트롤 - 취소
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowCancelBtn').enable();

		// 버튼 컨트롤 - 이전
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowPreviousBtn').enable();

		// 버튼 컨트롤 - 확인
		Ext.getCmp('MCV_volumeCreateWindowOKBtn').show();
		Ext.getCmp('MCV_volumeCreateWindowOKBtn').enable();
	}

	return;
};

// 클러스터 볼륨 확장 시 생성될 볼륨 크기 계산
function updateExpandMaxSize()
{
	var selection = MCV_volumeExpandNodeGrid.getSelectionModel().getSelection();

	// 선택한 노드 개수
	Ext.getCmp('MCV_volumeExpandNodeTotal').setText(
		lang_mcv_volume[237] + ': ' + selection.length
	);

	var selected_nodes = [];

	for (var i=0, len=selection.length; i<len; i++)
	{
		if (selection[i].get('inclusion') == "true")
		{
			selected_nodes.push(selection[i].get('Hostname'));
		}
	}

	// 선택된 노드 개수
	var selectNodeCount = MCV_volumeExpandNodeGrid.getSelectionModel().getCount();

	// 복제수
	var volumeReplica = Ext.getElementById('MCV_volumeExpandReplica').innerHTML;

	// 분산 노드수
	var volumeDistributed = Ext.getElementById('MCV_volumeExpandDistributed').innerHTML;

	// 코드수
	var volumeCodeCount = Ext.getElementById('MCV_volumeExpandCodeCount').innerHTML;
	var result = selection.length / selected_nodes.length;

	// 확장될 볼륨 크기
	var volumeExpandSize = document.getElementById('MCV_volumeExpandSize').innerHTML;
	    volumeExpandSize = convertSizeToMB(volumeExpandSize);

	var expandSizeValue = convertMBToSize(parseFloat(volumeExpandSize * result));

	// 확장할 노드를 선택하지 않았을 경우
	if (selected_nodes.length == selection.length)
	{
		Ext.getCmp('MCV_volumeExpandAssignSize').setText(lang_mcv_volume[56]);
		return;
	}

	var policy = Ext.getElementById('MCV_volumeExpandPolicy').innerHTML;

	if (policy == 'NetworkRAID')
	{
		// NetworkRAID 볼륨: (분산 노드수 + 코드 노드수)의 배수
		if (selectNodeCount % (parseInt(volumeDistributed) + parseInt(volumeCodeCount)) != 0)
		{
			Ext.getCmp('MCV_volumeExpandAssignSize').setText(
				lang_mcv_volume[57].replace(
					'@',
					(parseInt(volumeDistributed) + parseInt(volumeCodeCount)))
			);
		}
		else
		{
			Ext.getCmp('MCV_volumeExpandAssignSize').setText(expandSizeValue);
		}
	}
	else if (policy == 'Distributed')
	{
		// Distributed 볼륨: 복제수의 배수
		if (selectNodeCount % volumeReplica != 0)
		{
			Ext.getCmp('MCV_volumeExpandAssignSize').setText(
				lang_mcv_volume[57].replace('@', volumeReplica)
			);
		}
		else
		{
			Ext.getCmp('MCV_volumeExpandAssignSize').setText(expandSizeValue);
		}
	}
	else if (policy == 'Shard')
	{
		// Shard 볼륨: (복제수 X 분산 노드수)의 배수
		if (selectNodeCount % (volumeReplica * volumeDistributed) != 0)
		{
			Ext.getCmp('MCV_volumeExpandAssignSize').setText(
				lang_mcv_volume[57].replace('@', (volumeReplica * volumeDistributed))
			);
		}
		else
		{
			Ext.getCmp('MCV_volumeExpandAssignSize').setText(expandSizeValue);
		}
	}
};

// 최대 생성 가능한 볼륨 용량
function updateExpandMaxAssignSize()
{
	// 선택한 노드
	var nodes = MCV_volumeExpandNodeStore.data.items;
	var each_sizes = [];
	var is_zero = 1;

	// 선택한 노드 리스트의 최소 남은 용량
	for (var i=0, len=nodes.length; i<len; i++)
	{
		// 선택한 노드의 남은 볼륨 크기
		var free_size = nodes[i].get('Free_Size_Bytes');

		if (0 < free_size)
		{
			is_zero = 0;
		}

		// 선택한 노드의 브릭 크기
		var brick_size = 0;

		// 볼륨이 체인 모드일 경우
		if (nodes[i].get('Brick_Size_Bytes').toString().indexOf(', ') != -1)
		{
			nodes[i].get('Brick_Size_Bytes').split(', ').map(
				function (value)
				{
					brick_size += value;
				}
			);
		}
		else
		{
			brick_size = nodes[i].get('Brick_Size_Bytes');
		}

		each_sizes.push(parseInt(free_size) + parseInt(brick_size));
	}

	var min_size = 0;

	if (is_zero == 0)
	{
		min_size = each_sizes.reduce(
				function (previous, current) {
					return previous > current ? current : previous;
				},
		);
	}

	// 볼륨 생성 타입에 따른 볼륨 최대 용량 계산
	// - 코드 수
	// - 볼륨 최대 용량
	var policy      = document.getElementById('MCV_volumeExpandPolicy').innerHTML;
	var replica_num = parseInt(document.getElementById('MCV_volumeExpandReplica').innerHTML);
	var code_count  = parseInt(document.getElementById('MCV_volumeExpandCodeCount').innerHTML);

	var max_size_bytes;

	if (policy == 'NetworkRAID')
	{
		max_size_bytes = (nodes.length - code_count) * min_size;
	}
	else if (policy == 'Distributed' || policy == 'Shard')
	{
		max_size_bytes = (nodes.length * min_size) / replica_num;
	}

	Ext.getCmp('MCV_volumeExpandAssignMaxSizeBytes').setText(max_size_bytes);

	var max_size = max_size_bytes > 0
		? convertMBToSize(Math.floor((max_size_bytes / 1024 / 1024)))
		: '0.00 Byte';

	Ext.getCmp('MCV_volumeExpandAssignMaxSize').setText(max_size);
};

function loadVolumeExpand(params)
{
	params = params || {};

	// 볼륨 확장 Form 초기화
	Ext.getCmp('MCV_volumeExpandPanel').getForm().reset();

	// 볼륨 확장 유무 확인
	var wait = Ext.MessageBox.wait(lang_mcv_volume[205], lang_mcv_volume[0]);

	GMS.Ajax.request({
		url: '/api/cluster/volume/expand',
		timeout: 60000,
		method: 'POST',
		jsonData: {
			argument: {
				Pool_Name: params.pool_name,
				Pool_Type: params.pool_type,
				Volume_Name: params.volume_name,
				Dry: 'true',
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				if (wait)
				{
					wait.hide();
					wait = null;
				}

				return options.promise.reject();
			}

			if (decoded.entity[0].is_possible !== 'true')
			{
				Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[80]);
				return options.promise.reject();
			}

			return options.promise.resolve();
		}
	})
	.success(function () {
		GMS.Ajax.request({
			url: '/api/cluster/volume/pool/list',
			jsonData: {
				argument: {
					Pool_Type: params.pool_type,
					Pool_Name: params.pool_name,
				}
			},
			callback: function (options, success, response, decoded) {
				if (!success || !decoded.success)
				{
					if (wait)
					{
						wait.hide();
						wait = null;
					}

					return options.promise.reject();
				}

				options.promise.resolve(decoded);
			}
		})
		.success(function (response) {
			var pool = response.entity[0];

			GMS.Ajax.request({
				url: '/api/cluster/volume/list',
				jsonData: {
					argument: {
						Volume_Name: params.volume_name,
						Pool_Name: params.pool_name,
						Pool_Type: params.pool_type,
					}
				},
				callback: function (options, success, response, decoded) {
					if (!success || !decoded.success)
					{
						if (wait)
						{
							wait.hide();
							wait = null;
						}

						return options.promise.reject();
					}

					var volumes = decoded.entity;
					var volume  = null;

					for (j=0; j<volumes.length; j++)
					{
						if (params.volume_name == volumes[j].Volume_Name)
						{
							volume = volumes[j];
							break;
						}
					}

					if (volume == null)
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[255]);
						return;
					}

					var vol_nodes = volume.Nodes.map(function (v) { return v.Mgmt_Hostname; });

					for (var i=0; i<pool.Nodes.length; i++)
					{
						var pool_node = pool.Nodes[i];

						if (vol_nodes.includes(pool_node.Hostname))
						{
							pool_node.inclusion  = 'true';
							pool_node.expandable = 'true';
							continue;
						}

						pool_node.inclusion = 'false';

						for (var j=0; j<volume.Nodes.length; j++)
						{
							//if (volume.Nodes[j].Mgmt_Hostname != pool_node.Hostname)
							//	continue;

							if (pool_node.Free_Size_Bytes >= volume.Size_Bytes)
							{
								pool_node.expandable = 'true';
							}
							else
							{
								pool_node.expandable = 'false';
							}

							break;
						}
					}

					// 볼륨명
					Ext.getCmp('MCV_volumeExpandName').setText(volume.Volume_Name);

					// 작업 상태 메시지
					var status;

					if (volume.Oper_Stage == 'EXPAND_FAIL')
					{
						status = lang_mcv_volume[214];
					}
					else if (volume.Oper_Stage == 'EXTEND_FAIL')
					{
						status = lang_mcv_volume[215];
					}
					else
					{
						status = volume.Status_Code;
					}

					// 상태
					Ext.getCmp('MCV_volumeExpandStatus').setText(status);

					// 볼륨 유형
					Ext.getCmp('MCV_volumeExpandPolicy').setText(volume.Policy);

					// 분산 노드수
					if (volume.Type == 'NetworkRAID')
					{
						//NetworkRAID 볼륨: 분산 노드 수 + 코드 수
						Ext.getCmp('MCV_volumeExpandDistributed')
							.setText(
								volume.Dist_Node_Count
								+ "&nbsp(d"
								+ volume.Dist_Node_Count
								+ "+c"
								+ volume.Code_Count
								+ ")");
					}
					else
					{
						// Distributed 볼륨: 분산 노드 수
						Ext.getCmp('MCV_volumeExpandDistributed').setText(volume.Dist_Node_Count);
					}

					// 체인 모드
					Ext.getCmp('MCV_volumeExpandChaining').setText(volume.Chaining);

					// 아비터
					Ext.getCmp('MCV_volumeExpandArbiter').setText(volume.Arbiter);

					if (volume.Type == 'Shard')
					{
						// 샤딩할 단위 블록 크기
						Ext.getCmp('MCV_volumeExpandShardBlockSizePanel').show();
						Ext.getCmp('MCV_volumeExpandShardBlockSize').setText(volume.Shard_Block_Size);
					}
					else
					{
						// 샤딩할 단위 블록 크기
						Ext.getCmp('MCV_volumeExpandShardBlockSizePanel').hide();
					}

					// NetworkRAID 노드 수
					Ext.getCmp('MCV_volumeExpandDisperseCount').setText(volume.Disperse_Count);

					// 복제 수
					Ext.getCmp('MCV_volumeExpandReplica').setText(volume.Replica_Count);

					// 볼륨 크기
					Ext.getCmp('MCV_volumeExpandSize').setText(volume.Size + 'iB');

					// 코드 노드수
					Ext.getCmp('MCV_volumeExpandCodeCount').setText(volume.Code_Count);

					// 볼륨 유형
					if (volume.Provision == 'thin')
					{
						Ext.getCmp('MCV_volumeExpandType').setText(lang_mcv_volume[128]);
						Ext.getCmp('MCV_volumeExpandAssignMax').hide();
					}
					else
					{
						Ext.getCmp('MCV_volumeExpandType').setText(lang_mcv_volume[129]);
						Ext.getCmp('MCV_volumeExpandAssignMax').show();
						Ext.getCmp('MCV_volumeExpandAssignMaxSizeBytes').hide();
					}

					// 노드 목록
					MCV_volumeExpandNodeStore.loadRawData(pool.Nodes);

					options.promise.resolve({ pool: pool, volume: volume });
				},
			})
			.success(function (response) {
				var pool   = response.pool;
				var volume = response.volume;

				if (params.pool_type.toUpperCase() == 'LOCAL')
				{
					wait.hide();

					Ext.getCmp('MCV_volumeExpandNodeGrid').hide();
					Ext.getCmp('MCV_volumeExpandNodeAdd').setDisabled(true);

					// 노드 추가 비활성화 설명
					Ext.defer(function () {
						Ext.QuickTips.register({
							target: 'MCV_volumeExpandNodeAdd',
							text: lang_mcv_volume[257],
							width: 380
						});
					}, 100);

					// 최대 생성 가능한 볼륨 용량
					var max_size = '0';

					if (0 < pool.Pool_Free_Size_Bytes)
					{
						max_size = pool.Pool_Free_Size_Bytes + volume.Size_Bytes;

						Ext.getCmp('MCV_volumeExpandAssignMaxSizeBytes').setText(max_size);

						max_size = max_size > 0 ? convertMBToSize(max_size / (1024 * 1024)) : '0.00 Byte';
					}

					Ext.getCmp('MCV_volumeExpandAssignMaxSize').setText(max_size);

					MCV_volumeExpandWindow.show();
				}
				else
				{
					// 노드 목록 필터 제거
					MCV_volumeExpandNodeStore.clearFilter();

					// 볼륨 확장 시 선택된 노드 리스트만 출력
					MCV_volumeExpandNodeStore.filter(
						function (record) {
							return record.get('inclusion') == 'true';
						}
					);

					GMS.Ajax.request({
						url: '/api/cluster/volume/brick/list',
						jsonData: {
							argument: {
								Pool_Type: params.pool_type,
								Pool_Name: params.pool_name,
								Volume_Name: params.volume_name,
							}
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
							{
								if (wait)
								{
									wait.hide();
									wait = null;
								}

								return options.promise.reject();
							}

							// 브릭 리스트
							var bricks      = decoded.entity;
							var brick_sizes = [];

							// 관리 네트워크 장치 체크
							for (var i=0; i<bricks.length; i++)
							{
								if (bricks[i].Brick_Type != 'cold_tier')
									continue;

								MCV_volumeExpandNodeGrid.store.each(
									function (record) {
										if (record.get('Hostname') != bricks[i].Hostname)
											return;

										if (record.get('Brick_Size') == '')
										{
											record.set('Brick_Size', bricks[i].Capacity);
											record.set('Brick_Size_Bytes', bricks[i].Capacity_bytes);
										}
										else
										{
											record.set('Brick_Size', record.get('Brick_Size') + ', ' + bricks[i].Capacity);
											record.set('Brick_Size_Bytes', record.get('Brick_Size_Bytes') + ', ' + bricks[i].Capacity_bytes);
										}

										return false;
									}
								);

								brick_sizes.push(bricks[i].Capacity);
							}

							if (wait)
							{
								wait.hide();
								wait = null;
							}

							Ext.getCmp('MCV_volumeExpandNodeGrid').show();
							MCV_volumeExpandWindow.show();

							// 노드 추가 활성화
							Ext.getCmp('MCV_volumeExpandNodeAdd').setDisabled(false);

							// 볼륨 크기 변경 활성화
							Ext.getCmp('MCV_volumeExpandSizeChange').setDisabled(false);
							Ext.getCmp('MCV_volumeExpandSizeChange').setValue(true);

							// 체크박스 숨김
							MCV_volumeExpandNodeGrid.headerCt.items.getAt(0).hide();

							// 확장 후 볼륨 크기
							Ext.getCmp('MCV_volumeExtendSize').setDisabled(false);
							Ext.getCmp('MCV_volumeExtendSizeUnit').setDisabled(false);

							// 상태 label color
							Ext.getCmp('MCV_volumeExpandStatus').getEl().setStyle('color', 'black');

							// 확장 버튼: 볼륨 확장
							Ext.getCmp('MCV_volumeExpandBtn').setText(lang_mcv_volume[61]);

							// 노드 추가 실패
							if (volume.Oper_Stage == 'EXPAND_FAIL')
							{
								// 확장 타입: 노드 추가
								Ext.getCmp('MCV_volumeExpandNodeAdd').setValue(true);

								// 볼륨 크기 변경 비활성화
								Ext.getCmp('MCV_volumeExpandSizeChange').setDisabled(true);
								Ext.getCmp('MCV_volumeExpandAssignSize').setText(Ext.getCmp('MCV_volumeExpandSize').text);

								// 상태 label color
								Ext.getCmp('MCV_volumeExpandStatus').getEl().setStyle('color', 'red');

								// 확장 버튼: 재확장
								Ext.getCmp('MCV_volumeExpandBtn').setText(lang_mcv_volume[216]);

								MCV_volumeExpandNodeStore.clearFilter();

								// 볼륨 확장 시 선택된 노드 리스트
								MCV_volumeExpandNodeStore.filter(function (record) {
									return record.get('inclusion') == 'true';
								});
							}
							// 볼륨 크기 변경 실패
							else if (volume.Oper_Stage == 'EXTEND_FAIL')
							{
								// 확장 후 볼륨 크기
								var size_text = Ext.getCmp('MCV_volumeExpandSize').text;

								var unit = size_text.substring(size_text.length-1);
								var size = size_text.substring(0, size_text.length-1);

								Ext.getCmp('MCV_volumeExtendSize').setValue(size);
								Ext.getCmp('MCV_volumeExtendSize').setDisabled(true);

								Ext.getCmp('MCV_volumeExtendSizeUnit').select(unit);
								Ext.getCmp('MCV_volumeExtendSizeUnit').setDisabled(true);

								// 노드 추가 비활성화
								Ext.getCmp('MCV_volumeExpandNodeAdd').setDisabled(true);

								// 상태 label color
								Ext.getCmp('MCV_volumeExpandStatus').getEl().setStyle('color', 'red');

								// 확장 버튼: 재확장
								Ext.getCmp('MCV_volumeExpandBtn').setText(lang_mcv_volume[216]);
							}

							// 체인 볼륨일 경우
							if (volume.Chaining == 'optimal' || volume.Chaining == 'partially')
							{
								// 노드 추가 비활성화
								Ext.getCmp('MCV_volumeExpandNodeAdd').setDisabled(true);

								// 노드 추가 비활성화 설명
								Ext.defer(function () {
									Ext.QuickTips.register({
										target: 'MCV_volumeExpandNodeAdd',
										text: lang_mcv_volume[199]
									});
								}, 100);
							}
							else if (brick_sizes.length > 1)
							{
								for (var i=0; i<brick_sizes.length-1; i++)
								{
									// 노드별 브릭 크기가 다를 경우
									if (brick_sizes[i] === brick_sizes[i+1])
										continue;

									// 노드 추가 비활성화
									Ext.getCmp('MCV_volumeExpandNodeAdd').setDisabled(true);

									// 노드 추가 비활성화 설명
									Ext.defer(function () {
										Ext.QuickTips.register({
											target: 'MCV_volumeExpandNodeAdd',
											text: lang_mcv_volume[195],
											width: 380
										});
									}, 100);
								}
							}
							else
							{
								// 노드 추가 비활성화 설명 제거
								Ext.defer(function () {
									Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeExpandNodeAdd'));
								}, 100);
							}

							// 최대 생성 가능한 볼륨 용량
							updateExpandMaxAssignSize();
						},
					});
				}
			});
		});
	});
};

function extendVolume()
{
	if (!Ext.getCmp('MCV_volumeExtendSize').isValid())
	{
		return false;
	}

	// 현재 볼륨 크기
	var curr_size = convertSizeToMB(document.getElementById('MCV_volumeExpandSize').innerHTML);

	// 확장 후 볼륨 크기
	var extend_unit = Ext.getCmp('MCV_volumeExtendSizeUnit').getValue();
	var extend_size = Ext.getCmp('MCV_volumeExtendSize').getValue() + extend_unit;
		extend_size = convertSizeToMB(extend_size);

	// 현재 볼륨 크기와 확장 후 볼륨 크기 비교
	if (curr_size > extend_size)
	{
		Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[202]);
		return false;
	}

	var percent = null;
	var expand_type = document.getElementById('MCV_volumeExpandType').innerHTML;

	extend_size = convertMBToSize(extend_size);

	// 볼륨 타입이 고정 할당일 경우
	if (expand_type == lang_mcv_volume[129])
	{
		// 확장 가능한 볼륨 크기
		var max_size = convertSizeToMB(document.getElementById('MCV_volumeExpandAssignMaxSize').innerHTML);

		extend_size = convertSizeToMB(extend_size);

		// 확장 가능한 볼륨 크기와 확장 후 볼륨 크기 비교
		if (max_size < extend_size)
		{
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[197]);
			return false;
		}

		percent = Math.floor(extend_size / max_size * 100);

		extend_size = convertMBToSize(extend_size);

		if (percent == 100)
		{
			percent = percent + '%VG';
			extend_size = document.getElementById('MCV_volumeExpandAssignMaxSizeBytes').innerHTML + 'B';
		}
		else
		{
			percent = null;
		}
	}


	Ext.MessageBox.confirm(
		lang_mcv_volume[0],
		lang_mcv_volume[180],
		function (btn, text) {
			if (btn != 'yes')
				return;

			var volume = MCV_volumeGrid.getSelectionModel().getSelection()[0];

			requestVolumeExtend({
				pool_type: volume.get('Pool_Type'),
				pool_name: volume.get('Pool_Name'),
				volume_name: volume.get('Volume_Name'),
				extend_size: extend_size,
				extend_percent: percent,
			});
		}
	);
}

function expandVolume()
{
	// 선택된 그리드의 전송값 추출
	var selection = MCV_volumeExpandNodeGrid.getSelectionModel().getSelection();
	var nodes     = getSelectedNodes(selection);

	// 복제 수
	var replica_count = Ext.getElementById('MCV_volumeExpandReplica').innerHTML;

	// NetworkRAID 노드 수
	var disperse_count = Ext.getElementById('MCV_volumeExpandDisperseCount').innerHTML;

	// Distributed 분산 노드 수
	var dist_count = Ext.getElementById('MCV_volumeExpandDistributed').innerHTML;

	// 상태
	var status = Ext.getElementById('MCV_volumeExpandStatus').innerHTML;

	// 확장할 노드를 선택하지 않았을 경우
	if (nodes.inclusion.length == selection.length
		&& status !== lang_mcv_volume[214])
	{
		Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[56]);
		return false;
	}

	var policy = Ext.getElementById('MCV_volumeExpandPolicy').innerHTML;

	// NetworkRAID 볼륨: NetworkRAID 노드 수의 배수
	if (policy == 'NetworkRAID'
		&& selection.length % parseInt(disperse_count))
	{
		Ext.MessageBox.alert(
			lang_mcv_volume[0],
			lang_mcv_volume[57].replace('@', parseInt(disperse_count)));

		return false;
	}
	// Distributed 볼륨: 복제 수의 배수
	else if (policy == 'Distributed'
		&& selection.length % parseInt(replica_count))
	{
		Ext.MessageBox.alert(
			lang_mcv_volume[0],
			lang_mcv_volume[57].replace('@', parseInt(replica_count)));

		return false;
	}
	// Shard 볼륨: 복제 수의 배수
	else if (policy == 'Shard'
		&& selection.length % (parseInt(dist_count) * parseInt(replica_count)))
	{
		Ext.MessageBox.alert(
			lang_mcv_volume[0],
			lang_mcv_volume[57].replace('@', (parseInt(dist_count) * parseInt(replica_count))));

		return false;
	}

	Ext.MessageBox.confirm(
		lang_mcv_volume[0],
		lang_mcv_volume[180],
		function (btn, text) {
			if (btn != 'yes')
				return;

			var selected = MCV_volumeGrid.getSelectionModel().getSelection()[0];

			requestVolumeExpand({
				pool_type: selected.get('Pool_Type'),
				volume_name: selected.get('Volume_Name'),
				nodes: nodes.selected,
			});
		}
	);
}

function requestVolumeExtend(params)
{
	params = params || {};

	var wait = Ext.MessageBox.wait(lang_mcv_volume[62], lang_mcv_volume[0]);

	GMS.Ajax.request({
		url: '/api/cluster/volume/extend',
		method: 'POST',
		jsonData: {
			argument: {
				Pool_Type: params.pool_type,
				Pool_Name: params.pool_name,
				Volume_Name: params.volume_name,
				Extend_Size: params.extend_size,
				Extend_Percent: params.extend_percent,
				Dry: 'true',
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				if (wait)
				{
					wait.hide();
					wait = null;
				}

				options.promise.reject();
				return;
			}

			if (decoded.entity[0].is_possible != 'true')
			{
				Ext.MessageBox.alert(lang_mcv_volume[0], decoded.entity[0].msg);
				options.promise.reject();
				return;
			}

			options.promise.resolve();
		}
	})
	.success(function (response) {
		GMS.Ajax.request({
			url: '/api/cluster/volume/extend',
			method: 'POST',
			jsonData: {
				argument: {
					Pool_Type: params.pool_type,
					Pool_Name: params.pool_name,
					Volume_Name: params.volume_name,
					Extend_Size: params.extend_size,
					Extend_Percent: params.extend_percent,
				}
			},
			callback: function (options, success, response, decoded) {
				if (!success || !decoded.success)
					return;

				MCV_volumeExpandWindow.hide();

				Ext.MessageBox.alert(
					lang_mcv_volume[0],
					decoded.success ? lang_mcv_volume[63] : decoded.msg
				);
			}
		});
	});
}

function requestVolumeExpand(params)
{
	params = params || {};

	Ext.MessageBox.wait(lang_mcv_volume[62], lang_mcv_volume[0]);

	GMS.Ajax.request({
		url: '/api/cluster/volume/expand',
		timeout: 120000,
		method: 'POST',
		jsonData: {
			argument: {
				Pool_Type: params.pool_type,
				Pool_Name: params.pool_name,
				Volume_Name: params.volume_name,
				Node_List: params.nodes,
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			MCV_volumeExpandWindow.hide();

			Ext.MessageBox.alert(
				lang_mcv_volume[0],
				decoded.success ? lang_mcv_volume[63] : decoded.msg
			);
		}
	});
}

// 볼륨 삭제 버튼
function requestVolumeDelete(vol_name)
{
	Ext.MessageBox.wait(lang_mcv_volume[252], lang_mcv_volume[0]);

	// 볼륨 삭제 유무 확인
	GMS.Ajax.request({
		url: '/api/cluster/volume/delete',
		timeout: 120000,
		jsonData: {
			argument: {
				Dry: 'true',
				Pool_Name: MCV_volumeGrid.getSelectionModel().getSelection()[0].get('Pool_Name'),
				Pool_Type: MCV_volumeGrid.getSelectionModel().getSelection()[0].get('Pool_Type'),
				Volume_Name: vol_name,
			}
		},
		callback: function (options, success, response, decoded) {
			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
				return;

			if (decoded.entity[0].is_possible != 'true')
			{
				Ext.MessageBox.alert(
					lang_mcv_volume[0],
					lang_mcv_volume[77]
					+ '<!-- <br> -->: '
					+ decoded.entity[0].msg);

				return;
			}

			Ext.MessageBox.wait(lang_mcv_volume[67], lang_mcv_volume[0]);

			GMS.Ajax.request({
				url: '/api/cluster/volume/delete',
				timeout: 120000,
				jsonData: {
					argument: {
						Pool_Name: MCV_volumeGrid.getSelectionModel().getSelection()[0].get('Pool_Name'),
						Pool_Type: MCV_volumeGrid.getSelectionModel().getSelection()[0].get('Pool_Type'),
						Volume_Name: document.getElementById('MCV_volumeDeleteName').innerHTML,
						Reason: Ext.getCmp('MCV_volumeDeleteReason').getValue(),
						Password: Ext.getCmp('MCV_volumeDeletePassword').getValue()
					}
				},
				callback: function (options, success, response, decoded) {
					if (!success || !decoded.success)
						return;

					MCV_volumeDeleteWindow.hide();
					loadVolumeStore();
					Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[68]);
				},
			});
		}
	});
}

/*
function createVolumeTiering()
{
	// 티어링 크기
	if (!Ext.getCmp('MCV_volumeTieringCreateTieringSize').isValid())
	{
		return false;
	}

	// 복제 수
	var replica_num = Ext.getCmp('MCV_volumeTieringCreateReplicaCount').getValue();

	// 선택한 노드 리스트
	var selectNode = MCV_volumeTieringCreateNodeGrid.getSelectionModel().getSelection();

	if (selectNode.length <= 0)
	{
		Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[8]);
		return false;
	}
	if (replica_num == 1)
	{
		if (selectNode.length < 1)
		{
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[38]);
			return false;
		}
	}
	else if (replica_num == 2)
	{
		var rest = selectNode.length % 2;

		if (rest != 0)
		{
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[43]);
			return false;
		}
	}
	else if (replica_num == 3)
	{
		var rest = selectNode.length % 3;

		if (rest != 0)
		{
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[44]);
			return false;
		}
	}
	else if (replica_num == 4)
	{
		var rest = selectNode.length % 4;

		if (rest != 0)
		{
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[45]);
			return false;
		}
	}

	// 입력한 용량 확인(크기)
	var inputTierSize = Ext.getCmp('MCV_volumeTieringCreateTieringSize').getValue();

	// 입력한 용량 확인(단위)
	var inputTierSizeUnit = Ext.getCmp('MCV_volumeTieringCreateTieringSizeUnit').getValue();

	var inputTierSizeMb = convertSizeToMB(inputTierSize + ' ' + inputTierSizeUnit);

	if (Ext.getCmp('MCV_volumeTieringCreateType').getValue() == 'thick')
	{
		// 최대 생성 가능한 티어링 크기 확인
		var maxTierSizeObj = document.getElementById('MCV_volumeTieringCreateTieringSizeMaxSize').innerHTML;

		// 최대 생성 가능 볼륨타입
		var maxTierSizeUnit = trim(maxTierSizeObj.substring(maxTierSizeObj.length-3));

		// 최대 생성 가능 볼륨크기
		var maxTierSize   = trim(maxTierSizeObj.substring(0, maxTierSizeObj.length-3));
		var maxTierSizeMb = convertSizeToMB(maxTierSize);

		if (inputTierSizeMb > maxTierSizeMb)
		{
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[170]);
			return false;
		}
	}

	// 선택된 그리드의 전송값 추출
	var node_list = [];

	for (var i=0, len=selectNode.length; i<len; i++)
	{
		node_list.push(selectNode[i].get('Hostname'));
	}

	Ext.MessageBox.confirm(
		lang_mcv_volume[0],
		lang_mcv_volume[177],
		function (btn, text) {
			if (btn != 'yes')
				return;

			waitWindow(lang_mcv_volume[0], lang_mcv_volume[145]);

			Ext.Ajax.request({
				url: '/api/cluster/volume/tier/attach',
				method: 'POST',
				jsonData: {
					argument: {
						Pool_Type: MCV_volumeGrid.getSelectionModel().getSelection()[0].get('Pool_Type'),
						Volume_Name: document.getElementById('MCV_volumeTieringCreateName').innerHTML,
						Pool_Name: Ext.getCmp('MCV_volumeTieringCreatePoolName').getValue(),
						TieringSize: Ext.getCmp('MCV_volumeTieringCreateTieringSize').getValue(),
						TieringSizeUnit: Ext.getCmp('MCV_volumeTieringCreateTieringSizeUnit').getValue(),
						Replica_Count: Ext.getCmp('MCV_volumeTieringCreateReplicaCount').getValue(),
						Node_List: node_list
					}
				},
				callback: function (options, success, response) {
					// 데이터 전송 완료 후 wait 제거
					if (waitMsgBox)
					{
						waitMsgBox.hide();
						waitMsgBox = null;
					}

					var responseData = Ext.decode(response.responseText);

					if (!success || !responseData.success)
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], responseData.msg);
						return;
					}

					// 볼륨 정보 창
					if (Ext.getCmp('MCV_volumeViewWindow').hidden)
					{
						loadVolumeStore();
						MCV_volumeTieringCreateWindow.hide();
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[146]);
						return;
					}

					loadVolumeStore();

					Ext.getCmp('MCV_volumeViewTierCreate').hide();
					Ext.getCmp('MCV_volumeViewTierInfo').show();
					Ext.getCmp('MCV_volumeViewArbiterButton').setDisabled(true);
					Ext.defer(function () {
						Ext.QuickTips.register({
							target: 'MCV_volumeViewArbiterButton',
							text: lang_mcv_volume[233]
						});
					}, 100);

					MCV_volumeTieringCreateWindow.hide();

					Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[146]);
				},
			});
		}
	);
}

// 티어링 생성/관리 팝업 버튼
function showTieringWindow(vol_name, status, volumeType)
{
	waitWindow(lang_mcv_volume[0], lang_mcv_volume[169]);

	// 볼륨 풀 리스트 로드
	MCV_volumeTieringCreatePoolListStore.load({
		callback: function (record, operation, success) {
			// 예외 처리에 따른 동작
			if (success !== true)
			{
				var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mcv_volume[0] + '",'
					+ '"content": "' + lang_mcv_volume[126] + '",'
					+ '"response": ' + jsonText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// OPEN시 초기화
			Ext.getCmp('MCV_volumeTieringCreatePanel').getForm().reset();

			MCV_volumeTieringCreatePoolListStore.clearFilter();

			// 사용 용도가 티어링인 볼륨 풀 명 콤보박스
			MCV_volumeTieringCreatePoolListStore.filter(function (record) {
				var Pool_Purpose = record.get('Pool_Purpose');
				var Pool_Type  = record.get('Pool_Type');
				return (Pool_Purpose == 'for_tiering' && Pool_Type == volumeType);
			});

			// 티어링 생성
			if (status == 'Create')
			{
				// 데이터 전송 완료 후 wait 제거
				if (waitMsgBox)
				{
					waitMsgBox.hide();
					waitMsgBox = null;
				}

				var poolNameObj = Ext.getCmp('MCV_volumeTieringCreatePoolName');

				if (poolNameObj.getStore().data.length == 0)
				{
					if (volumeType == 'thick')
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[133]);
						return false;
					}
					else
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[176]);
						return false;
					}
				}

				// 볼륨 풀 명
				poolNameObj.select(poolNameObj.getStore().getAt(0).get(poolNameObj.valueField));

				// 생성 버튼
				Ext.getCmp('MCV_volumeTieringCreateBtn').show();

				// 확장 및 축소 버튼
				//Ext.getCmp('MCV_volumeTieringReconfigBtn').hide();

				// 제거 버튼
				Ext.getCmp('MCV_volumeTieringDeleteBtn').hide();

				// 티어링 옵션 버튼
				Ext.getCmp('MCV_volumeTieringOptionBtn').hide();

				// 볼륨명
				Ext.getCmp('MCV_volumeTieringCreateName').setText(vol_name);

				// 복제 수
				Ext.getCmp('MCV_volumeTieringCreateReplicaCount').show();
				Ext.getCmp('MCV_volumeTieringCreateReplicaCountLabel').hide();

				// 티어링 크기
				Ext.getCmp('MCV_volumeTieringCreateTieringSize').show();

				// 티어링 크기 타입
				Ext.getCmp('MCV_volumeTieringCreateTieringSizeUnit').show();
				Ext.getCmp('MCV_volumeTieringCreateTieringSizeLabel').hide();

				// 볼륨 타입
				Ext.getCmp('MCV_volumeTieringCreateType').setValue(volumeType);

				// 최대 생성 가능한 티어링 크기
				if (volumeType == 'thick')
				{
					Ext.getCmp('MCV_volumeTieringCreateTieringSizeMax').show();
					Ext.getCmp('MCV_volumeTieringCreateTieringSizeMaxSize').setText('0 Byte');
				}
				else
				{
					Ext.getCmp('MCV_volumeTieringCreateTieringSizeMax').hide();
				}

				// 노드 목록
				MCV_volumeTieringCreateNodeGridStore.loadRawData(poolNameObj.lastSelection[0].get('Nodes'));

				// 노드 목록 체크박스 show
				MCV_volumeTieringCreateNodeGrid.headerCt.items.getAt(0).show();
				MCV_volumeTieringCreateNodeGrid.down('[dataIndex=LV_Size]').hide();
				MCV_volumeTieringCreateNodeGrid.down('[dataIndex=LV_Used]').hide();
				MCV_volumeTieringCreateNodeGrid.down('[dataIndex=Used]').show();
				MCV_volumeTieringCreateWindow.show();
				MCV_volumeTieringCreateWindow.setTitle(lang_mcv_volume[132]);
			}
			// 티어링 관리
			else
			{
				var poolNameObj = Ext.getCmp('MCV_volumeTieringCreatePoolName');

				if (poolNameObj.getStore().data.length == 0)
				{
					if (volumeType == 'thick')
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[133]);
						return false;
					}
					else
					{
						Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[176]);
						return false;
					}
				}

				// 티어링 관리
				Ext.Ajax.request({
					url: '/api/cluster/volume/tier/list',
					jsonData: {
						argument: {
							Volume_Name: vol_name
						}
					},
					callback: function (options, success, response) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						var responseData = Ext.JSON.decode(response.responseText);

						// 예외 처리에 따른 동작
						if (!success || !responseData.success)
						{
							if (response.responseText == ''
									|| typeof(response.responseText) == 'undefined')
								response.responseText = '{}';

							if (typeof(responseData.msg) === 'undefined')
								responseData.msg = '';

							if (typeof(responseData.code) === 'undefined')
								responseData.code = '';

							var checkValue = '{'
								+ '"title": "' + lang_mcv_volume[0] + '",'
								+ '"content": "' + lang_mcv_volume[143] + '",'
								+ '"msg": "' + responseData.msg + '",'
								+ '"code": "' + responseData.code + '",'
								+ '"response": ' + response.responseText
							+ '}';

							return exceptionDataCheck(checkValue);
						}

						// 티어링 정보
						var tierList = responseData.tierList[0];

						// 생성 버튼
						Ext.getCmp('MCV_volumeTieringCreateBtn').hide();

						// 확장 및 축소 버튼
						//Ext.getCmp('MCV_volumeTieringReconfigBtn').show();

						// 제거 버튼
						Ext.getCmp('MCV_volumeTieringDeleteBtn').show();

						// 티어링 옵션 버튼
						Ext.getCmp('MCV_volumeTieringOptionBtn').show();

						// 볼륨명
						Ext.getCmp('MCV_volumeTieringCreateName').setText(vol_name);

						// 볼륨 풀 명
						Ext.getCmp('MCV_volumeTieringCreatePoolName').setValue(tierList.Pool_Name);

						if (tierList.Tier_Type == 'thick')
						{
							Ext.getCmp('MCV_volumeTieringCreateTieringSizeMax').show();
						}
						else
						{
							Ext.getCmp('MCV_volumeTieringCreateTieringSizeMaxSize').setText('0 Byte');
							Ext.getCmp('MCV_volumeTieringCreateTieringSizeMax').hide();
						}

						// 복제 수
						Ext.getCmp('MCV_volumeTieringCreateReplicaCount').hide();
						Ext.getCmp('MCV_volumeTieringCreateReplicaCountLabel').show();

						// 티어링 크기
						Ext.getCmp('MCV_volumeTieringCreateTieringSize').hide();

						// 티어링 크기 타입
						Ext.getCmp('MCV_volumeTieringCreateTieringSizeUnit').hide();
						Ext.getCmp('MCV_volumeTieringCreateTieringSizeLabel').show();

						// 복제 수
						Ext.getCmp('MCV_volumeTieringCreateReplicaCountLabel').setText(tierList.Replica_Count);

						// 티어링 크기
						Ext.getCmp('MCV_volumeTieringCreateTieringSizeLabel').setText(tierList.Size);

						//티어링 크기
						var selectVolumeSize = tierList.Size.substring(0, tierList.Size.length-3);
						Ext.getCmp('MCV_volumeTieringCreateTieringSize').setValue(selectVolumeSize);
						//티어링 크기 타입
						var tierSizeUnit = tierList.Size.substring(tierList.Size.length-3);
						Ext.getCmp('MCV_volumeTieringCreateTieringSizeUnit').setValue(tierSizeUnit);

						// 노드 목록
						MCV_volumeTieringCreateNodeGridStore.loadRawData(Ext.getCmp('MCV_volumeTieringCreatePoolName').lastSelection[0].get('Nodes'));
						MCV_volumeTieringCreateNodeGrid.down('[dataIndex=LV_Size]').show();
						MCV_volumeTieringCreateNodeGrid.down('[dataIndex=LV_Used]').show();
						MCV_volumeTieringCreateNodeGrid.down('[dataIndex=Used]').hide();
						MCV_volumeTieringCreateWindow.show();
						MCV_volumeTieringCreateWindow.setTitle(lang_mcv_volume[142]);

						// 티어링 생성시 선택된 노드 리스트
						var selectedNodes = [];

						for (var i=0; i<tierList.Nodes.length; i++)
						{
							MCV_volumeTieringCreateNodeGrid.store.each(
								function (record) {
									if (record.get('Hostname') !== tierList.Nodes[i].Hostname)
										return;

									// 티어링 장비 상태
									record.set('HW_Status',tierList.Nodes[i].HW_Status);

									// 티어링 서비스 상태
									record.set('SW_Status',tierList.Nodes[i].SW_Status);

									// 티어링 사용률
									record.set('LV_Used',tierList.Nodes[i].LV_Used);

									// 티어링 크기
									record.set('LV_Size',tierList.Nodes[i].LV_Size);

									// 선택된 노드 리스트 배열
									selectedNodes.push(record);
								}
							);
						}

						// 노드 목록
						MCV_volumeTieringCreateNodeGridStore.loadRawData(selectedNodes);

						// 노드 목록 체크박스 hide
						MCV_volumeTieringCreateNodeGrid.headerCt.items.getAt(0).hide();
					},
				});
			}
		}
	});
}

// 최대 생성 가능한 티어링 크기
function updateTieringCreateMaxSize()
{
	// 선택한 노드수(노드수)
	var selectNodeCount = MCV_volumeTieringCreateNodeGrid.getSelectionModel().getCount();

	// 선택한 노드(노드)
	var selectNodeSizeArray = [];
	var selectNode = MCV_volumeTieringCreateNodeGrid.getSelectionModel().getSelection();

	// 선택한 노드리스트의 최소 남은 용량
	if (selectNodeCount > 0)
	{
		if (MCV_volumeTieringCreateNodeGrid.down('[dataIndex=LV_Size]').hidden == true)
		{
			// 티어링 생성일 때
			for (var i=0, len=selectNode.length; i<len; i++)
			{
				// 선택한 노드의 남은 볼륨크기
				var selectNodeSizeMb = convertSizeToMB(selectNode[i].get('Free_Size'));

				selectNodeSizeArray.push(selectNodeSizeMb);
			}
		}
		else
		{
			// 티어링 관리일 때
			for (var i=0, len=selectNode.length; i<len; i++)
			{
				// 선택한 노드의 남은 볼륨 크기
				var selectNodeSize = selectNode[i].get('Free_Size');

				// 선택한 노드의 티어링 크기
				var selectNodeTierSize = selectNode[i].get('LV_Size');

				if (selectNodeTierSize !== '')
				{
					// 사용 중인 티어링일 때
					var selectNodeSizeMb     = convertSizeToMB(selectNodeSize);
					var selectNodeTierSizeMb = convertSizeToMB(selectNodeTierSize);

					selectNodeSizeArray.push(parseInt(selectNodeSizeMb)+parseInt(selectNodeTierSizeMb));
				}
				else
				{
					var selectNodeSizeMb = convertSizeToMB(selectNodeSize);

					selectNodeSizeArray.push(selectNodeSizeMb);
				}
			}
		}

		var selectNodeSizeMin = selectNodeSizeArray.reduce(function (previous, current) {
			return previous > current ? current:previous;
		});

		// 복제수
		var replicaCount = Ext.getCmp('MCV_volumeTieringCreateReplicaCount').getValue();

		// 티어링 최대 크기 MiB
		var tierMaxSizeMb = (selectNodeCount * selectNodeSizeMin) / replicaCount;

		// 티어링 최대 크기/단위
		var tierMaxSize;
		var tierMaxUnitSize;

		if (tierMaxSizeMb <= 0)
		{
			tierMaxUnitSize = '0 Byte';
		}
		else
		{
			tierMaxUnitSize = convertMBToSize(tierMaxSizeMb);
		}

		Ext.getCmp('MCV_volumeTieringCreateTieringSizeMaxSize').setText(tierMaxUnitSize);
	}
	else
	{
		Ext.getCmp('MCV_volumeTieringCreateTieringSizeMaxSize').setText('0 Byte');
	}
};

// 티어링 옵션 변경
function changeTieringOption()
{
	// 티어링 크기
	if (!Ext.getCmp('MCV_volumeTieringOptionTierMaxMB').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionTierMaxFiles').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionTierWatermarkHigh').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionTierWatermarkLow').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionIOThresholdReadFreq').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionIOThresholdWriteFreq').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionMigrationFreqPromote').isValid())
	{
		return false;
	}

	if (!Ext.getCmp('MCV_volumeTieringOptionMigrationFreqDemote').isValid())
	{
		return false;
	}

	// 볼륨명
	var Volume_Name = document.getElementById('MCV_volumeTieringCreateName').innerHTML;

	// Tier 동작 모드
	var Tier_Mode = Ext.getCmp('MCV_volumeTieringOptionTierMode').getValue().tierMode;

	// File migration 시 최대 데이터 양(1회 시)
	var Tier_Max_MB = Ext.getCmp('MCV_volumeTieringOptionTierMaxMB').getValue();

	// File migration 시 최대 파일 수(1회 시)
	var Tier_Max_Files = Ext.getCmp('MCV_volumeTieringOptionTierMaxFiles').getValue();

	// Promote 수행 사용률
	var High = Ext.getCmp('MCV_volumeTieringOptionTierWatermarkHigh').getValue();

	// Demote 수행 방지 사용률
	var Low = Ext.getCmp('MCV_volumeTieringOptionTierWatermarkLow').getValue();

	// Promote 수행 읽기 기준 횟수
	var Read_Freq = Ext.getCmp('MCV_volumeTieringOptionIOThresholdReadFreq').getValue();

	// Promote 수행 쓰기 기준 횟수
	var Write_Freq = Ext.getCmp('MCV_volumeTieringOptionIOThresholdWriteFreq').getValue();

	// Promote 수행 주기
	var Promote = Ext.getCmp('MCV_volumeTieringOptionMigrationFreqPromote').getValue();

	// Demote 수행 주기
	var Demote = Ext.getCmp('MCV_volumeTieringOptionMigrationFreqDemote').getValue();

	waitWindow(lang_mcv_volume[0], lang_mcv_volume[164]);

	// 티어링 옵션 변경 API
	Ext.Ajax.request({
		url: '/api/cluster/volume/tier/opts',
		jsonData: {
			argument: {
				Volume_Name: Volume_Name,
				Tier_Opts: {
					Tier_Mode: Tier_Mode,
					Tier_Max_MB: Tier_Max_MB,
					Tier_Max_Files: Tier_Max_Files,
					Watermark: {
						High: High,
						Low: Low,
					},
					IO_Threshold: {
						Read_Freq: Read_Freq,
						Write_Freq: Write_Freq,
					},
					Migration_Freq: {
						Promote: Promote,
						Demote: Demote
					}
				}
			}
		},
		callback: function (options, success, response) {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			var responseData = Ext.JSON.decode(response.responseText);

			MCV_volumeTieringOptionWindow.close();

			// 예외 처리에 따른 동작
			if (!success || !responseData.success)
			{
				if (response.responseText == ''
						|| typeof(response.responseText) == 'undefined')
					response.responseText = '{}';

				if (typeof(responseData.msg) === 'undefined')
					responseData.msg = '';

				if (typeof(responseData.code) === 'undefined')
					responseData.code = '';

				var checkValue = '{'
					+ '"title": "' + lang_mcv_volume[0] + '",'
					+ '"content": "' + lang_mcv_volume[166] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[165]);
		},
	});
}

function deleteVolumeTiering(vol_name)
{
	waitWindow(lang_mcv_volume[0], lang_mcv_volume[151]);

	Ext.Ajax.request({
		url: '/api/cluster/volume/tier/detach',
		jsonData: {
			argument: {
				Volume_Name: vol_name,
			}
		},
		success: function (response) {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			var responseData = Ext.decode(response.responseText);

			if (!success || !responseData.success)
			{
				Ext.MessageBox.alert(lang_mcv_volume[0], responseData.msg);
				return;
			}

			// 볼륨 정보 창
			if (Ext.getCmp('MCV_volumeViewWindow').hidden == false)
			{
				loadVolumeStore();
				MCV_volumeTieringCreateWindow.hide();
				Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[152]);
				return;
			}

			Ext.defer(function () {
				Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeViewTierCreate'));
				Ext.QuickTips.unregister(Ext.getCmp('MCV_volumeViewArbiterButton'));
			}, 100);

			loadVolumeStore();

			Ext.getCmp('MCV_volumeViewTierInfo').hide();
			Ext.getCmp('MCV_volumeViewTierCreate').setDisabled(false);
			Ext.getCmp('MCV_volumeViewArbiterButton').setDisabled(false);

			MCV_volumeTieringCreateWindow.hide();
			Ext.MessageBox.alert(lang_mcv_volume[0], lang_mcv_volume[152]);
		}
	});
}
*/

/*
 * 클러스터 볼륨 관리 -> 볼륨 관리
 */
Ext.define(
	'/admin/js/manager_cluster_volume',
	{
		extend: 'BasePanel',
		id: 'manager_cluster_volume',
		bodyStyle: 'padding: 0;',
		load: function () {
			Ext.QuickTips.init();
			loadVolumeStore();
			loadVPoolStore();
		},
		items: [
			{
				xtype: 'BasePanel',
				layout: 'fit',
				flex: 1,
				bodyStyle: 'padding: 20px;',
				items: [MCV_volumeGrid]
			}
		]
	}
);

