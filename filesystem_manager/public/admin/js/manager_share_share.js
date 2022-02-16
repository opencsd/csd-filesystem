/*
 * 페이지 로드 시 실행 함수
 */
// 공유 설정 정보 로드
function MSS_shareLoad()
{
	// 초기 버튼 컨트롤
	Ext.getCmp('MSS_shareModifyBtn').setDisabled(true);
	Ext.getCmp('MSS_shareDelBtn').setDisabled(true);

	// load volume store
	var promise = volumeStoreLoad();

	promise.success(
		function (result) {
			MSS_shareStore.load();
		}
	);
};

// SMB 데이터 로드
function MSS_shareSMBLoad()
{
	// 초기 버튼 컨트롤
	Ext.getCmp('MSS_shareSMBModifyBtn').setDisabled(true);

	// SMB 데이터 호출
	MSS_shareSMBStore.load();
};

// NFS 데이터 로드
function MSS_shareNFSLoad()
{
	// 초기 버튼 컨트롤
	Ext.getCmp('MSS_shareNFSModifyBtn').setDisabled(true);

	var promises = [];

	['ganesha', 'kernel'].forEach(
		function (item, index, array) {
			promises.push(
				GMS.Ajax.request({
					url: '/api/cluster/share/nfs/' + item + '/list',
					method: 'POST',
					callback: function (options, success, response, decoded) {
						if (!success || !decoded.success)
						{
							options.deferred.promise().reject(response);
							return;
						}

						// NFS Type 구분 값 삽입 (kernel, ganesha);
						decoded.entity.forEach(function (e) {
							e.Type = item;
						});

						options.deferred.promise().resolve(decoded);
					}
				})
			);
		}
	);

	Ext.ux.Deferred
		.when(...promises)
		.then(
			function (r) {
				var shares = [];

				for (var key in r)
				{
					if (!r[key].hasOwnProperty('entity')
						|| !Array.isArray(r[key].entity))
					{
						console.error('Unknown response:', r[key]);
						continue;
					}

					shares = shares.concat(r[key].entity);
				}

				MSS_shareNFSStore.loadRawData(shares);

				if (MSS_shareNFSGrid)
				{
					MSS_shareNFSGrid.unmask();
				}
			},
			function (e) {
				console.error('error:', e);
			},
		);
};

/*
 * 서비스 프로토콜 - SMB
 */
// 서비스 프로토콜 수정 - SMB: 설정폼
// SMB: 권한 모델
Ext.define(
	'MSS_shareSMBRightModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Name']
	}
);

// SMB: 접근 사용자 권한 스토어
var MSS_shareSMBUserRightStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareSMBRightModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			}
		}
	}
);

// SMB: 접근 그룹 권한 스토어
var MSS_shareSMBGroupRightStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareSMBRightModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			}
		}
	}
);

// SMB: 접근 네트워크 영역 스토어
var MSS_shareSMBZoneRightStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareSMBRightModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			}
		}
	}
);

var MSS_shareSMBInfoForm = Ext.create(
	'BaseFormPanel',
	{
		xtype: 'BaseFormPanel',
		id: 'MSS_shareSMBInfoForm',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				id: 'MSS_shareSMBInfoFormDesc',
				style: { marginBottom: '20px' },
				html: lang_mss_share[3]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MSS_shareSMBInfoFormNameLabel',
						text: lang_mss_share[4]+': ',
						width: 130,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSS_shareSMBInfoFormNameLabelValue',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MSS_shareSMBInfoFormDescLabel',
						text: lang_mss_share[95]+': ',
						width: 130,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSS_shareSMBInfoFormDescLabelValue',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MSS_shareSMBInfoFormPathLabel',
						text: lang_mss_share[5]+': ',
						width: 130,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSS_shareSMBInfoFormPathLabelValue',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'radiogroup',
				fieldLabel: lang_mss_share[6],
				id: 'MSS_shareSMBInfoFormRight',
				width: 450,
				style: { marginTop: '20px' },
				items: [
					{
						boxLabel: lang_mss_share[7],
						id: 'MSS_shareSMBInfoFormRightR',
						name: 'shareSMBInfoFormRightName',
						inputValue: 'readonly',
						checked: true
					},
					{
						boxLabel: lang_mss_share[8],
						id: 'MSS_shareSMBInfoFormRightRW',
						name: 'shareSMBInfoFormRightName',
						inputValue: 'read/write'
					}
				]
			},
			/*
			{
				fieldLabel: lang_mss_share[144],
				id: 'MSS_shareSMBInfoFormOwner',
				name: 'shareSMBInfoFormOwner',
				labelWidth: 125,
				style: { marginTop: '20px' }
			},
			*/
			{
				xtype: 'panel',
				border: false,
				layout: { type: 'hbox', pack: 'start' },
				bodyStyle: { padding: 0 },
				items: [
					{
						xtype: 'panel',
						border: false,
						width: 300,
						items: [
							/*
							{
								xtype: 'checkbox',
								boxLabel: lang_mss_share[9],
								id: 'MSS_shareSMBInfoFormAvailable',
								name: 'shareSMBInfoFormAvailable',
								style: { marginTop: '20px' }
							},
							*/
							{
								xtype: 'checkbox',
								boxLabel: lang_mss_share[10],
								id: 'MSS_shareSMBInfoFormGuest',
								name: 'shareSMBInfoFormGuest',
								style: { marginTop: '20px' },
								listeners: {
									change: function () {
										var enabled = this.getValue();

										Ext.getCmp('MSS_shareSMBUserPanel').setDisabled(enabled);
										Ext.getCmp('MSS_shareSMBGroupPanel').setDisabled(enabled);

										if (enabled)
											Ext.getCmp('MSS_shareSMBInfoFormGuestLabel').show();
										else
											Ext.getCmp('MSS_shareSMBInfoFormGuestLabel').hide();
									}
								}
							},
							{
								xtype: 'label',
								id: 'MSS_shareSMBInfoFormGuestLabel',
								hidden : true,
								text : lang_mss_share[147]
							},
							{
								xtype: 'checkbox',
								boxLabel: lang_mss_share[11],
								id: 'MSS_shareSMBInfoFormHide',
								name: 'shareSMBInfoFormHide',
								style: { marginTop: '20px' }
							},
							{
								xtype: 'checkbox',
								boxLabel: lang_mss_share[12],
								id: 'MSS_shareSMBInfoFormLog',
								name: 'shareSMBInfoFormLog',
								hidden: true,
								style: { marginTop: '20px' }
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareSMBInfoName',
								name: 'shareSMBInfoName',
								hidden : true
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareSMBInfoUserStoreLoad',
								name: 'shareSMBInfoUserStoreLoad',
								hidden: true
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareSMBInfoGroupStoreLoad',
								name: 'shareSMBInfoGroupStoreLoad',
								hidden: true
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareSMBInfoZoneStoreLoad',
								name: 'shareSMBInfoZoneStoreLoad',
								hidden: true
							}
						]
					},
				]
			}
		]
	}
);

/*
 * 서비스 프로토콜 수정 - SMB: 접근사용자
 */
// SMB: 접근 사용자 모델 (업데이트 내용 전달 모델)
Ext.define(
	'MSS_shareTempSMBUserModel',
	{
		extend: 'Ext.data.Model',
		fields: ['User_Name', 'AccessRight']
	}
);

// SMB: 접근 사용자 스토어 (업데이트 내용 전달 스토어)
var MSS_shareTempSMBUserStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareTempSMBUserModel'
	}
);

// SMB: 접근 사용자 모델
Ext.define(
	'MSS_shareSMBUserModel',
	{
		extend: 'Ext.data.Model',
		pruneRemoved: false,
		fields: ['User_Name', 'User_Desc', 'User_Location', 'AccessRight']
	}
);

// SMB: 접근 사용자 스토어
var MSS_shareSMBUserStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MSS_shareSMBUserModel',
		sorters: [
			{ property: 'User_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/smb/users',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				MSS_shareSMBUserStore.clearData();
				MSS_shareTempSMBUserStore.removeAll();
				Ext.getCmp('MSS_shareSMBInfoUserStoreLoad').setValue(false);

				store.proxy.setExtraParam(
					'Name',
					MSS_shareGrid.getSelectionModel().getSelection()[0].get('Name'));

				store.proxy.setExtraParam(
					'LocationType',
					Ext.getCmp('MSS_shareSMBUserLocationType').getValue());

				store.proxy.setExtraParam(
					'FilterName',
					Ext.getCmp('MSS_shareSMBUserFilterName').getValue());
			},
			load: function (store, records, success) {
				Ext.getCmp('MSS_shareSMBInfoUserStoreLoad').setValue(true);

				if (typeof(MSS_shareSMBUserGrid.el) != 'undefined')
					MSS_shareSMBUserGrid.unmask();

				// 예외 처리에 따른 동작
				if (success !== true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mss_share[0] + '",'
						+ '"content": "' + lang_mss_share[32] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				if (!MSS_shareSMBUserGrid.el)
					return;

				document.getElementById('MSS_shareSMBUserGridHeaderTotalCount').innerHTML
					= '&nbsp;&nbsp;&nbsp;'
						+ lang_mss_share[13]
						+ ': '
						+ MSS_shareSMBUserStore.totalCount;
			}
		}
	}
);

// SMB: 접근 사용자 그리드
var MSS_shareSMBUserGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareSMBUserGrid',
		store: MSS_shareSMBUserStore,
		title: lang_mss_share[14],
		height: 300,
		selModel: {
			pruneRemoved: false
		},
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'panel',
					id: 'MSS_shareSMBUserGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 300,
					height: 16,
					html: ''
				}
			]
		},
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1
			})
		],
		columns: [
			Ext.create('Ext.grid.RowNumberer', { width: 35, resizable: true }),
			{
				flex: 1,
				dataIndex: 'User_Name',
				text: lang_mss_share[15],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Desc',
				text: lang_mss_share[16],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Location',
				text: lang_mss_share[17],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'AccessRight',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					style: { marginTop: '6px', marginBottom: '11px' },
					editable: false,
					dirty: true,
					store: MSS_shareSMBUserRightStore,
					valueField: 'Name',
					displayField: 'Name',
					width: 50,
					listeners: {
						change: function (field, newValue, oldValue, e) {
							Ext.defer(function () {
								var record = MSS_shareSMBUserGrid.selModel.selected.items[0];
								record.set('AccessRight', newValue);

								// 변경 데이터 css 변경
								field.fireEvent('dirtychange', newValue, [record]);
							}, 50);
						},
						dirtychange: function (combo, isDirty, eOpts) {
							if (isDirty[0].data.AccessRight == isDirty[0].raw.AccessRight)
							{
								Ext.getCmp('MSS_shareSMBUserGrid').getView().removeRowCls(isDirty[0].index);
							}
							else
							{
								var record = MSS_shareSMBUserGrid.selModel.selected.items[0];

								MSS_shareTempSMBUserStore.add(record);

								Ext.getCmp('MSS_shareSMBUserGrid').getView()
									.removeRowCls(isDirty[0].index);

								Ext.getCmp('MSS_shareSMBUserGrid').getView()
									.addRowCls(isDirty[0].index, 'm-custom-grid-change');
							}
						}
					}
				}
			}
		],
		tbar: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareSMBUserLocationType',
				hiddenName: 'shareSMBUserLocationType',
				name: 'shareSMBUserLocationType',
				store: new Ext.data.SimpleStore({
					fields: ['LocationType', 'LocationCode'],
					data: [
						[lang_mss_share[19], 'LOCAL'],
						['LDAP', 'LDAP'],
						['Active Directory', 'ADS']
					]
				}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MSS_shareSMBUserStore.load();
					}
				}
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareSMBUserFilterName',
				hiddenName: 'shareSMBUserFilterName',
				name: 'shareSMBUserFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mss_share[20], 'User_Name'],
						[lang_mss_share[16], 'User_Desc']
					]
				}),
				value: 'User_Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mss_share[22],
			{
				xtype: 'searchfield',
				id: 'MSS_shareSMBUserFilterArgs',
				store: MSS_shareSMBUserStore,
				paramName: 'searchStr',
				width: 180
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

/*
 * 서비스 프로토콜 수정 - SMB: 접근그룹
 */
// SMB: 접근 그룹 모델 (업데이트 내용 전달 모델)
Ext.define(
	'MSS_shareTempSMBGroupModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Group_Name', 'AccessRight']
	}
);

// SMB: 접근 그룹 스토어 (업데이트 내용 전달 스토어)
var MSS_shareTempSMBGroupStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareTempSMBGroupModel'
	}
);

// SMB: 접근 그룹 모델
Ext.define(
	'MSS_shareSMBGroupModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Group_Name', 'Group_Desc', 'Group_Location', 'AccessRight']
	}
);

// SMB: 접근 그룹 스토어
var MSS_shareSMBGroupStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MSS_shareSMBGroupModel',
		sorters: [
			{ property: 'Group_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/smb/groups',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				MSS_shareSMBGroupStore.clearData();
				MSS_shareTempSMBGroupStore.removeAll();

				Ext.getCmp('MSS_shareSMBInfoGroupStoreLoad').setValue(false);

				store.proxy.setExtraParam(
					'Name',
					MSS_shareGrid.getSelectionModel().getSelection()[0].get('Name'));

				store.proxy.setExtraParam(
					'LocationType',
					Ext.getCmp('MSS_shareSMBGroupLocationType').getValue());

				store.proxy.setExtraParam(
					'FilterName',
					Ext.getCmp('MSS_shareSMBGroupFilterName').getValue());
			},
			load: function (store, records, success) {
				Ext.getCmp('MSS_shareSMBInfoGroupStoreLoad').setValue(true);

				if (typeof(MSS_shareSMBGroupGrid.el) != 'undefined')
					MSS_shareSMBGroupGrid.unmask();

				// 예외 처리에 따른 동작
				if (success !== true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mss_share[0] + '",'
						+ '"content": "' + lang_mss_share[33] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				if (!MSS_shareSMBGroupGrid.el)
					return;

				document.getElementById('MSS_shareSMBGroupGridHeaderTotalCount').innerHTML
					= '&nbsp;&nbsp;&nbsp;'
						+ lang_mss_share[23]
						+ ': '
						+ MSS_shareSMBGroupStore.totalCount;
			}
		}
	}
);

// SMB: 접근 그룹 그리드
var MSS_shareSMBGroupGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareSMBGroupGrid',
		store: MSS_shareSMBGroupStore,
		title: lang_mss_share[24],
		height: 300,
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'panel',
					id: 'MSS_shareSMBGroupGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 300,
					height: 16,
					html: ''
				}
			]
		},
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1
			})
		],
		columns: [
			Ext.create('Ext.grid.RowNumberer', { width: 35, resizable: true }),
			{
				flex: 1,
				dataIndex: 'Group_Name',
				text: lang_mss_share[25],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Desc',
				text: lang_mss_share[26],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Location',
				text: lang_mss_share[17],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'AccessRight',
				text: lang_mss_share[18],
				sortable: true,
				menuDisabled: true,
				// 변경셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					style: { marginTop: '6px',marginBottom: '11px' },
					editable: false,
					store: MSS_shareSMBGroupRightStore,
					valueField: 'Name',
					displayField: 'Name',
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareSMBGroupGrid.selModel.selected.items[0];
								record.set('AccessRight', newValue);

								// 변경 데이터 css 변경
								field.fireEvent('dirtychange', newValue, [record]);
							}, 50);
						},
						dirtychange: function (combo, isDirty, eOpts) {
							if (isDirty[0].data.AccessRight == isDirty[0].raw.AccessRight)
							{
								Ext.getCmp('MSS_shareSMBGroupGrid').getView().removeRowCls(isDirty[0].index);
							}
							else
							{
								var record = MSS_shareSMBGroupGrid.selModel.selected.items[0];

								MSS_shareTempSMBGroupStore.add(record);

								Ext.getCmp('MSS_shareSMBGroupGrid').getView()
									.removeRowCls(isDirty[0].index);
								Ext.getCmp('MSS_shareSMBGroupGrid').getView()
									.addRowCls(isDirty[0].index, 'm-custom-grid-change');
							}
						}
					}
				}
			}
		],
		tbar: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareSMBGroupLocationType',
				hiddenName: 'shareSMBGroupLocationType',
				name: 'shareSMBGroupLocationType',
				store: new Ext.data.SimpleStore({
					fields: ['LocationType', 'LocationCode'],
					data: [
						[lang_mss_share[27], 'LOCAL'],
						['LDAP', 'LDAP'],
						['Active Directory', 'ADS']
					]
				}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MSS_shareSMBGroupStore.load();
					}
				}
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareSMBGroupFilterName',
				hiddenName: 'shareSMBGroupFilterName',
				name: 'shareSMBGroupFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mss_share[25], 'Group_Name'],
						[lang_mss_share[26], 'Group_Desc']
					]
				}),
				value: 'Group_Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mss_share[22],
			{
				xtype: 'searchfield',
				id: 'MSS_shareSMBGroupFilterArgs',
				store: MSS_shareSMBGroupStore,
				paramName: 'searchStr',
				width: 180
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

/*
 * 서비스 프로토콜 수정 - SMB: 접근 제어 네트워크 목록
 */
// SMB: 접근 제어 네트워크 모델 (업데이트 내용 전달 모델)
Ext.define(
	'MSS_shareTempSMBZoneModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Name', 'AccessRight']
	}
);

// SMB: 접근 제어 네트워크 스토어 (업데이트 내용 전달 스토어)
var MSS_shareTempSMBZoneStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareTempSMBZoneModel'
	}
);

// SMB: 접근 제어 네트워크 모델
Ext.define(
	'MSS_shareSMBZoneModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			// default attrs
			'Name', 'Desc', 'Type',
			// network address specifiers
			'Addrs', 'Range', 'CIDR', 'Domain',
			// right
			'AccessRight',
			// tricky field for grid
			'Value'
		]
	}
);

// SMB: 접근 제어 네트워크 스토어
var MSS_shareSMBZoneStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareSMBZoneModel',
		remoteFilter: true,
		remoteSort: true,
		pageSize: 25,
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/smb/zones',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
				getResponseData: function (response) {
					try {
						var json = Ext.decode(response.responseText);

						json.entity.forEach(
							function (item, idx, array)
							{
								switch (item.Type)
								{
									case 'addrs':
										item.Value = item.Addrs.join(', ');
										break;
									case 'range':
										item.Value = item.Range;
										break;
									case 'cidr':
										item.Value = item.CIDR;
										break;
									case 'domain':
										item.Value = item.Domain;
										break;
									default:
										item.Value = null;
										break;
								}

								json.entity[idx] = item;
							}
						);

						return this.readRecords({
							entity: json.entity,
							count: json.count ? json.count : 0,
							success: json.success,
						});
					}
					catch (e) {
						var error = new Ext.data.ResultSet({
							total: 0,
							count: 0,
							records: [],
							success: false,
							message: e.message,
						});

						Ext.log('Unable to parse the response returned by the server as JSON format');
						return error;
					}
				}
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				MSS_shareTempSMBZoneStore.removeAll();
				store.removeAll();

				Ext.getCmp('MSS_shareSMBInfoZoneStoreLoad').setValue(false);

				var grid = Ext.getCmp('MSS_shareGrid');

				Ext.apply(
					store.getProxy().extraParams,
					{
						Name: grid.getSelectionModel().getSelection()[0].get('Name'),
					}
				);
			},
			load: function (store, records, success, eOpts) {
				var grid = Ext.getCmp('MSS_shareSMBZoneGrid');

				Ext.getCmp('MSS_shareSMBInfoZoneStoreLoad').setValue(true);

				if (typeof(grid.el) != 'undefined')
					grid.unmask();

				if (success != true)
				{
					// 예외 처리에 따른 동작
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mss_share[0] + '",'
						+ '"content": "' + lang_mss_share[28] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				if (!grid.el)
					return;

				document.getElementById('MSS_shareSMBZoneGridHeaderTotalCount').innerHTML
					= '&nbsp;&nbsp;&nbsp;'
						+ lang_mss_share[226]
						+ ': '
						+ MSS_shareSMBZoneStore.totalCount;
			}
		}
	}
);

// SMB: 보안 그리드
var MSS_shareSMBZoneGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareSMBZoneGrid',
		store: MSS_shareSMBZoneStore,
		title: lang_mss_share[29],
		height: 300,
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'panel',
					id: 'MSS_shareSMBZoneGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 300,
					height: 16,
					html: ''
				}
			]
		},
		plugins: [
			Ext.create(
				'Ext.grid.plugin.CellEditing',
				{
					clicksToEdit: 1
				}
			),
		],
		columns: [
			Ext.create('Ext.grid.RowNumberer', { width: 35, resizable: true }),
			{
				flex: 1,
				dataIndex: 'Name',
				text: lang_mss_share[30],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 2,
				dataIndex: 'Value',
				text: lang_mss_share[31],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'AccessRight',
				text: lang_mss_share[18],
				sortable: true,
				menuDisabled: true,
				// 변경셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: {
						marginTop: '6px',
						marginBottom: '11px'
					},
					editable: false,
					store: MSS_shareSMBZoneRightStore,
					valueField: 'Name',
					displayField: 'Name',
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareSMBZoneGrid.selModel.selected.items[0];
								record.set('AccessRight', newValue);

								// 변경 데이터 css 변경
								field.fireEvent('dirtychange', newValue, [record]);
							}, 50);
						},
						dirtychange: function (combo, isDirty, eOpts) {
							if (isDirty[0].data.AccessRight == isDirty[0].raw.AccessRight)
							{
								Ext.getCmp('MSS_shareSMBZoneGrid').getView()
									.removeRowCls(isDirty[0].index);
							}
							else
							{
								var record = MSS_shareSMBZoneGrid.selModel.selected.items[0];

								MSS_shareTempSMBZoneStore.add(record);

								Ext.getCmp('MSS_shareSMBZoneGrid').getView()
									.removeRowCls(isDirty[0].index);

								Ext.getCmp('MSS_shareSMBZoneGrid').getView()
									.addRowCls(isDirty[0].index, 'm-custom-grid-change');
							}
						}
					}
				}
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

