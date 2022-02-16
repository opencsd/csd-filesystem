/*
 * 페이지 로드 시 실행 함수
 */
function MAU_userLoad()
{
	// 초기 버튼 컨트롤
	Ext.getCmp('MAU_userModifyBtn').setDisabled(true);
	Ext.getCmp('MAU_userDelBtn').setDisabled(true);

	// 사용자 목록 로드
	MAU_userGrid.mask();
	MAU_userGridStore.load();

	/*
	if (licenseADS !== 'yes')
		return;
	*/

	// 사용자 인증 관련 데이터
	GMS.Ajax.request({
		url: '/api/cluster/auth/ads/info',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.getCmp('MAU_userLocationType')
				.setDisabled(!decoded.entity.Enabled);
		}
	});
};

/*
 * 생성, 수정 시 사용자 정보, 그룹 목록 로드
 */
function MAU_userDescLoad()
{
	MAU_userInfoGroupStore.clearFilter(true);
	MAU_userInfoGroupStore.removeAll(true);

	if (Ext.getCmp('MAU_userType').getValue() == 'Create')
	{
		// 생성일 경우 UI 변경
		Ext.getCmp('MAU_userPwModify').hide();
		Ext.getCmp('MAU_userPw').removeCls('m-custom-user-modify');
		Ext.getCmp('MAU_userRePw').removeCls('m-custom-user-modify');
		Ext.getCmp('MAU_userPw').setDisabled(false);
		Ext.getCmp('MAU_userRePw').setDisabled(false);
	}
	else if (Ext.getCmp('MAU_userType').getValue() == 'Modify')
	{
		GMS.Ajax.request({
			url: '/api/cluster/account/user/info',
			jsonData: {
				entity: {
					User_Name: Ext.getCmp('MAU_userName').getValue()
				}
			},
			callback: function (options, success, response, decoded) {
				// 예외 처리에 따른 동작
				if (!success || !decoded.success)
				{
					return;
				}

				var user = decoded.entity;

				if (!user.User_Name)
					return;

				// 사용자 상세 정보 로드
				Ext.getCmp('MAU_userName').setValue(user.User_Name);
				Ext.getCmp('MAU_userDesc').setValue(user.User_Desc);
				Ext.getCmp('MAU_userEmail').setValue(user.User_Email);

				// 수정일 경우 UI 변경
				Ext.getCmp('MAU_userPwModify').show();
				Ext.getCmp('MAU_userPw').addCls('m-custom-user-modify');
				Ext.getCmp('MAU_userRePw').addCls('m-custom-user-modify');
				Ext.getCmp('MAU_userPw').setDisabled(true);
				Ext.getCmp('MAU_userRePw').setDisabled(true);
			}
		});
	}

	// 생성, 수정 시 그룹 목록 받아오기
	MAU_userInfoGroupStore.load()
};

/*
 * 사용자 상세 정보 폼(생성, 수정), WINDOW
 */

// 사용자 생성폼: 스텝1
var MAU_userInfoDesc = Ext.create(
	'BasePanel',
	{
		id: 'MAU_userInfoDesc',
		bodyStyle: 'padding: 0;',
		layout: 'hbox',
		autoScroll: false,
		items: [
			{
				xtype: 'image',
				src: '/admin/images/bg_wizard.jpg',
				width: 150,
				height: 440
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						id: 'MAU_userAddDescContent1',
						html: lang_mau_user[3],
					},
					{
						xtype: 'BaseWizardContentPanel',
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mau_user[4] + '(1/2)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mau_user[5] + '(2/2)</li>'
							},
						],
					}
				],
			}
		],
	}
);

// 사용자 생성폼: 스텝2
var MAU_userInfoForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MAU_userInfoForm',
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
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mau_user[4],
					},
					{
						xtype: 'label',
						text: lang_mau_user[5],
					}
				],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mau_user[6],
					},
					{
						xtype: 'BaseWizardContentPanel',
						defaultType: 'textfield',
						items: [
							{
								fieldLabel: lang_mau_user[79]+lang_mau_user[7],
								id: 'MAU_userName',
								name: 'userName',
								allowBlank: false,
								vtype: 'reg_IdExcept',
								style: { marginBottom: '20px' }
							},
							{
								fieldLabel: '&nbsp'+lang_mau_user[8],
								id: 'MAU_userDesc',
								name: 'userDesc',
								vtype: 'reg_DESC',
								style: { marginBottom: '20px' }
							},
							{
								fieldLabel: lang_mau_user[79]+lang_mau_user[9],
								id: 'MAU_userEmail',
								name: 'userEmail',
								allowBlank: false,
								style: { marginBottom: '20px' },
								vtype: 'email'
							},
							{
								xtype: 'checkbox',
								boxLabel: lang_mau_user[10],
								id: 'MAU_userPwModify',
								name: 'userPwModify',
								style: { marginBottom: '10px' },
								listeners: {
									change: function () {
										Ext.getCmp('MAU_userPw').setDisabled(!this.getValue());
										Ext.getCmp('MAU_userRePw').setDisabled(!this.getValue());
									}
								}
							},
							{
								fieldLabel: lang_mau_user[79]+lang_mau_user[11],
								id: 'MAU_userPw',
								name: 'userPw',
								inputType: 'password',
								style: { marginBottom: '20px',marginRight: '20px' },
								allowBlank: false,
								vtype: 'reg_userPW'
							},
							{
								fieldLabel: lang_mau_user[79]+lang_mau_user[12],
								id: 'MAU_userRePw',
								name: 'userRePw',
								inputType: 'password',
								style: { marginBottom: '20px',marginRight: '20px' },
								allowBlank: false,
								vtype: 'reg_userPW'
							},
							{
								id: 'MAU_userType',
								name: 'userType',
								hidden : true
							}
						],
					}
				],
			}
		],
	}
);

