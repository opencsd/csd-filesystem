/****************************************************************************
 * Models
 ****************************************************************************/

// 서비스 IP 목록 모델
Ext.define(
	'MCN_networkVIPModel',
	{
		extend: 'Ext.data.Model',
		fields: [ 'Interface', 'IPAddr', 'First', 'Last', 'Netmask' ]
	}
);

Ext.define(
	'MCN_networkVIPGroupModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Name', type: 'string' },
			{ name: 'Host', type: 'string' },
			{ name: 'Device', type: 'string' },
		],
	}
);

Ext.define(
	'MCN_networkVIPAddrModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Name', type: 'string' },
			{ name: 'First', type: 'string' },
			{ name: 'Last', type: 'string' },
			{ name: 'Netmask', type: 'string' },
		],
	},
);

// 라우팅 네트워크 인터페이스 모델
Ext.define(
	'MCN_networkRouteComboModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Device']
	}
);

// 라우팅 정보 모델
Ext.define(
	'MCN_networkRouteModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Destination', 'Netmask', 'Gateway', 'Default', 'Device']
	}
);

// DNS 정보 모델
Ext.define(
	'MCN_networkDNSModel',
	{
		extend: 'Ext.data.Model',
		fields: ['IPAddr']
	}
);

// 네트워크 영역 정보 모델
Ext.define(
	'MCN_networkZoneGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [ 'Name', 'Desc', 'Type', 'Addrs', 'Range', 'CIDR', 'Domain' ],
		idProperty: 'Name'
	}
);

// 공유 정보 모델
Ext.define(
	'MCN_networkZoneShareGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [ 'Name', 'Used', 'Type', 'Access' ],
		//idProperty: 'Name'
	}
);

/****************************************************************************
 * Stores
 ****************************************************************************/

// 라우팅 정보 네트워크 인터페이스 comboBox 스토어
var MCN_networkDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkRouteComboModel',
		sorters: { property: 'Device', direction: 'ASC' },
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				//root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				if (success === true)
					return;

				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mcn_service[0] + '",'
					+ '"content": "' + lang_mcn_service[1] + '",'
					+ '"response": ' + jsonText
				+ '}';

				exceptionDataCheck(checkValue);
			}
		}
	}
);

// 라우팅 정보 스토어
var MCN_networkRouteStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkRouteModel',
		actionMethods: { read: 'POST' },
		sorters: [
			{ property: 'Destination', direction: 'ASC' }
		],
		proxy: {
			type: 'gms',
			url: '/api/cluster/network/route/entry/list',
			exception_title: lang_mcn_route[2],
			reader: {
				type: 'json',
				root: 'entity',
				getResponseData: function (response) {
					var json = Ext.decode(response.responseText);

					for (var i=0, len=json.entity.length; i<len; i++)
					{
						var to = json.entity[i].To.split(/\//);

						if (json.entity[i].Default
							|| (to[0] == '0.0.0.0' && to[1] == 0))
						{
							json.entity[i].Destination = 'Default GW';
							json.entity[i].Netmask     = '0.0.0.0';
							json.entity[i].Default     = true;
						}
						else
						{
							json.entity[i].Destination = to[0];
							json.entity[i].Netmask     = prefix_to_netmask(to[1]);
						}

						json.entity[i].Gateway = json.entity[i].Via;
					}

					return this.readRecords(json);
				},
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
		}
	}
);

// 서비스 IP 목록 스토어
var MCN_networkVIPGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkVIPModel',
		sorters: [
			{ property: 'Interface', direction: 'ASC' },
			{ property: 'First', direction: 'ASC' },
			{ property: 'Last', direction: 'ASC' }
		],
		proxy: {
			type: 'gms',
			url: '/api/cluster/network/vip/list',
			reader: {
				type: 'json',
				root: 'entity',
				/*
				getResponseData: function (response) {
					var json = Ext.decode(response.responseText);

					//
					// :WARNING 06/03/2019 02:13:14 PM: by P.G.
					// workaround for IP address range.
					// we have to replace it with a grid for service IP addresses.
					//
					for (var i=0, len=json.entity.length; i<len; i++)
					{
						var ipaddr = json.entity[i].IPAddrs.split(/-|\//);

						json.entity[i].First   = ipaddr[0];
						json.entity[i].Last    = ipaddr.length > 2 ? ipaddr[1] : ipaddr[0];
						json.entity[i].Netmask = ipaddr.length > 2
													? prefix_to_netmask(ipaddr[2])
													: prefix_to_netmask(ipaddr[1]);
					}

					return this.readRecords(json);
				}
				/*/

				//*/
			},
			exception_title: lang_mcn_service[1]
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
		}
	}
);

// DNS 정보 스토어
var MCN_networkDNSStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkDNSModel',
		actionMethods: { read: 'POST' },
		proxy: {
			type: 'gms',
			url: '/api/cluster/network/dns/info',
			exception_title: lang_mcn_dns[1],
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			}
		}
	}
);

// 네트워크 영역 정보 스토어
var MCN_networkZoneGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkZoneGridModel',
		proxy: {
			type: 'gms',
			url: '/api/cluster/network/zone/list',
			exception_title: lang_mcn_service[0],
		},
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
		}
	}
);

// 공유 정보 스토어
var MCN_networkZoneShareGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkZoneShareGridModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'shareZoneList'
			}
		}
	}
);

/****************************************************************************
 * Grids
 ****************************************************************************/
// 서비스 IP 목록 그리드
var MCN_networkVIPGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkVIPGrid',
		store: MCN_networkVIPGridStore,
		multiSelect: false,
		title: lang_mcn_service[13],
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			showHeaderCheckbox: false,
		},
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
		},
		tbar: [
			{
				text: lang_mcn_service[18],
				id: 'MCN_networkVIPAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					Ext.getCmp('MCN_networkVIPDescForm').getForm().reset();
					Ext.getCmp('MCN_networkVIPOperType').setValue('create');

					MCN_networkVIPDescWindow.animateTarget = Ext.getCmp('MCN_networkVIPAddBtn');
					MCN_networkVIPDescWindow.show();
				}
			},
			{
				text: lang_mcn_service[20],
				id: 'MCN_networkVIPModifyBtn',
				iconCls: 'b-icon-edit',
				handler: function () {
					Ext.getCmp('MCN_networkVIPDescForm').getForm().reset();

					// 선택된 서비스 IP 데이터 로드
					var selected = MCN_networkVIPGrid.getSelectionModel().getSelection()[0];

					var interface = selected.get('Interface');
					var first_ip  = selected.get('First');
					var last_ip   = selected.get('last');
					var netmask   = selected.get('Netmask');

					Ext.getCmp('MCN_networkVIPInterface').setText(interface);

					// 시작 IP
					var first_ip_arr = first_ip.split(".");

					Ext.getCmp('MCN_networkVIPStart1').setValue(first_ip_arr[0]);
					Ext.getCmp('MCN_networkVIPStart2').setValue(first_ip_arr[1]);
					Ext.getCmp('MCN_networkVIPStart3').setValue(first_ip_arr[2]);
					Ext.getCmp('MCN_networkVIPStart4').setValue(first_ip_arr[3]);

					// 마지막 IP
					var end_ip_arr = end_ip.split(".");

					Ext.getCmp('MCN_networkVIPLast1').setValue(end_ip_arr[0]);
					Ext.getCmp('MCN_networkVIPLast2').setValue(end_ip_arr[1]);
					Ext.getCmp('MCN_networkVIPLast3').setValue(end_ip_arr[2]);
					Ext.getCmp('MCN_networkVIPLast4').setValue(end_ip_arr[3]);

					// 넷마스크
					var netmask_arr = netmask.split(".");

					Ext.getCmp('MCN_networkServiceNetmask1').setValue(netmask_arr[0]);
					Ext.getCmp('MCN_networkServiceNetmask2').setValue(netmask_arr[1]);
					Ext.getCmp('MCN_networkServiceNetmask3').setValue(netmask_arr[2]);
					Ext.getCmp('MCN_networkServiceNetmask4').setValue(netmask_arr[3]);

					MCN_networkVIPDescWindow.animateTarget = Ext.getCmp('MCN_networkVIPModifyBtn');
					MCN_networkVIPDescWindow.show();

					Ext.getCmp('MCN_networkVIPOperType').setValue('modify');
				}
			},
			{
				text: lang_mcn_service[21],
				id: 'MCN_networkVIPDeleteBtn',
				iconCls: 'b-icon-delete',
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mcn_service[0],
						lang_mcn_service[22],
						function (btn, text) {
							if (btn !== 'yes')
								return;

							// 선택된 서비스 IP 데이터 로드
							var selected = MCN_networkVIPGrid.getSelectionModel().getSelection()[0];

							waitWindow(lang_mcn_service[0], lang_mcn_service[23]);

							GMS.Ajax.request({
								url: '/api/cluster/network/vip/delete',
								jsonData: {
									Interface: selected.get('Interface'),
									IPAddrs: [selected.get('IPAddr')],
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mcn_service[0], lang_mcn_service[24]);
									MCN_serviceLoad();
								}
							});
						}
					);
				}
			}
		],
		columns: [
			{
				flex: 1,
				text: lang_mcn_service[17],
				sortable: true,
				dataIndex: 'Interface'
			},
			{
				flex: 1,
				text: lang_mcn_service[14],
				sortable: true,
				dataIndex: 'First'
			},
			{
				flex: 1,
				text: lang_mcn_service[15],
				sortable: true,
				dataIndex: 'Last'
			},
			{
				flex: 1,
				text: lang_mcn_service[16],
				sortable: true,
				dataIndex: 'Netmask'
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () {
					MCN_networkVIPSelect(record)
				}, 200);
			}
		},
	}
);

/*
 * VIP Group
 */

// VIP Group Store
var MCN_networkVIPGroupStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkVIPGroupModel',
		groupField: 'Name',
		proxy: {
			type: 'gms',
			url: '/api/cluster/network/vip/list',
			reader: {
				type: 'json',
				root: 'entity',
				getResponseData: function (response) {
					var json = Ext.decode(response.responseText);

					var hosts = [];

					for (var i=0; i<json.entity.length; i++)
					{
						var entity = json.entity[i];

						if (!entity.Hosts.length)
						{
							entity.Hosts = [
								{
									Name: entity.Name,
								}
							];
						}

						hosts = hosts.concat(entity.Hosts);
					}

					json.entity = hosts;
					json.count  = hosts.length;

					return this.readRecords(json);
				},
			}
		}
	}
);

// VIP Address Store
var MCN_networkVIPAddrStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkVIPAddrModel',
		groupField: 'Name',
		proxy: {
			type: 'gms',
			url: '/api/cluster/network/vip/list',
			reader: {
				type: 'json',
				root: 'entity',
				getResponseData: function (response) {
					var json = Ext.decode(response.responseText);

					var ipaddrs = [];

					for (var i=0; i<json.entity.length; i++)
					{
						var entity = json.entity[i];

						if (!entity.IPAddrs.length)
						{
							continue;
						}

						ipaddrs = ipaddrs.concat(entity.IPAddrs);
					}

					json.entity = ipaddrs;
					json.count  = ipaddrs.length;

					return this.readRecords(json);
				},
			}
		},
		listeners: {
			load: function (store, records, successful, eOpts)
			{
				Ext.getCmp('MCN_networkVIPAddrAddBtn').setDisabled(false);
				Ext.getCmp('MCN_networkVIPAddrRemoveBtn').setDisabled(true);
			},
		},
	}
);

