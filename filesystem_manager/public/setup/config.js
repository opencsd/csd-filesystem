Ext.Loader.setConfig(
	{
		enabled: true,
		paths: {
			'Ext.ux': '/js/libraries',
			'Ext.ux.Deferred': '/js/ext.ux.deferred/Deferred.js',
			'Ext.ux.Promise': '/js/ext.ux.deferred/Promise.js',
		},
	}
);

function MII_installLoad()
{
	waitWindow(lang_install[0], lang_install[22]);

	// 티어링 관리
	Ext.Ajax.request({
		url: '/api/network/device/list',
		method: 'POST',
		jsonData: {
			entity: {
				scope: 'NO_SLAVE|NO_LOOPBACK|NO_BOND',
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
					+ '"title": "' + lang_install[0] + '",'
					+ '"content": "' + lang_install[67] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 네트워크 장치는 최소 2개 이상 있어야함
			if (responseData.entity.length < 2)
			{
				Ext.MessageBox.show({
					title: lang_install[0],
					msg: lang_install[66],
					buttons: Ext.MessageBox.OK,
					fn: function () {
						Ext.Ajax.request({
							url: '/api/manager/sign_out',
							success: function (response) {
								locationMain();
							},
							failure: function (response) {
								alert(response.status+": "+response.statusText);
							}
						});
					}
				});

				return false;
			}

			MII_installWindow.show();
			MII_installNetworkDeviceStore.loadRawData(responseData);
		}
	});
}

// 네트워크 장치 모델
Ext.define('MII_installNetworkDeviceModel',{
	extend: 'Ext.data.Model',
	fields: ['Device', 'Model' ,'HWAddr', 'Speed', 'MTU', 'LinkStatus']
});

// 네트워크 장치 스토어
var MII_installNetworkDeviceStore = Ext.create('Ext.data.Store', {
	model: 'MII_installNetworkDeviceModel',
	actionMethods: {
		read: 'POST'
	},
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
		beforeload: function (store, operation, eOpts) {
			store.removeAll();
		}
	}
});

// 스토리지 네트워크 장치 그리드
var MII_installStorageNetworkDeviceGrid = Ext.create('BaseGridPanel', {
	id: 'MII_installStorageNetworkDeviceGrid',
	store: MII_installNetworkDeviceStore,
	multiSelect: true,
	title: lang_install[21],
	height: 280,
	selModel: {
		selType: 'checkboxmodel',
		checkOnly: 'true'
	},
	columns: [
		{
			flex: 1,
			text: lang_install[14],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Device'
		},
		{
			flex: 3,
			text: lang_install[15],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Model'
		},
		{
			flex: 1.5,
			text: lang_install[16],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'HWAddr'
		},
		{
			flex: 1,
			text: lang_install[17],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Speed'
		},
		{
			flex: 1,
			text: lang_install[18],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'MTU'
		},
		{
			flex: 1,
			text: lang_install[19],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'LinkStatus'
		}
	],
	listeners: {
		selectionchange: function (model, records) {
			MII_installServiceNetworkDeviceGrid.getView().refresh();
			MII_installServiceNetworkDeviceGrid.getSelectionModel().deselect(records);
			MII_installMgmtNetworkDeviceGrid.getView().refresh();
			MII_installMgmtNetworkDeviceGrid.getSelectionModel().deselect(records);
		}
	}
});

// 서비스 네트워크 장치 그리드
var MII_installServiceNetworkDeviceGrid = Ext.create('BaseGridPanel', {
	id: 'MII_installServiceNetworkDeviceGrid',
	store: MII_installNetworkDeviceStore,
	multiSelect: true,
	title: lang_install[37],
	height: 280,
	selModel: {
		selType: 'checkboxmodel',
		checkOnly: 'true'
	},
	columns: [
		{
			flex: 1,
			text: lang_install[14],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Device'
		},
		{
			flex: 3,
			text: lang_install[15],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Model'
		},
		{
			flex: 1.5,
			text: lang_install[16],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'HWAddr'
		},
		{
			flex: 1,
			text: lang_install[17],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Speed'
		},
		{
			flex: 1,
			text: lang_install[18],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'MTU'
		},
		{
			flex: 1,
			text: lang_install[19],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'LinkStatus'
		}
	],
	listeners: {
		selectionchange: function (model, records) {
			var selectedRecords = [];
			var selectStorageNetworkDevice = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

			for (var i=0, len=selectStorageNetworkDevice.length; i<len; i++)
			{
				selectedRecords.push(selectStorageNetworkDevice[i]);

				Ext.each(records, function (record) {
					if (record == selectStorageNetworkDevice[i])
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[68]);
						return false;
					}
				});
			}

			MII_installServiceNetworkDeviceGrid.getSelectionModel().deselect(selectedRecords);
			MII_installMgmtNetworkDeviceGrid.getView().refresh();
			MII_installMgmtNetworkDeviceGrid.getSelectionModel().deselect(records);
		}
	},
	viewConfig: {
		forceFit: true,
		getRowClass: function (record, rowIndex, p, store) {
			var selectedRecords = [];
			var selectStorageNetworkDevice = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

			for (var i=0, len=selectStorageNetworkDevice.length; i<len; i++)
			{
				if (record.data.id == selectStorageNetworkDevice[i].data.id)
				{
					return 'disabled-row-install';
				}
			}
		}
	}
});

// 관리 네트워크 장치 그리드
var MII_installMgmtNetworkDeviceGrid = Ext.create('BaseGridPanel', {
    id: 'MII_installMgmtNetworkDeviceGrid',
	store: MII_installNetworkDeviceStore,
	multiSelect: false,
	title: lang_install[39],
	height: 280,
	selModel: {
		selType: 'checkboxmodel',
		mode: 'SINGLE',
		checkOnly: 'true',
		allowDeselect: true
	},
	columns: [
		{
			flex: 1,
			text: lang_install[14],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Device'
		},
		{
			flex: 3,
			text: lang_install[15],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Model'
		},
		{
			flex: 1.5,
			text: lang_install[16],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'HWAddr'
		},
		{
			flex: 1,
			text: lang_install[17],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Speed'
		},
		{
			flex: 1,
			text: lang_install[18],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'MTU'
		},
		{
			flex: 1,
			text: lang_install[19],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'LinkStatus'
		}
	],
	listeners: {
		selectionchange: function (model, records) {
			var selectedRecords = [];
			var selectStorageNetworkDevice = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

			for (var i=0, len=selectStorageNetworkDevice.length; i<len; i++)
			{
				selectedRecords.push(selectStorageNetworkDevice[i]);

				Ext.each(records, function (record) {
					if (record == selectStorageNetworkDevice[i])
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[68]);
						return false;
					}
				});
			}

			var selectServiceNetworkDevice = MII_installServiceNetworkDeviceGrid.getSelectionModel().getSelection();

			for (var i=0, len=selectServiceNetworkDevice.length; i<len; i++)
			{
				selectedRecords.push(selectServiceNetworkDevice[i]);

				Ext.each(records, function (record) {
					if (record == selectServiceNetworkDevice[i])
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[68]);
						return false;
					}
				});
			}

			MII_installMgmtNetworkDeviceGrid.getSelectionModel().deselect(selectedRecords);
		}
	},
	viewConfig: {
		forceFit: true,
		getRowClass: function (record, rowIndex, p, store) {
			var selectedRecords = [];
			var selectStorageNetworkDevice = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

			for (var i=0, len=selectStorageNetworkDevice.length; i<len; i++)
			{
				if (record.data.id == selectStorageNetworkDevice[i].data.id)
				{
					return 'disabled-row-install';
				}
			}

			var selectServiceNetworkDevice = MII_installServiceNetworkDeviceGrid.getSelectionModel().getSelection();

			for (var i=0, len=selectServiceNetworkDevice.length; i<len; i++)
			{
				if (record.data.id == selectServiceNetworkDevice[i].data.id)
				{
					return 'disabled-row-install';
				}
			}
		}
	}
});