/*
 * 서비스 프로토콜 수정 - SMB 데이터 로드
 */
function MSS_shareSMBWinLoad(name)
{
	Ext.getCmp('MSS_shareSMBInfoUserStoreLoad').setValue(false);
	Ext.getCmp('MSS_shareSMBInfoGroupStoreLoad').setValue(false);

	// 스토어 필터 정보 초기화 - 탭일 경우 자동 초기화 안됨
	Ext.getCmp('MSS_shareSMBUserLocationType').setValue('LOCAL');
	Ext.getCmp('MSS_shareSMBUserFilterName').setValue('User_Name');
	Ext.getCmp('MSS_shareSMBUserFilterArgs').setValue();

	Ext.getCmp('MSS_shareSMBGroupLocationType').setValue('LOCAL');
	Ext.getCmp('MSS_shareSMBGroupFilterName').setValue('Group_Name');
	Ext.getCmp('MSS_shareSMBGroupFilterArgs').setValue();

	shareSMBRightsLoad();

	GMS.Ajax.request({
		waitMsgBox: waitWindow(lang_mss_share[0], lang_mss_share[142]),
		url: '/api/cluster/share/smb/info',
		method: 'POST',
		jsonData: {
			Name: name,
		},
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				MSS_shareSMBWin.hide();
				return;
			}

			MSS_shareInfoExternalCheck('SMB');

			// SMB 정보 로드

			// 공유명
			var name        = decoded.entity.Name;
			var desc        = decoded.entity.Comment;
			var path        = decoded.entity.Path;
			//var available   = decoded.entity.Available;
			var browseable  = decoded.entity.Browseable;
			var guest_ok    = decoded.entity.Guest_Ok;
			var read_only   = decoded.entity.Read_Only;

			// 공유 이름
			Ext.getCmp('MSS_shareSMBInfoName').setValue(name);
			Ext.getCmp('MSS_shareSMBInfoFormNameLabelValue').update(name);

			// 공유 설명
			Ext.getCmp('MSS_shareSMBInfoFormDescLabelValue').update(desc);

			// 공유 경로
			Ext.getCmp('MSS_shareSMBInfoFormPathLabelValue').update(path);

			// 공유 접근 권한
			if (read_only.toUpperCase() == 'YES')
				Ext.getCmp('MSS_shareSMBInfoFormRightR').setValue(true);
			else
				Ext.getCmp('MSS_shareSMBInfoFormRightRW').setValue(true);

			// 활성화
			//Ext.getCmp('MSS_shareSMBInfoFormAvailable')
			//	.setValue(available.toUpperCase() == 'YES');

			// Guest 허용
			if (guest_ok.toUpperCase() == 'YES')
			{
				Ext.getCmp('MSS_shareSMBInfoFormGuest').setValue(true);
				Ext.getCmp('MSS_shareSMBUserPanel').setDisabled(true);
				Ext.getCmp('MSS_shareSMBGroupPanel').setDisabled(true);
			}
			else
			{
				Ext.getCmp('MSS_shareSMBInfoFormGuest').setValue(false);
			}

			// 공유 숨김 사용
			Ext.getCmp('MSS_shareSMBInfoFormHide')
				.setValue(browseable.toUpperCase() == 'NO');

			// SMB 설정 WINDOW OPEN
			Ext.getCmp('MSS_shareSMBInfo').setActiveTab(0);

			MSS_shareSMBWin.show();

			/*
			 * 데이터 로드 후 원본 데이터로 인식
			 * 변경된 데이터만 인식하기 위한 내용
			 */
			if (MSS_shareSMBInfoForm.isDirty())
			{
				var fields = MSS_shareSMBInfoForm.getForm().getFields().items;

				for (var i=0; i<fields.length; i++)
				{
					fields[i].resetOriginalValue();
				}
			}
		}
	});
};

function shareSMBRightsLoad()
{
	GMS.Ajax.request({
		url: '/api/cluster/share/smb/rights',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				MSS_shareSMBWin.hide();
				return;
			}

			// SMB 사용자 권한 데이터 로드
			MSS_shareSMBUserRightStore.loadRawData(decoded.entity.User, false);
			shareSMBUserLoad();

			// SMB 그룹 권한 데이터 로드
			MSS_shareSMBGroupRightStore.loadRawData(decoded.entity.Group, false);
			shareSMBGroupLoad();

			// SMB 네트워크 영역 권한 데이터 로드
			MSS_shareSMBZoneRightStore.loadRawData(decoded.entity.Zone, false);
			shareSMBZoneLoad();
		}
	});
}

function shareSMBUserLoad()
{
	// SMB 사용자 정보 로드
	MSS_shareSMBUserStore.load();
}

function shareSMBGroupLoad()
{
	// SMB 그룹 정보 로드
	MSS_shareSMBGroupStore.load();
}

function shareSMBZoneLoad()
{
	// SMB 보안 정보 로드
	MSS_shareSMBZoneStore.load();
}

/*
 * 서비스 프로토콜 수정 - SMB
 */
var MSS_shareSMBWin = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareSMBWin',
		layout: 'fit',
		maximizable: false,
		width: 620,
		height: 500,
		title: lang_mss_share[35],
		items: [
			{
				xtype: 'tabpanel',
				id: 'MSS_shareSMBInfo',
				activeTab: 0,
				bodyBorder: false,
				border: false,
				height: 320,
				items:[
					{
						xtype: 'BasePanel',
						id: 'MSS_shareSMBInfoPanel',
						title: lang_mss_share[35],
						bodyStyle: { padding: 0 },
						items: [MSS_shareSMBInfoForm]
					},
					{
						xtype: 'BasePanel',
						id: 'MSS_shareSMBUserPanel',
						title: lang_mss_share[36],
						bodyStyle: {
							paddingTop: '25px',
							paddingRight: '30px',
							paddingBottom: '30px',
							paddingLeft: '30px;',
						},
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: lang_mss_share[37] + '<br>' + lang_mss_share[38]
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareSMBUserLoadDone',
								hidden : true,
								value: false
							},
							{
								border: false,
								items: [MSS_shareSMBUserGrid]
							}
						]
					},
					{
						xtype: 'BasePanel',
						id: 'MSS_shareSMBGroupPanel',
						title: lang_mss_share[39],
						bodyStyle: {
							paddingTop: '25px',
							paddingRight: '30px',
							paddingBottom: '30px',
							paddingLeft: '30px;',
						},
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: lang_mss_share[40] + '<br>' + lang_mss_share[41]
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareSMBGroupLoadDone',
								hidden : true,
								value: false
							},
							{
								border: false,
								items: [MSS_shareSMBGroupGrid]
							}
						]
					},
					{
						xtype: 'BasePanel',
						id: 'MSS_shareSMBZonePanel',
						title: lang_mss_share[42],
						bodyStyle: {
							paddingTop: '25px',
							paddingRight: '30px',
							paddingBottom: '30px',
							paddingLeft: '30px;',
						},
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: lang_mss_share[43] + '<br>' + lang_mss_share[70]
							},
							{
								border: false,
								items: [MSS_shareSMBZoneGrid]
							}
						]
					}
				],
				listeners: {
					tabchange: function (tabPanel, tab) {
						if (tab.id == 'MSS_shareSMBUserPanel')
						{
							if (Ext.getCmp('MSS_shareSMBInfoUserStoreLoad').getValue() != 'true')
							{
								MSS_shareSMBUserGrid.mask(lang_common[30]);
							}
							else
							{
								MSS_shareSMBUserGrid.unmask();
							}

							// SMB 접근 사용자 탭 선택 시 전체 사용자수 출력
							if (typeof(MSS_shareSMBUserStore.totalCount) != 'undefined')
							{
								document.getElementById('MSS_shareSMBUserGridHeaderTotalCount').innerHTML
									= '&nbsp;&nbsp;&nbsp;'
										+ lang_mss_share[13]
										+ ': '
										+ MSS_shareSMBUserStore.totalCount;
							}
						}

						if (tab.id == 'MSS_shareSMBGroupPanel')
						{
							if (Ext.getCmp('MSS_shareSMBInfoGroupStoreLoad').getValue() != 'true')
							{
								MSS_shareSMBGroupGrid.mask(lang_common[30]);
							}
							else
							{
								MSS_shareSMBGroupGrid.unmask();
							}

							// SMB 접근 그룹 탭 선택 시 전체 그룹수 출력
							if (typeof(MSS_shareSMBGroupStore.totalCount) != 'undefined')
							{
								document.getElementById('MSS_shareSMBGroupGridHeaderTotalCount').innerHTML
									= '&nbsp;&nbsp;&nbsp;'
										+ lang_mss_share[23]
										+ ': '
										+ MSS_shareSMBGroupStore.totalCount;
							}
						}

						if (tab.id == 'MSS_shareSMBZonePanel')
						{
							if (Ext.getCmp('MSS_shareSMBInfoZoneStoreLoad').getValue() != 'true')
							{
								MSS_shareSMBZoneGrid.mask(lang_common[30]);
							}
							else
							{
								MSS_shareSMBZoneGrid.unmask();
							}

							// SMB 접근 사용자 탭 선택 시 전체 사용자수 출력
							if (typeof(MSS_shareSMBZoneStore.totalCount) != 'undefined')
							{
								document.getElementById('MSS_shareSMBZoneGridHeaderTotalCount').innerHTML
									= '&nbsp;&nbsp;&nbsp;'
										+ lang_mss_share[226]
										+ ': '
										+ MSS_shareSMBZoneStore.totalCount;
							}
						}
					}
				}
			}
		],
		buttons: [
			{
				text: lang_mss_share[44],
				id: 'MSS_shareSMBSaveBtn',
				handler: function () {
					if (!MSS_shareSMBInfoForm.getForm().isValid())
						return false;

					waitWindow(lang_mss_share[0], lang_mss_share[45]);

					// 공유명
					var name = Ext.getCmp('MSS_shareSMBInfoName').getValue();

					// 공유의 SMB 정보 변경 데이터
					/*
					var shareSMBInfo = [];

					if (MSS_shareSMBInfoForm.isDirty())
					{
						var fields = MSS_shareSMBInfoForm.getForm().getFields().items;

						for (var i=0; i<fields.length; i++)
						{
							if (!fields[i].isDirty() || !Ext.isDefined(fields[i].name))
								continue;

							var fieldName  = fields[i].name;
							var fieldValue = fields[i].lastValue;

							if (fieldName == 'shareSMBInfoFormRightName')
							{
								if (!fieldValue)
									continue;

								if (Ext.getCmp('MSS_shareSMBInfoFormRightR').getValue())
								{
									fieldValue = 'readonly';
								}
								else if (Ext.getCmp('MSS_shareSMBInfoFormRightRW').getValue())
								{
									fieldValue = 'read/write';
								}
								else
								{
									fieldValue = '';
								}
							}

							shareSMBInfo[fieldName] = fieldValue;
						}
					}
					*/

					//var available = Ext.getCmp('MSS_shareSMBInfoFormAvailable').getValue(),
					var hidden    = Ext.getCmp('MSS_shareSMBInfoFormHide').getValue(),
						guest_ok  = Ext.getCmp('MSS_shareSMBInfoFormGuest').getValue(),
						read_only = Ext.getCmp('MSS_shareSMBInfoFormRightR').getValue();

					// 각 공유의 SMB 접근 사용자 변경 데이터
					var users = [];

					Ext.each(
						MSS_shareTempSMBUserStore.getUpdatedRecords(),
						function (record) {
							users.push({
								User: record.get('User_Name'),
								Right: record.get('AccessRight'),
							});
						}
					);

					// 각 공유의 SMB 접근 그룹 변경 데이터
					var groups = [];

					Ext.each(
						MSS_shareTempSMBGroupStore.getUpdatedRecords(),
						function (record) {
							groups.push({
								Group: record.get('Group_Name'),
								Right: record.get('AccessRight'),
							});
						}
					);

					// 각 공유의 SMB 보안 변경 데이터
					var zones = [];

					Ext.each(
						MSS_shareTempSMBZoneStore.getUpdatedRecords(),
						function (record) {
							zones.push({
								Zone: record.get('Name'),
								Right: record.get('AccessRight'),
							});
						}
					);

					GMS.Ajax.request({
						url: '/api/cluster/share/smb/update',
						jsonData: {
							Name: name,
							//Available: available ? 'yes' : 'no',
							Browseable: hidden ? 'no' : 'yes',
							Guest_Ok: guest_ok ? 'yes' : 'no',
							Read_Only: read_only ? 'yes' : 'no',
						},
						users: users,
						groups: groups,
						zones: zones,
						callback: function (options, success, response, decoded) {
							// 수정 버튼 비활성화
							Ext.getCmp('MSS_shareSMBModifyBtn').setDisabled(true);

							if (!success)
							{
								MSS_shareSMBWin.hide();
								return;
							}

							updateAccountAccessRight(name, options.users.concat(options.groups));
							updateNetworkAccessRight('SMB', name, options.zones);

							// SMB 스토어만 재구성
							MSS_shareSMBStore.load();

							// 데이터 로드 성공 메세지
							Ext.Msg.alert(lang_mss_share[0], lang_mss_share[46]);
							MSS_shareSMBWin.hide();
						}
					});
				}
			}
		]
	}
);

function updateAccountAccessRight(share, entries)
{
	entries.forEach(
		function (entry)
		{
			var payload = null;

			if (entry.hasOwnProperty('User'))
			{
				payload = {
					Name: share,
					User: entry.User,
					Right: entry.Right,
				};
			}
			else if (entry.hasOwnProperty('Group'))
			{
				payload = {
					Name: share,
					Group: entry.Group,
					Right: entry.Right,
				};
			}

			GMS.Ajax.request({
				url: '/api/cluster/share/smb/access/account/set',
				jsonData: payload,
				callback: function (options, success, response, decoded) {
					if (!success)
						return;
				}
			});
		}
	);
}

function updateNetworkAccessRight(protocol, share, entries, type)
{
	var promises = [];

	entries.forEach(
		function (entry)
		{
			var url = '/api/cluster/share/' + protocol.toLowerCase(),
				payload;

			switch (protocol.toUpperCase())
			{
				case 'SMB':
					url += '/access/network/set';

					payload = {
						Name: share,
						Zone: entry.Zone,
						Right: entry.Right,
					};
					break;
				case 'NFS':
					url += '/' + type + '/access/network/set';

					payload = {
						Name: share,
						Zone: entry.Zone,
						Right: entry.Right,
						Squash: entry.Squash,
					};
					break;
				default:
			}

			promises.push(
				GMS.Ajax.request({
					url: url,
					jsonData: payload,
					callback: function (options, success, response, decoded) {
						if (!success || !decoded.success)
						{
							options.deferred.promise().reject(response);
							return;
						}

						options.deferred.promise().resolve(decoded);
					}
				})
			);
		}
	);

	Ext.ux.Deferred
		.when(...promises)
		.then(
			function (r) {
				console.debug('response:', r);
			},
			function (e) {
				console.error('error:', e);
			},
		);
}

/*
 * 서비스 프로토콜 - NFS
 */
// 서비스 프로토콜 수정 - NFS: 설정폼
// NFS: 권한 모델
Ext.define(
	'MSS_shareNFSRightModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Name']
	}
);

// NFS: 접근 보안 권한 스토어
var MSS_shareNFSZoneRightStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareNFSRightModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			}
		}
	}
);

var MSS_shareNFSInfoForm = Ext.create(
	'BaseFormPanel',
	{
		xtype: 'BaseFormPanel',
		id: 'MSS_shareNFSInfoForm',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				id: 'MSS_shareNFSInfoFormDesc',
				bodyStyle: { padding: 0 },
				style: { marginBottom: '30px' },
				html: lang_mss_share[48]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MSS_shareNFSInfoFormNameLabel',
						text: lang_mss_share[4]+' : ',
						width: 150,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSS_shareNFSInfoFormNameLabelValue',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						id: 'MSS_shareNFSInfoFormPathLabel',
						text: lang_mss_share[5]+' : ',
						width: 150,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSS_shareNFSInfoFormPathLabelValue',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			/*
			{
				xtype: 'checkbox',
				boxLabel: lang_mss_share[9],
				id: 'MSS_shareNFSInfoFormAvailable',
				name: 'shareNFSInfoFormAvailable',
				style: { marginTop: '20px' }
			},
			*/
			{
				id: 'MSS_shareNFSInfoName',
				name: 'shareNFSInfoName',
				hidden : true
			}
		]
	}
);

/*
 * 서비스 프로토콜 수정 - NFS: 보안목록
 */
// NFS: 접근 보안 모델 (업데이트 내용 전달 모델)
Ext.define(
	'MSS_shareTempNFSZoneModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Name', 'AccessRight', 'Squash'/*, 'Insecure'*/]
	}
);

// NFS: 접근 보안 스토어 (업데이트 내용 전달 스토어)
var MSS_shareTempNFSZoneStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareTempNFSZoneModel'
	}
);

// NFS: 보안 모델
/*
Ext.define(
	'MSS_shareNFSZoneModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'ZoneName', 'Access' ,'ZoneInfo', 'ZoneInfo',
			'NoRootSquashing', 'Insecure'
		]
	}
);
*/

Ext.define(
	'MSS_shareNFSZoneModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			// default attrs
			'Name', 'Desc', 'Type',
			// network address specifiers
			'Addrs', 'Range', 'CIDR', 'Domain',
			// right
			'AccessRight',
			// options
			'Squash', /*'Insecure',*/
		]
	}
);

// NFS: 보안 스토어
var MSS_shareNFSZoneStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareNFSZoneModel',
		remoteFilter: true,
		remoteSort: true,
		pageSize: 25,
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/nfs/ganesha/zones',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
				//getResponseData: function (response) {
				//	console.log('getResponseData: ', response);
				//}
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				MSS_shareTempNFSZoneStore.removeAll();
				store.removeAll();

				var grid = Ext.getCmp('MSS_shareGrid');

				Ext.apply(
					store.getProxy().extraParams,
					{
						Name: MSS_shareGrid.getSelectionModel().getSelection()[0].get('Name')
					}
				);
			},
			load: function (store, records, success, eOpts) {
				var grid = Ext.getCmp('MSS_shareNFSZoneGrid');

				if (typeof(grid.el) != 'undefined')
					grid.unmask();

				if (success != true)
				{
					// 예외 처리에 따른 동작
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mss_share[0] + '",'
						+ '"content": "' + lang_mss_share[28] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				if (!grid.el)
					return;

				document.getElementById('MSS_shareNFSZoneGridHeaderTotalCount').innerHTML
					= '&nbsp;&nbsp;&nbsp;'
						+ lang_mss_share[226]
						+ ': '
						+ MSS_shareNFSZoneStore.totalCount;
			},
		},
	}
);