// TODO:
// - 그룹 수정을 통해 VIP 추가/제거
var MCN_networkVIPGroupGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkVIPGroupGrid',
		store: MCN_networkVIPGroupStore,
		multiSelect: false,
		title: lang_mcn_service[37],
		//*
		selModel: {
			mode: 'SIMPLE',
			allowDeselect: false,
		},
		/*/
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			showHeaderCheckbox: false,
			allowDeselect: true,
		},
		*/
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
			getRowClass: function(record, index, rowParams, store) {
				if (record.get('Host') === '')
					return 'x-hide-display';
			}
		},
		features: [
			{
				ftype: 'brigrouping',
				//groupHeaderTpl: '{name} ({children.length})',
				groupHeaderTpl: "{name}",
				enableNoGroups: true,
				collapsible: false,
			}
		],
		tbar: [
			// Add VIP group
			{
				id: 'MCN_networkVIPGroupCreateBtn',
				text: lang_mcn_service[18],
				iconCls: 'b-icon-add',
				handler: function () {
					Ext.getCmp('vipGroupName').reset();

					var win = Ext.getCmp('MCN_networkVIPGroupCreateWindow');

					win.animateTarget = this;
					win.show();
				},
			},
			// Update VIP group
			{
				text: lang_common[6],
				id: 'MCN_networkVIPGroupUpdateBtn',
				iconCls: 'b-icon-edit',
				handler: function () {
					var win = Ext.getCmp('MCN_networkVIPGroupUpdateWindow');

					win.animateTarget = Ext.getCmp('MCN_networkVIPGroupUpdateBtn');
					win.show();
				}
			},
			// Delete VIP group
			{
				id: 'MCN_networkVIPGroupDeleteBtn',
				text: lang_mcn_service[21],
				iconCls: 'b-icon-delete',
				handler: function () {
					var grid     = this.up('grid');
					var selected = grid.getSelectionModel().getSelection()[0];

					Ext.MessageBox.confirm(
						lang_mcn_service[0],
						lang_mcn_service[38].replace("@", selected.get('Name')),
						function (btn, text) {
							if (btn != 'yes')
								return;

							waitWindow(lang_mcn_service[0], 'Deleting VIP group ' + selected.get('Name') + '...');

							GMS.Ajax.request({
								url: '/api/cluster/network/vip/' + selected.get('Name') + '/delete',
								method: 'DELETE',
								jsonData: {
									Name: selected.get('Name'),
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mcn_service[0], decoded.msg);

									MCN_networkVIPGroupStore.load();
								},
							});
						}
					);
				},
			},
		],
		columns: [
			{
				flex: 1,
				text: 'Name',
				sortable: true,
				dataIndex: 'Name',
				hidden: true,
			},
			{
				flex: 1,
				text: lang_common[38],
				sortable: true,
				dataIndex: 'Host',
			},
			{
				flex: 1,
				text: lang_common[35],
				sortable: true,
				dataIndex: 'Device',
			},
		],
		listeners: {
			select: function (rowmodel, record, index, eOpts) {
				var grid  = this;
				var sm    = grid.getSelectionModel();
				var group = record.get('Name');
				var count = 0;

				grid.getStore().each(
					function (record, id)
					{
						if (record.get('Name') == group)
						{
							count++;
							sm.select(record, true);
						}
						else
						{
							sm.deselect(record);
						}
					}
				);

				MCN_networkVIPAddrStore.filter('Name', record.get('Name'));

				Ext.getCmp('MCN_networkVIPGroupUpdateBtn')
					.setDisabled(grid.getStore().getCount() > 0 ? false : true);

				Ext.getCmp('MCN_networkVIPGroupDeleteBtn')
					.setDisabled(grid.getStore().getCount() > 0 ? false : true);
			},
			deselect: function (rowmodel, record, index, eOpts) {
				var grid  = this;
				var sm    = grid.getSelectionModel();
				var group = record.get('Name');

				grid.getStore().each(
					function (record, id)
					{
						if (record.get('Name') == group)
						{
							sm.deselect(record);
						}
					}
				);

				MCN_networkVIPAddrStore.clearFilter();

				Ext.getCmp('MCN_networkVIPGroupUpdateBtn')
					.setDisabled(grid.getStore().getCount() > 0 ? true : false);

				Ext.getCmp('MCN_networkVIPGroupDeleteBtn')
					.setDisabled(grid.getStore().getCount() > 0 ? true : false);
			},
		},
	},
);

var MCN_networkVIPGroupCreateWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCN_networkVIPGroupCreateWindow',
		itemId: 'me',
		layout: 'fit',
		title: lang_mcn_service[0],
		resizable: true,
		width: 300,
		autoHeight: true,
		items: [
			Ext.create(
				'BaseFormPanel',
				{
					itemId: 'Form',
					layout: {
						type: 'vbox',
						align: 'stretch',
					},
					frame: false,
					autoScroll: false,
					items: [
						// Group name 
						{
							id: 'vipGroupName',
							itemId: 'Name',
							xtype: 'textfield',
							vtype: 'reg_vipGroupName',
							fieldLabel: lang_common[39],
							allowBlank: false,
							labelWidth: 50,
						},
					],
				},
			),
		],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_common[5],
				handler: function () {
					var win      = this.up('window');
					var children = getChildComponents(['#Form']);

					if (!children[0].getForm().isValid())
						return;

					children = getChildComponents(['#Name']);

					var name = children[0].getValue();

					waitWindow(lang_mcn_service[0], lang_mcn_service[31]);

					GMS.Ajax.request({
						url: '/api/cluster/network/vip/create',
						method: 'POST',
						jsonData: {
							Name: name,
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							Ext.MessageBox.alert(lang_mcn_service[0], decoded.msg);

							win.close();

							MCN_networkVIPGroupStore.load();
						}
					});
				}
			},
			{
				text: lang_common[4],
				handler: function () {
					Ext.getCmp('MCN_networkVIPGroupCreateWindow').close();
				},
			},
		],
	}
);

/*
 * VIP 노드 인터페이스 추가 그리드
 */
Ext.define(
	'MCN_networkVIPDeviceModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Type', type: 'string' },
			{ name: 'Host', type: 'string' },
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

var MCN_networkVIPDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCN_networkVIPDeviceModel',
		sorters: [
			{
				sorterFn: function (a, b) {
					var me = this;

					// WARNING!
					var sel_model  = MCN_networkVIPDeviceGrid.getSelectionModel();
					var a_selected = sel_model.isSelected(a);
					var b_selected = sel_model.isSelected(b);

					if (!(a_selected ^ b_selected))
					{
						return 0;
					}
					else if (a_selected && !b_selected)
					{
						return -1;
					}
					else if (!a_selected && b_selected)
					{
						return 1;
					}
				},
			},
			{ property: 'Host', direction: 'ASC' },
			{ property: 'Device', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			}
		},
		listeners: {
			load: function () {
				var device_grid = MCN_networkVIPDeviceGrid;
				var group_grid  = MCN_networkVIPGroupGrid;

				group_grid.getSelectionModel().getSelection().forEach(
					function (selected) {
						device_grid.getStore().each(
							function (r, idx) {
								if (selected.get('Host') == r.get('Host')
									&& selected.get('Device') == r.get('Device'))
								{
									device_grid.getSelectionModel().select(idx, true, false);
								}
							}
						);
					}
				);

				// WARNING: Tricky
				device_grid.getStore().filterBy(
					function (r, idx) {
						var ipaddrs = r.get('IPAddrs');

						// 본딩의 Slave인 경우
						var is_bond_slave = false;

						device_grid.getStore().each(
							function (master, idx)
							{
								if (!isVLAN(r) && isBonding(master)
									&& master.get('Device') == r.get('Master'))
								{
									is_bond_slave = true;
								}
							}
						);

						if (is_bond_slave)
							return false;

						// VLAN의 Master인 경우
						var is_vlan_master = false;

						device_grid.getStore().each(
							function (slave, idx)
							{
								if (isVLAN(slave)
									&& r.get('Device') == slave.get('Master'))
								{
									is_vlan_master = true;
								}
							}
						);

						if (is_vlan_master)
							return false;

						return device_grid.getSelectionModel().isSelected(r)
								|| ipaddrs.length == 0;
					}
				);
			}
		}
	}
);

var MCN_networkVIPDeviceGrid = Ext.create(
	'BaseGridPanel',
	{
		store: MCN_networkVIPDeviceStore,
		multiSelect: false,
		title: lang_mnd_device[37],
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'MULTI',
			checkOnly: true,
			allowDeselect: true,
			listeners: {
				// TODO: Validation
				select: function (me, record, index, eOpts) {

				},
				deselect: function (me, record, index, eOpts) {

				},
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mnd_disk[30],
				sortable: true,
				dataIndex: 'Host',
			},
			{
				flex: 1,
				text: lang_mnd_device[11],
				sortable: true,
				dataIndex: 'Device',
			},
			{
				flex: 2,
				text: lang_mnd_device[26],
				sortable: true,
				dataIndex: 'Model',
				hidden: true,
			},
			{
				flex: 1,
				text: lang_mnd_device[14],
				sortable: true,
				dataIndex: 'HWAddr',
				hidden: true,
			},
			{
				flex: 1,
				text: lang_mnd_device[15],
				sortable: true,
				dataIndex: 'Speed',
			},
			{
				flex: 1,
				text: ' MTU',
				sortable: true,
				dataIndex: 'MTU',
				hidden: true,
			},
			{
				flex: 1,
				text: lang_mnd_device[16],
				sortable: true,
				dataIndex: 'OnBoot',
			},
			{
				flex: 1,
				text: lang_mnd_device[17],
				sortable: true,
				dataIndex: 'LinkStatus',
			},
			{
				flex: 1,
				text: lang_mnd_device[27],
				sortable: true,
				dataIndex: 'BootProto',
				hidden: true,
			},
			{
				flex: 1,
				text: lang_mnd_device[28],
				sortable: true,
				dataIndex: 'Master',
			},
		],
	},
);

var MCN_networkVIPGroupUpdateWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCN_networkVIPGroupUpdateWindow',
		itemId: 'me',
		layout: 'fit',
		title: lang_mcn_service[0],
		resizable: true,
		width: 700,
		autoHeight: true,
		items: [
			Ext.create(
				'BaseFormPanel',
				{
					layout: {
						type: 'vbox',
						align: 'stretch',
					},
					frame: false,
					autoScroll: false,
					items: [ MCN_networkVIPDeviceGrid ],
				}
			),
		],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_common[6],
				handler: function () {
					var win       = this.up('window');
					var group_sm  = MCN_networkVIPGroupGrid.getSelectionModel();
					var device_sm = MCN_networkVIPDeviceGrid.getSelectionModel();

					var targets = [];

					// get to be added devices
					device_sm.getSelection().forEach(
						function (r1)
						{
							var found = false;

							group_sm.getSelection().some(
								function (r2)
								{
									if (r1.get('Host') == r2.get('Host')
										&& r1.get('Device') == r2.get('Device'))
									{
										return found = true;
									}
								}
							);

							if (found == false
							    && r1.get('Device').length != 0)
							{
								targets.push(
									{
										Oper: 'add',
										Host: r1.get('Host'),
										Device: r1.get('Device'),
									}
								);
							}
						}
					);

					// get to be removed devices
					group_sm.getSelection().forEach(
						function (r1)
						{
							var found = false;

							device_sm.getSelection().some(
								function (r2)
								{
									if (r1.get('Host') == r2.get('Host')
										&& r1.get('Device') == r2.get('Device'))
									{
										return found = true;
									}
								}
							);

							if (found == false 
							    && r1.get('Device').length != 0)
							{
								targets.push(
									{
										Oper: 'remove',
										Host: r1.get('Host'),
										Device: r1.get('Device'),
									}
								);
							}
						}
					);

					var group = group_sm.getSelection()[0].get('Name');

					var handler = function (index, record) {
						var wait = waitWindow(
							lang_mcn_service[0],
							(record.Oper == 'add' ? lang_mcn_service[35] : lang_mcn_service[36])
								.replace('@', record.Host)
								.replace('@', record.Device)
								.replace('@', group));

						GMS.Ajax.request({
							url: '/api/cluster/network/vip/' + group + '/host/' + record.Oper,
							method: record.Oper == 'add' ? 'POST' : 'DELETE',
							jsonData: {
								Name  : group,
								Host  : record.Host,
								Device: record.Device,
								Length: group_sm.getSelection().length,
							},
							callback: function (options, success, response, decoded) {
								if (!success || !decoded.success)
									return defers[index].reject(index);

								wait.close();
								win.close();

								return defers[index].resolve(index);
							},
						});
						return;
					};

					var defers = targets.map(
						function (v)
						{
							var dfd = Ext.create('Ext.ux.Deferred');

							dfd.promise().then(
								function (index) {
									handler(index+1, v);
								},
								function (error) {
									// TODO: error handling (ex: pop up a messagebox)
									defers[index+1].reject(error);
								},
							);

							return dfd;
						}
					)

					var dfd = Ext.create('Ext.ux.Deferred');

					dfd.promise()
						.success(
							function(index) {
								MCN_networkVIPGroupStore.load();
								win.close();
							}
						)
						.failure(
							function (error) {
								console.error(error);
							}
						);

					defers.push(dfd);

					// trigger promise
					defers[0].resolve(0);
				}
			},
			{
				text: lang_common[4],
				handler: function () {
					this.up('window').close();
				}
			},
		],
		listeners: {
			show: function (me, eOpts) {
				var grid = getChildComponents(['grid'])[0];

				grid.mask(lang_common[30]);
				grid.getStore().removeAll();

				var promise = GMS.Ajax.request({
					url: '/api/cluster/network/device/list',
					method: 'POST',
					callback: function (options, success, response, decoded) {
						if (!success || !decoded.success)
						{
							options.promise.reject();
							return;
						}

						grid.getStore().loadRawData(decoded);
						options.promise.resolve();
					}
				});

				promise.success(
					function (response) {
						try {
							grid.getStore().sort();
						}
						catch (error) {
							console.error(error);
						}

						grid.unmask();
					}
				);
			},
		},
	}
);

