/*
 * 외부 인증 데이터 로드
 */
function MAE_externalGetData()
{
	/*
	// 외부 인증 라이선스 체크
	if (licenseADS != 'yes')
	{
		// Active Directory 비활성화
		Ext.getCmp('MAE_externalTypeADS').setDisabled(true);

		// LDAP 비활성화
		Ext.getCmp('MAE_externalTypeLDAP').setDisabled(true);

		return;
	}
	*/
};

/*
 * 외부 인증: Active Directory
 */
var MAE_externalADSPanel = Ext.create(
	'BasePanel',
	{
		id: 'MAE_externalADSPanel',
		title: 'ADS',
		bodyStyle: {
			padding: 0,
		},
		tbar: [
			{
				id: 'MAE_externalADSApplyBtn',
				xtype: 'button',
				text: lang_common[27],
				iconCls: 'b-icon-apply',
				handler: function (button, e) {
					var enabled = Ext.getCmp('MAE_externalADSEnabled').getValue();

					if (enabled)
					{
						enableADS();
					}
					else
					{
						disableADS();
					}
				},
			},
		],
		items: [
			{
				xtype: 'fieldset',
				title: lang_common[42],
				layout: 'anchor',
				defaults: {
					anchor: '100% 90%',
				},
				style: {
					marginTop: '10px',
					marginLeft: '20px',
					marginRight: '20px',
					paddingTop: '10px',
					paddingLeft: '20px',
					paddingRight: '50px',
				},
				items: [
					{
						id: 'MAE_externalADSEnabled',
						name: 'externalADSEnabled',
						xtype: 'checkbox',
						fieldLabel: lang_common[43],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
					},
					{
						id: 'MAE_externalADSRealm',
						name: 'externalADSRealm',
						xtype: 'textfield',
						fieldLabel: lang_mae_external[33],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalADSDC',
						name: 'externalADSDC',
						xtype: 'textfield',
						fieldLabel: lang_mae_external[6],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					/*
					{
						id: 'MAE_externalADSNBName',
						name: 'externalADSNBName',
						xtype: 'textfield',
						fieldLabel: lang_mae_external[7],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					*/
					{
						id: 'MAE_externalADSAdmin',
						name: 'externalADSAdmin',
						xtype: 'textfield',
						fieldLabel: lang_mae_external[8],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalADSPwd',
						name: 'externalADSPwd',
						xtype: 'textfield',
						fieldLabel: lang_mae_external[9],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						inputType: 'password',
						allowBlank: false,
					},
				]
			},
		],
		listeners: {
			render: function (me, eOpts) { loadADSConfig(me); },
			show: function (me, eOpts) { loadADSConfig(me); },
		},
	}
);

function loadADSConfig(me)
{
	me.mask(lang_common[30]);

	GMS.Ajax.request({
		url: '/api/cluster/auth/ads/info',
		callback: function (options, success, response, decoded) {
			me.unmask();

			if (!success)
			{
				return;
			}

			// ADS 정보
			Ext.getCmp('MAE_externalADSEnabled').setValue(decoded.entity.Enabled);
			Ext.getCmp('MAE_externalADSRealm').setValue(decoded.entity.Realm);
			Ext.getCmp('MAE_externalADSDC').setValue(decoded.entity.DC);
			//Ext.getCmp('MAE_externalADSNBName').setValue(decoded.entity.NBName);
			Ext.getCmp('MAE_externalADSAdmin').setValue(decoded.entity.Admin);
		},
	});
}

function enableADS()
{
	waitWindow(lang_mae_external[0], lang_mae_external[26]);

	GMS.Ajax.request({
		url: '/api/cluster/auth/ads/enable',
		jsonData: {
			Realm: Ext.getCmp('MAE_externalADSRealm').getValue(),
			DC: Ext.getCmp('MAE_externalADSDC').getValue(),
			//NBName: Ext.getCmp('MAE_externalADSNBName').getValue(),
			Admin: Ext.getCmp('MAE_externalADSAdmin').getValue(),
			Password: Ext.getCmp('MAE_externalADSPwd').getValue(),
		},
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mae_external[0],
				msg: lang_mae_external[27],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});
		},
	});
}

function disableADS()
{
	waitWindow(lang_mae_external[0], lang_mae_external[26]);

	GMS.Ajax.request({
		url: '/api/cluster/auth/ads/disable',
		jsonData: {
			Realm: Ext.getCmp('MAE_externalADSRealm').getValue(),
			DC: Ext.getCmp('MAE_externalADSDC').getValue(),
			//NBName: Ext.getCmp('MAE_externalADSNBName').getValue(),
			Admin: Ext.getCmp('MAE_externalADSAdmin').getValue(),
			Password: Ext.getCmp('MAE_externalADSPwd').getValue(),
		},
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mae_external[0],
				msg: lang_mae_external[27],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});
		},
	});
}

/*
 * 외부 인증: LDAP
 */
