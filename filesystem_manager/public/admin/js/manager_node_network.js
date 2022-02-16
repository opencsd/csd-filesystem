/****************************************************************************
 * Models
 ****************************************************************************/

// 네트워크 장치 목록 모델
Ext.define(
	'MND_deviceModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Type', type: 'string' },
			{ name: 'Device', type: 'string' },
			{ name: 'Model', type: 'string' },
			{ name: 'HWAddr', type: 'string' },
			{ name: 'Speed', type: 'string' },
			{ name: 'MTU', type: 'integer' },
			{ name: 'OnBoot', type: 'string' },
			{ name: 'LinkStatus', type: 'string' },
			{ name: 'BootProto', type: 'string' },
			{ name: 'IPAddrs', type: 'auto' },
			{ name: 'Mgmt_IP', type: 'boolean', defaultValue: false },

			/* Bonding */
			{ name: 'Master', type: 'string' },
			{ name: 'Slave', type: 'string' },
			{ name: 'Slaves', type: 'auto' },
			{ name: 'Primary', type: 'string' },
			{ name: 'ActiveSlave', type: 'string' },
			{ name: 'Mode', type: 'string' },
			{ name: 'PrintMode', type: 'string' },

			/* VLAN */
			{ name: 'Tag', type: 'integer' },
		]
	}
);

// 네트워크 장치 일반 정보 그리드
Ext.define(
	'MND_deviceDetailGeneralModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Device', 'MTU', 'HWAddr', 'LinkStatus',
			'Speed', 'OnBoot',
		]
	}
);

// 네트워크 장치 네트워크 주소 정보
Ext.define(
	'MND_deviceDetailAddrModel',
	{
		extend: 'Ext.data.Model',
		fields: ['IPAddr', 'Netmask', 'Gateway']
	}
);

// 네트워크 장치 Rx 정보
Ext.define(
	'MND_deviceDetailRxModel',
	{
		extend: 'Ext.data.Model',
		fields: ['rx_bytes', 'rx_packets', 'rx_dropped', 'rx_errors']
	}
);

// 네트워크 장치 Tx 정보
Ext.define(
	'MND_deviceDetailTxModel',
	{
		extend: 'Ext.data.Model',
		fields: ['tx_bytes', 'tx_packets', 'tx_dropped', 'tx_errors']
	}
);

// 본딩 구성 장치 선택 모델
Ext.define(
	'MNB_bondConfigSlaveModel',
	{
		extend: 'Ext.data.Model',
		fields: [ 'Device', 'HWAddr', 'Master', 'IPAddrs', 'LinkStatus' ]
	}
);

// 본딩 Primary 디바이스 모델
Ext.define(
	'MNB_bondConfigSlavePrimaryModel',
	{
		extend: 'Ext.data.Model',
		fields: ['DeviceName', 'DeviceView']
	}
);

// 본딩 장치 상세 정보 모델
Ext.define(
	'MNB_bondSlavesDetailModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Device', 'Model', 'HWAddr', 'LinkStatus']
	}
);

// 네트워크 정보 모델
Ext.define(
	'MNA_addressGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'IPAddr', 'Netmask' ,'Gateway', 'Device', 'Mgmt_IP'
		]
	}
);

// 디바이스명 모델
Ext.define(
	'MNA_addressDeviceModel',
	{
		extend: 'Ext.data.Model',
		fields: ['DeviceName']
	}
);

/**
 * Route table model
 */
Ext.define(
	'MNR_routeTableModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'ID', type: 'integer', },
			{ name: 'Name', type: 'string', },
		]
	}
);

/**
 * Route rule model
 */
Ext.define(
	'MNR_routeRuleModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Table', type: 'string' },
			{ name: 'Device', type: 'string', },
			{ name: 'From', type: 'string', },
			{ name: 'To', type: 'string', },
		],
	}
);

/**
 * Route entry model
 */
Ext.define(
	'MNR_routeEntryModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Table', type: 'string', },
			{ name: 'To', type: 'string', },
			{ name: 'Via', type: 'string', },
			{ name: 'Default', type: 'boolean', },
			{ name: 'Device', type: 'string', },
			{ name: 'Metric', type: 'integer', },
		],
	}
);

/****************************************************************************
 * Stores
 ****************************************************************************/

// 네트워크 장치 목록 스토어
var MND_deviceGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceModel',
		sorters: [
			{ property: 'Device', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Device',
			}
		}
	}
);

// 네트워크 장치 상세 정보 스토어
var MND_deviceDetailGeneralStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceDetailGeneralModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		}
	}
);

// 네트워크 장치 주소 목록 스토어
var MND_deviceDetailAddrStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceDetailAddrModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'IPAddrs',
			}
		}
	}
);

// 네트워크 장치 Rx 스토어
var MND_deviceDetailRxStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceDetailRxModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'Statistics',
			}
		}
	}
);

// 네트워크 장치 Tx 스토어
var MND_deviceDetailTxStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceDetailTxModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'Statistics',
			}
		}
	}
);

// 본딩 장치 목록 스토어
var MNB_bondGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceModel',
		sorters: [
			{
				property: 'Device',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Device',
			}
		}
	}
);

var MNV_vlanGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_deviceModel',
		sorters: [
			{
				property: 'Device',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Device',
			}
		},
		listeners: {
			beforeload: function (me, operation, eOpts) {
				var grid = Ext.getCmp('MNV_vlanGrid');

				Ext.getCmp('MNV_vlanAddBtn').setDisabled(true);
				Ext.getCmp('MNV_vlanModifyBtn').setDisabled(true);
				Ext.getCmp('MNV_vlanDeleteBtn').setDisabled(true);

				grid.mask();
			},
			load: function (me, records, success, eOpts) {
				var grid = Ext.getCmp('MNV_vlanGrid');

				Ext.getCmp('MNV_vlanAddBtn').setDisabled(false);
				Ext.getCmp('MNV_vlanModifyBtn').setDisabled(false);
				Ext.getCmp('MNV_vlanDeleteBtn').setDisabled(false);

				grid.unmask();
			},
		}
	}
);

// 본딩 구성 장치 선택 스토어
var MNB_bondConfigSlaveStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNB_bondConfigSlaveModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Device'
			}
		},
		sorters: [
			{
				property: 'Device',
				direction: 'ASC'
			}
		],
		listeners: {
			beforeload: function (store, operation, eOpts) {
				MNB_bondConfigSlaveStore.removeAll();
			}
		}
	}
);

// 본딩 주 장치 스토어
var MNB_bondConfigSlavePrimaryStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNB_bondConfigSlavePrimaryModel',
		sorters: [
			{
				property: 'DeviceName',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		}
	}
);

// 본딩 상세 정보 스토어
var MNB_bondSlavesDetailStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNB_bondSlavesDetailModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				idProperty: 'Device'
			}
		}
	}
);

// 네트워크 주소 정보 스토어
var MNA_addressGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNA_addressGridModel',
		sorters: [
			{ property: 'Device', direction: 'ASC' },
			{ property: 'IPAddr', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity'
			}
		}
	}
);

// 네트워크 주소 장치명 스토어
var MNA_addressDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNA_addressDeviceModel',
		sorters: [
			{ property: 'DeviceName', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		}
	}
);

/****************************************************************************
 * Grids
 ****************************************************************************/

/*
 * 물리적 네트워크 장치 상세 정보
 */
var MND_deviceDetailGeneralGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MND_deviceDetailGeneralGrid',
		store: MND_deviceDetailGeneralStore,
		multiSelect: false,
		title: lang_mnd_device[0],
		style: { marginBottom: '20px' },
		columns: [
			{
				flex: 1,
				text: lang_mnd_device[11],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Device'
			},
			{
				flex: 1,
				text: lang_mnd_device[14],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'HWAddr'
			},
			{
				flex: 1,
				text: lang_mnd_device[15],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Speed'
			},
			{
				flex: 1,
				text: ' MTU',
				menuDisabled: true,
				sortable: true,
				dataIndex: 'MTU'
			},
			{
				flex: 1,
				text: lang_mnd_device[16],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'OnBoot'
			},
			{
				flex: 1,
				text: lang_mnd_device[17],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LinkStatus'
			}
		]
	}
);

var MND_deviceDetailAddrGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MND_deviceDetailAddrGrid',
		store: MND_deviceDetailAddrStore,
		multiSelect: false,
		title: lang_mnd_device[18],
		style: { marginBottom: '20px' },
		columns: [
			{
				flex: 1,
				text: lang_mnd_device[19],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'IPAddr'
			},
			{
				flex: 1,
				text: lang_mnd_device[20],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Netmask'
			},
			{
				flex: 1,
				text: lang_mnd_device[21],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Gateway'
			},
		]
	}
);

var MND_deviceDetailRxGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MND_deviceDetailRxGrid',
		store: MND_deviceDetailRxStore,
		multiSelect: false,
		title: lang_mnd_device[22],
		style: { marginBottom: '20px' },
		columns: [
			{
				flex: 1,
				text: 'bytes',
				sortable: true,
				menuDisabled: true,
				dataIndex: 'rx_bytes'
			},
			{
				flex: 1,
				text: 'packets',
				sortable: true,
				menuDisabled: true,
				dataIndex: 'rx_packets'
			},
			{
				flex: 1,
				text: 'dropped',
				menuDisabled: true,
				sortable: true,
				dataIndex: 'rx_dropped'
			},
			{
				flex: 1,
				text: 'errors',
				menuDisabled: true,
				sortable: true,
				dataIndex: 'rx_errors'
			}
		]
	}
);

var MND_deviceDetailTxGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MND_deviceDetailTxGrid',
		store: MND_deviceDetailTxStore,
		multiSelect: false,
		title: lang_mnd_device[23],
		columns: [
			{
				flex: 1,
				text: 'bytes',
				sortable: true,
				menuDisabled: true,
				dataIndex: 'tx_bytes'
			},
			{
				flex: 1,
				text: 'packets',
				sortable: true,
				menuDisabled: true,
				dataIndex: 'tx_packets'
			},
			{
				flex: 1,
				text: 'dropped',
				menuDisabled: true,
				sortable: true,
				dataIndex: 'tx_dropped'
			},
			{
				flex: 1,
				text: 'errors',
				menuDisabled: true,
				sortable: true,
				dataIndex: 'tx_errors'
			}
		]
	}
);