/*
 * 초기 설정폼: 스텝1
 */
var MII_installStep1 = Ext.create('BasePanel', {
	id: 'MII_installStep1',
	bodyStyle: 'padding:0;',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	items:[
		{
			xtype: 'image',
			src: '/admin/images/bg_wizard.jpg',
			height: 518,
			width: 150
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			flex: 1,
			items:[
				{
					xtype: 'BaseWizardTitlePanel',
					html: lang_install[4]
				},
				{
					xtype: 'BaseWizardContentPanel',
					items: [
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[5]+'(1/7)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[6]+'(2/7)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[7]+'(3/7)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[8]+'(4/7)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[9]+'(5/7)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[10]+'(6/7)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>'+lang_install[12]+'(7/7)</li>'
						}
					]
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝2
 */
var MII_installStep2 = Ext.create('BasePanel', {
	id: 'MII_installStep2',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	border: false,
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			items: [
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[5]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: lang_install[6]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[7]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[8]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[9]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[10]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[20]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items:[
						{
							xtype: 'BasePanel',
							bodyStyle: 'padding:0;',
							items: [MII_installStorageNetworkDeviceGrid]
						}
					]
				},
				{
					xtype: 'BaseWizardDescPanel',
					items: [
						{
							border: false,
							html: '[ ' + lang_install[76] + ' ]<br><br>' + lang_install[77]
						}
					]
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝3
 */
var MII_installStep3 = Ext.create('BasePanel', {
	id: 'MII_installStep3',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	border: false,
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[5] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(1);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[6]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[7]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[8]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[9]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[10]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[23]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items: [
						{
							xtype: 'radiofield',
							checked: true,
							boxLabel: 'Round-Robin(0)',
							id: 'MII_installStorageBondModeRoundRobin',
							name: 'installStorageBondModeRadio',
							inputValue: 'Round-Robin(0)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[24]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Active Backup(1)',
							id: 'MII_installStorageBondModeActiveBackup',
							name: 'installStorageBondModeRadio',
							inputValue: 'Active Backup(1)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[25]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Balance-XOR(2)',
							id: 'MII_installStorageBondModeBalanceXOR',
							name: 'installStorageBondModeRadio',
							inputValue: 'Balance-XOR(2)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[26]
						},{
							xtype: 'radiofield'
							,checked: false
							,boxLabel: 'IEEE 802.3ad(4)'
							,id: 'MII_installStorageBondModeIEEE'
							,name: 'installStorageBondModeRadio'
							,inputValue: 'IEEE 802.3ad(4)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[27]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Balance-tlb(5)',
							id: 'MII_installStorageBondModeBalanceTlb',
							name: 'installStorageBondModeRadio',
							inputValue: 'Balance-tlb(5)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[28]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Balance-alb(6)',
							id: 'MII_installStorageBondModeBalanceAlb',
							name: 'installStorageBondModeRadio',
							inputValue: 'Balance-alb(6)'
						},
						{
							border: false,
							html: lang_install[29]
						}
					]
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝4
 */
var MII_installStep4 = Ext.create('BaseFormPanel', {
	id: 'MII_installStep4',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	frame: false,
	border: false,
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[5] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(1);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[6] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(2);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[7]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[8]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[9]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[10]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[30]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items:[
						{
							xtype: 'BasePanel',
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							style: { marginBottom: '20px'},
							items: [
								{
									xtype: 'label',
									id: 'MII_installStep4IPLabel',
									html: lang_install[34] + lang_install[31]+': ',
									disabledCls: 'm-label-disable-mask',
									width: 130
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									id: 'MII_installStep4IP1_1',
									name: 'installStep4IP1_1',
									enableKeyEvents: true,
									allowBlank: false,
									vtype: 'reg_IP',
									msgTarget: 'side',
									width: 55,
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4IP1_1').setValue(Ext.getCmp('MII_installStep4IP1_1').getValue().replace(".", ""));
												Ext.getCmp('MII_installStep4IP1_2').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4IP1_2',
									name: 'installStep4IP1_2',
									enableKeyEvents: true,
									allowBlank: false,
									vtype: 'reg_IP',
									msgTarget: 'side',
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4IP1_2').setValue(Ext.getCmp('MII_installStep4IP1_2').getValue().replace(".", ""));
												Ext.getCmp('MII_installStep4IP1_3').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4IP1_3',
									name: 'installStep4IP1_3',
									enableKeyEvents: true,
									allowBlank: false,
									vtype: 'reg_IP',
									msgTarget: 'side',
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4IP1_3').setValue(Ext.getCmp('MII_installStep4IP1_3').getValue().replace(".", ""));
												Ext.getCmp('MII_installStep4IP1_4').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4IP1_4',
									name: 'installStep4IP1_4',
									allowBlank: false,
									vtype: 'reg_IP',
									msgTarget: 'side',
									style: { marginRight: '5px' }
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
									id: 'MII_installStep4NetmaskLabel',
									html: lang_install[34] + lang_install[32]+': ',
									width: 130,
									disabledCls: 'm-label-disable-mask'
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									id: 'MII_installStep4Netmask1_1',
									name: 'installStep4Netmask1_1',
									enableKeyEvents: true,
									allowBlank: false,
									vtype: 'reg_NETMASK',
									msgTarget: 'side',
									width: 55,
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											netMaskInput(form.getValue(), 2, 'MII_installStep4Netmask1_');

											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4Netmask1_1').setValue(
													Ext.getCmp('MII_installStep4Netmask1_1').getValue().replace(".", "")
												);

												Ext.getCmp('MII_installStep4Netmask1_2').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4Netmask1_2',
									name: 'installStep4Netmask1_2',
									enableKeyEvents: true,
									allowBlank: false,
									vtype: 'reg_NETMASK',
									msgTarget: 'side',
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											netMaskInput(form.getValue(), 3, 'MII_installStep4Netmask1_');

											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4Netmask1_2').setValue(
													Ext.getCmp('MII_installStep4Netmask1_2').getValue().replace(".", "")
												);

												Ext.getCmp('MII_installStep4Netmask1_3').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4Netmask1_3',
									name: 'installStep4Netmask1_3',
									enableKeyEvents: true,
									allowBlank: false,
									vtype: 'reg_NETMASK',
									msgTarget: 'side',
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											netMaskInput(form.getValue(), 4, 'MII_installStep4Netmask1_');

											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4Netmask1_3').setValue(
													Ext.getCmp('MII_installStep4Netmask1_3').getValue().replace(".", "")
												);

												Ext.getCmp('MII_installStep4Netmask1_4').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4Netmask1_4',
									name: 'installStep4Netmask1_4',
									allowBlank: false,
									vtype: 'reg_NETMASK',
									msgTarget: 'side',
									style: { marginRight: '5px' }
								}
							]
						},
						{
							xtype: 'BasePanel',
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							style: { marginBottom: '50px' },
							items: [
								{
									xtype: 'label',
									id: 'MII_installStep4GatewayLabel',
									html: lang_install[33] + ': ',
									width: 130,
									disabledCls: 'm-label-disable-mask'
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									id: 'MII_installStep4Gateway1_1',
									name: 'installStep4Gateway1_1',
									enableKeyEvents: true,
									vtype: 'reg_IP',
									msgTarget: 'side',
									width: 55,
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4Gateway1_1').setValue(Ext.getCmp('MII_installStep4Gateway1_1').getValue().replace(".", ""));
												Ext.getCmp('MII_installStep4Gateway1_2').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4Gateway1_2',
									name: 'installStep4Gateway1_2',
									enableKeyEvents: true,
									vtype: 'reg_IP',
									msgTarget: 'side',
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4Gateway1_2').setValue(Ext.getCmp('MII_installStep4Gateway1_2').getValue().replace(".", ""));
												Ext.getCmp('MII_installStep4Gateway1_3').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4Gateway1_3',
									name: 'installStep4Gateway1_3',
									enableKeyEvents: true,
									vtype: 'reg_IP',
									msgTarget: 'side',
									style: { marginRight: '5px' },
									listeners: {
										keyup: function (form, e) {
											if (e.getKey() == 190 || e.getKey() == 110)
											{
												Ext.getCmp('MII_installStep4Gateway1_3').setValue(Ext.getCmp('MII_installStep4Gateway1_3').getValue().replace(".", ""));
												Ext.getCmp('MII_installStep4Gateway1_4').focus();
											}
										}
									}
								},
								{
									xtype: 'label',
									text: ' . ',
									style: {
										marginTop:'8px',
										marginRight: '5px'
									}
								},
								{
									xtype: 'textfield',
									hideLabel: true,
									width: 55,
									id: 'MII_installStep4Gateway1_4',
									name: 'installStep4Gateway1_4',
									vtype: 'reg_IP',
									msgTarget: 'side',
									style: { marginRight: '5px' }
								}
							]
						}
					]
				}
			]
		}
	]
});

// 서비스 네트워크 장치와 관리 네트워크 장치 공용으로 사용
var MII_installStep5ServiceMgmtCommon = Ext.create('BaseFormPanel', {
	id: 'MII_installStep5ServiceMgmtCommon',
	bodyStyle: 'padding: 0;',
	frame: false,
	disabled: true,
	hidden: true,
	style: {
		marginTop: '10px',
		marginBottom: '20px'
	},
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			style: { marginBottom: '30px' },
			items: [
				{
					xtype: 'label',
					html: lang_install[71]
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
					id: 'MII_installStep5IPLabel',
					html: lang_install[34]+lang_install[31] + ': ',
					disabledCls: 'm-label-disable-mask',
					width: 130
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					id: 'MII_installStep5IP1_1',
					name: 'installStep5IP1_1',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					width: 55,
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5IP1_1').setValue(Ext.getCmp('MII_installStep5IP1_1').getValue().replace(".", ""));
								Ext.getCmp('MII_installStep5IP1_2').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5IP1_2',
					name: 'installStep5IP1_2',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5IP1_2').setValue(Ext.getCmp('MII_installStep5IP1_2').getValue().replace(".", ""));
								Ext.getCmp('MII_installStep5IP1_3').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5IP1_3',
					name: 'installStep5IP1_3',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5IP1_3').setValue(Ext.getCmp('MII_installStep5IP1_3').getValue().replace(".", ""));
								Ext.getCmp('MII_installStep5IP1_4').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5IP1_4',
					name: 'installStep5IP1_4',
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					style: {
						marginRight: '5px'
					}
				}
			]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			style: { marginBottom: '20px' },
			maskOnDisable: false,
			items: [
				{
					xtype: 'label',
					id: 'MII_installStep5NetmaskLabel',
					html: lang_install[34]+lang_install[32] + ': ',
					width: 130,
					disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					id: 'MII_installStep5Netmask1_1',
					name: 'installStep5Netmask1_1',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_NETMASK',
					msgTarget: 'side',
					width: 55,
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							netMaskInput(form.getValue(), 2, 'MII_installStep5Netmask1_');

							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5Netmask1_1').setValue(
									Ext.getCmp('MII_installStep5Netmask1_1').getValue().replace(".", "")
								);

								Ext.getCmp('MII_installStep5Netmask1_2').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5Netmask1_2',
					name: 'installStep5Netmask1_2',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_NETMASK',
					msgTarget: 'side',
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							netMaskInput(form.getValue(), 3, 'MII_installStep5Netmask1_');

							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5Netmask1_2').setValue(
									Ext.getCmp('MII_installStep5Netmask1_2').getValue().replace(".", "")
								);

								Ext.getCmp('MII_installStep5Netmask1_3').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5Netmask1_3',
					name: 'installStep5Netmask1_3',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_NETMASK',
					msgTarget: 'side',
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							netMaskInput(form.getValue(), 4, 'MII_installStep5Netmask1_');

							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5Netmask1_3').setValue(
									Ext.getCmp('MII_installStep5Netmask1_3').getValue().replace(".", "")
								);
								Ext.getCmp('MII_installStep5Netmask1_4').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5Netmask1_4',
					name: 'installStep5Netmask1_4',
					allowBlank: true,
					vtype: 'reg_NETMASK',
					msgTarget: 'side',
					style: { marginRight: '5px' }
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
					xtype: 'label',
					id: 'MII_installStep5GatewayLabel',
					html: lang_install[33] + ': ',
					width: 130,
					disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					id: 'MII_installStep5Gateway1_1',
					name: 'installStep5Gateway1_1',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					width: 55,
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5Gateway1_1').setValue(Ext.getCmp('MII_installStep5Gateway1_1').getValue().replace(".", ""));
								Ext.getCmp('MII_installStep5Gateway1_2').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5Gateway1_2',
					name: 'installStep5Gateway1_2',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5Gateway1_2').setValue(Ext.getCmp('MII_installStep5Gateway1_2').getValue().replace(".", ""));
								Ext.getCmp('MII_installStep5Gateway1_3').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5Gateway1_3',
					name: 'installStep5Gateway1_3',
					enableKeyEvents: true,
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					style: { marginRight: '5px' },
					listeners: {
						keyup: function (form, e) {
							if (e.getKey() == 190 || e.getKey() == 110)
							{
								Ext.getCmp('MII_installStep5Gateway1_3').setValue(Ext.getCmp('MII_installStep5Gateway1_3').getValue().replace(".", ""));
								Ext.getCmp('MII_installStep5Gateway1_4').focus();
							}
						}
					}
				},
				{
					xtype: 'label',
					text: ' . ',
					style: {
						marginTop: '8px',
						marginRight: '5px'
					}
				},
				{
					xtype: 'textfield',
					hideLabel: true,
					width: 55,
					id: 'MII_installStep5Gateway1_4',
					name: 'installStep5Gateway1_4',
					allowBlank: true,
					vtype: 'reg_IP',
					msgTarget: 'side',
					style: { marginRight: '5px' }
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝5
 */
var MII_installStep5 = Ext.create('BaseFormPanel', {
	id: 'MII_installStep5',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	frame: false,
	border: false,
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[5] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(1);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[6] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(2);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[7] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(3);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[8]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[9]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[10]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[36]
				},
				{
					xtype: 'BasePanel',
					bodyStyle: 'padding: 30px 30px 0px;',
					layout: {
						align: 'stretch'
					},
					items: [
						{
							xtype: 'BasePanel',
							bodyStyle: 'padding:0;',
							style: { marginBottom: '10px' },
							items: [MII_installServiceNetworkDeviceGrid]
						},
						{
							xtype: 'checkbox',
							id: 'MII_installStep5ServiceMgmtCommonCheck',
							boxLabel: lang_install[70],
							inputValue: false,
							style: { marginLeft: '250px' },
							listeners: {
								change: function () {
									if (this.getValue() == true)
									{
										Ext.getCmp('MII_installStep5ServiceMgmtCommon').show();
										Ext.getCmp('MII_installStep5ServiceMgmtCommon').enable();
										Ext.getCmp('MII_installStep5IP1_1').allowBlank = false;
										Ext.getCmp('MII_installStep5IP1_2').allowBlank = false;
										Ext.getCmp('MII_installStep5IP1_3').allowBlank = false;
										Ext.getCmp('MII_installStep5IP1_4').allowBlank = false;
										Ext.getCmp('MII_installStep5Netmask1_1').allowBlank = false;
										Ext.getCmp('MII_installStep5Netmask1_2').allowBlank = false;
										Ext.getCmp('MII_installStep5Netmask1_3').allowBlank = false;
										Ext.getCmp('MII_installStep5Netmask1_4').allowBlank = false;

										MII_installWindow.setHeight(780);
										Ext.getCmp('MII_installWindow').center();
										Ext.getCmp('MII_installWindow').show();
										Ext.getCmp('MII_installStep5Desc').show();
									}
									else
									{
										Ext.getCmp('MII_installStep5IP1_1').allowBlank = true;
										Ext.getCmp('MII_installStep5IP1_2').allowBlank = true;
										Ext.getCmp('MII_installStep5IP1_3').allowBlank = true;
										Ext.getCmp('MII_installStep5IP1_4').allowBlank = true;
										Ext.getCmp('MII_installStep5Netmask1_1').allowBlank = true;
										Ext.getCmp('MII_installStep5Netmask1_2').allowBlank = true;
										Ext.getCmp('MII_installStep5Netmask1_3').allowBlank = true;
										Ext.getCmp('MII_installStep5Netmask1_4').allowBlank = true;
										Ext.getCmp('MII_installStep5ServiceMgmtCommon').disable();
										Ext.getCmp('MII_installStep5ServiceMgmtCommon').hide();

										MII_installWindow.setHeight(580);
										Ext.getCmp('MII_installWindow').center();
										Ext.getCmp('MII_installWindow').show();
										Ext.getCmp('MII_installStep5Desc').hide();
									}
								}
							}
						},
						{
							xtype: 'BasePanel',
							bodyStyle: 'padding:0;',
							items: [MII_installStep5ServiceMgmtCommon]
						}
					]
				},
				{
					xtype: 'BaseWizardDescPanel',
					bodyStyle: 'paddingRight: 10px !important;',
					items: [
						{
							border: false,
							html: '[ ' + lang_install[78] + ' ]<br><br>' + lang_install[79]
						},
						{
							border: false,
							id: 'MII_installStep5Desc',
							hidden: true,
							html: lang_install[72]
						}
					]
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝6
 */
var MII_installStep6 = Ext.create('BaseFormPanel', {
	id: 'MII_installStep6',
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
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[5] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(1);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[6] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(2);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[7] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(3);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[8] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(4);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[9]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[10]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[47]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items: [
						{
							xtype: 'radiofield',
							checked: true,
							boxLabel: 'Round-Robin(0)',
							id: 'MII_installServiceBondModeRoundRobin',
							name: 'installServiceBondModeRadio',
							inputValue: 'Round-Robin(0)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[24]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Active Backup(1)',
							id: 'MII_installServiceBondModeActiveBackup',
							name: 'installServiceBondModeRadio',
							inputValue: 'Active Backup(1)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[25]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Balance-XOR(2)',
							id: 'MII_installServiceBondModeBalanceXOR',
							name: 'installServiceBondModeRadio',
							inputValue: 'Balance-XOR(2)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[26]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'IEEE 802.3ad(4)',
							id: 'MII_installServiceBondModeIEEE',
							name: 'installServiceBondModeRadio',
							inputValue: 'IEEE 802.3ad(4)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[27]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Balance-tlb(5)',
							id: 'MII_installServiceBondModeBalanceTlb',
							name: 'installServiceBondModeRadio',
							inputValue: 'Balance-tlb(5)'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: lang_install[28]
						},
						{
							xtype: 'radiofield',
							checked: false,
							boxLabel: 'Balance-alb(6)',
							id: 'MII_installServiceBondModeBalanceAlb',
							name: 'installServiceBondModeRadio',
							inputValue: 'Balance-alb(6)'
						},
						{
							border: false,
							html: lang_install[29]
						}
					]
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝7
 */
var MII_installStep7 = Ext.create('BasePanel', {
	id: 'MII_installStep7',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[5] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(1);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[6] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(2);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[7] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(3);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[8] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(4);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[9] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(5);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[10]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[38]
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
							items: [MII_installMgmtNetworkDeviceGrid]
						}
					]
				},
				{
					xtype: 'BaseWizardDescPanel',
					items: [
						{
							border: false,
							html: '[ ' + lang_install[80] + ' ]<br><br>' + lang_install[81]
						}
					]
				}
			]
		}
	]
});

/*
 * 초기 설정폼: 스텝10
 */
var MII_installStep10 = Ext.create('BasePanel', {
	id: 'MII_installStep10',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[5] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(1);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[6] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(2);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[7] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(3);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[8] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(4);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[9] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(5);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">' + lang_install[10] + '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MII_installWindow.layout.setActiveItem(6);
								MII_installButton('next');
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_install[12]
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
					html: lang_install[46]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items: [
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[5] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep2Label'
								}
							]
						},
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[6] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep3Label'
								}
							]
						},
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[59]+' '+lang_install[31]+": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep4LabelIP'
								}
							]
						},
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[59]+' '+lang_install[32]+": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep4LabelNetmask'
								}
							]
						},
						{
							xtype: 'BasePanel',
							id: 'MII_installStep4LabelGatewayPanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[59]+' '+lang_install[33]+": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep4LabelGateway'
								}
							]
						},
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[8] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep5Label'
								}
							]
						},
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[9] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep6Label'
								}
							]
						},
						{
							xtype: 'BasePanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[10] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep7Label'
								}
							]
						},
						{
							xtype: 'BasePanel',
							id: 'MII_installStep5LabelMgmtIPPanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[73] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep5LabelMgmtIP'
								}
							]
						},
						{
							xtype: 'BasePanel',
							id: 'MII_installStep5LabelMgmtNetmaskPanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[74] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep5LabelMgmtNetmask'
								}
							]
						},
						{
							xtype: 'BasePanel',
							id: 'MII_installStep5LabelMgmtGatewayPanel',
							style: { marginBottom: '20px' },
							bodyStyle: 'padding: 0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									text: lang_install[85] +": ",
									width: 190
								},
								{
									xtype: 'label',
									id: 'MII_installStep5LabelMgmtGateway'
								}
							]
						}
					]
				}
			]
		}
	]
});