// NFS: 보안 그리드
var MSS_shareNFSZoneGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareNFSZoneGrid',
		store: MSS_shareNFSZoneStore,
		title: lang_mss_share[29],
		height: 300,
		header: {
			titlePosition: 0,
			items: [
				{
					xtype: 'panel',
					id: 'MSS_shareNFSZoneGridHeaderTotalCount',
					style: 'text-align: right; padding-right: 20px;',
					bodyCls: 'm-custom-transparent',
					border: false,
					width: 300,
					height: 16,
					html: ''
				}
			],
		},
		plugins: [
			Ext.create(
				'Ext.grid.plugin.CellEditing',
				{
					clicksToEdit: 1,
				}
			),
		],
		columns: [
			Ext.create(
				'Ext.grid.RowNumberer',
				{
					width: 35,
					resizable: true
				}
			),
			{
				flex: 1,
				dataIndex: 'Name',
				text: lang_mss_share[30],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'Desc',
				text: lang_mss_share[95],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'Type',
				text: lang_mss_share[31],
				sortable: true,
				menuDisabled: true,
				renderer: function (value, metaData, record, row, col, store, gridView) {
					switch (value)
					{
						case 'addrs':
							return record.get('Addrs');
							break;
						case 'range':
							return record.get('Range');
							break;
						case 'cidr':
							return record.get('CIDR');
							break;
						case 'domain':
							return record.get('Domain');
							break;
					}

					// TODO: ignore or discard this record to prevent change
					// with invalid network zone type
					return 'Unknown';
				}
			},
			{
				flex: 1,
				dataIndex: 'AccessRight',
				text: lang_mss_share[18],
				sortable: true,
				menuDisabled: true,
				// 변경셀 색상 변경,
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: {
						marginTop: '6px',
						marginBottom: '3px'
					},
					editable: false,
					store: MSS_shareNFSZoneRightStore,
					valueField: 'Name',
					displayField: 'Name',
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareNFSZoneGrid.selModel.selected.items[0];

								record.set('AccessRight', newValue);

								// 변경 데이터 css 변경
								field.fireEvent('dirtychange', newValue, [record]);
							}, 50);
						},
						dirtychange: function (combo, isDirty, eOpts) {
							if (isDirty[0].data.AccessRight == isDirty[0].raw.AccessRight
								&& isDirty[0].data.Squash == isDirty[0].raw.Squash)
							{
								Ext.getCmp('MSS_shareNFSZoneGrid').getView().removeRowCls(isDirty[0].index);
								return;
							}

							var record = MSS_shareNFSZoneGrid.selModel.selected.items[0];

							MSS_shareTempNFSZoneStore.add(record);

							Ext.getCmp('MSS_shareNFSZoneGrid').getView()
								.removeRowCls(isDirty[0].index);

							Ext.getCmp('MSS_shareNFSZoneGrid').getView()
								.addRowCls(isDirty[0].index, 'm-custom-grid-change');
						}
					}
				},
			},
			{
				flex: 1,
				dataIndex: 'Squash',
				text: 'Squash',
				sortable: true,
				menuDisabled: true,
				// 변경셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					style: {
						marginTop: '6px',
						marginBottom: '3px'
					},
					editable: false,
					store: ['no_root_squash', 'root_squash', 'all_squash'],
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareNFSZoneGrid.selModel.selected.items[0];

								record.set('Squash', newValue);

								// 변경 데이터 css 변경
								field.fireEvent('dirtychange', newValue, [record]);
							}, 50);
						},
						dirtychange: function (combo, isDirty, eOpts) {
							if (isDirty[0].data.AccessRight == isDirty[0].raw.AccessRight
								&& isDirty[0].data.Squash == isDirty[0].raw.Squash)
							{
								Ext.getCmp('MSS_shareNFSZoneGrid').getView()
									.removeRowCls(isDirty[0].index);

								return;
							}

							var record = MSS_shareNFSZoneGrid.selModel.selected.items[0];

							MSS_shareTempNFSZoneStore.add(record);

							Ext.getCmp('MSS_shareNFSZoneGrid').getView()
								.removeRowCls(isDirty[0].index);

							Ext.getCmp('MSS_shareNFSZoneGrid').getView()
								.addRowCls(isDirty[0].index, 'm-custom-grid-change');
						}
					}
				},
			},
		],
	}
);

/*
 * 서비스 프로토콜 수정 - NFS 데이터 로드
 */
function MSS_shareNFSWinLoad(share)
{
	if (typeof(share) == 'undefined'
		|| share == null)
	{
		console.error('Invalid share record:', share);
		return null;
	}

	var nfs_type = getNFSType(share);

	if (nfs_type == null)
	{
		console.error('Failed to get NFS type:', share);
		return;
	}

	shareNFSRightsLoad(share);

	GMS.Ajax.request({
		waitMsgBox: waitWindow(lang_mss_share[0], lang_mss_share[142]),
		url: '/api/cluster/share/nfs/' + nfs_type + '/info',
		jsonData: {
			Name: share.get('Name'),
		},
		callback: function (options, success, response, decoded) {
			if (!success)
				return;

			// NFS 정보 로드
			// 공유명
			Ext.getCmp('MSS_shareNFSInfoFormNameLabelValue')
				.update(decoded.entity.Name);

			Ext.getCmp('MSS_shareNFSInfoName')
				.setValue(decoded.entity.Name);

			// 공유 경로
			Ext.getCmp('MSS_shareNFSInfoFormPathLabelValue')
				.update(decoded.entity.Path);

			// NFS 상세 정보 WINDOW SHOW
			Ext.getCmp('MSS_shareNFSInfo').setActiveTab(0);

			MSS_shareNFSWin.show();

			/*
			 * 데이터 로드 후 원본 데이터로 인식
			 * 변경된 데이터만 인식하기 위한 내용
			 */
			if (MSS_shareNFSInfoForm.isDirty())
			{
				var fields = MSS_shareNFSInfoForm.getForm().getFields().items;

				for (var i=0; i<fields.length; i++)
				{
					fields[i].resetOriginalValue();
				}
			}
		}
	});
};

function shareNFSRightsLoad(share)
{
	if (typeof(share) == 'undefined'
		|| share == null)
	{
		console.error('Invalid share record:', share);
		return null;
	}

	var nfs_type = getNFSType(share);

	if (nfs_type == null)
	{
		console.error('Failed to get NFS type:', share);
		return;
	}

	GMS.Ajax.request({
		url: '/api/cluster/share/nfs/' + nfs_type + '/rights',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				MSS_shareNFSWin.hide();
				return;
			}

			// NFS 네트워크 영역 권한 데이터 로드
			MSS_shareNFSZoneRightStore.loadRawData(decoded.entity.Zone, false);
			shareNFSZoneLoad(share);
		}
	});
}

function shareNFSZoneLoad(share)
{
	if (typeof(share) == 'undefined'
		|| share == null)
	{
		console.error('Invalid share record:', share);
		return null;
	}

	var nfs_type = getNFSType(share);

	if (nfs_type == null)
	{
		console.error('Failed to get NFS type:', share);
		return;
	}

	// NFS 보안 정보 로드
	MSS_shareNFSZoneStore.getProxy().url
		= '/api/cluster/share/nfs/' + nfs_type + '/zones';

	MSS_shareNFSZoneStore.load();
}

/*
 * 서비스 프로토콜 수정 - NFS
 */
var MSS_shareNFSWin = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareNFSWin',
		layout: 'fit',
		maximizable: false,
		width: 600,
		height: 510,
		title: lang_mss_share[50],
		items: [
			{
				xtype: 'tabpanel',
				id: 'MSS_shareNFSInfo',
				activeTab: 0,
				bodyBorder: false,
				border: false,
				height: 320,
				bodyStyle: { padding: 0 },
				items: [
					{
						xtype: 'BasePanel',
						id: 'MSS_shareNFSInfoPanel',
						title: lang_mss_share[50],
						bodyStyle: { padding: 0 },
						items: [ MSS_shareNFSInfoForm ]
					},
					{
						xtype: 'BasePanel',
						id: 'MSS_shareNFSZonePanel',
						title: lang_mss_share[51],
						bodyStyle: {
							paddingTop: '25px',
							paddingRight: '30px',
							paddingBottom: '30px',
							paddingLeft: '30px',
						},
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: lang_mss_share[52] + '<br>' + lang_mss_share[53]
							},
							{
								border: false,
								items: [ MSS_shareNFSZoneGrid ]
							}
						]
					}
				]
			}
		],
		buttons: [
			{
				text: lang_mss_share[54],
				id: 'MSS_shareNFSSaveBtn',
				handler: function () {
					if (!MSS_shareNFSInfoForm.getForm().isValid())
						return false;

					waitWindow(lang_mss_share[0], lang_mss_share[55]);

					// 공유명
					var name      = Ext.getCmp('MSS_shareNFSInfoName').getValue();
					//var available = Ext.getCmp('MSS_shareNFSInfoFormAvailable').getValue();
					var share     = MSS_shareStore.findRecord('Name', name);
					var type      = getNFSType(share);

					// 공유의 NFS 정보 변경 데이터
					var shareNFSInfo = [];

					if (MSS_shareNFSInfoForm.isDirty())
					{
						var fields = MSS_shareNFSInfoForm.getForm().getFields().items;

						for (var i=0; i<fields.length; i++)
						{
							if (!fields[i].isDirty()
									|| !Ext.isDefined(fields[i].name))
								continue;

							var fieldName  = fields[i].name;
							var fieldValue = fields[i].lastValue;

							shareNFSInfo[fieldName] = fieldValue;
						}
					}

					// 각 공유의 NFS 보안 변경 데이터
					var zones = [];

					Ext.each(
						MSS_shareTempNFSZoneStore.getUpdatedRecords(),
						function (record) {
							zones.push({
								Zone: record.get('Name'),
								Right: record.get('AccessRight'),
								Squash: record.get('Squash'),
								/*Insecure: record.data.Insecure*/
							});
						}
					);

					GMS.Ajax.request({
						url: '/api/cluster/share/nfs/' + type + '/update',
						jsonData: {
							Name: name,
							//Available: available ? 'yes' : 'no',
						},
						zones: zones,
						callback: function (options, success, response, decoded) {
							// 수정 버튼 비활성화
							Ext.getCmp('MSS_shareNFSModifyBtn').setDisabled(true);

							if (!success)
							{
								MSS_shareNFSWin.hide();
								return;
							}

							updateNetworkAccessRight('NFS', name, options.zones, type);

							// NFS 스토어만 재구성
							MSS_shareNFSLoad();

							// 데이터 로드 성공 메세지
							Ext.Msg.alert(lang_mss_share[0], lang_mss_share[56]);
							MSS_shareNFSWin.hide();
						}
					});
				}
			}
		]
	}
);

/*
 * 공유 정보
 */
// 공유 생성 볼륨, 경로 모델
Ext.define(
	'MSS_shareVolumeModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Pool_Name',
			'Policy',
			'Volume_Type',
			'Volume_Name',
			'Volume_Mount',
		],
	}
);

//볼륨 스토어
var MSS_shareVolumeStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareVolumeModel',
		sorters: [
			{ property: 'Pool_Name', direction: 'ASC' },
			{ property: 'Volume_Name', direction: 'ASC' },
		],
		sortOnLoad: true,
		proxy: {
			type: 'ajax',
			url: '/api/cluster/volume/list',
			reader: {
				type: 'json',
				root: 'entity'
			}
		}
	}
);

/*
 * POSIX 권한 정보 (사용자, 그룹)
 */
function loadPOSIXAccount(shareName)
{
	var type     = Ext.getCmp('MSS_shareInfoPOSIXOwnerType').getValue();
	var location = Ext.getCmp('MSS_shareInfoPOSIXLocationType').getValue();
	var name     = Ext.getCmp('shareInfoPOSIXOwnerFilterArgs').getValue();

	type = type.toLowerCase();

	if (type !== 'user' && type !== 'group')
	{
		// TODO: Exception handling
		return;
	}

	var grid  = MSS_shareInfoPOSIXRightOwnerGrid;
	var store = MSS_shareInfoPOSIXRightOwnerStore;

	switch (type)
	{
		case 'user':
			grid.columnManager.getColumns()[1].setVisible(true);
			//grid.columnManager.getColumns()[2].setVisible(true);
			grid.columnManager.getColumns()[3].setVisible(false);
			//grid.columnManager.getColumns()[4].setVisible(false);
			grid.columnManager.getColumns()[5].setVisible(true);
			grid.columnManager.getColumns()[6].setVisible(false);
			break;
		case 'group':
			grid.columnManager.getColumns()[1].setVisible(false);
			//grid.columnManager.getColumns()[2].setVisible(false);
			grid.columnManager.getColumns()[3].setVisible(true);
			//grid.columnManager.getColumns()[4].setVisible(true);
			grid.columnManager.getColumns()[5].setVisible(false);
			grid.columnManager.getColumns()[6].setVisible(true);
			break;
	}

	var grid_mask = new Ext.LoadMask(grid, { msg: (lang_common[30]) });

	grid_mask.show();
	store.clearData();

	GMS.Ajax.request({
		url: '/api/cluster/share/smb/' + type + 's',
		jsonData: {
			argument: {
				Location: location,
				Filters: [
					{
						FilterType: type.charAt(0).toUpperCase() + type.slice(1) + '_Name',
						FilterStr: name,
					},
				],
			},
			Name: shareName,
		},
		callback: function (options, success, response, decoded) {
			grid_mask.hide();

			if (!success)
				return;

			// 로드 전 기존 데이터 제거
			var store = MSS_shareInfoPOSIXRightOwnerStore;

			store.loadRawData(decoded, false);

			var sorter         = store.sorters.getAt(0);
			var sort_column    = sorter.property,
				sort_direction = sorter.direction;

			if (type == 'user' && sort_column != 'User_Name')
			{
				sort_column    = 'User_Name';
				sort_direction = 'ASC';
			}
			else if (type == 'group' && sort_column != 'Group_Name')
			{
				sort_column    = 'Group_Name';
				sort_direction = 'ASC';
			}

			store.sort(sort_column, sort_direction);
		}
	});

	return;
}
// POSIX 권한 설정 정보 owner 모델
Ext.define(
	'MSS_shareInfoPOSIXRightOwnerModel',
	{
		extend: 'Ext.data.Model',
		pruneRemoved: false,
		fields: [
			'User_Name',
			'User_Location',
			'Group_Name',
			'Group_Location',
			{ name: 'Right', defaultValue: 'R' },
			'User_Desc',
			'Group_Desc',
		]
	}
);

// POSIX 권한 설정 정보 owner 스토어
var MSS_shareInfoPOSIXRightOwnerStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MSS_shareInfoPOSIXRightOwnerModel',
		sorters: [
			{ property: 'User_Desc', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
				totalProperty: 'count',
			},
		},
	}
);

// POSIX 권한 설정 정보 owner 그리드
var MSS_shareInfoPOSIXRightOwnerGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareInfoPOSIXRightOwnerGrid',
		frame: false,
		store: MSS_shareInfoPOSIXRightOwnerStore,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			mode: 'SINGLE',
			allowDeselect: true,
			pruneRemoved: false
		},
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1
			})
		],
		frame: false,
		columns: [
			{
				flex: 1,
				dataIndex: 'User_Name',
				text: lang_mss_share[15],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'User_Location',
				text: lang_mss_share[17],
				sortable: false,
				menuDisabled: true,
				hidden: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Name',
				text: lang_mss_share[25],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Group_Location',
				text: lang_mss_share[17],
				sortable: false,
				menuDisabled: true,
				hidden: true
			},
			{
				flex: 1,
				dataIndex: 'User_Desc',
				text: lang_mau_user[8],
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
				dataIndex: 'Right',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: { marginTop: '2px', marginBottom: '2px' },
					editable: false,
					dirty: true,
					store: new Ext.data.SimpleStore({
						fields: ['view', 'code'],
						data: [
							[lang_mss_share[150], 'R'],
							[lang_mss_share[152], 'RW'],
							[lang_mss_share[193], 'None']
						]
					}),
					value: 'R',
					valueField: 'code',
					displayField: 'view',
					width: 60
				},
				renderer: function (value) {
					switch (value) {
						case 'R':
							return lang_mss_share[150];
						case 'RW':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			}
		],
		tbar: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareInfoPOSIXOwnerType',
				hiddenName: 'shareInfoPOSIXOwnerType',
				name: 'shareInfoPOSIXOwnerType',
				width: 120,
				store: new Ext.data.SimpleStore({
					fields: ['OwnerType', 'OwnerCode'],
					data: [
						[lang_mss_share[172], 'user'],
						[lang_mss_share[173], 'group']
					]
				}),
				value: 'user',
				displayField: 'OwnerType',
				valueField: 'OwnerCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						//MSS_shareInfoPOSIXRightOwnerStore.load();
						var shareName = Ext.getCmp('MSS_shareInfoModifyName').getValue();
						loadPOSIXAccount(shareName);
					}
				}
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareInfoPOSIXLocationType',
				hiddenName: 'shareInfoPOSIXLocationType',
				name: 'shareInfoPOSIXLocationType',
				width: 120,
				store: new Ext.data.SimpleStore({
					fields: ['LocationType', 'LocationCode'],
					data: [
						['LOCAL', 'LOCAL'],
						['LDAP', 'LDAP'],
						['Active Directory', 'ADS'],
					]
				}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						//MSS_shareInfoPOSIXRightOwnerStore.load();
						var shareName = Ext.getCmp('MSS_shareInfoName').getValue();
						loadPOSIXAccount(shareName);
					}
				}
			},
			'-',
			lang_mss_share[22],
			{
				xtype: 'searchfield',
				id: 'shareInfoPOSIXOwnerFilterArgs',
				store: MSS_shareInfoPOSIXRightOwnerStore,
				paramName: 'searchStr',
				width: 120
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

// POSIX 권한 설정 Window
var MSS_shareInfoPOSIXRightWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareInfoPOSIXRightWindow',
		title: lang_mss_share[194],
		layout: 'fit',
		width: 500,
		height:450,
		items:[
			{
				xtype: 'BasePanel',
				id: 'MSS_shareInfoPOSIXUserPanel',
				layout: 'fit',
				frame: false,
				bodyStyle: { padding: 0 },
				items: [MSS_shareInfoPOSIXRightOwnerGrid]
			}
		],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_mss_share[195],
				id: 'MSS_shareInfoPOSIXRightClose',
				handler: function () {
					MSS_shareInfoPOSIXRightWindow.hide();
				}
			},
			{
				text: lang_mss_share[197],
				id: 'MSS_shareInfoPOSIXRightAdd',
				handler: function () {
					var openedWindow;

					// 수정 창에서 호출 시
					if (MSS_shareInfoPOSIXRightWindow.animateTarget.id
						== 'MSS_shareInfoModifyPOSIXRightSet')
					{
						openedWindow = MSS_shareInfoModifyPOSIXStore;
					}
					// 생성 창에서 호출시
					else if (MSS_shareInfoPOSIXRightWindow.animateTarget.id
							== 'MSS_shareInfoPOSIXRightSet')
					{
						openedWindow = MSS_shareInfoPOSIXStore;
					}

					var addRecord = MSS_shareInfoPOSIXRightOwnerGrid.getSelectionModel().getSelection()[0];
					var ownerType = Ext.getCmp('MSS_shareInfoPOSIXOwnerType').getValue();
					var locationType = Ext.getCmp('MSS_shareInfoPOSIXLocationType').getValue();

					if (ownerType == 'user')
					{
						var addRecordSet = {
							"Type": "User",
							"ID": addRecord.get('User_Name'),
							"Desc": addRecord.get('User_Desc'),
							"Right": addRecord.get('Right'),
						};

						openedWindow.each(function (record) {
							if (record.get('Type') == 'User')
							{
								record.set(addRecordSet);
								return false;
							}
						});
					}
					else
					{
						var addRecordSet = {
							"Type": "Group",
							"ID": addRecord.get('Group_Name'),
							"Desc": addRecord.get('Group_Desc'),
							"Right": addRecord.get('Right'),
						};

						openedWindow.each(function (record) {
							if (record.get('Type') == 'Group')
							{
								record.set(addRecordSet);
								return false;
							}
						});
					}
				}
			}
		]
	}
);

// ACL 권한 설정 정보 owner (사용자, 그룹)
// ACL 권한 설정 정보 owner 모델
Ext.define(
	'MSS_shareInfoACLRightOwnerModel',
	{
		extend: 'Ext.data.Model',
		pruneRemoved: false,
		fields: [
			'User_Name',
			'User_Location',
			'Group_Name',
			'Group_Location',
			{ name: 'Right', defaultValue: 'R' },
			'User_Desc',
			'Group_Desc'
		]
	}
);

// ACL 권한 설정 정보 owner 스토어
var MSS_shareInfoACLRightOwnerStore = Ext.create(
	'BaseBufferStore',
	{
		model: 'MSS_shareInfoACLRightOwnerModel',
		sorters: [
			{ property: 'User_Desc', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			},
		},
		/*
		proxy: {
			type: 'ajax',
			url: '/index.php/admin/manager_share_share/shareInfoACLOwnerInfo',
			reader: {
				type: 'json',
				root: 'OwnerListData',
				totalProperty: 'totalOwnerCount'
			}
		},
		*/
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				MSS_shareInfoACLRightOwnerStore.clearData();

				store.proxy.setExtraParam('ownerType', Ext.getCmp('MSS_shareInfoACLOwnerType').getValue());
				store.proxy.setExtraParam('LocationType', Ext.getCmp('MSS_shareInfoACLLocationType').getValue());

				var sorter         = store.sorters.getAt(0);
				var sort_column    = sorter.property;
				var sort_direction = sorter.direction;

				if (Ext.getCmp('MSS_shareInfoACLOwnerType').getValue() == 'user')
				{
					if (sort_column != 'User_Name')
					{
							sort_column    = 'User_Name';
							sort_direction = 'ASC';

							store.sort('User_Name', 'ASC');
					}
					
					store.proxy.setExtraParam('property', sort_column);
					store.proxy.setExtraParam('direction', sort_direction);

					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[1].setVisible(true);
					//MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[2].setVisible(true);
					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[3].setVisible(false);
					//MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[4].setVisible(false);
					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[5].setVisible(true);
					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[6].setVisible(false);
				}
				else if (Ext.getCmp('MSS_shareInfoACLOwnerType').getValue() == 'group')
				{
					if (sort_column != 'Group_Name')
					{
							sort_column    = 'Group_Name';
							sort_direction = 'ASC';

							store.sort('Group_Name', 'ASC');
					}

					store.proxy.setExtraParam('property', sort_column);
					store.proxy.setExtraParam('direction', sort_direction);

					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[1].setVisible(false);
					//MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[2].setVisible(false);
					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[3].setVisible(true);
					//MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[4].setVisible(true);
					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[5].setVisible(false);
					MSS_shareInfoACLRightOwnerGrid.columnManager.getColumns()[6].setVisible(true);
				}
			},
			load: function (store, records, success) {
				if (success === true)
					return;

				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mss_share[0] + '",'
					+ '"content": "' + lang_mss_share[162] + '",'
					+ '"response": ' + jsonText
				+ '}';

				return exceptionDataCheck(checkValue);
			}
		}
	}
);