// 물리적 네트워크 목록 그리드
var MND_deviceGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MND_deviceGrid',
		store: MND_deviceGridStore,
		multiSelect: false,
		title: lang_mnd_device[37],
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			checkOnly: true,
			allowDeselect: true,
			listeners: {
				selectall: deviceSelectListener,
				deselectall: deviceSelectListener,
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mnd_device[11],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Device'
			},
			{
				flex: 2,
				text: lang_mnd_device[26],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Model'
			},
			{
				flex: 1,
				text: lang_mnd_device[14],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'HWAddr'
			},
			{
				flex: 1,
				text: lang_mnd_device[15],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Speed'
			},
			{
				flex: 1,
				text: ' MTU',
				menuDisabled: true,
				sortable: true,
				dataIndex: 'MTU'
			},
			{
				flex: 1,
				text: lang_mnd_device[16],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'OnBoot'
			},
			{
				flex: 1,
				text: lang_mnd_device[17],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LinkStatus'
			},
			{
				flex: 1,
				text: lang_mnd_device[27],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'BootProto',
			},
			{
				flex: 1,
				text: lang_mnd_device[28],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Master'
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { deviceSelectListener() }, 200);
			}
		},
		tbar: [
			/*
			{
				text: lang_mnd_device[38],
				id: 'MND_bondingAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					MNB_bondConfigWindow.animateTarget = Ext.getCmp('MNB_bondingAddBtn');

					Ext.getCmp('MNB_bondConfigWindowPreBtn').hide();
					Ext.getCmp('MNB_bondConfigWindowPreBtn').disable();
					Ext.getCmp('MNB_bondConfigWindowNextBtn').show();
					Ext.getCmp('MNB_bondConfigWindowNextBtn').enable();
					Ext.getCmp('MNB_bondConfigWindowSetBtn').hide();
					Ext.getCmp('MNB_bondConfigWindowSetBtn').disable();

					// 타입 - 생성
					Ext.getCmp('MNB_bondConfigType').setValue('create');

					// 본드명
					Ext.getCmp('MNB_bondConfigBondName').setValue();
					MNB_bondConfigWindow.layout.setActiveItem('MNB_bondConfigForm');

					// 모드
					Ext.getCmp('MNB_bondConfigModeRoundRobin').setValue(true);

					// 활성화
					Ext.getCmp('MNB_bondConfigOnBoot').setValue(false);
					Ext.getCmp('MNB_bondConfigOnBoot').setDisabled(false);

					// 장치 정보 호출
					waitWindow(lang_mnb_bond[0], lang_mnb_bond[54]);

					Ext.getCmp('MNB_bondConfigTitle').update(lang_mnb_bond[57]);

					loadBondSlaves();
				}
			},
			{
				text: lang_mnd_device[39],
				id: 'MND_vlanAddBtn',
				iconCls: 'b-icon-add',
				handle: function () {
				}
			},
			*/
			{
				text: lang_mnd_device[29],
				id: 'MND_deviceModifyBtn',
				iconCls: 'b-icon-edit',
				handler: function () {
					Ext.getCmp('MND_deviceModifyForm').getForm().reset();

					var device = MND_deviceGrid.getSelectionModel().getSelection()[0];

					if (isBonding(device))
					{
						// 활성화
						// 선택된 장치가 클러스터 기본 인터페이스인 경우 비활성화 제한
						Ext.getCmp('MND_deviceModifyOnBoot')
							.setDisabled(device.get('Device').match(/^bond[0-1]$/));
					}
					else if (isVLAN(device))
					{
						// TODO: validation
					}
					else
					{
						if (device.get('Slave') == 'yes')
						{
							Ext.MessageBox.alert(lang_mnd_device[0], lang_mnd_device[30]);
							return;
						}
					}

					Ext.getCmp('MND_deviceModifyNameLabel').update(device.get('Device'));
					Ext.getCmp('MND_deviceModifyName').setValue(device.get('Device'));
					Ext.getCmp('MND_deviceModifyOnBoot').setValue(device.get('OnBoot') == 'yes');
					Ext.getCmp('MND_deviceModifyMTU').setValue(device.get('MTU'));

					MND_deviceModifyWin.show();
				}
			},
			{
				text: lang_mnd_device[31],
				id: 'MND_deviceDetailBtn',
				iconCls: 'b-icon-detail-view',
				handler: function () {
					MND_deviceDetailGeneralStore.removeAll();
					MND_deviceDetailAddrStore.removeAll();
					MND_deviceDetailRxStore.removeAll();
					MND_deviceDetailTxStore.removeAll();

					var device = MND_deviceGrid.getSelectionModel().getSelection()[0];
					var type   = getDeviceType(device);

					if (type == null)
					{
						console.error('Unknown device type:', device);
						return;
					}

					GMS.Cors.request({
						url: '/api/network/' + type + '/info',
						waitMsgBox: waitWindow(lang_mnd_device[0], lang_mnd_device[36]),
						method: 'POST',
						jsonData: {
							Device: device.get('Device'),
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							MND_deviceDetailGeneralStore.loadRawData(decoded.entity, false);
							MND_deviceDetailAddrStore.loadRawData(decoded.entity, false);
							MND_deviceDetailRxStore.loadRawData(decoded.entity, false);
							MND_deviceDetailTxStore.loadRawData(decoded.entity, false);

							MND_deviceDetailWin.show();
						}
					});
				}
			},
			/*
			{
				text: lang_common[7],
				id: 'MND_deviceDeleteBtn',
				iconCls: 'b-icon-delete',
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mnd_device[0],
						lang_mnd_device[43],
						function (btn, text) {
							if (btn != 'yes')
								return;

							var device = MND_deviceGrid.getSelectionModel().getSelection()[0];
							var type   = getDeviceType(device);

							if (type == null)
							{
								console.error('Unknown device type:', device);
								return;
							}

							waitWindow(lang_mnd_device[0], lang_mnd_device[41]);

							GMS.Cors.request({
								url: '/api/network/' + type + '/delete',
								method: 'POST',
								jsonData: {
									Device: device.get('Device'),
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mnd_device[0], lang_mnd_device[42]);
									loadNetworkInfo();
								}
							});
						}
					);
				},
			}
			*/
		]
	}
);

// 본딩 목록
var MNB_bondGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNB_bondGrid',
		store: MNB_bondGridStore,
		multiSelect: false,
		title: lang_mnb_bond[11],
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			checkOnly: true,
			allowDeselect: true,
			listeners: {
				selectall: bondSelectListener,
				deselectall: bondSelectListener,
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mnb_bond[28],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Device'
			},
			{
				flex: 1,
				text: lang_mnb_bond[30],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Slaves',
			},
			{
				flex: 1,
				text: lang_mnb_bond[59],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Primary'
			},
			{
				flex: 1,
				text: lang_mnb_bond[60],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'ActiveSlave'
			},
			{
				flex: 1,
				text: lang_mnb_bond[31],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'PrintMode'
			},
			{
				dataIndex: 'Mode',
				hidden: true
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { bondSelectListener() }, 200);
			}
		},
		tbar: [
			{
				text: lang_mnb_bond[33],
				id: 'MNB_bondAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					MNB_bondConfigWindow.animateTarget
						= Ext.getCmp('MNB_bondAddBtn');

					Ext.getCmp('MNB_bondConfigWindowPreBtn').hide();
					Ext.getCmp('MNB_bondConfigWindowPreBtn').disable();
					Ext.getCmp('MNB_bondConfigWindowNextBtn').show();
					Ext.getCmp('MNB_bondConfigWindowNextBtn').enable();
					Ext.getCmp('MNB_bondConfigWindowSetBtn').hide();
					Ext.getCmp('MNB_bondConfigWindowSetBtn').disable();

					// 타입 - 생성
					Ext.getCmp('MNB_bondConfigType').setValue('create');

					// 본드명
					Ext.getCmp('MNB_bondConfigBondName').setValue();
					MNB_bondConfigWindow.layout.setActiveItem('MNB_bondConfigForm');

					// 모드
					Ext.getCmp('MNB_bondConfigModeRoundRobin').setValue(true);

					// 활성화
					Ext.getCmp('MNB_bondConfigOnBoot').setValue(false);
					Ext.getCmp('MNB_bondConfigOnBoot').setDisabled(false);

					// 장치 정보 호출
					Ext.getCmp('MNB_bondConfigTitle').update(lang_mnb_bond[57]);

					loadBondSlaves();
				}
			},
			{
				text: lang_mnb_bond[34],
				id: 'MNB_bondModifyBtn',
				iconCls: 'b-icon-edit',
				handler: function () {
					MNB_bondConfigWindow.animateTarget
						= Ext.getCmp('MNB_bondModifyBtn');

					Ext.getCmp('MNB_bondConfigWindowPreBtn').hide();
					Ext.getCmp('MNB_bondConfigWindowPreBtn').disable();
					Ext.getCmp('MNB_bondConfigWindowNextBtn').show();
					Ext.getCmp('MNB_bondConfigWindowNextBtn').enable();
					Ext.getCmp('MNB_bondConfigWindowSetBtn').hide();
					Ext.getCmp('MNB_bondConfigWindowSetBtn').disable();

					// 타입 - 수정
					Ext.getCmp('MNB_bondConfigType').setValue('modify');

					// 본드명
					var bond = MNB_bondGrid.getSelectionModel().getSelection()[0];
					
					Ext.getCmp('MNB_bondConfigBondName').setValue(bond.get('Device'));

					MNB_bondConfigWindow.layout.setActiveItem('MNB_bondConfigForm');

					// 모드 선택
					var mode     = bond.get('Mode');
					var mode_str = null;

					switch (parseInt(mode))
					{
						case 0:
							mode_str = 'RoundRobin';
							break;
						case 1:
							mode_str = 'ActiveBackup';
							break;
						case 2:
							mode_str = 'BalanceXOR';
							break;
						case 4:
							mode_str = 'LACP';
							break;
						case 5:
							mode_str = 'BalanceTLB';
							break;
						case 6:
							mode_str = 'BalanceALB';
							break;
					}

					if (mode_str != null)
					{
						Ext.getCmp('MNB_bondConfigMode' + mode_str).setValue(true);
					}

					// 활성화 유무
					Ext.getCmp('MNB_bondConfigOnBoot').setDisabled(false);

					Ext.getCmp('MNB_bondConfigOnBoot')
						.setValue(bond.get('OnBoot') == 'yes');

					// 본드 명
					if (bond.get('Device').match(/^bond[0-1]$/))
					{
						Ext.getCmp('MNB_bondConfigOnBoot').setDisabled(true);
					}

					// 장치 정보 호출
					var slaves = [];

					for (var i = 0; i < bond.get('Slaves').length; i++)
					{
						slaves.push(bond.get('Slaves')[i]);
					}

					Ext.getCmp('MNB_bondConfigTitle').update(lang_mnb_bond[58]);

					loadBondSlaves(slaves);
				}
			},
			{
				text: lang_mnb_bond[35],
				id: 'MNB_bondDeleteBtn',
				iconCls: 'b-icon-delete',
				handler: function () {
					var find_ip = '';
					var bond    = MNB_bondGrid.getSelectionModel().getSelection()[0];

					MNA_addressGridStore.each(
						function (record) {
							if (record.get('Device') == bond.get('Device'))
							{
								find_ip = record.get('IPAddr');
							}
						}
					);

					// 삭제 예외 처리
					if (bond.get('Device').match(/^bond0$/)
							|| find_ip != '')
					{
						Ext.MessageBox.alert(
							lang_mnb_bond[0],
							bond.get('Device').match(/^bond0$/) ? 
								lang_mnb_bond[61] : lang_mnb_bond[62]
						);
						return false;
					}

					Ext.MessageBox.confirm(
						lang_mnb_bond[0],
						lang_mnb_bond[36],
						function (btn, text) {
							if (btn != 'yes')
								return;

							var slaves = [];

							if (slaves.length)
							{
								Ext.MessageBox.alert(
									lang_mnb_bond[0],
									lang_mnd_device[30] + ': ' + slaves.join(', ')
								);

								return;
							}

							waitWindow(lang_mnb_bond[0], lang_mnb_bond[37]);

							GMS.Cors.request({
								url: '/api/network/bonding/delete',
								method: 'POST',
								jsonData: {
									Device: bond.get('Device'),
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mnb_bond[0], lang_mnb_bond[38]);
									loadNetworkInfo();
								}
							});
						}
					);
				}
			},
			{
				text: lang_mnb_bond[40],
				id: 'MNB_bondDetailBtn',
				iconCls: 'b-icon-detail-view',
				handler: function () {
					// 물리 장치 상세 정보 데이터 로드
					var bond   = MNB_bondGrid.getSelectionModel().getSelection()[0];
					var slaves = bond.get('Slaves');
					var data   = [];

					MND_deviceGridStore.each(
						function (record, id)
						{
							if (slaves.includes(record.get('Device')))
							{
								data.push({
									Device: record.get('Device'),
									Model: record.get('Model'),
									HWAddr: record.get('HWAddr'),
									LinkStatus: record.get('LinkStatus'),
								});
							}
						}
					);

					MNB_bondSlavesDetailStore.removeAll();
					MNB_bondSlavesDetailStore.loadRawData(data, false);

					var window = MNB_bondSlavesDetailWindow;

					window.animateTarget = Ext.getCmp('MNB_bondDetailBtn');
					window.show();
				}
			}
		]
	}
);

