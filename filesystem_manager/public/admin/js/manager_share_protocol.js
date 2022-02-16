/*
 * 페이지 로드 시 실행 함수
 */
// SMB 정보 로드
function MSP_smbLoad()
{
	// 초기 컨트롤
	Ext.getCmp('MSP_SMBPanel').getForm().reset();

	Ext.Array.forEach(
		Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
		function(c) { c.setDisabled(true); }
	);

	Ext.getCmp('MSP_SMBEnable').enable();
	Ext.getCmp('MSP_SMBReload').setDisabled(true);

	MSP_SMBPanel.mask(lang_msp_protocol[46]);

	GMS.Ajax.request({
		url: '/api/cluster/share/smb/config/get',
		callback: function(options, success, response, decoded) {
			// 마스크 숨김
			MSP_SMBPanel.unmask();

			// 응답 데이터
			if (!success)
				return;

			if (decoded.entity.Active == 'on')
			{
				Ext.Array.forEach(
					Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
					function(c) { c.setDisabled(false); }
				);

				Ext.getCmp('MSP_SMBReload').setDisabled(false);
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

// NFS 정보 로드
function MSP_nfsLoad()
{
	// 초기 컨트롤
	Ext.getCmp('MSP_NFSPanel').getForm().reset();
	Ext.Array.forEach(
		Ext.getCmp('MSP_NFSPanel').query('.field, .label, .radiogroup'),
		function(c) { c.setDisabled(true); });
	Ext.getCmp('MSP_NFSEnable').enable();
	Ext.getCmp('MSP_NFSReload').setDisabled(true);

	MSP_NFSPanel.mask(lang_msp_protocol[46]);

	GMS.Ajax.request({
		url: '/api/cluster/share/nfs/ganesha/config/get',
		callback: function(options, success, response, decoded) {
			// 마스크 숨김
			MSP_NFSPanel.unmask();

			if (!success)
				return;

			if (decoded.entity.Active == 'on')
			{
				Ext.Array.forEach(
					Ext.getCmp('MSP_NFSPanel').query('.field, .label, .radiogroup'),
					function(c) { c.setDisabled(false); });

				Ext.getCmp('MSP_NFSReload').setDisabled(false);
			}

			Ext.getCmp('MSP_NFSEnable').setValue(decoded.entity.Active);
			Ext.getCmp('MSP_NFSStatus').update(decoded.entity.Status);

			// 데이터 로드 성공 메세지
			//Ext.ux.DialogMsg.msg(lang_msp_protocol[0], lang_msp_protocol[1]);
		}
	});
};

/** 서비스 프로토콜 리로드 **/
function MSP_reload(protocol)
{
	var setUrl;

	if (protocol == 'NFS')
	{
		setUrl = '/api/cluster/share/nfs/ganesha/control';
	}
	else if (protocol == 'SMB')
	{
		setUrl = '/api/cluster/share/smb/control';
	}
	else if (protocol == 'AFP')
	{
		setUrl = '/api/cluster/share/afp/control';
	}
	else if (protocol == 'FTP')
	{
		setUrl = '/api/cluster/share/ftp/control';
	}

	waitWindow(
		lang_msp_protocol[0],
		protocol + ' ' + lang_msp_protocol[45]);

	GMS.Ajax.request({
		url: setUrl,
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
				case 'NFS':
					MSP_nfsLoad();
					break;
				case 'SMB':
					MSP_smbLoad();
					break;
				/*
				case 'AFP':
					MSP_afpLoad();
					break;
				case 'FTP':
					MSP_ftpLoad();
					break;
				*/
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
var MSP_SMBPanel = Ext.create('BaseFormPanel', {
	id: 'MSP_SMBPanel',
	title: lang_msp_protocol[34],
	frame: true,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_msp_protocol[3],
			id: 'MSP_SMBEnable',
			name: 'protocolSMBEnable',
			inputValue: 'on',
			style: { marginBottom: '20px' },
			listeners: {
				change: function() {
					if (this.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(false); }
						);

						Ext.getCmp('MSP_SMBReload').setDisabled(false);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_SMBPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(true); }
						);

						Ext.getCmp('MSP_SMBEnable').setDisabled(false);
						Ext.getCmp('MSP_SMBReload').setDisabled(true);
					}
				}
			}
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginLeft: '15px', marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					id: 'MSP_SMBStatusLabel',
					text: lang_msp_protocol[4]+' : ',
					width: 130,
					disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'label',
					id: 'MSP_SMBStatus',
					disabledCls: 'm-label-disable-mask',
					style: { marginRight: '20px' }
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
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginLeft: '15px', marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					id: 'MSP_SMBNetbiosNameLabel',
					text: 'Netbios Name:',
					width: 150,
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
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginLeft: '15px', marginBottom: '20px' },
			items: [
				{
					xtype: 'label'
					,id: 'MSP_SMBModeLabel'
					,text: lang_msp_protocol[5]+' : '
					,width: 150
					,disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'label'
					,id: 'MSP_SMBMode'
					,disabledCls: 'm-label-disable-mask'
				}
			]
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_msp_protocol[6],
			id: 'MSP_SMBWorkgroup',
			name: 'protocolSMBWorkgroup',
			//vtype: 'reg_protocolSMBWorkgroup',
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

				waitWindow(lang_msp_protocol[0], lang_msp_protocol[10]);

				var protocolSMBActive
					= Ext.getCmp('MSP_SMBEnable').getValue() ? 'on' : 'off';

				GMS.Ajax.request({
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
						MSP_smbLoad();
					}
				});
			}
		}
	]
});


