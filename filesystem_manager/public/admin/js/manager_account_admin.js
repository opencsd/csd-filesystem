/*
 * 페이지 로드시 실행 함수
 */
function MAA_adminLoad()
{
	// 마스크 표시
	var adminLoadMask = new Ext.LoadMask(
		Ext.getCmp('MAA_adminForm'),
		{ msg: (lang_common[30]) }
	);

	adminLoadMask.show();

	var claims = jwt_decode($.cookie('gms_token'));

	// 관리자 정보 호출
	GMS.Ajax.request({
		url: '/api/manager/info',
		jsonData: {
			ID: claims.id,
		},
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			adminLoadMask.hide();

			if (!success || !decoded.success)
				return;

			// 관리자 아이디
			Ext.getCmp('MAA_adminId').setValue(decoded.entity.ID);
			Ext.getCmp('MAA_adminIdLabel').setText(decoded.entity.ID);

			// 조직명
			Ext.getCmp('MAA_adminOrganization').setValue(decoded.entity.Organization);

			// 관리자 전화번호
			Ext.getCmp('MAA_adminPhone').setValue(decoded.entity.Phone);

			// 관리자 이메일
			Ext.getCmp('MAA_adminEmail').setValue(decoded.entity.Email);

			// 담당자
			Ext.getCmp('MAA_adminEngineer').setValue(decoded.entity.Engineer);

			// 담당자 전화번호
			Ext.getCmp('MAA_adminEngineerPhone').setValue(decoded.entity.EngineerPhone);

			// 담당자 이메일
			Ext.getCmp('MAA_adminEngineerEmail').setValue(decoded.entity.EngineerEmail);
		},
	});
};

/*
 * 슈퍼 관리자 정보
 */
var MAA_adminForm = Ext.create('BaseFormPanel', {
	id: 'MAA_adminForm',
	title: lang_maa_admin[2],
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding:0;',
			layout: 'hbox',
			style: { marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					text: lang_maa_admin[3]+': ',
					width: 135
				},
				{
					xtype: 'label',
					id: 'MAA_adminIdLabel',
					text: jwt_decode($.cookie('gms_token')).id,
				}
			]
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[3],
			id: 'MAA_adminId',
			name: 'adminId',
			hidden: true
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[4],
			id: 'MAA_adminOrganization',
			name: 'adminOrganization',
			msgTarget: 'side',
			allowBlank: false,
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[5],
			id: 'MAA_adminPhone',
			name: 'adminPhone',
			msgTarget: 'side',
			vtype: 'reg_PHONE',
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[6],
			id: 'MAA_adminEmail',
			name: 'adminEmail',
			msgTarget: 'side',
			vtype: 'email',
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[7],
			id: 'MAA_adminEngineer',
			name: 'adminEngineer',
			vtype: 'reg_DESC',
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[8],
			id: 'MAA_adminEngineerPhone',
			name: 'adminEngineerPhone',
			msgTarget: 'side',
			vtype: 'reg_PHONE',
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'textfield',
			fieldLabel: lang_maa_admin[9],
			id: 'MAA_adminEngineerEmail',
			name: 'adminEngineerEmail',
			msgTarget: 'side',
			vtype: 'email',
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'checkbox',
			boxLabel: lang_maa_admin[10],
			id: 'MAA_adminPwModify',
			name: 'adminPwModify',
			style: { marginBottom: '10px' },
			inputValue: true,
			listeners: {
				change: function() {
					Ext.getCmp('MAA_adminPw').setDisabled(!this.getValue());
					Ext.getCmp('MAA_adminRePw').setDisabled(!this.getValue());
				}
			}
		},
		{
			fieldLabel: lang_maa_admin[11],
			id: 'MAA_adminPw',
			name: 'adminPw',
			inputType: 'password',
			disabled: true,
			allowBlank: false,
			vtype: 'reg_PW',
			style: { marginLeft: '30px', marginBottom: '20px' }
		},
		{
			fieldLabel: lang_maa_admin[12],
			id: 'MAA_adminRePw',
			name: 'adminRePw',
			inputType: 'password',
			disabled: true,
			allowBlank: false,
			vtype: 'reg_PW',
			style: { marginLeft: '30px', marginBottom: '20px' }
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_maa_admin[13],
			id: 'MAA_adminFormButton',
			handler: function() {
				if (!MAA_adminForm.getForm().isValid())
					return false;

				var payload = {
					ID: Ext.getCmp('MAA_adminId').getValue(),
					Organization: Ext.getCmp('MAA_adminOrganization').getValue(),
					Phone: Ext.getCmp('MAA_adminPhone').getValue(),
					Email: Ext.getCmp('MAA_adminEmail').getValue(),
					Engineer: Ext.getCmp('MAA_adminEngineer').getValue(),
					EngineerPhone: Ext.getCmp('MAA_adminEngineerPhone').getValue(),
					EngineerEmail: Ext.getCmp('MAA_adminEngineerEmail').getValue(),
				};

				if (Ext.getCmp('MAA_adminPwModify').getValue() == true)
				{
					if (!Ext.getCmp('MAA_adminPw').getValue())
					{
						Ext.MessageBox.alert(lang_maa_admin[0], lang_maa_admin[15]);
						return false;
					}

					if (Ext.getCmp('MAA_adminPw').getValue()
						!= Ext.getCmp('MAA_adminRePw').getValue())
					{
						Ext.MessageBox.alert(lang_maa_admin[0], lang_maa_admin[14]);
						return false;
					}

					payload.Password = gms_encrypt(Ext.getCmp('MAA_adminPw').getValue());
				}

				waitWindow(lang_maa_admin[0], lang_maa_admin[16]);

				GMS.Ajax.request({
					url: '/api/manager/update',
					jsonData: payload,
					callback: function(options, success, response, decoded) {
						if (!success || !decoded.success)
							return;

						// 데이터 로드 성공 메세지
						Ext.MessageBox.alert(lang_maa_admin[0], lang_maa_admin[17]);
					},
				});
			}
		}
	]
});

// 계정 -> 관리자
Ext.define('/admin/js/manager_account_admin', {
	extend: 'BasePanel',
	id: 'manager_account_admin',
	load: function() { MAA_adminLoad(); },
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			bodyStyle: 'padding: 20px;',
			items: [MAA_adminForm]
		}
	]
});
