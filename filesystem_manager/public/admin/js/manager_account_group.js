/*
 * 페이지 로드 시 실행 함수
 */
function MAG_groupLoad()
{
	// 초기 버튼 컨트롤
	Ext.getCmp('MAG_groupModifyBtn').setDisabled(true);
	Ext.getCmp('MAG_groupDelBtn').setDisabled(true);

	// buffered STORE 데이터 리셋
	MAG_groupGridStore.clearData();

	// 그룹 목록 로드
	MAG_groupGridStore.load();

	/*
	if (licenseADS == 'yes')
	{
		// 그룹 인증 관련 데이터 호출
		GMS.Ajax.request({
			url: '/api/cluster/auth/info',
			callback: function (options, success, response, decoded) {
				if (!success || !decoded.success)
				{
					return;
				}

				if (decoded.entity.LDAP.Enabled == 'true'
					|| decoded.entity.ADS.Enabled == 'true')
				{
					Ext.getCmp('MAG_groupLocationType').setDisabled(false);
				}
				else
				{
					Ext.getCmp('MAG_groupLocationType').setDisabled(true);
				}
			}
		});
	}
	*/
};

/*
 * 생성, 수정 시 사용자 정보, 그룹 목록 로드
 */
function MAG_groupDescLoad(GroupName)
{
	MAG_groupInfoUserStore.clearFilter(true);
	MAG_groupInfoUserStore.removeAll(true);

	Ext.getCmp('MAG_groupUserStoreLoad').setValue(false);

	// 그룹 정보 받아오기
	if (Ext.getCmp('MAG_groupType').getValue() != 'Modify')
	{
		// 생성, 수정 시 그룹 목록 받아오기
		return MAG_groupInfoUserStore.load();
	}

	GMS.Ajax.request({
		url: '/api/cluster/account/group/info',
		jsonData: {
			entity: {
				Group_Name: GroupName
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			if (!GroupName)
				return;

			// 그룹 상세 정보 로드
			var group = decoded.entity;

			Ext.getCmp('MAG_groupName').setValue(group.Group_Name);
			Ext.getCmp('MAG_groupDesc').setValue(group.Group_Desc);

			// 생성, 수정 시 그룹 목록 받아오기
			MAG_groupInfoUserStore.load();
		}
	});
};

/*
 * 그룹 상세 정보 폼(생성, 수정), WINDOW
 */
/*
 * 그룹 생성폼: 스텝1
 */
var MAG_groupInfoDesc = Ext.create(
	'BasePanel',
	{
		id: 'MAG_groupInfoDesc',
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
						id: 'MAG_groupAddDescContent1',
						html: lang_mag_group[3]
					},
					{
						xtype: 'BaseWizardContentPanel',
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mag_group[4] + '(1/2)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mag_group[5] + '(2/2)</li>'
							},
							{
								xtype: 'textfield',
								id: 'MAG_groupUserStoreLoad',
								hidden: true
							}
						]
					}
				]
			}
		]
	}
);

/*
 * 그룹 생성폼: 스텝2
 */
var MAG_groupInfoForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MAG_groupInfoForm',
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
						text: lang_mag_group[4]
					},
					{
						xtype: 'label',
						text: lang_mag_group[5]
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
						html: lang_mag_group[6]
					},
					{
						xtype: 'BaseWizardContentPanel',
						defaultType: 'textfield',
						items: [
							{
								fieldLabel: lang_mag_group[68] + lang_mag_group[7],
								id: 'MAG_groupName',
								name: 'groupName',
								allowBlank: false,
								vtype: 'reg_ID',
								style: { marginBottom: '20px' }
							},
							{
								fieldLabel: '&nbsp' + lang_mag_group[8],
								id: 'MAG_groupDesc',
								name: 'groupDesc',
								vtype: 'reg_DESC',
								style: { marginBottom: '20px' }
							},
							{
								id: 'MAG_groupType',
								name: 'groupType',
								hidden : true
							}
						]
					}
				]
			}
		]
	}
);

/*
 * 그룹 생성폼: 스텝3
 */
// 그룹별 사용자 모델 (업데이트 내용 전달 모델)
Ext.define(
	'MAG_groupInfoUserTempModel',
	{
		extend: 'Ext.data.Model',
		fields: ['User_Name', 'User_Member']
	}
);

// 그룹별 사용자 스토어 (업데이트 내용 전달 스토어)
var MAG_groupInfoUserTempStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MAG_groupInfoUserTempModel',
		idProperty: 'User_Name'
	}
);

// 그룹별 사용자 정보 모델
Ext.define(
	'MAG_groupInfoUserModel',
	{
		extend: 'Ext.data.Model',
		pruneRemoved: false,
		fields: ['User_Name', 'User_Desc', 'User_Location', 'User_Member']
	}
);