/*
 * VIP Address
 */
var MCN_networkVIPAddrGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkVIPAddrGrid',
		store: MCN_networkVIPAddrStore,
		multiSelect: false,
		title: lang_mcn_service[13],
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			showHeaderCheckbox: false,
			listeners: {
				select: function (me, record, index, eOpts) {
					Ext.getCmp('MCN_networkVIPAddrRemoveBtn')
						.setDisabled(me.getCount() != 1);
				},
				deselect: function (me, record, index, eOpts) {
					Ext.getCmp('MCN_networkVIPAddrRemoveBtn')
						.setDisabled(me.getCount() != 1);
				},
			},
		},
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
		},
		features: [
			{
				ftype: 'grouping',
				//groupHeaderTpl: "{name} <tpl if=\"children[0].data.First != ''\">({children.length})</tpl>",
				groupHeaderTpl: '{name}',
				enableNoGroups: true,
			}
		],
		tbar: [
			// Add a VIP address to VIP group
			{
				id: 'MCN_networkVIPAddrAddBtn',
				text: lang_common[34],
				iconCls: 'b-icon-add',
				handler: function () {
					var win = Ext.getCmp('MCN_networkVIPAddrAddWindow');

					win.animateTarget = this;
					win.show();
				}
			},
			// Remove a VIP address from VIP gruop
			{
				id: 'MCN_networkVIPAddrRemoveBtn',
				text: lang_common[37],
				iconCls: 'b-icon-delete',
				handler: function () {
					var grid      = this.up('grid');
					var selection = grid.getSelectionModel().getSelection();

					var name    = selection[0].get('Name');
					var first   = selection[0].get('First');
					var last    = selection[0].get('Last');
					var netmask = selection[0].get('Netmask');

					Ext.MessageBox.confirm(
						lang_mcn_service[0],
						lang_mcn_service[33].replace('@', first).replace('@', last),
						function (btn, text) {
							if (btn != 'yes')
								return;

							waitWindow(lang_mcn_service[0], lang_mcn_service[34]);

							GMS.Ajax.request({
								method: 'DELETE',
								url: '/api/cluster/network/vip/'
									+ selection[0].get('Name')
									+ '/address/remove',
								jsonData: {
									Name: name,
									IPAddrs: [
										first + '-' + last + '/' + netmask_to_prefix(netmask)
									],
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mcn_service[0], decoded.msg);
									MCN_networkVIPAddrStore.load();
								},
							});
						}
					);
				}
			},
		],
		columns: [
			{
				flex: 1,
				text: 'Name',
				sortable: true,
				dataIndex: 'Name',
				hidden: true,
			},
			{
				flex: 1,
				text: lang_mcn_service[14],
				sortable: true,
				dataIndex: 'First',
			},
			{
				flex: 1,
				text: lang_mcn_service[15],
				sortable: true,
				dataIndex: 'Last',
			},
			{
				flex: 1,
				text: lang_mcn_service[16],
				sortable: true,
				dataIndex: 'Netmask',
			},
		],
	},
);

var MCN_networkVIPAddrAddWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCN_networkVIPAddrAddWindow',
		itemId: 'me',
		layout: 'fit',
		title: lang_mcn_service[12],
		resizable: true,
		width: 350,
		autoHeight: true,
		items: [
			Ext.create(
				'BaseFormPanel',
				{
					itemId: 'Form',
					layout: {
						type: 'vbox',
						align: 'stretch',
					},
					frame: false,
					autoScroll: false,
					items: [
						// VIP group
						{
							itemId: 'Group',
							xtype: 'combo',
							fieldLabel: lang_mcn_service[0],
							allowBlank: false,
							labelWidth: 80,
							displayField: 'Group',
							valueField: 'Group',
							editable: false,
							store: Ext.create('Ext.data.Store', { fields: [ 'Group' ] }),
						},
						// First IP address
						{
							itemId: 'First_IP',
							xtype: 'textfield',
							//vtype: 'reg_IP',
							fieldLabel: lang_mcn_service[14],
							allowBlank: false,
							labelWidth: 80,
						},
						// Last IP address (allowBlank: true)
						{
							itemId: 'Last_IP',
							xtype: 'textfield',
							//vtype: 'reg_IP',
							fieldLabel: lang_mcn_service[15],
							allowBlank: true,
							labelWidth: 80,
						},
						// Netmask
						{
							itemId: 'Netmask',
							xtype: 'textfield',
							//vtype: 'reg_NETMASK',
							fieldLabel: lang_common[16],
							allowBlank: false,
							labelWidth: 80,
						},
					],
				},
			),
		],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_common[34],
				handler: function () {
					var win  = this.up('window');
					var form = win.down('form');

					if (!form.getForm().isValid())
						return;

					children = getChildComponents(['#Group', '#First_IP', '#Last_IP', '#Netmask']);

					var group   = children[0].getValue();
					var first   = children[1].getValue();
					var last    = children[2].getValue();
					var netmask = children[3].getValue();

					var iprange = first;

					if (!Ext.isEmpty(last))
					{
						iprange += '-' + last;
					}

					waitWindow(lang_mcn_service[0], lang_mcn_service[32].replace('@', group));

					GMS.Ajax.request({
						url: '/api/cluster/network/vip/' + group + '/address/add',
						method: 'POST',
						jsonData: {
							Name: group,
							IPAddrs: [iprange + '/' + netmask_to_prefix(netmask)],
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							Ext.MessageBox.alert(lang_mcn_service[0], decoded.msg);
							MCN_networkVIPAddrStore.load();
							win.close();
						}
					});
				}
			},
		],
		listeners: {
			show: function (me, eOpts) {
				getChildComponents(['form'])
					.forEach(function (v) { v.getForm().reset(); });

				var groups = [];

				MCN_networkVIPGroupStore.each(
					function (record)
					{
						if (groups.some(
								function (val)
								{
									return val.Group == record.get('Name')
								}))
						{
							return;
						}

						groups.push(
							{
								Group: record.get('Name'),
							}
						);
					}
				);

				var combo = getChildComponents(['#Group'])[0];

				combo.getStore().loadRawData(groups);
				combo.setValue(combo.getStore().getAt(0).get(combo.valueField), true);
			}
		},
	},
);

/*
 * VLAN Group
 */
Ext.define(
	'MCN_networkVLANModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Name', type: 'string' },
			{ name: 'ID', type: 'integer' },
			{ name: 'Nodes', type: 'auto' },
		]
	}
);

var MCN_networkVLANStore = Ext.create(
	'Ext.data.Store',
	{
		storeId: 'vlanStore',
		fields: [ 'Name', 'ID', 'Nodes' ],
		groupField: 'Name',
		data: [
			{
				Name: "VLAN-10",
				ID: 10,
				Nodes: [
					{
						Name: 'NODE-1',
						Device: 'bond1.10',
					},
					{
						Name: 'NODE-2',
						Device: 'bond1.10',
					},
					{
						Name: 'NODE-3',
						Device: 'bond1.10',
					},
					{
						Name: 'NODE-4',
						Device: 'bond1.10',
					},
				],
			},
			{
				Name: "VLAN-20",
				ID: 20,
				Nodes: [
					{
						Name: 'NODE-1',
						Device: 'bond1.20',
					},
					{
						Name: 'NODE-2',
						Device: 'bond1.20',
					},
					{
						Name: 'NODE-3',
						Device: 'bond1.20',
					},
				],
			},
			{
				Name: "VLAN-30",
				ID: 30,
				Nodes: [
					{
						Name: 'NODE-1',
						Device: 'bond1.30',
					},
					{
						Name: 'NODE-3',
						Device: 'bond1.30',
					},
					{
						Name: 'NODE-4',
						Device: 'bond1.30',
					},
				],
			},
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		}
	}
);


var MCN_networkVLANGroupGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkVLANGroupGrid',
		store: MCN_networkVLANStore,
		frame: true,
		title: 'VLAN Groups',
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		},
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			checkOnly: true,
			allowDeselect: true,
		},
		tbar: [
			{
				xtype: 'button',
				text: 'Add',
				iconCls: 'b-icon-add',
				handler: function () {
					// show pop-up to add VLAN Group
				}
			},
			{
				xtype: 'button',
				text: 'Modify',
				iconCls: 'b-icon-edit',
				handler: function () {
					// show pop-up to modify VLAN Group
				}
			},
			{
				xtype: 'button',
				text: 'Remove',
				iconCls: 'b-icon-delete',
				handler: function () {
					// show pop-up to remove VLAN Group
				}
			},
		],
		columns: [
			// VLAN group name
			{
				flex: 1,
				text: 'Name',
				sortable: true,
				dataIndex: 'Name',
			},
			// VLAN ID
			{
				flex: 1,
				text: 'ID',
				sortable: true,
				dataIndex: 'ID',
			},
		],
		listeners: {
			select: function (grid, record, index, eOpts) {
				Ext.getCmp('MCN_networkVLANGroupInfoGrid').getStore().loadRawData(record.raw.Nodes);
			},
			deselect: function (grid, record, index, eOpts) {
				Ext.getCmp('MCN_networkVLANGroupInfoGrid').getStore().removeAll();
			},
		},
	}
);