// ACL 권한 설정 정보 owner 그리드
var MSS_shareInfoACLRightOwnerGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareInfoACLRightOwnerGrid',
		frame: false,
		store: MSS_shareInfoACLRightOwnerStore,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			allowDeselect: true,
			pruneRemoved: false,
		},
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1,
			})
		],
		frame: false,
		columns: [
			{
				flex: 1,
				dataIndex: 'User_Name',
				text: lang_mss_share[15],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'User_Location',
				text: lang_mss_share[17],
				sortable: false,
				menuDisabled: true,
				hidden: true,
			},
			{
				flex: 1,
				dataIndex: 'Group_Name',
				text: lang_mss_share[25],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'Group_Location',
				text: lang_mss_share[17],
				sortable: false,
				menuDisabled: true,
				hidden: true,
			},
			{
				flex: 1,
				dataIndex: 'User_Desc',
				text: lang_mau_user[8],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'Group_Desc',
				text: lang_mau_user[17],
				sortable: true,
				menuDisabled: true,
			},
			{
				flex: 1,
				dataIndex: 'Right',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: {
						marginTop: '2px',
						marginBottom: '2px',
					},
					editable: false,
					dirty: true,
					store: new Ext.data.SimpleStore({
						fields: ['view', 'code'],
						data: [
							[lang_mss_share[150], 'R'],
							[lang_mss_share[152], 'RW'],
							[lang_mss_share[193], 'None'],
						]
					}),
					value: 'R',
					valueField: 'code',
					displayField: 'view',
					width: 60,
				},
				renderer: function (value) {
					switch (value) {
						case 'R':
							return lang_mss_share[150];
						case 'RW':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			}
		],
		tbar: [
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareInfoACLOwnerType',
				hiddenName: 'shareInfoACLOwnerType',
				name: 'shareInfoACLOwnerType',
				width: 120,
				store: new Ext.data.SimpleStore({
					fields: ['OwnerType', 'OwnerCode'],
					data: [
						[lang_mss_share[172], 'user'],
						[lang_mss_share[173], 'group']
					]
				}),
				value: 'user',
				displayField: 'OwnerType',
				valueField: 'OwnerCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MSS_shareInfoACLRightOwnerStore.load();
					}
				}
			},
			'-',
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareInfoACLLocationType',
				hiddenName: 'shareInfoACLLocationType',
				name: 'shareInfoACLLocationType',
				width: 120,
				store: new Ext.data.SimpleStore({
					fields: ['LocationType', 'LocationCode'],
					data: [
						['LOCAL', 'LOCAL'],
						['LDAP', 'LDAP'],
						['Active Directory', 'ADS'],
					]
				}),
				value: 'LOCAL',
				displayField: 'LocationType',
				valueField: 'LocationCode',
				listeners: {
					change: function (combo, newValue, oldValue) {
						MSS_shareInfoACLRightOwnerStore.load();
					}
				}
			},
			'-',
			lang_mss_share[22],
			{
				xtype: 'searchfield',
				id: 'shareInfoACLOwnerFilterArgs',
				store: MSS_shareInfoACLRightOwnerStore,
				paramName: 'searchStr',
				width: 120
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

// ACL 권한 설정 Window
var MSS_shareInfoACLRightWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareInfoACLRightWindow',
		title: lang_mss_share[196],
		layout: 'fit',
		width: 500,
		height:450,
		items:[
			{
				xtype: 'BasePanel',
				id: 'MSS_shareInfoACLUserPanel',
				layout: 'fit',
				frame: false,
				bodyStyle: { padding: 0 },
				items: [MSS_shareInfoACLRightOwnerGrid]
			}
		],
		buttonAlign: 'right',
		buttons: [
			{
				text: lang_mss_share[195],
				id: 'MSS_shareInfoACLRightClose',
				handler: function () {
					MSS_shareInfoACLRightWindow.hide();
				}
			},
			{
				text: lang_mss_share[197],
				id: 'MSS_shareInfoACLRightAdd',
				handler: function (btn) {
					var openedWindow;

					// 수정 창에서 호출 시
					if (MSS_shareInfoACLRightWindow.animateTarget.id
						== 'MSS_shareInfoModifyACLRightSet')
					{
						openedWindow = MSS_shareInfoModifyACLStore;
					}
					// 생성 창에서 호출 시
					else if (MSS_shareInfoACLRightWindow.animateTarget.id
							== 'MSS_shareInfoACLRightSet')
					{
						openedWindow = MSS_shareInfoACLStore;
					}

					var deleteRecord = [];
					var record = [];
					var selected = MSS_shareInfoACLRightOwnerGrid.getSelectionModel().getSelection();
					var ownerType = Ext.getCmp('MSS_shareInfoACLOwnerType').getValue();
					var locationType = Ext.getCmp('MSS_shareInfoACLLocationType').getValue();

					if (ownerType == 'user')
					{
						for (var i=0, len=selected.length; i<len; i++)
						{
							record.push({
								"Type": "User",
								"ID": selected[i].get('User_Name'),
								"Desc": selected[i].get('User_Desc'),
								"Right": selected[i].get('Right'),
							});
							
							// ACL 제거
							openedWindow.each(function (rec) {
								if (rec.get('Type') == 'User'
									&& rec.get('ID') == selected[i].get('User_Name'))
								{
									deleteRecord.push(rec);
								}
							});
						}
					}
					else
					{
						for (var i=0, len=selected.length; i<len; i++)
						{
							record.push({
								"Type": "Group",
								"ID": selected[i].get('Group_Name'),
								"Desc": selected[i].get('Group_Desc'),
								"Right": selected[i].get('Right'),
							});

							// ACL 제거
							openedWindow.each(function (rec) {
								if (rec.get('Type') == 'Group'
									&& rec.get('ID') == selected[i].get('Group_Name'))
								{
									deleteRecord.push(rec);
								}
							});
						}
					}

					// 중복 사용자, 그룹 제거
					openedWindow.remove(deleteRecord);

					// ACL 소유주 ADD
					openedWindow.add(record);
				}
			}
		]
	}
);

// 공유 생성

// 공유 생성 step1 :: 공유 생성 정보 출력 */
var MSS_shareInfoStep1Panel = Ext.create(
	'BasePanel',
	{
		id: 'MSS_shareInfoStep1Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: { padding: 0 },
		items: [
			{
				xtype: 'image',
				src: '/admin/images/bg_wizard.jpg',
				height: 540,
				width: 150
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mss_share[153]
					},
					{
						xtype: 'BaseWizardContentPanel',
						items: [
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mss_share[154] + '(1/2)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mss_share[155]
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '<li>' + lang_mcv_volume[24] + ', ' + lang_mss_share[156] + '(2/2)</li>'
							},
							{
								border: false,
								style: { marginBottom: '20px' },
								html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mss_share[157]
							}
						]
					}
				]
			}
		]
	}
);

// 공유 생성 step2 :: 공유 정보 입력 */
var MSS_shareInfoStep2Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSS_shareInfoStep2Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: { padding: 0 },
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
						text: lang_mss_share[154]
					},
					{
						xtype: 'label',
						style: 'marginBottom: 20px;',
						text: lang_mss_share[156]
					}
				]
			},
			{
				xtype: 'BaseFormPanel',
				id: 'MSS_shareInfoForm',
				frame: false,
				bodyStyle: { padding: 0 },
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mss_share[160]
					},
					{
						xtype: 'BaseWizardContentPanel',
						height: 220,
						items: [
							{
								xtype: 'BaseComboBox',
								id: 'MSS_shareInfoPool',
								fieldLabel: lang_mss_share[228],
								allowBlank: false,
								style: { marginBottom: '20px' },
								store: MSS_shareVolumeStore,
								displayField: 'Pool_Name',
								valueField: 'Pool_Name',
								listeners: {
									expand: function (field, eOpts) {
										MSS_shareVolumeStore.clearFilter();

										var poolName = MSS_shareVolumeStore.collect("Pool_Name");
										var poolCheck = {};

										MSS_shareVolumeStore.filterBy(
											function (record) {
												var name = record.get("Pool_Name");

												if (poolCheck[name])
												{
													return false;
												}
												else
												{
													poolCheck[name] = true;
													return true;
												}
											}
										);
									},
									select: function (selModel, records) {
										var nfs_flag = false;

										MSS_shareStore.each(
											function (share) {
												var volume = getVolume(share.get('Volume'));

												if (share.get('NFS_Enabled') == 'yes'
													&& (volume == null
														|| volume.get('Volume_Type') != records[0].get('Volume_Type')))
												{
													nfs_flag = true;
												}
											}
										);

										if (nfs_flag)
										{
											Ext.getCmp('MSS_shareInfoNFS').setValue('no');
											Ext.getCmp('MSS_shareInfoNFS').setDisabled(true);
										}
										else
										{
											Ext.getCmp('MSS_shareInfoNFS').setDisabled(false);
										}

										Ext.getCmp('MSS_shareInfoVolume').clearValue();
										Ext.getCmp('MSS_shareInfoVolume').setDisabled(false);
									},
								},
							},
							{
								xtype: 'BaseComboBox',
								id: 'MSS_shareInfoVolume',
								name: 'shareInfoVolume',
								fieldLabel: lang_mss_share[92],
								allowBlank: false,
								style: { marginBottom: '20px' },
								store: MSS_shareVolumeStore,
								displayField: 'Volume_Name',
								valueField: 'Volume_Mount',
								listeners: {
									expand: function (field, eOpts) {
										var pool = Ext.getCmp('MSS_shareInfoPool').getValue();

										MSS_shareVolumeStore.clearFilter();
										MSS_shareVolumeStore.filter(
											function (item) {
												const name   = item.get('Pool_Name');
												const regexp = new RegExp('^' + name + '$', 'g');

												return pool.search(regexp) >= 0 ? true : false;
											}
										);
									},
									select: function (selModel, records) {
										if (!records[0].get('Volume_Name'))
											return;

										// 볼륨에 대한 디렉토리 정보 가져오기
										MSS_shareInfoDirectoryStore.proxy.extraParams = {
											argument: {
												type: ['dir'],
												dirpath: records[0].get('Volume_Mount'),
											}
										};

										MSS_shareInfoDirectoryStore.load();
										MSS_shareInfoDirectoryGrid.getSelectionModel().clearSelections();

										// 볼륨에 대한 소유주, 권한 가져오기 - 생성일 때 경로 선택하지 않는 경우
										MSS_shareInfoPOSIXStore.load();
										MSS_shareInfoACLStore.load();
									}
								}
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareInfoName',
								name: 'shareInfoName',
								fieldLabel: lang_mss_share[4],
								allowBlank: false,
								vtype: 'reg_shareInfoName',
								style: { marginBottom: '20px' }
							},
							{
								xtype: 'textfield',
								id: 'MSS_shareInfoDesc',
								name: 'shareInfoDesc',
								fieldLabel: lang_mss_share[95],
								vtype: 'reg_DESC',
								style: { marginBottom: '20px' }
							},
							{
								xtype: 'checkboxgroup',
								fieldLabel: lang_mss_share[96],
								width: 300,
								items: [
									{
										boxLabel: 'SMB',
										id: 'MSS_shareInfoSMB',
										name: 'shareInfoSMB',
									},
									{
										boxLabel: 'NFS',
										id: 'MSS_shareInfoNFS',
										name: 'shareInfoNFS',
									}
								]
							}
						]
					}
				]
			}
		]
	}
);

/*
 * 디렉터리 권한 :: POSIX
 */
// 디렉터리 권한 :: POSIX - 모델
Ext.define(
	'MSS_shareInfoPOSIXModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Type', 'ID', 'Desc', /*'Location',*/
			{ name: 'Right', defaultValue: 'R' }
		]
	}
);

// 디렉터리 권한 :: POSIX - 스토어
var MSS_shareInfoPOSIXStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareInfoPOSIXModel',
		proxy: {
			type: 'ajax',
			url: '/api/explorer/getfacl',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				store.removeAll();

				// 공유 경로
				var path,
					selmodel = MSS_shareInfoDirectoryGrid.getSelectionModel();

				if (selmodel.getCount() > 0)
				{
					// 디렉토리 목록이 선택 되었을경우
					path = selmodel.getSelection()[0].get('FullPath');
				}
				else
				{
					// 디렉토리 목록이 선택되지 않았을 경우 - 생성
					selmodel = MSS_shareGrid.getSelectionModel()
					path     = Ext.getCmp('MSS_shareInfoVolume').getValue();
				}

				store.proxy.setExtraParam(
					'argument',
					{
						Type: 'POSIX',
						Path: path,
					}
				);
			},
			load: function (store, records, success) {
				if (success === true)
					return;

				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mss_share[0] + '",'
					+ '"content": "' + lang_mss_share[192] + '",'
					+ '"response": ' + jsonText
				+ '}';

				return exceptionDataCheck(checkValue);
			}
		}
	}
);

// 설정된 디렉터리 권한 :: POSIX - 그리드
var MSS_shareInfoPOSIXGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareInfoPOSIXGrid',
		store: MSS_shareInfoPOSIXStore,
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1
			})
		],
		frame: false,
		columns: [
			{
				flex: 1,
				dataIndex: 'Type',
				text: lang_mss_share[198],
				sortable: false,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'ID',
				text: 'ID',
				sortable: false,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Desc',
				text: lang_mss_share[199],
				sortable: false,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Right',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				// 변경셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: {marginTop: '2px',marginBottom: '2px'},
					editable: false,
					dirty: true,
					store: new Ext.data.SimpleStore({
						fields: ['view', 'code'],
						data: [
							[lang_mss_share[150], 'R'],
							[lang_mss_share[152], 'RW'],
							[lang_mss_share[193], 'None']
						]
					}),
					value: 'R',
					valueField: 'code',
					displayField: 'view',
					width: 60,
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareInfoPOSIXGrid.selModel.selected.items[0];
								record.set('Right', newValue);
							}, 50);
						}
					}
				},
				renderer: function (value) {
					switch (value) {
						case 'R':
							return lang_mss_share[150];
						case 'RW':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			}
		],
		tbar: [
			{
				text: lang_mss_share[201],
				id: 'MSS_shareInfoPOSIXRightSet',
				iconCls: 'b-icon-add',
				handler: function () {
					MSS_shareInfoPOSIXRightWindow.animateTarget = Ext.getCmp('MSS_shareInfoPOSIXRightSet');
					MSS_shareInfoPOSIXRightWindow.show();
					MSS_shareInfoPOSIXRightWindow.center();

					var selectNode = MSS_shareInfoPOSIXGrid.getSelectionModel().getSelection();

					if (selectNode.length > 0)
					{
						if (selectNode[0].get('Type') == 'User')
						{
							Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('user');
						}
						else if (selectNode[0].get('Type') == 'Group')
						{
							Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('group');
						}
						else
						{
							Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('user');
						}
					}
					else
					{
						Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('user');
					}

					//MSS_shareInfoPOSIXRightOwnerStore.load();
					var shareCreateName = Ext.getCmp('MSS_shareInfoName').getValue();
					loadPOSIXAccount(shareCreateName);
				}
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
			markDirty: false
		}
	}
);

/** 설정된 디렉터리 권한 :: ACL **/
// 설정된 디렉터리 권한 :: ACL - 모델
Ext.define(
	'MSS_shareInfoACLModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Type', 'ID', 'Desc', 'Location',
			{ name: 'Right', defaultValue: 'R' }
		]
	}
);

// 설정된 디렉터리 권한 :: ACL - 스토어
var MSS_shareInfoACLStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareInfoACLModel',
		proxy: {
			type: 'ajax',
			url: '/api/explorer/getfacl',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				store.removeAll();

				// 공유 경로
				var path,
					selmodel = MSS_shareInfoDirectoryGrid.getSelectionModel();

				if (selmodel.getCount() > 0)
				{
					// 디렉토리 목록이 선택 되었을경우
					path = selmodel.getSelection()[0].get('FullPath');
				}
				else
				{
					// 디렉토리 목록이 선택되지 않았을 경우 - 생성
					selmodel = MSS_shareGrid.getSelectionModel()
					path     = Ext.getCmp('MSS_shareInfoVolume').getValue();
				}

				store.proxy.setExtraParam(
					'argument',
					{
						Type: 'ACL',
						Path: path
					},
				);
			},
			load: function (store, records, success) {
				if (success === true)
					return;

				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mss_share[0] + '",'
					+ '"content": "' + lang_mss_share[192] + '",'
					+ '"response": ' + jsonText
				+ '}';

				return exceptionDataCheck(checkValue);
			}
		}
	}
);

// 성정된 디렉터리 권한 :: ACL - 그리드
var MSS_shareInfoACLGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareInfoACLGrid',
		store: MSS_shareInfoACLStore,
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1
			})
		],
		frame: false,
		columns: [
			{
				flex: 1,
				dataIndex: 'Type',
				text: lang_mss_share[198],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'ID',
				text: 'ID',
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Desc',
				text: lang_mss_share[199],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Right',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				// 변경 셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: { marginTop: '2px',marginBottom: '2px' },
					editable: false,
					dirty: true,
					store: new Ext.data.SimpleStore({
						fields: ['view', 'code'],
						data: [
							[lang_mss_share[150], 'R'],
							[lang_mss_share[152], 'RW'],
							[lang_mss_share[193], 'None']
						]
					}),
					value: 'R',
					valueField: 'code',
					displayField: 'view',
					width: 60,
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareInfoACLGrid.selModel.selected.items[0];
								record.set('Right', newValue);
							}, 50);
						}
					}
				},
				renderer: function (value) {
					switch (value) {
						case 'R':
							return lang_mss_share[150];
						case 'RW':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () {
					if (MSS_shareInfoACLGrid.getSelectionModel().getCount() > 0)
					{
						Ext.getCmp('MSS_shareInfoACLRightDelete').setDisabled(false);
					}
					else
					{
						Ext.getCmp('MSS_shareInfoACLRightDelete').setDisabled(true);
					}
				}, 200);
			}
		},
		tbar: [
			{
				text: lang_mss_share[201],
				id: 'MSS_shareInfoACLRightSet',
				iconCls: 'b-icon-add',
				handler: function () {
					MSS_shareInfoACLRightWindow.animateTarget = Ext.getCmp('MSS_shareInfoACLRightSet');
					MSS_shareInfoACLRightWindow.show();
					MSS_shareInfoACLRightWindow.center();

					var selection = MSS_shareInfoACLGrid.getSelectionModel().getSelection();

					if (selection.length > 0)
					{
						if (selection[0].get('Type') == 'User')
						{
							Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('user');
						}
						else if (selection[0].get('Type') == 'Group')
						{
							Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('group');
						}
						else
						{
							Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('user');
						}
					}
					else
					{
						Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('user');
					}

					MSS_shareInfoACLRightOwnerStore.load();
				}
			},
			{
				text: lang_mss_share[202],
				id: 'MSS_shareInfoACLRightDelete',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					var selection = MSS_shareInfoACLGrid.getSelectionModel().getSelection();

					MSS_shareInfoACLStore.remove(selection);

					Ext.getCmp('MSS_shareInfoACLRightDelete').setDisabled(true);
				}
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

/*
 * 공유 디렉토리 생성
 */
// 공유 디렉토리 생성 폼
var MSS_shareInfoDirectoryAddForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSS_shareInfoDirectoryAddForm',
		frame: false,
		jsonSubmit: true,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				border: false,
				style: { marginBottom: '30px' },
				html: lang_mss_share[203]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				id: 'MSS_shareInfoDirectoryAddFormVolumePanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mss_share[224]+' : ',
						width: 130,
						disabledCls: 'm-label-disable-mask'
					},
					{
						xtype: 'label',
						id: 'MSS_shareInfoDirectoryAddFormVolumePath',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'textfield',
				fieldLabel: lang_mss_share[205],
				id: 'MSS_shareInfoDirectoryAddFormPath',
				name: 'shareInfoDirectoryAddFormPath',
				allowBlank: false,
				vtype: 'reg_shareInfoPath',
				style: { marginBottom: '20px' }
			}
		]
	}
);