// 각 그룹의 사용자 정보, 공유 정보 스토어
var MAG_groupInfoUserStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MAG_groupInfoUserModel',
		sorters: [
			{ property: 'User_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/account/user/list',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
				getResponseData: function (response) {
					try {
						var json = Ext.decode(response.responseText),
							filter = Ext.getCmp('MAG_groupUserFilterName').getValue(),
							mtype  = Ext.getCmp('MAG_groupUserMatchType').getValue();

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
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 수정 데이터 제거
				MAG_groupInfoUserTempStore.removeAll();

				console.debug('extraParams(before):', store.proxy.extraParams);

				Ext.getCmp('MAG_groupUserStoreLoad').setValue(false);

				['LocationType', 'FilterName', 'FilterArgs', 'MatchType']
					.forEach(
						function (e)
						{
							store.proxy.setExtraParam(
								e,
								Ext.getCmp('MAG_groupUser' + e).getValue()
							);
						}
					);

				// 선택된 그룹 정보 전달: 그룹명
				if (Ext.getCmp('MAG_groupType').getValue() == 'Modify')
				{
					store.proxy.setExtraParam(
						'TempName',
						Ext.getCmp('MAG_groupName').getValue()
					);
				}

				console.debug('extraParams(after):', store.proxy.extraParams);
			},
			load: function (store, records, success) {
				// 데이터 전송 완료 후 wait 제거
				if (waitMsgBox)
				{
					waitMsgBox.hide();
					waitMsgBox = null;
				}

				// 사용자에 대한 그룹 리스트가 없을 경우 load.callBack 호출하지 않음
				Ext.getCmp('MAG_groupUserStoreLoad').setValue(true);

				if (typeof(MAG_groupInfoUserGrid.el) != 'undefined')
					MAG_groupInfoUserGrid.unmask();

				// 예외 처리에 따른 동작
				if (success !== true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mag_group[0] + '",'
						+ '"content": "' + lang_mag_group[10] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				// 그룹 생성, 수정 WINDOW OPEN
				MAG_groupInfoWindow.show();

				// 그룹 정보 로드 시 그룹 수 출력
				if (typeof(MAG_groupInfoUserGrid.el) != 'undefined')
				{
					document.getElementById('MAG_groupInfoUserGridHeaderTotalCount').innerHTML
						= lang_mag_group[9]
						+ ': '
						+ store.proxy.reader.rawData.count;
				}
			},
			prefetch: function (store, records, success, operation, eOpts) {
				if (success !== true)
					return;

				console.debug('records:', records);

				var selected = [];

				records.forEach(
					function (item) {
						if (item.raw.User_Member == 'true')
						{
							selected.push(item);
						}
					}
				);

				console.debug('selected:', selected);

				Ext.defer(
					function ()
					{
						MAG_groupInfoUserGrid
							.getSelectionModel()
							.select(selected, true);
					},
					200
				);
			}
		}
	}
);

var MAG_groupInfoUserGridSelModel = Ext.create(
	'Ext.selection.CheckboxModel',
	{
		columns: [
			{
				xtype : 'checkcolumn',
				dataIndex : 'User_Member'
			}
		],
		pruneRemoved: false,
		checkOnly: 'true',
		listeners : {
			select: function (grid, record, index, eOpts) {
				Ext.defer(function () {
					record.set('User_Member', true);

					// 변경된 데이터만 저장
					if (String(record.raw.User_Member)
						!= String(record.data.User_Member))
					{
						MAG_groupInfoUserTempStore.add(record);
					}
				}, 50);
			},
			deselect: function (grid, record, index, eOpts) {
				Ext.defer(function () {
					record.set('User_Member', false);

					// 변경된 데이터만 저장
					if (String(record.raw.User_Member)
						!= String(record.data.User_Member))
					{
						MAG_groupInfoUserTempStore.add(record);
					}
				}, 50);
			}
		}
	}
);

// 각 그룹의 사용자 그리드
var MAG_groupInfoUserGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAG_groupInfoUserGrid',
		store: MAG_groupInfoUserStore,
		title: lang_mag_group[11],
		height: 310,
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'BasePanel',
					id: 'MAG_groupInfoUserGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 200,
					height: 16
				}
			]
		},
		selModel: MAG_groupInfoUserGridSelModel,
		columns: [
			{
				flex: 1,
				dataIndex: 'User_Name',
				text: lang_mag_group[12],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Desc',
				text: lang_mag_group[13],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Location',
				text: lang_mag_group[14],
				sortable: true,
				menuDisabled: true
			}
		],
		tbar: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAG_groupUserMatchType',
				hiddenName: 'groupUserMatchType',
				name: 'groupUserMatchType',
				store: new Ext.data.SimpleStore({
					fields: ['MatchType', 'MatchCode'],
					data: [
						[lang_mag_group[15], 'ALL'],
						[lang_mag_group[16], 'MATCHED'],
						[lang_mag_group[17], 'UNMATCHED']
					]
				}),
				value: 'ALL',
				displayField: 'MatchType',
				valueField: 'MatchCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						// 생성, 수정 시 사용자 목록 받아오기
						MAG_groupInfoUserStore.clearData();
						MAG_groupInfoUserStore.load();
					}
				}
			},
			{
				xtype: 'BaseComboBox',
				hidden: true,
				hideLabel: true,
				id: 'MAG_groupUserLocationType',
				hiddenName: 'groupUserLocationType',
				name: 'groupUserLocationType',
				store: new Ext.data.SimpleStore({
					fields: ['LocationType', 'LocationCode'],
					data: [
						[lang_mag_group[18], 'LOCAL'],
						['LDAP', 'LDAP'],
						['Active Directory', 'ADS']
					]
				}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						// 생성, 수정 시 사용자 목록 받아오기
						MAG_groupInfoUserStore.clearData();
						MAG_groupInfoUserStore.load();
					}
				}
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAG_groupUserFilterName',
				hiddenName: 'groupUserFilterName',
				name: 'groupUserFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mag_group[12], 'User_Name'],
						[lang_mag_group[13], 'User_Desc'],
						[lang_mag_group[71], 'MemberOf'],
					]
				}),
				value: 'User_Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mag_group[20],
			{
				xtype: 'searchfield',
				id: 'MAG_groupUserFilterArgs',
				store: MAG_groupInfoUserStore,
				paramName: 'FilterArgs',
				width: 135,
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

var MAG_groupInfoUser = Ext.create(
	'BaseFormPanel',
	{
		id: 'MAG_groupInfoUser',
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
						text: lang_mag_group[4]
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold;',
						text: lang_mag_group[5]
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
						html: lang_mag_group[22]
					},
					{
						xtype: 'BaseWizardContentPanel',
						layout: {
							align : 'stretch'
						},
						items: [MAG_groupInfoUserGrid]
					}
				]
			}
		]
	}
);