var MAE_externalLDAPPanel = Ext.create(
	'BasePanel',
	{
		id: 'MAE_externalLDAPPanel',
		title: 'LDAP',
		bodyStyle: {
			padding: 0,
		},
		tbar: [
			{
				id: 'MAE_externalLDAPApplyBtn',
				xtype: 'button',
				text: lang_common[27],
				iconCls: 'b-icon-apply',
				handler: function () { setLDAPConfig(); }
			},
		],
		items: [
			{
				xtype: 'fieldset',
				title: lang_common[42],
				layout: 'anchor',
				defaults: {
					anchor: '100% 90%',
				},
				style: {
					marginTop: '10px',
					marginLeft: '20px',
					marginRight: '20px',
					paddingTop: '10px',
					paddingLeft: '20px',
					paddingRight: '20px',
				},
				items: [
					{
						id: 'MAE_externalLDAPEnabled',
						name: 'externalLDAPEnabled',
						xtype: 'checkbox',
						fieldLabel: lang_common[43],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
					},
					{
						id: 'MAE_externalLDAPURI',
						name: 'externalLDAPURI',
						xtype: 'textfield',
						fieldLabel: 'URI',
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPBaseDN',
						name: 'externalLDAPBaseDN',
						xtype: 'textfield',
						fieldLabel: 'BaseDN',
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPBindDN',
						name: 'externalLDAPBindDN',
						xtype: 'textfield',
						fieldLabel: 'BindDN',
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPBindPw',
						name: 'externalLDAPBindPw',
						xtype: 'textfield',
						fieldLabel: 'BindPw',
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						inputType: 'password',
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPPasswdDN',
						name: 'externalLDAPPasswdDN',
						xtype: 'textfield',
						fieldLabel: 'PasswdDN',
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPShadowDN',
						name: 'externalLDAPShadowDN',
						xtype: 'textfield',
						fieldLabel: 'ShadowDN',
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPGroupDN',
						name: 'externalLDAPGroupDN',
						xtype: 'textfield',
						fieldLabel: 'GroupDN',
						labelSeparator: '',
						labelWidth: 100,
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						allowBlank: false,
					},
					{
						id: 'MAE_externalLDAPSecure',
						name: 'externalLDAPSecure',
						xtype: 'BaseComboBox',
						fieldLabel: lang_mae_external[13],
						labelSeparator: '',
						labelWidth: 100,
						style: {
							marginBottom: '20px',
						},
						store: new Ext.data.SimpleStore(
							{
								fields: [
									'externalLDAPSecureName',
									'externalLDAPSecureValue'
								],
								data: [
									[lang_mcm_mail[60], 'None'],
									[lang_mcm_mail[61], 'SSL/TLS'],
									[lang_mcm_mail[62], 'StartTLS'],
								]
							}
						),
						value: 'SSL/TLS',
						valueField: 'externalLDAPSecureValue',
						displayField: 'externalLDAPSecureName',
					}
				]
			}
		],
		listeners: {
			show: function (me, eOpts) { loadLDAPConfig(me); },
			load: function (me, eOpts) { loadLDAPConfig(me); },
		}
	}
);

function loadLDAPConfig(me)
{
	me.mask(lang_common[30]);

	GMS.Ajax.request({
		url: '/api/cluster/auth/ldap/info',
		callback: function (options, success, response, decoded) {
			me.unmask();

			if (!success)
			{
				return;
			}

			// LDAP 정보
			Ext.getCmp('MAE_externalLDAPEnabled').setValue(decoded.entity.Enabled);
			Ext.getCmp('MAE_externalLDAPURI').setValue(decoded.entity.URI);
			Ext.getCmp('MAE_externalLDAPBaseDN').setValue(decoded.entity.BaseDN);
			Ext.getCmp('MAE_externalLDAPBindDN').setValue(decoded.entity.BindDN);
			Ext.getCmp('MAE_externalLDAPPasswdDN').setValue(decoded.entity.PasswdDN);
			Ext.getCmp('MAE_externalLDAPShadowDN').setValue(decoded.entity.ShadowDN);
			Ext.getCmp('MAE_externalLDAPGroupDN').setValue(decoded.entity.GroupDN);
			Ext.getCmp('MAE_externalLDAPSecure').setValue(decoded.entity.SSL);
		},
	});
}

function enableLDAP()
{
	waitWindow(lang_mae_external[0], lang_mae_external[32]);

	GMS.Ajax.request({
		url: '/api/cluster/auth/ldap/enable',
		jsonData: {
			URI: Ext.getCmp('MAE_externalLDAPURI').getValue(),
			BaseDN: Ext.getCmp('MAE_externalLDAPBaseDN').getValue(),
			BindDN: Ext.getCmp('MAE_externalLDAPBindDN').getValue(),
			BindPw: Ext.getCmp('MAE_externalLDAPBindPw').getValue(),
			PasswdDN: Ext.getCmp('MAE_externalLDAPPasswdDN').getValue(),
			ShadowDN: Ext.getCmp('MAE_externalLDAPShadowDN').getValue(),
			GroupDN: Ext.getCmp('MAE_externalLDAPGroupDN').getValue(),
			SSL: Ext.getCmp('MAE_externalLDAPSecure').getValue(),
		},
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mae_external[0],
				msg: lang_mae_external[30],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});
		},
	});
}

function disableLDAP()
{
	waitWindow(lang_mae_external[0], lang_mae_external[26]);

	GMS.Ajax.request({
		url: '/api/cluster/auth/ldap/disable',
		jsonData: {
		},
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mae_external[0],
				msg: lang_mae_external[30],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});
		},
	});
}

// 외부 인증
Ext.define(
	'/admin/js/manager_account_external',
	{
		extend: 'BasePanel',
		id: 'manager_account_external',
		bodyStyle: { padding: 0 },
		load: function () {
			// 외부 인증 데이터 로드
			//MAE_externalGetData();
		},
		items: [
			{
				xtype: 'tabpanel',
				id: 'MAE_AuthTab',
				activeTab: 0,
				frame: false,
				border: false,
				bodyStyle: { padding: 0 },
				items: [
					MAE_externalADSPanel,
					MAE_externalLDAPPanel,
				],
			},
		]
	}
);