/** 버튼 컨트롤 **/
function MII_installButton(type)
{
	if (type == 'next')
	{
		// 다음 버튼
		Ext.getCmp('MII_installWindowNextBtn').show();
		Ext.getCmp('MII_installWindowNextBtn').enable();

		// 이전 버튼
		Ext.getCmp('MII_installWindowPreBtn').show();
		Ext.getCmp('MII_installWindowPreBtn').enable();

		// 저장 버튼
		Ext.getCmp('MII_installWindowSetBtn').hide();
		Ext.getCmp('MII_installWindowSetBtn').disable();

		// 취소 버튼
		Ext.getCmp('MII_installWindowCancelBtn').show();
		Ext.getCmp('MII_installWindowCancelBtn').enable();
	}
	else if (type == 'pre')
	{
		// 다음 버튼
		Ext.getCmp('MII_installWindowNextBtn').show();
		Ext.getCmp('MII_installWindowNextBtn').enable();
		// 이전 버튼
		Ext.getCmp('MII_installWindowPreBtn').hide();
		Ext.getCmp('MII_installWindowPreBtn').disable();
		// 저장 버튼
		Ext.getCmp('MII_installWindowSetBtn').hide();
		Ext.getCmp('MII_installWindowSetBtn').disable();
		// 취소 버튼
		Ext.getCmp('MII_installWindowCancelBtn').show();
		Ext.getCmp('MII_installWindowCancelBtn').enable();
	}
	else if (type == 'set')
	{
		// 다음 버튼
		Ext.getCmp('MII_installWindowNextBtn').hide();
		Ext.getCmp('MII_installWindowNextBtn').disable();

		// 이전 버튼
		Ext.getCmp('MII_installWindowPreBtn').show();
		Ext.getCmp('MII_installWindowPreBtn').enable();

		// 저장 버튼
		Ext.getCmp('MII_installWindowSetBtn').show();
		Ext.getCmp('MII_installWindowSetBtn').enable();

		// 취소 버튼
		Ext.getCmp('MII_installWindowCancelBtn').show();
		Ext.getCmp('MII_installWindowCancelBtn').enable();
	}
};