/*
 * 그룹 생성 윈도우
 */
var MAG_groupInfoWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MAG_groupInfoWindow',
		layout: 'card',
		title: lang_mag_group[21],
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
				id: 'MAG_groupInfoDescPanel',
				items: [MAG_groupInfoDesc]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MAG_groupInfoFormPanel',
				items: [MAG_groupInfoForm]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0',
				layout: 'fit',
				id: 'MAG_groupInfoUserPanel',
				items: [MAG_groupInfoUser]
			}
		],
		fbar: [
			{
				text: lang_mag_group[48],
				width: 70,
				disabled: false,
				border: true,
				handler: function () {
					MAG_groupInfoWindow.close();
				}
			},
			'->',
			{
				text: lang_mag_group[23],
				id: 'MAG_groupInfoWindowPreBtn',
				width: 70,
				disabled: true,
				handler: function () {
					var currentStepPanel = MAG_groupInfoWindow.layout.activeItem;
					var currentStepIndex = MAG_groupInfoWindow.items.indexOf(currentStepPanel);

					MAG_groupInfoWindow.layout.setActiveItem(--currentStepIndex);

					if (currentStepIndex == 0)
					{
						Ext.getCmp('MAG_groupInfoWindowPreBtn').hide();
					}
					else
					{
						// 다음 버튼
						Ext.getCmp('MAG_groupInfoWindowNextBtn').show();
						Ext.getCmp('MAG_groupInfoWindowNextBtn').enable();

						// 확인 버튼
						Ext.getCmp('MAG_groupInfoWindowSetBtn').hide();
						Ext.getCmp('MAG_groupInfoWindowSetBtn').disable();
					}
				}
			},
			{
				text: lang_mag_group[24],
				id: 'MAG_groupInfoWindowNextBtn',
				width: 70,
				handler: function () {
					var curr_panel = MAG_groupInfoWindow.layout.activeItem;
					var curr_idx   = MAG_groupInfoWindow.items.indexOf(curr_panel);

					MAG_groupInfoWindow.layout.setActiveItem(++curr_idx);

					// 버튼 컨트롤
					Ext.getCmp('MAG_groupInfoWindowPreBtn').show();
					Ext.getCmp('MAG_groupInfoWindowPreBtn').enable();

					if (MAG_groupInfoWindow.layout.getActiveItem().id
						== 'MAG_groupInfoUserPanel')
					{
						// 생성일 때 그룹 이름 중복 확인
						if (Ext.getCmp('MAG_groupType').getValue() == 'Create')
						{
							var dup_id = false;

							MAG_groupGridStore.proxy.reader.rawData.entity
								.forEach(
									function (record) {
										if (record.Group_Name
											== Ext.getCmp('MAG_groupName')
												.getValue())
										{
											dup_id = true;
										}
									}
								);

							if (dup_id == true)
							{
								MAG_groupInfoWindow.layout
									.setActiveItem('MAG_groupInfoFormPanel');

								Ext.MessageBox.alert(
									lang_mag_group[0],
									lang_mag_group[64]
								);

								return false;
							}
						}

						if (!MAG_groupInfoForm.getForm().isValid())
						{
							MAG_groupInfoWindow.layout
								.setActiveItem('MAG_groupInfoFormPanel');

							return false;
						}

						// store가 LOAD 되었는지 확인후 MASK SHOW
						if (Ext.getCmp('MAG_groupUserStoreLoad').getValue()
							!= 'true')
						{
							MAG_groupInfoUserGrid.mask('Loading...');
						}

						// 다음 버튼
						Ext.getCmp('MAG_groupInfoWindowNextBtn').hide();
						Ext.getCmp('MAG_groupInfoWindowNextBtn').disable();

						// 확인 버튼
						Ext.getCmp('MAG_groupInfoWindowSetBtn').show();
						Ext.getCmp('MAG_groupInfoWindowSetBtn').enable();
					}
					else
					{
						Ext.getCmp('MAG_groupInfoWindowSetBtn').hide();
						Ext.getCmp('MAG_groupInfoWindowSetBtn').disable();
					}
				}
			},
			{
				text: lang_mag_group[25],
				id: 'MAG_groupInfoWindowSetBtn',
				width: 70,
				disabled: true,
				handler: function () {
					if (!MAG_groupInfoForm.getForm().isValid())
						return false;

					// 변경된 사용자 데이터 정보
					var users = [];

					MAG_groupInfoUserTempStore.getUpdatedRecords()
						.forEach(
							function (record) {
								users.push(
									{
										User_Name: record.data.User_Name,
										User_Member: record.data.User_Member
													? 'true' : 'false',
									}
								);
							}
						);

					var url;
					var msg;
					var msg_success;
					var msg_failure;

					if (Ext.getCmp('MAG_groupType').getValue() == 'Create')
					{
						// 생성
						url         = '/api/cluster/account/group/create';
						msg         = lang_mag_group[26];
						msg_success = lang_mag_group[27];
						msg_failure = lang_mag_group[28];
					}
					else if (Ext.getCmp('MAG_groupType').getValue() == 'Modify')
					{
						// 수정
						url         = '/api/cluster/account/group/update';
						msg         = lang_mag_group[29];
						msg_success = lang_mag_group[30];
						msg_failure = lang_mag_group[31];
					}

					waitWindow(lang_mag_group[0], msg);

					GMS.Ajax.request({
						url: url,
						jsonData: {
							entity: {
								Group_Name: Ext.getCmp('MAG_groupName')
												.getValue(),
								Group_Desc: Ext.getCmp('MAG_groupDesc')
												.getValue(),
								Group_Members: users,
							}
						},
						callback: function (options, success, response, decoded) {
							MAG_groupInfoWindow.hide();

							// 예외 처리에 따른 동작
							if (!success || !decoded.success)
							{
								return;
							}

							// 데이터 로드 성공 메세지
							Ext.MessageBox.show({
								title: lang_mag_group[0],
								msg: msg_success,
								buttons: Ext.MessageBox.OK,
								fn: function () { MAG_groupLoad(); }
							});
						}
					});
				}
			}
		]
	}
);

