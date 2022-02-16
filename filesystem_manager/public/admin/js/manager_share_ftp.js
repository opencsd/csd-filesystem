/*
 * 페이지 로드 시 실행 함수
 */
// FTP 정보 로드
function MSP_ftpDefaultLoad()
{
	// 초기 컨트롤
	Ext.getCmp('MSP_FTPPanel').getForm().reset();

	Ext.Array.forEach(
		Ext.getCmp('MSP_FTPPanel').query('.field, .label, .radiogroup'),
		function(c) { c.setDisabled(true); }
	);

	Ext.getCmp('MSP_FTPEnable').enable();

	MSP_FTPPanel.mask(lang_msp_protocol[46]);

	GMS.Ajax.request({
		url: '/api/cluster/share/ftp/proftpd/config/get',
		callback: function(options, success, response, decoded) {
			// 마스크 숨김
			MSP_FTPPanel.unmask();

			// 응답 데이터
			if (!success || !decoded.success)
				return;

			if (decoded.entity.Active == 'on')
			{
				Ext.Array.forEach(
					Ext.getCmp('MSP_FTPPanel').query('.field, .label, .radiogroup'),
					function(c) { c.setDisabled(false); }
				);

				//Ext.getCmp('MSP_FTPReload').setDisabled(false);
			}

			Ext.getCmp('MSP_FTPEnable').setValue(decoded.entity.Active);
			Ext.getCmp('MSP_FTPStatus').update(decoded.entity.Status);
		},
	});
};

/** 서비스 프로토콜 리로드 **/
function MSP_reload(protocol)
{
	var setUrl;

	if (protocol == 'FTP')
	{
		setUrl = '/api/cluster/share/ftp/proftpd/control';
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
				case 'FTP':
					MSP_ftpDefaultLoad();
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
 * FTP 설정
 */
var MSP_FTPPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSP_FTPPanel',
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
						id: 'MSP_FTPEnableLabel',
						text: lang_msp_protocol[3] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask',
					},
					{
						xtype: 'checkbox',
						style: { marginTop: 0 },
						id: 'MSP_FTPEnable',
						name: 'protocolFTPEnable',
						inputValue: 'on',
						listeners: {
							change: function() {
								if (this.getValue() == true)
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_FTPPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(false); }
									);

									//Ext.getCmp('MSP_FTPReload').setDisabled(false);
								}
								else
								{
									Ext.Array.forEach(
										Ext.getCmp('MSP_FTPPanel').query('.field, .label, .radiogroup'),
										function(c) { c.setDisabled(true); }
									);

									Ext.getCmp('MSP_FTPEnable').setDisabled(false);
									//Ext.getCmp('MSP_FTPReload').setDisabled(true);
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
						id: 'MSP_FTPStatusLabel',
						text: lang_msp_protocol[4] + ' : ',
						width: 135,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSP_FTPStatus',
						disabledCls: 'm-label-disable-mask',
						style: { marginRight: '20px' }
					},
				]
			},
		],
		buttonAlign: 'left',
		buttons: [
			{
				text: lang_msp_protocol[9],
				id: 'MSP_FTPPanelBtn',
				handler: function() {
					if (!MSP_FTPPanel.getForm().isValid())
						return false;

					var protocolFTPActive
						= Ext.getCmp('MSP_FTPEnable').getValue() ? 'on' : 'off';

					GMS.Ajax.request({
						waitMsgBox: waitWindow(lang_msp_protocol[0], lang_msp_protocol[10]),
						url: '/api/cluster/share/ftp/proftpd/config/set',
						jsonData: {
							Active: protocolFTPActive,
						},
						callback: function(options, success, response, decoded) {
							if (!success)
								return;

							Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[11]);
							MSP_ftpDefaultLoad();
						}
					});
				}
			},
			{
				xtype: 'button',
				id: 'MSP_FTPReload',
				text: lang_msp_protocol[41],
				handler: function() {
					MSP_reload('FTP');
				}
			},
		]
	}
);

// 서비스 프로토콜
Ext.define(
	'/admin/js/manager_share_ftp',
	{
		extend: 'BasePanel',
		id: 'manager_share_ftp',
		load: function() {
			MSP_ftpDefaultLoad();

			Ext.getCmp('MSP_FTPTab').layout.setActiveItem('MSP_FTPTab_Default');
		},
		bodyStyle: { padding: 0 },
		items: [
			{
				xtype: 'tabpanel',
				id: 'MSP_FTPTab',
				activeTab: 0,
				frame: false,
				border: false,
				bodyStyle: { padding: 0 },
				items: [
					{
						xtype: 'BasePanel',
						id: 'MSP_FTPTab_Default',
						title: lang_common[40],
						layout: 'fit',
						bodyStyle: { padding: 0 },
						items: [ MSP_FTPPanel ]
					},
				],
				listeners: {
					tabchange: function(tabPanel, newCard, oldCard) {
						MSP_ftpDefaultLoad();
					}
				}
			}
		]
	}
);