// 사용자 생성폼: 스텝3

// 사용자별 그룹 모델(업데이트 내용 전달 모델)
Ext.define(
	'MAU_userInfoGroupTempModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Group_Name', 'Group_Member'],
	}
);

// 사용자별 그룹 스토어(업데이트 내용 전달 스토어)
var MAU_userInfoGroupTempStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MAU_userInfoGroupTempModel',
		idProperty: 'Group_Name'
	}
);

// 사용자별 그룹 정보 모델
Ext.define(
	'MAU_userInfoGroupModel',
	{
		extend: 'Ext.data.Model',
		pruneRemoved: false,
		fields: [
			'Group_Name', 'Group_Desc' ,'Group_Domain', 'Group_Location',
			'Group_Member'
		],
	}
);

// 각 사용자의 그룹 정보, 공유 정보 스토어
var MAU_userInfoGroupStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MAU_userInfoGroupModel',
		sorters: [
			{
				property: 'Group_Name',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/account/group/list',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
				getResponseData: function (response) {
					try {
						var json = Ext.decode(response.responseText),
							filter = Ext.getCmp('MAU_userGroupFilterName').getValue(),
							mtype  = Ext.getCmp('MAU_userGroupMatchType').getValue();

						console.debug('filter:', filter);
						console.debug('mtype:', mtype);

						var filtered = [];

						json.entity.forEach(
							function (item, idx, array)
							{
								console.debug('item:', item);

								var matched = item.Matched[filter];

								console.debug('matched:', matched);

								if (mtype == 'ALL'
									|| (mtype == 'MATCHED' && matched == 'true')
									|| (mtype == 'UNMATCHED' && matched == 'false'))
								{
									filtered.push(item);
								}
							}
						);

						console.debug('filtered:', filtered);

						json.entity = filtered;
						json.count  = filtered.length;

						console.debug('json:', json);

						return this.readRecords(json);
					}
					catch (ex) {
						console.error(ex);

						var error = new Ext.data.ResultSet({
							total: 0,
							count: 0,
							records: [],
							success: false,
							message: ex.message,
						});

						Ext.log('Unable to parse the response returned by the server as JSON format');
						return error;
					}
				},
			},
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 수정 데이터 제거
				MAU_userInfoGroupTempStore.removeAll();

				console.trace('extraParams(before):', store.proxy.extraParams);

				['LocationType', 'FilterName', 'FilterArgs', 'MatchType']
					.forEach(
						function (e)
						{
							store.proxy.setExtraParam(
								e,
								Ext.getCmp('MAU_userGroup' + e).getValue()
							);
						}
					);

				if (Ext.getCmp('MAU_userType').getValue() == 'Modify')
				{
					store.proxy.setExtraParam(
						'TempName',
						Ext.getCmp('MAU_userName').getValue()
					);
				}

				console.trace('extraParams(after):', store.proxy.extraParams);
			},
			load: function (store, records, success) {
				// 데이터 전송 완료 후 wait 제거
				if (waitMsgBox)
				{
					waitMsgBox.hide();
					waitMsgBox = null;
				}

				if (typeof(MAU_userInfoGroupGrid.el) != 'undefined')
					MAU_userInfoGroupGrid.unmask();

				// 예외 처리에 따른 동작
				if (success !== true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mau_user[0] + '",'
						+ '"content": "' + lang_mau_user[14] + '",'
						+ '"response": ' + jsonText
						+ '}';

					return exceptionDataCheck(checkValue);
				}

				// 그룹 정보 로드 시 그룹수 출력
				if (typeof(MAU_userInfoGroupGrid.el) != 'undefined')
				{
					document
						.getElementById('MAU_userInfoGroupGridHeaderTotalCount')
						.innerHTML
							= lang_mau_user[13]
								+ ': '
								+ store.proxy.reader.rawData.count;
				}

				MAU_userInfoWindow.show();
			},
			prefetch: function (store, records, success, operation, eOpts) {
				if (success !== true)
					return;

				console.debug('records:', records);

				var selected = [];

				records.forEach(
					function (item) {
						console.debug('item:', item);

						if (item.raw.Group_Member == 'true')
						{
							selected.push(item);
							return;
						}
					}
				);

				console.debug('selected:', selected);

				Ext.defer(
					function ()
					{
						MAU_userInfoGroupGrid
							.getSelectionModel()
							.select(selected , true);
					},
					200
				);
			}
		}
	}
);

var MAU_userInfoGroupGridSelModel = Ext.create(
	'Ext.selection.CheckboxModel',
	{
		columns: [
			{
				xtype : 'checkcolumn',
				dataIndex : 'Group_Member'
			}
		],
		pruneRemoved: false,
		checkOnly: true,
		listeners : {
			select: function (me, record, index, eOpts) {
				Ext.defer(function () {
					record.set('Group_Member', true);

					// 변경된 데이터만 저장
					if (String(record.raw.Group_Member)
						!= String(record.data.Group_Member))
					{
						MAU_userInfoGroupTempStore.add(record);
					}
				}, 50);
			},
			deselect: function (me, record, index, eOpts) {
				Ext.defer(function () {
					record.set('Group_Member', false);

					// 변경된 데이터만 저장
					if (String(record.raw.Group_Member)
						!= String(record.data.Group_Member))
					{
						MAU_userInfoGroupTempStore.add(record);
					}
				}, 50);
			}
		}
	}
);