/*
// VLAN 목록
var MNV_vlanGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNV_vlanGrid',
		store: MNV_vlanGridStore,
		multiSelect: false,
		title: 'VLAN',
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			checkOnly: true,
			allowDeselect: true,
			listeners: {
				selectall: function () { },
				deselectall: function () { }
			}
		},
		columns: [
			{
				flex: 1,
				dataIndex: 'Device',
				text: lang_common[35],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'Tag',
				text: lang_common[36],
				sortable: true,
				menuDisabled: true,
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { }, 200);
			}
		},
		tbar: [
			{
				text: lang_common[34],
				id: 'MNV_vlanAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					Ext.getCmp('vlanDevice').setDisabled(false);
					Ext.getCmp('vlanTag').setDisabled(false);
					Ext.getCmp('vlanOnBoot').setDisabled(false);
					Ext.getCmp('vlanMTU').setDisabled(false);

					vlanWindow.show();
				}
			},
			{
				text: lang_common[6],
				id: 'MNV_vlanModifyBtn',
				iconCls: 'b-icon-edit',
				handler: function () {
					Ext.getCmp('vlanDevice').setDisabled(true);
					Ext.getCmp('vlanTag').setDisabled(true);
					Ext.getCmp('vlanOnBoot').setDisabled(false);
					Ext.getCmp('vlanMTU').setDisabled(false);

					vlanWindow.show();
				}
			},
			{
				text: lang_common[7],
				id: 'MNV_vlanDeleteBtn',
				iconCls: 'b-icon-delete',
				handler: function (btn, event) {
					var device = MNV_vlanGrid.getSelectionModel().getSelection()[0];

					Ext.MessageBox.confirm(
						lang_mnv_vlan[5],
						lang_mnv_vlan[6],
						function (buttonId, text, eOpts) {
							if (buttonId != 'yes')
								return;

							waitWindow(lang_mnv_vlan[5], lang_mnv_vlan[7]);

							GMS.Cors.request({
								url: '/api/network/vlan/delete',
								method: 'POST',
								jsonData: {
									Device: device.get('Device'),
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mnv_vlan[5], decoded.msg);

									loadNetworkInfo();
								}
							});
						}
					);
				}
			},
		]
	}
);
*/

// 본딩 장치 상세 그리드
var MNB_bondSlavesDetailGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNB_bondSlavesDetailGrid',
		store: MNB_bondSlavesDetailStore,
		multiSelect: false,
		frame: false,
		border: false,
		columns: [
			{
				flex: 1,
				text: lang_mnb_bond[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Device'
			},
			{
				flex: 1,
				text: lang_mnb_bond[9],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'HWAddr'
			},
			{
				flex: 1,
				text: lang_mnd_device[17],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LinkStatus'
			}
		]
	}
);

// MVC 구조로 리팩토링할 때, 해당하는 Grid의 Object로 구가하여 관리해야함
// Commect by THKIM. (2021.03.25)
var MNB_bondConfigSlaveGridListeners = null;

// 본딩 구성 장치 선택 그리드
var MNB_bondConfigSlaveGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNB_bondConfigSlaveGrid',
		store: MNB_bondConfigSlaveStore,
		multiSelect: false,
		title: lang_mnb_bond[6],
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
		},
		columns: [
			{
				flex: 1,
				text: lang_mnb_bond[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Device'
			},
			{
				flex: 1,
				text: lang_mnb_bond[9],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'HWAddr'
			},
			{
				flex: 1,
				text: lang_mnb_bond[32],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LinkStatus'
			}
		],
		/*
		listeners: {
			select: function (grid, record, index, eOpts) {
				console.log('select:', record);

				// 다른 본드 정보의 선택 해제 못함
				if (record.get('Master') != Ext.getCmp('MNB_bondConfigBondName').getValue()
					|| record.get('Master') != null)
				{
					grid.getSelectionModel().deselect(index);
				}
				else
				{
					Ext.defer(
						function () {
							var slaves = [
								[ record.get('Device'), record.get('Device') ]
							];

							MNB_bondConfigSlavePrimaryStore.add(slaves);
						},
						200
					);
				}

				Ext.getCmp('MNB_bondConfigWindowSetBtn').setDisabled(false);
			},
			deselect: function (grid, record, index, eOpts) {
				console.log('deselect:', record);

				Ext.defer(
					function () {
						MNB_bondConfigSlavePrimaryStore.each(
							function (record) {
								if (typeof(record) != 'undefined')
								{
									if (record.get('DeviceName') != '0')
										MNB_bondConfigSlavePrimaryStore.remove(record);
								}
							}
						);

						var selection = grid.getSelectionModel().getSelection();

						// 현재 사용 중인 본딩의 디바이스는 하나 이상 선택 되어야 함(수정)
						if (Ext.getCmp('MNB_bondConfigType').getValue() == 'modify')
						{
							if (selection.length == 0)
							{
								Ext.getCmp('MNB_bondConfigWindowSetBtn').setDisabled(true);
								Ext.MessageBox.alert(lang_mnb_bond[0], lang_mnb_bond[53]);
							}
						}
					},
					200
				);
			}
		}
		*/
	}
);

// 네트워크 주소 정보 그리드
var MNA_addressGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNA_addressGrid',
		store: MNA_addressGridStore,
		multiSelect: false,
		title: lang_mna_address[3],
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			listeners: {
				selectall: function () {
					MNA_addressSelect('selectAll');
				},
				deselectall: function () {
					MNA_addressSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mna_address[4],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'IPAddr'
			},
			{
				flex: 1,
				text: lang_mna_address[5],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Netmask'
			},
			{
				flex: 1,
				text: lang_mna_address[6],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Gateway'
			},
			{
				flex: 1,
				text: lang_mna_address[8],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Device'
			},
			{
				// 관리자 IP 체크
				dataIndex: 'Mgmt_IP',
				hidden: true
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MNA_addressSelect(record) }, 200);
			}
		},
		tbar: [
			{
				text: lang_mna_address[11],
				id: 'MNA_addressGridAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					MNA_addressDescForm.getForm().reset();

					// 생성, 수정 구분
					Ext.getCmp('MNA_addressOperType').setValue('add');

					MNA_addressDeviceStore.removeAll();

					MND_deviceGridStore.each(
						function (record) {
							MNA_addressDeviceStore.add(record);
						}
					);

					// 생성할 장치가 없을 시
					if (MNA_addressDeviceStore.getCount() == 0)
					{
						Ext.MessageBox.alert(lang_mna_address[0], lang_mna_address[39]);
						return;
					}

					// 장치 이름 초기값
					var DeviceNameObj = Ext.getCmp('MNA_addressDevice');

					DeviceNameObj.setValue(DeviceNameObj.getStore().getAt(0).get(DeviceNameObj.valueField), true);

					// WINDOW OPEN 시 동작
					MNA_addressDescWindow.animateTarget = Ext.getCmp('MNA_addressGridAddBtn');

					// 디바이스명 활성화
					Ext.getCmp('MNA_addressDevice').setDisabled(false);

					// 활성화 예외 처리
					//Ext.getCmp('MNA_addressActive').setDisabled(false);

					// 수정 시 선택한 IP 초기화
					Ext.getCmp('MNA_addressIpaddr').setValue("");

					// IP 주소 입력
					Ext.getCmp('MNA_addressIpaddr1').setDisabled(false);
					Ext.getCmp('MNA_addressIpaddr2').setDisabled(false);
					Ext.getCmp('MNA_addressIpaddr3').setDisabled(false);
					Ext.getCmp('MNA_addressIpaddr4').setDisabled(false);

					// 네트워크 정보 생성 WINDOW OPEN
					MNA_addressDescWindow.show();
				}
			},
			{
				text: lang_mna_address[12],
				id: 'MNA_addressUpdateBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function () {
					MNA_addressDescForm.getForm().reset();

					// 생성, 수정 구분
					Ext.getCmp('MNA_addressOperType').setValue('update');

					// 선택한 네트워크 주소의 정보
					var selection = MNA_addressGrid.getSelectionModel().getSelection();
					var selected  = selection[0];

					// 수정 예외 처리
					if (isInternalAddr(selected))
					{
						Ext.MessageBox.alert(
							lang_mna_address[0],
							lang_mna_address[43]
						);
						return false;
					}

					// 장치 이름
					Ext.getCmp('MNA_addressDevice').setValue(selected.get('Device'));
					Ext.getCmp('MNA_addressDevice').setDisabled(true);

					// 활성화
					//Ext.getCmp('MNA_addressActive').setValue(selected.get('Active') == true);

					// 활성화 변경 유무
					//Ext.getCmp('MNA_addressActive').setDisabled(false);

					// 관리 IP일 경우 활성화 체크박스 비활성화
					//if (selected.get('Mgmt_IP') == true)
					//{
					//	Ext.getCmp('MNA_addressActive').setDisabled(true);
					//}

					// IP 주소
					var ipaddr = selected.get('IPAddr').split(/\./);

					Ext.getCmp('MNA_addressIpaddr1').setValue(ipaddr[0]);
					Ext.getCmp('MNA_addressIpaddr2').setValue(ipaddr[1]);
					Ext.getCmp('MNA_addressIpaddr3').setValue(ipaddr[2]);
					Ext.getCmp('MNA_addressIpaddr4').setValue(ipaddr[3]);

					// 로드한 주소 저장
					Ext.getCmp('MNA_addressIpaddr').setValue(ipaddr.join('.'));

					// IP 주소 변경 제한
					//var restricted = selected.Restrict == true;

					//Ext.getCmp('MNA_addressIpaddr1').setDisabled(restricted);
					//Ext.getCmp('MNA_addressIpaddr2').setDisabled(restricted);
					//Ext.getCmp('MNA_addressIpaddr3').setDisabled(restricted);
					//Ext.getCmp('MNA_addressIpaddr4').setDisabled(restricted);

					// 넷마스크 주소
					var netmask = selected.get('Netmask').split(/\./);

					Ext.getCmp('MNA_addressNetmask1').setValue(netmask[0]);
					Ext.getCmp('MNA_addressNetmask2').setValue(netmask[1]);
					Ext.getCmp('MNA_addressNetmask3').setValue(netmask[2]);
					Ext.getCmp('MNA_addressNetmask4').setValue(netmask[3]);

					// 게이트웨이
					// Gateway 객체를 null값으로 읽어들임
					// 따라서Gateway 처리를 위한 방법이 정해지면 다시 설정을 시작하는 걸로 수정 예정
					// #8140 create by Hyunho Jung (2021-02-03)
//					if (selected.get('Gateway') != null)
//					{
//						var gateway = selected.get('Gateway').split(/\./);
//
//						Ext.getCmp('MNA_addressGateway1').setValue(gateway[0]);
//						Ext.getCmp('MNA_addressGateway2').setValue(gateway[1]);
//						Ext.getCmp('MNA_addressGateway3').setValue(gateway[2]);
//						Ext.getCmp('MNA_addressGateway4').setValue(gateway[3]);
//					}

					// 네트워크 정보 수정 WINDOW OPEN
					MNA_addressDescWindow.show();
				}
			},
			{
				text: lang_mna_address[14],
				id: 'MNA_addressDeleteBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					var addr = MNA_addressGrid.getSelectionModel().getSelection()[0];

					// 삭제 예외 처리
					if (isInternalAddr(addr) || addr.get('Mgmt_IP'))
					{
						Ext.MessageBox.alert(
							lang_mna_address[0],
							addr.get('Mgmt_IP') ? lang_mna_address[44] : lang_mna_address[31]
						);
						return false;
					}

					Ext.MessageBox.confirm(
						lang_mna_address[0],
						lang_mna_address[15],
						function (btn, text) {
							if (btn != 'yes')
								return;

							waitWindow(lang_mna_address[0], lang_mna_address[16]);

							GMS.Cors.request({
								url: '/api/network/address/remove',
								method: 'POST',
								jsonData: {
									Device: addr.get('Device'),
									IPAddr: addr.get('IPAddr'),
									Netmask: addr.get('Netmask'),
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;
									Ext.MessageBox.alert(lang_mna_address[0], lang_mna_address[17]);
									loadNetworkInfo();
								}
							});
						}
					);
				}
			}
		]
	}
);