var MCN_networkVLANGroupInfoGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkVLANGroupInfoGrid',
		store: new Ext.data.Store(
			{
				fields: ['Name', 'Device'],
				autoLoad: false
			}
		),
		frame: true,
		title: 'Details',
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
		},
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			checkOnly: true,
			allowDeselect: true,
		},
		tbar: [
			{
				xtype: 'button',
				text: 'Add',
				iconCls: 'b-icon-add',
				handler: function () {
					/*
					// show pop-up to add an interface to a VLAN Group
					GMS.Ajax.request({
						url: '/api/cluster/network/vlan/add',
						method: 'POST',
						jsonData: {
							Host: ,
							Device: ,
						},
						callback: function (options, success, response, decoded) {
						}
					});
					*/
				}
			},
			{
				xtype: 'button',
				text: 'Modify',
				iconCls: 'b-icon-edit',
				handler: function () {
					/*
					// show pop-up to modify an interface to a VLAN Group
					GMS.Ajax.request({
						url: '/api/cluster/network/vlan/modify',
						method: 'POST',
						jsonData: {
							Host: 
						},
						callback: function (options, success, response, decoded) {
						}
					});
					*/
				}
			},
			{
				xtype: 'button',
				text: 'Remove',
				iconCls: 'b-icon-delete',
				handler: function () {
					/*
					// show pop-up to remove an interface to a VLAN Group
					GMS.Ajax.request({
						url: '/api/cluster/network/vlan/remove',
						method: 'POST',
						jsonData: {
							Device: '',

						},
						callback: function (options, success, response, decoded) {
						}
					});
					*/
				}
			},
		],
		columns: [
			// VLAN Node
			{
				flex: 1,
				text: 'Name',
				sortable: true,
				dataIndex: 'Name',
			},
			// VLAN Device
			{
				flex: 1,
				text: 'Device',
				sortable: true,
				dataIndex: 'Device',
			},
		],
		listeners: {
			select: function (grid, record, index, eOpts) {
			},
			deslect: function (grid, record, index, eOpts) {
			},
		},
	}
);

// 라우팅 그리드
var MCN_networkRouteGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkRouteGrid',
		store: MCN_networkRouteStore,
		frame: true,
		title: lang_mcn_route[3],
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			listeners: {
				selectall: function () { MCN_networkRouteSelect('selectAll'); },
				deselectall: function () { MCN_networkRouteSelect('deselectAll'); }
			}
		},
		viewConfig: { forceFit: true, loadMask: true, trackOver: false },
		columns: [
			{
				flex: 1,
				dataIndex : 'Destination',
				text : lang_mcn_route[4],
				sortable: true,
				width: 70
			},
			{
				flex: 1,
				dataIndex: 'Netmask',
				text: lang_mcn_route[5],
				sortable: true,
			},
			{
				flex: 1,
				dataIndex: 'Gateway',
				text: lang_mcn_route[6],
				sortable: true,
			},
			/*
			{
				flex: 1,
				dataIndex: 'Device',
				text: lang_mcn_route[8],
				sortable: true,
			},
			*/
		],
		tbar: [
			{
				text: lang_mcn_route[9],
				id: 'MCN_networkRouteAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					MCN_networkRouteForm.getForm().reset();

					// 생성, 수정 구분
					Ext.getCmp('MCN_networkRouteOperType').setValue('create');

					// WINDOW OPEN시 동작
					MCN_networkRouteFormWindow.animateTarget = Ext.getCmp('MCN_networkRouteAddBtn');

					// 디바이스 인터페이스 리스트 가져오기
					//MCN_networkRouteFormDevice('create');

					// 라우팅 목록중 기본 게이트웨이가 있는지 확인
					Ext.getCmp('MCN_networkRouteDefaultGateway').setDisabled(false);

					MCN_networkRouteGrid.store.each(
						function (record) {
							if (record.data.Destination === 'Default GW')
							{
								Ext.getCmp('MCN_networkRouteDefaultGateway').setDisabled(true);
							}
						}
					);

					// 수정, 생성 팝업 열기
					MCN_networkRouteFormWindow.show();
				}
			},
			/*
			{
				text: lang_mcn_route[10],
				id: 'MCN_networkRouteModifyBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function () {
					MCN_networkRouteForm.getForm().reset();

					// 생성, 수정 구분
					Ext.getCmp('MCN_networkRouteOperType').setValue('modify');

					// WINDOW OPEN시 동작
					MCN_networkRouteFormWindow.animateTarget = Ext.getCmp('MCN_networkRouteModifyBtn');

					// 디바이스 인터페이스 리스트 가져오기
					//MCN_networkRouteFormDevice('modify');

					// 상세 정보 받아오기
					var selection = MCN_networkRouteGrid.getSelectionModel().getSelection();

					// 목적지
					var dest = selection[0].get('Destination');

					if (dest === 'Default GW')
					{
						Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(true);
						dest = '0.0.0.0';
					}
					else
					{
						Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(false);
						dest = dest.split(".");
					}

					Ext.getCmp('MCN_networkRouteDest1').setValue(dest[0]);
					Ext.getCmp('MCN_networkRouteDest2').setValue(dest[1]);
					Ext.getCmp('MCN_networkRouteDest3').setValue(dest[2]);
					Ext.getCmp('MCN_networkRouteDest4').setValue(dest[3]);

					// 네트워크 인터페이스
					//Ext.getCmp('MCN_networkRouteDeviceCombo')
					//	.setValue(selection[0].get('Device'));

					// 넷마스크
					var netmask = selection[0].get('Netmask').split(".");

					Ext.getCmp('MCN_networkRouteNetmask1').setValue(netmask[0]);
					Ext.getCmp('MCN_networkRouteNetmask2').setValue(netmask[1]);
					Ext.getCmp('MCN_networkRouteNetmask3').setValue(netmask[2]);
					Ext.getCmp('MCN_networkRouteNetmask4').setValue(netmask[3]);

					// 게이트 웨이
					var gateway = selection[0].get('Gateway').split(".");

					Ext.getCmp('MCN_networkRouteGateway1').setValue(gateway[0]);
					Ext.getCmp('MCN_networkRouteGateway2').setValue(gateway[1]);
					Ext.getCmp('MCN_networkRouteGateway3').setValue(gateway[2]);
					Ext.getCmp('MCN_networkRouteGateway4').setValue(gateway[3]);

					// 라우팅 목록 중 기본 게이트웨이가 있는지 확인
					Ext.getCmp('MCN_networkRouteDefaultGateway').setDisabled(false);

					MCN_networkRouteGrid.store.each(
						function (record) {
							if (record.data.Destination === 'Default GW')
							{
								Ext.getCmp('MCN_networkRouteDefaultGateway').setDisabled(true);
							}
						}
					);

					// 수정, 생성 팝업 열기
					MCN_networkRouteFormWindow.show();
				}
			},
			*/
			{
				text: lang_mcn_route[11],
				id: 'MCN_networkRouteDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mcn_route[0],
						lang_mcn_route[12],
						function (btn, text) {
							if (btn != 'yes')
								return;

							// 상세 정보 받아오기
							var selection = MCN_networkRouteGrid.getSelectionModel().getSelection();

							// 목적지
							var isgw = false;
							var dest = selection[0].get('Destination')

							if (dest === 'Default GW')
							{
								dest = '0.0.0.0';
								isgw = true;
							}

							// 넷마스크
							var netmask = selection[0].get('Netmask');

							// 게이트웨이
							var gateway = selection[0].get('Gateway');

							// 네트워크 인터페이스
							var device = selection[0].get('Device');

							waitWindow(lang_mcn_route[0], lang_mcn_route[13]);

							GMS.Ajax.request({
								url: '/api/cluster/network/route/entry/delete',
								jsonData: {
									Table: 'main',
									Default: isgw ? 1 : 0,
									To: dest + '/' + netmask_to_prefix(netmask),
									Via: gateway,
									Device: device,
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
										return;

									Ext.MessageBox.alert(lang_mcn_route[0], lang_mcn_route[14]);
									MCN_routeLoad();
								}
							});
						}
					);
				}
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				setTimeout(function () { MCN_networkRouteSelect(grid, record) }, 200);
			}
		}
	}
);

// 네트워크 영역 정보 그리드
var MCN_networkZoneGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkZoneGrid',
		title: lang_mcn_zone[3],
		store: MCN_networkZoneGridStore,
		style: { marginBottom: '20px' },
		minHeight: 300,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			showHeaderCheckbox: false,
		},
		columns: [
			{
				flex: 1,
				text: lang_mcn_zone[4],
				sortable: true,
				dataIndex: 'Name'
			},
			{
				flex: 1,
				text: lang_mcn_zone[5],
				sortable: true,
				dataIndex: 'Desc'
			},
			{
				flex: 1,
				text: lang_mcn_zone[6],
				sortable: true,
				dataIndex: 'Type',
				renderer: function (value) {
					var table = {
						addrs: lang_mcn_zone[16],
						range: lang_mcn_zone[17],
						cidr: lang_mcn_zone[18],
						domain: lang_mcn_zone[19],
					};

					return table[value];
				},
			},
			{
				flex: 1,
				text: lang_mcn_zone[7],
				sortable: true,
				dataIndex: 'Type',
				renderer: function (value, meta) {
					if (value === 'addrs')
					{
						return meta.record.get('Addrs');
					}
					else if (value == 'range')
					{
						return meta.record.get('Range');
					}
					else if (value == 'cidr')
					{
						return meta.record.get('CIDR');
					}
					else if (value == 'domain')
					{
						return meta.record.get('Domain');
					}
				},
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MCN_networkZoneSelect(record) }, 200);
			}
		},
		tbar: [
			{
				text: lang_mcn_zone[8],
				id: 'MCN_networkZoneAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					MCN_networkZoneForm.getForm().reset();
					// WINDOW OPEN 시 동작
					MCN_networkZoneFormWindow.animateTarget = Ext.getCmp('MCN_networkZoneAddBtn');
					MCN_networkZoneFormWindow.show();

					Ext.getCmp('MCN_networkZoneFormIpAddrRadio').setValue(true);

					// 생성, 수정 구분
					Ext.getCmp('MCN_networkZoneOperType').setValue('add');
				}
			},
			{
				text: lang_mcn_zone[32],
				id: 'MCN_networkZoneDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(lang_mcn_zone[0], lang_mcn_zone[9], function (btn, text) {
						if (btn !== 'yes')
							return;

						// 선택된 그리드의 전송값 추출
						var selected = MCN_networkZoneGrid.getSelectionModel().getSelection()[0];

						waitWindow(lang_mcn_zone[0], lang_mcn_zone[10]);

						GMS.Ajax.request({
							url: '/api/cluster/network/zone/delete',
							jsonData: {
								Name: selected.get('Name'),
							},
							callback: function (options, success, response, decoded) {
								if (!success || !decoded.success)
									return;

								Ext.MessageBox.alert(lang_mcn_zone[0], lang_mcn_zone[11]);
								MCN_zoneLoad();
							}
						});
					});
				}
			}
		]
	}
);

// 공유 정보 그리드
var MCN_networkZoneShareGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCN_networkZoneShareGrid',
		title: lang_mcn_zone[25],
		store: MCN_networkZoneShareGridStore,
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		},
		columns: [
			{
				flex: 1,
				text: lang_mcn_zone[4],
				sortable: true,
				dataIndex: 'Name'
			},
			{
				flex: 1,
				text: lang_mcn_zone[26],
				sortable: true,
				dataIndex: 'Used'
			},
			{
				flex: 1,
				text: lang_mcn_zone[27],
				sortable: true,
				dataIndex: 'Type'
			},
			{
				flex: 1,
				text: lang_mcn_zone[28],
				sortable: true,
				dataIndex: 'Access'
			}
		]
	}
);

/****************************************************************************
 * Forms
 ****************************************************************************/
