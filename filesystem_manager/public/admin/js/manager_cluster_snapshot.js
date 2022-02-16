/*
 * 페이지 로드 시 실행 함수
 */
function MCS_snapshotSchedLoad()
{
	// 스냅샷 스케줄링 목록 마스크 표시
	var snapshotSchedLoadMask = new Ext.LoadMask(
		Ext.getCmp('MCS_snapshotSchedListGrid'),
		{ msg: (lang_mcs_snapshot[113]) }
	);

	snapshotSchedLoadMask.show();

	// 스냅샷 스케줄링 데이터 호출
	GMS.Ajax.request({
		url: '/api/cluster/schedule/snapshot/list',
		method: 'POST',
		callback: function(options, success, response, decoded) {
			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
				return;

			// 수동 스냅샷 리스트
			var manSnapList = [];

			GMS.Ajax.request({
				url: '/api/cluster/volume/snapshot/list',
				method: 'POST',
				async: false,
				jsonData: {
					argument: {
						FS_Type: 'glusterfs',
					},
				},
				callback: function(options, success, response, decoded) {
					// 예외 처리에 따른 동작
					if (!success || !decoded.success)
						return;

					// 볼륨별 수동 스냅샷 수
					var manCountEach = {};

					for (var i = 0; i < decoded.entity.length; i++)
					{
						var name = decoded.entity[i].Volume_Name;
						if (decoded.entity[i].Created_By == null)
						{
							manCountEach[name] = manCountEach[name] ? manCountEach[name] + 1 : 1;
						}
					}

					// 볼륨명 가져오기
					var volumeNames = Object.keys(manCountEach);

					// JSON 생성
					for (var i = 0; i < volumeNames.length; i++)
					{
						var manSnapItem = new Object();
						manSnapItem.Volume_Name = volumeNames[i];
						manSnapItem.Snapshot_Count = manCountEach[volumeNames[i]];
						manSnapItem.Sched_Name = lang_mcs_snapshot[79];

						manSnapList.push(manSnapItem);
					}
				}
			});

			snapshotSchedLoadMask.hide();

			manSnapList.forEach(function (i) {
				decoded.entity.push(i);
			});

			MCS_snapshotSchedListStore.loadRawData(decoded.entity, false);
		}
	});
}

/*
 * 스냅샷
 */
// 스냅샷 목록 모델
Ext.define('MCS_snapshotManagementModel', {
	extend: 'Ext.data.Model',
	fields: [
		'Snapshot_Name', 'Node_List', 'Status',
		'Activated', 'Created', 'Management',
		'Volume_Name', 'Snapshot_Desc'
	]
});

// 스냅샷 목록 스토어
var MCS_snapshotManagementStore = Ext.create('Ext.data.Store', {
	model: 'MCS_snapshotManagementModel',
	sorters: [
		{
			property: 'Created',
			direction: 'DESC'
		}
	],
	proxy: {
		type: 'ajax',
		url: '/api/cluster/volume/snapshot/list',
		reader: {
			type: 'json',
			root: 'entity'
		}
	},
	listeners: {
		beforeload: function(store, operation, eOpts) {
			store.removeAll();
		}
	}
});

// 스냅샷 목록 그리드
var MCS_snapshotManagementGrid = Ext.create('BaseGridPanel', {
	id: 'MCS_snapshotManagementGrid',
	store: MCS_snapshotManagementStore,
	multiSelect: false,
	frame: false,
	border: false,
	cls: 'line-break',
	columns: [
		{
			flex: 2.5,
			text: lang_mcs_snapshot[86],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Snapshot_Name'
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[112],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Status'
		},
		{
			flex: 3,
			text: lang_mcs_snapshot[111],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Node_List',
			renderer: function(value) {
				return value.sort();
			}
		},
		{
			flex: 1.5,
			text: lang_mcs_snapshot[84],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Created',
			xtype: 'componentcolumn',
			renderer: function(v, m, r) {
				var Created = stampToData(v * 1000);

				return {
					xtype: 'label',
					text: Created
				}
			}
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[83],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Activated',
			xtype: 'componentcolumn',
			renderer: function(value) {
				if (value == 'false')
				{
					return {
						xtype: 'label',
						text: 'deactivate'
					}
				}
				else
				{
					return {
						xtype: 'label',
						text: 'activate'
					}
				}
			}
		},
		{
			text: lang_mcs_snapshot[9],
			width: 140,
			autoSizeColumn: true,
			minWidth: 140,
			sortable: false,
			menuDisabled: true,
			dataIndex: 'Management',
			xtype: 'componentcolumn',
			renderer: function(value, metaData, record) {
				var scrollMenu = new Ext.menu.Menu();

				if (record.data.Activated == "false")
				{
					// 스냅샷 목록의 활성화 상태가 DEACTIVATE 일 때
					scrollMenu.add({
						text: lang_mcs_snapshot[92],
						handler: function() {
							var me = this;

							me.up('button').setText(lang_mcs_snapshot[92]);

							Ext.defer(function() {
								me.up('button').setText(lang_mcs_snapshot[9]);
							}, 500);

							Ext.MessageBox.confirm(
								lang_mcs_snapshot[0],
								lang_mcs_snapshot[103],
								function(btn, text) {
									if (btn != 'yes')
										return;

									// 스냅샷 활성화 유무 확인
									waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[109]);

									GMS.Ajax.request({
										url: '/api/cluster/volume/snapshot/activate',
										jsonData: {
											argument: {
												Volume_Name: record.data.Volume_Name,
												Snapshot_Name: record.data.Snapshot_Name,
												Activated: 'true'
											}
										},
										callback: function(options, success, response, decoded) {
											if (!success || !decoded.success)
												return;

											// 성공 메시지
											var msg = decoded.msg ? decoded.msg : lang_mcs_snapshot[104];

											Ext.MessageBox.alert(lang_mcs_snapshot[0], msg);

											// 스냅샷 목록 마스크 표시
											var snapshotLoadMask = new Ext.LoadMask(
												Ext.getCmp('MCS_snapshotManagementGrid'),
												{ msg: (lang_mcs_snapshot[113]) }
											);

											snapshotLoadMask.show();

											// 스냅샷 리스트
											GMS.Ajax.request({
												url: '/api/cluster/volume/snapshot/list',
												jsonData: {
													argument: {
														Volume_Name: record.data.Volume_Name,
														Filter_By: record.data.Snapshot_Desc,
													}
												},
												callback: function(options, success, response, decoded) {
													// 마스크 숨김
													snapshotLoadMask.hide();

													// 예외 처리에 따른 동작
													if (!success || !decoded.success)
														return;

													MCS_snapshotManagementStore.loadRawData(decoded.entity);
												},
											});
										},
									});
								}
							);
						}
					});
				}
				else
				{
					// 스냅샷 목록의 활성화 상태가 ACTIVATE 일 때
					scrollMenu.add({
						text: lang_mcs_snapshot[102],
						handler: function() {
							var me = this;

							me.up('button').setText(lang_mcs_snapshot[102]);

							Ext.defer(function() {
								me.up('button').setText(lang_mcs_snapshot[9]);
							}, 500);

							Ext.MessageBox.confirm(
								lang_mcs_snapshot[0],
								lang_mcs_snapshot[103],
								function(btn, text) {
									if (btn != 'yes')
										return;

									// 스냅샷 활성화 유무 확인
									waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[109]);

									GMS.Ajax.request({
										url: '/api/cluster/volume/snapshot/activate',
										jsonData: {
											argument: {
												Volume_Name: record.data.Volume_Name,
												Snapshot_Name: record.data.Snapshot_Name,
												Activated: 'false'
											}
										},
										callback: function(options, success, response, decoded) {
											if (!success || !decoded.success)
												return;

											// 성공 메시지
											var msg = decoded.msg ? decoded.msg : lang_mcs_snapshot[104];

											Ext.MessageBox.alert(lang_mcs_snapshot[0], msg);

											// 스냅샷 목록 마스크 표시
											var snapshotLoadMask = new Ext.LoadMask(
												Ext.getCmp('MCS_snapshotManagementGrid'),
												{ msg: (lang_mcs_snapshot[113]) }
											);

											snapshotLoadMask.show();

											// 스냅샷 리스트
											GMS.Ajax.request({
												url: '/api/cluster/volume/snapshot/list',
												jsonData: {
													argument: {
														Volume_Name: record.data.Volume_Name,
														Filter_By: record.data.Snapshot_Desc,
													},
												},
												callback: function(options, success, response, decoded) {
													// 마스크 숨김
													snapshotLoadMask.hide();

													if (!success || !decoded.success)
														return;

													MCS_snapshotManagementStore.loadRawData(decoded.entity);
												},
											});
										},
									});
								}
							);
						}
					});
				}

				scrollMenu.add({
					// DELETE
					text: lang_mcs_snapshot[10],
					handler: function() {
						var me = this;
						me.up('button').setText(lang_mcs_snapshot[10]);

						Ext.defer(function() {
							me.up('button').setText(lang_mcs_snapshot[9]);
						}, 500);

						Ext.MessageBox.confirm(
							lang_mcs_snapshot[0],
							lang_mcs_snapshot[97],
							function(btn, text) {
								if (btn != 'yes')
									return;

								// 스냅샷 삭제 유무 확인
								waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[107]);

								GMS.Ajax.request({
									url: '/api/cluster/volume/snapshot/delete',
									jsonData: {
										argument: {
											Volume_Name: record.data.Volume_Name,
											Snapshot_Name: record.data.Snapshot_Name
										}
									},
									callback: function(options, success, response, decoded) {
										if (!success || !decoded.success)
											return;

										// 성공 메시지
										Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[95]);

										// 스냅샷 목록 마스크 표시
										var snapshotLoadMask = new Ext.LoadMask(
											Ext.getCmp('MCS_snapshotManagementGrid'),
											{ msg: (lang_mcs_snapshot[113]) }
										);

										snapshotLoadMask.show();

										// 스냅샷 스케줄링 리스트
										MCS_snapshotSchedLoad();

										// 스냅샷 리스트
										GMS.Ajax.request({
											url: '/api/cluster/volume/snapshot/list',
											jsonData: {
												argument: {
													Volume_Name: record.data.Volume_Name,
													Filter_By: record.data.Snapshot_Desc,
												}
											},
											callback: function(options, success, response, decoded) {
												// 마스크 숨김
												snapshotLoadMask.hide();

												if (!success || !decoded.success)
													return;

												MCS_snapshotManagementStore.loadRawData(decoded.entity);
											},
										});
									},
								});
							}
						);
					}
				});

				return {
					xtype: 'button',
					text: lang_mcs_snapshot[9],
					menu: scrollMenu
				}
			}
		}
	]
});