// 공유 디렉토리 생성 Window
var MSS_shareInfoDirectoryAddWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareInfoDirectoryAddWindow',
		title: '공유 디렉토리 생성',
		layout: 'fit',
		maximizable: false,
		autoHeight: true,
		width: 500,
		height: 250,
		items: [MSS_shareInfoDirectoryAddForm],
		buttons: [
			{
				xtype: 'button',
				text: lang_mss_share[206],
				handler: function () {
					if (!Ext.getCmp('MSS_shareInfoDirectoryAddForm').getForm().isValid())
						return false;

					waitWindow(lang_mss_share[0], lang_mss_share[207]);

					var volume = Ext.getElementById('MSS_shareInfoDirectoryAddFormVolumePath').innerHTML;
					var dir    = Ext.getCmp('MSS_shareInfoDirectoryAddFormPath').getValue();

					// 공유 경로
					var path = volume + '/' + dir;

					Ext.getCmp('MSS_shareInfoDirectoryAddForm').getForm().submit({
						method: 'POST',
						url: '/api/explorer/makedir',
						params: {
							argument: {
								dirpath: path,
								recursive: 1
							}
						},
						success: function (form, action) {
							// 데이터 전송 완료 후 wait 제거
							if (waitMsgBox)
							{
								waitMsgBox.hide();
								waitMsgBox = null;
							}

							// 메세지 출력
							var returnMsg;

							if (action.result.msg != ''
								&& action.result.msg == 'directoryExist')
							{
								returnMsg = lang_mss_share[225];
							}
							else
							{
								returnMsg = lang_mss_share[208];
							}
							
							Ext.Msg.alert(lang_mss_share[0], returnMsg);

							// 디렉토리 목록 갱신
							MSS_shareInfoDirectoryStore.proxy.extraParams = {
								argument: {
									type: ['dir'],
									dirpath: Ext.getCmp('MSS_shareInfoVolume').getValue()
								}
							};

							MSS_shareInfoDirectoryStore.load({
								callback: function (records, operation, success) {
									// 데이터 전송 완료 후 wait 제거
									if (waitMsgBox)
									{
										waitMsgBox.hide();
										waitMsgBox = null;
									}

									// 예외 처리에 따른 동작
									if (success !== true)
									{
										if (response.responseText == ''
												|| typeof(response.responseText) == 'undefined')
											response.responseText = '{}';

										var checkValue = '{'
											+ '"title": "' + lang_mss_share[0] + '",'
											+ '"content": "' + lang_mss_share[209] + '",'
											+ '"response": ' + response.responseText
										+ '}';

										return exceptionDataCheck(checkValue);
									}

									// 볼륨 경로
									var volume = Ext.getCmp('MSS_shareInfoVolume').getValue();

									// 입력한 하위 경로
									var dir = Ext.getCmp('MSS_shareInfoDirectoryAddFormPath').getValue();

									/*
									* 입력한 경로를 바로 선택하기 위한 루틴
									*/
									// 상위 경로
									var path = volume + '/' + (dir.split('/'))[0];

									Ext.each(
										MSS_shareInfoDirectoryStore.getRootNode().childNodes,
										function (node) {
											if (node.get('id') == path)
											{
												MSS_shareInfoDirectoryGrid.expandNode(node, true);
											}
										}
									);
								}
							});

							// 팝업 창 닫기
							MSS_shareInfoDirectoryAddWindow.hide();
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
								+ '"title": "' + lang_mss_share[0] + '",'
								+ '"content": "' + lang_mss_share[209] + '",'
								+ '"response": ' + jsonText
							+ '}';

							return exceptionDataCheck(checkValue);
						}
					});
				}
			}
		]
	}
);

/** 공유 디렉토리 선택 - 생성 **/
// 공유 정보 설정 - 디렉토리 선택 모델
Ext.define(
	'MSS_shareInfoDirectoryModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'id', 'Name', 'FullPath', 'Owner',
			'OwnerGroup', 'Permission', 'PermissionRWX'
		]
	}
);

// 공유 정보 설정 - 디렉토리 선택 스토어
var MSS_shareInfoDirectoryStore = Ext.create(
	'Ext.data.TreeStore',
	{
		model: 'MSS_shareInfoDirectoryModel',
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		autoLoad: false,
		root: {
			expanded: true
		},
		proxy: {
			type: 'ajax',
			url: '/api/explorer/list',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'FullPath',
			},
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				if (operation.node.get('Name'))
				{
					store.proxy.extraParams.argument.dirpath
						= operation.node.get('FullPath');
				}

				// 트리 루트면 건너뛰기
				if (operation.id == 'root')
					return;

				// 입력한 하위 경로
				var dir = Ext.getCmp('MSS_shareInfoDirectoryAddFormPath').getValue();

				// 입력이 없으면 건너뛰기
				if (dir == '')
					return;

				// 생성한 디렉토리의 전체 경로
				var volume        = Ext.getCmp('MSS_shareInfoVolume').getValue();
				var created_path  = volume + '/' + dir;
				var created_paths = created_path.split('/');

				// 선택된 디렉터리와 생성을 통해 로딩될 디렉터리의 일치 검사
				var selected = '';
				var id_array = operation.id.split('/');

				if (created_paths.length < id_array.length)
					return false;

				for (var i=0; i<id_array.length; i++)
				{
					if (created_paths[i] != '')
					{
						selected = selected + '/' + created_paths[i];
					}
				}

				if (selected != operation.id)
				{
					MSS_shareInfoDirectoryStore.loading = false;
					return false;
				}
			},
			load: function (store, node, records, success, eOpts) {
				// 입력한 하위 경로
				var dir = Ext.getCmp('MSS_shareInfoDirectoryAddFormPath').getValue();

				// 입력이 없으면 건너뛰기
				if (dir == '')
					return;

				// 생성한 디렉토리의 전체 경로
				var volume        = Ext.getCmp('MSS_shareInfoVolume').getValue();
				var created_path  = volume + '/' + dir;
				var created_paths = created_path.split('/');

				// 선택된 디렉터리와 일치하지 않으면 건너뛰기
				if (node.get('id') != created_path)
					return;

				var grid = Ext.getCmp('MSS_shareInfoDirectoryGrid');

				grid.getSelectionModel().select(store.getNodeById(created_path));

				// 공유 경로 선택 시 POSIX/ACL 권한 로드
				MSS_shareInfoPOSIXStore.load();
				MSS_shareInfoACLStore.load();

				Ext.getCmp('MSS_shareInfoDirectoryAddFormPath').setValue('');
			},
		}
	}
);

// 공유 정보 설정 - 디렉토리 선택 그리드
var MSS_shareInfoDirectoryGrid = Ext.create(
	'Ext.tree.Panel',
	{
		id: 'MSS_shareInfoDirectoryGrid',
		width: 500,
		height: 350,
		useArrows: true,
		rootVisible: false,
		multiSelect: false,
		frame: true,
		allowDeselect: true,
		store: MSS_shareInfoDirectoryStore,
		columnLines: true,
		rowLines: true,
		viewConfig: {
			loadMask: true,
		},
		header: {
			titlePosition: 0,
			items:[
				{
					xtype:'panel',
					id: 'MSS_shareInfoDirectoryGridHeader',
					style: 'text-align: left; padding-right:20px;',
					bodyCls: 'm-custom-transparent-left',
					border: false,
					width: 350,
					height: 16,
					html: lang_mss_share[187]
				},
				{
					xtype: 'button',
					width: 130,
					id: 'MSS_shareInfoDirectoryAdd',
					text: lang_mss_share[210],
					handler: function () {
						Ext.getCmp('MSS_shareInfoDirectoryAddForm').getForm().reset();

						// 디렉토리 경로 선택되어 있을 경우 - 경로 입력
						var selmodel = MSS_shareInfoDirectoryGrid.getSelectionModel();

						if (selmodel.getCount() == 1)
						{
							var selected = selmodel.getSelection()[0];
							var replacer = Ext.getCmp('MSS_shareInfoVolume').getValue() + "/";
							var replaced = selected.get('FullPath').replace(replacer, "");

							Ext.getCmp('MSS_shareInfoDirectoryAddFormPath').setValue(replaced);
						}

						MSS_shareInfoDirectoryAddWindow.show();
						MSS_shareInfoDirectoryAddWindow.center();

						Ext.getCmp('MSS_shareInfoDirectoryAddFormVolumePath')
							.update(Ext.getCmp('MSS_shareInfoVolume').getValue());
					}
				}
			]
		},
		selModel: Ext.create('Ext.selection.CheckboxModel', {
			mode: 'SINGLE',
			checkOnly: 'true',
			allowDeselect: true
		}),
		columns: [
			{
				xtype: 'treecolumn',
				text: lang_mss_share[90],
				dataIndex: 'Name',
				flex: 1,
				sortable: true,
				menuDisabled: true
			},
			{
				dataIndex: 'Owner',
				hidden: true
			},
			{
				dataIndex: 'OwnerGroup',
				hidden: true
			},
			{
				dataIndex: 'Permission',
				hidden: true
			},
			{
				dataIndex: 'FullPath',
				hidden: true
			},
			{
				dataIndex: 'PermissionRWX',
				hidden: true
			},
			{
				dataIndex: 'id',
				hidden: true
			}
		],
		listeners: {
			cellclick: function (gridView, htmlElement, columnIndex, dataRecord) {
				if (columnIndex != 0)
					return;

				Ext.defer(function () {
					// 공유 경로 선택 시 POSIX/ACL 권한 로드
					MSS_shareInfoPOSIXStore.load();
					MSS_shareInfoACLStore.load();
				}, 200);
			}
		}
	}
);

/** 공유 생성 step3 :: 경로, 권한 **/
var MSS_shareInfoStep3Panel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSS_shareInfoStep3Panel',
		layout: {
			type: 'hbox',
			pack: 'start',
			align: 'stretch'
		},
		bodyStyle: { padding: 0 },
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
						html: '<span class="m-wizard-side-link">' + lang_mss_share[154] + '</span>',
						listeners: {
							afterrender: function () {
								this.el.on('click', function () {
									MSS_shareInfoWin.layout.setActiveItem(0);
									// 버튼 컨트롤
									MSS_shareInfoBtn();
								});
							}
						}
					},
					{
						xtype: 'label',
						style: 'fontWeight: bold; marginBottom: 20px;',
						text: lang_mss_share[156]
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				flex: 1,
				items: [
					{
						xtype: 'BaseWizardTitlePanel',
						html: lang_mss_share[167]
					},
					{
						xtype: 'BasePanel',
						bodyStyle: { padding: 0 },
						style: { marginLeft: '40px', marginTop: '20px' },
						html: lang_mss_share[168]
					},
					{
						xtype: 'BasePanel',
						layout: 'column',
						bodyStyle: { padding: 0 },
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								style: {
									marginLeft: '20px',
									marginRight: '20px',
									marginTop: '20px'
								},
								items: [
									{
										xtype: 'BasePanel',
										id: 'MSS_shareInfoDirectoryPanel',
										name: 'shareInfoDirectoryPanel',
										bodyStyle: { padding: 0 },
										items: [MSS_shareInfoDirectoryGrid]
									}
								]
							},
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								id: 'MSS_shareInfoOwnerPanel',
								style: { marginTop: '20px' },
								items: [
									{
										xtype: 'tabpanel',
										id: 'MSS_shareInfoDirectoryOwnerInfo',
										activeTab: 0,
										bodyBorder: false,
										border: false,
										frame: true,
										width: 580,
										height: 350,
										items:[
											{
												xtype: 'BasePanel',
												id: 'MSS_shareInfoPOSIXPanel',
												title: 'POSIX',
												bodyStyle: { padding: 0 },
												layout: 'fit',
												items: [MSS_shareInfoPOSIXGrid]
											},
											{
												xtype: 'BasePanel',
												id: 'MSS_shareInfoACLPanel',
												title: 'ACL',
												bodyStyle: { padding: 0 },
												layout: 'fit',
												items: [MSS_shareInfoACLGrid]
											}
										]
									}
								]
							}
						]
					}
				]
			}
		]
	}
);

/** 공유 생성 WINDOW **/
var MSS_shareInfoWin = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareInfoWin',
		layout: 'card',
		title: lang_mss_share[182],
		maximizable: false,
		autoHeight: true,
		width: 600,
		height: 600,
		activeItem: 0,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'fit',
				id: 'MSS_shareInfoStep1',
				items: [MSS_shareInfoStep1Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'fit',
				id: 'MSS_shareInfoStep2',
				items: [MSS_shareInfoStep2Panel]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'fit',
				id: 'MSS_shareInfoStep3',
				items: [MSS_shareInfoStep3Panel]
			}
		],
		fbar: [
			{
				text: lang_mss_share[183],
				id: 'MSS_shareInfoCancelBtn',
				width: 70,
				disabled: false,
				border: true,
				handler:function () {
					MSS_shareInfoWin.close();
				}
			},
			'->',
			{
				text: lang_mss_share[184],
				id: 'MSS_shareInfoPreviousBtn',
				width: 70,
				disabled: false,
				handler: function () {
					var currentStepPanel = MSS_shareInfoWin.layout.activeItem;
					var currentStepIndex = MSS_shareInfoWin.items.indexOf(currentStepPanel);

					MSS_shareInfoWin.layout.setActiveItem(--currentStepIndex);

					// 버튼 컨트롤
					MSS_shareInfoBtn();
				}
			},
			{
				text: lang_mss_share[185],
				id: 'MSS_shareInfoNextBtn',
				width: 70,
				disabled: false,
				handler: function () {
					var currentStepPanel = MSS_shareInfoWin.layout.activeItem;
					var currentStepIndex = MSS_shareInfoWin.items.indexOf(currentStepPanel);

					MSS_shareInfoWin.layout.setActiveItem(++currentStepIndex);

					MSS_shareInfoBtn();
				}
			},
			{
				text: lang_mss_share[186],
				id: 'MSS_shareInfoOKBtn',
				width: 70,
				disabled: false,
				handler: function ()
				{
					var name     = Ext.getCmp('MSS_shareInfoName').getValue();
					var desc     = Ext.getCmp('MSS_shareInfoDesc').getValue();
					var pool     = Ext.getCmp('MSS_shareInfoPool').getValue();
					var volume   = Ext.getCmp('MSS_shareInfoVolume').getRawValue();
					var selected = MSS_shareInfoDirectoryGrid.getSelectionModel().getSelection()[0];
					var path     = selected
						         ? selected.get('FullPath').replace(getVolumePath(volume), '')
						         : '/';

					waitWindow(lang_mss_share[0], lang_mss_share[98]);

					requestShareCreate({
						name: name,
						desc: desc,
						pool: pool,
						volume: volume,
						path: path,
					})
					.success(function (response)
					{
						var promise = updateFilingProtocols({
							name: name,
							volume: getVolume(volume),
							SMB: Ext.getCmp('MSS_shareInfoSMB'),
							NFS: Ext.getCmp('MSS_shareInfoNFS'),
						});

						promise.success(
							function (response)
							{
								setPermForShare({
									path: path,
									perm: {
										POSIX: get_posix_perms(),
										ACL: get_acl_perms(),
									}
								})
								.finally(
									function ()
									{
										// 생성창 닫기
										MSS_shareInfoWin.hide();

										Ext.Msg.alert(lang_mss_share[0], lang_mss_share[100]);
									}
								);
							}
						);

						if (!Ext.getCmp('MSS_shareInfoSMB').getValue()
							&& !Ext.getCmp('MSS_shareInfoNFS').getValue())
						{
							promise.resolve();
						}
					});
				}
			}
		],
		listeners: {
			show: function (win, eOpts) {
				win.center();
			},
			hide: function (win, eOpts) {
				MSS_shareLoad();
			}
		}
	}
);

function requestShareCreate(params)
{
	// TODO: parameter validation
	params = params || {};

	return GMS.Ajax.request({
		url: '/api/cluster/share/create',
		waitMsgBox: null,
		jsonData: {
			// 공유 이름
			Name: params.name,
			// 공유 설명
			Desc: params.desc,
			// 볼륨 풀 이름
			Pool: params.pool,
			// 볼륨 이름
			Volume: params.volume,
			// 경로
			Path: params.path.replace(/\/+/, '/'),
		},
		callback: function (options, success, response, decoded) {
			if (success)
				options.deferred.promise().resolve(response);
			else
				options.deferred.promise().reject(response);
		}
	});
}

/** 공유 수정 */
// 공유 디렉토리 생성 - 공유 수정 시

// 공유 디렉토리 생성 폼 - 공유 수정 시
var MSS_shareInfoModifyDirectoryAddForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MSS_shareInfoModifyDirectoryAddForm',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				border: false,
				style: { marginBottom: '30px' },
				html: lang_mss_share[203]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: { padding: 0 },
				layout: 'hbox',
				id: 'MSS_shareInfoModifyDirectoryAddFormVolumePanel',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mss_share[224] + ': ',
						width: 130,
						disabledCls: 'm-label-disable-mask',
						style: { marginRight: '10px' },
					},
					{
						xtype: 'label',
						id: 'MSS_shareInfoModifyDirectoryAddFormVolumePath',
						disabledCls: 'm-label-disable-mask'
					}
				]
			},
			{
				xtype: 'textfield',
				fieldLabel: lang_mss_share[205],
				id: 'MSS_shareInfoModifyDirectoryAddFormPath',
				name: 'shareInfoModifyDirectoryAddFormPath',
				allowBlank: false,
				vtype: 'reg_shareInfoPath',
				style: { marginBottom: '20px' }
			}
		]
	}
);

// 공유 디렉토리 생성 Window - 공유 수정 시
var MSS_shareInfoModifyDirectoryAddWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareInfoModifyDirectoryAddWindow',
		title: lang_mss_share[210],
		layout: 'fit',
		maximizable: false,
		autoHeight: true,
		width: 500,
		height: 250,
		items: [MSS_shareInfoModifyDirectoryAddForm],
		buttons: [
			{
				xtype: 'button',
				text: lang_mss_share[206],
				handler: function () {
					if (!Ext.getCmp('MSS_shareInfoModifyDirectoryAddForm').getForm().isValid())
						return false;

					waitWindow(lang_mss_share[0], lang_mss_share[207]);

					var share_selmodel = MSS_shareGrid.getSelectionModel();
					var share_path     = getSharePath(share_selmodel);
					var dir            = Ext.getCmp('MSS_shareInfoModifyDirectoryAddFormPath').getValue();
					var dir_path       = share_path + '/' + dir;

					Ext.getCmp('MSS_shareInfoModifyDirectoryAddForm').getForm().submit({
						method: 'POST',
						url: '/api/explorer/makedir',
						jsonSubmit: true,
						params: {
							argument: {
								dirpath: dir_path,
								recursive: 1
							}
						},
						success: function (form, action) {
							// 데이터 전송 완료 후 wait 제거
							if (waitMsgBox)
							{
								waitMsgBox.hide();
								waitMsgBox = null;
							}

							// 메세지 출력
							var msg;

							if (action.result.msg != ''
								&& action.result.msg == 'directoryExist')
							{
								msg = lang_mss_share[225];
							}
							else
							{
								msg = lang_mss_share[208];
							}

							Ext.Msg.alert(lang_mss_share[0], msg);

							// 디렉토리 목록 갱신
							MSS_shareInfoModifyDirectoryStore.proxy.extraParams = {
								argument: {
									type: ['dir'],
									dirpath: share_path,
								}
							};

							MSS_shareInfoModifyDirectoryStore.load({
								callback: function (records, operation, success) {
									// 데이터 전송 완료 후 wait 제거
									if (waitMsgBox)
									{
										waitMsgBox.hide();
										waitMsgBox = null;
									}

									// 예외 처리에 따른 동작
									if (success !== true)
									{
										if (response.responseText == ''
												|| typeof(response.responseText) == 'undefined')
											response.responseText = '{}';

										var checkValue = '{'
											+ '"title": "' + lang_mss_share[0] + '",'
											+ '"content": "' + lang_mss_share[209] + '",'
											+ '"response": ' + response.responseText
										+ '}';

										return exceptionDataCheck(checkValue);
									}

									// 입력한 하위 경로
									var path = share_path + '/' + (dir.split('/'))[0];

									Ext.each(
										MSS_shareInfoModifyDirectoryStore.getRootNode().childNodes,
										function (node) {
											if (node.get('id') == path)
											{
												MSS_shareInfoModifyDirectoryGrid.expandNode(node, true);
											}
										}
									);
								}
							});

							// 팝업창 닫기
							MSS_shareInfoModifyDirectoryAddWindow.hide();
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
								+ '"title": "' + lang_mss_share[0] + '",'
								+ '"content": "' + lang_mss_share[209] + '",'
								+ '"response": ' + jsonText
							+ '}';

							return exceptionDataCheck(checkValue);
						}
					});
				}
			}
		]
	}
);

/** 공유 수정 디렉토리 선택 - 수정 **/
// 공유 수정 디렉토리 모델
// 공유 수정 디렉토리 스토어
var MSS_shareInfoModifyDirectoryStore = Ext.create(
	'Ext.data.TreeStore',
	{
		model: 'MSS_shareInfoDirectoryModel',
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		autoLoad: false,
		root: {
			expanded: true
		},
		proxy: {
			type: 'ajax',
			url: '/api/explorer/list',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'FullPath',
			},
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				if (operation.node.get('Name'))
				{
					store.proxy.extraParams.argument.dirpath
						= operation.node.get('FullPath');
				}

				// 트리 루트면 건너뛰기
				if (operation.id == 'root')
					return;

				var dir = Ext.getCmp('MSS_shareInfoModifyDirectoryAddFormPath').getValue();

				// 입력이 없으면 건너뛰기
				if (dir == '')
					return;

				var share_selmodel = MSS_shareGrid.getSelectionModel();
				var share_path     = getSharePath(share_selmodel);

				var created_path  = share_path + '/' + dir;
				var created_paths = created_path.split('/');

				// 선택된 디렉터리와 생성을 통해 로딩될 디렉터리의 일치 검사
				var selected = '';
				var id_array = operation.id.split('/');

				if (created_paths.length < id_array.length)
					return false;

				for (var i=0; i<id_array.length; i++)
				{
					if (created_paths[i] != '')
					{
						selected = selected + '/' + created_paths[i];
					}
				}

				if (selected != operation.id)
				{
					MSS_shareInfoModifyDirectoryStore.loading = false;
					return false;
				}
			},
			load: function (store, node, records, success, eOpts) {
				var dir = Ext.getCmp('MSS_shareInfoModifyDirectoryAddFormPath').getValue();

				// 입력이 없으면 건너뛰기
				if (dir == '')
					return;

				// 생성한 디렉토리의 전체 경로
				var share_path    = getSharePath(MSS_shareGrid.getSelectionModel());
				var created_path  = share_path + '/' + dir;
				var created_paths = created_path.split('/');

				// 선택된 디렉터리와 일치하지 않으면 건너뛰기
				if (node.get('id') != created_path)
					return;

				var grid = Ext.getCmp('MSS_shareInfoModifyDirectoryGrid');

				grid.getSelectionModel().select(store.getNodeById(created_path));

				// 공유 경로 선택 시 POSIX/ACL 권한 로드
				MSS_shareInfoModifyPOSIXStore.load();
				MSS_shareInfoModifyACLStore.load();

				Ext.getCmp('MSS_shareInfoModifyDirectoryAddFormPath').setValue('');
			},
		}
	}
);