// 서비스 IP 생성,수정 FORM
var MCN_networkVIPDescForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCN_networkVIPDescForm',
		frame: false,
		autoScroll: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				html: lang_mcn_service[2],
				border: false,
				style: { marginBottom: '30px' }
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				id: 'MCN_networkVIPInterfacePanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mcn_service[3]+': ',
						width: 130,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MCN_networkVIPInterface',
						text: 'bond1',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				id: 'MCN_networkVIPFirstIPPanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MCN_networkVIPFirstIPLabel',
						html: lang_mcn_service[28] + lang_mcn_service[14]+': ',
						width: 130,
						style: { marginTop: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPFirst1',
						name: 'serviceIPAddr',
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
									Ext.getCmp('MCN_networkVIPFirst1')
										.setValue(Ext.getCmp('MCN_networkVIPFirst1').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkVIPFirst2').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPFirst2',
						name: 'serviceIPAddr2',
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
									Ext.getCmp('MCN_networkVIPFirst2')
										.setValue(Ext.getCmp('MCN_networkVIPFirst2').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkVIPFirst3').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPFirst3',
						name: 'serviceIPAddr3',
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
									Ext.getCmp('MCN_networkVIPFirst3')
										.setValue(Ext.getCmp('MCN_networkVIPFirst3').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkVIPFirst4').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPFirst4',
						name: 'serviceIPAddr4',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '10px' }
					},
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				id: 'MCN_networkVIPLastIPPanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MCN_networkVIPLastIPLabel',
						html: lang_mcn_service[28] + lang_mcn_service[15]+': ',
						width: 130,
						style: { marginTop: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPLast1',
						name: 'serviceIPLast1',
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
									Ext.getCmp('MCN_networkVIPLast1')
										.setValue(Ext.getCmp('MCN_networkVIPLast1').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkVIPLast2').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPLast2',
						name: 'serviceIPLast2',
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
									Ext.getCmp('MCN_networkVIPLast2')
										.setValue(Ext.getCmp('MCN_networkVIPLast2').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkVIPLast3').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPLast3',
						name: 'serviceIPLast3',
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
									Ext.getCmp('MCN_networkVIPLast3')
										.setValue(Ext.getCmp('MCN_networkVIPLast3').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkVIPLast4').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkVIPLast4',
						name: 'serviceIPLast4',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '10px' }
					},
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				id: 'MCN_networkVIPNetmaskPanel',
				maskOnDisable: false,
				items: [
					{
						xtype: 'label',
						id: 'MCN_networkVIPNetmaskLabel',
						html: lang_mcn_service[28] + lang_mcn_service[5] + ': ',
						width: 130,
						style: { marginTop: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkServiceNetmask1',
						name: 'serviceNetmask1',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 2, 'MCN_networkServiceNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkServiceNetmask1')
										.setValue(Ext.getCmp('MCN_networkServiceNetmask1').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkServiceNetmask2').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkServiceNetmask2',
						name: 'serviceNetmask2',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 3, 'MCN_networkServiceNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkServiceNetmask2')
										.setValue(Ext.getCmp('MCN_networkServiceNetmask2').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkServiceNetmask3').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkServiceNetmask3',
						name: 'serviceNetmask3',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 4, 'MCN_networkServiceNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkServiceNetmask3')
										.setValue(Ext.getCmp('MCN_networkServiceNetmask3').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkServiceNetmask4').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						id: 'MCN_networkServiceNetmask4',
						name: 'serviceNetmask4',
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						style: { marginRight: '10px' }
					}
				]
			},
			{
				id: 'MCN_networkVIPOperType',
				name: 'serviceIPOperType',
				hidden : true
			},
		]
	}
);

var MCN_networkRouteForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCN_networkRouteForm',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				id: 'MCN_networkRouteFormDesc',
				border: false,
				style: { marginBottom: '30px' },
				html: lang_mcn_route[17]
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
						text: lang_mcn_route[19]+': ',
						formBind: true,
						width: 130
					},
					{
						xtype: 'checkbox',
						id: 'MCN_networkRouteDefaultGateway',
						name: 'routeDefaultGateway',
						listeners: {
							change: function (cb, nv, ov) {
								if (nv == true)
								{
									// 라우팅 목적지 초기화
									Ext.getCmp('MCN_networkRouteDest1').setValue('0');
									Ext.getCmp('MCN_networkRouteDest2').setValue('0');
									Ext.getCmp('MCN_networkRouteDest3').setValue('0');
									Ext.getCmp('MCN_networkRouteDest4').setValue('0');

									Ext.getCmp('MCN_networkRouteDest1').setDisabled(true);
									Ext.getCmp('MCN_networkRouteDest2').setDisabled(true);
									Ext.getCmp('MCN_networkRouteDest3').setDisabled(true);
									Ext.getCmp('MCN_networkRouteDest4').setDisabled(true);

									// 넷마스크 초기화
									Ext.getCmp('MCN_networkRouteNetmask1').setValue('0');
									Ext.getCmp('MCN_networkRouteNetmask2').setValue('0');
									Ext.getCmp('MCN_networkRouteNetmask3').setValue('0');
									Ext.getCmp('MCN_networkRouteNetmask4').setValue('0');

									Ext.getCmp('MCN_networkRouteNetmask1').setDisabled(true);
									Ext.getCmp('MCN_networkRouteNetmask2').setDisabled(true);
									Ext.getCmp('MCN_networkRouteNetmask3').setDisabled(true);
									Ext.getCmp('MCN_networkRouteNetmask4').setDisabled(true);
								}
								else
								{
									// 라우팅 목적지
									Ext.getCmp('MCN_networkRouteDest1').setValue();
									Ext.getCmp('MCN_networkRouteDest2').setValue();
									Ext.getCmp('MCN_networkRouteDest3').setValue();
									Ext.getCmp('MCN_networkRouteDest4').setValue();

									Ext.getCmp('MCN_networkRouteDest1').setDisabled(false);
									Ext.getCmp('MCN_networkRouteDest2').setDisabled(false);
									Ext.getCmp('MCN_networkRouteDest3').setDisabled(false);
									Ext.getCmp('MCN_networkRouteDest4').setDisabled(false);

									// 넷마스크 초기화
									Ext.getCmp('MCN_networkRouteNetmask1').setDisabled(false);
									Ext.getCmp('MCN_networkRouteNetmask2').setDisabled(false);
									Ext.getCmp('MCN_networkRouteNetmask3').setDisabled(false);
									Ext.getCmp('MCN_networkRouteNetmask4').setDisabled(false);
								}
							}
						}
					}
				]
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
						id: 'MCN_networkRouteDestAddrLable',
						text: lang_mcn_route[18]+': ',
						formBind: true,
						width: 130
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						id: 'MCN_networkRouteDest1',
						name: 'routeDest1',
						width: 55,
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteDest1')
										.setValue(Ext.getCmp('MCN_networkRouteDest1').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteDest2').focus();
								}

								var Dest1Check = Ext.getCmp('MCN_networkRouteDest1').getValue();
								var Dest2Check = Ext.getCmp('MCN_networkRouteDest2').getValue();
								var Dest3Check = Ext.getCmp('MCN_networkRouteDest3').getValue();
								var Dest4Check = Ext.getCmp('MCN_networkRouteDest4').getValue();

								if (Dest1Check == '0' && Dest2Check == '0' && Dest3Check == '0' && Dest4Check == '0')
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(true);
								}
								else
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(false);
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						width: 55,
						id: 'MCN_networkRouteDest2',
						name: 'routeDest2',
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						enableKeyEvents: true,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteDest2')
										.setValue(Ext.getCmp('MCN_networkRouteDest2').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteDest3').focus();
								}

								var Dest1Check = Ext.getCmp('MCN_networkRouteDest1').getValue();
								var Dest2Check = Ext.getCmp('MCN_networkRouteDest2').getValue();
								var Dest3Check = Ext.getCmp('MCN_networkRouteDest3').getValue();
								var Dest4Check = Ext.getCmp('MCN_networkRouteDest4').getValue();

								if (Dest1Check == '0' && Dest2Check == '0' && Dest3Check == '0' && Dest4Check == '0')
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(true);
								}
								else
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(false);
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						width: 55,
						id: 'MCN_networkRouteDest3',
						name: 'routeDest3',
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						enableKeyEvents: true,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteDest3')
										.setValue(Ext.getCmp('MCN_networkRouteDest3').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteDest4').focus();
								}

								var Dest1Check = Ext.getCmp('MCN_networkRouteDest1').getValue();
								var Dest2Check = Ext.getCmp('MCN_networkRouteDest2').getValue();
								var Dest3Check = Ext.getCmp('MCN_networkRouteDest3').getValue();
								var Dest4Check = Ext.getCmp('MCN_networkRouteDest4').getValue();

								if (Dest1Check == '0' && Dest2Check == '0' && Dest3Check == '0' && Dest4Check == '0')
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(true);
								}
								else
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(false);
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						width: 55,
						id: 'MCN_networkRouteDest4',
						name: 'routeDest4',
						allowBlank: false,
						vtype: 'reg_IP',
						msgTarget: 'side',
						enableKeyEvents: true,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								var Dest1Check = Ext.getCmp('MCN_networkRouteDest1').getValue();
								var Dest2Check = Ext.getCmp('MCN_networkRouteDest2').getValue();
								var Dest3Check = Ext.getCmp('MCN_networkRouteDest3').getValue();
								var Dest4Check = Ext.getCmp('MCN_networkRouteDest4').getValue();

								if (Dest1Check == '0' && Dest2Check == '0' && Dest3Check == '0' && Dest4Check == '0')
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(true);
								}
								else
								{
									Ext.getCmp('MCN_networkRouteDefaultGateway').setValue(false);
								}
							}
						}
					}
				]
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
						id: 'MCN_networkRouteNetmaskLable',
						text: lang_mcn_route[5]+': ',
						formBind: true,
						width: 130
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						id: 'MCN_networkRouteNetmask1',
						name: 'routeNetmask1',
						enableKeyEvents: true,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						allowBlank: false,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 2, 'MCN_networkRouteNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteNetmask1')
										.setValue(Ext.getCmp('MCN_networkRouteNetmask1').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteNetmask2').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						id: 'MCN_networkRouteNetmask2',
						name: 'routeNetmask2',
						enableKeyEvents: true,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						allowBlank: false,
						hideLabel: true,
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 3, 'MCN_networkRouteNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteNetmask2')
										.setValue(Ext.getCmp('MCN_networkRouteNetmask2').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteNetmask3').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						id: 'MCN_networkRouteNetmask3',
						name: 'routeNetmask3',
						enableKeyEvents: true,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						allowBlank: false,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								netMaskInput(form.getValue(), 4, 'MCN_networkRouteNetmask');

								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteNetmask3')
										.setValue(Ext.getCmp('MCN_networkRouteNetmask3').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteNetmask4').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						id: 'MCN_networkRouteNetmask4',
						name: 'routeNetmask4',
						enableKeyEvents: true,
						vtype: 'reg_NETMASK',
						msgTarget: 'side',
						hideLabel: true,
						width: 55,
						allowBlank: false,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (Ext.getCmp('MCN_networkRouteNetmask3').getValue() == '')
								{
									Ext.getCmp('MCN_networkRouteNetmask4').setValue();
									Ext.getCmp('MCN_networkRouteNetmask3').focus();
								}
								else if (Ext.getCmp('MCN_networkRouteNetmask3').getValue() == 0)
								{
									Ext.getCmp('MCN_networkRouteNetmask4').setValue(0);
								}
							}
						}
					}
				]
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
						id: 'MCN_networkRouteGatewayLable',
						text: lang_mcn_route[6]+': ',
						formBind: true,
						width: 130
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						id: 'MCN_networkRouteGateway1',
						name: 'routeGateway1',
						enableKeyEvents: true,
						vtype: 'reg_IP',
						msgTarget: 'side',
						width: 55,
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteGateway1')
										.setValue(Ext.getCmp('MCN_networkRouteGateway1').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteGateway2').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						width: 55,
						id: 'MCN_networkRouteGateway2',
						name: 'routeGateway2',
						enableKeyEvents: true,
						vtype: 'reg_IP',
						msgTarget: 'side',
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteGateway2')
										.setValue(Ext.getCmp('MCN_networkRouteGateway2').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteGateway3').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						width: 55,
						id: 'MCN_networkRouteGateway3',
						name: 'routeGateway3',
						enableKeyEvents: true,
						vtype: 'reg_IP',
						msgTarget: 'side',
						style: { marginRight: '5px' },
						listeners : {
							keyup: function (form, e) {
								if (e.getKey() == 190 || e.getKey() == 110)
								{
									Ext.getCmp('MCN_networkRouteGateway3')
										.setValue(Ext.getCmp('MCN_networkRouteGateway3').getValue().replace(".", ""));
									Ext.getCmp('MCN_networkRouteGateway4').focus();
								}
							}
						}
					},
					{
						xtype: 'label',
						text: ' . ',
						style: { marginTop:'10px',marginRight: '5px' },
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'textfield',
						hideLabel: true,
						width: 55,
						id: 'MCN_networkRouteGateway4',
						name: 'routeGateway4',
						enableKeyEvents: true,
						vtype: 'reg_IP',
						msgTarget: 'side',
						style: { marginRight: '5px' }
					}
				]
			},
			/*
			{
				xtype: 'BaseComboBox',
				id: 'MCN_networkRouteDeviceCombo',
				name: 'routeDeviceCombo',
				fieldLabel: lang_mcn_route[20],
				labelWidth: 125,
				width: 320,
				store: MCN_networkDeviceStore,
				displayField: 'Device',
				valueField: 'Device',
				style: { marginBottom: '20px' }
			},
			*/
			{
				id: 'MCN_networkRouteOperType',
				name: 'routeOperType',
				value: 'create',
				hidden : true
			}
		]
	}
);