/* 입력 내용 확인 */
function MII_installInputCheck(currentStepIndex)
{
	MII_installWindow.layout.setActiveItem(++currentStepIndex);
	MII_installButton('set');

	// 선택한 스토리지 네트워크 장치 개수
	var selectStorageNetworkDeviceCount = MII_installStorageNetworkDeviceGrid.getSelectionModel().getCount();

	// 선택한 스토리지 네트워크 장치
	var selectStorageNetworkDeviceArray = [];
	var selectStorageNetworkDevice = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

	for (var i=0, len=selectStorageNetworkDeviceCount; i<len; i++)
	{
		var DevName = selectStorageNetworkDevice[i].data.Device;
		selectStorageNetworkDeviceArray.push(DevName);
	}

	selectStorageNetworkDeviceArray.sort();

	var selectStorageNetworkDeviceString = selectStorageNetworkDeviceArray.join(',');

	Ext.getCmp('MII_installStep2Label').update(selectStorageNetworkDeviceString);

	// 선택한 스토리지 본딩 모드
	var selectStorageBondMode = Ext.ComponentQuery.query('[name=installStorageBondModeRadio]')[0].getGroupValue();
	Ext.getCmp('MII_installStep3Label').update(selectStorageBondMode);

	// 입력한 스토리지 IP 주소
	var MII_installStep4IPValue = Ext.getCmp('MII_installStep4IP1_1').getValue()
								+ '.' + Ext.getCmp('MII_installStep4IP1_2').getValue()
								+ '.' + Ext.getCmp('MII_installStep4IP1_3').getValue()
								+ '.' + Ext.getCmp('MII_installStep4IP1_4').getValue();

	Ext.getCmp('MII_installStep4LabelIP').update(MII_installStep4IPValue);

	// 입력한 스토리지 넷마스크
	var MII_installStep4NETMASKValue = Ext.getCmp('MII_installStep4Netmask1_1').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Netmask1_2').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Netmask1_3').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Netmask1_4').getValue();

	Ext.getCmp('MII_installStep4LabelNetmask').update(MII_installStep4NETMASKValue);

	// 입력한 스토리지 게이트웨이
	if (Ext.getCmp('MII_installStep4Gateway1_1').getValue() == ''
		|| Ext.getCmp('MII_installStep4Gateway1_2').getValue() == ''
		|| Ext.getCmp('MII_installStep4Gateway1_3').getValue() == ''
		|| Ext.getCmp('MII_installStep4Gateway1_4').getValue() == '')
	{
		Ext.getCmp('MII_installStep4LabelGateway').update('');
		Ext.getCmp('MII_installStep4LabelGatewayPanel').hide();
	}
	else
	{
		var MII_installStep4GatewayValue = Ext.getCmp('MII_installStep4Gateway1_1').getValue()
										+ '.' + Ext.getCmp('MII_installStep4Gateway1_2').getValue()
										+ '.' + Ext.getCmp('MII_installStep4Gateway1_3').getValue()
										+ '.' + Ext.getCmp('MII_installStep4Gateway1_4').getValue();

		Ext.getCmp('MII_installStep4LabelGateway').update(MII_installStep4GatewayValue);
		Ext.getCmp('MII_installStep4LabelGatewayPanel').show();
	}

	// 선택한 서비스 네트워크 장치 개수
	var selecServiceNetworkDeviceCount = MII_installServiceNetworkDeviceGrid.getSelectionModel().getCount();

	// 선택한 서비스 네트워크 장치
	var selectServiceNetworkDeviceArray = [];
	var selectServiceNetworkDevice = MII_installServiceNetworkDeviceGrid.getSelectionModel().getSelection();

	for (var i=0, len=selecServiceNetworkDeviceCount; i<len; i++)
	{
		var DevName = selectServiceNetworkDevice[i].data.Device;
		selectServiceNetworkDeviceArray.push(DevName);
	}

	selectServiceNetworkDeviceArray.sort();

	var selectServiceNetworkDeviceString = selectServiceNetworkDeviceArray.join(',');

	Ext.getCmp('MII_installStep5Label').update(selectServiceNetworkDeviceString);

	// 선택한 서비스 본딩 모드
	var selectServiceBondMode = Ext.ComponentQuery.query('[name=installServiceBondModeRadio]')[0].getGroupValue();
	Ext.getCmp('MII_installStep6Label').update(selectServiceBondMode);

	// 서비스 네트워크 장비와 관리 네트워크 장비를 공용으로 사용할 경우
	if (Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() == true)
	{
		// 관리 네트워크 장치
		Ext.getCmp('MII_installStep7Label').update(selectServiceNetworkDeviceString + ' ' + lang_install[75]);

		// 입력한 관리 IP 주소
		var MII_installStep4IPValue = Ext.getCmp('MII_installStep5IP1_1').getValue()
									+ '.' + Ext.getCmp('MII_installStep5IP1_2').getValue()
									+ '.' + Ext.getCmp('MII_installStep5IP1_3').getValue()
									+ '.' + Ext.getCmp('MII_installStep5IP1_4').getValue();

		// 관리 IP 주소
		Ext.getCmp('MII_installStep5LabelMgmtIPPanel').show();
		Ext.getCmp('MII_installStep5LabelMgmtIP').update(MII_installStep4IPValue);

		// 입력한 관리 넷마스크
		var MII_installStep4NETMASKValue = Ext.getCmp('MII_installStep5Netmask1_1').getValue()
										+ '.' + Ext.getCmp('MII_installStep5Netmask1_2').getValue()
										+ '.' + Ext.getCmp('MII_installStep5Netmask1_3').getValue()
										+ '.' + Ext.getCmp('MII_installStep5Netmask1_4').getValue();

		// 관리 넷마스크
		Ext.getCmp('MII_installStep5LabelMgmtNetmaskPanel').show();
		Ext.getCmp('MII_installStep5LabelMgmtNetmask').update(MII_installStep4NETMASKValue);

		// 입력한 관리 게이트웨이
		if (Ext.getCmp('MII_installStep5Gateway1_1').getValue() == ''
			|| Ext.getCmp('MII_installStep5Gateway1_2').getValue() == ''
			|| Ext.getCmp('MII_installStep5Gateway1_3').getValue() == ''
			|| Ext.getCmp('MII_installStep5Gateway1_4').getValue() == '')
		{
			Ext.getCmp('MII_installStep5LabelMgmtGatewayPanel').hide();
			Ext.getCmp('MII_installStep5LabelMgmtGateway').update('');
		}
		else
		{
			Ext.getCmp('MII_installStep5LabelMgmtGatewayPanel').show();

			var MII_installStep5MgmtGatewayValue = Ext.getCmp('MII_installStep5Gateway1_1').getValue()
												+ '.' + Ext.getCmp('MII_installStep5Gateway1_2').getValue()
												+ '.' + Ext.getCmp('MII_installStep5Gateway1_3').getValue()
												+ '.' + Ext.getCmp('MII_installStep5Gateway1_4').getValue();

			Ext.getCmp('MII_installStep5LabelMgmtGateway').update(MII_installStep5MgmtGatewayValue);
		}
	}
	else
	{
		// 선택한 관리 네트워크 장치 개수
		var selectMgmtNetworkDeviceCount = MII_installMgmtNetworkDeviceGrid.getSelectionModel().getCount();

		// 선택한 관리 네트워크 장치
		var selectMgmtNetworkDevice = MII_installMgmtNetworkDeviceGrid.getSelectionModel().getSelection();

		if (selectMgmtNetworkDeviceCount > 0)
		{
			var selectMgmtNetworkDeviceString = selectMgmtNetworkDevice[0].data.Device;
		}

		Ext.getCmp('MII_installStep7Label').update(selectMgmtNetworkDeviceString);

		// 관리 IP 주소
		Ext.getCmp('MII_installStep5LabelMgmtIP').update('');
		Ext.getCmp('MII_installStep5LabelMgmtIPPanel').hide();

		// 관리 넷마스크
		Ext.getCmp('MII_installStep5LabelMgmtNetmask').update('');
		Ext.getCmp('MII_installStep5LabelMgmtNetmaskPanel').hide();

		// 관리 게이트웨이
		Ext.getCmp('MII_installStep5LabelMgmtGateway').update('');
		Ext.getCmp('MII_installStep5LabelMgmtGatewayPanel').hide();
	}
}