/*
 * 그룹 일괄 등록
 */
/*
 * 그룹 일괄 등록 그리드
 */
// 그룹 정보 모델
Ext.define(
	'MAG_groupFileuploadGridModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Group_Name', 'Group_Desc', 'Group_Result', 'Group_Errors']
	}
);

// 그룹 정보 스토어
var MAG_groupFileuploadGridStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MAG_groupFileuploadGridModel',
		sorters: [
			{
				property: 'Group_Name',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'groupListData'
			}
		}
	}
);

/** 그룹 정보 그리드 **/
var MAG_groupFileuploadGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAG_groupFileuploadGrid',
		store: MAG_groupFileuploadGridStore,
		title: lang_mag_group[32],
		height: 330,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				selectall: function () {
					MAG_groupFileSelect('selectAll');
				},
				deselectall: function () {
					MAG_groupFileSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mag_group[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Group_Name'
			},
			{
				flex: 1,
				text: lang_mag_group[8],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Group_Desc'
			},
			{
				flex: 1,
				text: lang_mag_group[33],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Group_Result'
			}
		],
		tbar: [
			{
				text: lang_mag_group[34],
				id: 'MAG_groupFileuploadDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mag_group[0],
						lang_mag_group[35],
						function (btn, text) {
							if (btn != 'yes')
								return;

							var targets = [];

							MAG_groupFileuploadGrid
								.getSelectionModel()
								.getSelection()
								.forEach(
									function (item)
									{
										targets.push(item);
									}
								);

							MAG_groupFileuploadGridStore.remove(targets);
						}
					);
				}
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MAG_groupFileSelect(record) }, 200);
			},
			itemdblclick: function (dataview, record, item, index, e) {
				if (record.data.Group_Result.toUpperCase() != 'ERROR')
					return;

				var errorArrayStr = '';
				var errorStr = record.data.Group_Errors;

				for (var i=0; i<errorStr.length; i++)
				{
					errorArrayStr = errorArrayStr
									+ eval(errorStr[i]).replace("@", lang_mag_group[0])
									+ "<br>";
				}

				Ext.MessageBox.alert(lang_mag_group[0], errorArrayStr);
			}
		},
		viewConfig: {
			forceFit: true,
			getRowClass: function (record, rowIndex, p, store) {
				var statusRowValue = record.data.Group_Result.toUpperCase();

				if (statusRowValue == 'ERROR')
				{
					return 'm-custom-user-bundle';
				}
			}
		}
	}
);

