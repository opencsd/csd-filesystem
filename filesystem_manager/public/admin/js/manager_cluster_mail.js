/*
 * 알림 정보 가져오기
 */
function MCM_mailLoad()
{
	Ext.getCmp('MCM_mailMailFormPanel').getForm().reset();
	Ext.getCmp('MCM_mailSmnpFormPanel').getForm().reset();
	Ext.getCmp('MCM_mailRsyslogFormPanel').getForm().reset();
	Ext.getCmp('MCM_mailAlarmFormPanel').getForm().reset();
	MCM_mailMailFormPanel.mask(lang_mcm_mail[63]);

	GMS.Ajax.request({
		url: '/api/cluster/system/smtp/info',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				// 실패 시 전자 메일 disabled
				Ext.getCmp('MCM_mailMailFormSet').setValue(false);
				Ext.Array.forEach(
					Ext.getCmp('MCM_mailMailFormPanel').query('.field, .button, .label'),
					function(c) { c.setDisabled(true); }
				);
				Ext.getCmp('MCM_mailMailFormSet').enable();
				Ext.getCmp('MCM_mailMailFormBtn').enable();

				// 실패 시 SNMP disabled
				Ext.getCmp('MCM_mailSmnpFormSet').setValue(false);
				Ext.Array.forEach(
					Ext.getCmp('MCM_mailSmnpFormPanel').query('.field, .button, .label'),
					function(c) { c.setDisabled(true); }
				);
				Ext.getCmp('MCM_mailSmnpFormSet').enable();
				Ext.getCmp('MCM_mailSmnpFormBtn').enable();

				// 실패 시 Rsyslog disabled
				Ext.getCmp('MCM_mailRsyslogFormSet').setValue(false);
				Ext.Array.forEach(
					Ext.getCmp('MCM_mailRsyslogFormPanel').query('.field, .button, .label'),
					function(c) { c.setDisabled(true); }
				);
				Ext.getCmp('MCM_mailRsyslogFormSet').enable();
				Ext.getCmp('MCM_mailRsyslogFormBtn').enable();

				// 실패 시 경보음 disabled
				Ext.getCmp('MCM_mailAlarmFormSet').setValue(false);
				Ext.Array.forEach(
					Ext.getCmp('MCM_mailAlarmFormPanel').query('.field, .button, .label'),
					function(c) { c.setDisabled(true); }
				);
				Ext.getCmp('MCM_mailAlarmFormSet').enable();
				Ext.getCmp('MCM_mailAlarmFormBtn').enable();

				return;
			}

			MCM_mailMailFormPanel.unmask();

			// 전자 메일 로드
			Ext.getCmp('MCM_mailMailFormSet').setValue(decoded.entity.Enabled);

			if (decoded.entity.Enabled == 'true')
			{
				Ext.Array.forEach(
					Ext.getCmp('MCM_mailMailFormPanel').query('.field, .button, .label'),
					function(c) { c.setDisabled(false); }
				);

				var smtp_enabled = decoded.entity.Auth;

				// SMTP 인증 사용시
				Ext.getCmp('MCM_mailMailFormSmtpUserId').setDisabled(!smtp_enabled);
				Ext.getCmp('MCM_mailMailFormSmtpUserPw').setDisabled(!smtp_enabled);
				Ext.getCmp('MCM_mailMailFormSmtpUserPwRe').setDisabled(!smtp_enabled);
			}
			else
			{
				Ext.Array.forEach(
					Ext.getCmp('MCM_mailMailFormPanel').query('.field, .button, .label'),
					function(c) { c.setDisabled(true); }
				);

				Ext.getCmp('MCM_mailMailFormSet').enable();
				Ext.getCmp('MCM_mailMailFormBtn').enable();
			}

			Ext.getCmp('MCM_mailMailFormAdminMail').setValue(decoded.entity.Receiver);
			Ext.getCmp('MCM_mailMailFormSendMail').setValue(decoded.entity.Sender);
			Ext.getCmp('MCM_mailMailFormSmtpAddr').setValue(decoded.entity.Server);
			Ext.getCmp('MCM_mailMailFormSmtpPort').setValue(decoded.entity.Port);
			Ext.getCmp('MCM_mailMailFormLevel').setValue(decoded.entity.Alert_Level);
			Ext.getCmp('MCM_mailMailFormSmtpAuth').setValue(decoded.entity.Auth);
			Ext.getCmp('MCM_mailMailFormSmtpUserId').setValue(decoded.entity.ID);
			Ext.getCmp('MCM_mailMailFormSecurity').setValue(decoded.entity.Security);
		}
	});
};