// DNS
var MCN_networkDNS = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCN_networkDNS',
		title: lang_mcn_dns[2],
		frame: true,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				border: false,
				style: { marginBottom: '30px' },
				html: lang_mcn_dns[3]
			},
			{
				xtype: 'textfield',
				fieldLabel: lang_mcn_dns[5],
				id: 'MCN_networkDNSEntry1',
				name: 'infoDns1',
				vtype: 'reg_HOSTNAME',
				style: { marginBottom: '20px' },
				labelWidth: 130,
				inputWidth: 245
			},
			{
				xtype: 'textfield',
				fieldLabel: lang_mcn_dns[6],
				id: 'MCN_networkDNSEntry2',
				name: 'infoDns2',
				vtype: 'reg_HOSTNAME',
				style: { marginBottom: '20px' },
				labelWidth: 130,
				labelStyle: 'white-space: nowrap;',
				inputWidth: 245
			}
		],
		buttonAlign: 'left',
		buttons: [
			{
				text: lang_mcn_dns[7],
				id: 'MCN_networkDNSBtn',
				handler: function () {
					if (!Ext.getCmp('MCN_networkDNS').getForm().isValid())
						return false;

					waitWindow(lang_mcn_dns[0], lang_mcn_dns[12]);

					GMS.Ajax.request({
						url: '/api/cluster/network/dns/update',
						jsonData: [
							Ext.getCmp('MCN_networkDNSEntry1').getValue(),
							Ext.getCmp('MCN_networkDNSEntry2').getValue()
						],
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							// 성공 알림 창
							Ext.MessageBox.alert(lang_mcn_dns[0], lang_mcn_dns[16]);
							MCN_dnsLoad();
						}
					});
				}
			}
		]
	}
);

// 네트워크 영역 설정 폼: 생성
var MCN_networkZoneForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCN_networkZoneForm',
		frame: false,
		autoScroll: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				id: 'MCN_networkZoneFormDesc',
				border: false,
				style: { marginBottom: '30px' },
				html: lang_mcn_zone[13]
			},
			{
				xtype: 'textfield',
				id: 'MCN_networkZoneFormName',
				name: 'zoneFormName',
				fieldLabel: lang_mcn_zone[4],
				labelWidth: 125,
				allowBlank: false,
				vtype: 'reg_zoneFormName',
				style: { marginBottom: '20px' }
			},
			{
				xtype: 'textfield',
				id: 'MCN_networkZoneFormDesc',
				name: 'zoneFormDesc',
				fieldLabel: lang_mcn_zone[5],
				labelWidth: 125,
				vtype: 'reg_DESC',
				style: { marginBottom: '20px' }
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				maskOnDisable: false,
				items: [
					{
						xtype: 'radiofield',
						id: 'MCN_networkZoneFormIpAddrRadio',
						name: 'zoneFormRadio',
						boxLabel: lang_mcn_zone[16] + ': ',
						width: 130,
						inputValue: 'ip',
						listeners: {
							change: function () {
								var me = this;

								Ext.Array.forEach(
									Ext.getCmp('MCN_networkZoneFormIPAddrPanel').query('.field, .button, .label'),
									function (c) {
										c.setDisabled(!me.getValue());
									}
								);
							}
						}
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						layout: 'hbox',
						id: 'MCN_networkZoneFormIPAddrPanel',
						maskOnDisable: false,
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'textfield',
								hideLabel: true,
								id: 'MCN_networkZoneFormIpAddr1_1',
								name: 'zoneFormIpAddr1_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIpAddr1_1')
												.setValue(Ext.getCmp('MCN_networkZoneFormIpAddr1_1')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIpAddr1_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIpAddr1_2',
								name: 'zoneFormIpAddr1_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIpAddr1_2')
												.setValue(Ext.getCmp('MCN_networkZoneFormIpAddr1_2')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIpAddr1_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIpAddr1_3',
								name: 'zoneFormIpAddr1_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIpAddr1_3')
												.setValue(Ext.getCmp('MCN_networkZoneFormIpAddr1_3')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIpAddr1_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIpAddr1_4',
								name: 'zoneFormIpAddr1_4',
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' }
							}
						]
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
						xtype: 'radiofield',
						id: 'MCN_networkZoneFormIPAddrRangeRadio',
						name: 'zoneFormRadio',
						boxLabel: lang_mcn_zone[17] + ': ',
						width: 130,
						inputValue: 'range',
						listeners: {
							change: function () {
								var me = this;

								Ext.Array.forEach(
									Ext.getCmp('MCN_networkZoneFormIPAddrRangePanel').query('.field, .button, .label'),
									function (c) {
										c.setDisabled(!me.getValue());
									}
								);
							}
						}
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						layout: 'hbox',
						id: 'MCN_networkZoneFormIPAddrRangePanel',
						maskOnDisable: false,
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'textfield',
								hideLabel: true,
								id: 'MCN_networkZoneFormIPAddrRangeFrom_1',
								name: 'zoneFormIPAddrRangeFrom_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_1')
												.setValue(Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_1')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIPAddrRangeFrom_2',
								name: 'zoneFormIPAddrRangeFrom_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_2')
												.setValue(Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_2')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIPAddrRangeFrom_3',
								name: 'zoneFormIPAddrRangeFrom_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_3')
												.setValue(Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_3')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIPAddrRangeFrom_4',
								name: 'zoneFormIPAddrRangeFrom_4',
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '10px' }
							},
							{
								xtype: 'label',
								text: '~',
								width: 20,
								style: { marginTop: '5px', marginLeft: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								id: 'MCN_networkZoneFormIPAddrRangeTo_1',
								name: 'zoneFormIPAddrRangeTo_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_1')
												.setValue(Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_1')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIPAddrRangeTo_2',
								name: 'zoneFormIPAddrRangeTo_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_2')
												.setValue(Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_2')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIPAddrRangeTo_3',
								name: 'zoneFormIPAddrRangeTo_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_3')
												.setValue(Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_3')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCN_networkZoneFormIPAddrRangeTo_4',
								name: 'zoneFormIPAddrRangeTo_4',
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '10px' }
							},
						]
					},
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				maskOnDisable: false,
				items: [
					{
						xtype: 'radiofield',
						checked: false,
						boxLabel: lang_mcn_zone[18] + ': ',
						width: 130,
						id: 'MCN_networkZoneFormNetworkRadio',
						name: 'zoneFormRadio',
						inputValue: 'network',
						listeners: {
							change: function () {
								var me = this;

								Ext.Array.forEach(
									Ext.getCmp('MCN_networkZoneFormNetworkPanel').query('.field, .button, .label'),
									function (c) {
										c.setDisabled(!me.getValue());
									}
								);
							}
						}
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						layout: 'hbox',
						id: 'MCN_networkZoneFormNetworkPanel',
						maskOnDisable: false,
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetwork_1',
								name: 'zoneFormNetwork_1',
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
											Ext.getCmp('MCN_networkZoneFormNetwork_1')
												.setValue(Ext.getCmp('MCN_networkZoneFormNetwork_1')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormNetwork_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetwork_2',
								name: 'zoneFormNetwork_2',
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
											Ext.getCmp('MCN_networkZoneFormNetwork_2')
												.setValue(Ext.getCmp('MCN_networkZoneFormNetwork_2')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormNetwork_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetwork_3',
								name: 'zoneFormNetwork_3',
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
											Ext.getCmp('MCN_networkZoneFormNetwork_3')
												.setValue(Ext.getCmp('MCN_networkZoneFormNetwork_3')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormNetwork_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetwork_4',
								name: 'zoneFormNetwork_4',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' }
							},
							{
								xtype: 'label',
								id: 'MCN_networkZoneFormNetworkSection',
								text: '/',
								width: 20,
								style: { marginTop: '5px', marginLeft: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetmask_1',
								name: 'zoneFormNetmask_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										netMaskInput(form.getValue(), 2, 'MCN_networkZoneFormNetmask_');

										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormNetmask_1')
												.setValue(Ext.getCmp('MCN_networkZoneFormNetmask_1')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormNetmask_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetmask_2',
								name: 'zoneFormNetmask_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										netMaskInput(form.getValue(), 3, 'MCN_networkZoneFormNetmask_');

										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormNetmask_2')
												.setValue(Ext.getCmp('MCN_networkZoneFormNetmask_2')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormNetmask_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px',marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetmask_3',
								name: 'zoneFormNetmask_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										netMaskInput(form.getValue(), 4, 'MCN_networkZoneFormNetmask_');

										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCN_networkZoneFormNetmask_3')
												.setValue(Ext.getCmp('MCN_networkZoneFormNetmask_3')
												.getValue()
												.replace(".", ""));

											Ext.getCmp('MCN_networkZoneFormNetmask_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: { marginTop:'10px', marginRight: '5px' },
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormNetmask_4',
								name: 'zoneFormNetmask_4',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' },
								listeners : {
									keyup: function (form, e) {
										if (Ext.getCmp('MCN_networkZoneFormNetmask_3').getValue() == '')
										{
											Ext.getCmp('MCN_networkZoneFormNetmask_4').setValue();
											Ext.getCmp('MCN_networkZoneFormNetmask_3').focus();
										}
										else if (Ext.getCmp('MCN_networkZoneFormNetmask_3').getValue() == 0)
										{
											Ext.getCmp('MCN_networkZoneFormNetmask_4').setValue(0);
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
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				maskOnDisable: false,
				items: [
					{
						xtype: 'radiofield',
						checked: false,
						boxLabel: lang_mcn_zone[19] + ': ',
						width: 130,
						id: 'MCN_networkZoneFormDomainRadio',
						name: 'zoneFormRadio',
						inputValue: 'domain',
						listeners: {
							change: function () {
								var me = this;

								Ext.Array.forEach(
									Ext.getCmp('MCN_networkZoneFormDomainPanel').query('.field, .button, .label'),
									function (c) { c.setDisabled(!me.getValue()); }
								);
							}
						}
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						layout: 'hbox',
						id: 'MCN_networkZoneFormDomainPanel',
						maskOnDisable: false,
						items: [
							{
								xtype: 'textfield',
								id: 'MCN_networkZoneFormDomain',
								name: 'zoneFormDomain',
								hideLabel: true,
								width: 200,
								vtype: 'reg_DOMAIN',
								style: { marginRight: '10px' }
							}
						]
					}
				]
			},
			{
				id: 'MCN_networkZoneOperType',
				name: 'zoneOperType',
				hidden : true
			}
		]
	}
);

/****************************************************************************
 * Windows
 ****************************************************************************/

// 서비스 IP 생성, 수정 윈도우
var MCN_networkVIPDescWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCN_networkVIPDescWindow',
		layout: 'fit',
		title: lang_mcn_service[12],
		width: 550,
		items: [ MCN_networkVIPDescForm ],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_mcn_service[6],
				id: 'MCN_networkVIPSaveBtn',
				handler: function () {
					// 넷마스크의 null 허용하지 않음
					Ext.getCmp('MCN_networkServiceNetmask1').allowBlank = false;
					Ext.getCmp('MCN_networkServiceNetmask2').allowBlank = false;
					Ext.getCmp('MCN_networkServiceNetmask3').allowBlank = false;
					Ext.getCmp('MCN_networkServiceNetmask4').allowBlank = false;

					if (!Ext.getCmp('MCN_networkVIPDescForm').getForm().isValid())
						return false;

					if (waitMsgBox)
					{
						// 데이터 전송 완료 후 wait 제거
						waitMsgBox.hide();
						waitMsgBox = null;
					}

					var opertype = Ext.getCmp('MCN_networkVIPOperType').getValue();
					var setUrl;
					var returnMsg;

					if (opertype == 'create')
					{
						waitWindow(lang_mcn_service[0], lang_mcn_service[8]);
						setUrl = '/api/cluster/network/vip/create';
						returnMsg = lang_mcn_service[10];
					}
					else if (opertype == 'modify')
					{
						waitWindow(lang_mcn_service[0], lang_mcn_service[9]);
						setUrl = '/api/cluster/network/vip/update';
						returnMsg = lang_mcn_service[30];
					}

					var first = Ext.getCmp('MCN_networkVIPFirst1').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkVIPFirst2').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkVIPFirst3').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkVIPFirst4').getValue();

					var last = Ext.getCmp('MCN_networkVIPLast1').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkVIPLast2').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkVIPLast3').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkVIPLast4').getValue();

					var netmask = Ext.getCmp('MCN_networkServiceNetmask1').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkServiceNetmask2').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkServiceNetmask3').getValue()
								+ '.'
								+ Ext.getCmp('MCN_networkServiceNetmask4').getValue();

					GMS.Ajax.request({
						url: setUrl,
						jsonData: {
							Interface: Ext.getCmp('MCN_networkVIPInterface').text,
							IPAddrs: [first + '-' + last + '/' + netmask_to_prefix(netmask)],
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							MCN_networkVIPDescWindow.hide();
							Ext.MessageBox.alert(lang_mcn_service[0], decoded.msg);
							MCN_serviceLoad();
						}
					});
				}
			}
		]
	}
);

// 라우팅 설정 윈도우
var MCN_networkRouteFormWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCN_networkRouteFormWindow',
		title: lang_mcn_route[0],
		layout: 'fit',
		width: 500,
		items: [ MCN_networkRouteForm ],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_mcn_route[21],
				id: 'MCN_networkRouteSetBtn',
				handler: function () {
					Ext.getCmp('MCN_networkRouteNetmask1').allowBlank = false;
					Ext.getCmp('MCN_networkRouteNetmask2').allowBlank = false;
					Ext.getCmp('MCN_networkRouteNetmask3').allowBlank = false;
					Ext.getCmp('MCN_networkRouteNetmask4').allowBlank = false;

					var defaultgw = Ext.getCmp('MCN_networkRouteDefaultGateway').getValue();
					var defaultgwexist = false;

					// 라우팅 목록 중 기본 게이트웨이가 있는지 확인
					MCN_networkRouteGrid.store.each(
						function (record) {
							if (record.get('Destination') == 'Default GW'
								&& defaultgw == true)
							{
								// 기본 게이트웨이가 있을 경우 생성하지 못함
								defaultgwexist = true;
							}
						}
					);

					var Gateway1 = Ext.getCmp('MCN_networkRouteGateway1').getValue();
					var Gateway2 = Ext.getCmp('MCN_networkRouteGateway2').getValue();
					var Gateway3 = Ext.getCmp('MCN_networkRouteGateway3').getValue();
					var Gateway4 = Ext.getCmp('MCN_networkRouteGateway4').getValue();

					if (Gateway1 == '' && Gateway2 == ''
						&& Gateway3 == '' && Gateway4 == '')
					{
						Ext.MessageBox.alert(lang_mcn_route[0], lang_mcn_route[17]);
						return false;
					}

					var Gateway = Gateway1
								+ '.' + Gateway2
								+ '.' + Gateway3
								+ '.' + Gateway4;

					var Dest1 = Ext.getCmp('MCN_networkRouteDest1').getValue();
					var Dest2 = Ext.getCmp('MCN_networkRouteDest2').getValue();
					var Dest3 = Ext.getCmp('MCN_networkRouteDest3').getValue();
					var Dest4 = Ext.getCmp('MCN_networkRouteDest4').getValue();

					if (Dest1 == '' || Dest2 == ''
						|| Dest3 == '' || Dest4 == '')
					{
						Ext.MessageBox.alert(lang_mcn_route[0], lang_mcn_route[17]);
						return false;
					}

					var Dest = Dest1
							+ '.' + Dest2
							+ '.' + Dest3
							+ '.' + Dest4;

					var Netmask1 = Ext.getCmp('MCN_networkRouteNetmask1').getValue();
					var Netmask2 = Ext.getCmp('MCN_networkRouteNetmask2').getValue();
					var Netmask3 = Ext.getCmp('MCN_networkRouteNetmask3').getValue();
					var Netmask4 = Ext.getCmp('MCN_networkRouteNetmask4').getValue();

					if (Netmask1 == '' || Netmask2 == ''
						|| Netmask3 == '' || Netmask4 == '')
					{
						Ext.MessageBox.alert(lang_mcn_route[0], lang_mcn_route[17]);
						return false;
					}

					var Netmask = Netmask1
							+ '.' + Netmask2
							+ '.' + Netmask3
							+ '.' + Netmask4;

					var opertype = Ext.getCmp('MCN_networkRouteOperType').getValue();
					var reqUrl;

					if (opertype === 'create')
					{
						if (defaultgwexist === true)
						{
							Ext.MessageBox.alert(lang_mcn_route[0], lang_mcn_route[22]);
							return false;
						}

						reqUrl = '/api/cluster/network/route/entry/create';

						waitWindow(lang_mcn_route[0], lang_mcn_route[23]);
					}
					else if (opertype === 'modify')
					{
						// 상세 정보 받아오기
						var selection = MCN_networkRouteGrid.getSelectionModel().getSelection();

						// 목적지
						var dest = selection[0].get('Destination');

						if (dest !== 'Default GW' && defaultgwexist === true)
						{
							// 기본 게이트웨이가 있는데 기본 게이트웨이를 만들려고 함
							Ext.MessageBox.alert(lang_mcn_route[0], lang_mcn_route[22]);
							return false;
						}

						// 기본 게이트웨이 수정
						reqUrl = '/api/cluster/network/route/entry/update';

						waitWindow(lang_mcn_route[0], lang_mcn_route[24]);
					}

					GMS.Ajax.request({
						url: reqUrl,
						method: 'POST',
						jsonData: {
							To: Dest + '/' + netmask_to_prefix(Netmask),
							Via: Gateway,
							//Device: Ext.getCmp('MCN_networkRouteDeviceCombo').getValue(),
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							// 라우트 정보 로드
							MCN_routeLoad();

							// 팝업 창 닫기
							MCN_networkRouteFormWindow.hide();

							// 성공 알림 창
							var msg = decoded.msg || lang_mcn_route[25];

							Ext.MessageBox.alert(lang_mcn_route[0], msg);
						}
					});
				}
			}
		]
	}
);