// 각 사용자의 그룹 그리드
var MAU_userInfoGroupGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAU_userInfoGroupGrid',
		store: MAU_userInfoGroupStore,
		selModel: MAU_userInfoGroupGridSelModel,
		title: lang_mau_user[15],
		height: 310,
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'panel',
					id: 'MAU_userInfoGroupGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 200,
					height: 16
				},
			],
		},
		columns: [
			{
				flex: 1,
				dataIndex: 'Group_Name',
				text: lang_mau_user[16],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Desc',
				text: lang_mau_user[17],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Location',
				text: lang_mau_user[18],
				sortable: true,
				menuDisabled: true
			},
		],
		tbar: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAU_userGroupMatchType',
				hiddenName: 'userGroupMatchType',
				name: 'userGroupMatchType',
				store: new Ext.data.SimpleStore({
					fields: ['MatchType', 'MatchCode'],
					data: [
						[lang_mau_user[19], 'ALL'],
						[lang_mau_user[20], 'MATCHED'],
						[lang_mau_user[21], 'UNMATCHED'],
					],
				}),
				value: 'ALL',
				displayField: 'MatchType',
				valueField: 'MatchCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MAU_userDescLoad();
					},
				},
			},
			{
				xtype: 'BaseComboBox',
				hidden: true,
				hideLabel: true,
				id: 'MAU_userGroupLocationType',
				hiddenName: 'userGroupLocationType',
				name: 'userGroupLocationType',
				store: new Ext.data.SimpleStore({
						fields: ['LocationType', 'LocationCode'],
						data: [
							[lang_mau_user[22], 'LOCAL'],
							['LDAP', 'LDAP'],
							['Active Directory', 'ADS'],
						],
					}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MAU_userDescLoad();
					},
				},
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAU_userGroupFilterName',
				hiddenName: 'userGroupFilterName',
				name: 'userGroupFilterName',
				store: new Ext.data.SimpleStore({
						fields: ['FilterName', 'FilterCode'],
						data: [
							[lang_mau_user[23], 'Group_Name'],
							[lang_mau_user[24], 'Group_Desc'],
							[lang_mau_user[82], 'MemberOf'],
						],
					}),
				value: 'Group_Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mau_user[25],
			{
				xtype: 'searchfield',
				id: 'MAU_userGroupFilterArgs',
				store: MAU_userInfoGroupStore,
				paramName: 'FilterArgs',
				width: 135,
			},
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		},
	}
);

// 그룹 지정
var MAU_userInfoGroup = Ext.create(
	'BaseFormPanel',
	{
		id: 'MAU_userInfoGroup',
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
				width: 150,
				items: [
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mau_user[4],
					},
					{
						xtype: 'label',
						style: 'line-height: 16px !important; fontWeight: bold;',
						text: lang_mau_user[5],
					},
				],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mau_user[27],
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align : 'stretch'
						},
						items: [MAU_userInfoGroupGrid],
					},
				],
			},
		],
	}
);

