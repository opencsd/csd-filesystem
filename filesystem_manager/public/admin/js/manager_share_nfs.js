// Ganesha 정보 로드
function MSP_NFSGaneshaLoad()
{
	// 초기 컨트롤
	Ext.getCmp('MSP_GaneshaPanel').getForm().reset();

	Ext.Array.forEach(
		Ext.getCmp('MSP_GaneshaPanel').query('.field, .label, .radiogroup'),
		function(c) { c.setDisabled(true); }
	);

	Ext.getCmp('MSP_GaneshaEnable').enable();
	//Ext.getCmp('MSP_GaneshaReload').setDisabled(true);

	MSP_GaneshaPanel.mask(lang_msp_protocol[46]);

	GMS.Ajax.request({
		url: '/api/cluster/share/nfs/ganesha/config/get',
		callback: function(options, success, response, decoded) {
			// 마스크 숨김
			MSP_GaneshaPanel.unmask();

			if (!success || !decoded.success)
				return;

			if (decoded.entity.Active == 'on')
			{
				Ext.Array.forEach(
					Ext.getCmp('MSP_GaneshaPanel').query('.field, .label, .radiogroup'),
					function(c) { c.setDisabled(false); }
				);

				//Ext.getCmp('MSP_GaneshaReload').setDisabled(false);
			}

			Ext.getCmp('MSP_GaneshaEnable').setValue(decoded.entity.Active);
			Ext.getCmp('MSP_GaneshaStatus').update(decoded.entity.Status);
		}
	});
};

// Kernel 정보 로드
function MSP_NFSKernelLoad()
{
	// 초기 컨트롤
	Ext.getCmp('MSP_KernelPanel').getForm().reset();

	Ext.Array.forEach(
		Ext.getCmp('MSP_KernelPanel').query('.field, .label, .radiogroup'),
		function(c) { c.setDisabled(true); }
	);

	Ext.getCmp('MSP_KernelEnable').enable();

	MSP_KernelPanel.mask(lang_msp_protocol[46]);

	GMS.Ajax.request({
		url: '/api/cluster/share/nfs/kernel/config/get',
		callback: function(options, success, response, decoded) {
			// 마스크 숨김
			MSP_KernelPanel.unmask();

			if (!success || !decoded.success)
				return;

			if (decoded.entity.Active == 'on')
			{
				Ext.Array.forEach(
					Ext.getCmp('MSP_KernelPanel').query('.field, .label, .radiogroup'),
					function(c) { c.setDisabled(false); }
				);

				//Ext.getCmp('MSP_KernelReload').setDisabled(false);
			}

			Ext.getCmp('MSP_KernelEnable').setValue(decoded.entity.Active);
			Ext.getCmp('MSP_KernelStatus').update(decoded.entity.Status);
		}
	});
}

/*
 * Ganesha 설정
 */
var MSP_GaneshaPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSP_GaneshaPanel',
		frame: true,
		bodyStyle: {
			padding: '20px',
		},
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginLeft: '15px',
					marginBottom: '20px',
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_GaneshaEnableLabel',
						text: lang_msp_protocol[3] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'checkbox',
						style: { marginTop: 0 },
						id: 'MSP_GaneshaEnable',
						name: 'protocolGaneshaEnable',
						inputValue: 'on',
						listeners: {
							change: function() {
								if (this.getValue() == true)
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_GaneshaPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(false); }
									);

									//Ext.getCmp('MSP_GaneshaReload').setDisabled(false);
								}
								else
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_GaneshaPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(true); }
									);

									Ext.getCmp('MSP_GaneshaEnable').enable();
									//Ext.getCmp('MSP_GaneshaReload').setDisabled(true);
								}
							}
						}
					},
				],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginLeft: '15px', marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MSP_GaneshaStatusLabel',
						text: lang_msp_protocol[4] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSP_GaneshaStatus',
						disabledCls: 'm-label-disable-mask',
					},
					/*
				*/
				]
			},
		],
		buttonAlign: 'left',
		buttons: [
			{
				text: lang_msp_protocol[16],
				id: 'MSP_GaneshaOKBtn',
				handler: function() {
					if (!MSP_GaneshaPanel.getForm().isValid())
						return false;

					var active
						= Ext.getCmp('MSP_GaneshaEnable').getValue() ? 'on' : 'off';

					var isKernelEnabled = Ext.getCmp('MSP_KernelEnable').getValue();
					if (isKernelEnabled)
					{
						Ext.getCmp('MSP_GaneshaPanel').getForm().reset();
						Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[18]);
						return;
					}

					GMS.Ajax.request({
						waitMsgBox: waitWindow(lang_msp_protocol[0], lang_msp_protocol[17]),
						url: '/api/cluster/share/nfs/ganesha/config/set',
						jsonData: {
							Active: active,
						},
						callback: function(options, success, response, decoded) {
							if (!success)
								return;

							Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[18]);
							MSP_NFSGaneshaLoad();
						}
					});
				}
			},
			{
				xtype: 'button',
				id: 'MSP_GaneshaReload',
				text: lang_msp_protocol[41],
				handler: function() {
					MSP_reload('Ganesha');
				}
			}
		],
	}
);

/*
 * Kernel NFS
 */