// 스냅샷 관리 WINDOW
var MCS_snapshotManagementWindow = Ext.create('BaseWindowPanel', {
	id: 'MCS_snapshotManagementWindow',
	title: lang_mcs_snapshot[0],
	maximizable: false,
	width: 1200,
	height: 700,
	layout: 'fit',
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			bodyStyle: 'padding: 0',
			autoScroll: true,
			items: [ MCS_snapshotManagementGrid ]
		}
	]
});

/*
 * 볼륨 리스트
 */
// 볼륨 리스트 모델
Ext.define('MCS_volumeListModel',{
	extend: 'Ext.data.Model',
	fields: ['Volume_Name']
});

// 볼륨 리스트 스토어
var MCS_snapshotVolumeListStore = Ext.create('Ext.data.Store', {
	model: 'MCS_volumeListModel',
	sorters: [
		{
			property: 'Volume_Name',
			direction: 'ASC',
		},
	],
	sortOnLoad: true,
	proxy: {
		type: 'ajax',
		url: '/api/cluster/volume/list',
		reader: {
			type: 'json',
			root: 'entity',
			totalProperty: 'count',
			getResponseData: function(response) {
				try {
					var json = Ext.decode(response.responseText);

					var idx = json.entity.length;
					while(idx--)
					{
						if (json.entity[idx].Provision != 'thin')
						{
							json.entity.splice(idx, 1);
						}
					}

					return this.readRecords({
						entity: json.entity,
						count: json.count ? json.count : 0,
						success: json.success,
					});
				}
				catch(ex) {
					var error = new Ext.data.ResultSet({
						total: 0,
						count: 0,
						records: [],
						success: false,
						message: ex.message,
					});

					Ext.MessageBox.alert(lang_mcs_snapshot[0], ex.message);
					Ext.log('Unable to parse the response returned by the server as JSON format');

					return error;
				}
			},
		},
	}
});

/*
 * 스냅샷 생성 팝업
 */
// 스냅샷 생성 PANEL
var MCS_snapshotCreatePanel = Ext.create('BaseFormPanel', {
	id: 'MCS_snapshotCreatePanel',
	frame: false,
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding:0;',
			border: false,
			style: { marginBottom: '30px' },
			html: lang_mcs_snapshot[118]
		},
		{
			xtype: 'BaseComboBox',
			fieldLabel: lang_mcs_snapshot[27],
			id: 'MCS_snapshotCreateVolumeName',
			name:'snapshotCreateVolumeName',
			style: { marginBottom: '20px' },
			labelWidth: 130,
			store: MCS_snapshotVolumeListStore,
			displayField: 'Volume_Name',
			valueField: 'Volume_Name',
			listeners: {
				select: function( grid, record, index, eOpts) {
					// 스냅샷 스케줄링 목록 마스크 표시
					var snapshotCreateLoadMask = new Ext.LoadMask(
						Ext.getCmp('MCS_snapshotCreatePanel'),
						{ msg: (lang_mcs_snapshot[113]) }
					);

					snapshotCreateLoadMask.show();

					// 생성 가능한 스냅샷 개수
					GMS.Ajax.request({
						url: '/api/cluster/volume/snapshot/avail',
						jsonData: {
							argument: {
								Volume_Name: Ext.getCmp('MCS_snapshotCreateVolumeName').getValue(),
							}
						},
						callback: function(options, success, response, decoded) {
							snapshotCreateLoadMask.hide();

							// 예외 처리에 따른 동작
							if (!success || !decoded.success)
								return;

							// 생성 가능한 스냅샷 개수
							var snapshotAvail = decoded.entity;

							Ext.getCmp('MCS_snapshotCreateAvail').setText(snapshotAvail);
						},
					});
				}
			}
		},
		{
			xtype: 'textfield',
			id: 'MCS_snapshotCreateName',
			fieldLabel: lang_mcs_snapshot[86],
			allowBlank: false,
			vtype: 'reg_snapshotName',
			enableKeyEvents: true,
			style: { marginBottom: '20px' },
			listeners: {
				specialkey: function(field, e) {
					if (e.getKey() != e.ENTER)
						return;

					Ext.getCmp("MCS_snapshotCreateOKBtn").handler.call(
						Ext.getCmp("MCS_snapshotCreateOKBtn").scope
					);
				}
			}
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding:0;',
			layout: 'hbox',
			maskOnDisable: false,
			items: [
				{
					xtype: 'label',
					text: lang_mcs_snapshot[117] + ': ',
					style: { marginTop: '5px', marginRight: '10px' }
				},
				{
					xtype: 'label',
					id: 'MCS_snapshotCreateAvail',
					style: { marginTop: '5px' }
				}
			]
		}
	]
});

// 스냅샷 생성 WINDOW
var MCS_snapshotCreateWindow = Ext.create('BaseWindowPanel', {
	id: 'MCS_snapshotCreateWindow',
	title: lang_mcs_snapshot[88],
	maximizable: false,
	autoHeight: true,
	width: 380,
	items: [MCS_snapshotCreatePanel],
	buttons: [
		{
			id: 'MCS_snapshotCreateOKBtn',
			text: lang_mcs_snapshot[32],
			width: 70,
			handler:function() {
				if (Ext.getCmp('MCS_snapshotCreateName').validate() == false)
				{
					return false;
				}

				if (Ext.getCmp('MCS_snapshotCreateAvail').text == '0')
				{
					Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[119]);
					return false;
				}

				waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[39]);

				GMS.Ajax.request({
					url: '/api/cluster/volume/snapshot/create',
					jsonData: {
						argument: {
							// 볼륨 명
							Volume_Name: Ext.getCmp('MCS_snapshotCreateVolumeName').getValue(),
							// 스냅샷 명
							Snapshot_Name: Ext.getCmp('MCS_snapshotCreateName').getValue(),
							Snapshot_Desc: 'manual', 
						}
					},
					callback: function(options, success, response, decoded) {
						if (success && decoded.success)
						{
							Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[93]);
							MCS_snapshotCreateWindow.hide();
							MCS_snapshotSchedLoad();
						}
						else
						{
							MCS_snapshotCreateWindow.hide();
							MCS_snapshotSchedLoad();
							Ext.MessageBox.alert(lang_mcs_snapshot[0], decoded.msg);
						}
					},
				});
			}
		}
	]
});

/*
 * 스냅샷 스케줄링 목록
 */
// 스냅샷 스케줄링 목록 모델
Ext.define('MCS_snapshotSchedListModel',{
	extend: 'Ext.data.Model',
	fields: [
		'Volume_Name', 'Sched_ID', 'Period_Unit', 'Sched_Times',
		'Management', 'Sched_Week_Days', 'Sched_Weeks', 'Start_Date',
		'End_Date', 'Sched_Enabled', 'Snapshot_Activate', 'Snapshot_Count',
		'Prev_Sched', 'Snapshot_Limit', 'Prev_Sched_Msg', 'Prev_Sched_Status',
		'Next_Sched', 'Period', 'Prev_Start_Of_Period', 'Sched_Name'
	]
});