// 일괄 등록 그리드 선택 시 버튼 컨트롤
function MAG_groupFileSelect(record)
{
	var selectCount = MAG_groupFileuploadGrid.getSelectionModel().getCount();

	if (selectCount > 1)
	{
		Ext.getCmp('MAG_groupFileuploadDelBtn').setDisabled(false);
	}
	else if (selectCount == 1)
	{
		Ext.getCmp('MAG_groupFileuploadDelBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MAG_groupFileuploadDelBtn').setDisabled(true);
	}
};

// 그룹 일괄 등록 폼
var MAG_groupFileuploadForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MAG_groupFileuploadForm',
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
				id: 'MAG_groupInfoFile',
				name: 'groupInfoFile',
				anchor: '40%',
				emptyText: lang_mag_group[36],
				fieldLabel: lang_mag_group[37],
				buttonOnly: true,
				buttonText: lang_mag_group[38],
				buttonConfig: {
					iconCls: 'b-icon-upload'
				},
				allowBlank: false,
				vtype: 'reg_userFile',
				listeners: {
					change : function (filefield, value, eOpts) {
						if (!Ext.getCmp('MAG_groupFileuploadForm').getForm().isValid())
							return false;

						waitWindow(lang_mag_group[0], lang_mag_group[39]);

						/*
						* TODO: Need an implementation to upload a group info file
						*/
						Ext.getCmp('MAG_groupFileuploadForm').getForm().submit({
							url: '/api/cluster/account/group/batch_validate',
							method: 'POST',
							success: function (form, action) {
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								// 메세지 출력
								var responseMsg = action.result.msg;
								var returnMsg   = responseMsg || lang_mag_group[40];

								Ext.MessageBox.alert(lang_mag_group[0], returnMsg);
								MAG_groupFileuploadGridStore.loadRawData(action.result.groupListData);
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
									+ '"title": "' + lang_mag_group[0] + '",'
									+ '"content": "' + lang_mag_group[41] + '",'
									+ '"response": ' + jsonText
								+ '}';

								exceptionDataCheck(checkValue);
							}
						});
					}
				}
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0px;',
				style: { marginTop: '20px' },
				html: lang_mag_group[42]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0px;',
				html: lang_mag_group[43]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0px;',
				html: lang_mag_group[44]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding-top: 20px;',
				items: [MAG_groupFileuploadGrid]
			}
		],
		buttons: [
			{
				text: lang_mag_group[21],
				handler: function () {
					var groupFileAddData = [];

					MAG_groupFileuploadGridStore.data.items
						.forEach(
							function (item) {
								if (item.data.Group_Result.toUpperCase() == 'ERROR')
									return;

								groupFileAddData.push(
									{
										Group_Name: item.data.Group_Name,
										Group_Desc: item.data.Group_Desc
									}
								);
							}
						);

					waitWindow(lang_mag_group[0], lang_mag_group[45]);

					GMS.Ajax.request({
						url: '/api/cluster/account/group/batch_create',
						jsonData: {
							entity: groupFileAddData,
						},
						callback: function (options, success, response, decoded) {
							// 예외 처리에 따른 동작
							if (!success || !decoded.success)
							{
								return;
							}

							MAG_groupFileuploadWindow.hide();

							Ext.MessageBox.show({
								title: lang_mag_group[0],
								msg: lang_mag_group[46],
								buttons: Ext.MessageBox.OK,
								fn : function () { MAG_groupLoad(); }
							});
						}
					});
				}
			},
			{
				text: lang_mag_group[48],
				scope: this,
				handler: function () {
					MAG_groupFileuploadWindow.hide();
				}
			}
		]
	}
);

// 그룹 일괄 등록 WINDOW
var MAG_groupFileuploadWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MAG_groupFileuploadWindow',
		animateTarget: Ext.getCmp('MAG_groupLumpAddBtn'),
		title: lang_mag_group[49],
		maximizable: false,
		autoHeight: true,
		border: false,
		items: [MAG_groupFileuploadForm]
	}
);