// 사용자 생성 윈도우
var MAU_userInfoWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MAU_userInfoWindow',
		layout: 'card',
		title: lang_mau_user[26],
		maximizable: false,
		autoHeight: true,
		width: 720,
		height: 500,
		activeItem: 0,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MAU_userInfoDescPanel',
				items: [MAU_userInfoDesc],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MAU_userInfoFormPanel',
				items: [MAU_userInfoForm],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MAU_userInfoGroupPanel',
				items: [MAU_userInfoGroup],
			},
		],
		fbar: [
			{
				text: lang_mau_user[74],
				width: 70,
				disabled: false,
				border: true,
				handler: function () { MAU_userInfoWindow.close(); },
			},
			'->',
			{
				text: lang_mau_user[28],
				id: 'MAU_userInfoWindowPreBtn',
				width: 70,
				disabled: true,
				handler: function () {
					var curr_panel = MAU_userInfoWindow.layout.activeItem;
					var curr_idx   = MAU_userInfoWindow.items.indexOf(curr_panel);

					MAU_userInfoWindow.layout.setActiveItem(--curr_idx);

					if (curr_idx == 0)
					{
						Ext.getCmp('MAU_userInfoWindowPreBtn').hide();
					}
					else
					{
						// 다음 버튼
						Ext.getCmp('MAU_userInfoWindowNextBtn').show();
						Ext.getCmp('MAU_userInfoWindowNextBtn').enable();

						// 확인 버튼
						Ext.getCmp('MAU_userInfoWindowSetBtn').hide();
						Ext.getCmp('MAU_userInfoWindowSetBtn').disable();
					}
				},
			},
			{
				text: lang_mau_user[29],
				id: 'MAU_userInfoWindowNextBtn',
				width: 70,
				handler: function () {
					var curr_panel = MAU_userInfoWindow.layout.activeItem;
					var curr_idx   = MAU_userInfoWindow.items.indexOf(curr_panel);

					MAU_userInfoWindow.layout.setActiveItem(++curr_idx);

					// 버튼 컨트롤
					Ext.getCmp('MAU_userInfoWindowPreBtn').show();
					Ext.getCmp('MAU_userInfoWindowPreBtn').enable();

					if (MAU_userInfoWindow.layout.getActiveItem().id
						!= 'MAU_userInfoGroupPanel')
					{
						Ext.getCmp('MAU_userInfoWindowSetBtn').hide();
						Ext.getCmp('MAU_userInfoWindowSetBtn').disable();

						return;
					}

					// 생성일 때 사용자 ID 중복 확인
					if (Ext.getCmp('MAU_userType').getValue() == 'Create')
					{
						var dup_id = false;

						MAU_userGridStore.proxy.reader.rawData.entity
							.forEach(
								function (record)
								{
									if (record.User_Name
										== Ext.getCmp('MAU_userName').getValue())
									{
										dup_id = true;
									}
								}
							);

						if (dup_id == true)
						{
							MAU_userInfoWindow.layout
								.setActiveItem('MAU_userInfoFormPanel');

							Ext.MessageBox.alert(
								lang_mau_user[0],
								lang_mau_user[75]
							);

							return false;
						}
					}

					if (Ext.getCmp('MAU_userPw').getValue()
						!= Ext.getCmp('MAU_userRePw').getValue())
					{
						MAU_userInfoWindow.layout
							.setActiveItem('MAU_userInfoFormPanel');

						Ext.MessageBox.alert(
							lang_mau_user[0],
							lang_mau_user[31]
						);

						return false;
					}

					if (!MAU_userInfoForm.getForm().isValid())
					{
						MAU_userInfoWindow.layout
							.setActiveItem('MAU_userInfoFormPanel');

						return false;
					}

					// store가 LOAD 되었는지 확인 후 MASK SHOW
					if (MAU_userInfoGroupStore.isLoading())
					{
						MAU_userInfoGroupGrid.mask('Loading...');
					}

					// 다음 버튼
					Ext.getCmp('MAU_userInfoWindowNextBtn').hide();
					Ext.getCmp('MAU_userInfoWindowNextBtn').disable();

					// 확인 버튼
					Ext.getCmp('MAU_userInfoWindowSetBtn').show();
					Ext.getCmp('MAU_userInfoWindowSetBtn').enable();
				},
			},
			{
				text: lang_mau_user[30],
				id: 'MAU_userInfoWindowSetBtn',
				width: 70,
				disabled: true,
				handler: function () {
					if (!MAU_userInfoForm.getForm().isValid())
						return false;

					// 패스워드와 패스워드 확인 필드 예외 처리
					if (Ext.getCmp('MAU_userPwModify').getValue() == true
						|| Ext.getCmp('MAU_userType').getValue() == 'Create')
					{
						if (Ext.getCmp('MAU_userPw').getValue()
							!= Ext.getCmp('MAU_userRePw').getValue())
						{
							Ext.MessageBox.alert(
								lang_mau_user[0],
								lang_mau_user[31]
							);

							return false;
						}
					}

					// 사용자 정보
					var payload = {
						User_Name: Ext.getCmp('MAU_userName').getValue(),
						User_Desc: null,
						User_Email: null,
						User_Password: null,
						User_Groups: [],
					};

					if (MAU_userInfoForm.isDirty())
					{
						var fields
							= MAU_userInfoForm.getForm().getFields().items;

						for (var i=0; i<fields.length; i++)
						{
							if (!fields[i].isDirty()
									|| !Ext.isDefined(fields[i].name))
								continue;

							var fieldName  = fields[i].name;
							var fieldValue = fields[i].lastValue;

							switch (fieldName)
							{
								case 'userDesc':
									payload.User_Desc = fieldValue;
									break;
								case 'userEmail':
									payload.User_Email = fieldValue;
									break;
								case 'userPw':
									payload.User_Password = gms_encrypt(fieldValue);
									break;
							}
						}
					}

					// 변경된 그룹 데이터 정보
					MAU_userInfoGroupTempStore.getUpdatedRecords()
						.forEach(
							function (record) {
								var groupDataobj = {
									Group_Name: record.data.Group_Name,
									Group_Member: record.data.Group_Member
													? 'true' : 'false',
								};

								payload.User_Groups.push(groupDataobj);
							}
						);

					var url;
					var title;
					var msg_success;
					var msg_failure;

					// 생성
					if (Ext.getCmp('MAU_userType').getValue() == 'Create')
					{
						url         = '/api/cluster/account/user/create';
						title       = lang_mau_user[32];
						msg_success = lang_mau_user[33];
						msg_failure = lang_mau_user[34];
					}
					// 수정
					else if (Ext.getCmp('MAU_userType').getValue() == 'Modify')
					{
						url         = '/api/cluster/account/user/update';
						title       = lang_mau_user[35];
						msg_success = lang_mau_user[36];
						msg_failure = lang_mau_user[37];
					}

					waitWindow(lang_mau_user[0], title);

					GMS.Ajax.request({
						url: url,
						jsonData: {
							entity: payload
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
							{
								return;
							}

							MAU_userInfoWindow.close();

							// 데이터 로드 성공 메세지
							Ext.MessageBox.show({
								title: lang_mau_user[0],
								msg: msg_success,
								buttons: Ext.MessageBox.OK,
								fn : function () { MAU_userLoad(); }
							});
						},
					});
				},
			},
		],
	}
);

/*
 * 사용자 일괄등록
 */

// 사용자 일괄등록 그리드
// 사용자 정보 모델
Ext.define(
	'MAU_userFileuploadGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'User_Name', 'User_Desc', 'User_Email', 'User_Password',
			'User_Result', 'User_Errors'
		],
	}
);

//사용자 정보 스토어
var MAU_userFileuploadGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MAU_userFileuploadGridModel',
		sorters: [
			{ property: 'User_Name', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'userListData'
			},
		},
	}
);