// 스냅샷 스케줄링 목록 스토어
var MCS_snapshotSchedListStore = Ext.create('Ext.data.Store', {
	model: 'MCS_snapshotSchedListModel',
	sorters: [
		{
			property: 'Volume_Name',
			direction: 'ASC'
		},
		{
			property: 'Sched_Name',
			direction: 'ASC'
		}
	],
	proxy: {
		type: 'ajax',
		//url: '/index.php/admin/manager_cluster_snapshot/scheduleList',
		url: '/api/cluster/schedule/snapshot/list',
		reader: {
			type: 'json',
			root: 'entity'
		}
	},
	listeners: {
		beforeload: function(store, operation, eOpts) {
			store.removeAll();
		}
	}
});

// 스냅샷 스케줄링 목록 그리드
var MCS_snapshotSchedListGrid = Ext.create('BaseGridPanel', {
	id: 'MCS_snapshotSchedListGrid',
	store: MCS_snapshotSchedListStore,
	multiSelect: false,
	title: lang_mcs_snapshot[82],
	cls: 'line-break',
	height: 300,
	viewConfig: {
		markDirty: false,
		loadMask: true
	},
	listeners: {
		beforeselect: function() {
			return false;
		}
	},
	columns: [
		{
			dataIndex: 'Sched_ID',
			hidden: true
		},
		{
			dataIndex: 'Snapshot_Activate',
			hidden: true
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[1],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Volume_Name',
			renderer: function (value, meta, record, rowIndex, colIndex, store) {
				var first = !rowIndex
							|| value !== store.getAt(rowIndex - 1).get('Volume_Name');

				var last  = rowIndex >= store.getCount() - 1
							|| value !== store.getAt(rowIndex + 1).get('Volume_Name');

				if (first)
				{
					var i = rowIndex + 1, span = 1;

					while (i < store.getCount()
						&& value === store.getAt(i).get('Volume_Name'))
					{
						i++;
						span++;
					}

					var rowHeight = 30;
					var height    = (rowHeight * (i - rowIndex)) + 'px';

					meta.style  = 'height:' + height + ';line-height:' + height + ';';
					meta.tdAttr = 'rowspan = ' + span;
				}
				else
				{
					meta.tdAttr = 'style="display:none;"';
				}

				return first ? value : '';
			},
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[77],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Sched_Name'
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[62],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Period_Unit',
			xtype: 'componentcolumn',
			renderer: function(v, m, r) {
				var period = r.data.Period;

				if (r.data.Period_Unit == 'H')
				{
					period = lang_mcs_snapshot[63];
				}
				else if (r.data.Period_Unit == 'D')
				{
					period = lang_mcs_snapshot[64];
				}
				else if (r.data.Period_Unit == 'W')
				{
					period = lang_mcs_snapshot[65];
				}
				else if (r.data.Period_Unit == 'M')
				{
					period = lang_mcs_snapshot[66];
				}

				return {
					xtype: 'label',
					text: period
				};
			}
		},
		{
			dataIndex: 'Sched_Times',
			hidden: true
		},
		{
			dataIndex: 'Sched_Week_Days',
			hidden: true
		},
		{
			dataIndex: 'Sched_Weeks',
			hidden: true
		},
		{
			flex: 1.5,
			text: lang_mcs_snapshot[7],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Next_Sched',
			xtype: 'componentcolumn',
			renderer: function(v, m, r) {
				var prevSched;

				if (v)
				{
					prevSched = stampToData(v * 1000);
				}

				return {
					xtype: 'label',
					text: prevSched
				};
			}
		},
		{
			flex: 1.5,
			text: lang_mcs_snapshot[67],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Prev_Sched',
			xtype: 'componentcolumn',
			renderer: function(v, m, r) {
				var prevSched;

				if (v)
				{
					prevSched = stampToData(v*1000);
				}

				return {
					xtype: 'label',
					text: prevSched
				};
			}
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[68],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Prev_Sched_Status'
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[3],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Start_Date'
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[4],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'End_Date'
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[8],
			menuDisabled: true,
			sortable: true,
			dataIndex: 'Sched_Enabled',
			xtype: 'componentcolumn',
			renderer: function(value) {
				var schedEnabled = value == 'true' ? 'enable' : 'disable';

				return {
					xtype: 'label',
					text: schedEnabled
				};
			}
		},
		{
			flex: 1,
			text: lang_mcs_snapshot[2],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Snapshot_Count'
		},
		{
			text: lang_mcs_snapshot[9],
			width: 140,
			autoSizeColumn: true,
			minWidth: 140,
			sortable: false,
			menuDisabled: true,
			dataIndex: 'Management',
			xtype: 'componentcolumn',
			renderer: function(value, metaData, record) {
				var scrollMenu = new Ext.menu.Menu();

				scrollMenu.add({
					text: lang_mcv_volume[230],
					handler: function() {
						var me = this;

						me.up('button').setText(lang_mcv_volume[230]);

						Ext.defer(function() {
							me.up('button').setText(lang_mcs_snapshot[9]);
						}, 100);

						waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[80]);

						// 스냅샷 리스트
						GMS.Ajax.request({
							url: '/api/cluster/volume/snapshot/list',
							jsonData: {
								argument: {
									Volume_Name: record.data.Volume_Name,
								}
							},
							callback: function(options, success, response, decoded) {
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								// 예외 처리에 따른 동작
								if (!success || !decoded.success)
									return;

								MCS_snapshotManagementWindow.show();

								// 매뉴얼 스냅샷과 오토 스냅샷을 서로 다르게 로드할 수 있도록 나눔
								var manuals = [];
								var autos   = [];

								for (var i=0; i<decoded.entity.length; i++)
								{
									if (decoded.entity[i].Created_By == null)
									{
										manuals.push(decoded.entity[i]);
										continue;
									}

									autos.push(decoded.entity[i]);
								}

								// 수동 스냅샷
								if (record.data.Sched_Name == lang_mcs_snapshot[79])
								{
									MCS_snapshotManagementWindow.setTitle(
										lang_mcs_snapshot[0]
										+ ' [ ' + record.data.Sched_Name
										+ ' / ' + lang_mcs_snapshot[1]
										+ ': ' + record.data.Volume_Name
										+ ' ]'
									);

									MCS_snapshotManagementStore.loadRawData(manuals);
								}
								else
								{
									MCS_snapshotManagementWindow.setTitle(
										lang_mcs_snapshot[0]
										+ ' [ ' + lang_mcs_snapshot[77]
										+ ': ' + record.data.Sched_Name
										+ ' / ' + lang_mcs_snapshot[1]
										+ ': ' + record.data.Volume_Name
										+ ' ]'
									);

									MCS_snapshotManagementStore.loadRawData(autos);
								}
							},
						});
					}
				});

				// 스케줄링으로 생성된 리스트만 버튼 출력
				if (record.data.Sched_Name !== lang_mcs_snapshot[79])
				{
					// 수정
					scrollMenu.add(
						{
							text: lang_mcs_snapshot[11],
							handler: function() {
								var me = this;

								me.up('button').setText(lang_mcs_snapshot[11]);

								Ext.defer(function() {
									me.up('button').setText(lang_mcs_snapshot[9]);
								}, 100);

								waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[74]);

								// 페이지 로드 시 스냅샷 생성창 초기화
								Ext.getCmp('MCS_snapshotSchedCreatePanel').getForm().reset();
								MCS_snapshotSchedCreateWindow.setTitle(lang_mcs_snapshot[43]);
								Ext.getCmp('MCS_snapshotSchedCreateOKBtn').hide();
								Ext.getCmp('MCS_snapshotSchedModifyOKBtn').show();

								// 반복 주기별
								if (record.data.Period_Unit == 'H')
								{
									// 시단위 설정
									Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitHour').setValue(true);
									Ext.getCmp('MCS_snapshotSchedCreatePeriod').hide();
									Ext.getCmp('MCS_snapshotSchedCreateDay').hide();
									Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
								}
								else if (record.data.Period_Unit == 'D')
								{
									// 일단위 설정
									Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitDay').setValue(true);
									Ext.getCmp('MCS_snapshotSchedCreatePeriod').show();
									Ext.getCmp('MCS_snapshotSchedCreatePeriodLabel').setText(lang_mcs_snapshot[52]);
									Ext.getCmp('MCS_snapshotSchedCreateDay').hide();
									Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
								}
								else if (record.data.Period_Unit == 'W')
								{
									// 주단위 설정
									Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitWeek').setValue(true);
									Ext.getCmp('MCS_snapshotSchedCreatePeriod').show();
									Ext.getCmp('MCS_snapshotSchedCreatePeriodLabel').setText(lang_mcs_snapshot[53]);
									Ext.getCmp('MCS_snapshotSchedCreateDay').show();
									Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
								}
								else if(record.data.Period_Unit == 'M')
								{
									// 월단위 설정
									Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitMonth').setValue(true);
									Ext.getCmp('MCS_snapshotSchedCreatePeriod').show();
									Ext.getCmp('MCS_snapshotSchedCreatePeriodLabel').setText(lang_mcs_snapshot[54]);
									Ext.getCmp('MCS_snapshotSchedCreateDay').show();
									Ext.getCmp('MCS_snapshotSchedCreateWeek').show();
								}

								// 스케줄링 명
								Ext.getCmp('MCS_snapshotSchedCreateSchedName').setValue(record.data.Sched_Name);
								Ext.getCmp('MCS_snapshotSchedCreateSchedName').setDisabled(true);

								// 볼륨 명
								Ext.getCmp('MCS_snapshotSchedCreateVolumeName').setValue(record.data.Volume_Name);
								Ext.getCmp('MCS_snapshotSchedCreateVolumeName').setDisabled(true);

								// 시작 날짜
								Ext.getCmp('MCS_snapshotSchedCreateStartDate').setValue(record.data.Start_Date);

								// 종료 날짜
								Ext.getCmp('MCS_snapshotSchedCreateEndDate').setValue(record.data.End_Date);

								// 스냅샷 활성화
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotActivate').setValue(record.data.Snapshot_Activate);

								// 스케줄링 활성화
								Ext.getCmp('MCS_snapshotSchedCreateScheduleActivate').setValue(record.data.Sched_Enabled);

								// 스케줄링 ID
								Ext.getCmp('MCS_snapshotSchedCreateSchedID').setValue(record.data.Sched_ID);

								// 반복 간격
								Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue(record.data.Period);

								// 수행 시각
								var times = (record.data.Sched_Times).split(',');
								var i = 0;

								MCS_snapshotSchedCreateTimeComboBox.store.each(
									function (record) {
										if (times[i] == record.data.time)
										{
											MCS_snapshotSchedCreateTimeCheckboxGroup.items.items[record.index].setValue('true');
											i++;
										}
									}
								);

								// 수행 요일
								var days = (record.data.Sched_Week_Days).split(',');
								var i = 0;

								MCS_snapshotSchedCreateDayComboBox.store.each(
									function (record) {
										if (days[i] == record.data.Day)
										{
											MCS_snapshotSchedCreateDayCheckboxGroup.items.items[record.index].setValue('true');
											i++;
										}
									}
								);

								// 수행 주간
								var weeks = (record.data.Sched_Weeks).split(',');
								var i = 0;

								MCS_snapshotSchedCreateWeekComboBox.store.each(
									function (record) {
										if (weeks[i] == record.data.Week)
										{
											MCS_snapshotSchedCreateWeekCheckboxGroup.items.items[record.index].setValue('true');
											i++;
										}
									}
								);

								// 최대 생성 스냅샷 개수
								GMS.Ajax.request({
									url: '/api/cluster/volume/snapshot/avail',
									jsonData: {
										argument: {
											Volume_Name: Ext.getCmp('MCS_snapshotSchedCreateVolumeName').getValue()
										}
									},
									callback: function(options, success, response, decoded) {
										if (waitMsgBox)
										{
											waitMsgBox.hide();
											waitMsgBox = null;
										}

										if (!success || !decoded.success)
											return;

										// 설정된 최대 생성 스냅샷 개수
										var snapshotLimit = record.data.Snapshot_Limit;

										// 생성 가능한 스냅샷 개수
										var snapshotAvail = decoded.entity;

										// 최대 생성 스냅샷 개수 최대값
										Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit')
											.setMaxValue(parseInt(snapshotLimit) + parseInt(snapshotAvail));

										// 최대 생성 스냅샷 개수 최소값
										Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit')
											.setMinValue('1');

										// 최대 생성 스냅샷 개수
										Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit')
											.setValue(snapshotLimit);

										MCS_snapshotSchedCreateWindow.show();
									},
								});
							}
						},
						{
							text: lang_mcs_snapshot[10],
							handler: function() {
								var me = this;

								me.up('button').setText(lang_mcs_snapshot[10]);

								Ext.defer(function() {
									me.up('button').setText(lang_mcs_snapshot[9]);
								}, 100);

								Ext.MessageBox.confirm(
									lang_mcs_snapshot[0],
									lang_mcs_snapshot[44],
									function(btn, text) {
										if (btn != 'yes')
											return;

										waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[120]);

										// 볼륨 삭제 유무 확인
										GMS.Ajax.request({
											url: '/api/cluster/schedule/snapshot/delete',
											jsonData: {
												argument: {
													Sched_ID: record.data.Sched_ID
												},
											},
											callback: function(options, success, response, decoded) {
												// 예외 처리에 따른 동작
												if (!success || !decoded.success)
													return;

												Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[45]);

												MCS_snapshotSchedLoad();
											},
										});
									}
								);
							}
						}
					);
				}

				return {
					xtype: 'button',
					text: lang_mcs_snapshot[9],
					menu: scrollMenu
				}
			}
		}
	],
	tbar: [
		{
			text: lang_mcs_snapshot[26],
			id: 'MCS_snapshotSchedCreateBtn',
			iconCls: 'b-icon-schedule-add',
			handler: function() {
				waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[33]);

				// 볼륨 명
				MCS_snapshotVolumeListStore.load({
					callback: function(record, operation, success) {
						if (!success)
						{
							// 예외 처리에 따른 동작
							var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

							if (typeof(jsonText) == 'undefined')
								jsonText = '{}';

							var checkValue = '{'
								+ '"title": "' + lang_mcs_snapshot[0] + '", '
								+ '"content": "' + lang_mcs_snapshot[34] + '", '
								+ '"response": ' + jsonText
							+ '}';

							return exceptionDataCheck(checkValue);
						}

						if (record == '')
						{
							Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[71]);
							return;
						}

						// 스냅샷 스케줄링 생성창 초기화
						MCS_snapshotSchedCreateWindow.animateTarget = Ext.getCmp('MCS_snapshotSchedCreateBtn');
						Ext.getCmp('MCS_snapshotSchedCreateVolumeName').setDisabled(false);
						MCS_snapshotSchedCreateWindow.setTitle(lang_mcs_snapshot[26]);
						Ext.getCmp('MCS_snapshotSchedCreatePanel').getForm().reset();
						Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitHour').setValue(true);
						Ext.getCmp('MCS_snapshotSchedCreatePeriod').hide();
						Ext.getCmp('MCS_snapshotSchedCreateDay').hide();
						Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
						Ext.getCmp('MCS_snapshotSchedCreateOKBtn').show();
						Ext.getCmp('MCS_snapshotSchedModifyOKBtn').hide();

						// 볼륨 명 첫번째 선택
						var volumeNameObj = Ext.getCmp('MCS_snapshotSchedCreateVolumeName');

						volumeNameObj.select(volumeNameObj.getStore().getAt(0).get(volumeNameObj.valueField));

						// 최대 생성 스냅샷 개수
						GMS.Ajax.request({
							url: '/api/cluster/volume/snapshot/avail',
							jsonData: {
								argument: {
									Volume_Name: Ext.getCmp('MCS_snapshotSchedCreateVolumeName').getValue(),
								},
							},
							callback: function(options, success, response, decoded) {
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								if (!success || !decoded.success)
									return;

								// 생성 가능한 스냅샷 개수
								var snapshotAvail = decoded.entity;

								if (snapshotAvail > 0)
								{
									// 최대 생성 스냅샷 개수 최대값
									Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMaxValue(snapshotAvail);
									// 최대 생성 스냅샷 개수 최소값
									Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMinValue('1');
									// 최대 생성 스냅샷 개수
									Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setValue('1');
								}
								else
								{
									// 최대 생성 스냅샷 개수 최대값
									Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMaxValue();
									// 최대 생성 스냅샷 개수 최소값
									Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMinValue();
									// 최대 생성 스냅샷 개수
									Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setValue('0');
								}

								MCS_snapshotSchedCreateWindow.show();
							},
						});
					}
				});
			}
		},
		{
			text: lang_mcs_snapshot[88],
			iconCls: 'b-icon-snapshot-add',
			id: 'MCS_snapshotCreateBtn',
			handler: function()
			{
				waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[114]);

				// 볼륨 풀 리스트 로드
				MCS_snapshotVolumeListStore.load({
					callback: function(record, operation, success) {
						if (success != true)
						{
							// 예외 처리에 따른 동작
							var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

							if (typeof(jsonText) == 'undefined')
								jsonText = '{}';

							var checkValue = '{'
								+ '"title": "' + lang_mcs_snapshot[0] + '", '
								+ '"content": "' + lang_mcs_snapshot[115] + '", '
								+ '"response": ' + jsonText
							+ '}';

							return exceptionDataCheck(checkValue);
						}

						if (record == '')
						{
							Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[116]);
							return;
						}

						MCS_snapshotCreatePanel.getForm().reset();

						// 볼륨 명 첫번째 선택
						var volumeNameObj = Ext.getCmp('MCS_snapshotCreateVolumeName');

						volumeNameObj.select(volumeNameObj.getStore().getAt(0).get(volumeNameObj.valueField));

						// 최대 생성 스냅샷 개수
						GMS.Ajax.request({
							url: '/api/cluster/volume/snapshot/avail',
							jsonData: {
								argument: {
									Volume_Name: Ext.getCmp('MCS_snapshotCreateVolumeName').getValue(),
								},
							},
							callback: function(options, success, response, decoded) {
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								if (!success || !decoded.success)
									return;

								MCS_snapshotCreateWindow.animateTarget
									= Ext.getCmp('MCS_snapshotCreateBtn');

								MCS_snapshotCreateWindow.show();

								// 생성 가능한 스냅샷 개수
								Ext.getCmp('MCS_snapshotCreateAvail')
									.setText(decoded.entity);
							},
						});
					}
				});
			}
		}
	]
});