// 알림 수준 모델
Ext.define('MCM_mailAlarmLevelModel', {
	extend: 'Ext.data.Model',
	fields: ['alertAlarmLevelName', 'alertAlarmLevelValue']
});

// 알림 수준 스토어
var MCM_mailAlarmLevelStore = Ext.create('Ext.data.Store', {
	model: 'MCM_mailAlarmLevelModel',
	data:[
		[lang_mcm_mail[3], 1],
		[lang_mcm_mail[3]+'+'+lang_mcm_mail[4], 2],
		[lang_mcm_mail[3]+'+'+lang_mcm_mail[4]+'+'+lang_mcm_mail[5], 3]
	]
});

// 서버 인증 모델
Ext.define('MCM_mailSecurityModel',{
	extend: 'Ext.data.Model',
	fields: ['mailSecurityName', 'mailSecurityValue']
});

// 서버 인증 스토어
var MCM_mailSecurityStore = Ext.create('Ext.data.Store', {
	model: 'MCM_mailSecurityModel',
	data: [
		[lang_mcm_mail[60], 'None'],
		[lang_mcm_mail[61], 'SSL/TLS'],
		[lang_mcm_mail[62], 'StartTLS']
	]
});

/*
 * 전자 메일
 */
var MCM_mailMailFormPanel = Ext.create('BaseFormPanel', {
	id: 'MCM_mailMailFormPanel',
	fieldDefaults: { labelWidth: 130 },
	title: lang_mcm_mail[58],
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_mcm_mail[6],
			id: 'MCM_mailMailFormSet',
			name: 'alertMailFormSet',
			inputValue: true,
			style: { marginBottom: '20px' },
			listeners: {
				change: function() {
					var me = this;

					if (me.getValue() !== true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailMailFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(true); }
						);
						Ext.getCmp('MCM_mailMailFormSet').enable();
						Ext.getCmp('MCM_mailMailFormBtn').enable();
						return;
					}

					Ext.Array.forEach(
						Ext.getCmp('MCM_mailMailFormPanel').query('.field, .button, .label'),
						function(c) { c.setDisabled(false); }
					);

					// SMTP 인증 사용 시
					var use_smtp = Ext.getCmp('MCM_mailMailFormSmtpAuth').getValue();

					Ext.getCmp('MCM_mailMailFormSmtpUserId').setDisabled(!use_smtp);
					Ext.getCmp('MCM_mailMailFormSmtpUserPw').setDisabled(!use_smtp);
					Ext.getCmp('MCM_mailMailFormSmtpUserPwRe').setDisabled(!use_smtp);
				}
			}
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[7],
			id: 'MCM_mailMailFormAdminMail',
			name: 'alertMailFormAdminMail',
			allowBlank: false,
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[8],
			id: 'MCM_mailMailFormSendMail',
			name: 'alertMailFormSendMail',
			allowBlank: false,
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[9],
			id: 'MCM_mailMailFormSmtpAddr',
			name: 'alertMailFormSmtpAddr',
			allowBlank: false,
			vtype: 'reg_HOSTNAME',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[57],
			id: 'MCM_mailMailFormSmtpPort',
			name: 'alertMailFormSmtpPort',
			allowBlank: false,
			vtype: 'reg_PORT',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'BaseComboBox',
			id: 'MCM_mailMailFormLevel',
			name: 'alertMailFormLevel',
			store: MCM_mailAlarmLevelStore,
			fieldLabel: lang_mcm_mail[10],
			value: '1',
			valueField: 'alertAlarmLevelValue',
			displayField: 'alertAlarmLevelName',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'BaseComboBox',
			id: 'MCM_mailMailFormSecurity',
			name: 'alertMailFormSecurity',
			store: MCM_mailSecurityStore,
			fieldLabel: lang_mcm_mail[59],
			value: 'None',
			valueField: 'mailSecurityValue',
			displayField: 'mailSecurityName',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' }
		},
		{
			xtype: 'checkbox',
			boxLabel: lang_mcm_mail[11],
			id: 'MCM_mailMailFormSmtpAuth',
			name: 'alertMailFormSmtpAuth',
			inputValue: true,
			inputValue: 'auth',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '15px', marginBottom: '20px' },
			listeners: {
				change: function(cb, nv, ov) {
					// SMTP 인증 사용시
					if (nv == true)
					{
						if (Ext.getCmp('MCM_mailMailFormSet').getValue() == true)
						{
							Ext.getCmp('MCM_mailMailFormSmtpUserId').setDisabled(false);
							Ext.getCmp('MCM_mailMailFormSmtpUserPw').setDisabled(false);
							Ext.getCmp('MCM_mailMailFormSmtpUserPwRe').setDisabled(false);
						}
					}
					// SMTP 인증 사용시
					else
					{
						Ext.getCmp('MCM_mailMailFormSmtpUserId').setDisabled(true);
						Ext.getCmp('MCM_mailMailFormSmtpUserPw').setDisabled(true);
						Ext.getCmp('MCM_mailMailFormSmtpUserPwRe').setDisabled(true);
					}
				}
			}
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[12],
			id: 'MCM_mailMailFormSmtpUserId',
			name: 'alertMailFormSmtpUserId',
			allowBlank: false,
			vtype: 'reg_smtpID',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '35px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[13],
			id: 'MCM_mailMailFormSmtpUserPw',
			name: 'alertMailFormSmtpUserPw',
			inputType: 'password',
			allowBlank: false,
			vtype: 'reg_PW',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '35px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[14],
			id: 'MCM_mailMailFormSmtpUserPwRe',
			name: 'alertMailFormSmtpUserPwRe',
			inputType: 'password',
			allowBlank: false,
			vtype: 'reg_PW',
			width: 400,
			labelWidth: 150,
			style: { marginLeft: '35px', marginBottom: '20px' }
		},
		{
			xtype: 'button',
			id: 'MCM_mailMailFormTestSendBtn',
			text: lang_mcm_mail[15],
			style: { marginLeft: '15px' },
			handler: function() {
				if (!MCM_mailMailFormPanel.getForm().isValid())
					return false;

				var alertMailFormSmtpUserPw;

				if (Ext.getCmp('MCM_mailMailFormSet').getValue() == true
					&& Ext.getCmp('MCM_mailMailFormSmtpAuth').getValue() == true)
				{
					// 패스워드와 패스워드 확인 필드 예외 처리
					if (Ext.getCmp('MCM_mailMailFormSmtpUserPw').getValue()
						!= Ext.getCmp('MCM_mailMailFormSmtpUserPwRe').getValue())
					{
						Ext.MessageBox.alert(lang_mcm_mail[0], lang_mcm_mail[16]);
						return false;
					}

					// 계정 패스워드 암호화
					/*
					alertMailFormSmtpUserPw = AesCtr.encrypt(
						Ext.getCmp('MCM_mailMailFormSmtpUserPw').getValue(),
						Ext.util.Cookies.get('gms_token'),
						256
					);
					/*/
					alertMailFormSmtpUserPw = gms_encrypt(Ext.getCmp('MCM_mailMailFormSmtpUserPw').getValue());
					//*/
				}

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[17]);

				GMS.Ajax.request({
					url: '/api/cluster/system/smtp/test',
					jsonData: {
						Enabled: Ext.getCmp('MCM_mailMailFormSet').getValue(),
						Receiver: Ext.getCmp('MCM_mailMailFormAdminMail').getValue(),
						Sender: Ext.getCmp('MCM_mailMailFormSendMail').getValue(),
						Server: Ext.getCmp('MCM_mailMailFormSmtpAddr').getValue(),
						Alert_Level: Ext.getCmp('MCM_mailMailFormLevel').getValue(),
						Auth: Ext.getCmp('MCM_mailMailFormSmtpAuth').getValue(),
						ID: Ext.getCmp('MCM_mailMailFormSmtpUserId').getValue(),
						Pass: alertMailFormSmtpUserPw,
						Port: Ext.getCmp('MCM_mailMailFormSmtpPort').getValue(),
						Security: Ext.getCmp('MCM_mailMailFormSecurity').getValue(),
					},
					callback: function (options, success, response, decoded) {
						if (!success || !decoded.success)
						{
							return;
						}

						Ext.MessageBox.alert(lang_mcm_mail[0], lang_mcm_mail[18]);
					}
				});
			}
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcm_mail[20],
			id: 'MCM_mailMailFormBtn',
			handler: function() {
				if (!MCM_mailMailFormPanel.getForm().isValid())
					return false;

				var alertMailFormSmtpUserPw;

				if (Ext.getCmp('MCM_mailMailFormSet').getValue() == true
					&& Ext.getCmp('MCM_mailMailFormSmtpAuth').getValue() == true)
				{
					// 패스워드와 패스워드 확인 필드 예외처리
					if (Ext.getCmp('MCM_mailMailFormSmtpUserPw').getValue()
						!= Ext.getCmp('MCM_mailMailFormSmtpUserPwRe').getValue())
					{
						Ext.MessageBox.alert(lang_mcm_mail[0], lang_mcm_mail[21]);
						return false;
					}

					// 계정 패스워드 암호화
					/*
					alertMailFormSmtpUserPw = AesCtr.encrypt(
						Ext.getCmp('MCM_mailMailFormSmtpUserPw').getValue(),
						Ext.util.Cookies.get('mojolicious'),
						256
					);
					/*/
					alertMailFormSmtpUserPw = Ext.getCmp('MCM_mailMailFormSmtpUserPw').getValue();
					//*/
				}

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[22]);

				GMS.Ajax.request({
					url: '/api/cluster/system/smtp/config',
					jsonData: {
						Enabled: Ext.getCmp('MCM_mailMailFormSet').getValue(),
						Receiver: Ext.getCmp('MCM_mailMailFormAdminMail').getValue(),
						Sender: Ext.getCmp('MCM_mailMailFormSendMail').getValue(),
						Server: Ext.getCmp('MCM_mailMailFormSmtpAddr').getValue(),
						Alert_Level: Ext.getCmp('MCM_mailMailFormLevel').getValue(),
						Auth: Ext.getCmp('MCM_mailMailFormSmtpAuth').getValue(),
						ID: Ext.getCmp('MCM_mailMailFormSmtpUserId').getValue(),
						Pass: alertMailFormSmtpUserPw,
						Port: Ext.getCmp('MCM_mailMailFormSmtpPort').getValue(),
						Security: Ext.getCmp('MCM_mailMailFormSecurity').getValue(),
					},
					callback: function (options, success, response, decoded) {
						// 예외 처리에 따른 동작
						if (!success || !decoded.success)
						{
							return;
						}

						Ext.MessageBox.alert(lang_mcm_mail[0], lang_mcm_mail[23]);
					}
				});
			}
		}
	]
});