// 그룹별 사용자 정보 모델
Ext.define(
	'MAG_groupSelectUserModel',
	{
		extend: 'Ext.data.Model',
		//pruneRemoved: false,
		fields: ['User_Name', 'User_Desc', 'User_Location', 'User_Member']
	}
);

// 각 그룹의 사용자 정보 스토어
var MAG_groupSelectUserStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MAG_groupSelectUserModel',
		sorters: [
			{ property: 'User_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/account/user/list',
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
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();

				var group = MAG_groupGrid
							.getSelectionModel()
							.getSelection()[0]
							.get('Group_Name');

				var loc = Ext.getCmp('MAG_groupLocationType').getValue();

				// 선택된 그룹 정보 전달: 그룹명
				store.proxy.setExtraParam('LocationType', loc);
				store.proxy.setExtraParam('MatchType', 'MATCHED');
				store.proxy.setExtraParam('FilterName', 'MemberOf');
				store.proxy.setExtraParam('FilterArgs', group);
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
					+ '"title": "' + lang_mag_group[0] + '",'
					+ '"content": "' + lang_mag_group[10] + '",'
					+ '"response": ' + jsonText
				+ '}';

				exceptionDataCheck(checkValue);
			}
		}
	}
);

// 각 그룹의 사용자 그리드
var MAG_groupSelectUserGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAG_groupSelectUserGrid',
		store: MAG_groupSelectUserStore,
		title: lang_mag_group[11],
		height: 275,
		columns: [
			{
				flex: 1,
				dataIndex: 'User_Name',
				text: lang_mag_group[12],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Desc',
				text: lang_mag_group[13],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Location',
				text: lang_mag_group[14],
				sortable: true,
				menuDisabled: true
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

// 사용자 정보
var MAG_groupSelectWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MAG_groupSelectWindow',
		title: lang_mag_group[11],
		maximizable: false,
		autoHeight: true,
		width: 640,
		height: 430,
		items: [
			{
				xtype: 'BasePanel',
				id: 'MAG_groupSelectUserPanel',
				bodyStyle: 'padding: 25px 30px 30px 30px;',
				items: [
					{
						border: false,
						style: {marginBottom: '20px'},
						html: lang_mag_group[66]
					},
					{
						border: false,
						items: [MAG_groupSelectUserGrid]
					}
				]
			}
		],
		buttons: [
			{
				text: lang_mag_group[67],
				handler: function () {
					MAG_groupSelectWindow.hide();
				}
			}
		]
	}
);

/*
 * 그룹 정보 그리드
 */
// 그룹 정보 모델
Ext.define(
	'MAG_groupGridModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Group_Name', 'Group_Desc', 'Group_Location']
	}
);

// 그룹 정보 스토어
var MAG_groupGridStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MAG_groupGridModel',
		sorters: [
			{ property: 'Group_Name', direction: 'ASC' }
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
							filter = Ext.getCmp('MAG_groupFilterName').getValue();

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
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.proxy.setExtraParam(
					'LocationType',
					Ext.getCmp('MAG_groupLocationType').getValue());

				store.proxy.setExtraParam(
					'FilterName',
					Ext.getCmp('MAG_groupFilterName').getValue());
			},
			load: function (store, records, success) {
				// 그룹 정보 mask 제거
				MAG_groupGrid.unmask();

				// 예외 처리에 따른 동작
				if (success !== true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mag_group[0] + '",'
						+ '"content": "' + lang_mag_group[10] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				// 그룹 정보 로드 시 그룹 수 출력
				document.getElementById('MAG_groupGridHeaderTotalCount').innerHTML
					= lang_mag_group[50]
					+ ': '
					+ store.proxy.reader.rawData.count;

				// 데이터 로드 성공 메세지
				//Ext.ux.DialogMsg.msg(lang_mag_group[0], lang_mag_group[51]);
			}
		}
	}
);