var MII_installWindow = Ext.create('BaseWindowPanel', {
	id: 'MII_installWindow',
	layout: 'card',
	title: lang_install[0],
	width: 900,
	height: 580,
	autoScroll: false,
	maximizable: false,
	closable: false,
	activeItem: 0,
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep1Panel',
			items: [MII_installStep1]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep2Panel',
			items: [MII_installStep2]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep3Panel',
			items: [MII_installStep3]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep4Panel',
			items: [MII_installStep4]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep5Panel',
			items: [MII_installStep5]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep6Panel',
			items: [MII_installStep6]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep7Panel',
			items: [MII_installStep7]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MII_installStep10Panel',
			items: [MII_installStep10]
		}
	],
	fbar: [
		{
			text: lang_install[1],
			id: 'MII_installWindowCancelBtn',
			width: 70,
			handler: function () {
				Ext.MessageBox.confirm(
					lang_install[0],
					lang_install[13],
					function (btn, text) {
						if (btn != 'yes')
							return;

						Ext.Ajax.request({
							url: '/api/manager/sign_out',
							success: function (response) {
								locationMain();
							},
							failure: function (response) {
								alert(response.status+": "+response.statusText);
							}
						});
					}
				);
			}
		},
		'->',
		{
			text: lang_install[2],
			id: 'MII_installWindowPreBtn',
			width: 70,
			hidden: true,
			handler: function () {
				MII_installWindow.setHeight(580, true);

				Ext.getCmp('MII_installWindow').center();
				Ext.getCmp('MII_installWindow').show();

				var currentStepPanel = MII_installWindow.layout.activeItem;
				var currentStepIndex = MII_installWindow.items.indexOf(currentStepPanel);

				MII_installWindow.layout.setActiveItem(--currentStepIndex);

				if (currentStepIndex == 0)
				{
					MII_installButton('pre');
				}
				else if (currentStepIndex == 4
					&& Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() == true)
				{
					MII_installWindow.setHeight(780);
					Ext.getCmp('MII_installWindow').center();
					Ext.getCmp('MII_installWindow').show();
					MII_installButton('next');
				}
				else if (currentStepIndex == 6
					&& Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() == true)
				{
					MII_installWindow.layout.setActiveItem(--currentStepIndex);
					MII_installButton('next');
				}
				else
				{
					MII_installButton('next');
				}
			}
		},
		{
			text: lang_install[3],
			id: 'MII_installWindowNextBtn',
			width: 70,
			handler: function () {
				MII_installWindow.setHeight(580,true);

				Ext.getCmp('MII_installWindow').center();
				Ext.getCmp('MII_installWindow').show();

				var currentStepPanel = MII_installWindow.layout.activeItem;
				var currentStepIndex = MII_installWindow.items.indexOf(currentStepPanel);

				if (currentStepIndex == 0)
				{
					MII_installWindow.layout.setActiveItem(++currentStepIndex);
					MII_installButton('next');
				}
				else if (currentStepIndex == 1)
				{
					var StorageRecords = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

					if (StorageRecords.length <= 0)
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[48]);
					}
					else if ((MII_installStorageNetworkDeviceGrid.store.totalCount-StorageRecords.length) < 1)
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[61]);
					}
					else
					{
						MII_installServiceNetworkDeviceGrid.getView().refresh();
						MII_installWindow.layout.setActiveItem(++currentStepIndex);
						MII_installButton('next');
					}
				}
				else if (currentStepIndex == 2)
				{
					MII_installWindow.layout.setActiveItem(++currentStepIndex);
					MII_installButton('next');
				}
				else if (currentStepIndex == 3)
				{
					// 넷마스크의 null 허용하지 않음
					Ext.getCmp('MII_installStep4Netmask1_1').allowBlank = false;
					Ext.getCmp('MII_installStep4Netmask1_2').allowBlank = false;
					Ext.getCmp('MII_installStep4Netmask1_3').allowBlank = false;
					Ext.getCmp('MII_installStep4Netmask1_4').allowBlank = false;

					if (Ext.getCmp('MII_installStep4').getForm().isValid())
					{
						if (Ext.getCmp('MII_installStep4Gateway1_1').getValue() != ""
							&& Ext.getCmp('MII_installStep4Gateway1_2').getValue() != ""
							&& Ext.getCmp('MII_installStep4Gateway1_3').getValue() != ""
							&& Ext.getCmp('MII_installStep4Gateway1_4').getValue() != "")
						{
							MII_installWindow.layout.setActiveItem(++currentStepIndex);
							MII_installButton('next');
						}
						else if (Ext.getCmp('MII_installStep4Gateway1_1').getValue() == ""
								&& Ext.getCmp('MII_installStep4Gateway1_2').getValue() == ""
								&& Ext.getCmp('MII_installStep4Gateway1_3').getValue() == ""
								&& Ext.getCmp('MII_installStep4Gateway1_4').getValue() == "")
						{
							MII_installWindow.layout.setActiveItem(++currentStepIndex);
							MII_installButton('next');

							if (Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue())
							{
								MII_installWindow.setHeight(780);
								Ext.getCmp('MII_installStep5ServiceMgmtCommon').show();
								Ext.getCmp('MII_installStep5ServiceMgmtCommon').enable();
								Ext.getCmp('MII_installStep5Desc').show();
								Ext.getCmp('MII_installWindow').center();
								Ext.getCmp('MII_installWindow').show();
							}
							else
							{
								Ext.getCmp('MII_installStep5ServiceMgmtCommon').disable();
								Ext.getCmp('MII_installStep5ServiceMgmtCommon').hide();
								Ext.getCmp('MII_installStep5Desc').hide();
							}
						}
						else
						{
							Ext.MessageBox.alert(lang_install[0], lang_install[63]);
						}
					}
				}
				else if (currentStepIndex == 4)
				{
					var ServiceRecords = MII_installServiceNetworkDeviceGrid.getSelectionModel().getSelection();
					var StorageRecords = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

					if (Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() == true)
					{
						MII_installWindow.setHeight(780);
						Ext.getCmp('MII_installWindow').center();
						Ext.getCmp('MII_installWindow').show();
						Ext.getCmp('MII_installStep5ServiceMgmtCommon').show();
						Ext.getCmp('MII_installStep5ServiceMgmtCommon').enable();
						Ext.getCmp('MII_installStep5Desc').show();
					}
					else
					{
						Ext.getCmp('MII_installStep5ServiceMgmtCommon').disable();
						Ext.getCmp('MII_installStep5ServiceMgmtCommon').hide();
						Ext.getCmp('MII_installStep5Desc').hide();
					}

					if (ServiceRecords.length <= 0)
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[49]);
						return false;
					}
					else if ((MII_installServiceNetworkDeviceGrid.store.totalCount - (ServiceRecords.length + StorageRecords.length)) < 1
							&& Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() != true)
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[62]);
						return false;
					}
					else if (!Ext.getCmp('MII_installStep5ServiceMgmtCommon').getForm().isValid())
					{
						return false;
					}
					else
					{
						MII_installWindow.layout.setActiveItem(++currentStepIndex);
						MII_installButton('next');
						MII_installWindow.setHeight(580,true);
						Ext.getCmp('MII_installWindow').center();
						Ext.getCmp('MII_installWindow').show();
					}
				}
				else if (currentStepIndex == 5
						&& Ext.getCmp('MII_installStep6').getForm().isValid())
				{
					// 6단계 관리 네트워크 장치 선택 SKIP
					if (Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() == true)
					{
						MII_installInputCheck(++currentStepIndex);
					}
					else
					{
						MII_installWindow.layout.setActiveItem(++currentStepIndex);
						MII_installButton('next');
					}
				}
				else if (currentStepIndex == 6)
				{
					var records = MII_installMgmtNetworkDeviceGrid.getSelectionModel().getSelection();

					if (records.length <= 0)
					{
						Ext.MessageBox.alert(lang_install[0], lang_install[50]);
					}
					else
					{
						MII_installInputCheck(currentStepIndex);
					}
				}
			}
		},
		{
			text: lang_install[52],
			id: 'MII_installWindowSetBtn',
			width: 80,
			hidden: true,
			disabled: true,
			handler: function () {
				waitWindow(lang_install[0], lang_install[56]);

				// 선택한 스토리지 네트워크 장치 개수
				var selectStorageNetworkDeviceCount = MII_installStorageNetworkDeviceGrid.getSelectionModel().getCount();

				// 선택한 스토리지 네트워크 장치
				var Storage_Slaves = [];
				var selectStorageNetworkDevice = MII_installStorageNetworkDeviceGrid.getSelectionModel().getSelection();

				for (var i=0, len=selectStorageNetworkDeviceCount; i<len; i++)
				{
					Storage_Slaves.push(selectStorageNetworkDevice[i].data.Device);
				}

				// 스토리지 본딩 모드
				var Storage_Mode;

				if (Ext.getCmp('MII_installStorageBondModeRoundRobin').getValue() == true)
					Storage_Mode = '0';
				else if (Ext.getCmp('MII_installStorageBondModeActiveBackup').getValue() == true)
					Storage_Mode = '1';
				else if (Ext.getCmp('MII_installStorageBondModeBalanceXOR').getValue() == true)
					Storage_Mode = '2';
				else if (Ext.getCmp('MII_installStorageBondModeIEEE').getValue() == true)
					Storage_Mode = '4';
				else if (Ext.getCmp('MII_installStorageBondModeBalanceTlb').getValue() == true)
					Storage_Mode = '5';
				else if (Ext.getCmp('MII_installStorageBondModeBalanceAlb').getValue() == true)
					Storage_Mode = '6';

				// 스토리지 네트워크 주소
				var Storage_Ipaddr = Ext.getCmp('MII_installStep4IP1_1').getValue()
									+ '.' + Ext.getCmp('MII_installStep4IP1_2').getValue()
									+ '.' + Ext.getCmp('MII_installStep4IP1_3').getValue()
									+ '.' + Ext.getCmp('MII_installStep4IP1_4').getValue();

				var Storage_Netmask = Ext.getCmp('MII_installStep4Netmask1_1').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Netmask1_2').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Netmask1_3').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Netmask1_4').getValue();

				var Storage_Gateway;

				if (Ext.getCmp('MII_installStep4Gateway1_1').getValue() != ''
					&& Ext.getCmp('MII_installStep4Gateway1_2').getValue() != ''
					&& Ext.getCmp('MII_installStep4Gateway1_3').getValue() != ''
					&& Ext.getCmp('MII_installStep4Gateway1_4').getValue() != '')
				{
					Storage_Gateway = Ext.getCmp('MII_installStep4Gateway1_1').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Gateway1_2').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Gateway1_3').getValue()
									+ '.' + Ext.getCmp('MII_installStep4Gateway1_4').getValue();
				}

				// 선택한 서비스 네트워크 장치 개수
				var selecServiceNetworkDeviceCount = MII_installServiceNetworkDeviceGrid.getSelectionModel().getCount();

				// 선택한 서비스 네트워크 장치
				var Service_Slaves = [];
				var selectServiceNetworkDevice = MII_installServiceNetworkDeviceGrid.getSelectionModel().getSelection();

				for (var i=0, len=selecServiceNetworkDeviceCount; i<len; i++)
				{
					Service_Slaves.push(selectServiceNetworkDevice[i].data.Device);
				}

				// 서비스 본딩 모드
				var Service_Mode;

				if (Ext.getCmp('MII_installServiceBondModeRoundRobin').getValue() == true)
					Service_Mode = '0';
				else if (Ext.getCmp('MII_installServiceBondModeActiveBackup').getValue() == true)
					Service_Mode = '1';
				else if (Ext.getCmp('MII_installServiceBondModeBalanceXOR').getValue() == true)
					Service_Mode = '2';
				else if (Ext.getCmp('MII_installServiceBondModeIEEE').getValue() == true)
					Service_Mode = '4';
				else if (Ext.getCmp('MII_installServiceBondModeBalanceTlb').getValue() == true)
					Service_Mode = '5';
				else if (Ext.getCmp('MII_installServiceBondModeBalanceAlb').getValue() == true)
					Service_Mode = '6';

				// 서비스 네트워크 장비와 관리 네트워크 장비를 공용으로 사용할 경우
				var Management_Interface;
				var Management_Ipaddr;
				var Management_Netmask;
				var Management_Gateway;

				if (Ext.getCmp('MII_installStep5ServiceMgmtCommonCheck').getValue() == true)
				{
					// 관리 네트워크 장치
					Management_Interface = 'service';

					// 관리 IP 주소
					Management_Ipaddr = Ext.getCmp('MII_installStep5IP1_1').getValue()
											+ '.' + Ext.getCmp('MII_installStep5IP1_2').getValue()
											+ '.' + Ext.getCmp('MII_installStep5IP1_3').getValue()
											+ '.' + Ext.getCmp('MII_installStep5IP1_4').getValue();

					// 관리 넷마스크
					Management_Netmask = Ext.getCmp('MII_installStep5Netmask1_1').getValue()
											+ '.' + Ext.getCmp('MII_installStep5Netmask1_2').getValue()
											+ '.' + Ext.getCmp('MII_installStep5Netmask1_3').getValue()
											+ '.' + Ext.getCmp('MII_installStep5Netmask1_4').getValue();

					//  관리 게이트웨이
					Management_Gateway;

					if (Ext.getCmp('MII_installStep5Gateway1_1').getValue() == ''
						|| Ext.getCmp('MII_installStep5Gateway1_2').getValue() == ''
						|| Ext.getCmp('MII_installStep5Gateway1_3').getValue() == ''
						|| Ext.getCmp('MII_installStep5Gateway1_4').getValue() == '')
					{
						Management_Gateway = '';
					}
					else
					{
						Management_Gateway = Ext.getCmp('MII_installStep5Gateway1_1').getValue()
											+ '.' + Ext.getCmp('MII_installStep5Gateway1_2').getValue()
											+ '.' + Ext.getCmp('MII_installStep5Gateway1_3').getValue()
											+ '.' + Ext.getCmp('MII_installStep5Gateway1_4').getValue();
					}
				}
				else
				{
					// 선택한 Mgmt 네트워크 장치 개수
					var selectMgmtNetworkDeviceCount = MII_installMgmtNetworkDeviceGrid.getSelectionModel().getCount();

					// 선택한 Mgmt 네트워크 장치
					var selectMgmtNetworkDevice = MII_installMgmtNetworkDeviceGrid.getSelectionModel().getSelection();

					if (selectMgmtNetworkDeviceCount > 0)
					{
						Management_Interface = selectMgmtNetworkDevice[0].data.Device;
					}

					// 관리 IP 주소
					Management_Ipaddr ='0.0.0.0';

					// 관리 넷마스크
					Management_Netmask ='0.0.0.0';
				}

				GMS.Ajax.request({
					url: '/api/cluster/init/config',
					timeout: 600000,
					jsonData: {
						Network: {
							Service: {
								Slaves: Service_Slaves,
								Mode: Service_Mode,
							},
							Storage: {
								Slaves: Storage_Slaves,
								Mode: Storage_Mode,
								Ipaddr: Storage_Ipaddr,
								Netmask: Storage_Netmask,
								Gateway: Storage_Gateway,
							},
							Management: {
								Interface: Management_Interface,
								Ipaddr: Management_Ipaddr,
								Netmask: Management_Netmask,
								Gateway: Management_Gateway
							},
						},
					},
					callback: function (options, success, response, decoded) {
						// 예외 처리에 따른 동작
						if (!success || !decoded.success)
						{
							return;
						}

						// 초기 설정 정보 저장 성공 메세지
						Ext.MessageBox.show({
							title: lang_install[0],
							msg: lang_install[57],
							buttons: Ext.MessageBox.OK,
							fn: function () {
								locationMain();
							}
						});
					}
				});
			}
		}
	]
});

Ext.onReady(function () { MII_installLoad(); });
