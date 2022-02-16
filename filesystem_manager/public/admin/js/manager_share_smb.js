/*
 * 페이지 로드 시 실행 함수
 */
// SMB 정보 로드
function MSP_smbDefaultLoad()
{
	// 초기 컨트롤
	Ext.getCmp('MSP_SMBPanel').getForm().reset();

	Ext.Array.forEach(
		Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
		function(c) { c.setDisabled(true); }
	);

	Ext.getCmp('MSP_SMBEnable').enable();
	//Ext.getCmp('MSP_SMBReload').setDisabled(true);

	MSP_SMBPanel.mask(lang_msp_protocol[46]);

	GMS.Ajax.request({
		url: '/api/cluster/share/smb/config/get',
		callback: function(options, success, response, decoded) {
			// 마스크 숨김
			MSP_SMBPanel.unmask();

			// 응답 데이터
			if (!success || !decoded.success)
				return;

			if (decoded.entity.Active == 'on')
			{
				Ext.Array.forEach(
					Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
					function(c) { c.setDisabled(false); }
				);

				//Ext.getCmp('MSP_SMBReload').setDisabled(false);
			}

			Ext.getCmp('MSP_SMBEnable').setValue(decoded.entity.Active);
			Ext.getCmp('MSP_SMBStatus').update(decoded.entity.Status);
			Ext.getCmp('MSP_SMBWorkgroup').setValue(decoded.entity.Workgroup);
			Ext.getCmp('MSP_SMBDesc').setValue(decoded.entity.Server_String);
			Ext.getCmp('MSP_SMBNetbiosName').update(decoded.entity.Netbios_Name);
			Ext.getCmp('MSP_SMBMode').update(decoded.entity.Security);
		},
	});
};

/** 서비스 프로토콜 리로드 **/
function MSP_reload(protocol)
{
	var setUrl;

	if (protocol == 'SMB')
	{
		setUrl = '/api/cluster/share/smb/control';
	}

	GMS.Ajax.request({
		url: setUrl,
		waitMsgBox: waitWindow(
						lang_msp_protocol[0],
						protocol + ' ' + lang_msp_protocol[45]),
		jsonData: {
			Action: 'restart',
		},
		protocol: protocol,
		callback: function(options, success, response, decoded) {
			if (!success)
				return;

			Ext.MessageBox.alert(
				lang_msp_protocol[0],
				protocol + ' ' + lang_msp_protocol[43]);

			switch (options.protocol)
			{
				case 'SMB':
					MSP_smbDefaultLoad();
					break;
				default:
					Ext.MessageBox.alert(
						lang_msp_protocol[0],
						lang_msp_protocol[47] + protocol);
			}
		}
	});
};

/*
 * SMB 설정
 */
var MSP_SMBPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSP_SMBPanel',
		frame: true,
		bodyStyle: {
			paddingTop: '20px'
		},
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginLeft: '15px',
					marginBottom: '20px'
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_SMBEnableLabel',
						text: lang_msp_protocol[3] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask',
					},
					{
						xtype: 'checkbox',
						style: { marginTop: 0 },
						id: 'MSP_SMBEnable',
						name: 'protocolSMBEnable',
						inputValue: 'on',
						listeners: {
							change: function() {
								if (this.getValue() == true)
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(false); }
									);

									//Ext.getCmp('MSP_SMBReload').setDisabled(false);
								}
								else
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(true); }
									);

									Ext.getCmp('MSP_SMBEnable').setDisabled(false);
									//Ext.getCmp('MSP_SMBReload').setDisabled(true);
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
					marginBottom: '20px'
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_SMBStatusLabel',
						text: lang_msp_protocol[4] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSP_SMBStatus',
						disabledCls: 'm-label-disable-mask',
						style: { marginRight: '20px' }
					},
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginLeft: '15px',
					marginBottom: '20px'
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_SMBNetbiosNameLabel',
						text: lang_msp_protocol[8] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSP_SMBNetbiosName',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: {
					marginLeft: '15px',
					marginBottom: '20px'
				},
				items: [
					{
						xtype: 'label',
						id: 'MSP_SMBModeLabel',
						text: lang_msp_protocol[5] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSP_SMBMode',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'textfield',
				fieldLabel: lang_msp_protocol[6],
				id: 'MSP_SMBWorkgroup',
				name: 'protocolSMBWorkgroup',
				style: { marginLeft: '15px', marginBottom: '20px' }
			},
			{
				xtype: 'textfield',
				fieldLabel: lang_msp_protocol[7],
				id: 'MSP_SMBDesc',
				name: 'protocolSMBDesc',
				style: { marginLeft: '15px', marginBottom: '20px' }
			},
		],
		buttonAlign: 'left',
		buttons: [
			{
				text: lang_msp_protocol[9],
				id: 'MSP_SMBPanelBtn',
				handler: function() {
					if (!MSP_SMBPanel.getForm().isValid())
						return false;

					var protocolSMBActive
						= Ext.getCmp('MSP_SMBEnable').getValue() ? 'on' : 'off';

					GMS.Ajax.request({
						waitMsgBox: waitWindow(lang_msp_protocol[0], lang_msp_protocol[10]),
						url: '/api/cluster/share/smb/config/set',
						jsonData: {
							Active: protocolSMBActive,
							Workgroup: Ext.getCmp('MSP_SMBWorkgroup').getValue(),
							Server_String: Ext.getCmp('MSP_SMBDesc').getValue(),
						},
						callback: function(options, success, response, decoded) {
							if (!success)
								return;

							Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[11]);
							MSP_smbDefaultLoad();
						}
					});
				}
			},
			{
				xtype: 'button',
				id: 'MSP_SMBReload',
				text: lang_msp_protocol[41],
				handler: function() {
					MSP_reload('SMB');
				}
			}
		]
	}
);

// 서비스 프로토콜
Ext.define(
	'/admin/js/manager_share_smb',
	{
		extend: 'BasePanel',
		id: 'manager_share_smb',
		load: function() {
			MSP_smbDefaultLoad();

			Ext.getCmp('MSP_SMBTab').layout.setActiveItem('MSP_SMBTab_Default');

			// SMB 라이선스 체크
			Ext.getCmp('MSP_SMBTab_Default').setDisabled(
				licenseSMB == 'yes' ? false : true
			);
		},
		bodyStyle: { padding: 0 },
		items: [
			{
				xtype: 'tabpanel',
				id: 'MSP_SMBTab',
				activeTab: 0,
				frame: false,
				border: false,
				bodyStyle: { padding: 0 },
				items: [
					{
						xtype: 'BasePanel',
						id: 'MSP_SMBTab_Default',
						title: lang_common[40],
						layout: 'fit',
						bodyStyle: { padding: 0 },
						items: [ MSP_SMBPanel ]
					},
				],
				listeners: {
					tabchange: function(tabPanel, newCard, oldCard) {
						MSP_smbDefaultLoad();
					}
				}
			}
		]
	}
);