/** 사용자 정보 그리드 **/
var MAU_userFileuploadGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAU_userFileuploadGrid',
		store: MAU_userFileuploadGridStore,
		title: lang_mau_user[38],
		height: 330,
		multiSelect: false,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				selectall: function () {
					MAU_userFileSelect('selectAll');
				},
				deselectall: function () {
					MAU_userFileSelect('deselectAll');
				},
			},
		},
		columns: [
			{
				flex: 1,
				text: lang_mau_user[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'User_Name'
			},
			{
				flex: 1,
				text: lang_mau_user[8],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'User_Desc'
			},
			{
				flex: 1,
				text: lang_mau_user[9],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'User_Email'
			},
			{
				flex: 1,
				text: lang_mau_user[11],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'User_Password'
			},
			{
				flex: 1,
				text: lang_mau_user[39],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'User_Result'
			},
		],
		tbar: [
			{
				text: lang_mau_user[40],
				id: 'MAU_userFileuploadDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mau_user[0],
						lang_mau_user[41],
						function (btn, text) {
							if (btn !== 'yes')
								return;

							var deleteData = [];
							var records = MAU_userFileuploadGrid
											.getSelectionModel()
											.getSelection();

							for (var i=0, len=records.length; i<len; i++)
							{
								deleteData.push(records[i]);
							}

							MAU_userFileuploadGridStore.remove(deleteData);
						}
					);
				},
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MAU_userFileSelect(record) }, 200);
			},
			itemdblclick: function (dataview, record, item, index, e) {
				if (record.data.User_Result.toUpperCase() !== 'ERROR')
					return;

				var errorArrayStr = '';
				var errorStr = record.data.User_Errors;

				for (var i=0; i<errorStr.length; i++)
				{
					errorArrayStr = errorArrayStr
									+ eval(errorStr[i])
										.replace('@', lang_mau_user[0]) + '<br>';
				}

				Ext.MessageBox.alert(lang_mau_user[0], errorArrayStr);
			},
		},
		viewConfig: {
			forceFit: true,
			getRowClass: function (record, rowIndex, p, store) {
				var statusRowValue = record.data.User_Result.toUpperCase();

				if (statusRowValue == 'ERROR')
				{
					return 'm-custom-user-bundle';
				}
			},
		},
	}
);

// 일괄 등록 그리드 선택 시 버튼 컨트롤
function MAU_userFileSelect(record)
{
	var selectCount = MAU_userFileuploadGrid.getSelectionModel().getCount();

	if (selectCount > 1)
	{
		Ext.getCmp('MAU_userFileuploadDelBtn').setDisabled(false);
	}
	else if (selectCount == 1)
	{
		Ext.getCmp('MAU_userFileuploadDelBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MAU_userFileuploadDelBtn').setDisabled(true);
	}
};

// 사용자 일괄 등록 폼
var MAU_userFileuploadForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MAU_userFileuploadForm',
		bodyStyle: 'padding: 10px; padding-top: 20px;',
		width: 700,
		height: 520,
		defaults: {
			anchor: '100%',
			allowBlank: false
		},
		items: [
			{
				xtype: 'filefield',
				id: 'MAU_userInfoFile',
				name: 'userInfoFile',
				anchor: '40%',
				emptyText: lang_mau_user[42],
				fieldLabel: lang_mau_user[43],
				buttonOnly: true,
				buttonText: lang_mau_user[44],
				buttonConfig: { conCls: 'b-icon-upload' },
				allowBlank: false,
				vtype: 'reg_userFile',
				listeners: {
					hange: function (filefield, value, eOpts) {
						if (!Ext.getCmp('MAU_userFileuploadForm').getForm().isValid())
							return false;

						waitWindow(lang_mau_user[0], lang_mau_user[45]);

						Ext.getCmp('MAU_userFileuploadForm').getForm().submit({
							method: 'POST',
							url: '/api/cluster/account/user/batch_validate',
							success: function (form, action) {
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								// 메세지 출력
								var msg = action.result.msg || lang_mau_user[46];

								Ext.MessageBox.alert(lang_mau_user[0], msg);
								MAU_userFileuploadGridStore.loadRawData(action.result.userListData);
							},
							failure: function (form, action) {
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
									+ '"title": "' + lang_mau_user[0] + '",'
									+ '"content": "' + lang_mau_user[47] + '",'
									+ '"response": ' + jsonText
								+ '}';

								exceptionDataCheck(checkValue);
							}
						});
					},
				},
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0px;',
				style: { marginTop: '20px' },
				html: lang_mau_user[48],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0px;',
				html: lang_mau_user[49],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0px;',
				html: lang_mau_user[50],
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding-top: 20px;',
				items: [MAU_userFileuploadGrid],
			},
		],
		buttons: [
			{
				text: lang_mau_user[51],
				handler: function () {
					var userFileAddData = [];
					var userPasswd = '';

					MAU_userFileuploadGridStore.data.items
						.forEach(
							function (item) {
								// 필드가 패스워드일 경우
								userPasswd = AesCtr.encrypt(
									item.data.User_Password,
									Ext.util.Cookies.get('gms_token'),
									256
								);

								if (item.data.User_Result.toUpperCase() == 'ERROR')
									return;

								var userFileAddDataobj = '{'
									+ '"User_Name": "' + item.data.User_Name + '",'
									+ '"User_Desc": "' + item.data.User_Desc + '",'
									+ '"User_Email": "' + item.data.User_Email + '",'
									+ '"User_Password": "' + userPasswd + '"'
									+ '}';

								userFileAddData.push(userFileAddDataobj);
							}
						);

					var encodedJsonSetData = new Array(userFileAddData);
					var encodedJsonSetData = "[" + encodedJsonSetData + "]";

					waitWindow(lang_mau_user[0], lang_mau_user[52]);

					GMS.Ajax.request({
						url: '/api/cluster/account/user/batch_create',
						jsonData: {
							entity: {
								userList: encodedJsonSetData
							},
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
							{
								return;
							}

							MAU_userFileuploadWindow.hide();

							Ext.MessageBox.show({
								title: lang_mau_user[0],
								msg: lang_mau_user[53],
								buttons: Ext.MessageBox.OK,
								fn : function () { MAU_userLoad(); },
							});
						},
					});
				},
			},
			{
				text: lang_mau_user[74],
				scope: this,
				handler: function () {
					MAU_userFileuploadWindow.hide();
				},
			},
		],
	}
);