/*
 * stamp를 일자(YYYY-MM-DD hh:mm::ss)형식으로 변경하는 함수
 */
function stampToData(stamp)
{
	var now = new Date(stamp);
	var nowYear = now.getFullYear();
	var nowMonth = (now.getMonth()+1);
	var nowDate = now.getDate();
	var nowHours = now.getHours();
	var nowMinutes = now.getMinutes();
	var nowSeconds = now.getSeconds();

	if ((""+nowMonth).length == 1)
		nowMonth = "0" + nowMonth;

	if ((""+nowDate).length == 1)
		nowDate = "0" + nowDate;

	if ((""+nowHours).length == 1)
		nowHours = "0" + nowHours;

	if ((""+nowMinutes).length == 1)
		nowMinutes = "0" + nowMinutes;

	if ((""+nowSeconds).length == 1)
		nowSeconds = "0" + nowSeconds;

	if (isNaN(nowYear))
	{
		clearInterval(_nowCurrentrVar);
		return false;
	}
	else
	{
		return nowYear + "-" + nowMonth + "-" + nowDate
				+ " " + nowHours + ":" + nowMinutes + ":" + nowSeconds;
	}
};

/*
 * 스냅샷 스케줄링 생성 수행시각 체크박스
 */
// 스냅샷 스케줄링 생성 수행시각 스토어
var MCS_snapshotSchedCreateTimeStore = new Ext.data.ArrayStore({
	fields: ['time'],
	data: [
		['00'], ['01'], ['02'], ['03'], ['04'], ['05'],
		['06'], ['07'], ['08'], ['09'], ['10'], ['11'],
		['12'], ['13'], ['14'], ['15'], ['16'], ['17'],
		['18'], ['19'], ['20'], ['21'], ['22'], ['23']
	]
});