/** 그룹 정보 그리드 **/
var MAG_groupGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MAG_groupGrid',
		store: MAG_groupGridStore,
		title: lang_mag_group[52],
		header: {
			titlePosition: 0,
			items: [
				{
					xtype:'panel',
					id: 'MAG_groupGridHeaderTotalCount',
					style: 'text-align: right; padding-right:20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 200,
					height: 16
				}
			]
		},
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			renderer: function (val, meta, record, rowIndex, colIndex, store, view) {
				var status = record.data['Group_Location'].toLowerCase();

				if (status == 'local')
				{
					meta.tdCls = Ext.baseCSSPrefix + 'grid-cell-special';

					return '<div class="'
						+ Ext.baseCSSPrefix
						+ 'grid-row-checker">&#160;</div>';
				}
				else
				{
					return null;
				}
			},
			listeners: {
				selectall: function() {
					MAG_groupSelect('selectAll');
				},
				deselectall: function() {
					MAG_groupSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mag_group[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Group_Name'
			},
			{
				flex: 1,
				text: lang_mag_group[8],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Group_Desc'
			},
			{
				flex: 1,
				text: lang_mag_group[11],
				sortable: false,
				menuDisabled: true,
				xtype: 'componentcolumn',
				autoWidthComponents: false,
				renderer: function(value, metaData, record) {
					return {
						xtype: 'button',
						width: 120,
						text: lang_mag_group[11],
						handler: function() {
							// 선택된 버튼의 row 활성화
							MAG_groupGrid.getSelectionModel().deselectAll();
							MAG_groupGrid.getSelectionModel().select(record, true);

							waitWindow(lang_mag_group[52], lang_mag_group[65]);

							MAG_groupSelectWindow.show();

							Ext.defer(function() {
								MAG_groupSelectUserStore.load();
							}, 200);
						}
					};
				}
			}
		],
		tbar: [
			{
				text: lang_mag_group[53],
				id: 'MAG_groupCreateBtn',
				iconCls: 'b-icon-add',
				handler: function() {
					waitWindow(lang_mag_group[0], lang_mag_group[69]);

					// 페이지 로드 시 그룹 정보 초기화
					MAG_groupInfoForm.getForm().reset();

					// buffered STORE 데이터 리셋
					MAG_groupInfoUserStore.clearData();

					// 전달할 사용자 리스트 스토어 초기화
					MAG_groupInfoUserTempStore.removeAll();

					// 생성을 위한 메세지
					MAG_groupInfoWindow.setTitle(lang_mag_group[21]);

					// 첫번째 페이지 로드
					MAG_groupInfoWindow.layout
						.setActiveItem('MAG_groupInfoDescPanel');

					Ext.getCmp('MAG_groupAddDescContent1')
						.update(lang_mag_group[54]);

					// WINDOW OPEN 시 동작
					MAG_groupInfoWindow.animateTarget
						= Ext.getCmp('MAG_groupCreateBtn');

					Ext.getCmp('MAG_groupType').setValue('Create');

					// 사용자 아이디 수정가능
					Ext.getCmp('MAG_groupName').setDisabled(false);

					Ext.getCmp('MAG_groupInfoWindowNextBtn').show();
					Ext.getCmp('MAG_groupInfoWindowNextBtn').enable();
					Ext.getCmp('MAG_groupInfoWindowPreBtn').hide();
					Ext.getCmp('MAG_groupInfoWindowSetBtn').hide();

					// 그룹생성 스텝3 selectBox,inputBox 초기셋팅
					Ext.getCmp('MAG_groupUserLocationType').setValue('LOCAL');
					Ext.getCmp('MAG_groupUserFilterName').setValue('MemberOf');
					Ext.getCmp('MAG_groupUserFilterArgs').setValue();
					Ext.getCmp('MAG_groupUserMatchType').setValue('ALL');

					// 그룹 정보 로드
					MAG_groupDescLoad();
				}
			},
			{
				text: lang_mag_group[55],
				id: 'MAG_groupModifyBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function() {
					waitWindow(lang_mag_group[0], lang_mag_group[70]);

					// 페이지 로드 시 사용자 정보 초기화
					MAG_groupInfoForm.getForm().reset();

					// buffered STORE 데이터 리셋
					//MAG_groupInfoUserStore.clearData();

					// 전달할 사용자 리스트 스토어 초기화
					MAG_groupInfoUserTempStore.removeAll();

					// 선택된 그룹 정보 전달: 그룹명
					var selection
						= MAG_groupGrid.getSelectionModel().getSelection();

					var groupname = selection[0].get('Group_Name');

					// 수정을 위한 메세지
					MAG_groupInfoWindow.setTitle(lang_mag_group[56]);

					Ext.getCmp('MAG_groupAddDescContent1')
						.update('[' + groupname + '] ' + lang_mag_group[57]);

					// 첫번째 페이지 로드
					MAG_groupInfoWindow.layout
						.setActiveItem('MAG_groupInfoDescPanel');

					// WINDOW OPEN시 동작
					MAG_groupInfoWindow.animateTarget
						= Ext.getCmp('MAG_groupModifyBtn');

					Ext.getCmp('MAG_groupType').setValue('Modify');

					// 그룹명 수정못함
					Ext.getCmp('MAG_groupName').setDisabled(true);

					Ext.getCmp('MAG_groupInfoWindowNextBtn').show();
					Ext.getCmp('MAG_groupInfoWindowNextBtn').enable();
					Ext.getCmp('MAG_groupInfoWindowPreBtn').hide();
					Ext.getCmp('MAG_groupInfoWindowSetBtn').hide();

					Ext.getCmp('MAG_groupUserLocationType').setValue('LOCAL');
					Ext.getCmp('MAG_groupUserFilterName').setValue('MemberOf');
					Ext.getCmp('MAG_groupUserFilterArgs').setValue(groupname);
					Ext.getCmp('MAG_groupUserMatchType').setValue('ALL');

					// 사용자 정보 로드
					MAG_groupDescLoad(groupname);
				}
			},
			{
				text: lang_mag_group[34],
				id: 'MAG_groupDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mag_group[0],
						lang_mag_group[58],
						function (btn, text) {
							if (btn != 'yes')
								return;

							// 선택된 그리드의 전송값 추출
							var selection = MAG_groupGrid.getSelectionModel().getSelection();
							var targets = [];

							selection.forEach(
								function (item)
								{
									targets.push(item.data.Group_Name);
								}
							);

							waitWindow(lang_mag_group[0], lang_mag_group[59]);

							GMS.Ajax.request({
								url: '/api/cluster/account/group/delete',
								jsonData: {
									entity: {
										Group_Names: targets
									}
								},
								callback: function (options, success, response, decoded) {
									// 예외 처리에 따른 동작
									if (!success || !decoded.success)
									{
										return;
									}

									Ext.MessageBox.show({
										title: lang_mag_group[0],
										msg: lang_mag_group[60],
										buttons: Ext.MessageBox.OK,
										fn : function () { MAG_groupLoad(); }
									});
								}
							});
						}
					);
				}
			},
			/*
			{
				text: lang_mag_group[62],
				id: 'MAG_groupLumpAddBtn',
				tooltip: lang_mag_group[62],
				iconCls: 'b-icon-user-regi',
				handler: function() {
					MAG_groupFileuploadGridStore.removeAll();
					MAG_groupFileuploadWindow.show();
				}
			},
			*/
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAG_groupLocationType',
				hiddenName: 'groupLocationType',
				name: 'groupLocationType',
				store: new Ext.data.SimpleStore({
					fields: ['LocationType', 'LocationCode'],
					data: [
						[lang_mag_group[63], 'LOCAL'],
						['LDAP', 'LDAP'],
						['Active Directory', 'ADS']
					]
				}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue){
						MAG_groupLoad();
					}
				}
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MAG_groupFilterName',
				hiddenName: 'groupFilterName',
				name: 'groupFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mag_group[7], 'Group_Name'],
						[lang_mag_group[8], 'Group_Desc'],
						[lang_mag_group[71], 'MemberOf'],
					]
				}),
				value: 'Group_Name',
				displayField: 'FilterName',
				valueField: 'FilterCode',
				/*
				listeners: {
					change: function (combo, newValue, oldValue) {
						Ext.getCmp('MAG_groupFilterArgs').store.proxy.extraParams
							= {
								LocationType: Ext.getCmp('MAG_groupLocationType').getValue(),
								FilterName: newValue,
							};
					},
					afterrender: function (combo) {
						Ext.getCmp('MAG_groupFilterArgs').store.proxy.extraParams
							= {
								LocationType: Ext.getCmp('MAG_groupLocationType').getValue(),
								FilterName: combo.getValue(),
							};
					}
				}
				*/
			},
			'-',
			lang_mag_group[20],
			{
				xtype: 'searchfield',
				id: 'MAG_groupFilterArgs',
				store: MAG_groupGridStore,
				paramName: 'FilterArgs',
				width: 180
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MAG_groupSelect(record) }, 200);
			},
			/*
			select: function (model, record, index) {
				if (record.data.Group_Location.toLowerCase() != 'local')
				{
					//인증 local 이 아닌경우 선택 할수 없음
					MAG_groupGrid.getSelectionModel().deselect(index);
				}
			}
			*/
		},
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

// 사용자 목록 선택 시
function MAG_groupSelect(record)
{
	var count = MAG_groupGrid.getSelectionModel().getCount();

	if (count > 1)
	{
		Ext.getCmp('MAG_groupModifyBtn').setDisabled(true);
		Ext.getCmp('MAG_groupDelBtn').setDisabled(false);
	}
	else if (count == 1)
	{
		Ext.getCmp('MAG_groupModifyBtn').setDisabled(false);
		Ext.getCmp('MAG_groupDelBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MAG_groupModifyBtn').setDisabled(true);
		Ext.getCmp('MAG_groupDelBtn').setDisabled(true);
	}
};

// 그룹 설정
Ext.define(
	'/admin/js/manager_account_group',
	{
		extend: 'BasePanel',
		id: 'manager_account_group',
		load: function () {
			MAG_groupLoad();
		},
		bodyStyle: 'padding: 0;',
		items: [
			{
				xtype: 'BasePanel',
				layout: 'fit',
				bodyStyle: 'padding: 20px;',
				items: [MAG_groupGrid],
			}
		]
	}
);