// 사용자 일괄 등록 WINDOW
var MAU_userFileuploadWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MAU_userFileuploadWindow',
		animateTarget: Ext.getCmp('MAU_userLumpAddBtn'),
		title: lang_mau_user[55],
		maximizable: false,
		autoHeight: true,
		border: false,
		items: [MAU_userFileuploadForm],
	}
);


/*
 * 각 사용자의 그룹정보
 */
// 사용자별 그룹 정보 모델
Ext.define(
	'MAU_userSelectGroupModel',
	{
		extend: 'Ext.data.Model',
		pruneRemoved: false,
		fields: [
			'Group_Name', 'Group_Desc' ,'Group_Domain', 'Group_Location',
			'Group_Member'
		],
	}
);

// 각 사용자의 그룹 정보, 공유 정보 스토어
var MAU_userSelectGroupStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MAU_userSelectGroupModel',
		sorters: [
			{ property: 'Group_Name', direction: 'ASC' },
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/account/group/list',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
				getResponseData: function (response) {
					try {
						var json = Ext.decode(response.responseText);

						var filtered = [];

						json.entity.forEach(
							function (item, idx, array)
							{
								console.debug('item:', item);

								var matched = item.Matched['MemberOf'];

								console.debug('matched:', matched);

								if (matched == 'true')
								{
									filtered.push(item);
								}
							}
						);

						console.debug('filtered:', filtered);

						json.entity = filtered;
						json.count  = filtered.length;

						console.debug('json:', json);

						return this.readRecords(json);
					}
					catch (ex) {
						console.error(ex);

						var error = new Ext.data.ResultSet({
							total: 0,
							count: 0,
							records: [],
							success: false,
							message: ex.message,
						});

						Ext.log('Unable to parse the response returned by the server as JSON format');
						return error;
					}
				},
			},
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();

				var user = MAU_userGrid
							.getSelectionModel()
							.getSelection()[0]
							.get('User_Name');

				var loc = Ext.getCmp('MAU_userLocationType').getValue();

				store.proxy.setExtraParam('LocationType', loc);
				store.proxy.setExtraParam('MatchType', 'MATCHED');
				store.proxy.setExtraParam('FilterName', 'MemberOf');
				store.proxy.setExtraParam('FilterArgs', user);
			},
			load: function (store, records, success) {
				// 데이터 전송 완료 후 wait 제거
				if (waitMsgBox)
				{
					waitMsgBox.hide();
					waitMsgBox = null;
				}

				if (success == true)
					return;

				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mau_user[0] + '",'
					+ '"content": "' + lang_mau_user[14] + '",'
					+ '"response": ' + jsonText
				+ '}';

				exceptionDataCheck(checkValue);
			},
		},
	}
);

// 각 사용자의 그룹 그리드
var MAU_userSelectGroupGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAU_userSelectGroupGrid',
		store: MAU_userSelectGroupStore,
		title: lang_mau_user[15],
		height: 275,
		columns: [
			{
				flex: 1,
				dataIndex: 'Group_Name',
				text: lang_mau_user[16],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Desc',
				text: lang_mau_user[17],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Location',
				text: lang_mau_user[18],
				sortable: true,
				menuDisabled: true
			},
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
		},
	}
);

// 사용자의 그룹 정보 Window
var MAU_userSelectGroupWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MAU_userSelectGroupWindow',
		title: lang_mau_user[15],
		maximizable: false,
		autoHeight: true,
		width: 640,
		height: 430,
		items: [
			{
				xtype: 'BasePanel',
				id: 'MAU_userSelectGroupPanel',
				bodyStyle: 'padding: 25px 30px 30px 30px;',
				items: [
					{
						border: false,
						style: { marginBottom: '20px' },
						html: lang_mau_user[77],
					},
					{
						border: false,
						items: [MAU_userSelectGroupGrid],
					},
				],
			},
		],
		buttons: [
			{
				text: lang_mau_user[78],
				handler: function () { MAU_userSelectGroupWindow.hide(); },
			},
		],
	}
);

/*
 * 사용자 정보 그리드
 */
// 사용자 정보 모델
Ext.define(
	'MAU_userGridModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'User_Name', 'User_Domain', 'User_HomeDir', 'User_Location',
			'User_FullName', 'User_Office', 'User_OfficePhone', 'User_HomePhone',
			'User_Email', 'User_Desc'
		],
	}
);

// 사용자 정보 스토어
var MAU_userGridStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MAU_userGridModel',
		sorters: [
			{ property: 'User_Name', direction: 'ASC' },
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/account/user/list',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
				getResponseData: function (response) {
					console.log('response:', response);

					try {
						var json = Ext.decode(response.responseText),
							filter = Ext.getCmp('MAU_userFilterName').getValue();

						console.debug('filter:', filter);

						var filtered = [];

						json.entity.forEach(
							function (item, idx, array)
							{
								console.debug('item:', item);

								if (!item.hasOwnProperty('Matched'))
								{
									filtered.push(item);
									return;
								}

								if (!item.Matched.hasOwnProperty(filter))
								{
									filtered.push(item);
									return;
								}

								var matched = item.Matched[filter];

								if (matched == 'true')
								{
									filtered.push(item);
								}
							}
						);

						console.debug('filtered:', filtered);

						json.entity = filtered;
						json.count  = filtered.length;

						console.debug('json:', json);

						return this.readRecords(json);
					}
					catch (ex) {
						console.error(ex);

						var error = new Ext.data.ResultSet({
							total: 0,
							count: 0,
							records: [],
							success: false,
							message: ex.message,
						});

						Ext.log('Unable to parse the response returned by the server as JSON format');
						return error;
					}
				},
			},
			listeners: {
				exception: function (me, response, operation, eOpts) {
					console.debug('me:', me);
					console.debug('response:', response);
					console.debug('operation:', operation);
					console.debug('eOpts:', eOpts);

					if (operation.error.status == 0)
					{
						Ext.MessageBox.show({
							title: 'Communication failed',
							msg: 'Communication failed',
							icon: Ext.MessageBox.ERROR,
							buttons: Ext.MessageBox.OK,
						});
					}
				},
			},
		},
		listeners: {
			load: function (store, records, success) {
				if (!success)
				{
					return;
				}

				document.getElementById('MAU_userGridHeaderTotalCount').innerHTML
					= lang_mau_user[57] + ': ' + store.proxy.reader.rawData.count;

				MAU_userGrid.unmask();
			},
		},
	}
);