/*
 * NFS 설정
 */
var MSP_NFSPanel = Ext.create('BaseFormPanel', {
	id: 'MSP_NFSPanel',
	title: lang_msp_protocol[35],
	frame: true,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_msp_protocol[3],
			id: 'MSP_NFSEnable',
			name: 'protocolNFSEnable',
			inputValue: 'on',
			style: {marginBottom: '20px'},
			listeners: {
				change: function() {
					if (this.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_NFSPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(false); }
						);

						Ext.getCmp('MSP_NFSReload').setDisabled(false);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_NFSPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(true); }
						);

						Ext.getCmp('MSP_NFSEnable').enable();
						Ext.getCmp('MSP_NFSReload').setDisabled(true);
					}
				}
			}
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginLeft: '15px', marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					id: 'MSP_NFSStatusLabel',
					text: lang_msp_protocol[4]+' : ',
					width: 130,
					disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'label',
					id: 'MSP_NFSStatus',
					disabledCls: 'm-label-disable-mask',
					style: { marginRight: '20px' }
				},
				{
					xtype: 'button',
					id: 'MSP_NFSReload',
					text: lang_msp_protocol[41],
					handler: function() {
						MSP_reload('NFS');
					}
				}
			]
		},
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_msp_protocol[16],
			id: 'MSP_NFSPanelBtn',
			handler: function() {
				if (!MSP_NFSPanel.getForm().isValid())
					return false;

				waitWindow(lang_msp_protocol[0], lang_msp_protocol[17]);

				var protocolNFSActive
					= Ext.getCmp('MSP_NFSEnable').getValue() ? 'on' : 'off';

				GMS.Ajax.request({
					url: '/api/cluster/share/nfs/ganesha/config/set',
					jsonData: {
						Active: protocolNFSActive,
					},
					callback: function(options, success, response, decoded) {
						if (!success)
							return;

						Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[18]);
						MSP_nfsLoad();
					}
				});
			}
		}]
});

/*
 * Kernel NFS
 */
var MSP_KNFSPanel = Ext.create('BaseFormPanel', {
	id: 'MSP_KNFSPanel',
	title: 'Kernel NFS',
	frame: true,
	items: [
	],
	buttonAlign: 'left',
	buttons: [
	]
});

/*
 * AFP 설정
 */
var MSP_AFPPanel = Ext.create('BaseFormPanel', {
	id: 'MSP_AFPPanel',
	border: false,
	bodyStyle: 'padding:0;',
	frame: false,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_msp_protocol[3],
			id: 'MSP_AFPEnable',
			name: 'protocolAFPEnable',
			inputValue: 'on',
			style: { marginBottom: '20px' },
			listeners: {
				change: function() {
					if (this.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_AFPPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(false); }
						);

						Ext.getCmp('MSP_AFPReload').setDisabled(false);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_AFPPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(true); }
						);

						Ext.getCmp('MSP_AFPEnable').enable();
						Ext.getCmp('MSP_AFPReload').setDisabled(true);
					}
				}
			}
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginLeft: '15px', marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					id: 'MSP_AFPStatusLabel',
					text: lang_msp_protocol[4]+' : ',
					width: 130,
					disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'label',
					id: 'MSP_AFPStatus',
					disabledCls: 'm-label-disable-mask',
					style: { marginRight: '20px' }
				},
				{
					xtype: 'button',
					id: 'MSP_AFPReload',
					text: lang_msp_protocol[41],
					handler: function() {
						MSP_reload('AFP');
					}
				}
			]
		},
		{
			xtype: 'button',
			text: lang_msp_protocol[20],
			id: 'MSP_AFPPanelBtn',
			handler: function() {
				if (!MSP_AFPPanel.getForm().isValid())
					return false;

				waitWindow(lang_msp_protocol[0], lang_msp_protocol[21]);

				var protocolFTPActive
					= Ext.getCmp('MSP_AFPEnable').getValue() ? 'on' : 'off';

				GMS.Ajax.request({
					url: '/api/cluster/share/afp/config/set',
					jsonData: {
						Active: protocolFTPActive
					},
					callback: function(options, success, response, decoded) {
						if (!success)
							return;

						Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[22]);
						MSP_infoLoad();
					}
				});
			}
		}
	]
});