/****************************************************************************
 * Forms
 ****************************************************************************/
// 네트워크 정보 상세 폼
var MNA_addressDescForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MNA_addressDescForm',
		frame: false,
		fieldDefaults: {
			labelWidth: 145
		},
		bodyStyle: 'padding: 25px 30px 0px 30px;', // #7281-54 create by thkim
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				border: false,
				style: { marginBottom: '30px' },
				html: lang_mna_address[20]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				id: 'MNA_addressDevicePanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mna_address[21]+': ',
						width: 150,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'BaseComboBox',
						store: MNA_addressDeviceStore,
						id: 'MNA_addressDevice',
						name: 'addressDevice',
						valueField: 'Device',
						displayField: 'Device'
					}
				]
			},
//			{
//				xtype: 'BasePanel',
//				bodyStyle: 'padding: 0;',
//				layout: 'hbox',
//				id: 'MNA_addressActivePanel',
//				maskOnDisable: false,
//				style: { marginBottom: '20px' },
//				items: [
//					{
//						xtype: 'label',
//						text: lang_mna_address[22]+': ',
//						width: 150,
//						disabledCls: 'm-label-disable-mask'
//					},
//					{
//						xtype: 'checkbox',
//						id: 'MNA_addressActive',
//						name: 'addressActive',
//						inputValue: true,
//						allowBlank: false
//					},
//				]
//			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				id: 'MNA_addressIpaddrPanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MNA_addressIpaddrLabel',
						text: lang_mna_address[23]+': ',
						width: 150,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressIpaddr1',
						name: 'networkIpaddr1',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MNA_addressIpaddr1').setValue(Ext.getCmp('MNA_addressIpaddr1').getValue().replace(".", ""));
									Ext.getCmp('MNA_addressIpaddr2').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: {
							marginTop: '10px',
							marginRight: '5px'
						}
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressIpaddr2',
						name: 'networkIpaddr2',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MNA_addressIpaddr2').setValue(Ext.getCmp('MNA_addressIpaddr2').getValue().replace(".", ""));
									Ext.getCmp('MNA_addressIpaddr3').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: {
							marginTop: '10px',
							marginRight: '5px'
						}
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressIpaddr3',
						name: 'networkIpaddr3',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MNA_addressIpaddr3').setValue(Ext.getCmp('MNA_addressIpaddr3').getValue().replace(".", ""));
									Ext.getCmp('MNA_addressIpaddr4').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: {
							marginTop: '10px',
							marginRight: '5px'
						}
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressIpaddr4',
						name: 'networkIpaddr4',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' }
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressIpaddr',
						hidden: true
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MNA_addressNetmaskPanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mna_address[5]+': ',
						id: 'MNA_addressNetmaskLabel',
						width: 150,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressNetmask1',
						name: 'networkNetmask1',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 2, 'MNA_addressNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MNA_addressNetmask1').setValue(Ext.getCmp('MNA_addressNetmask1').getValue().replace(".", ""));
									Ext.getCmp('MNA_addressNetmask2').focus();
								}
							},
							blur: function () {
								MNA_addressDescNetmask();
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: {
							marginTop: '10px',
							marginRight: '5px'
						}
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressNetmask2',
						name: 'networkNetmask2',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 3, 'MNA_addressNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MNA_addressNetmask2').setValue(Ext.getCmp('MNA_addressNetmask2').getValue().replace(".", ""));
									Ext.getCmp('MNA_addressNetmask3').focus();
								}
							},
							blur: function () {
								MNA_addressDescNetmask();
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: {
							marginTop: '10px',
							marginRight: '5px'
						}
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressNetmask3',
						name: 'networkNetmask3',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 4, 'MNA_addressNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MNA_addressNetmask3').setValue(Ext.getCmp('MNA_addressNetmask3').getValue().replace(".", ""));
									Ext.getCmp('MNA_addressNetmask4').focus();
								}
							},
							blur: function () {
								MNA_addressDescNetmask();
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: {
							marginTop: '10px',
							marginRight: '5px'
						}
					},
					{
						xtype: 'textfield',
						id: 'MNA_addressNetmask4',
						name: 'networkNetmask4',
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (Ext.getCmp('MNA_addressNetmask3').getValue() == '')
								{
									Ext.getCmp('MNA_addressNetmask4').setValue();
									Ext.getCmp('MNA_addressNetmask3').focus();
								}
							},
							blur: function () {
								MNA_addressDescNetmask();
							}
						}
					}
				]
			},
// TODO: #7281-54
// etcd v3에서 빈 값('')에 대한 처리 방법이 정해지면 그때 Gateway 설정을 다시 시작함. modified by thkim
// Gateway 값은 받지만, 실제로 아무 작업을 하지 않는다.
//
//			{
//				xtype: 'BasePanel',
//				bodyStyle: 'padding: 0;',
//				layout: 'hbox',
//				id: 'MNA_addressGatewayPanel',
//				maskOnDisable: false,
//				items: [
//					{
//						xtype: 'label',
//						text: lang_mna_address[6]+': ',
//						width: 150,
//						disabledCls: 'm-label-disable-mask'
//					},
//					{
//						xtype: 'textfield',
//						id: 'MNA_addressGateway1',
//						name: 'networkGateway1',
//						enableKeyEvents: true,
//						vtype: 'reg_IP',
//						msgTarget: 'side',
//						hideLabel: true,
//						width: 55,
//						style: {marginRight: '5px'},
//						listeners : {
//							keyup: function (form, e) {
//								if (e.getKey() == 190 || e.getKey() == 110)
//								{
//									Ext.getCmp('MNA_addressGateway1').setValue(Ext.getCmp('MNA_addressGateway1').getValue().replace(".", ""));
//									Ext.getCmp('MNA_addressGateway2').focus();
//								}
//							}
//						}
//					},
//					{
//						xtype: 'label',
//						text: ' . ',
//						style: {
//							marginTop: '10px',
//							marginRight: '5px'
//						}
//					},
//					{
//						xtype: 'textfield',
//						id: 'MNA_addressGateway2',
//						name: 'networkGateway2',
//						enableKeyEvents: true,
//						vtype: 'reg_IP',
//						msgTarget: 'side',
//						hideLabel: true,
//						width: 55,
//						style: { marginRight: '5px' },
//						listeners : {
//							keyup: function (form, e) {
//								if (e.getKey() == 190 || e.getKey() == 110)
//								{
//									Ext.getCmp('MNA_addressGateway2').setValue(Ext.getCmp('MNA_addressGateway2').getValue().replace(".", ""));
//									Ext.getCmp('MNA_addressGateway3').focus();
//								}
//							}
//						}
//					},
//					{
//						xtype: 'label',
//						text: ' . ',
//						style: {
//							marginTop: '10px',
//							marginRight: '5px'
//						}
//					},
//					{
//						xtype: 'textfield',
//						id: 'MNA_addressGateway3',
//						name: 'networkGateway3',
//						enableKeyEvents: true,
//						vtype: 'reg_IP',
//						msgTarget: 'side',
//						hideLabel: true,
//						width: 55,
//						style: { marginRight: '5px' },
//						listeners : {
//							keyup: function (form, e) {
//								if (e.getKey() == 190 || e.getKey() == 110)
//								{
//									Ext.getCmp('MNA_addressGateway3').setValue(Ext.getCmp('MNA_addressGateway3').getValue().replace(".", ""));
//									Ext.getCmp('MNA_addressGateway4').focus();
//								}
//							}
//						}
//					},
//					{
//						xtype: 'label',
//						text: ' . ',
//						style: {
//							marginTop: '10px',
//							marginRight: '5px'
//						}
//					},
//					{
//						xtype: 'textfield',
//						id: 'MNA_addressGateway4',
//						name: 'networkGateway4',
//						enableKeyEvents: true,
//						vtype: 'reg_IP',
//						msgTarget: 'side',
//						hideLabel: true,
//						width: 55,
//						style: { marginRight: '5px' }
//					}
//				]
//			},
			{
				id: 'MNA_addressOperType',
				name: 'addressSaveType',
				hidden : true
			}
		]
	}
);

/****************************************************************************
 * Panels
 ****************************************************************************/
// 본딩 설정 폼
var MNB_bondConfigPanel = Ext.create(
	'BasePanel',
	{
		id: 'MNB_bondConfigPanel',
		bodyStyle: 'padding:0;',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'image',
				src: '/admin/images/bg_wizard.jpg',
				height: 520,
				width: 150
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						id: 'MNB_bondConfigTitle',
						html: lang_mnb_bond[57]
					},
					{
						xtype: 'BaseWizardContentPanel',
						height: 330,
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>'+lang_mnb_bond[3]+'(1/2)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>'+lang_mnb_bond[4]+'(2/2)</li>'
							}
						]
					},
					{
						xtype: 'BaseWizardDescPanel',
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: lang_mnb_bond[1]
							},
							{
								border: false,
								html: lang_mnb_bond[2]
							}
						]
					}
				]
			}
		]
	}
);