/*
 * SNMP
 */
var MCM_mailSmnpFormPanel = Ext.create('BaseFormPanel', {
	id: 'MCM_mailSmnpFormPanel',
	border: false,
	bodyStyle: 'padding:0;',
	frame: false,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_mcm_mail[25],
			id: 'MCM_mailSmnpFormSet',
			name: 'alertSmnpFormSet',
			inputValue: true,
			style: { marginTop: '20px' },
			listeners: {
				change: function() {
					var me = this;

					if (me.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailSmnpFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(false); }
						);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailSmnpFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(true); }
						);

						Ext.getCmp('MCM_mailSmnpFormSet').enable();
						Ext.getCmp('MCM_mailSmnpFormBtn').enable();
					}
				}
			}
		},
		{
			xtype: 'textfield',
			fieldLabel: 'SNMP Trap',
			id: 'MCM_mailSmnpFormTrap',
			name: 'alertSmnpFormTrap',
			vtype: 'reg_HOSTNAME',
			style: { marginLeft: '20px', marginBottom: '20px' }
		},
		{
			xtype: 'BaseComboBox',
			id: 'MCM_mailSmnpFormLevel',
			name: 'alertSmnpFormLevel',
			fieldLabel: lang_mcm_mail[10],
			store: MCM_mailAlarmLevelStore,
			value: '1',
			valueField: 'alertAlarmLevelValue',
			displayField: 'alertAlarmLevelName',
			style: { marginLeft: '20px', marginBottom: '20px' }
		},
		{
			xtype: 'button',
			id: 'MCM_mailSmnpFormTestBtn',
			text: lang_mcm_mail[26],
			style: { marginLeft: '20px', marginBottom: '20px' },
			handler: function() {
				if (!Ext.getCmp('MCM_mailSmnpFormPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[27]);

				Ext.getCmp('MCM_mailSmnpFormPanel').getForm().submit({
					method: 'POST',
					url: '/api/cluster/system/snmp/test',
					success: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 메세지 출력
						var responseMsg = action.result.msg;
						var returnMsg = responseMsg || lang_mcm_mail[28];

						Ext.MessageBox.alert(lang_mcm_mail[0], returnMsg);
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcm_mail[0] + '",'
							+ '"content": "' + lang_mcm_mail[29] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcm_mail[53],
			id: 'MCM_mailSmnpFormBtn',
			handler: function() {
				if (!Ext.getCmp('MCM_mailSmnpFormPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[30]);

				Ext.getCmp('MCM_mailSmnpFormPanel').getForm().submit({
					method: 'POST',
					url: '/api/cluster/system/snmp/enable',
					success: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 메세지 출력
						var responseMsg = action.result.msg;
						var returnMsg = responseMsg || lang_mcm_mail[31];

						Ext.MessageBox.alert(lang_mcm_mail[0], returnMsg);
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcm_mail[0] + '",'
							+ '"content": "' + lang_mcm_mail[32] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	]
});

/*
 * RSYSLOG
 */
var MCM_mailRsyslogFormPanel = Ext.create('BaseFormPanel', {
	id: 'MCM_mailRsyslogFormPanel',
	border: false,
	bodyStyle: 'padding:0;',
	frame: false,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_mcm_mail[33],
			id: 'MCM_mailRsyslogFormSet',
			name: 'alertRsyslogFormSet',
			inputValue: true,
			style: {marginTop: '20px'},
			listeners: {
				change: function() {
					var me = this;

					if (me.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailRsyslogFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(false); }
						);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailRsyslogFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(true); }
						);
						Ext.getCmp('MCM_mailRsyslogFormSet').enable();
						Ext.getCmp('MCM_mailRsyslogFormBtn').enable();
					}
				}
			}
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[34],
			id: 'MCM_mailRsyslogFormAddress',
			name: 'alertRsyslogFormAddress',
			vtype: 'reg_HOSTNAME',
			style: { marginLeft: '20px', marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_mcm_mail[35],
			id: 'MCM_mailRsyslogFormPort',
			name: 'alertRsyslogFormPort',
			allowBlank:false,
			vtype: 'reg_PORT',
			style: { marginLeft: '20px', marginBottom: '20px' }
		},
		{
			xtype: 'button',
			id: 'MCM_mailRsyslogFormTestBtn',
			text: lang_mcm_mail[54],
			style: { marginLeft: '20px', marginBottom: '20px' },
			handler: function() {
				if (!Ext.getCmp('MCM_mailRsyslogFormPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[36]);

				Ext.getCmp('MCM_mailRsyslogFormPanel').getForm().submit({
					method: 'POST',
					url: '/api/cluster/system/rsyslog/test',
					success: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 메세지 출력
						var responseMsg = action.result.msg;
						var returnMsg   = responseMsg || lang_mcm_mail[37];

						Ext.MessageBox.alert(lang_mcm_mail[0], returnMsg);
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcm_mail[0] + '",'
							+ '"content": "' + lang_mcm_mail[38] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcm_mail[55],
			id: 'MCM_mailRsyslogFormBtn',
			handler: function() {
				if (!Ext.getCmp('MCM_mailRsyslogFormPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[39]);

				Ext.getCmp('MCM_mailRsyslogFormPanel').getForm().submit({
					method: 'POST',
					url: '/api/cluster/system/rsyslog/config',
					success: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 메세지 출력
						var responseMsg = action.result.msg;
						var returnMsg   = responseMsg || lang_mcm_mail[40];

						Ext.MessageBox.alert(lang_mcm_mail[0], returnMsg);
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcm_mail[0] + '",'
							+ '"content": "' + lang_mcm_mail[41] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	]
});

/*
 * 경보음
 */
var MCM_mailAlarmFormPanel = Ext.create('BaseFormPanel', {
	id: 'MCM_mailAlarmFormPanel',
	border: false,
	bodyStyle: 'padding:0;',
	frame: false,
	items: [
		{
			xtype: 'checkbox',
			boxLabel: lang_mcm_mail[42],
			id: 'MCM_mailAlarmFormSet',
			name: 'alertAlarmFormSet',
			inputValue: true,
			style: { marginTop: '20px' },
			listeners: {
				change: function() {
					var me = this;

					if (me.getValue() == true)
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailAlarmFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(false); }
						);
					}
					else
					{
						Ext.Array.forEach(
							Ext.getCmp('MCM_mailAlarmFormPanel').query('.field, .button, .label'),
							function(c) { c.setDisabled(true); }
						);
						Ext.getCmp('MCM_mailAlarmFormSet').enable();
						Ext.getCmp('MCM_mailAlarmFormBtn').enable();
					}
				}
			}
		},{
			xtype: 'BaseComboBox',
			id: 'MCM_mailAlarmFormLevel',
			name: 'alertAlarmFormLevel',
			store: MCM_mailAlarmLevelStore,
			fieldLabel: lang_mcm_mail[10],
			value: '1',
			valueField: 'alertAlarmLevelValue',
			displayField: 'alertAlarmLevelName',
			style: { marginLeft: '20px', marginBottom: '20px' }
		},
		{
			xtype: 'button',
			id: 'MCM_mailAlarmFormTestBtn',
			text: lang_mcm_mail[43],
			style: { marginLeft: '20px', marginBottom: '20px' },
			handler: function() {
				if (!Ext.getCmp('MCM_mailAlarmFormPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[44]);

				Ext.getCmp('MCM_mailAlarmFormPanel').getForm().submit({
					method: 'POST',
					url: '/api/cluster/system/beep/test',
					success: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 메세지 출력
						var responseMsg = action.result.msg;
						var returnMsg   = responseMsg || lang_mcm_mail[45];

						Ext.MessageBox.alert(lang_mcm_mail[0], returnMsg);
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcm_mail[0] + '",'
							+ '"content": "' + lang_mcm_mail[46] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcm_mail[56],
			id: 'MCM_mailAlarmFormBtn',
			handler: function() {
				if (!Ext.getCmp('MCM_mailAlarmFormPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcm_mail[0], lang_mcm_mail[47]);

				Ext.getCmp('MCM_mailAlarmFormPanel').getForm().submit({
					method: 'POST',
					url: '/api/cluster/system/beep/config',
					success: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 메세지 출력
						var responseMsg = action.result.msg;
						var returnMsg   = responseMsg || lang_mcm_mail[48];

						Ext.MessageBox.alert(lang_mcm_mail[0], returnMsg);
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcm_mail[0] + '",'
							+ '"content": "' + lang_mcm_mail[49] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	]
});

// 시스템-> 알림
Ext.define('/admin/js/manager_cluster_mail', {
	extend: 'BasePanel',
	id: 'manager_cluster_mail',
	bodyStyle: 'padding: 0',
	load: function() { MCM_mailLoad(); },
	items: [
		{
			xtype: 'BasePanel',
			id: 'MCM_mailPanel',
			layout: 'fit',
			frame: false,
			bodyStyle: 'padding: 20px',
			items: [
				MCM_mailMailFormPanel
			]
		}
		/*
		{
			xtype: 'tabpanel',
			activeTab: 0,
			frame: true,
			defaults: {
				overflowX: 'hidden',
				overflowY:'auto',
				bodyCls: 'm-panelbody',
				bodyStyle: 'padding:15px;',
				border: false
			},
			items: [
				{
					title: lang_mcm_mail[51],
					items: [MCM_mailMailFormPanel]
				},
				{
					title: 'SNMP',
					items: [MCM_mailSmnpFormPanel]
				},
				{
					title: 'Rsyslog',
					items: [MCM_mailRsyslogFormPanel]
				},
				{
					title: lang_mcm_mail[52],
					items: [MCM_mailAlarmFormPanel]
				}
			]
		}*/
	]
});