/*
 * FTP 설정
 */
var MSP_FTPPanel = Ext.create('BaseFormPanel', {
	id: 'MSP_FTPPanel',
	border: false,
	bodyStyle: 'padding:0;',
	frame: false,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_msp_protocol[3],
			id: 'MSP_FTPEnable',
			name: 'protocolFTPEnable',
			inputValue: 'on',
			style: { marginBottom: '20px' },
			listeners: {
				change: function() {
					if (this.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_FTPPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(false); }
						);

						Ext.getCmp('MSP_FTPReload').setDisabled(false);

						var activity = Ext.getCmp('MSP_FTPPassiveModeActivity').getValue();

						Ext.getCmp('MSP_FTPPassiveModeStartPort').setDisabled(!activity);
						Ext.getCmp('MSP_FTPPassiveModeEndPort').setDisabled(!activity);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MSP_FTPPanel').query('.field, .label, .radiogroup'),
							function(c) { c.setDisabled(true); }
						);

						Ext.getCmp('MSP_FTPEnable').enable();
						Ext.getCmp('MSP_FTPReload').setDisabled(true);
					}
				}
			}
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginLeft: '15px', marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					id: 'MSP_FTPStatusLabel',
					text: lang_msp_protocol[4]+' : ',
					width: 150,
					disabledCls: 'm-label-disable-mask'
				},
				{
					xtype: 'label',
					id: 'MSP_FTPStatus',
					disabledCls: 'm-label-disable-mask',
					style: { marginRight: '20px' }
				},
				{
					xtype: 'button',
					id: 'MSP_FTPReload',
					text: lang_msp_protocol[41],
					handler: function() {
						MSP_reload('FTP');
					}
				}
			]
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_msp_protocol[24],
			id: 'MSP_FTPPort',
			name: 'protocolFTPPort',
			labelWidth: 150,
			allowBlank: false,
			vtype: 'reg_PORT',
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'checkbox',
			boxLabel: lang_msp_protocol[25],
			id: 'MSP_FTPPassiveModeActivity',
			name: 'protocolFTPPassiveModeActivity',
			inputValue: 'on',
			style: { marginLeft: '15px', marginBottom: '20px' },
			listeners: {
				change: function() {
					if (this.getValue() == true)
					{
						var enabled = Ext.getCmp('MSP_FTPEnable').getValue();

						Ext.getCmp('MSP_FTPPassiveModeStartPort').setDisabled(!enabled);
						Ext.getCmp('MSP_FTPPassiveModeEndPort').setDisabled(!enabled);
					}
					else
					{
						Ext.getCmp('MSP_FTPPassiveModeStartPort').setDisabled(true);
						Ext.getCmp('MSP_FTPPassiveModeEndPort').setDisabled(true);
					}
				}
			}
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_msp_protocol[26],
			id: 'MSP_FTPPassiveModeStartPort',
			name: 'protocolFTPPassiveModeStartPort',
			allowBlank: false,
			vtype: 'reg_PORT',
			style: { marginLeft: '40px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_msp_protocol[27],
			id: 'MSP_FTPPassiveModeEndPort',
			name: 'protocolFTPPassiveModeEndPort',
			allowBlank: false,
			vtype: 'reg_PORT',
			style: { marginLeft: '40px', marginBottom: '30px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_msp_protocol[28],
			id: 'MSP_FTPMaxConnection',
			name: 'protocolFTPMaxConnection',
			labelWidth: 150,
			vtype: 'reg_allNumber',
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'BaseComboBox',
			fieldLabel: lang_msp_protocol[29],
			id: 'MSP_FTPEncoding',
			hiddenName: 'protocolFTPEncoding',
			name: 'protocolFTPEncoding',
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' },
			store: new Ext.data.SimpleStore({
				fields: ['EncodingType', 'EncodingCode'],
				data: [
					['UTF-8', 'UTF-8'],
					['CP949 (EUC_KR)', 'CP949']
				]
			}),
			value: 'UTF-8',
			displayField: 'EncodingType',
			valueField: 'EncodingCode'
		},
		{
			xtype: 'checkbox',
			boxLabel: lang_msp_protocol[30],
			id: 'MSP_FTPLogging',
			name: 'protocolFTPLogging',
			inputValue: 'on',
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'button',
			text: lang_msp_protocol[31],
			id: 'MSP_FTPPanelBtn',
			handler: function() {
				if (!MSP_FTPPanel.getForm().isValid())
					return false;

				waitWindow(lang_msp_protocol[0], lang_msp_protocol[38]);

				var protocolFTPActive
					= Ext.getCmp('MSP_FTPEnable').getValue() ? 'on' : 'off';

				var protocolFTPPassiveModeActivityStatus
					= Ext.getCmp('MSP_FTPPassiveModeActivity').getValue() ? 'on' : 'off';

				var passiveStart = Ext.getCmp('MSP_FTPPassiveModeStartPort').getValue();
				var passiveEnd   = Ext.getCmp('MSP_FTPPassiveModeEndPort').getValue();

				if (passiveStart > passiveEnd)
				{
					Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[44]);
					return false;
				}

				GMS.Ajax.request({
					// TODO: implement by referencing protocolFTPSet()
					url: '/api/cluster/share/ftp/config/set',
					jsonData: {
						Active: protocolFTPActive,
						Passive: protocolFTPPassiveModeActivityStatus,
						Port: Ext.getCmp('MSP_FTPPort').getValue(),
						PassivePortFrom: Ext.getCmp('MSP_FTPPassiveModeStartPort').getValue(),
						PassivePortTo: Ext.getCmp('MSP_FTPPassiveModeEndPort').getValue(),
						MaxConnection: Ext.getCmp('MSP_FTPMaxConnection').getValue(),
						Logging: Ext.getCmp('MSP_FTPLogging').getValue(),
						Encoding: Ext.getCmp('MSP_FTPEncoding').getValue()
					},
					callback: function(options, success, response, decoded) {
						if (!success)
							return;

						Ext.MessageBox.alert(lang_msp_protocol[0], lang_msp_protocol[39]);
						MSP_infoLoad();
					}
				});
			}
		}
	]
});