// 본딩 모드 설정
var MNB_bondConfigModePanel = Ext.create(
	'BasePanel',
	{
		id: 'MNB_bondConfigModePanel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mnb_bond[3]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mnb_bond[4]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 2,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mnb_bond[5]
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align : 'stretch'
						},
						flex: 1,
						items: [
							{
								xtype: 'radiofield',
								checked: true,
								boxLabel: 'Round-Robin(0)',
								id: 'MNB_bondConfigModeRoundRobin',
								name: 'bondConfigModeRadio',
								inputValue: '0'
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								style: { marginBottom: '20px' },
								html: lang_mnb_bond[42]
							},
							{
								xtype: 'radiofield',
								checked: false,
								boxLabel: 'Active Backup(1)',
								id: 'MNB_bondConfigModeActiveBackup',
								name: 'bondConfigModeRadio',
								inputValue: '1'
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								style: { marginBottom: '20px' },
								html: lang_mnb_bond[43]
							},
							{
								xtype: 'radiofield',
								checked: false,
								boxLabel: 'Balance-XOR(2)',
								id: 'MNB_bondConfigModeBalanceXOR',
								name: 'bondConfigModeRadio',
								inputValue: '2'
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								style: { marginBottom: '20px' },
								html: lang_mnb_bond[44]
							},
							{
								xtype: 'radiofield',
								checked: false,
								boxLabel: 'IEEE 802.3ad(4)',
								id: 'MNB_bondConfigModeLACP',
								name: 'bondConfigModeRadio',
								inputValue: '4'
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								style: { marginBottom: '20px' },
								html: lang_mnb_bond[45]
							},
							{
								xtype: 'radiofield',
								checked: false,
								boxLabel: 'Balance-TLB(5)',
								id: 'MNB_bondConfigModeBalanceTLB',
								name: 'bondConfigModeRadio',
								inputValue: '5'
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								style: { marginBottom: '20px' },
								html: lang_mnb_bond[46]
							},
							{
								xtype: 'radiofield',
								checked: false,
								boxLabel: 'Balance-ALB(6)',
								id: 'MNB_bondConfigModeBalanceALB',
								name: 'bondConfigModeRadio',
								inputValue: '6'
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								html: lang_mnb_bond[47]
							}
						]
					}
				]
			}
		]
	}
);

// 본딩 모드 설정
var MNB_bondConfigSlaveListPanel = Ext.create(
	'BasePanel',
	{
		id: 'MNB_bondConfigSlaveListPanel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'BaseWizardSidePanel',
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mnb_bond[3]
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mnb_bond[4]
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
						html: lang_mnb_bond[13]
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align : 'stretch'
						},
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0;',
								layout: 'hbox',
								style: { marginBottom: '20px' },
								maskOnDisable: false,
								items: [
									{
										xtype: 'checkbox',
										boxLabel: lang_mnb_bond[14],
										id: 'MNB_bondConfigOnBoot',
										name: 'bondConfigOnBoot'
									},
								]
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding:0;',
								style: { marginBottom: '20px' },
								items: [
									{
										xtype: 'BaseComboBox',
										store: MNB_bondConfigSlavePrimaryStore,
										id: 'MNB_bondConfigSlavePrimaryDevice',
										name: 'bondConfigSlavePrimaryDevice',
										fieldLabel: 'Primary Slave',
										labelWidth: 130,
										valueField: 'DeviceName',
										displayField: 'DeviceView'
									}
								]
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding:0;',
								items: [MNB_bondConfigSlaveGrid]
							},
							{
								xtype: 'textfield',
								id: 'MNB_bondConfigType',
								value: 'create',
								hidden: true
							},
							{
								xtype: 'textfield',
								id: 'MNB_bondConfigBondName',
								hidden: true
							},
							{
								xtype: 'label',
								style: 'marginBottom: 20px; marginTop: 10px',
								html: lang_mnb_bond[63]
							}
						]
					}
				]
			}
		]
	}
);


/****************************************************************************
 * Windows
 ****************************************************************************/
/** 물리 네트워크 장치 정보수정 폼 WIN **/
var MND_deviceModifyWin = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MND_deviceModifyWin',
		layout: 'fit',
		maximizable: false,
		width: 500,
		autoHeight: true,
		title: lang_mnd_device[1],
		items: [
			{
				xtype: 'BaseFormPanel',
				id: 'MND_deviceModifyForm',
				frame: false,
				border: false,
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '30px' },
						html: lang_mnd_device[2]
					},
					{
						xtype: 'BasePanel',
						layout: 'hbox',
						bodyStyle: 'padding: 0;',
						maskOnDisable: false,
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'label',
								text: lang_mnd_device[3]+': ',
								width: 135
							},
							{
								xtype: 'label',
								id: 'MND_deviceModifyNameLabel'
							}
						]
					},
					{
						id: 'MND_deviceModifyName',
						name: 'deviceModifyName',
						hidden : true
					},
					{
						xtype: 'BasePanel',
						layout: 'hbox',
						bodyStyle: 'padding: 0;',
						maskOnDisable: false,
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'label',
								text: lang_mnd_device[4]+': ',
								width: 135,
								style: { marginTop: '5px' }
							},
							{
								xtype: 'checkbox',
								id: 'MND_deviceModifyOnBoot',
								name: 'deviceModifyOnBoot',
								allowBlank: false,
								inputValue: true
							},
						]
					},
					{
						fieldLabel: 'MTU',
						id: 'MND_deviceModifyMTU',
						name: 'deviceModifyMTU',
						allowBlank: false,
						vtype: 'reg_Number'
					}
				]
			}
		],
		buttons: [
			{
				text: lang_mnd_device[8],
				id: 'MND_deviceModifyFormSaveBtn',
				handler: function () {
					if (!Ext.getCmp('MND_deviceModifyForm').getForm().isValid())
						return false;

					var device = MND_deviceGrid.selModel.selected.items[0];
					var type   = getDeviceType(device);

					if (type == null)
					{
						console.error('Unknown device type:', device);
						return;
					}

					var slaves = [];

					MND_deviceGridStore.each(
						function (record, idx)
						{
							if (record.get('Master') == device.get('Device'))
							{
								slaves.push(record.get('Device'));
							}
						}
					);

					if (slaves.length)
					{
						Ext.MessageBox.alert(
							lang_mnd_device[0],
							lang_mnd_device[30] + ': ' + slaves.join(', ')
						);

						return;
					}

					waitWindow(lang_mnd_device[0], lang_mnd_device[35]);

					GMS.Cors.request({
						url: '/api/network/' + type + '/update',
						method: 'POST',
						jsonData: {
							Device: device.get('Device'),
							MTU: Ext.getCmp('MND_deviceModifyMTU').getValue(),
							OnBoot: Ext.getCmp('MND_deviceModifyOnBoot').getValue() ? 'yes' : 'no',
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							var msg = decoded.msg || lang_mnd_device[9];

							Ext.MessageBox.alert(lang_mnd_device[0], msg);

							// 데이터 갱신
							loadNetworkInfo();

							// 팝업창 닫기
							MND_deviceModifyWin.hide();
						}
					});
				}
			}
		]
	}
);

/** 물리적 네트워크 장치 상세 정보 WIN **/
var MND_deviceDetailWin = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MND_deviceDetailWin',
		title: lang_mnd_device[31],
		maximizable: false,
		autoHeight: true,
		width: 800,
		bodyStyle: 'padding: 15px !important',
		items: [
			MND_deviceDetailGeneralGrid,
			MND_deviceDetailAddrGrid,
			MND_deviceDetailRxGrid,
			MND_deviceDetailTxGrid
		]
	}
);

// 본딩 설정 윈도
var MNB_bondConfigWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNB_bondConfigWindow',
		layout: 'card',
		title: lang_mnb_bond[12],
		maximizable: false,
		width: 770,
		height: 580,
		autoScroll: false,
		activeItem: 0,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MNB_bondConfigForm',
				autoScroll: false,
				items: [ MNB_bondConfigPanel ]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MNB_bondConfigMode',
				autoScroll: false,
				items: [ MNB_bondConfigModePanel ]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MNB_bondConfigSlaveList',
				autoScroll: false,
				items: [ MNB_bondConfigSlaveListPanel ]
			}
		],
		fbar: [
			{
				text: lang_mnb_bond[56],
				id: 'MNB_bondConfigWindowCancleBtn',
				width: 70,
				disabled: false,
				handler: function () {
					MNB_bondConfigWindow.close();
				}
			},
			'->',
			{
				text: lang_mnb_bond[15],
				id: 'MNB_bondConfigWindowPreBtn',
				width: 70,
				disabled: true,
				handler: function () {
					var currentStepPanel = MNB_bondConfigWindow.layout.activeItem;
					var currentStepIndex = MNB_bondConfigWindow.items.indexOf(currentStepPanel);

					MNB_bondConfigWindow.layout.setActiveItem(--currentStepIndex);

					if (currentStepIndex == 0)
					{
						Ext.getCmp('MNB_bondConfigWindowPreBtn').hide();
						Ext.getCmp('MNB_bondConfigWindowPreBtn').disable();
					}
					else
					{
						// 다음 버튼
						Ext.getCmp('MNB_bondConfigWindowNextBtn').show();
						Ext.getCmp('MNB_bondConfigWindowNextBtn').enable();

						// 확인 버튼
						Ext.getCmp('MNB_bondConfigWindowSetBtn').hide();
						Ext.getCmp('MNB_bondConfigWindowSetBtn').disable();
					}
				}
			},
			{
				text: lang_mnb_bond[16],
				id: 'MNB_bondConfigWindowNextBtn',
				width: 70,
				handler: function () {
					var currentStepPanel = MNB_bondConfigWindow.layout.activeItem;
					var currentStepIndex = MNB_bondConfigWindow.items.indexOf(currentStepPanel);

					MNB_bondConfigWindow.layout.setActiveItem(++currentStepIndex);

					// 버튼 컨트롤
					Ext.getCmp('MNB_bondConfigWindowPreBtn').show();
					Ext.getCmp('MNB_bondConfigWindowPreBtn').enable();

					if (MNB_bondConfigWindow.layout.getActiveItem().id
						== 'MNB_bondConfigSlaveList')
					{
						// 다음 버튼
						Ext.getCmp('MNB_bondConfigWindowNextBtn').hide();
						Ext.getCmp('MNB_bondConfigWindowNextBtn').disable();

						// 확인 버튼
						Ext.getCmp('MNB_bondConfigWindowSetBtn').show();
						Ext.getCmp('MNB_bondConfigWindowSetBtn').enable();

						// 기본적으로 primary device 선택 활성화
						Ext.getCmp('MNB_bondConfigSlavePrimaryDevice').setDisabled(false);

						// 모드가 Active/Backup이 아닐 때, primary 선택 비활성화
						if (Ext.getCmp('MNB_bondConfigModeActiveBackup').getValue() == false)
						{
							Ext.getCmp('MNB_bondConfigSlavePrimaryDevice').setDisabled(true);
							Ext.getCmp('MNB_bondConfigSlavePrimaryDevice').setValue(lang_mnb_bond[23]);
						}

						loadSelectedSlaves();
						if (MNB_bondConfigSlaveGridListeners == null)
						{
							MNB_bondConfigSlaveGridListeners = MNB_bondConfigSlaveGrid.on({
								destroyable : true,
								select      : loadSelectedSlaves,
								selectall   : loadSelectedSlaves,
								deselect    : loadSelectedSlaves,
								deselectall : loadSelectedSlaves
							});
						}
					}
					else
					{
						// 다음 버튼
						Ext.getCmp('MNB_bondConfigWindowNextBtn').show();
						Ext.getCmp('MNB_bondConfigWindowNextBtn').enable();

						// 확인 버튼
						Ext.getCmp('MNB_bondConfigWindowSetBtn').hide();
						Ext.getCmp('MNB_bondConfigWindowSetBtn').disable();
					}
				}
			},
			{
				text: lang_mnb_bond[17],
				id: 'MNB_bondConfigWindowSetBtn',
				width: 70,
				disabled: true,
				handler: function () {
					var url;
					var oper   = Ext.getCmp('MNB_bondConfigType').getValue();
					var params = {
						Device: null,
						Mode: null,
						Primary: null,
						Slaves: [],
						OnBoot: null,
					};

					if (oper == 'create')
					{
						url = '/api/network/bonding/create';
					}
					else
					{
						url = '/api/network/bonding/update';
					}

					var slaves = MNB_bondConfigSlaveGrid.getSelectionModel().getSelection();

					for (var i=0, len=slaves.length; i<len; i++)
					{
						params.Slaves.push(slaves[i].get('Device'));
					}

					// 본딩을 구성하는 네트워크 장치가 없을 경우 예외 처리
					if (params.Slaves.length == 0)
					{
						Ext.MessageBox.alert(lang_mnb_bond[0], lang_mnb_bond[18]);
						return false;
					}

					if (oper == 'create')
					{
						waitWindow(lang_mnb_bond[0], lang_mnb_bond[48]);
						delete(params.Device);
					}
					else
					{
						waitWindow(lang_mnb_bond[0], lang_mnb_bond[49]);
						params.Device = MNB_bondGrid.selModel.selected.items[0].data.Device;
					}

					// 모드
					if (Ext.getCmp('MNB_bondConfigModeRoundRobin').getValue())
						params.Mode = 0;
					else if (Ext.getCmp('MNB_bondConfigModeActiveBackup').getValue())
						params.Mode = 1;
					else if (Ext.getCmp('MNB_bondConfigModeBalanceXOR').getValue())
						params.Mode = 2;
					else if (Ext.getCmp('MNB_bondConfigModeLACP').getValue())
						params.Mode = 4;
					else if (Ext.getCmp('MNB_bondConfigModeBalanceTLB').getValue())
						params.Mode = 5;
					else if (Ext.getCmp('MNB_bondConfigModeBalanceALB').getValue())
						params.Mode = 6;

					var primary = Ext.getCmp('MNB_bondConfigSlavePrimaryDevice').getValue();

					if (primary == lang_mnb_bond[23]
						|| typeof(primary) == 'undefined'
						|| primary == '')
					{
						params.Primary = '';
					}
					else
					{
						params.Primary = primary;
					}

					params.OnBoot = Ext.getCmp('MNB_bondConfigOnBoot').getValue() ? 'yes' : 'no';

					GMS.Cors.request({
						url: url,
						method: 'POST',
						jsonData: params,
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							if (Ext.getCmp('MNB_bondConfigType').getValue() == 'create')
							{
								Ext.MessageBox.alert(lang_mnb_bond[0], lang_mnb_bond[19]);
							}
							else
							{
								Ext.MessageBox.alert(lang_mnb_bond[0], lang_mnb_bond[20]);
							}

							loadNetworkInfo();
						}
					});

					// 전송 완료 후 창닫기
					MNB_bondConfigWindow.hide();
				}
			}
		]
	}
);