// 사용자 정보 그리드
var MAU_userGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAU_userGrid',
		store: MAU_userGridStore,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			renderer: function (val, meta, record, rowIndex, colIndex, store, view) {
				var status = record.data['User_Location'].toLowerCase();

				if (status !== 'local')
					return null;

				meta.tdCls = Ext.baseCSSPrefix + 'grid-cell-special';

				return '<div class="'
						+ Ext.baseCSSPrefix
						+ 'grid-row-checker">&#160;</div>';
			},
			listeners: {
				selectall: function () {
					MAU_userSelect('selectAll');
				},
				deselectall: function () {
					MAU_userSelect('deselectAll');
				},
			},
		},
		title: lang_mau_user[59],
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'panel',
					id: 'MAU_userGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 200,
					height: 16
				},
			],
		},
		columns: [
			{
				flex: 1,
				text: lang_mau_user[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'User_Name'
			},
			{
				flex: 1,
				text: lang_mau_user[8],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'User_Desc'
			},
			{
				flex: 1,
				text: lang_mau_user[60],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'User_HomeDir'
			},
			{
				flex: 1,
				text: lang_mau_user[9],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'User_Email'
			},
			{
				flex: 1,
				text: lang_mau_user[15],
				sortable: false,
				menuDisabled: true,
				xtype: 'componentcolumn',
				autoWidthComponents: false,
				renderer: function (value, metaData, record) {
					return {
						xtype: 'button',
						width: 120,
						text: lang_mau_user[15],
						handler: function () {
							// 선택된 버튼의 row 활성화
							MAU_userGrid.getSelectionModel().deselectAll();
							MAU_userGrid.getSelectionModel().select(record, true);

							waitWindow(lang_mau_user[59], lang_mau_user[76]);

							MAU_userSelectGroupWindow.show();

							Ext.defer(function () {
								MAU_userSelectGroupStore.load();
							}, 200);
						},
					};
				},
			},
		],
		tbar: [
			{
				text: lang_mau_user[61],
				id: 'MAU_userCreateBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					waitWindow(lang_mau_user[0], lang_mau_user[80]);

					// 페이지 로드 시 사용자 정보 초기화
					MAU_userInfoForm.getForm().reset();

					// 전달할 그룹 리스트 스토어 초기화
					MAU_userInfoGroupTempStore.removeAll();

					// 생성을 위한 메세지
					MAU_userInfoWindow.setTitle(lang_mau_user[51]);

					// 첫번째 페이지 로드
					MAU_userInfoWindow.layout.setActiveItem('MAU_userInfoDescPanel');
					Ext.getCmp('MAU_userAddDescContent1').update(lang_mau_user[62]);

					// WINDOW OPEN 시 동작
					MAU_userInfoWindow.animateTarget = Ext.getCmp('MAU_userCreateBtn');
					Ext.getCmp('MAU_userType').setValue('Create');

					// 사용자 아이디 수정가능
					Ext.getCmp('MAU_userName').setDisabled(false);

					Ext.getCmp('MAU_userInfoWindowNextBtn').show();
					Ext.getCmp('MAU_userInfoWindowNextBtn').enable();
					Ext.getCmp('MAU_userInfoWindowPreBtn').hide();
					Ext.getCmp('MAU_userInfoWindowSetBtn').hide();

					Ext.getCmp('MAU_userGroupLocationType').setValue('LOCAL');
					Ext.getCmp('MAU_userGroupFilterName').setValue('Group_Name');
					Ext.getCmp('MAU_userGroupFilterArgs').setValue();
					Ext.getCmp('MAU_userGroupMatchType').setValue('ALL');

					MAU_userDescLoad();
				},
			},
			{
				text: lang_mau_user[63],
				id: 'MAU_userModifyBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function () {
					waitWindow(lang_mau_user[0], lang_mau_user[81]);

					// 페이지 로드 시 사용자 정보 초기화
					MAU_userInfoForm.getForm().reset();

					// 전달할 그룹 리스트 스토어 초기화
					MAU_userInfoGroupTempStore.removeAll();

					// 선택된 사용자 정보 전달: 사용자아이디
					var selection
						= MAU_userGrid.getSelectionModel().getSelection();

					var username = selection[0].get('User_Name');

					// 수정을 위한 메세지
					MAU_userInfoWindow.setTitle(lang_mau_user[64]);

					Ext.getCmp('MAU_userAddDescContent1')
						.update('[' + username + '] ' + lang_mau_user[65]);

					// 첫번째 페이지 로드
					MAU_userInfoWindow.layout
						.setActiveItem('MAU_userInfoDescPanel');

					// WINDOW OPEN 시 동작
					MAU_userInfoWindow.animateTarget
						= Ext.getCmp('MAU_userModifyBtn');

					Ext.getCmp('MAU_userType').setValue('Modify');

					// 사용자 아이디 수정 못 함
					Ext.getCmp('MAU_userName').setDisabled(true);
					Ext.getCmp('MAU_userName').setValue(username);

					Ext.getCmp('MAU_userInfoWindowNextBtn').show();
					Ext.getCmp('MAU_userInfoWindowNextBtn').enable();
					Ext.getCmp('MAU_userInfoWindowPreBtn').hide();
					Ext.getCmp('MAU_userInfoWindowSetBtn').hide();

					Ext.getCmp('MAU_userGroupLocationType').setValue('LOCAL');
					Ext.getCmp('MAU_userGroupFilterName').setValue('MemberOf');
					Ext.getCmp('MAU_userGroupFilterArgs').setValue(username);
					Ext.getCmp('MAU_userGroupMatchType').setValue('ALL');

					MAU_userDescLoad();
				},
			},
			{
				text: lang_mau_user[66],
				id: 'MAU_userDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mau_user[0],
						lang_mau_user[67],
						function (btn, text) {
							if (btn !== 'yes')
								return ;

							// 선택된 그리드의 전송값 추출
							var userList
								= MAU_userGrid.getSelectionModel().getSelection();

							var targets = [];

							for (var i=0, len=userList.length; i<len; i++)
							{
								targets.push(userList[i].data.User_Name);
							}

							waitWindow(lang_mau_user[0], lang_mau_user[68]);

							GMS.Ajax.request({
								url: '/api/cluster/account/user/delete',
								jsonData: {
									entity: {
										User_Names: targets
									},
								},
								callback: function (options, success, response, decoded) {
									// 예외 처리에 따른 동작
									if (!success || !decoded.success)
									{
										return;
									}

									Ext.MessageBox.show({
										title: lang_mau_user[0],
										msg: lang_mau_user[69],
										buttons: Ext.MessageBox.OK,
										fn : function () { MAU_userLoad(); },
									});
								},
							});
						}
					);
				},
			},
			/*
			{
				text: lang_mau_user[71],
				id: 'MAU_userLumpAddBtn',
				tooltip: lang_mau_user[71],
				iconCls: 'b-icon-user-regi',
				handler: function () {
					MAU_userFileuploadGridStore.removeAll();
					MAU_userFileuploadWindow.show();
				},
			},
			*/,
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAU_userLocationType',
				hiddenName: 'userLocationType',
				name: 'userLocationType',
				store: new Ext.data.SimpleStore({
						fields: ['LocationType', 'LocationCode'],
						data: [
							[lang_mau_user[72], 'LOCAL'],
							['LDAP', 'LDAP'],
							['Active Directory', 'ADS'],
						],
					}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MAU_userLoad();
					},
				},
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAU_userFilterName',
				hiddenName: 'userFilterName',
				name: 'userFilterName',
				store: new Ext.data.SimpleStore({
						fields: ['FilterName', 'FilterCode'],
						data: [
							[lang_mau_user[7], 'User_Name'],
							[lang_mau_user[8], 'User_Desc'],
							[lang_mau_user[9], 'User_Email'],
						],
					}),
				value: 'User_Name',
				displayField: 'FilterName',
				valueField: 'FilterCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						Ext.getCmp('MAU_userFilterArgs').store.proxy.extraParams
							= {
								LocationType: Ext.getCmp('MAU_userLocationType').getValue(),
								FilterName: newValue,
							};
					},
					afterrender: function (combo) {
						Ext.getCmp('MAU_userFilterArgs').store.proxy.extraParams
							= {
								LocationType: Ext.getCmp('MAU_userLocationType').getValue(),
								FilterName: combo.getValue(),
							};
					},
				},
			},
			'-',
			lang_mau_user[25],
			{
				xtype: 'searchfield',
				id: 'MAU_userFilterArgs',
				store: MAU_userGridStore,
				paramName: 'FilterArgs',
				width: 180
			},
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MAU_userSelect(record) }, 200);
			},
			/*
			itemdblclick: function (dataview, record, item, index, e) {
				// 사용자 정보그리드 더블클릭시 동작
				alert('dblclick');
			},
			select: function (model, record, index) {
				if (record.data.User_Location.toLowerCase() != 'local')
				{
					//도메인이 local 이 아닌경우 선택 할수 없음
					MAU_userGrid.getSelectionModel().deselect(index);
				}
			},
			*/
		},
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		},
	}
);