// 서비스 프로토콜
Ext.define('/admin/js/manager_share_protocol', {
	extend: 'BasePanel',
	id: 'manager_share_protocol',
	load: function() {
		MSP_smbLoad();

		Ext.getCmp('MSP_Tab').layout.setActiveItem('MSP_SMBTab');

		// SMB 라이선스 체크
		Ext.getCmp('MSP_SMBTab').setDisabled(
			licenseSMB == 'yes' ? false : true
		);

		// NFS 라이선스 체크
		Ext.getCmp('MSP_NFSTab').setDisabled(
			licenseNFS == 'yes' ? false : true
		);
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'tabpanel',
			id: 'MSP_Tab',
			activeTab: 0,
			frame: false,
			border: false,
			bodyStyle: 'padding: 20px;',
			items: [
				{
					xtype: 'BasePanel',
					id: 'MSP_SMBTab',
					title: lang_msp_protocol[34],
					layout: 'fit',
					bodyStyle: 'padding: 0',
					items: [MSP_SMBPanel]
				},
				{
					xtype: 'BasePanel',
					id: 'MSP_NFSTab',
					title: lang_msp_protocol[35],
					layout: 'fit',
					bodyStyle: 'padding: 0',
					items: [MSP_NFSPanel]
				},
				{
					xtype: 'BasePanel',
					id: 'MSP_KernelNFSTab',
					title: 'Kernel NFS',
					layout: 'fit',
					bodyStyle: 'padding: 0',
					items: [MSP_KNFSPanel],
				}
			],
			listeners: {
				tabchange: function(tabPanel, newCard, oldCard) {
					if (newCard.id == 'MSP_SMBTab')
					{
						MSP_smbLoad();
					}
					else if (newCard.id == 'MSP_NFSTab')
					{
						MSP_nfsLoad();
					}
				}
			}
		}
	]
});