// Detailed bonding info window
var MNB_bondSlavesDetailWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNB_bondSlavesDetailWindow',
		layout: 'fit',
		title: lang_mnb_bond[22],
		maximizable: false,
		autoHeight: true,
		width: 520,
		height: 350,
		activeItem: 0,
		items: [ MNB_bondSlavesDetailGrid ]
	}
);

// VLAN management window
var vlanWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'vlanWindow',
		layout: 'fit',
		width: 500,
		autoHeight: true,
		maximizable: false,
		title: 'VLAN Management',
		items: [
			{
				xtype: 'BaseFormPanel',
				id: 'vlanForm',
				frame: false,
				border: false,
				items: [
					{
						xtype: 'BasePanel',
						style: { marginBottom: '30px' },
						bodyStyle: { padding: 0 },
						html: 'Please input below fields to add new VLAN',
					},
					{
						xtype: 'combo',
						fieldLabel: lang_mnd_device[0],
						id: 'vlanDevice',
						name: 'vlanDevice',
						style: { marginBottom: '20px' },
						store: MND_deviceGridStore,
						displayField: 'Device',
						valueField: 'Device',
					},
					{
						xtype: 'textfield',
						fieldLabel: lang_mnv_vlan[0] + ' ' + lang_common[36],
						id: 'vlanTag',
						name: 'vlanTag',
						vtype: 'reg_vlanID',
						style: { marginBottom: '20px' },
					},
					{
						xtype: 'checkbox',
						fieldLabel: lang_mnd_device[4],
						id: 'vlanOnBoot',
						name: 'vlanOnBoot',
						style: { marginBottom: '20px' },
					},
					{
						xtype: 'textfield',
						fieldLabel: 'MTU',
						id: 'vlanMTU',
						name: 'vlanMTU',
						vtype: 'reg_Number',
						allowBlank: false,
						style: { marginBottom: '20px' },
						value: 1500,
					},
				],
			},
		],
		buttons: [
			{
				text: lang_common[3],
				handler: function () {
					var form = Ext.getCmp('vlanForm');

					if (!form.getForm().isValid())
					{
						console.error('VLAN form is invalid');
						return false;
					}

					var device = Ext.getCmp('vlanDevice').getValue()
								+ '.'
								+ Ext.getCmp('vlanTag').getValue();

					waitWindow(lang_mnv_vlan[1], lang_mnv_vlan[2]);

					GMS.Cors.request({
						url: '/api/network/vlan/create',
						method: 'POST',
						jsonData: {
							Device: device,
							OnBoot: Ext.getCmp('vlanOnBoot').getValue() ? 'yes' : 'no',
							MTU: Ext.getCmp('vlanMTU').getValue(),
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							Ext.MessageBox.alert(lang_mnv_vlan[1], decoded.msg);

							Ext.getCmp('vlanWindow').close();

							loadNetworkInfo();
						}
					});
				},
			},
		],
		listeners: {
			show: function () {
				var combo = Ext.getCmp('vlanDevice');

				combo.select(combo.getStore().getAt(0));
			},
			hide: function (me, eOpts) {
				// TODO: if some fields changed, ESC key won't work as
				// expected
				Ext.getCmp('vlanForm').getForm().reset();
			},
		}
	},
);

// Detailed network info window
var MNA_addressDescWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNA_addressDescWindow',
		layout: 'fit',
		title: lang_mna_address[29],
		maximizable: false,
		width: 600,
		height: 270, // #7281-54 modify by thkim, default : 370
		items: [ MNA_addressDescForm ],
		buttons: [
			{
				text: lang_mna_address[24],
				id: 'MNA_addressSaveBtn',
				handler: function () {
					if (!Ext.getCmp('MNA_addressDescForm').getForm().isValid())
					{
						console.error('Network address form is invalid');
						return false;
					}

					var device  = Ext.getCmp('MNA_addressDevice').getValue();
					//var active  = Ext.getCmp('MNA_addressActive').getValue();
					var oper    = Ext.getCmp('MNA_addressOperType').getValue();
					var ipaddr  = null;
					var netmask = null;
					var gateway = null;

					// 생성, 수정할 아이피
					ipaddr = Ext.getCmp('MNA_addressIpaddr1').getValue()
							+ "."
							+ Ext.getCmp('MNA_addressIpaddr2').getValue()
							+ "."
							+ Ext.getCmp('MNA_addressIpaddr3').getValue()
							+ "."
							+ Ext.getCmp('MNA_addressIpaddr4').getValue();

					// 생성, 수정할 넷마스크
					netmask = Ext.getCmp('MNA_addressNetmask1').getValue()
							+ "."
							+ Ext.getCmp('MNA_addressNetmask2').getValue()
							+ "."
							+ Ext.getCmp('MNA_addressNetmask3').getValue()
							+ "."
							+ Ext.getCmp('MNA_addressNetmask4').getValue();

					/*
					// TODO : #7281-54 modify by thkim
					// 생성, 수정할 게이트웨이
					for (var i=1; i<=4; i++)
					{
						var field = Ext.getCmp('MNA_addressGateway' + i).getValue();

						if (typeof(field) == 'undefined' || field == null || field == '')
						{
							gateway = null;
							break;
						}

						if (gateway == null)
							gateway = field;
						else
							gateway = gateway + '.' + field;
					}
					*/

					var duplicated = false;

					var reqSet = {
						oper : oper,
						device : device,
						ipaddr,
						netmask,
						gateway};

					// 네트워크 주소 중복 확인
					MNA_addressGridStore.each(
						function (record) {
							if (record.get('IPAddr') == ipaddr
									&& record.get('Netmask') == netmask)
                                    //#8139 modify by KSE 21.02.03
									//&& record.get('Gateway') == gateway)
							{
								duplicated = true;
								return false;
							}
						}
					);

					// 중복 확인시, 메세지 박스 띄우고 종료
					if (duplicated == true)
					{
						Ext.MessageBox.alert(lang_mna_address[0], lang_mna_address[38]);
						return false;
					}

					var addrs    = [];
					var netmasks = [];
					var gateways = [];

					// API 서버에 전송할 request set 작성
					switch (oper)
					{
						case 'add':
							reqSet.ipaddr = ipaddr;
							reqSet.netmask = netmask;
							reqSet.gateway = gateway;
							break;
						case 'update':
							MNA_addressGridStore.each(
								function (record) {
									if (record.get('Device') == device)
									{
										var addr = MNA_addressGrid.getSelectionModel().getSelection()[0];
										if (record.get('IPAddr') == addr.get('IPAddr'))
										{
											//old ip
											addrs.push(addr.get('IPAddr'));
											netmasks.push(addr.get('Netmask'));
											gateways.push(addr.get('Gateway'));
											//new ip
											addrs.push(ipaddr);
											netmasks.push(netmask);
											gateways.push(gateway);
										}
//										else
//										{
//											addrs.push(record.get('IPAddr'));
//											netmasks.push(record.get('Netmask'));
//											gateways.push(record.get('Gateway'));
//										}
									}
								}
							);
							reqSet.ipaddr  = addrs;
							reqSet.netmask = netmasks;
							reqSet.gateway = gateways;
							break;
					}

					requestAddrSet(reqSet);
				}
			}
		]
	}
);

/****************************************************************************
 * Functions
 ****************************************************************************/
function isSlaveDevice(model)
{
	MND_deviceGridStore.each(
		function (record, idx)
		{
		}
	);
}