// 스냅샷 스케줄링 생성 수행시각
var MCS_snapshotSchedCreateTimeComboBox = new Ext.form.ComboBox({
	typeAhead: true,
	triggerAction: 'all',
	mode: 'local',
	store: MCS_snapshotSchedCreateTimeStore,
	valueField: 'time',
	displayField: 'time'
});

// 스냅샷 스케줄링 생성 수행시각 체크박스 아이템
var timeItems = [];

MCS_snapshotSchedCreateTimeComboBox.store.each(
	function (record) {
		timeItems.push({
			boxLabel: record.get(MCS_snapshotSchedCreateTimeComboBox.displayField),
			handler: function(record) {
				// 스냅샷 생성 시간
				var j = 0;
				var timesArr = new Array();

				for (var i = 0; i < 24; i++)
				{
					// 체크박스 체크 여부
					if (MCS_snapshotSchedCreateTimeCheckboxGroup.items.items[i].checked != true)
						continue;

					timesArr[j++] = MCS_snapshotSchedCreateTimeCheckboxGroup.items.items[i].boxLabel;
				}

				if (j == 24)
				{
					Ext.getCmp('MCS_snapshotSchedCreateTimeCheckAll').hide();
					Ext.getCmp('MCS_snapshotSchedCreateTimeCheckClear').show();
				}
				else
				{
					Ext.getCmp('MCS_snapshotSchedCreateTimeCheckAll').show();
					Ext.getCmp('MCS_snapshotSchedCreateTimeCheckClear').hide();
				}

				Sched_Times = timesArr.join();

				var me = this;

				if (Sched_Times == '')
				{
					Sched_Times = lang_mcs_snapshot[58];
				}

				me.up('button').setText(Sched_Times);
			}
		}
	);
});

// 스냅샷 스케줄링 생성 수행 시각 체크박스 그룹
var MCS_snapshotSchedCreateTimeCheckboxGroup = new Ext.form.CheckboxGroup({
	xtype: 'checkboxgroup',
	columns: 4,
	items: timeItems,
	style: { marginLeft: '30px' }
});

// 스냅샷 스케줄링 생성 수행 시각 메뉴
var MCS_snapshotSchedCreateTimeMenu = Ext.create('Ext.menu.Menu', {
	id: 'MCS_snapshotSchedCreateTimeMenu',
	width: '300px',
	items: MCS_snapshotSchedCreateTimeCheckboxGroup
});

/*
 * 스냅샷 스케줄링 생성 수행요일 체크박스
 */
// 스냅샷 스케줄링 생성 수행요일 스토어
var MCS_snapshotSchedCreateDayStore = new Ext.data.ArrayStore({
	fields: ['Day', 'DayType'],
	data: [
		['MON', lang_mcs_snapshot[17]],
		['TUE', lang_mcs_snapshot[18]],
		['WED', lang_mcs_snapshot[19]],
		['THU', lang_mcs_snapshot[20]],
		['FRI', lang_mcs_snapshot[21]],
		['SAT', lang_mcs_snapshot[22]],
		['SUN', lang_mcs_snapshot[16]],
	]
});

// 스냅샷 스케줄링 생성 수행요일
var MCS_snapshotSchedCreateDayComboBox = new Ext.form.ComboBox({
	typeAhead: true,
	triggerAction: 'all',
	mode: 'local',
	store: MCS_snapshotSchedCreateDayStore,
	valueField: 'Day',
	displayField: 'DayType'
});

// 스냅샷 스케줄링 생성 수행요일 체크박스
var dayItems = [];

MCS_snapshotSchedCreateDayComboBox.store.each(
	function (record) {
		dayItems.push({
			boxLabel: record.get(MCS_snapshotSchedCreateDayComboBox.displayField),
			inputValue: record.get(MCS_snapshotSchedCreateDayComboBox.valueField),
			handler: function() {
				// 스냅샷 생성 요일
				var daysArr = new Array();
				var daysValueArr = new Array();
				var j = 0;

				for (var i = 0; i < 7; i++)
				{
					// 월~일까지 체크박스 체크 여부
					if (MCS_snapshotSchedCreateDayCheckboxGroup.items.items[i].checked != true)
						continue;

					daysArr[j]      = MCS_snapshotSchedCreateDayCheckboxGroup.items.items[i].boxLabel;
					daysValueArr[j] = MCS_snapshotSchedCreateDayCheckboxGroup.items.items[i].inputValue;

					j++;
				}

				if (j == 7)
				{
					Ext.getCmp('MCS_snapshotSchedCreateDayCheckAll').hide();
					Ext.getCmp('MCS_snapshotSchedCreateDayCheckClear').show();
				}
				else
				{
					Ext.getCmp('MCS_snapshotSchedCreateDayCheckAll').show();
					Ext.getCmp('MCS_snapshotSchedCreateDayCheckClear').hide();
				}

				var Sched_Days = daysArr.join();
				var Sched_Days_Value = daysValueArr.join();

				if (Sched_Days == '')
				{
					Sched_Days = lang_mcs_snapshot[38];
				}

				var me = this;

				me.up('button').setText(Sched_Days);
				Ext.getCmp('MCS_snapshotSchedCreateDayValue').setValue(Sched_Days_Value);
			}
		});
	}
);

// 스냅샷 스케줄링 생성 수행요일 체크박스그룹
var MCS_snapshotSchedCreateDayCheckboxGroup = new Ext.form.CheckboxGroup({
	xtype: 'checkboxgroup',
	columns: 4,
	items: dayItems,
	style: { marginLeft: '30px' }
});


// 스냅샷 스케줄링 생성 수행요일 메뉴
var MCS_snapshotSchedCreateDayMenu = Ext.create('Ext.menu.Menu', {
	id: 'MCS_snapshotSchedCreateDayMenu',
	items: MCS_snapshotSchedCreateDayCheckboxGroup,
	width: '300px'
});

/*
 * 스냅샷 스케줄링 생성 수행주간 체크박스
 */