// 네트워크 영역 설정 폼 윈도우
var MCN_networkZoneFormWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MCN_networkZoneFormWindow',
		title: lang_mcn_zone[24],
		layout: 'fit',
		items: [ MCN_networkZoneForm ],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_mcn_zone[20],
				id: 'MCN_networkZoneFormBtn',
				handler: function () {
					// 넷마스크의 null 허용하지 않음
					Ext.getCmp('MCN_networkZoneFormNetmask_1').allowBlank = false;
					Ext.getCmp('MCN_networkZoneFormNetmask_2').allowBlank = false;
					Ext.getCmp('MCN_networkZoneFormNetmask_3').allowBlank = false;
					Ext.getCmp('MCN_networkZoneFormNetmask_4').allowBlank = false;

					if (!MCN_networkZoneForm.getForm().isValid())
						return false;

					// 예외 처리
					if (Ext.getCmp('MCN_networkZoneFormIPAddrRangeRadio').getValue() == true)
					{
						/*
						if (Number(Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_4').getValue())
							> Number(Ext.getCmp('MCN_networkZoneFormIPAddrRange2_4').getValue()))
						{
							Ext.MessageBox.alert(lang_mcn_zone[0], lang_mcn_zone[31]);
							return false;
						}
						*/
					}

					var zoneForm = Ext.getCmp('MCN_networkZoneFormDomainRadio').getGroupValue();
					var params   = getZoneEntity(zoneForm);

					waitWindow(lang_mcn_zone[0], lang_mcn_zone[21]);

					GMS.Ajax.request({
						url: '/api/cluster/network/zone/create',
						jsonData: params,
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							// 성공 알림 창
							Ext.MessageBox.alert(lang_mcn_zone[0], lang_mcn_zone[22]);

							// 네트워크 영역 그리드 로드
							MCN_zoneLoad();

							// 팝업 창 닫기
							MCN_networkZoneFormWindow.hide();
						}
					});
				}
			}
		]
	}
);

/****************************************************************************
 * Functions
 ****************************************************************************/
// 서비스 IP 목록 로드
function MCN_serviceLoad()
{
	// 서비스 IP 목록 버튼 컨트롤
	//Ext.getCmp('MCN_networkVIPModifyBtn').setDisabled(true);
	//Ext.getCmp('MCN_networkVIPDeleteBtn').setDisabled(true);

	Ext.getCmp('MCN_networkVIPGroupUpdateBtn').setDisabled(true);
	Ext.getCmp('MCN_networkVIPGroupDeleteBtn').setDisabled(true);
	Ext.getCmp('MCN_networkVIPAddrAddBtn').setDisabled(true);
	Ext.getCmp('MCN_networkVIPAddrRemoveBtn').setDisabled(true);

	// 서비스 IP 데이터 로드
	MCN_networkVIPGridStore.load();
	MCN_networkVIPGroupStore.load();
	MCN_networkVIPAddrStore.load();
}

// 라우팅 목록 로드
function MCN_routeLoad()
{
	// 라우팅 목록 버튼 컨트롤
	//Ext.getCmp('MCN_networkRouteModifyBtn').setDisabled(true);
	Ext.getCmp('MCN_networkRouteDelBtn').setDisabled(true);

	// 네트워크 영역 목록 버튼 컨트롤
	Ext.getCmp('MCN_networkZoneDelBtn').setDisabled(true);

	// 라우팅 데이터 로드
	MCN_networkRouteStore.load();
}

// DNS 정보 로드
function MCN_dnsLoad()
{
	// 네트워크 일반 설정 마스크 표시
	var dnsLoadMask = new Ext.LoadMask(
		Ext.getCmp('MCN_networkDNS'),
		{ msg: (lang_mcn_dns[15]) }
	);

	dnsLoadMask.show();

	// 초기화
	Ext.getCmp('MCN_networkDNS').getForm().reset();

	// DNS 데이터 로드
	MCN_networkDNSStore.load({
		callback: function (records, operation, success) {
			if (!success)
				return;

			// 마스크 제거
			dnsLoadMask.hide();

			var entries = [];

			records.forEach(
				function (v) {
					entries.push(v.get('IPAddr') ? v.get('IPAddr') : '');
				}
			);

			Ext.getCmp('MCN_networkDNSEntry1').setValue(entries[0]);
			Ext.getCmp('MCN_networkDNSEntry2').setValue(entries[1]);
		}
	});
}