// 물리적 네트워크 목록 선택 시 버튼 컨트롤
function deviceSelectListener(record)
{
	var selection = MND_deviceGrid.getSelectionModel().getSelection();

	if (selection.length > 1)
	{
		Ext.getCmp('MND_deviceModifyBtn').setDisabled(true);
		Ext.getCmp('MND_deviceDetailBtn').setDisabled(true);
	}
	else if (selection.length == 1)
	{
		Ext.getCmp('MND_deviceModifyBtn').setDisabled(false);
		Ext.getCmp('MND_deviceDetailBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MND_deviceModifyBtn').setDisabled(true);
		Ext.getCmp('MND_deviceDetailBtn').setDisabled(true);
	}

	/*
	if (selection.length > 0)
	{
		var device = selection[0];

		if (device.get('Device').match(/^(bond|vlan)/)
			&& !device.get('Device').match(/^bond[0-1]$/)
			&& device.get('Mgmt_IP') != true)
		{
			Ext.getCmp('MND_deviceDeleteBtn').setDisabled(false);
		}
		else
		{
			Ext.getCmp('MND_deviceDeleteBtn').setDisabled(true);
		}
	}
	*/
};

/*
 * 본딩
 */
function bondSelectListener()
{
	var selectCount = MNB_bondGrid.getSelectionModel().getCount();

	if (selectCount > 1)
	{
		Ext.getCmp('MNB_bondDetailBtn').setDisabled(true);
		Ext.getCmp('MNB_bondModifyBtn').setDisabled(true);
		Ext.getCmp('MNB_bondDeleteBtn').setDisabled(false);
	}
	else if (selectCount == 1)
	{
		Ext.getCmp('MNB_bondDetailBtn').setDisabled(false);
		Ext.getCmp('MNB_bondModifyBtn').setDisabled(false);
		Ext.getCmp('MNB_bondDeleteBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MNB_bondDetailBtn').setDisabled(true);
		Ext.getCmp('MNB_bondModifyBtn').setDisabled(true);
		Ext.getCmp('MNB_bondDeleteBtn').setDisabled(true);
	}
};

function loadBondSlaves(devices)
{
	// Setting notifications for network bonding creation and modification
	var wait_msg = (!devices) ? lang_mnb_bond[54] : lang_mnb_bond[55];

	GMS.Cors.request({
		url: '/api/network/device/list',
		waitMsgBox: waitWindow(lang_mnb_bond[0], wait_msg),
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			var grid = Ext.getCmp('MNB_bondConfigSlaveGrid');

			// 본드 할당 가능한 장치 목록 로드
			grid.store.loadRawData(decoded, false);

			// 가용 네트워크 장치 목록에서 루프백 장치(lo) 제거
			grid.store.clearFilter();
			grid.store.filter(
				function (r) {
					return (r.get('Device') !== 'lo');
				}
			);

			// 생성 수정 시 Primary 장치 스토어 초기화
			MNB_bondConfigSlavePrimaryStore.removeAll();

			// 생성일 경우
			if (!devices)
			{
				var excludes = [];

				// Master가 이미 있거나 IP 주소가 할당된 대상은 제외
				grid.store.each(
					function (record) {
						if (record.get("Master") != null
							|| record.get("IPAddrs").length != 0)
						{
							excludes.push(record);
						}
					}
				);

				grid.store.remove(excludes);

				if (grid.store.getCount() == 0)
				{
					MNB_bondConfigWindow.hide();
					Ext.MessageBox.alert(lang_mnb_bond[0], lang_mnd_device[40]);
					return;
				}
			}
			// 수정일 경우
			else
			{
				// 본드로 사용된 장치 선택
				var bond     = MNB_bondGrid.getSelectionModel().getSelection()[0];
				var slaves   = [];
				var excludes = [];

				grid.store.each(
					function (record) {
						/*
						* 다음과 같은 경우 제거
						* - Master가 있거나 할당된 주소가 있음
						* - Master가 할당되어 있지만 선택한 본딩에 포함 안됨
						*/
						if (record.get('IPAddrs').length != 0
							|| (record.get('Master') != null
								&& record.get('Master') != bond.get('Device')))
						{
							excludes.push(record);
							return;
						}
						// 선택된 장치들을 본드 구성 장치 목록에 추가
						else if (record.get('Master') == bond.get('Device'))
						{
							slaves.push(record);
						}
					}
				);

				Ext.defer(
					function () {
						grid.store.remove(excludes);
						grid.getSelectionModel().select(slaves, true);
					},
					200
				);
				
				// Primary 장치 선택
				var primary = bond.get('Primary');

				Ext.getCmp('MNB_bondConfigSlavePrimaryDevice')
					.setValue(primary === 'None' ? lang_mnb_bond[23] : primary);

				// 선택되어있는 장치들을 checkbox 리스트에 넣어둠
				for (i=0; i<devices.length; i++)
				{
					if (primary == devices[i])
					{
						continue;
					}

					MNB_bondConfigSlavePrimaryStore.add([[devices[i], devices[i]]]);
				}
			}

			if (MNB_bondConfigSlaveGridListeners != null)
			{
				MNB_bondConfigSlaveGridListeners.destroy();
				MNB_bondConfigSlaveGridListeners = null;
			}
			MNB_bondConfigWindow.show();
		},
	});
};

/*
 * 네트워크 본딩 추가 및 수정에서 slave 장치 선택하는 list에서
 * slave를 선택(check)할 경우, Primary slave 목록(checkbox)에 뿌려주는 기능
 */
function loadSelectedSlaves()
{
	// primary 설정은 A/B에서만 사용되는 옵션, 그외 모드에서는 사용하지 않음
	if (Ext.getCmp('MNB_bondConfigModeActiveBackup').getValue() == false)
	{
		return;
	}

	MNB_bondConfigSlavePrimaryStore.removeAll()

	var slaves = MNB_bondConfigSlaveGrid.getSelectionModel().getSelection();
	var primary = Ext.getCmp('MNB_bondConfigSlavePrimaryDevice').getValue();
	var check_flag = false;

	//primary를 제거할 때 선택하는 checkbox 값
	if (0 < slaves.length)
	{
		MNB_bondConfigSlavePrimaryStore.add([['', lang_mnb_bond[64]]]);
	}

	//선택한 slave 들을 checkbox에 채우는 작업
	for (i=0; i<slaves.length; i++)
	{
		MNB_bondConfigSlavePrimaryStore.add([[slaves[i].get('Device'), slaves[i].get('Device')]]);

		// 현재 지정된 primary slave가 select 한 slave device에 포함되어 있으면 그대로 표기
		if (primary == slaves[i].get('Device'))
		{
			check_flag = true;
		}
	}

	// 지정된 primary slave가 select되어있지 않을 경우 '선택'으로 변경
	if (check_flag == false)
	{
		Ext.getCmp('MNB_bondConfigSlavePrimaryDevice').setValue(lang_mnb_bond[23]);
	}
}

/*
 * 네트워크 주소
 */

// 네트워크 정보 그리드 선택 시 수정 버튼 컨트롤
function MNA_addressSelect(record)
{
	// 선택한 네트워크 주소의 정보
	var selection = MNA_addressGrid.getSelectionModel().getSelection();

	if (selection.length > 1)
	{
		Ext.getCmp('MNA_addressUpdateBtn').setDisabled(true);
		Ext.getCmp('MNA_addressDeleteBtn').setDisabled(true);
	}
	else if (selection.length == 1)
	{
		Ext.getCmp('MNA_addressUpdateBtn').setDisabled(false);
		Ext.getCmp('MNA_addressDeleteBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MNA_addressUpdateBtn').setDisabled(true);
		Ext.getCmp('MNA_addressDeleteBtn').setDisabled(true);
	}

    // 기본 룰은 관리 인터페이스는 삭제하면 안됨
//	for (var i=0; i<selection.length; i++)
//	{
//		var address = selection[i];
//
//		if (address.get('Device').match(/^bond[0-1]$/))
//		{
//			// 스토리지/서비스 네트워크와 관리 네트워크가 공용일 때
//			//Ext.getCmp('MNA_addressUpdateBtn').setDisabled(true);
//			Ext.getCmp('MNA_addressDeleteBtn').setDisabled(address.get('Mgmt_IP'));
//		}
//		// 관리 인터페이스: 삭제 금지
//		else if (address.get('Mgmt_IP') == true)
//		{
//			Ext.getCmp('MNA_addressDeleteBtn').setDisabled(true);
//		}
//	}
};


// 넷마스크 컨트롤
function MNA_addressDescNetmask()
{
	if (Ext.getCmp('MNA_addressNetmask1').getValue() != '255'
		&& Ext.getCmp('MNA_addressNetmask1').getValue() != '')
	{
		Ext.getCmp('MNA_addressNetmask2').setValue(0);
		Ext.getCmp('MNA_addressNetmask3').setValue(0);
		Ext.getCmp('MNA_addressNetmask4').setValue(0);
	}
	else if (Ext.getCmp('MNA_addressNetmask2').getValue() != '255'
			&& Ext.getCmp('MNA_addressNetmask2').getValue() != '')
	{
		Ext.getCmp('MNA_addressNetmask3').setValue(0);
		Ext.getCmp('MNA_addressNetmask4').setValue(0);

	}
	else if (Ext.getCmp('MNA_addressNetmask3').getValue() != '255'
			&& Ext.getCmp('MNA_addressNetmask3').getValue() != '')
	{
		Ext.getCmp('MNA_addressNetmask4').setValue(0);
	}
};

// 웹서버 연결 함수 (IP 변경)
function MNA_addrestHostLocation(postAddr)
{
	var responseData = Ext.JSON.decode(postAddr);
	var protocol = responseData.protocol;
	var address = responseData.address;
	var page = responseData.page;
	var httpPort = responseData.httpPort;

	if (typeof(httpPort) == 'undefined' || httpPort == '')
		httpPort = '80';

	var httpsPort = responseData.httpsPort;
	var scriptTimestamp = Math.floor(new Date().getTime() / 1000);
	var imgObj = new Image();

	var src = "http://"+address+":"+httpPort+"/common/images/img_logo.png?t="+scriptTimestamp;

	var url;

	if (protocol == 'http')
		url = protocol+"://"+address+":"+httpPort;
	else if (protocol == 'https')
		url = protocol+"://"+address+":"+httpsPort;

	imgObj.src    = src;
	imgObj.onload = function () {
		// 데이터 전송 완료 후 wait 제거
		if (waitMsgBox)
		{
			waitMsgBox.hide();
			waitMsgBox = null;
		}

		// 선택한 네트워크 주소의 정보
		var selected = MNA_addressGrid.getSelectionModel().getSelection();

		// 관리 IP 체크
		var Mgmt_IP = selected[0].data.Mgmt_IP;

		// IP 주소
		var IPAddr = selected[0].data.IPAddr;

		// 관리 IP일 경우 비활성화
		if (document.location.host == IPAddr)
		{
			Ext.MessageBox.show({
				title: lang_mna_address[0],
				msg: lang_mna_address[27],
				// icon: Ext.MessageBox.WARNING,
				buttons: Ext.MessageBox.OK,
				fn: function (buttonId) {
					if (buttonId !== "ok")
						return;

					location.href = url;
				}
			});
		}
		else
		{
			MNA_addressDescWindow.hide();

			var nodeCombo = Ext.getCmp('content-main-node-combo');

			var nodeID = nodeCombo.rawValue;
			var nodeIP = Ext.getCmp('MNA_addressIpaddr1').getValue()
						+ '.'
						+ Ext.getCmp('MNA_addressIpaddr2').getValue()
						+ '.'
						+ Ext.getCmp('MNA_addressIpaddr3').getValue()
						+ '.'
						+ Ext.getCmp('MNA_addressIpaddr4').getValue();

			Ext.getCmp('content-main-node-combo').store.load({
				callback: function (record, operation, success) {
					if (success != true)
						return;

					// 노드 관리 메뉴의 Combo 출력
					Ext.MessageBox.show({
						title: lang_mna_address[0],
						msg: lang_mna_address[27],
						buttons: Ext.MessageBox.OK,
						fn: function (buttonId) {
							if (buttonId !== "ok")
								return;

							Ext.getCmp('content-main-node-combo').setValue(nodeIP);
						}
					});
				}
			});
		}
	};

	imgObj.onerror = function () {
		setTimeout(function () { MNA_addrestHostLocation(postAddr); }, 5000);
	};
};