// 사용자 목록 선택 시
function MAU_userSelect(record)
{
	var count = MAU_userGrid.getSelectionModel().getCount();

	if (count > 1)
	{
		Ext.getCmp('MAU_userModifyBtn').setDisabled(true);
		Ext.getCmp('MAU_userDelBtn').setDisabled(false);
	}
	else if (count == 1)
	{
		Ext.getCmp('MAU_userModifyBtn').setDisabled(false);
		Ext.getCmp('MAU_userDelBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MAU_userModifyBtn').setDisabled(true);
		Ext.getCmp('MAU_userDelBtn').setDisabled(true);
	}

	var select = MAU_userGrid.getSelectionModel();

	select.getSelection().forEach(
		function (r) {
			if (r.data.User_Name == 'admin')
			{
				Ext.getCmp('MAU_userModifyBtn').setDisabled(true);
				Ext.getCmp('MAU_userDelBtn').setDisabled(true);
			}
		}
	);
};

// 사용자 설정
Ext.define(
	'/admin/js/manager_account_user',
	{
		extend: 'BasePanel',
		id: 'manager_account_user',
		load: function () { MAU_userLoad(); },
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'BasePanel',
				layout: 'fit',
				bodyStyle: 'padding: 20px;',
				items: [MAU_userGrid],
			},
		],
	}
);