// 공유 수정 디렉토리 그리드
var MSS_shareInfoModifyDirectoryGrid = Ext.create(
	'Ext.tree.Panel',
	{
		id: 'MSS_shareInfoModifyDirectoryGrid',
		width: 500,
		height: 350,
		useArrows: true,
		rootVisible: false,
		multiSelect: false,
		frame: true,
		allowDeselect: true,
		store: MSS_shareInfoModifyDirectoryStore,
		loadMask: true,
		columnLines: true,
		rowLines: true,
		header: {
			titlePosition: 0,
			items: [
				{
					xtype:'panel',
					id: 'MSS_shareInfoModifyDirectoryGridHeader',
					style: 'text-align: left; padding-right:20px;',
					bodyCls: 'm-custom-transparent-left',
					border: false,
					width: 330,
					height: 16,
					html: lang_mss_share[187]
				},
				{
					xtype: 'button',
					width: 130,
					id: 'MSS_shareInfoModifyDirectoryAdd',
					text: lang_mss_share[210],
					handler: function () {
						Ext.getCmp('MSS_shareInfoModifyDirectoryAddForm').getForm().reset();

						var share_selmodel = MSS_shareGrid.getSelectionModel(),
							dir_selmodel   = MSS_shareInfoModifyDirectoryGrid.getSelectionModel();

						var share_path = getSharePath(share_selmodel),
							dir_path   = null;

						// 디렉토리 경로 선택되어 있을 경우 - 경로 입력
						if (dir_selmodel.getCount() == 1)
						{
							dir_path = dir_selmodel.getSelection()[0].get('FullPath')
										.replace(share_path + '/', '');
						}

						Ext.getCmp('MSS_shareInfoModifyDirectoryAddFormVolumePath').update(share_path);
						Ext.getCmp('MSS_shareInfoModifyDirectoryAddFormPath').setValue(dir_path);

						MSS_shareInfoModifyDirectoryAddWindow.show();
						MSS_shareInfoModifyDirectoryAddWindow.center();
					}
				}
			]
		},
		selModel: Ext.create('Ext.selection.CheckboxModel', {
			mode: 'SINGLE',
			checkOnly: 'true',
			allowDeselect: true
		}),
		columns: [
			{
				xtype: 'treecolumn',
				text: lang_mss_share[90],
				dataIndex: 'Name',
				flex: 1,
				sortable: true,
				menuDisabled: true
			},
			{
				dataIndex: 'Owner',
				hidden: true
			},
			{
				dataIndex: 'OwnerGroup',
				hidden: true
			},
			{
				dataIndex: 'Permission',
				hidden: true
			},
			{
				dataIndex: 'FullPath',
				hidden: true
			},
			{
				dataIndex: 'PermissionRWX',
				hidden: true
			},
			{
				dataIndex: 'id',
				hidden: true
			}
		],
		viewConfig: {
			loadMask: true
		},
		listeners: {
			cellclick: function (gridView, htmlElement, columnIndex, dataRecord) {
				if (columnIndex != 0)
					return;

				Ext.defer(function () {
					// 공유 경로 선택 시 POSIX/ACL 권한 로드
					MSS_shareInfoModifyPOSIXStore.load();
					MSS_shareInfoModifyACLStore.load();
				}, 200);
			}
		}
	}
);

/*
 * 디렉터리 권한 수정 : POSIX
 */

// 디렉터리 권한 수정 :: POSIX - 모델
Ext.define(
	'MSS_shareInfoModifyPOSIXModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Type', 'ID', 'Desc', 'Location',
			{ name: 'Right', defaultValue: 'R' }
		]
	}
);

// 디렉터리 권한 수정 :: POSIX - 스토어
var MSS_shareInfoModifyPOSIXStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareInfoModifyPOSIXModel',
		proxy: {
			type: 'ajax',
			url: '/api/explorer/getfacl',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				store.removeAll();

				// 공유 경로
				var share_selmodel = MSS_shareGrid.getSelectionModel(),
					dir_selmodel   = MSS_shareInfoModifyDirectoryGrid.getSelectionModel();

				var share_path = getSharePath(share_selmodel);
				var dir_path   = getSelectedPath(share_selmodel, dir_selmodel);
				var path       = share_path + '/' + dir_path;

				store.proxy.setExtraParam(
					'argument',
					{
						Type: 'POSIX',
						Path: path.replace(/\/+/, '/'),
					},
				);
			}
		}
	}
);

// 공유 수정 권한 :: POSIX - 그리드
var MSS_shareInfoModifyPOSIXGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareInfoModifyPOSIXGrid',
		store: MSS_shareInfoModifyPOSIXStore,
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1
			})
		],
		frame: false,
		columns: [
			{
				flex: 1,
				dataIndex: 'Type',
				text: lang_mss_share[198],
				sortable: false,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'ID',
				text: 'ID',
				sortable: false,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Desc',
				text: lang_mss_share[199],
				sortable: false,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Right',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				// 변경 셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: { marginTop: '2px', marginBottom: '2px' },
					editable: false,
					dirty: true,
					store: new Ext.data.SimpleStore({
						fields: ['view', 'code'],
						data: [
							[lang_mss_share[150], 'R'],
							[lang_mss_share[152], 'RW'],
							[lang_mss_share[193], 'None']
						]
					}),
					value: 'R',
					valueField: 'code',
					displayField: 'view',
					width: 60,
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareInfoModifyPOSIXGrid.selModel.selected.items[0];
								record.set('Right', newValue);
							}, 50);
						}
					}
				},
				renderer: function (value) {
					switch (value) {
						case 'R':
							return lang_mss_share[150];
						case 'RW':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			}
		],
		tbar: [
			{
				text: lang_mss_share[201],
				id: 'MSS_shareInfoModifyPOSIXRightSet',
				iconCls: 'b-icon-add',
				handler: function () {
					MSS_shareInfoPOSIXRightWindow.animateTarget
						= Ext.getCmp('MSS_shareInfoModifyPOSIXRightSet');

					MSS_shareInfoPOSIXRightWindow.show();
					MSS_shareInfoPOSIXRightWindow.center();

					var selectNode = MSS_shareInfoModifyPOSIXGrid.getSelectionModel().getSelection();

					if (selectNode.length > 0)
					{
						if (selectNode[0].get('Type') == 'User')
						{
							Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('user');
						}
						else if (selectNode[0].get('Type') == 'Group')
						{
							Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('group');
						}
						else
						{
							Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('user');
						}
					}
					else
					{
						Ext.getCmp('MSS_shareInfoPOSIXOwnerType').setValue('user');
					}

					//MSS_shareInfoPOSIXRightOwnerStore.load();
					var shareModifyName = Ext.getCmp('MSS_shareInfoModifyName').getValue();
					loadPOSIXAccount(shareModifyName);
				}
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
			markDirty: false
		}
	}
);

/** 디렉터리 권한 :: ACL **/
// 디렉터리 권한 :: ACL - 모델
Ext.define(
	'MSS_shareInfoModifyACLModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Type', 'ID', 'Desc', 'Location',
			{ name: 'Right', defaultValue: 'R' }
		]
	}
);

// 디렉터리 권한 :: ACL - 스토어
var MSS_shareInfoModifyACLStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareInfoModifyACLModel',
		proxy: {
			type: 'ajax',
			url: '/api/explorer/getfacl',
			paramsAsJson: true,
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				// 로드 전 기존 데이터 제거
				store.removeAll();

				// 공유 경로
				var share_selmodel = MSS_shareGrid.getSelectionModel(),
					dir_selmodel   = MSS_shareInfoModifyDirectoryGrid.getSelectionModel();

				var share_path = getSharePath(share_selmodel);
				var dir_path   = getSelectedPath(share_selmodel, dir_selmodel);
				var path       = share_path + dir_path;

				store.proxy.setExtraParam(
					'argument',
					{
						Type: 'ACL',
						Path: path.replace(/\/+/, '/'),
					},
				);
			}
		}
	}
);

// 공유 수정 권한 :: ACL - 그리드
var MSS_shareInfoModifyACLGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareInfoModifyACLGrid',
		store: MSS_shareInfoModifyACLStore,
		plugins: [
			Ext.create('Ext.grid.plugin.CellEditing', {
				clicksToEdit: 1,
				clicksToMoveEditor: 1
			})
		],
		frame: false,
		columns: [
			{
				flex: 1,
				dataIndex: 'Type',
				text: lang_mss_share[198],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'ID',
				text: 'ID',
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Desc',
				text: lang_mss_share[199],
				sortable: true,
				menuDisabled: true
			},
			{
				flex: 1,
				dataIndex: 'Right',
				text: lang_mss_share[18],
				sortable: false,
				menuDisabled: true,
				// 변경 셀 색상 변경
				tdCls: 'm-custom-cell-modify',
				editor: {
					xtype: 'BaseComboBox',
					// combo 위치 설정
					style: { marginTop: '2px',marginBottom: '2px' },
					editable: false,
					dirty: true,
					store: new Ext.data.SimpleStore({
						fields: ['view', 'code'],
						data: [
							[lang_mss_share[150], 'R'],
							[lang_mss_share[152], 'RW'],
							[lang_mss_share[193], 'None']
						]
					}),
					value: 'R',
					valueField: 'code',
					displayField: 'view',
					width: 60,
					listeners: {
						change: function (field, newValue, oldValue) {
							Ext.defer(function () {
								var record = MSS_shareInfoModifyACLGrid.selModel.selected.items[0];
								record.set('Right', newValue);
							}, 50);
						}
					}
				},
				renderer: function (value) {
					switch (value) {
						case 'R':
							return lang_mss_share[150];
						case 'RW':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () {
					var delete_btn   = Ext.getCmp('MSS_shareInfoModifyACLRightDelete');
					var acl_selmodel = MSS_shareInfoModifyACLGrid.getSelectionModel();

					delete_btn.setDisabled(acl_selmodel.getcount() <= 0);
				}, 200);
			}
		},
		tbar: [
			{
				text: lang_mss_share[201],
				id: 'MSS_shareInfoModifyACLRightSet',
				iconCls: 'b-icon-add',
				handler: function () {
					MSS_shareInfoACLRightWindow.animateTarget
						= Ext.getCmp('MSS_shareInfoModifyACLRightSet');

					MSS_shareInfoACLRightWindow.show();
					MSS_shareInfoACLRightWindow.center();

					var selection = MSS_shareInfoModifyACLGrid.getSelectionModel().getSelection();

					if (selection.length > 0)
					{
						if (selection[0].get('Type') == 'User')
						{
							Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('user');
						}
						else if (selection[0].get('Type') == 'Group')
						{
							Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('group');
						}
						else
						{
							Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('user');
						}
					}
					else
					{
						Ext.getCmp('MSS_shareInfoACLOwnerType').setValue('user');
					}

					MSS_shareInfoACLRightOwnerStore.load();
				}
			},
			{
				text: lang_mss_share[202],
				id: 'MSS_shareInfoModifyACLRightDelete',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					var selection = MSS_shareInfoModifyACLGrid.getSelectionModel().getSelection();

					MSS_shareInfoModifyACLStore.remove(selection);

					Ext.getCmp('MSS_shareInfoModifyACLRightDelete').setDisabled(true);
				}
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

/** 공유 수정 FORM **/
var MSS_shareInfoModifyForm = Ext.create(
	'BasePanel',
	{
		id: 'MSS_shareInfoModifyForm',
		bodyStyle: { padding: 0 },
		frame: false,
		items: [
			{
				xtype: 'BaseFormPanel',
				id: 'MSS_shareInfoModifyFormPanel',
				layout: {
					type: 'hbox',
					pack: 'start',
					align: 'stretch'
				},
				bodyStyle: { padding: 0 },
				border: false,
				frame: false,
				items: [
					{
						xtype: 'fieldset',
						id: 'MSS_shareInfoModifyInfoForm',
						title: lang_mss_share[211],
						width: 700,
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								layout: 'hbox',
								maskOnDisable: false,
								defaults: {
									style: {
										marginTop: '20px',
										marginBottom: '20px',
										marginLeft: '20px',
										marginRight: '30px'
									}
								},
								items: [
									{
										xtype: 'textfield',
										fieldLabel: lang_mss_share[204],
										id: 'MSS_shareInfoModifyVolume',
										name: 'shareInfoModifyVolume',
										labelWidth: 100,
										width: 220,
										disabled: true
									},
									{
										xtype: 'textfield',
										fieldLabel: lang_mss_share[212],
										id: 'MSS_shareInfoModifyName',
										name: 'shareInfoModifyName',
										labelWidth: 100,
										width: 220,
										disabled: true
									}
								]
							},
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								layout: 'hbox',
								maskOnDisable: false,
								defaults: {
									style: {
										marginBottom: '20px',
										marginLeft: '20px',
										marginRight: '30px'
									}
								},
								items: [
									{
										xtype: 'textfield',
										fieldLabel: lang_mss_share[213],
										id: 'MSS_shareInfoModifyDesc',
										name: 'shareInfoModifyDesc',
										labelWidth: 100,
										width: 220
									},
									{
										xtype: 'checkboxgroup',
										fieldLabel: lang_mss_share[96],
										labelWidth: 100,
										width: 250,
										items: [
											{
												boxLabel: 'SMB',
												id: 'MSS_shareInfoModifySMB',
												name: 'shareInfoModifySMB',
											},
											{
												boxLabel: 'NFS',
												id: 'MSS_shareInfoModifyNFS',
												name: 'shareInfoModifyNFS',
											}
										]
									}
								]
							},
							{
								xtype: 'button',
								id: 'MSS_shareInfoModifyInfoSet',
								text: lang_mss_share[214],
								style: {
									marginLeft: '40px',
									marginTop: '10px',
									marginBottom: '15px'
								},
								handler: function () {
									if (!Ext.getCmp('MSS_shareInfoModifyDesc').isValid())
										return false;

									var share  = getShare(Ext.getCmp('MSS_shareInfoModifyName').getValue());
									var volume = getVolume(share.get('Volume'));
									var path   = getSelectedPath(
										MSS_shareGrid.getSelectionModel(),
										MSS_shareInfoModifyDirectoryGrid.getSelectionModel()
									);

									waitWindow(lang_mss_share[0], lang_mss_share[99]);

									GMS.Ajax.request({
										url: '/api/cluster/share/update',
										jsonData: {
											// 공유 이름
											Name: share.get('Name'),
											// 공유 경로
											Path: path,
											// 공유 설명
											Desc: Ext.getCmp('MSS_shareInfoModifyDesc').getValue(),
										},
										SMB: Ext.getCmp('MSS_shareInfoModifySMB'),
										NFS: Ext.getCmp('MSS_shareInfoModifyNFS'),
										Volume: volume,
										callback: function (options, success, response, decoded) {
											if (!success)
												return;

											var promise = updateFilingProtocols({
												name: options.jsonData.Name,
												volume: options.Volume,
												SMB: options.SMB,
												NFS: options.NFS,
											})
											.success(
												function (response) {
													Ext.Msg.alert(lang_mss_share[0], lang_mss_share[46]);
												}
											);

											if (!Ext.getCmp('MSS_shareInfoModifySMB').isDirty()
												&& !Ext.getCmp('MSS_shareInfoModifyNFS').isDirty())
											{
												promise.resolve();
											}

											Ext.getCmp('MSS_shareInfoModifyProtocolSMB').setDisabled(!options.SMB.checked);
											Ext.getCmp('MSS_shareInfoModifyProtocolNFS').setDisabled(!options.NFS.checked);

											Ext.getCmp('MSS_shareInfoModifySMB').originalValue
												= Ext.getCmp('MSS_shareInfoModifySMB').getValue();

											Ext.getCmp('MSS_shareInfoModifyNFS').originalValue
												= Ext.getCmp('MSS_shareInfoModifyNFS').getValue();
										}
									});
								}
							}
						]
					},
					{
						xtype: 'fieldset',
						id: 'MSS_shareInfoModifyProtocolSet',
						title: lang_mss_share[215],
						style: {marginLeft: '20px'},
						width: 325,
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								border: false,
								style: {
									marginTop: '30px',
									marginBottom: '10px',
									marginLeft: '10px'
								},
								html: lang_mss_share[216]
							},
							{
								xtype: 'button',
								id: 'MSS_shareInfoModifyProtocolSMB',
								text: lang_mss_share[217],
								style: { marginLeft: '40px', marginBottom: '0px', marginTop: '10px' },
								handler: function () {
									// 선택된 공유 정보 전달
									var record = MSS_shareGrid.getSelectionModel().getSelection()[0];

									// WINDOW OPEN시 동작
									MSS_shareSMBWin.animateTarget = Ext.getCmp('MSS_shareInfoModifyProtocolSMB');

									// SMB 수정 팝업
									MSS_shareSMBWinLoad(record.get('Name'));
								}
							},
							{
								xtype: 'button',
								id: 'MSS_shareInfoModifyProtocolNFS',
								text: lang_mss_share[218],
								style: {
									marginLeft: '40px',
									marginBottom: '0px',
									marginTop: '10px'
								},
								handler: function () {
									// 선택된 공유 정보 전달
									var record = MSS_shareGrid.getSelectionModel().getSelection()[0];

									// WINDOW OPEN시 동작
									MSS_shareNFSWin.animateTarget = Ext.getCmp('MSS_shareInfoModifyProtocolNFS');

									waitWindow(lang_mss_share[0], lang_mss_share[142]);

									// NFS 수정 팝업
									MSS_shareNFSWinLoad(record);
								}
							}
						]
					}
				]
			},
			{
				xtype: 'fieldset',
				id: 'MSS_shareInfoModifyRightForm',
				title: lang_mss_share[219],
				style: { marginTop: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: { padding: 0 },
						layout: 'column',
						items: [
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								style: {
									marginTop: '20px',
									marginLeft: '20px',
								},
								html: lang_mss_share[222]
							},
							{
								xtype: 'button',
								id: 'MSS_shareInfoModifyRightSet',
								text: lang_mss_share[220],
								style: { marginTop: '20px', marginLeft: '20px' },
								handler: function () {
									// 공유 경로
									var path = getSelectedFullPath(
										MSS_shareGrid.getSelectionModel(),
										MSS_shareInfoModifyDirectoryGrid.getSelectionModel()
									);

									waitWindow(lang_mss_share[0], lang_mss_share[223]);

									var posix = get_dir_perms('POSIX');

									if (posix.length > 0)
									{
										GMS.Ajax.request({
											url: '/api/explorer/setfacl',
											jsonData: {
												argument: {
													Type: 'POSIX',
													Path: path,
													Permissions: posix,
												}
											},
											callback: function (options, success, response, decoded) {
												if (!success || !decoded.success)
													return;

												Ext.Msg.alert(lang_mss_share[0], lang_mss_share[231]);
											}
										});
									}

									var acl = get_dir_perms('ACL');

									if (acl.length <= 0)
									{
										GMS.Ajax.request({
											url: '/api/explorer/setfacl',
											jsonData: {
												argument: {
													Type: 'ACL',
													Path: path,
													Permissions: acl,
												}
											},
											callback: function (options, success, response, decoded) {
												if (!success || !decoded.success)
													return;

												Ext.Msg.alert(lang_mss_share[0], lang_mss_share[231]);
											}
										});
									}
								}
							}
						]
					},
					{
						xtype: 'BasePanel',
						layout: 'column',
						items: [
							{
								xtype: 'BasePanel',
								id: 'MSS_shareInfoModifyDirectoryPanel',
								name: 'shareInfoModifyDirectoryPanel',
								bodyStyle: { padding: 0 },
								style: { marginTop: '10px' },
								layout: 'fit',
								width: 480,
								height: 350,
								items: [ MSS_shareInfoModifyDirectoryGrid ]
							},
							{
								xtype: 'BasePanel',
								bodyStyle: { padding: 0 },
								id: 'MSS_shareInfoModifyOwnerPanel',
								style: {
									marginLeft: '25px',
									marginTop: '10px'
								},
								items: [
									{
										xtype: 'tabpanel',
										id: 'MSS_shareInfoModifyDirectoryOwnerInfo',
										activeTab: 0,
										bodyBorder: false,
										border: false,
										frame: true,
										items: [
											{
												xtype: 'BasePanel',
												id: 'MSS_shareInfoModifyPOSIXPanel',
												title: 'POSIX',
												bodyStyle: { padding: 0 },
												layout: 'fit',
												width: 480,
												height: 320,
												items: [ MSS_shareInfoModifyPOSIXGrid ]
											},
											{
												xtype: 'BasePanel',
												id: 'MSS_shareInfoModifyACLPanel',
												title: 'ACL',
												bodyStyle: { padding: 0 },
												layout: 'fit',
												width: 480,
												height: 320,
												items: [ MSS_shareInfoModifyACLGrid ]
											},
										]
									}
								]
							}
						]
					}
				]
			}
		]
	}
);