// 스냅샷 스케줄링 생성 수행주간 스토어
var MCS_snapshotSchedCreateWeekStore = new Ext.data.ArrayStore({
	fields: ['Week', 'WeekType'],
	data: [
		['1', '1'+lang_mcs_snapshot[14]],
		['2', '2'+lang_mcs_snapshot[14]],
		['3', '3'+lang_mcs_snapshot[14]],
		['4', '4'+lang_mcs_snapshot[14]],
		['5', '5'+lang_mcs_snapshot[14]],
		['6', '6'+lang_mcs_snapshot[14]],
	]
});

// 스냅샷 스케줄링 생성 수행주간
var MCS_snapshotSchedCreateWeekComboBox = new Ext.form.ComboBox({
	typeAhead: true,
	triggerAction: 'all',
	mode: 'local',
	store: MCS_snapshotSchedCreateWeekStore,
	valueField: 'Week',
	displayField: 'WeekType'
});

// 스냅샷 스케줄링 생성 수행 주간 체크박스
var weekItems = [];

MCS_snapshotSchedCreateWeekComboBox.store.each(
	function (record) {
		weekItems.push({
			boxLabel: record.get(MCS_snapshotSchedCreateWeekComboBox.displayField),
			inputValue: record.get(MCS_snapshotSchedCreateWeekComboBox.valueField),
			handler: function() {
				// 스냅샷 생성 요일
				var weekArr = new Array();
				var weeksValueArr = new Array();
				var j = 0;

				for (var i = 0; i < 6; i++)
				{
					if (MCS_snapshotSchedCreateWeekCheckboxGroup.items.items[i].checked != true)
						continue;

					// 1주~6주까지 체크박스 체크 여부
					weekArr[j]       = MCS_snapshotSchedCreateWeekCheckboxGroup.items.items[i].boxLabel;
					weeksValueArr[j] = MCS_snapshotSchedCreateWeekCheckboxGroup.items.items[i].inputValue;

					j++;
				}

				if (j == 6)
				{
					Ext.getCmp('MCS_snapshotSchedCreateWeekCheckAll').hide();
					Ext.getCmp('MCS_snapshotSchedCreateWeekCheckClear').show();
				}
				else
				{
					Ext.getCmp('MCS_snapshotSchedCreateWeekCheckAll').show();
					Ext.getCmp('MCS_snapshotSchedCreateWeekCheckClear').hide();
				}

				var Sched_Weeks = weekArr.join();
				var Sched_Weeks_Value = weeksValueArr.join();

				if (Sched_Weeks == '')
				{
					Sched_Weeks = lang_mcs_snapshot[59];
				}

				var me = this;

				me.up('button').setText(Sched_Weeks);
				Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue(Sched_Weeks_Value);
			}
		});
	}
);

// 스냅샷 스케줄링 생성 수행 주간 체크박스 그룹
var MCS_snapshotSchedCreateWeekCheckboxGroup = new Ext.form.CheckboxGroup({
	xtype: 'checkboxgroup',
	columns: 4,
	items: weekItems,
	style: { marginLeft: '30px' }
});

// 스냅샷 스케줄링 생성 수행주간 메뉴
var MCS_snapshotSchedCreateWeekMenu = Ext.create('Ext.menu.Menu', {
	id: 'MCS_snapshotSchedCreateWeekMenu',
	items: MCS_snapshotSchedCreateWeekCheckboxGroup,
	width: '300px'
});

// 스냅샷 스케줄링 생성 PANEL
var MCS_snapshotSchedCreatePanel = Ext.create('BaseFormPanel', {
	id: 'MCS_snapshotSchedCreatePanel',
	frame: false,
	region: 'center',
	jsonSubmit: true,
	items: [
		{
			xtype: 'textfield',
			id: 'MCS_snapshotSchedCreateSchedID',
			name: 'Sched_ID',
			hidden: true
		},
		{
			xtype: 'textfield',
			id: 'MCS_snapshotSchedCreateSchedName',
			name: 'Sched_Name',
			fieldLabel: lang_mcs_snapshot[77],
			labelWidth: 130,
			vtype: 'reg_ID',
			allowBlank: false,
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'BaseComboBox',
			fieldLabel: lang_mcs_snapshot[27],
			id: 'MCS_snapshotSchedCreateVolumeName',
			name: 'Volume_Name',
			style: { marginBottom: '20px' },
			labelWidth: 130,
			store: MCS_snapshotVolumeListStore,
			displayField: 'Volume_Name',
			valueField: 'Volume_Name',
			listeners: {
				select: function(grid, record, index, eOpts) {
					GMS.Ajax.request({
						url: '/api/cluster/volume/snapshot/avail',
						jsonData: {
							argument: {
								Volume_Name: record[0].data.Volume_Name
							}
						},
						callback: function(options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							// 생성 가능한 스냅샷 개수
							var snapshotAvail = decoded.entity;

							if (snapshotAvail > 0)
							{
								// 최대 생성 스냅샷 개수 최대값
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMaxValue(snapshotAvail);
								// 최대 생성 스냅샷 개수 최소값
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMinValue('1');
								// 최대 생성 스냅샷 개수
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setValue('1');
							}
							else
							{
								// 최대 생성 스냅샷 개수 최대값
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMaxValue();
								// 최대 생성 스냅샷 개수 최소값
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setMinValue();
								// 최대 생성 스냅샷 개수
								Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').setValue('0');
							}
						},
					});
				}
			}
		},
		{
			xtype: 'BasePanel',
			id: 'MCS_snapshotSchedCreatePeriod',
			layout: 'hbox',
			maskOnDisable: false,
			bodyStyle: 'padding: 0;',
			style: { marginBottom: '20px' },
			hidden: true,
			items: [
				{
					xtype: 'numberfield',
					id: 'MCS_snapshotSchedCreatePeriodField',
					name: 'Period',
					fieldLabel: lang_mcs_snapshot[6],
					value: '',
					minValue: 1,
					maxValue: 99
				},
				{
					xtype: 'label',
					id: 'MCS_snapshotSchedCreatePeriodLabel',
					text: lang_mcs_snapshot[52],
					disabledCls: 'm-label-disable-mask',
					style: { marginTop: '5px', marginLeft: '10px' }
				}
			]
		},
		{
			xtype: 'BasePanel',
			id: 'MCS_snapshotSchedCreateWeek',
			layout: 'hbox',
			maskOnDisable: false,
			bodyStyle: 'padding: 0;',
			style: { marginBottom: '20px' },
			hidden: true,
			items: [
				{
					xtype: 'label',
					text: lang_mcs_snapshot[57]+':',
					disabledCls: 'm-label-disable-mask',
					style: { marginTop: '5px' },
					width: 135
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateWeekGroup',
					text: lang_mcs_snapshot[59],
					width: 300,
					menu: MCS_snapshotSchedCreateWeekMenu
				},
				{
					xtype: 'textfield',
					id: 'MCS_snapshotSchedCreateWeekValue',
					name: 'Sched_Weeks',
					value: '',
					hidden: true
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateWeekCheckAll',
					text: lang_mcs_snapshot[69],
					style: { marginLeft: '5px' },
					listeners: {
						click: function() {
							var weekGroup = MCS_snapshotSchedCreateWeekCheckboxGroup.items;

							for (var i = 0; i < weekGroup.length; i++)
							{
								Ext.getCmp(weekGroup.keys[i]).setValue('true');
							}
						}
					}
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateWeekCheckClear',
					text: lang_mcs_snapshot[70],
					style: { marginLeft: '5px' },
					hidden: true,
					listeners: {
						click: function () {
							var weekGroup = MCS_snapshotSchedCreateWeekCheckboxGroup.items;

							for (var i = 0; i < weekGroup.length; i++)
							{
								Ext.getCmp(weekGroup.keys[i]).setValue('false');
							}
						}
					}
				}
			]
		},
		{
			xtype: 'BasePanel',
			id: 'MCS_snapshotSchedCreateDay',
			layout: 'hbox',
			maskOnDisable: false,
			bodyStyle: 'padding: 0;',
			style: { marginBottom: '20px' },
			hidden: true,
			items: [
				{
					xtype: 'label',
					text: lang_mcs_snapshot[56]+':',
					disabledCls: 'm-label-disable-mask',
					style: { marginTop: '5px' },
					width: 135
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateDayGroup',
					text: lang_mcs_snapshot[38],
					width: 300,
					menu: MCS_snapshotSchedCreateDayMenu
				},
				{
					xtype: 'textfield',
					id: 'MCS_snapshotSchedCreateDayValue',
					name: 'Sched_Week_Days',
					value: '',
					hidden: true
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateDayCheckAll',
					text: lang_mcs_snapshot[69],
					style: {marginLeft: '5px'},
					listeners: {
						click: function () {
							var dayGroup = MCS_snapshotSchedCreateDayCheckboxGroup.items;

							for (var i = 0; i < dayGroup.length; i++)
							{
								Ext.getCmp(dayGroup.keys[i]).setValue('true');
							}
						}
					}
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateDayCheckClear',
					text: lang_mcs_snapshot[70],
					style: {marginLeft: '5px'},
					hidden: true,
					listeners: {
						click: function () {
							var dayGroup = MCS_snapshotSchedCreateDayCheckboxGroup.items;

							for (var i = 0; i < dayGroup.length; i++)
							{
								Ext.getCmp(dayGroup.keys[i]).setValue('false');
							}
						}
					}
				}
			]
		},
		{
			xtype: 'BasePanel',
			layout: 'hbox',
			maskOnDisable: false,
			bodyStyle: 'padding: 0;',
			style: { marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					text: lang_mcs_snapshot[51]+':',
					disabledCls: 'm-label-disable-mask',
					style: { marginTop: '5px' },
					width: 135
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateTimeGroup',
					text: lang_mcs_snapshot[58],
					autoWidthComponents: false,
					minWidth: 300,
					menu: MCS_snapshotSchedCreateTimeMenu,
					listeners: {
						menushow: function (menu) {
							var width = MCS_snapshotSchedCreateTimeMenu.up('button').getWidth();

							MCS_snapshotSchedCreateTimeMenu.setWidth(width);
						}
					}
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateTimeCheckAll',
					text: lang_mcs_snapshot[69],
					style: { marginLeft: '5px' },
					listeners: {
						click: function () {
							var timeGroup = MCS_snapshotSchedCreateTimeCheckboxGroup.items;

							for (var i = 0; i < timeGroup.length; i++)
							{
								Ext.getCmp(timeGroup.keys[i]).setValue('true');
							}
						}
					}
				},
				{
					xtype: 'button',
					id: 'MCS_snapshotSchedCreateTimeCheckClear',
					text: lang_mcs_snapshot[70],
					style: { marginLeft: '5px' },
					hidden: true,
					listeners: {
						click: function () {
							var TimeGroup = MCS_snapshotSchedCreateTimeCheckboxGroup.items;

							for (var i = 0; i < TimeGroup.length; i++)
							{
								Ext.getCmp(TimeGroup.keys[i]).setValue('false');
							}
						}
					}
				}
			]
		},
		{
			xtype: 'datefield',
			id: 'MCS_snapshotSchedCreateStartDate',
			name: 'Start_Date',
			fieldLabel: lang_mcs_snapshot[3],
			labelWidth: 130,
			style: { marginBottom: '20px' },
			format: 'Y/m/d',
			altFormats: 'Y/m/d',
			allowBlank: false,
			value: new Date(),
			listeners: {
				blur: function() {
					if (Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue())
					{
						if (Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue()
							- Ext.getCmp('MCS_snapshotSchedCreateStartDate').getValue() < 0)
						{
							// 시작 날짜가 종료 날짜보다 이후일 때
							Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[61]);

							Ext.getCmp('MCS_snapshotSchedCreateStartDate')
								.setValue(Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue());
						}
					}
				}
			}
		},
		{
			xtype: 'datefield',
			id: 'MCS_snapshotSchedCreateEndDate',
			name: 'End_Date',
			fieldLabel: lang_mcs_snapshot[4],
			labelWidth: 130,
			style: { marginBottom: '20px' },
			format: 'Y/m/d',
			altFormats: 'Y/m/d',
			value: '',
			listeners: {
				blur: function() {
					if (Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue())
					{
						if (Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue()
							- Ext.getCmp('MCS_snapshotSchedCreateStartDate').getValue() < 0)
						{
							// 종료 날짜가 시작 날짜보다 이전일 때
							Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[60]);

							Ext.getCmp('MCS_snapshotSchedCreateEndDate')
								.setValue(Ext.getCmp('MCS_snapshotSchedCreateStartDate').getValue());
						}
					}
				}
			}
		},
		{
			xtype: 'numberfield',
			fieldLabel: lang_mcs_snapshot[35],
			id: 'MCS_snapshotSchedCreateSnapshotLimit',
			name: 'Snapshot_Limit',
			value: '1',
			minValue: 1,
			maxValue: 256,
			style: { marginBottom: '20px' },
			validator: function(value) {
				if (this.maxValue == '1.7976931348623157e+308')
				{
					return lang_mcs_snapshot[76];
				}
				else
				{
					return true;
				}
			}
		},
		{
			xtype: 'checkbox',
			id: 'MCS_snapshotSchedCreateScheduleActivate',
			fieldLabel: lang_mcs_snapshot[36],
			checked: true,
			style: { marginBottom: '20px' }
		},
		{
			xtype: 'checkbox',
			id: 'MCS_snapshotSchedCreateSnapshotActivate',
			fieldLabel: lang_mcs_snapshot[37],
			checked: false
		}
	]
});