var MSP_KernelPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSP_KernelPanel',
		frame: true,
		bodyStyle: {
			padding: '20px',
		},
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginLeft: '15px',
					marginBottom: '20px',
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_KernelEnableLabel',
						text: lang_msp_protocol[3] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'checkbox',
						style: { marginTop: 0 },
						id: 'MSP_KernelEnable',
						name: 'protocolKernelEnable',
						inputValue: 'on',
						listeners: {
							change: function() {
								if (this.getValue() == true)
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_KernelPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(false); }
									);
								}
								else
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_KernelPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(true); }
									);

									Ext.getCmp('MSP_KernelEnable').enable();
								}
							}
						}
					},
				],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginLeft: '15px',
					marginBottom: '20px',
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_KernelStatusLabel',
						text: lang_msp_protocol[4] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask',
					},
					{
						xtype: 'label',
						id: 'MSP_KernelStatus',
						disabledCls: 'm-label-disable-mask',
					},
				]
			},
		],
		buttonAlign: 'left',
		buttons: [
			{
				text: lang_msp_protocol[16],
				id: 'MSP_KernelPanelBtn',
				handler: function() {
					if (!MSP_GaneshaPanel.getForm().isValid())
						return false;

					var active
						= Ext.getCmp('MSP_KernelEnable').getValue() ? 'on' : 'off';

					var isGaneshaEnabled= Ext.getCmp('MSP_GaneshaEnable').getValue();
					if (isGaneshaEnabled)
					{
						Ext.getCmp('MSP_KernelPanel').getForm().reset();
						Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[18]);
						return;
					}

					GMS.Ajax.request({
						waitMsgBox: waitWindow(lang_msp_protocol[0], lang_msp_protocol[17]),
						url: '/api/cluster/share/nfs/kernel/config/set',
						jsonData: {
							Active: active,
						},
						callback: function(options, success, response, decoded) {
							if (!success)
								return;

							Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[18]);
							MSP_NFSKernelLoad();
						}
					});
				}
			},
			{
				xtype: 'button',
				id: 'MSP_KernelReload',
				text: lang_msp_protocol[41],
				handler: function() {
					MSP_reload('Kernel');
				}
			}
		],
	}
);

function MSP_reload(type)
{
	var url;
	var type_str;

	switch (type.toUpperCase())
	{
		case 'GANESHA':
			url      = '/api/cluster/share/nfs/ganesha/control';
			type_str = lang_msp_protocol[48] + ' NFS';
			break;
		case 'KERNEL':
			url      = '/api/cluster/share/nfs/kernel/control';
			type_str = lang_common[41] + ' NFS';
			break;
		default:
			Ext.MessageBox.alert(
				lang_msp_protocol[0],
				lang_msp_protocol[47] + protocol);

			throw 'Unknown NFS type: ' + type;

			return;
	}

	GMS.Ajax.request({
		waitMsgBox: waitWindow(
						lang_msp_protocol[0],
						type_str + ' ' + lang_msp_protocol[45]),
		url: url,
		jsonData: {
			Action: 'restart',
		},
		callback: function(options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			Ext.MessageBox.alert(
				lang_msp_protocol[0],
				type_str + ' ' + lang_msp_protocol[43]);

			switch (type.toUpperCase())
			{
				case 'GANESHA':
					MSP_NFSGaneshaLoad();
					break;
				case 'KERNEL':
					MSP_NFSKernelLoad();
					break;
			}
		}
	});
};

// NFS 프로토콜
Ext.define(
	'/admin/js/manager_share_nfs',
	{
		extend: 'BasePanel',
		id: 'manager_share_nfs',
		load: function() {
			Ext.getCmp('MSP_NFSTab').layout.setActiveItem('MSP_NFSTab_Kernel');
			MSP_NFSKernelLoad();

			Ext.getCmp('MSP_NFSTab').layout.setActiveItem('MSP_NFSTab_Ganesha');
			MSP_NFSGaneshaLoad();

			// NFS 라이선스 체크
			Ext.getCmp('MSP_NFSTab_Ganesha').setDisabled(
				licenseNFS == 'yes' ? false : true
			);
		},
		bodyStyle: { padding: 0 },
		items: [
			{
				xtype: 'tabpanel',
				id: 'MSP_NFSTab',
				activeTab: 0,
				frame: false,
				border: false,
				bodyStyle: { padding: '0px' },
				items: [
					{
						xtype: 'BasePanel',
						id: 'MSP_NFSTab_Ganesha',
						title: lang_msp_protocol[48],
						layout: 'fit',
						bodyStyle: { padding: 0 },
						items: [ MSP_GaneshaPanel ]
					},
					{
						xtype: 'BasePanel',
						id: 'MSP_NFSTab_Kernel',
						title: lang_common[41],
						layout: 'fit',
						bodyStyle: { padding: 0 },
						items: [ MSP_KernelPanel ]
					},
				],
				listeners: {
					tabchange: function(tabPanel, newCard, oldCard) {
						if (newCard.id == 'MSP_NFSTab_Ganesha')
						{
							MSP_NFSGaneshaLoad();
						}
						else if (newCard.id == 'MSP_NFSTab_Kernel')
						{
							MSP_NFSKernelLoad();
						}
					}
				}
			}
		]
	}
);