function getShare(name)
{
	var share = null;

	MSS_shareStore.each(
		function (record) {
			if (record.get('Name') == name)
			{
				share = record;
				return false;
			}
		}
	);

	return share;
}

function getVolume(name)
{
	var volume = null;

	console.log('volume_name:', name);
	console.log('store:', MSS_shareVolumeStore);

	MSS_shareVolumeStore.each(
		function (record) {
			console.log('volume:', record);

			if (record.get('Volume_Name') == name)
			{
				volume = record;
				return false;
			}
		}
	)

	return volume;
}

function getVolumePath(volume_name)
{
	var volume = getVolume(volume_name);
	var path   = volume.get('Volume_Mount');

	return path.replace(/\/+/, '/').replace(/\/+$/, '');
}

function getSharePath(share_selmodel)
{
	var share_selected = share_selmodel.getSelection()[0];
	var path = getVolumePath(share_selected.get('Volume'))
		+ share_selected.get('Path');

	return path.replace(/\/+/, '/').replace(/\/+$/, '');
}

function getNFSType(record)
{
	var volume   = getVolume(record.get('Volume'));
	var nfs_type = null;

	var policy = volume.get('Policy');

	if (typeof(policy) == 'undefined'
		|| policy == null)
	{
		return null;
	}

	switch (policy.toUpperCase())
	{
		case 'LOCAL':
			nfs_type = 'kernel';
			break;
		default:
			nfs_type = 'ganesha';
	}

	return nfs_type;
}

function getSelectedPath(share_selmodel, dir_selmodel)
{
	if (!share_selmodel.getCount())
		return null;

	var share_selected = share_selmodel.getSelection()[0],
	    dir_selected   = dir_selmodel.getSelection()[0];

	var volume_path    = getVolumePath(share_selected.get('Volume'));

	var path = dir_selmodel.getCount() > 0
	         ? dir_selected.get('FullPath').replace(volume_path, '')
	         : '/';

	path = path.replace(/\/+/, '/');

	return path.match(/[^\/]+\/+$/) ? path.replace(/\/+$/, '') : path;
}

function getSelectedFullPath(share_selmodel, dir_selmodel)
{
	if (!share_selmodel.getCount())
		return null;

	var share_selected = share_selmodel.getSelection()[0],
		dir_selected   = dir_selmodel.getSelection()[0];

	var volume_path = getVolumePath(share_selected.get('Volume'));

	var path = dir_selmodel.getCount() > 0
				? dir_selected.get('FullPath')
				: volume_path + share_selected.get('Path');

	return path.replace(/\/+/, '/').replace(/\/+$/, '');
}

/*
 * get_posix_perms
 *
 * @description get an array of POSIX permissions from POSIX store
 * @returns {array} Array of POSIX permissions
 */
function get_posix_perms()
{
	return MSS_shareInfoPOSIXStore.data.items.reduce(
		(acc, cur, i) => {
			acc.push(
				{
					Type: cur.get('Type'),
					ID: cur.get('ID'),
					Right: cur.get('Right'),
				}
			);
			return acc;
		},
		[]
	);
}

/**
 * get_acl_perms
 *
 * @description get an array of ACEs from ACL store
 * @returns {array} Array of ACEs
 */
function get_acl_perms()
{
	return MSS_shareInfoACLStore.data.items.reduce(
		(acc, cur, i) => {
			acc.push(
				{
					Type: cur.get('Type'),
					ID: cur.get('ID'),
					Right: cur.get('Right'),
				}
			);
			return acc;
		},
		[]
	);
}

/**
 * get_dir_perms
 *
 * @description get directory permissions for API request
 * @param {string} type POSIX or ACL
 * @returns {array} permissions array of specified type
 */
function get_dir_perms (type)
{
	var payload;

	switch (type)
	{
		case "POSIX":
			payload = MSS_shareInfoModifyPOSIXStore.data.items.reduce(
				(acc, cur, i) => {
					acc.push(
						{
							Type: cur.get('Type'),
							ID: cur.get('ID'),
							Right: cur.get('Right'),
						}
					);

					return acc;
				},
				[]
			);
			break;
		case "ACL":
			payload = MSS_shareInfoModifyACLStore.data.items.reduce(
				(acc, cur, i) => {
					acc.push(
						{
							Type: cur.get('Type'),
							ID: cur.get('ID'),
							Right: cur.get('Right'),
						}
					);

					return acc;
				},
				[]
			);
			break;
	}

	return payload;
}

/**
 * updateFilingProtocols
 *
 * @description call GMS API to enable/disable filing protocols for a share
 * @param {Object} params An object which may contain the following properties:
 * @param {string} params.name A share to enable/disable filing protocols
 * @param {string} params.volume A volume is associated with a share specified with params.name
 * @param {params} params.SMB Combobox component which stores enable/disable SMB
 * @param {params} params.NFS Compobox component which stores enable/disable NFS
 */
function updateFilingProtocols(params)
{
	params = params || {};

	var dfd      = Ext.create('Ext.ux.Deferred');
	var promises = [];

	if (params.SMB.isDirty())
	{
		promises.push(
			updateSMBForShare(
				params.name,
				params.volume,
				params.SMB.getValue(),
				'true',
			)
		);
	}

	if (params.NFS.isDirty())
	{
		promises.push(
			updateNFSForShare(
				params.name,
				params.volume,
				params.NFS.getValue()
			)
		);
	}

	Ext.ux.Deferred
		.when(...promises)
		.then(
			function (r) { dfd.resolve(r); },
			function (e) { dfd.reject(e); });

	return dfd.promise();
}

function setPermForShare(params)
{
	params = params || {};

	//var wait     = waitWindow(lang_mss_share[0], lang_mss_share[222]);
	var dfd      = Ext.create('Ext.ux.Deferred');
	var promises = [];

	promises.push(
		setPOSIXPerm({
			path: params.path,
			perm: params.perm.POSIX,
		})
	);

	promises.push(
		setACLPerm({
			path: params.path,
			perm: params.perm.ACL,
		})
	);

	Ext.ux.Deferred
		.when(...promises)
		.then(
			function (r) { dfd.resolve(r); },
			function (e) { dfd.reject(e); });
		/*
		.finally(function () {
			if (wait)
			{
				wait.hide();
			}
		});
		*/

	return dfd.promise();
}

function setPOSIXPerm(params)
{
	params = params || {};

	return GMS.Ajax.request({
		url: '/api/explorer/setfacl',
		waitMsgBox: null,
		jsonData: {
			argument: {
				Type: 'POSIX',
				Path: params.path.replace(/\/+/, '/'),
				Permissions: params.perm,
			}
		},
		callback: function (options, success, response, decoded) {
			if (success)
				options.deferred.promise().resolve(response);
			else
				options.deferred.promise().reject(response);
		}
	});
}

function setACLPerm(params)
{
	params = params || {};

	return GMS.Ajax.request({
		url: '/api/explorer/setfacl',
		waitMsgBox: null,
		jsonData: {
			argument: {
				Type: 'ACL',
				Path: params.path.replace(/\/+/, '/'),
				Permissions: params.perm,
			}
		},
		callback: function (options, success, response, decoded) {
			if (success)
				options.deferred.promise().resolve(response);
			else
				options.deferred.promise().reject(response);
		}
	});
}

/**
 * updateSMBForShare
 *
 * @description call GMS API to enable/disable SMB filing for a share
 * @param {string} name Share name to enable/disable SMB
 * @param {boolean} flag Flag to enable/disable SMB
 */
function updateSMBForShare(name, volume, flag)
{
	return GMS.Ajax.request({
		url: '/api/cluster/share/smb/' + (flag ? 'enable' : 'disable'),
		waitMsgBox: waitMsgBox
						? null
						: waitWindow(lang_mss_share[0], lang_mss_share[229]),
		method: 'POST',
		jsonData: {
			Name: name,
		},
		callback: function (options, success, response, decoded) {
			if (success)
				options.deferred.promise().resolve(response);
			else
				options.deferred.promise().reject(response);
		},
	});
}

/**
 * updateNFSForShare
 *
 * @description call GMS API to enable/disable NFS filing for a share
 * @param {string} name Share name to enable/disable NFS
 * @param {object} volume Volume used by a share that specified with 'name' parameter
 * @param {boolean} flag Flag to enable/disable NFS
 */
function updateNFSForShare(name, volume, flag)
{
	var nfs_type = null;

	switch (volume.get('Policy').toUpperCase())
	{
		case 'LOCAL':
			nfs_type = 'kernel';
			break;
		default:
			nfs_type = 'ganesha';
	}

	return GMS.Ajax.request({
		url: '/api/cluster/share/nfs/' + nfs_type + '/' + (flag ? 'enable' : 'disable'),
		waitMsgBox: waitMsgBox
						? null
						: waitWindow(lang_mss_share[0], lang_mss_share[230]),
		method: 'POST',
		jsonData: {
			Name: name,
		},
		callback: function (options, success, response, decoded) {
			if (success)
				options.deferred.promise().resolve(response);
			else
				options.deferred.promise().reject(response);
		},
	});
}

function volumeStoreLoad()
{
	var dfd = Ext.create('Ext.ux.Deferred');

	MSS_shareVolumeStore.load({
		callback: function (records, operation, success) {
			// 예외 처리에 따른 동작
			if (success !== true)
			{
				var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mss_share[0] + '",'
					+ '"content": "' + lang_mss_share[107] + '",'
					+ '"response": ' + jsonText
				+ '}';

				dfd.reject();

				return exceptionDataCheck(checkValue);
			}

			if (operation.resultSet.totalRecords <= 0)
			{
				dfd.resolve();
				Ext.Msg.alert(lang_mss_share[0], lang_mss_share[106]);
				return;
			}

			MSS_shareVolumeStore.clearFilter();

			dfd.resolve();
		}
	});

	return dfd.promise();
}

/** 공유 수정 WINDOW **/
var MSS_shareInfoModifyWin = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MSS_shareInfoModifyWin',
		title: lang_mss_share[221],
		maximizable: false,
		autoHeight: true,
		width: 1100,
		height: 770,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: {
					paddingTop: '20px',
					paddingRight: '20px',
					paddingBottom: '10px',
					paddingLeft: '20px',
				},
				layout: 'fit',
				id: 'MSS_shareInfoModifyPanel',
				items: [MSS_shareInfoModifyForm]
			}
		],
		buttons: [
			{
				text: lang_mss_share[195],
				id: 'MSS_shareInfoModifyClose',
				handler: function () {
					MSS_shareInfoModifyWin.hide();
				}
			}
		],
		listeners: {
			hide: function (thisWindow) {
				// 공유 목록 갱신
				MSS_shareLoad();
			},
		}
	}
);

// 공유 설정 생성/수정 버튼 컨트롤
function MSS_shareInfoBtn()
{
	if (MSS_shareInfoWin.layout.getActiveItem().id == 'MSS_shareInfoStep1')
	{
		Ext.getCmp('MSS_shareInfoPreviousBtn').hide();
		Ext.getCmp('MSS_shareInfoNextBtn').show();
		Ext.getCmp('MSS_shareInfoOKBtn').hide();

		MSS_shareInfoWin.setWidth(600, true);
	}
	else if (MSS_shareInfoWin.layout.getActiveItem().id == 'MSS_shareInfoStep2')
	{
		Ext.getCmp('MSS_shareInfoPreviousBtn').show();
		Ext.getCmp('MSS_shareInfoNextBtn').show();
		Ext.getCmp('MSS_shareInfoOKBtn').hide();

		MSS_shareInfoWin.setWidth(600, true);
	}
	else if (MSS_shareInfoWin.layout.getActiveItem().id == 'MSS_shareInfoStep3')
	{
		if (!Ext.getCmp('MSS_shareInfoStep2Panel').getForm().isValid())
		{
			MSS_shareInfoWin.layout.setActiveItem('MSS_shareInfoStep2');
			MSS_shareInfoBtn();
			return false;
		}

		Ext.getCmp('MSS_shareInfoPreviousBtn').show();
		Ext.getCmp('MSS_shareInfoNextBtn').hide();
		Ext.getCmp('MSS_shareInfoOKBtn').show();

		MSS_shareInfoWin.setWidth(1300, true);

		// ADS 라이선스 확인
		if (licenseADS != 'yes')
		{
			Ext.getCmp('MSS_shareInfoPOSIXLocationType').setDisabled(true);
			Ext.getCmp('MSS_shareInfoACLLocationType').setDisabled(true);
		}
		else
		{
			Ext.getCmp('MSS_shareInfoPOSIXLocationType').setDisabled(false);
			Ext.getCmp('MSS_shareInfoACLLocationType').setDisabled(false);
		}
	}

	MSS_shareInfoWin.center();
}

// 공유 설정 외부 인증
function MSS_shareInfoExternalCheck(type)
{
	return;

	// 외부 인증 필터링
	GMS.Ajax.request({
		url: '/api/cluster/auth/info',
		callback: function (options, success, response, decoded) {
			if (!success)
			{
				// 팝업창 닫기
				MSS_shareSMBWin.hide();
				return;
			}

			if (type == 'shareCreate' || type == 'shareModify')
			{
				// 외부인증 타입 확인 - ADS, LDAP filter :: 공유 생성/수정 - 사용자
				Ext.getCmp('MSS_shareInfoPOSIXLocationType').store.filter(
					function (record) {
						var loc = record.get('LocationCode');

						if (decoded.entity.ADS.Enabled == "true")
						{
							return (loc == 'ADS' || loc == 'LOCAL');
						}
						else if (decoded.entity.LDAP.Enabled == "true")
						{
							return (loc == 'LDAP' || loc == 'LOCAL');
						}
					}
				);


				// 외부인증 타입 확인 - ADS, LDAP filter :: 공유 생성/수정 - 그룹
				Ext.getCmp('MSS_shareInfoACLLocationType').store.filter(
					function (record) {
						var loc = record.get('LocationCode');

						if (decoded.entity.ADS.Enabled == "true")
						{
							return (loc == 'ADS' || loc == 'LOCAL');
						}
						else if (decoded.entity.LDAP.Enabled == "true")
						{
							return (loc == 'LDAP' || loc == 'LOCAL');
						}
					}
				);

				if (decoded.entity.ADS.Enabled == "true")
				{
					// 공유 생성/수정 - 사용자, 그룹
					Ext.getCmp('MSS_shareInfoPOSIXLocationType').setValue('ADS');
					Ext.getCmp('MSS_shareInfoACLLocationType').setValue('ADS');
				}
				else if (decoded.entity.LDAP.Enabled == "true")
				{
					// 공유 생성/수정 - 사용자, 그룹
					Ext.getCmp('MSS_shareInfoPOSIXLocationType').setValue('LDAP');
					Ext.getCmp('MSS_shareInfoACLLocationType').setValue('LDAP');
				}
			}

			if (type == 'SMB' || type == 'shareModify')
			{
				// 외부 인증 타입 확인 - ADS, LDAP filter :: SMB - 사용자
				Ext.getCmp('MSS_shareSMBUserLocationType').store.filter(
					function (record) {
						var loc = record.get('LocationCode');

						if (decoded.entity.ADS.Enabled == "true")
						{
							return (loc == 'ADS' || loc == 'LOCAL');
						}
						else if (decoded.entity.LDAP.Enabled == "true")
						{
							return (loc == 'LDAP' || loc == 'LOCAL');
						}
					}
				);

				// 외부 인증 타입 확인 - ADS, LDAP filter :: SMB - 그룹
				Ext.getCmp('MSS_shareSMBGroupLocationType').store.filter(
					function (record) {
						var loc = record.get('LocationCode');

						if (decoded.entity.ADS.Enabled == "true")
						{
							return (loc == 'ADS' || loc == 'LOCAL');
						}
						else if (decoded.entity.LDAP.Enabled == "true")
						{
							return (loc == 'LDAP' || loc == 'LOCAL');
						}
					}
				);

				if (decoded.entity.ADS.Enabled == "true")
				{
					// SMB - 사용자, 그룹
					Ext.getCmp('MSS_shareSMBUserLocationType').setValue('ADS');
					Ext.getCmp('MSS_shareSMBGroupLocationType').setValue('ADS');
				}
				else if (decoded.entity.LDAP.Enabled == "true")
				{
					// SMB - 사용자, 그룹
					Ext.getCmp('MSS_shareSMBUserLocationType').setValue('LDAP');
					Ext.getCmp('MSS_shareSMBGroupLocationType').setValue('LDAP');
				}
			}
		}
	});
};

// 공유 설정 정보 모델
Ext.define(
	'MSS_shareModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Name', 'Desc', 'Status', 'Path', 'Volume',
			{ name: 'SMB_Enabled', mapping: 'Protocols.SMB' },
			{ name: 'NFS_Enabled', mapping: 'Protocols.NFS' },
		]
	}
);

// 공유 설정 정보 스토어
var MSS_shareStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareModel',
		remoteFilter: true,
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		sortOnLoad: true,
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/list',
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
				store.proxy.setExtraParam(
					'FilterName',
					Ext.getCmp('MSS_shareFilterName').getValue()
				);
			},
			load: function (store, records, success) {
				if (success === true)
					return;

				// 예외 처리에 따른 동작
				var jsonText = JSON.stringify(store.proxy.reader.rawData);

				if (typeof(jsonText) == 'undefined')
					jsonText = '{}';

				var checkValue = '{'
					+ '"title": "' + lang_mss_share[0] + '",'
					+ '"content": "' + lang_mss_share[2] + '",'
					+ '"response":' + jsonText
					+ '}';

				return exceptionDataCheck(checkValue);
			}
		}
	}
);