// 스냅샷 스케줄링 생성 라디오 버튼
var MCS_snapshotSchedCreatePeriodUnitRadioGroup = new Ext.form.RadioGroup({
	id: 'MCS_snapshotSchedCreatePeriodUnitRadioGroup',
	xtype: 'radiogroup',
	region: 'west',
	layout: 'vbox',
	bodyStyle: 'padding:0;',
	style: {
		backgroundColor: '#ececec',
		borderRight: '1px solid #bcb1b0'
	},
	width: 150,
	items: [
		{
			boxLabel: lang_mcs_snapshot[47],
			id: 'MCS_snapshotSchedCreatePeriodUnitHour',
			name: 'rb',
			inputValue: 'H',
			checked: true,
			style: {
				marginTop: '20px',
				marginLeft: '10px',
				marginRight:'10px'
			}
		},
		{
			boxLabel: lang_mcs_snapshot[48],
			id: 'MCS_snapshotSchedCreatePeriodUnitDay',
			name: 'rb',
			inputValue: 'D',
			style: {
				marginTop: '20px',
				marginLeft: '10px',
				marginRight:'10px'
			}
		},
		{
			boxLabel: lang_mcs_snapshot[49],
			id: 'MCS_snapshotSchedCreatePeriodUnitWeek',
			name: 'rb',
			inputValue: 'W',
			style: {
				marginTop: '20px',
				marginLeft: '10px',
				marginRight:'10px'
			}
		},
		{
			boxLabel: lang_mcs_snapshot[50],
			id: 'MCS_snapshotSchedCreatePeriodUnitMonth',
			name: 'rb',
			inputValue: 'M',
			style: {
				marginTop: '20px',
				marginLeft: '10px',
				marginRight:'10px'
			}
		}
	],
	listeners: {
		change: function(radiogroup, radio) {
			if (radio.rb == 'H')
			{
				Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue('');
				Ext.getCmp('MCS_snapshotSchedCreatePeriod').hide();
				Ext.getCmp('MCS_snapshotSchedCreateDay').hide();
				Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
			}
			else if (radio.rb == 'D')
			{
				Ext.getCmp('MCS_snapshotSchedCreatePeriod').show();
				Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue('2');
				Ext.getCmp('MCS_snapshotSchedCreatePeriodLabel').setText(lang_mcs_snapshot[52]);
				Ext.getCmp('MCS_snapshotSchedCreateDay').hide();
				Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
			}
			else if (radio.rb == 'W')
			{
				Ext.getCmp('MCS_snapshotSchedCreatePeriod').show();
				Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue('4');
				Ext.getCmp('MCS_snapshotSchedCreatePeriodLabel').setText(lang_mcs_snapshot[53]);
				Ext.getCmp('MCS_snapshotSchedCreateDay').show();
				Ext.getCmp('MCS_snapshotSchedCreateWeek').hide();
			}
			else if (radio.rb == 'M')
			{
				Ext.getCmp('MCS_snapshotSchedCreatePeriod').show();
				Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue('2');
				Ext.getCmp('MCS_snapshotSchedCreatePeriodLabel').setText(lang_mcs_snapshot[54]);
				Ext.getCmp('MCS_snapshotSchedCreateDay').show();
				Ext.getCmp('MCS_snapshotSchedCreateWeek').show();
			}
		}
	}
});

// 스냅샷 스케줄링 생성 WINDOW
var MCS_snapshotSchedCreateWindow = Ext.create('BaseWindowPanel', {
	id: 'MCS_snapshotSchedCreateWindow',
	title: lang_mcs_snapshot[26],
	maximizable: false,
	autoHeight: true,
	width: 790,
	height: 570,
	layout: 'border',
	tools:[
		{
			type: 'help',
			handler: function (event, toolEl, panel) {
				manualWindowOpen('clusterVolume','#2422-스냅샷-스케줄링-생성');
			}
		}
	],
	items: [
		MCS_snapshotSchedCreatePeriodUnitRadioGroup,
		MCS_snapshotSchedCreatePanel
	],
	buttons: [
		{
			text: lang_mcs_snapshot[32],
			id: 'MCS_snapshotSchedCreateOKBtn',
			width: 70,
			disabled: false,
			handler: function() { MCS_snapshotSchedCreateWindowBtn(); }
		},
		{
			text: lang_mcs_snapshot[29],
			id: 'MCS_snapshotSchedModifyOKBtn',
			width: 70,
			disabled: false,
			handler: function() { MCS_snapshotSchedModifyWindowBtn(); }
		}
	]
});