// 네트워크 영역, 공유 정보 로드
function MCN_zoneLoad()
{
	// 네트워크 영역 정보 마스크 표시
	var zoneLoadMask = new Ext.LoadMask(
		Ext.getCmp('MCN_networkZoneGrid'),
		{ msg:(lang_mcn_zone[33]) }
	);

	zoneLoadMask.show();

	// 네트워크 영역 데이터 로드
	Ext.Array.forEach(
		Ext.getCmp('MCN_networkZoneFormIPAddrPanel').query('.field, .button, .label'),
		function (c) { c.setDisabled(false); }
	);

	Ext.Array.forEach(
		Ext.getCmp('MCN_networkZoneFormIPAddrRangePanel').query('.field, .button, .label'),
		function (c) { c.setDisabled(true); }
	);

	Ext.Array.forEach(
		Ext.getCmp('MCN_networkZoneFormNetworkPanel').query('.field, .button, .label'),
		function (c) { c.setDisabled(true); }
	);

	Ext.Array.forEach(
		Ext.getCmp('MCN_networkZoneFormDomainPanel').query('.field, .button, .label'),
		function (c) { c.setDisabled(true); }
	);

	MCN_networkZoneGridStore.removeAll();
	MCN_networkZoneShareGridStore.removeAll();

	GMS.Ajax.request({
		url: '/api/cluster/network/zone/list',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			zoneLoadMask.hide();

			if (!success || !decoded.success)
				return;

			// 네트워크 영역 정보
			MCN_networkZoneGridStore.loadRawData(decoded.entity);
		}
	});

	// 공유 정보 마스크 표시
	//var shareLoadMask = new Ext.LoadMask(Ext.getCmp('MCN_networkZoneShareGrid'),{msg:(lang_mcn_zone[33])});
	//shareLoadMask.show();

	/*
	GMS.Ajax.requesst({
		url: '/api/cluster/share/list',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			shareLoadMask.hide();

			if (!success)
				return;

			var sharezones = getShareZones(seczones);

			// 네트워크 영역 공유 정보 목록 로드
			MCN_networkZoneShareGridStore.loadRawData(decoded.entity);
		}
	});
	*/
};

function getShareZones(seczones)
{
	var sharezones = [];
	var userinfocount = 0;
	var szkey = 0;

	for (var k in seczones)
	{
		var userinfo = [];

		for (var sk in seczones[k])
		{
			if (seczones[k][sk] instanceof Array)
			{
				for (var ssk in seczones[k][sk])
				{
					sharezones.push(userinfo);
				}
			}
			else
			{
				for (var i=0; i<userinfocount; i++)
				{
					for (var ssk in seczones[k][sk])
					{
						if (seczones[k][sk][ssk] instanceof Array)
							continue;

						sharezones[szkey].push({ ssk: seczones[k][sk][ssk] });
					}

					szkey++;
				}

				userinfocount = 0;
			}
		}
	}

	return sharezones;
}

// 서비스 IP 목록 선택시 버튼 컨트롤
function MCN_networkVIPSelect(record)
{
	var selection = MCN_networkVIPGrid.getSelectionModel();

	selection.getSelection().forEach(
		function (r) {
			if (r != record)
			{
				selection.deselect(r.index);
			}
		}
	);

	// 선택한 서비스 IP 개수
	if (selection.getSelection().length)
	{
		Ext.getCmp('MCN_networkVIPModifyBtn').setDisabled(false);
		Ext.getCmp('MCN_networkVIPDeleteBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MCN_networkVIPModifyBtn').setDisabled(true);
		Ext.getCmp('MCN_networkVIPDeleteBtn').setDisabled(true);
	}
};

function MCN_networkRouteSelect(grid, record)
{
	var selection = MCN_networkRouteGrid.getSelectionModel().getSelection();

	if (selection.length > 1)
	{
		//Ext.getCmp('MCN_networkRouteModifyBtn').setDisabled(true);
		Ext.getCmp('MCN_networkRouteDelBtn').setDisabled(false);
	}
	else if (selection.length == 1)
	{
		//Ext.getCmp('MCN_networkRouteModifyBtn').setDisabled(false);
		Ext.getCmp('MCN_networkRouteDelBtn').setDisabled(false);
	}
	else
	{
		//Ext.getCmp('MCN_networkRouteModifyBtn').setDisabled(true);
		Ext.getCmp('MCN_networkRouteDelBtn').setDisabled(true);
	}

};

// 생성, 수정 팝업 시 네트워크 인터페이스 리스트 받아오기
/*
function MCN_networkRouteFormDevice(type)
{
	var wait = Ext.MessageBox.wait(lang_mcn_route[30], lang_mcn_route[0]);

	var promise_dev = GMS.Ajax.request({
		url: '/api/network/device/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return options.deferred.reject();

			options.deferred.resolve(decoded.entity);
		}
	});

	var promise_bond = GMS.Ajax.request({
		url: '/api/network/bonding/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return options.deferred.reject();

			options.deferred.resolve(decoded.entity);
		}
	});

	Ext.ux.Deferred
		.when(promise_dev, promise_bond)
		.then(
			function (responses)
			{
				var devices = [];

				Object.keys(responses).map(
					function (key)
					{
						devices = devices.concat(responses[key]);
					}
				);

				console.log(devices);

				try {
					MCN_networkDeviceStore.loadRawData(devices);

					// 생성일 때 첫번째 출력
					if (type == 'create')
					{
						var device = Ext.getCmp('MCN_networkRouteDeviceCombo');
					
						device.setValue(device.getStore().getAt(0).get(device.valueField), true);
					}

					wait.hide();
					wait = null;

					// 수정, 생성 팝업 열기
					MCN_networkRouteFormWindow.show();
				}
				catch (e) {
					console.error(e);
				}
			}
		);
};
*/

// 목록 선택 시
function MCN_networkZoneSelect(record)
{
	var selection = MCN_networkZoneGrid.getSelectionModel();

	selection.getSelection().forEach(
		function (r) {
			if (r != record)
			{
				selection.deselect(r.index);
			}
		}
	);

	// 선택한 서비스 IP 개수
	if (selection.getSelection().length)
	{
		Ext.getCmp('MCN_networkZoneDelBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MCN_networkZoneDelBtn').setDisabled(true);
	}
};

function getZoneEntity(form)
{
	var entity = {
		Name: Ext.getCmp('MCN_networkZoneFormName').getValue(),
		Desc: Ext.getCmp('MCN_networkZoneFormDesc').getValue(),
	};

	if (form == 'ip')
	{
		var ip = '';

		for (var i=1; i<=4; i++)
		{
			ip += Ext.getCmp('MCN_networkZoneFormIpAddr1_' + i).getValue();

			if (i != 4)
			{
				ip += '.';
			}
		}

		entity.Addrs = [ip];
	}
	else if (form == 'range')
	{
		var from = '',
			to   = '';

		for (var i=1; i<=4; i++)
		{
			from += Ext.getCmp('MCN_networkZoneFormIPAddrRangeFrom_' + i).getValue();
			to   += Ext.getCmp('MCN_networkZoneFormIPAddrRangeTo_' + i).getValue();

			if (i != 4)
			{
				from += '.';
				to   += '.';
			}
		}

		entity.Range = from + '-' + to;
	}
	else if (form == 'network')
	{
		var network = '',
			netmask = '';

		for (var i=1; i<=4; i++)
		{
			network += Ext.getCmp('MCN_networkZoneFormNetwork_' + i).getValue();
			netmask += Ext.getCmp('MCN_networkZoneFormNetmask_' + i).getValue();

			if (i != 4)
			{
				network += '.';
				netmask += '.';
			}
		}

		entity.CIDR = network + '/' + netmask_to_prefix(netmask);
	}
	else if (form == 'domain')
	{
		entity.Domain = Ext.getCmp('MCN_networkZoneFormDomain').getValue();
	}

	return entity;
}

// 클러스터 네트워크 설정
Ext.define(
	'/admin/js/manager_cluster_network',
	{
		extend: 'BasePanel',
		id: 'manager_cluster_network',
		load: function () {
			MCN_serviceLoad();
			Ext.getCmp('MCN_networkTab').layout.setActiveItem('MCN_networkVIPTab');
		},
		bodyStyle: 'padding: 0px;',
		items: [
			{
				xtype: 'tabpanel',
				id: 'MCN_networkTab',
				activeTab: 1,
				frame: false,
				bodyStyle: { padding: '20px' },
				border: false,
				items: [
					{
						xtype: 'BasePanel',
						title: lang_mcn_service[0],
						id: 'MCN_networkVIPTab',
						iconCls: 't-icon-network-address',
						layout: {
							type: 'hbox',
							pack: 'start',
							align: 'stretch',
						},
						bodyStyle: { padding: 0 },
						items: [
							{
								border: false,
								flex: 1,
								layout: 'fit',
								//items: MCN_networkVIPGrid,
								items: MCN_networkVIPGroupGrid,
							},
							{
								border: false,
								width: 20,
								html: '&nbsp',
							},
							{
								border: false,
								flex: 1,
								layout: 'fit',
								items: MCN_networkVIPAddrGrid,
							},
						],
					},
					/*
					{
						xtype: 'BasePanel',
						title: 'VLAN',
						id: 'MCN_networkVLANTab',
						iconCls: 't-icon-network',
						layout: {
							type: 'hbox',
							pack: 'start',
							align: 'stretch',
						},
						bodyStyle: { padding: 0 },
						items: [
							{
								flex: 1,
								layout: 'fit',
								items: MCN_networkVLANGroupGrid,
							},
							{
								border: false,
								width: 20,
								html: '&nbsp',
							},
							{
								flex: 1,
								layout: 'fit',
								items: MCN_networkVLANGroupInfoGrid,
							},
						],
					},
					*/
					{
						xtype: 'BasePanel',
						bodyStyle: { padding: 0 },
						title: lang_mcn_route[0],
						id: 'MCN_networkRouteTab',
						iconCls: 't-icon-routing',
						layout: 'fit',
						items: [ MCN_networkRouteGrid ]
					},
					{
						xtype: 'BasePanel',
						bodyStyle: { padding: 0 },
						title: 'DNS',
						id: 'MCN_networkDNSTab',
						iconCls: 't-icon-network',
						layout: 'fit',
						items: [ MCN_networkDNS ]
					},
					{
						xtype: 'BasePanel',
						bodyStyle: { padding: 0 },
						title: lang_mcn_zone[0],
						id: 'MCN_networkZoneTab',
						iconCls: 't-icon-ftp',
						layout: 'fit',
						items: [
							{
								xtype: 'BasePanel',
								layout: {
									type: 'vbox',
									align : 'stretch'
								},
								bodyStyle: 'padding: 0;',
								items: [
									{
										xtype: 'BasePanel',
										layout: 'fit',
										bodyStyle: { padding: 0 },
										items: [ MCN_networkZoneGrid ]
									},
									/*
									{
										xtype: 'BasePanel',
										layout: 'fit',
										flex: 1,
										bodyStyle: 'padding: 0;',
										items: [ MCN_networkZoneShareGrid ]
									}
									*/
								]
							}
						]
					}
				],
				listeners: {
					tabchange: function (tabPanel, newCard, oldCard) {
						if (newCard.id === 'MCN_networkVIPTab')
						{
							MCN_serviceLoad();
						}
						else if (newCard.id === 'MCN_networkRouteTab')
						{
							MCN_routeLoad();
						}
						else if (newCard.id === 'MCN_networkDNSTab')
						{
							MCN_dnsLoad();
						}
						else if (newCard.id === 'MCN_networkZoneTab')
						{
							MCN_zoneLoad();
						}
					}
				}
			}]
	}
);