// 공유 그리드
var MSS_shareGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareGrid',
		store: MSS_shareStore,
		style: { padding: 0 },
		bodyStyle: { padding: 0 },
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			mode: 'SINGLE',
			listeners: {
				selectall: function () {
					MSS_shareSelect('selectAll');
				},
				deselectall: function () {
					MSS_shareSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mss_share[4],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Name',
				/*
				renderer: function (val, meta, record, rowIndex, colIndex, store) {
					var status = record.get('Status');

					if (typeof(status) == undefined
						|| status == null
						|| status.toLowerCase() != 'normal')
					{
						if (typeof(status) == undefined || status == null)
						{
							record.set('Status', 'Unknown');
						}

						meta.tdAttr = 'data-qtip="'+lang_mss_share[102]+'"';
					}

					return val;
				}
				*/
			},
			{
				flex: 1,
				text: lang_mss_share[95],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Desc'
			},
			{
				flex: 1,
				text: lang_mss_share[141],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'Status'
			},
			{
				flex: 1,
				text: lang_mss_share[90],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'Path',
				renderer: function (val, meta, record, rowIndex, colIndex, store) {
					try {
						var volume_path = getVolumePath(record.get('Volume'));
						var voltype     = getVolume(record.get('Volume').Policy);
						var path        = record.get('Path');

						return volume_path + path;
					}
					catch (e) {
						console.error(e);
					}
				}
			},
			{
				flex: 1,
				text: lang_mss_share[92],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'Volume'
			},
			{
				xtype: 'actioncolumn',
				flex: 1,
				text: lang_mss_share[104],
				items: [
					{
						iconCls: 't-icon-cifs',
						tooltip: 'SMB',
						handler: function (grid, rowIndex, colIndex) {
							// 선택된 공유 정보 전달
							var record = grid.getStore().getAt(rowIndex);

							// WINDOW OPEN시 동작
							MSS_shareSMBWin.animateTarget = this.el;

							// 서비스 프로토콜 설정창 SHOW => 그리드 리스트 SELECT
							grid.getSelectionModel().deselectAll();
							grid.getSelectionModel().select(record, true);

							Ext.defer(function () { MSS_shareSelect(record) }, 100);

							// SMB 수정 팝업
							if (record.get('SMB_Enabled') == 'yes')
							{
								MSS_shareSMBWinLoad(record.get('Name'));
							}
							else
							{
								Ext.MessageBox.alert(lang_mss_share[0], lang_mss_share[232]);
							}
						},
						getClass: function (v, meta, record) {
							if (record.get('SMB_Enabled') == 'yes')
							{
								return 'x-action-col-icon x-action-col-0 t-icon-cifs';
							}
							else
							{
								return 'x-action-col-icon x-action-col-0 t-icon-cifs x-item-disabled disabled-click';
							}
						}
					},
					{
						iconCls: 't-icon-nfs',
						tooltip: 'NFS',
						handler: function (grid, rowIndex, colIndex) {
							if (licenseNFS != 'yes')
								return;

							// 선택된 공유 정보 전달
							var record = grid.getStore().getAt(rowIndex);

							// WINDOW OPEN시 동작
							MSS_shareNFSWin.animateTarget = this.el;

							// 서비스 프로토콜 설정창 SHOW => 그리드 리스트 SELECT
							grid.getSelectionModel().deselectAll();
							grid.getSelectionModel().select(record, true);

							Ext.defer(function () { MSS_shareSelect(record) }, 100);

							// NFS 정보 로드
							if (record.get('NFS_Enabled') == 'yes')
							{
								MSS_shareNFSWinLoad(record);
							}
							else
							{
								Ext.MessageBox.alert(lang_mss_share[0], lang_mss_share[232]);
							}
						},
						getClass: function (v, meta, record) {
							if (record.get('NFS_Enabled') == 'yes')
							{
								return 'x-action-col-icon x-action-col-1 t-icon-nfs';
							}
							else
							{
								return 'x-action-col-icon x-action-col-1 t-icon-nfs x-item-disabled disabled-click';
							}
						}
					}
				]
			},
		],
		tbar: [
			{
				text: lang_mss_share[105],
				id: 'MSS_shareAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					waitWindow(lang_mss_share[0], lang_mss_share[148]);

					// 볼륨 생성 시 볼륨 리스트, 경로 받아오기
					MSS_shareVolumeStore.load({
						callback: function (records, operation, success) {
							// 예외 처리에 따른 동작
							if (success !== true)
							{
								var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

								if (typeof(jsonText) == 'undefined')
									jsonText = '{}';

								var checkValue = '{'
									+ '"title": "' + lang_mss_share[0] + '",'
									+ '"content": "' + lang_mss_share[107] + '",'
									+ '"response": ' + jsonText
								+ '}';

								return exceptionDataCheck(checkValue);
							}

							if (operation.resultSet.totalRecords <= 0)
							{
								Ext.Msg.alert(lang_mss_share[0], lang_mss_share[106]);
								return;
							}

							// 데이터 전송 완료 후 wait 제거
							if (waitMsgBox)
							{
								waitMsgBox.hide();
								waitMsgBox = null;
							}

							// WINDOW OPEN 시 동작
							MSS_shareInfoWin.layout.setActiveItem('MSS_shareInfoStep1');
							MSS_shareInfoWin.animateTarget = Ext.getCmp('MSS_shareAddBtn');
							Ext.getCmp('MSS_shareInfoVolume').setDisabled(true);
							MSS_shareInfoWin.show();

							MSS_shareInfoBtn();

							// 외부 인증 체크
							MSS_shareInfoExternalCheck('shareCreate');

							// 수정일 경우 높이 지정(POSIX, ACL)
							Ext.getCmp('MSS_shareInfoOwnerPanel').getEl().setStyle('margin-top', '20px');
							
							// 기존 작성 폼 초기화
							Ext.getCmp('MSS_shareInfoForm').getForm().reset();

							/*
							// 볼륨 첫번째 선택
							var nodeNameObj = Ext.getCmp('MSS_shareInfoVolume');
							nodeNameObj.select(nodeNameObj.getStore().getAt(0).get(nodeNameObj.valueField));
							
							// 첫번째 공유 선택 후 select 이벤트 호출
							var record = nodeNameObj.getStore().findRecord(
								'Volume_Mount',
								nodeNameObj.getStore().getAt(0).get(nodeNameObj.valueField)
							);

							nodeNameObj.fireEvent('select', nodeNameObj, [record]);
							*/

							// POSIX, ACL 탭 기본 선택
							Ext.getCmp('MSS_shareInfoDirectoryOwnerInfo').setActiveTab(0);

							// SMB 라이선스 체크
							if (licenseSMB == 'yes')
							{
								Ext.getCmp('MSS_shareInfoSMB').setDisabled(false);
							}
							else
							{
								Ext.QuickTips.register({
									target: 'MSS_shareInfoSMB',
									text: lang_mcl_license[23],
									dismissDelay: 5000
								});

								Ext.getCmp('MSS_shareInfoSMB').setValue("no");
								Ext.getCmp('MSS_shareInfoSMB').setDisabled(true);
							}

							// NFS 라이선스 체크
							if (licenseNFS == 'yes')
							{
								Ext.getCmp('MSS_shareInfoNFS').setDisabled(false);
							}
							else
							{
								Ext.QuickTips.register({
									target: 'MSS_shareInfoNFS',
									text: lang_mcl_license[23],
									dismissDelay: 5000
								});

								Ext.getCmp('MSS_shareInfoNFS').setValue("no");
								Ext.getCmp('MSS_shareInfoNFS').setDisabled(true);
							}
						}
					});
				}
			},
			{
				text: lang_mss_share[108],
				id: 'MSS_shareModifyBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function () {
					Ext.getCmp('MSS_shareInfoModifyFormPanel').getForm().reset();

					// 공유 수정 시 선택된 공유 목록
					var share = MSS_shareGrid.getSelectionModel().getSelection()[0];

					// 공유 설정 정보 - 공유명 출력
					Ext.getCmp('MSS_shareInfoModifyName').setValue(share.get('Name'));

					// 공유 설정 정보 - 볼륨 출력
					Ext.getCmp('MSS_shareInfoModifyVolume').setValue(share.get('Volume'));

					// 공유 설정 정보 - 공유 설명 출력
					Ext.getCmp('MSS_shareInfoModifyDesc').setValue(share.get('Desc'));

					// 공유 수정 시 프로토콜 버튼, 체크박스 컨트롤
					if (licenseSMB == 'yes')
					{
						Ext.getCmp('MSS_shareInfoModifySMB').setDisabled(false);

						if (share.get('SMB_Enabled') == 'yes')
						{
							Ext.getCmp('MSS_shareInfoModifySMB').setValue(true);
							Ext.getCmp('MSS_shareInfoModifyProtocolSMB').setDisabled(false);
						}
						else
						{
							Ext.getCmp('MSS_shareInfoModifySMB').setValue(false);
							Ext.getCmp('MSS_shareInfoModifyProtocolSMB').setDisabled(true);
						}
					}
					else
					{
						Ext.getCmp('MSS_shareInfoModifySMB').setDisabled(true);
						Ext.getCmp('MSS_shareInfoModifySMB').setValue(false);
						Ext.getCmp('MSS_shareInfoModifyProtocolSMB').setDisabled(true);
					}

					if (licenseNFS == 'yes')
					{
						Ext.getCmp('MSS_shareInfoModifyNFS').setDisabled(false);

						if (share.get('NFS_Enabled') == 'yes')
						{
							Ext.getCmp('MSS_shareInfoModifyNFS').setValue(true);
							Ext.getCmp('MSS_shareInfoModifyProtocolNFS').setDisabled(false);
						}
						else
						{
							Ext.getCmp('MSS_shareInfoModifyNFS').setValue(false);
							Ext.getCmp('MSS_shareInfoModifyProtocolNFS').setDisabled(true);
						}
					}
					else
					{
						Ext.getCmp('MSS_shareInfoModifyNFS').setDisabled(true);
						Ext.getCmp('MSS_shareInfoModifyNFS').setValue(false);
						Ext.getCmp('MSS_shareInfoModifyProtocolNFS').setDisabled(true);
					}

					Ext.getCmp('MSS_shareInfoModifySMB').originalValue
						= Ext.getCmp('MSS_shareInfoModifySMB').getValue();

					Ext.getCmp('MSS_shareInfoModifyNFS').originalValue
						= Ext.getCmp('MSS_shareInfoModifyNFS').getValue();

					var nfs_flag = false;

					MSS_shareStore.each(
						function (record) {
							var rec_vol   = getVolume(record.get('Volume'));
							var share_vol = getVolume(share.get('Volume'));

							if (record.get('NFS_Enabled') == 'yes'
								&& (rec_vol.get('Volume_Type')
									!= share_vol.get('Volume_Type')))
							{
								nfs_flag = true;
							}
						}
					);

					if (nfs_flag)
					{
						Ext.getCmp('MSS_shareInfoModifyNFS').setValue('no');
						Ext.getCmp('MSS_shareInfoModifyNFS').setDisabled(true);
					}
					else
					{
						Ext.getCmp('MSS_shareInfoModifyNFS').setDisabled(false);
					}

					// 공유 수정 WINDOW OPEN
					MSS_shareInfoModifyWin.show();

					// 외부 인증 체크
					MSS_shareInfoExternalCheck('shareModify');

					// 디렉토리 경로 호출 시 전달값 - 볼륨 경로, 공유 경로
					var volume_path = getVolumePath(share.get('Volume'));
					var share_path  = volume_path + share.get('Path');

					// 디렉토리 경로 정보 로드
					var shareInfoModifyDirectoryLoadMask = new Ext.LoadMask(
						Ext.getCmp('MSS_shareInfoModifyDirectoryGrid'),
						{ msg: (lang_common[30]) }
					);

					shareInfoModifyDirectoryLoadMask.show();

					MSS_shareInfoModifyDirectoryStore.proxy.extraParams = {
						argument: {
							type: ['dir'],
							dirpath: share_path,
						}
					};

					MSS_shareInfoModifyDirectoryStore.load({
						callback: function (records, operation, success) {
							shareInfoModifyDirectoryLoadMask.hide();
						}
					});

					// POSIX 정보 로드
					var shareInfoModifyPOSIXGridLoadMask = new Ext.LoadMask(
						Ext.getCmp('MSS_shareInfoModifyPOSIXGrid'),
						{ msg: (lang_mcn_zone[33]) }
					);

					shareInfoModifyPOSIXGridLoadMask.show();

					// POSIX 호출 시 전달값 - 공유 경로
					MSS_shareInfoModifyPOSIXStore.proxy.extraParams = {
						argument: {
							Type: 'POSIX',
							Path: share_path,
						}
					};

					MSS_shareInfoModifyPOSIXStore.load({
						callback: function (records, operation, success) {
							shareInfoModifyPOSIXGridLoadMask.hide();
						}
					});

					// ACL 호출시 전달 값 - 공유 경로
					MSS_shareInfoModifyACLStore.proxy.extraParams = {
						argument: {
							Type: 'ACL',
							Path: share_path,
						}
					};

					// ACL 정보 로드
					MSS_shareInfoModifyACLStore.load();
				}
			},
			{
				text: lang_mss_share[109],
				id: 'MSS_shareDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					Ext.Msg.confirm(
						lang_mss_share[0],
						lang_mss_share[110],
						function (btn, text) {
							if (btn !== 'yes')
								return;

							// 선택된 그리드의 전송값 추출
							var shareList = MSS_shareGrid.getSelectionModel().getSelection();
							var targets   = shareList.reduce(
								(acc, cur, i) => {
									acc.push(cur.get('Name'));
									return acc;
								},
								[]
							);

							waitWindow(lang_mss_share[0], lang_mss_share[111]);

							// TODO: delete multiple shares in async way
							GMS.Ajax.request({
								url: '/api/cluster/share/delete',
								jsonData: {
									Name: targets[0]
								},
								callback: function (options, success, response, decoded) {
									if (!success)
										return;

									Ext.Msg.alert(lang_mss_share[0], lang_mss_share[112]);
									MSS_shareLoad();
								}
							});
						}
					);
				}
			},
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareFilterName',
				hiddenName: 'shareFilterName',
				name: 'shareFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mss_share[4], 'Name'],
						[lang_mss_share[95], 'Desc'],
						[lang_mss_share[90], 'Path']
					]
				}),
				value: 'Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mss_share[22],
			{
				xtype: 'searchfield',
				id: 'MSS_shareFilterArgs',
				store: MSS_shareStore,
				paramName: 'searchStr',
				width: 180
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MSS_shareSelect(record) }, 100);
			},
		},
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false,
			getRowClass: function (record) {
				// 상태가 Normal이 아닐 경우
				if (record.get('Status') !== 'Normal')
				{
					return 'err-row';
				}
			}
		}
	}
);

// 공유 그리드 선택 시 버튼 컨트롤
function MSS_shareSelect(record)
{
	var selectCount = MSS_shareGrid.getSelectionModel().getCount();

	if (selectCount > 1)
	{
		Ext.getCmp('MSS_shareModifyBtn').setDisabled(true);
		Ext.getCmp('MSS_shareDelBtn').setDisabled(false);
	}
	else if (selectCount == 1)
	{
		var status = MSS_shareGrid.selModel.selected.items[0].get('Status');

		if (status == 'Normal')
		{
			Ext.getCmp('MSS_shareModifyBtn').setDisabled(false);
			Ext.getCmp('MSS_shareDelBtn').setDisabled(false);
		}
		else
		{
			Ext.getCmp('MSS_shareModifyBtn').setDisabled(true);
			Ext.getCmp('MSS_shareDelBtn').setDisabled(false);
		}
	}
	else
	{
		Ext.getCmp('MSS_shareModifyBtn').setDisabled(true);
		Ext.getCmp('MSS_shareDelBtn').setDisabled(true);
	}
};

/**
공유 SMB
**/
// SMB 공유 모델
Ext.define(
	'MSS_shareSMBModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Name', 'Comment', 'Path', 'Read_Only', 'Guest_Ok',
			'Browseable', 'Available'
		]
	}
);

// SMB 공유 스토어
var MSS_shareSMBStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareSMBModel',
		remoteFilter: true,
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		sortOnLoad: true,
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/smb/list',
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
				store.proxy.setExtraParam(
					'FilterName',
					Ext.getCmp('MSS_shareSMBFilterName').getValue()
				);
			},
			load: function (store, records, success) {
				if (success !== true)
				{
					// 예외 처리에 따른 동작
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mss_share[0] + '",'
						+ '"content": "' + lang_mss_share[2] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				// 데이터 로드 성공 메세지
				//Ext.ux.DialogMsg.msg(lang_mss_share[0], lang_mss_share[1]);
			}
		}
	}
);

// SMB 공유 그리드
var MSS_shareSMBGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareSMBGrid',
		store: MSS_shareSMBStore,
		style: { padding: 0 },
		bodyStyle: { padding: 0 },
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			mode: 'SINGLE',
			listeners: {
				selectall: function () {
					MSS_shareSMBSelect('selectAll');
				},
				deselectall: function () {
					MSS_shareSMBSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mss_share[4],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Name'
			},
			{
				flex: 1,
				text: lang_mss_share[95],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Comment'
			},
			{
				flex: 1,
				text: lang_mss_share[90],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'Path'
			},
			{
				flex: 1,
				text: lang_mss_share[18],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'Read_Only',
				renderer: function (value) {
					switch (value.toUpperCase()) {
						case 'YES':
							return lang_mss_share[150];
						case 'NO':
							return lang_mss_share[152];
						case 'None':
							return lang_mss_share[193];
					}
				}
			},
			{
				flex: 1,
				text: lang_mss_share[10],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Guest_Ok'
			},
			{
				flex: 1,
				text: lang_mss_share[115],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Browseable'
			},
			{
				flex: 1,
				text: lang_mss_share[9],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Available'
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MSS_shareSMBSelect(record) }, 100);
			}
		},
		tbar: [
			{
				text: lang_mss_share[108],
				id: 'MSS_shareSMBModifyBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function () {
					// 선택된 공유 정보 전달
					var shareSMBSelectedRec = MSS_shareSMBGrid.getSelectionModel().getSelection();
					var shareSMBSelectName = shareSMBSelectedRec[0].get('Name');

					// WINDOW OPEN시 동작
					MSS_shareSMBWin.animateTarget = Ext.getCmp('MSS_shareSMBModifyBtn');

					// SMB, ADS 라이선스 체크
					MSS_shareSMBWinLoad(shareSMBSelectName);
				}
			},
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareSMBFilterName',
				hiddenName: 'shareSMBFilterName',
				name: 'shareSMBFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mss_share[4], 'Name'],
						[lang_mss_share[95], 'Desc'],
						[lang_mss_share[90], 'Path']
					]
				}),
				value: 'Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mss_share[22],{
				xtype: 'searchfield',
				id: 'MSS_shareSMBFilterArgs',
				store: MSS_shareSMBStore,
				paramName: 'searchStr',
				width: 180
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

// 공유 SMB 그리드 선택 시 버튼 컨트롤
function MSS_shareSMBSelect(record)
{
	var selectCount = MSS_shareSMBGrid.getSelectionModel().getCount();

	if (selectCount > 1)
	{
		Ext.getCmp('MSS_shareSMBModifyBtn').setDisabled(true);
	}
	else if (selectCount == 1)
	{
		Ext.getCmp('MSS_shareSMBModifyBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MSS_shareSMBModifyBtn').setDisabled(true);
	}
};

/**
공유 NFS
**/
// NFS 공유 모델
Ext.define(
	'MSS_shareNFSModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Name', 'Desc', 'Path', 'Available', 'Type']
	}
);

// NFS 공유 스토어
var MSS_shareNFSStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MSS_shareNFSModel',
		remoteFilter: true,
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		sortOnLoad: true,
		/*
		proxy: {
			type: 'ajax',
			url: '/api/cluster/share/nfs/ganesha/list',
			reader: {
				type: 'json',
				root: 'entity'
			}
		},
		*/
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
				store.proxy.setExtraParam(
					'FilterName',
					Ext.getCmp('MSS_shareNFSFilterName').getValue()
				);
			},
			load: function (store, records, success) {
				if (success !== true)
				{
					// 예외 처리에 따른 동작
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mss_share[0] + '",'
						+ '"content": "' + lang_mss_share[2] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}
			}
		}
	}
);

// NFS 공유 그리드
var MSS_shareNFSGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MSS_shareNFSGrid',
		store: MSS_shareNFSStore,
		style: { padding: 0 },
		bodyStyle: { padding: 0 },
		loadMask: { msg: lang_common[30] },
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			mode: 'SINGLE',
			listeners: {
				selectall: function () {
					MSS_shareNFSSelect('selectAll');
				},
				deselectall: function () {
					MSS_shareNFSSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mss_share[4],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Name'
			},
			{
				flex: 1,
				text: lang_mss_share[95],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Desc'
			},
			{
				flex: 1,
				text: lang_mss_share[90],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'Path'
			},
			{
				flex: 1,
				text: lang_mss_share[9],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Available'
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MSS_shareNFSSelect(record) }, 100);
			}
		},
		tbar: [
			{
				text: lang_mss_share[108],
				id: 'MSS_shareNFSModifyBtn',
				iconCls: 'b-icon-edit',
				disabled: true,
				handler: function () {
					// 선택된 공유 정보 전달
					var shareNFSSelectedRec = MSS_shareNFSGrid.getSelectionModel().getSelection();

					// WINDOW OPEN시 동작
					MSS_shareNFSWin.animateTarget = Ext.getCmp('MSS_shareNFSModifyBtn');

					// NFS 수정 팝업
					MSS_shareNFSWinLoad(shareNFSSelectedRec[0]);
				}
			},
			{
				xtype: 'BaseComboBox',
				hideLabel: true,
				id: 'MSS_shareNFSFilterName',
				hiddenName: 'shareNFSFilterName',
				name: 'shareNFSFilterName',
				store: new Ext.data.SimpleStore({
					fields: ['FilterName', 'FilterCode'],
					data: [
						[lang_mss_share[4], 'Name'],
						[lang_mss_share[95], 'Desc'],
						[lang_mss_share[90], 'Path']
					]
				}),
				value: 'Name',
				displayField: 'FilterName',
				valueField: 'FilterCode'
			},
			'-',
			lang_mss_share[22],
			{
				xtype: 'searchfield',
				id: 'MSS_shareNFSFilterArgs',
				store: MSS_shareNFSStore,
				paramName: 'searchStr',
				width: 180
			}
		],
		viewConfig: {
			forceFit: true,
			loadMask: true,
			trackOver: false
		}
	}
);

// 공유 NFS 그리드 선택 시 버튼 컨트롤
function MSS_shareNFSSelect(record)
{
	var selectCount = MSS_shareNFSGrid.getSelectionModel().getCount();

	if (selectCount > 1)
	{
		Ext.getCmp('MSS_shareNFSModifyBtn').setDisabled(true);
	}
	else if (selectCount == 1)
	{
		Ext.getCmp('MSS_shareNFSModifyBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MSS_shareNFSModifyBtn').setDisabled(true);
	}
};

// 공유 설정
Ext.define(
	'/admin/js/manager_share_share',
	{
		extend: 'BasePanel',
		id: 'manager_share_share',
		load: function () {
			MSS_shareLoad();
			Ext.getCmp('MSS_shareTab').layout.setActiveItem('MSS_shareListTab');
			Ext.QuickTips.init();
		},
		bodyStyle: { padding: 0 },
		items: [
			{
				xtype: 'tabpanel',
				id: 'MSS_shareTab',
				activeTab: 0,
				frame: false,
				bodyStyle: { padding: 0 },
				border: false,
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: { padding: 0 },
						title: lang_mss_share[0],
						id: 'MSS_shareListTab',
						layout: 'fit',
						iconCls: 't-icon-share',
						items: [MSS_shareGrid]
					},
				],
				listeners: {
					tabchange: function (tabPanel, newCard, oldCard) {
						if (newCard.id == 'MSS_shareListTab')
						{
							MSS_shareLoad();
						}
					}
				}
			}
		]
	}
);