// 네트워크 주소 설정
function isInternalAddr(record)
{
	//return record.get('Device').match(/^bond[0-1]$/) || record.get('Mgmt_IP');
	return record.get('Device').match(/^bond[0-1]$/);
}

function requestAddrSet(params)
{
	params = params || {};

	switch (params.oper)
	{
		case 'add':
			waitWindow(lang_mna_address[0], lang_mna_address[25]);
			break;
		case 'update':
			waitWindow(lang_mna_address[0], lang_mna_address[26]);
			break;
	}

	for (var key in params)
	{
		if (typeof(params[key]) == 'undefined' || params[key] == null)
		{
			delete(params[key]);
		}
	}

	switch (params.oper)
	{
		case 'add':
			GMS.Cors.request({
				url: '/api/network/address/add',
				method: 'POST',
				jsonData: {
					Device: params.device,
					//Active: params.active,
					IPAddr: params.ipaddr,
					Netmask: params.netmask,
					Gateway: params.gateway,
				},
				callback: function (options, success, response, decoded) {
					// 선택한 네트워크 주소의 정보
					var addr = MNA_addressGrid.getSelectionModel().getSelection()[0];

					if (!success || !decoded.success)
						return;

					MNA_addressDescWindow.hide();
					Ext.MessageBox.alert(lang_mna_address[0], lang_mna_address[27]);
					loadNetworkInfo();
				},
			});
			break;
		case 'update':
			GMS.Cors.request({
				url: '/api/cluster/network/address/update',
				method: 'POST',
				jsonData: {
					Device: params.device,
					//Active: params.active,
					IPAddr: params.ipaddr,
					Netmask: params.netmask,
					Gateway: params.gateway,
				},
				callback: function (options, success, response, decoded) {
					// 선택한 네트워크 주소의 정보
					var addr = MNA_addressGrid.getSelectionModel().getSelection()[0];

					if (!success || !decoded.success)
					{
						// WEB에 접속한 IP를 수정할 경우 리다이렉션 처리 구문
						if ((addr.get('IPAddr') == document.location.hostname))
						{
							// IP 주소 변경 확인
							var mgmt_changed = false;

							if (MNA_addressDescForm.isDirty())
							{
								var fields = MNA_addressDescForm.getForm().getFields().items;

								for (var i=0; i<fields.length; i++)
								{
									if (fields[i].name == 'networkIpaddr1'
											|| fields[i].name == 'networkIpaddr2'
											|| fields[i].name == 'networkIpaddr3'
											|| fields[i].name == 'networkIpaddr4')
									{
										if (fields[i].isDirty())
										{
											mgmt_changed = true;
											break;
										}
									}
								}
							}

							// 페이지 리다이렉트
							if (mgmt_changed == true)
							{
								var protocol = window.location.protocol.replace(':', '');
								var port     = window.location.port;    // URL에 포트가 입력되지 않으면 "" (null)이 입력됨.
								if ( port == "" )   // port가 ""이면 exception 발생 (msg : You're trying to decode an invalid JSON String)
									port = "\"\"";
								var address  = Ext.getCmp('MNA_addressIpaddr1').getValue()
									+ '.' + Ext.getCmp('MNA_addressIpaddr2').getValue()
									+ '.' + Ext.getCmp('MNA_addressIpaddr3').getValue()
									+ '.' + Ext.getCmp('MNA_addressIpaddr4').getValue();
								var new_loc = '{'
									+ '"protocol": "' + protocol + '",'
									+ '"address": "' + address + '",'
									+ '"page": "",'
									+ '"httpPort": ' + port + ','
									+ '"httpsPort": ' + port
									+ '}';

								hostLocation(new_loc);
								waitWindow(lang_mna_address[0], lang_mna_address[34]);
							}
						}
						else
						{
							return;
						}
					}

					MNA_addressDescWindow.hide();
					Ext.MessageBox.alert(lang_mna_address[0], lang_mna_address[40]);
					loadNetworkInfo();
				},
			});
			break;
	}

	/*
	// 관리 IP일 경우 비활성화
	if (selected.get('IPAddr') == document.location.host)
	{
		var href        = document.location.href;
		var reader      = document.createElement('a');
			reader.href = href;
		var protocol    = reader.protocol.replace(':', '');
		var ip          = ipaddr;
		var port        = (reader.port) ? reader.port : '80';
		var page        = reader.pathname;

		var data = '{'
			+ '"protocol": "' + protocol + '",'
			+ '"address": "' + addr + '",'
			+ '"page": "",'
			+ '"httpPort": ' + port + ','
			+ '"httpsPort": ' + port
		+ '}';

		setTimeout(function () { MNA_addrestHostLocation(data); }, 10000);
	}
	*/
};

/**
 * Node network management UI loader
 */
function loadNetworkInfo()
{
	// 초기 버튼 컨트롤
	Ext.getCmp('MND_deviceModifyBtn').setDisabled(true);
	Ext.getCmp('MND_deviceDetailBtn').setDisabled(true);
	//Ext.getCmp('MND_deviceDeleteBtn').setDisabled(true);

	Ext.getCmp('MNB_bondDetailBtn').setDisabled(true);
	Ext.getCmp('MNB_bondModifyBtn').setDisabled(true);
	Ext.getCmp('MNB_bondDeleteBtn').setDisabled(true);

	/*
	Ext.getCmp('MNV_vlanAddBtn').setDisabled(true);
	Ext.getCmp('MNV_vlanModifyBtn').setDisabled(true);
	Ext.getCmp('MNV_vlanDeleteBtn').setDisabled(true);
	*/

	Ext.getCmp('MNA_addressUpdateBtn').setDisabled(true);
	Ext.getCmp('MNA_addressDeleteBtn').setDisabled(true);

	// 데이터 제거
	MND_deviceGridStore.removeAll();
	MNB_bondGridStore.removeAll();
	//MNV_vlanGridStore.removeAll();
	MNA_addressGridStore.removeAll();

	// 마스크 표시
	MND_deviceGrid.mask(lang_mnn_network[1]);
	MNB_bondGrid.mask(lang_mnn_network[1]);
	//MNV_vlanGrid.mask(lang_mnn_network[1]);
	MNA_addressGrid.mask(lang_mnn_network[1]);

	// 네트워크 장치 정보
	GMS.Cors.request({
		url: '/api/network/device/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			// 마스크 제거
			MND_deviceGrid.unmask();
			MNB_bondGrid.unmask();
			//MNV_vlanGrid.unmask();

			MND_deviceGridStore.loadRawData(decoded, false);
			MND_deviceGridStore.each(
				function (record)
				{
					record.get('IPAddrs').some(
						function (item)
						{
							if (item == Ext.getCmp('content-main-node-combo').getValue())
							{
								record.set('Mgmt_IP', true);
								return true;
							}
						}
					);
				}
			);

			// lo 장치 숨김
			MND_deviceGridStore.filter(
				function (record)
				{
					return record.get('Device') !== 'lo';
				}
			);

			MNB_bondGridStore.loadRawData(decoded, false);

			MNB_bondGridStore.each(
				function (record)
				{
					record.get('IPAddrs').some(
						function (item)
						{
							if (item == Ext.getCmp('content-main-node-combo').getValue())
							{
								record.set('Mgmt_IP', true);
								return true;
							}
						}
					);
				}
			);

			MNB_bondGridStore.filter(
				function (record)
				{
					return isBonding(record) && !isVLAN(record);
				}
			);

			/*
			MNV_vlanGridStore.loadRawData(decoded, false);

			MNV_vlanGridStore.each(
				function (record)
				{
					record.get('IPAddrs').some(
						function (item)
						{
							if (item == Ext.getCmp('content-main-node-combo').getValue())
							{
								record.set('Mgmt_IP', true);
								return true;
							}
						}
					);
				}
			);

			MNV_vlanGridStore.filter(
				function (record)
				{
					return isVLAN(record);
				}
			);
			*/

			// 데이터 로드 성공 메세지
			// Ext.ux.DialogMsg.msg(lang_mnd_device[0], lang_mnd_device[24]);
		}
	});

	// 네트워크 주소 정보
	GMS.Cors.request({
		url: '/api/network/address/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			MNA_addressGrid.unmask();

			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
				return;

			MNA_addressGridStore.loadRawData(decoded, false);

			MNA_addressGridStore.each(
				function (record) {
					var ip = record.data.IPAddr;

					//if (ip == Ext.getCmp('content-main-node-combo').getValue())
					if (ip == document.location.hostname)
					{
						record.set('Mgmt_IP', true);
					}
				}
			);
		}
	});
}

// 네트워크
Ext.define('/admin/js/manager_node_network',
	{
		extend: 'BasePanel',
		id: 'manager_node_network',
		load: function () {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			loadNetworkInfo();
		},
		bodyStyle: { padding: '0px' },
		items: [
			{
				xtype: 'BasePanel',
				id: 'manager_node_network_panel',
				layout: 'absolute',
				autoScroll: true,
				bodyStyle: { padding: '0px' },
				items: [
					{
						xtype: 'BasePanel',
						layout: {
							type: 'vbox',
							pack: 'start',
							align : 'stretch'
						},
						bodyStyle: { padding: '20px' },
						items: [
							{
								flex: 1,
								xtype: 'BasePanel',
								layout: 'fit',
								style: { marginBottom: '20px' },
								bodyStyle: { padding: '0px' },
								items: [ MND_deviceGrid ]
							},
							{
								flex: 1,
								xtype: 'BasePanel',
								layout: {
									type: 'hbox',
									pack: 'start',
									align : 'stretch'
								},
								style: { marginBottom: '20px' },
								bodyStyle: { padding: '0px' },
								items: [
									{
										flex: 1,
										xtype: 'BasePanel',
										layout: 'fit',
										bodyStyle: { padding: '0px' },
										items: [ MNB_bondGrid ]
									},
									/*
									{
										width: 20,
										xtype: 'BasePanel',
										bodyStyle: { padding: '0px' },
										html: '&nbsp;'
									},
									{
										flex: 0.5,
										xtype: 'BasePanel',
										layout: 'fit',
										bodyStyle: { padding: '0px' },
										items: [ MNV_vlanGrid ]
									},
									*/
								]
							},
							{
								flex: 1,
								xtype: 'BasePanel',
								layout: 'fit',
								bodyStyle: { padding: '0px' },
								style: { marginBottom: '20px' },
								items: [ MNA_addressGrid ]
							},
						]
					}
				]
			}
		]
	}
);