// 스냅샷 스케줄링 생성 버튼 함수
function MCS_snapshotSchedCreateWindowBtn()
{
	// 스케줄링 명
	if (!Ext.getCmp('MCS_snapshotSchedCreateSchedName').isValid())
	{
		return false;
	}

	// 스케줄링 명 중복 확인
	var schedName = Ext.getCmp('MCS_snapshotSchedCreateSchedName').getValue();
	var schedNameCheck = true;

	MCS_snapshotSchedListStore.each(
		function(record) {
			if (record.data.Sched_Name == schedName)
			{
				schedNameCheck = false;
				return false;
			}
		}
	);

	if (!schedNameCheck)
	{
		Ext.MessageBox.alert(
			lang_mcs_snapshot[0],
			lang_mcs_snapshot[78].replace('@', schedName));

		return false;
	}

	// 시작 날짜
	if (!Ext.getCmp('MCS_snapshotSchedCreateStartDate').validate())
	{
		return false;
	}

	// 최대 생성 스냅샷 개수
	if (!Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').validate())
	{
		return false;
	}

	if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'M')
	{
		// 월 단위 설정일 때 필수 입력
		if (Ext.getCmp('MCS_snapshotSchedCreateWeekValue').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[59]);
			return false;
		}

		if (Ext.getCmp('MCS_snapshotSchedCreateDayValue').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[38]);
			return false;
		}
	}

	if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'W')
	{
		// 주단위 설정일 때 필수 입력
		if (Ext.getCmp('MCS_snapshotSchedCreateDayValue').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[38]);
			return false;
		}

		Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue('');
	}

	if (Ext.getCmp('MCS_snapshotSchedCreateTimeGroup').getText()
		== lang_mcs_snapshot[58])
	{
		Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[58]);
		return false;
	}

	if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'D'
		|| MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'H')
	{
		// 시단위, 일단위 설정일 때 필수 입력
		if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'H')
		{
			Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue('');
		}

		Ext.getCmp('MCS_snapshotSchedCreateDayValue').setValue('');
		Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue('') ;
	}

	waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[39]);

	GMS.Ajax.request({
		url: '/api/cluster/schedule/snapshot/create',
		method: 'POST',
		jsonData: {
			argument: {
				Sched_Name: Ext.getCmp('MCS_snapshotSchedCreateSchedName').getValue(),
				Volume_Name: Ext.getCmp('MCS_snapshotSchedCreateVolumeName').getValue(),
				Period: Ext.getCmp('MCS_snapshotSchedCreatePeriodField').getValue(),
				Period_Unit: Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitRadioGroup').getValue().rb,
				Sched_Enabled: Ext.getCmp('MCS_snapshotSchedCreateScheduleActivate').checked ? 'true' : 'false',
				Sched_Times: Ext.getCmp('MCS_snapshotSchedCreateTimeGroup').getText(),
				Sched_Week_Days: Ext.getCmp('MCS_snapshotSchedCreateDayValue').getValue(),
				Sched_Weeks: Ext.getCmp('MCS_snapshotSchedCreateWeekValue').getValue(),
				Start_Date: Ext.Date.format(Ext.getCmp('MCS_snapshotSchedCreateStartDate').getValue(), 'Y/m/d'),
				End_Date: Ext.Date.format(Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue(), 'Y/m/d'),
				Snapshot_Activate : Ext.getCmp('MCS_snapshotSchedCreateSnapshotActivate').checked ? 'true' : 'false',
				Snapshot_Limit: Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').getValue(),
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			// 생성창 닫기
			MCS_snapshotSchedCreateWindow.hide();

			// 메세지 출력
			var msg = decoded.msg ? decoded.msg : lang_mcs_snapshot[30];

			Ext.MessageBox.alert(lang_mcs_snapshot[0], msg);

			// 스냅샷 스케줄링 리스트 로드
			MCS_snapshotSchedLoad();

			// 스냅샷 스케줄링 생성 창 초기화
			Ext.getCmp('MCS_snapshotSchedCreateDayValue').setValue('');
			Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue('') ;
		}
	});
}

// 스냅샷 스케줄링 수정 버튼 함수
function MCS_snapshotSchedModifyWindowBtn()
{
	// 스케줄링 명
	if (!Ext.getCmp('MCS_snapshotSchedCreateSchedName').isValid())
	{
		return false;
	}

	// 시작 날짜
	if (!Ext.getCmp('MCS_snapshotSchedCreateStartDate').validate())
	{
		return false;
	}

	// 최대 생성 스냅샷 개수
	if (!Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').validate())
	{
		return false;
	}

	if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'M')
	{
		// 월단위 설정일 때 필수 입력
		if (Ext.getCmp('MCS_snapshotSchedCreateWeekValue').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[59]);
			return false;
		}

		if (Ext.getCmp('MCS_snapshotSchedCreateDayValue').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[38]);
			return false;
		}
	}

	if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'W')
	{
		// 주단위 설정일 때 필수 입력
		if (Ext.getCmp('MCS_snapshotSchedCreateDayValue').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[38]);
			return false;
		}

		Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue('') ;
	}

	if (Ext.getCmp('MCS_snapshotSchedCreateTimeGroup').getText() == lang_mcs_snapshot[58])
	{
		Ext.MessageBox.alert(lang_mcs_snapshot[0], lang_mcs_snapshot[58]);
		return false;
	}

	if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'D'
		|| MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'H')
	{
		// 시단위, 일단위 설정일 때 필수 입력
		if (MCS_snapshotSchedCreatePeriodUnitRadioGroup.getValue().rb == 'H')
		{
			Ext.getCmp('MCS_snapshotSchedCreatePeriodField').setValue('');
		}

		Ext.getCmp('MCS_snapshotSchedCreateDayValue').setValue('');
		Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue('') ;
	}

	waitWindow(lang_mcs_snapshot[0], lang_mcs_snapshot[40]);

	GMS.Ajax.request({
		url: '/api/cluster/schedule/snapshot/change',
		method: 'POST',
		jsonData: {
			argument: {
				Sched_ID: Ext.getCmp('MCS_snapshotSchedCreateSchedID').getValue(),
				Sched_Name: Ext.getCmp('MCS_snapshotSchedCreateSchedName').getValue(),
				Period: Ext.getCmp('MCS_snapshotSchedCreatePeriodField').getValue(),
				Period_Unit: Ext.getCmp('MCS_snapshotSchedCreatePeriodUnitRadioGroup').getValue().rb,
				Sched_Enabled: Ext.getCmp('MCS_snapshotSchedCreateScheduleActivate').checked ? 'true' : 'false',
				Sched_Times: Ext.getCmp('MCS_snapshotSchedCreateTimeGroup').getText(),
				Sched_Week_Days: Ext.getCmp('MCS_snapshotSchedCreateDayValue').getValue(),
				Sched_Weeks: Ext.getCmp('MCS_snapshotSchedCreateWeekValue').getValue(),
				Start_Date: Ext.Date.format(Ext.getCmp('MCS_snapshotSchedCreateStartDate').getValue(), 'Y/m/d'),
				End_Date: Ext.Date.format(Ext.getCmp('MCS_snapshotSchedCreateEndDate').getValue(), 'Y/m/d'),
				Snapshot_Activate : Ext.getCmp('MCS_snapshotSchedCreateSnapshotActivate').checked ? 'true' : 'false',
				Snapshot_Limit: Ext.getCmp('MCS_snapshotSchedCreateSnapshotLimit').getValue(),
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			// 생성창 닫기
			MCS_snapshotSchedCreateWindow.hide();

			// 메세지 출력
			var msg = decoded.msg ? decoded.msg : lang_mcs_snapshot[41];

			Ext.MessageBox.alert(lang_mcs_snapshot[0], msg);

			// 스냅샷 스케줄링 리스트 로드
			MCS_snapshotSchedLoad();

			// 스냅샷 스케줄링 생성 창 초기화
			Ext.getCmp('MCS_snapshotSchedCreateDayValue').setValue('');
			Ext.getCmp('MCS_snapshotSchedCreateWeekValue').setValue('') ;
		}
	});
}

// 클러스터 볼륨 관리 -> 스냅샷 스케줄링 관리
Ext.define('/admin/js/manager_cluster_snapshot', {
	extend: 'BasePanel',
	id: 'manager_cluster_snapshot',
	bodyStyle: 'padding: 0;',
	load: function() {
		MCS_snapshotSchedListStore.removeAll();
		MCS_snapshotSchedLoad();
	},
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			flex: 1,
			bodyStyle: 'padding: 20px;',
			items: [MCS_snapshotSchedListGrid]
		}
	]
});
