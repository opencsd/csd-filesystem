/*
 * 페이지 로드 시 실행 함수
 */
function MCV_volumePoolLoad()
{
	// record 정보 초기화 후 리로딩
	MCV_volumePoolStore.removeAll();
	MCV_volumePoolStore.clearFilter();
	MCV_volumeThinPoolStore.removeAll();
	MCV_volumeThinPoolStore.clearFilter();

	// 클러스터 볼륨 풀 목록 그리드 로드
	MCV_volumePoolStore.load();

	// thin 볼륨 풀 목록 숨김
	MCV_volumePoolStore.filter(function (r) {
		var Pool_Name = r.get('Pool_Name');
		if (Pool_Name.slice(0,3) != 'tp_' )
		{
			return true;
		}
		else
		{
			MCV_volumeThinPoolStore.add(r.copy().data);
		}
	});
};

/*
 * 클러스터 볼륨 풀 목록
 */
// 클러스터 볼륨 풀 목록 모델
Ext.define(
	'MCV_volumePoolModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Pool_Name', 'Pool_Purpose', 'Pool_Type', 'Pool_Status',
			'Pool_Size', 'Pool_Used', 'Management', 'Node_List',
			'Nodes','Provision', 'Thin_Allocation', 'Base_Pool', 'Volume_Count',
			'External_IP', 'External_Type'
		]
	}
);

var MCV_volumeThinPoolStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumePoolModel',
	}
);

// 클러스터 볼륨 풀 목록 스토어
var MCV_volumePoolStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumePoolModel',
		sorters: [
			{ property: 'Pool_Name', direction: 'ASC' },
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/volume/pool/list',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Pool_Name',
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 예외 처리에 따른 동작
				if (success !== true)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcv_volumePool[0] + '",'
						+ '"content": "' + lang_mcv_volumePool[24] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}
			}
		}
	}
);

// 클러스터 볼륨 풀 목록 그리드
var MCV_volumePoolGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumePoolGrid',
		store: MCV_volumePoolStore,
		multiSelect: false,
		title: lang_mcv_volumePool[0],
		cls: 'line-break',
		height: 300,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: true,
			mode: 'SINGLE',
			listeners: {
				selectall: function () {
					MCV_volumePoolSelect('selectAll');
				},
				deselectall: function () {
					MCV_volumePoolSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mcv_volumePool[1],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Pool_Name'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[111],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Pool_Type'
			},
//			{
//				flex: 1,
//				text: lang_mcv_volumePool[11],
//				sortable: true,
//				menuDisabled: true,
//				dataIndex: 'Pool_Purpose',
//				renderer: function (v, m, r) {
//					return lang_mcv_volumePool[45];
//
//					/*
//					if (v == 'for_tiering')
//						return lang_mcv_volumePool[44]
//					else if (v == 'for_data')
//						return lang_mcv_volumePool[45]
//					*/
//				}
//			},
			{
				flex: 2.5,
				text: lang_mcv_volumePool[2],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Node_List'
			},
			{
				flex: 0.6,
				text: lang_mcv_volumePool[3],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Pool_Status'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[4],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Pool_Size'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[39],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Thin_Allocation'
			},
			{
				xtype: 'componentcolumn',
				flex: 1,
				text: lang_mcv_volumePool[5],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Pool_Used',
				renderer: function (v, m, r) {
					var rateValue = parseFloat(v);

					return {
						xtype: 'progressbar',
						cls: 'used-progress',
						value: rateValue / 100,
						text: v
					}
				}
			},
			{
				flex: 0.6,
				text: lang_mcv_volumePool[6],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Volume_Count'
			},
			{
				dataIndex: 'External_IP',
				hidden: true
			},
			{
				dataIndex: 'External_Type',
				hidden: true
			},
			{
				text: lang_mcv_volumePool[7],
				width: 160,
				autoSizeColumn: true,
				minWidth: 160,
				sortable: false,
				menuDisabled: true,
				dataIndex: 'Management',
				xtype: 'componentcolumn',
				renderer: function (value, metaData, record) {
					var menu = new Ext.menu.Menu();

					menu.add({
						text: lang_common[6],
						itemId: 'MCV_volumePoolChangeBtn',
						width: 140,
						handler: function () {
							var me = this;

							MCV_volumePoolGrid.getSelectionModel().select(record, true);

							// 볼륨 풀 설정 윈도우
							MCV_volumePoolCreateWindow.animateTarget = menu.getComponent('MCV_volumePoolChangeBtn');
							MCV_volumePoolCreateWindow.show();
							MCV_volumePoolCreateWindow.layout.setActiveItem(0);

							// form 초기화
							Ext.getCmp('MCV_volumePoolCreateStep3Form').getForm().reset();
							MCV_volumePoolCreateBtn();
							MCV_volumePoolCreateWindow.setTitle(lang_mcv_volumePool[50]);

							// 선택된 공유풀 정보
							var pool = MCV_volumePoolGrid.getSelectionModel().getSelection()[0];

							// 스토리지 구성 타입 제거
							Ext.getCmp('MCV_volumePoolCreateStep2StorageType').reset();

							// 스토리지 구성 타입
							Ext.getCmp('MCV_volumePoolCreateStep2StorageType').setValue( { storageType: record.get('Pool_Type') } );

							//볼륨풀 type redonly 해제
							Ext.getCmp('MCV_volumePoolCreateStep2StorageType').setDisabled(true);
						}
					});

					if (record.get('Pool_Type').toUpperCase() == 'GLUSTER')
					{
						menu.add({
							text: lang_mcv_volumePool[117],
							width: 140,
							handler: function () {
								var me = this;

								MCV_volumePoolGrid.getSelectionModel().select(record, true);

								waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[87]);

								// 볼륨 풀 동적 할당 생성 Form 초기화
								Ext.getCmp('MCV_volumePoolThinPanel').getForm().reset();

								// Pool type
								var pool_type = record.get('Pool_Type');

								// thick 볼륨 풀 명
								var pool_name = record.get('Pool_Name');

								Ext.getCmp('MCV_vpoolThinBasePoolName').setText(pool_name);

								// thin 볼륨 풀 명
								var tp_pool_name = 'tp_' + record.get('Pool_Name').slice(3);

								Ext.getCmp('MCV_vpoolThinPoolName').setText(tp_pool_name);

								var provision = record.get('Provision');
								MCV_volumeThinPoolStore.each(function (r) {
									if (tp_pool_name == r.data.Pool_Name)
									{
										provision = 'thin';
									}
								});

								// 볼륨 풀 동적 할당 생성 팝업
								if (provision == 'thick')
								{
									GMS.Ajax.request({
										url: '/api/cluster/volume/pool/list',
										method: 'POST',
										jsonData: {
											argument: {
												Pool_Name: pool_name,
												Pool_Type: pool_type,
											}
										},
										callback: function (options, success, response, decoded) {
											// 데이터 전송 완료 후 wait 제거
											if (waitMsgBox)
											{
												waitMsgBox.hide();
												waitMsgBox = null;
											}

											// 예외 처리에 따른 동작
											if (!success || !decoded.success)
											{
												if (response.responseText == ''
														|| typeof(response.responseText) == 'undefined')
													response.responseText = '{}';

												if (typeof(decoded.msg) === 'undefined')
													decoded.msg = '';

												if (typeof(decoded.code) === 'undefined')
													decoded.code = '';

												var checkValue = '{'
													+ '"title": "' + lang_mcv_volumePool[0] + '",'
													+ '"content": "' + lang_mcv_volumePool[88] + '",'
													+ '"msg": "' + decoded.msg + '",'
													+ '"code": "' + decoded.code + '",'
													+ '"response": ' + response.responseText
												+ '}';

												return exceptionDataCheck(checkValue);
											}

											MCV_volumePoolNodeStore.loadRawData(decoded.entity[0].Nodes, false);
											MCV_volumePoolNodeGrid.down('[dataIndex=In_Use]').hide();

											MCV_volumePoolThinWindow.setTitle(lang_mcv_volumePool[47]);
											MCV_volumePoolThinWindow.show();

											// 생성 버튼
											Ext.getCmp('MCV_vpoolThinCreateBtn').show();

											// 수정 버튼
											Ext.getCmp('MCV_vpoolThinReconfigBtn').hide();

											// 제거 버튼
											Ext.getCmp('MCV_vpoolThinDeleteBtn').hide();
										}
									});
								}
								else
								{
									// 볼륨 풀 동적 할당 관리 팝업
									GMS.Ajax.request({
										url: '/api/cluster/volume/pool/list',
										method: 'POST',
										jsonData: {
											argument: {
												Pool_Name: tp_pool_name,
												Pool_Type: pool_type,
											}
										},
										callback: function (options, success, response, decoded) {
											//
											// wait는 base_pool 정보 획득 이후 제거
											//
											// TODO: .then(...) 으로 추후 대체 혹은 기저 볼륨 풀에 대한 정보를
											//       같이 반환하도록 API 개선
											//
											if (waitMsgBox)
											{
												waitMsgBox.hide();
												waitMsgBox = null;
											}

											// 예외 처리에 따른 동작
											if (!success || !decoded.success)
											{
												if (response.responseText == ''
														|| typeof(response.responseText) == 'undefined')
													response.responseText = '{}';

												if (typeof(decoded.msg) === 'undefined')
													decoded.msg = '';

												if (typeof(decoded.code) === 'undefined')
													decoded.code = '';

												var checkValue = '{'
													+ '"title": "' + lang_mcv_volumePool[0] + '",'
													+ '"content": "' + lang_mcv_volumePool[27] + '",'
													+ '"msg": "' + decoded.msg + '",'
													+ '"code": "' + decoded.code + '",'
													+ '"response": ' + response.responseText
												+ '}';

												return exceptionDataCheck(checkValue);
											}

											var base_pool;

											GMS.Ajax.request({
												url: '/api/cluster/volume/pool/list',
												method: 'POST',
												async: false,
												jsonData: {
													argument: {
														Pool_Name: pool_name,
														Pool_Type: pool_type,
													}
												},
												callback: function (options, success, response, decoded) {
													if (waitMsgBox)
													{
														waitMsgBox.hide();
														waitMsgBox = null;
													}

													// 예외 처리에 따른 동작
													if (!success || !decoded.success)
													{
														if (response.responseText == ''
																|| typeof(response.responseText) == 'undefined')
															response.responseText = '{}';

														if (typeof(decoded.msg) === 'undefined')
															decoded.msg = '';

														if (typeof(decoded.code) === 'undefined')
															decoded.code = '';

														var checkValue = '{'
															+ '"title": "' + lang_mcv_volumePool[0] + '",'
															+ '"content": "' + lang_mcv_volumePool[88] + '",'
															+ '"msg": "' + decoded.msg + '",'
															+ '"code": "' + decoded.code + '",'
															+ '"response": ' + response.responseText
														+ '}';

														return exceptionDataCheck(checkValue);
													}

													base_pool = decoded.entity[0].Nodes;
												}
											});

											var tp_info = base_pool.reduce(
												function (acc, cur ,i) {
													var in_use = 0;

													decoded.entity[0].Nodes.some(function (v) {
														if (v.Hostname == cur.Hostname)
														{
															in_use = 1;
															return true;
														}

														return false;
													});

													acc.push(
														{
															Hostname: cur.Hostname,
															HW_Status: cur.HW_Status,
															SW_Status: cur.SW_Status,
															Used: cur.Used,
															Free_Size: cur.Free_Size,
															Size: cur.Size,
															In_Use: in_use,
														}
													);

													return acc;
												},
												[]
											);

											MCV_volumePoolNodeStore.loadRawData(tp_info, false);

											MCV_volumePoolThinWindow.show();
											MCV_volumePoolNodeGrid.down('[dataIndex=In_Use]').show();
											MCV_volumePoolThinWindow.setTitle(lang_mcv_volumePool[59]);

											MCV_volumePoolNodeGrid.store.each(
												function (record) {
													// thin 볼륨 풀로 사용 중인 노드 목록
													if (record.get('In_Use') == '1')
													{
														MCV_volumePoolNodeGrid.getSelectionModel().select(record, true);
													}
												}
											);

											// 동적 할당 크기
											var thin_size = record.get('Thin_Allocation');

											// 동적 할당 타입
											var thin_unit = trim(thin_size.substring(thin_size.length - 1));
											var thin_unit_detail;

											// 볼륨 풀 동적 할당으로 사용 중인 노드 갯수
											var node_count = MCV_volumePoolNodeGrid.getSelectionModel().getCount();

											// 노드별 동적 할당 크기
											thin_size = (trim(thin_size.substring(0, thin_size.length - 1)) / node_count).toFixed(2);

											if (thin_unit == "G")
											{
												thin_unit_detail = "GiB";
											}
											else if (thin_unit == "T")
											{
												thin_unit_detail = "TiB";
											}

											// 노드별 동적 할당 크기
											Ext.getCmp('MCV_vpoolThinAssign').setValue(thin_size);
											Ext.getCmp('MCV_vpoolThinAssignType').setValue(thin_unit_detail);

											// 노드별 동적 할당 크기(hidden)
											Ext.getCmp('MCV_vpoolThinSize').setValue(thin_size);
											Ext.getCmp('MCV_vpoolThinSizeType').setValue(thin_unit_detail);

											// 볼륨 풀 동적 할당에서 사용 중인 노드의 볼륨 풀 크기 계산
											MCV_volumePoolNodeGrid.store.each(
												function (record)
												{
													if (record.get('In_Use') != '1')
														return;

													// 볼륨 풀 남은 크기
													var free_size = record.get('Free_Size');

													// 볼륨 풀 남은 크기 타입
													var free_size_unit = trim(free_size.substring(free_size.length - 1));

													// 볼륨 풀 남은 크기
													var free_size_value = trim(free_size.substring(0, free_size.length - 1));

													// 볼륨 풀 남은 크기
													if (free_size_unit == 'M')
														free_size = free_size_value;
													else if (free_size_unit == 'G')
														free_size = free_size_value * 1024;
													else if (free_size_unit == 'T')
														free_size = free_size_value * 1024 * 1024;
													else if (free_size_unit == 'P')
														free_size = free_size_value * 1024 * 1024 * 1024;

													// 사용 중인 노드별 동적 할당 크기
													if (thin_unit == 'M')
														thin_size = thin_size;
													else if (thin_unit == 'G')
														thin_size = thin_size * 1024;
													else if (thin_unit == 'T')
														thin_size = thin_size * 1024 * 1024;
													else if (thin_unit == 'P')
														thin_size = thin_size * 1024 * 1024 * 1024;

													// 볼륨 풀 크기
													var total_size = parseInt(thin_size) + parseInt(free_size) + 2048;
													var total_value;
													var total_unit;

													if (total_size > 1024 * 1024 * 1024)
													{
														total_unit  = 'P';
														total_value = total_size / 1024 / 1024 / 1024;
													}
													else if (total_size > 1024 * 1024)
													{
														total_unit  = 'T';
														total_value = total_size / 1024 / 1024;
													}
													else if (total_size > 1024)
													{
														total_unit  = 'G';
														total_value = total_size / 1024;
													}
													else
													{
														total_unit  = 'M';
														total_value = total_size;
													}

													record.set('Assign_Size', total_value + total_unit);
												}
											);

											// 노드별 최대 동적 할당 가능한 크기
											MCV_volumePoolMaxVolumePoolSize();

											// 생성 버튼
											Ext.getCmp('MCV_vpoolThinCreateBtn').hide();

											// 수정 버튼
											Ext.getCmp('MCV_vpoolThinReconfigBtn').show();

											// 제거 버튼
											Ext.getCmp('MCV_vpoolThinDeleteBtn').show();
										}
									});

									/*
									MCV_volumePoolNodeStore.load({
										params:{
											"poolName": pool_name,
											"poolType": pool_type,
											"tp_poolName": tp_pool_name
										},
										callback: function (record, operation, success) {
											// 예외 처리에 따른 동작
											if (success != true)
											{
												var jsonText = JSON.stringify(operation.request.proxy.reader.rawData);

												if (typeof(jsonText) == 'undefined')
													jsonText = '{}';

												var checkValue = `{
													"title": "${lang_mcv_volumePool[0]}",
													"content": "${lang_mcv_volumePool[27]}",
													"response": ${jsonText}
												}`;

												return exceptionDataCheck(checkValue);
											}

										}
									});
									*/
								}
							}
						});
					}

					return {
						xtype: 'button',
						text: lang_mcv_volumePool[7],
						menu: menu
					};
				}
			}
		],
		tbar: [
			{
				text: lang_mcv_volumePool[10],
				id: 'MCV_volumePoolCreateBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[48]);

					// 클러스터 볼륨 풀 생성 OPEN
					MCV_volumePoolCreateWindow.animateTarget = Ext.getCmp('MCV_volumePoolCreateBtn');
					MCV_volumePoolCreateWindow.layout.setActiveItem(0);

					// 버튼 컨트롤
					MCV_volumePoolCreateBtn();

					// 볼륨풀 생성 제목
					MCV_volumePoolCreateWindow.setTitle(lang_mcv_volumePool[20]);

					// form 초기화
					Ext.getCmp('MCV_volumePoolCreateStep3Form').getForm().reset();

					// 스토리지 구성 타입 제거
					Ext.getCmp('MCV_volumePoolCreateStep2StorageType').reset();

					// 스토리지 구성 타입
					Ext.getCmp('MCV_volumePoolCreateStep2StorageType').setValue( { storageType: 'Gluster' } );

					// 볼륨풀 type readonly 해제
					Ext.getCmp('MCV_volumePoolCreateStep2StorageType').setDisabled(false);

					MCV_volumePoolDeviceStore.removeAll();
					MCV_volumePoolDeviceStore.clearFilter();

					GMS.Ajax.request({
						url: '/api/cluster/block/device/list',
						method: 'POST',
						jsonData: {
							entity: {
								scope: 'NO_INUSE',
							}
						},
						callback: function (options, success, response, decoded) {
							loadBlockDeviceStore(success, response);

							MCV_volumePoolCreateWindow.show();
						}
					});
				}
			},
			{
				text: lang_mcv_volumePool[89],
				id: 'MCV_volumePoolDeleteBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					var selected = MCV_volumePoolGrid.getSelectionModel().getSelection()[0];

					// 볼륨 풀 동적 할당이 있으면 삭제 실패
					var provision  = selected.get('Provision');
					var thin_alloc = selected.get('Thin_Allocation');
					var pool_type  = selected.get('Pool_Type');

					/*
					if (thin_alloc != '0.0G' && pool_type.toUpperCase() != 'EXTERNAL')
					{
						Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[61]);
						return false;
					}
					*/

					// 볼륨이 있으면 삭제 실패
					var vol_count = selected.get('Volume_Count');

					if (vol_count > 0)
					{
						Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[37]);
						return false;
					}
					
					Ext.MessageBox.confirm(
						lang_mcv_volumePool[0],
						lang_mcv_volumePool[34],
						function (btn, text) {
							if (btn != 'yes')
								return;

							// 볼륨 풀 명
							var pool_name = selected.get('Pool_Name');

							// 볼륨 풀 타입
							var pool_type = selected.get('Pool_Type');

							waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[35]);

							Ext.Ajax.request({
								url: '/api/cluster/volume/pool/remove',
								timeout: 60000,
								jsonData: {
									argument: {
										Pool_Name: pool_name,
										Pool_Type: pool_type,
									}
								},
								callback: function (options, success, response) {
									// 데이터 전송 완료 후 wait 제거
									if (waitMsgBox)
									{
										waitMsgBox.hide();
										waitMsgBox = null;
									}

									var responseData = Ext.JSON.decode(response.responseText);

									// 예외 처리에 따른 동작
									if (!success || !responseData.success)
									{
										if (response.responseText == ''
												|| typeof(response.responseText) == 'undefined')
											response.responseText = '{}';

										if (typeof(responseData.msg) === 'undefined')
											responseData.msg = '';

										if (typeof(responseData.code) === 'undefined')
											responseData.code = '';

										var checkValue = '{'
											+ '"title": "' + lang_mcv_volumePool[0] + '",'
											+ '"content": "' + lang_mcv_volumePool[33] + '",'
											+ '"msg": "' + responseData.msg + '",'
											+ '"code": "' + responseData.code + '",'
											+ '"response": ' + response.responseText
										+ '}';

										return exceptionDataCheck(checkValue);
									}

									Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[32]);
									MCV_volumePoolLoad();
								}
							});
						}
					);
				}
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { 
					MCV_volumePoolGrid.getSelectionModel().select(record, true);
					MCV_volumePoolSelect(record);
				}, 100);
			},
			cellclick: function (gridView, htmlElement, columnIndex, dataRecord) {
				if (columnIndex == 12)
				{
					MCV_volumePoolGrid.getSelectionModel().deselectAll();
					MCV_volumePoolGrid.getSelectionModel().select(dataRecord, true);
				}
			}
		},
		viewConfig: {
			getRowClass: function (record,id) {
			if (record.get('Base_Pool') !== '') {
				return 'hide-row';
			}
			},
			loadMask: true,
			markDirty: false
		}
	}
);

// 볼륨 풀 목록 선택 시
function MCV_volumePoolSelect(record)
{
	if (MCV_volumePoolGrid.getSelectionModel().getCount() == 1)
	{
		Ext.getCmp('MCV_volumePoolDeleteBtn').setDisabled(false);
	}
	else
	{
		Ext.getCmp('MCV_volumePoolDeleteBtn').setDisabled(true);
	}
};

// 노드 장치 크기 합산
function MCV_volumePoolDeviceTotalSize()
{
	if (MCV_volumePoolDeviceGrid.getSelectionModel().getCount() == 0)
	{
		Ext.getCmp('MCV_volumePoolCreatePoolSize').setText('0.00 Byte');
		return;
	}

	var selection = MCV_volumePoolDeviceGrid.getSelectionModel().getSelection(),
		selected = [],
		total_size = 0;

	for (var i=0, len=selection.length; i<len; i++)
	{
		if (selection[i].get('Serial') != null)
		{
			if (selected.includes(selection[i].get('Serial')))
				continue;

			selected.push(selection[i].get('Serial'));
		}

		// 최대 생성 사능 용량 확인
		var size  = selection[i].get('Size');
		var value = trim(size.substring(0, size.length - 1));
		var unit  = trim(size.substring(size.length - 1));

		if (unit == 'M')
			size = parseInt(value);
		else if (unit == 'G')
			size = value * 1024;
		else if (unit == 'T')
			size = value * 1024 * 1024;
		else if (unit == 'P')
			size = value * 1024 * 1024 * 1024;

		total_size += size;
	}

	var total_unit = 0;

	if (total_size > 1024 * 1024 * 1024)
	{
		total_size = total_size / 1024 / 1024 / 1024;
		total_unit = 'PiB';
	}
	else if (total_size > 1048576)
	{
		total_size = total_size / 1024 / 1024;
		total_unit = 'TiB';
	}
	else if (total_size > 1024)
	{
		total_size = total_size / 1024;
		total_unit = 'GiB';
	}
	else
	{
		total_size = total_size;
		total_unit = 'MiB';
	}

	Ext.getCmp('MCV_volumePoolCreatePoolSize')
		.setText((Math.round(total_size * 100) / 100) + ' ' + total_unit);
}

// 노드명 정렬
Ext.apply(
	Ext.data.SortTypes,
	{
		asHostName: function (hostname) {
			var hostnameData   = hostname.split('-');
			var hostnameNumber = parseInt(hostnameData[1]);

			return hostnameNumber;
		}
	}
);

// 노드에 대한 블럭 디바이스의 정보 GRID
// 노드에 대한 블럭 디바이스의 정보 GRID 모델
Ext.define(
	'MCV_volumePoolDeviceModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Hostname', sortType: 'asHostName' },
			'Serial', 'Name', 'Type', 'Transport', 'Size', 'In_Use',
			'OS_Disk', 'inclusion'
		]
	}
);

function loadBlockDeviceStore(success, response)
{
	// 데이터 전송 완료 후 wait 제거
	if (waitMsgBox)
	{
		waitMsgBox.hide();
		waitMsgBox = null;
	}

	var decoded = Ext.decode(response.responseText);

	// 예외 처리에 따른 동작
	if (!success || !decoded.success)
	{
		if (response.responseText == ''
				|| typeof(response.responseText) == 'undefined')
			response.responseText = '{}';

		if (typeof(decoded.msg) === 'undefined')
			decoded.msg = '';

		if (typeof(decoded.code) === 'undefined')
			decoded.code = '';

		var checkValue = '{'
			+ '"title": "' + lang_mcv_volumePool[0] + '",'
			+ '"content": "' + lang_mcv_volumePool[49] + '",'
			+ '"msg": "' + decoded.msg + '",'
			+ '"code": "' + decoded.code + '",'
			+ '"response": ' + response.responseText
		+ '}';

		exceptionDataCheck(checkValue);

		return -1;
	}

	var records = decoded.entity.reduce(
		function (acc, cur, i) {
			for (var i=0; i<cur.Devices.length; i++)
			{
				if (cur.Devices[i].OS_Disk == 1)
				{
					continue;
				}

				acc.push({
					Serial: cur.Devices[i].Serial,
					Hostname: cur.Hostname,
					Name: cur.Devices[i].Name,
					Type: cur.Devices[i].Type,
					Transport: cur.Devices[i].Transport,
					Size: cur.Devices[i].Size,
					In_Use: cur.Devices[i].In_Use
				});
			}

			return acc;
		},
		[]
	);

	MCV_volumePoolDeviceStore.loadRawData(records, false);
	MCV_volumePoolDeviceStore.sort();

	return 0;
}

// 노드에 대한 블럭 디바이스의 정보 GRID 스토어
var MCV_volumePoolDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumePoolDeviceModel',
		sorters: [
			{ property: 'Serial', direction: 'ASC' },
			{ property: 'Hostname', direction: 'ASC' },
			{ property: 'Name', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				var mpaths = [];

				// 예외 처리에 따른 동작
				records.forEach(
					function (e) {
						if (!e.get('Type').match(/^(hdd|ssd|nvme|multipath)$/))
						{
							store.remove(e);
						}

						if (e.get('Type') == 'multipath')
						{
							mpaths.push(e);
						}
					}
				);

				mpaths.forEach(
					function (mpath) {
						records.forEach(
							function (dev) {
								if (dev.get('Name') != mpath.get('Name')
									&& dev.get('Hostname') == mpath.get('Hostname')
									&& dev.get('Serial') == mpath.get('Serial'))
								{
									store.remove(dev);
								}
							}
						);
					}
				);

				if (!success)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcv_volumePool[0] + '",'
						+ '"content": "' + lang_mcv_volumePool[27] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}
			}
		}
	}
);

// 노드에 대한 블럭 디바이스의 정보 GRID
var MCV_volumePoolDeviceGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCV_volumePoolDeviceGrid',
		store: MCV_volumePoolDeviceStore,
		multiSelect: true,
		title: lang_mcv_volumePool[46],
		height: 240,
		loadMask: true,
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				select: function (me, target) {
					var type = Ext.getCmp('MCV_volumePoolCreateStep2StorageType').getValue()
								.storageType.toUpperCase();

					var store = me.getStore();

					if (type == 'EXTERNAL')
					{
						return;
					}
					else if (type == 'LOCAL')
					{
						var selection = me.getSelection();

						if (selection.some(
							function (record)
							{
								return record.get('Hostname')
										!= target.get('Hostname');
							}))
						{
							me.deselect([target], true, true);

							Ext.MessageBox.alert(
								lang_mcv_volumePool[0],
								lang_mcv_volumePool[114]);

							return;
						}

						if (target)
						{
							store.clearFilter();
							store.filter(
								function (record) {
									return target.get('Hostname') == record.get('Hostname');
								}
							);
						}
					}

					if (target.get('Serial') == null)
					{
						me.select([target], true, true);
						return;
					}

					store.each(
						function (record) {
							if (target.get('Hostname') != record.get('Hostname')
								&& target.get('Serial') == record.get('Serial'))
							{
								me.deselect([record], true, true);
							}
						}
					);
				},
				deselect: function (me, target) {
					var oper = MCV_volumePoolCreateWindow.animateTarget.id;

					if (oper != 'MCV_volumePoolCreateBtn'
						&& me.getSelection().length == 0)
					{
						me.select([target], true, true);

						Ext.MessageBox.alert(
							lang_mcv_volumePool[0],
							lang_mcv_volumePool[86]);

						return;
					}

					var type = Ext.getCmp('MCV_volumePoolCreateStep2StorageType').getValue()
								.storageType.toUpperCase();

					var store = me.getStore();

					if (type == 'EXTERNAL')
					{
						return;
					}
					else if (type == 'LOCAL' && me.getCount() == 0)
					{
						store.clearFilter();
					}

					if (target.get('Serial') == null)
					{
						me.deselect([target], true, true);
						return;
					}

					store.each(
						function (record) {
							if (target.get('Serial') == record.get('Serial'))
							{
								me.deselect([record], true, true);
							}
						}
					);
				},
				selectall: function () {
					// 최대 볼륨 풀 크기 계산
					Ext.defer(function () { MCV_volumePoolDeviceTotalSize(); }, 200);
				},
				deselectall: function () {
					// 최대 볼륨 풀 크기 계산
					Ext.defer(function () { MCV_volumePoolDeviceTotalSize(); }, 200);
				},
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_common[31],
				sortable: true,
				dataIndex: 'Serial'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[41],
				sortable: true,
				dataIndex: 'Hostname'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[15],
				sortable: true,
				dataIndex: 'Name'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[42],
				sortable: true,
				dataIndex: 'Type'
			},
			{
				flex: 1,
				text: lang_common[17],
				sortable: true,
				dataIndex: 'Transport'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[43],
				sortable: true,
				dataIndex: 'Size'
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[69],
				sortable: true,
				dataIndex: 'In_Use',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					if (value == '1')
					{
						return '<span style="color:green">'
								+ lang_mcv_volumePool[70]
								+ '</span>';
					}
					else
					{
						return '<span style="color:gray">'
								+ lang_mcv_volumePool[71]
								+ '</span>';
					}
				}
			},
			{
				dataIndex: 'inclusion',
				hidden: true,
			}
		],
		listeners: {
			selectionchange: function (model, records) {
				// 볼륨 풀 생성 시 추가한 장치 리스트
				/*
				this.store.each(
					function (record) {
						// 현재 볼륨 풀에서 사용 중인 장치 (선택 해제 불가)
						if (record.get('inclusion') == '1')
						{
							this.getSelectionModel().select(record, true);
						}
					}
				);
				*/

				// 볼륨 풀 크기
				MCV_volumePoolDeviceTotalSize();
				//Ext.defer(function (){MCV_volumePoolDeviceTotalSize()},200);
			}
		}
	}
);

/** 볼륨풀 생성 step */
/** 볼륨 풀 생성 step1 :: 볼륨 풀 생성 정보 출력 */
var MCV_volumePoolCreateStep1Panel = Ext.create('BasePanel', {
	id: 'MCV_volumePoolCreateStep1Panel',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'image',
			src: '/admin/images/bg_wizard.jpg',
			height: 540,
			width: 150
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			flex: 1,
			items: [
				{
					xtype: 'BaseWizardTitlePanel',
					html: lang_mcv_volumePool[91]
				},
				{
					xtype: 'BaseWizardContentPanel',
					items: [
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>' + lang_mcv_volumePool[92] + '(1/3)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volumePool[93]
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>' + lang_mcv_volumePool[94] + '(2/3)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volumePool[95]
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '<li>' + lang_mcv_volumePool[96] + '(3/3)</li>'
						},
						{
							border: false,
							style: { marginBottom: '20px' },
							html: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + lang_mcv_volumePool[97]
						}
					]
				}
			]
		}
	]
});

/** 볼륨 풀 생성 step2 :: 스토리지 구성 선택 */
var MCV_volumePoolCreateStep2Panel = Ext.create('BasePanel', {
	id: 'MCV_volumePoolCreateStep2Panel',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			width: 150,
			items: [
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_mcv_volumePool[92]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_mcv_volumePool[94]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_mcv_volumePool[96]
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
					html: lang_mcv_volumePool[93]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: 'hbox',
					bodyStyle: 'padding: 0;',
					maskOnDisable: false,
					items: [
						{
							xtype: 'radiogroup',
							id: 'MCV_volumePoolCreateStep2StorageType',
							columns: 1,
							width: 150,
							items: [
								{
									boxLabel: 'Gluster',
									id: 'MCV_volumePoolCreateStep2StorageTypeGluster',
									name: 'storageType',
									inputValue: 'Gluster',
									border: false,
									style: { marginBottom: '20px' },
									listeners: {
										change: function () {
											if (this.getValue() != true)
												return;

											Ext.getCmp('MCV_volumePoolCreateStep2Img')
												.setSrc('/admin/images/cluster.png');
										}
									}
								},
								{
									boxLabel: 'Local',
									id: 'MCV_volumePoolCreateStep2StorageTypeLocal',
									name: 'storageType',
									inputValue: 'Local',
									border: false,
									style: { marginBottom: '20px' },
									listeners: {
										change: function () {
											if (this.getValue() != true)
												return;

											Ext.getCmp('MCV_volumePoolCreateStep2Img')
												.setSrc('/admin/images/local.png');
										}
									},
								},
								{
									boxLabel: 'External',
									id: 'MCV_volumePoolCreateStep2StorageTypeExternal',
									name: 'storageType',
									inputValue: 'External',
									border: false,
									style: { marginBottom: '20px' },
									listeners: {
										change: function () {
											if (this.getValue() != true)
												return;

											Ext.getCmp('MCV_volumePoolCreateStep2Img')
												.setSrc('/admin/images/external.png');
										}
									}
								}
							],
							listeners: {
								change: function (field, newValue, oldValue) {
									var type = newValue.hasOwnProperty('storageType')
												? newValue.storageType
												: oldValue.storageType;

									var btn = MCV_volumePoolCreateWindow.animateTarget.id;

									if (type.toUpperCase().match(/^(?:GLUSTER|LOCAL)$/))
									{
										MCV_volumePoolCreateStep2Listener(btn);
									}
									else if (type.toUpperCase() == 'EXTERNAL')
									{
										MCV_volumePoolCreateStep2ExternalListener(btn);
									}
								}
							}
						},
						{
							xtype: 'image',
							id: 'MCV_volumePoolCreateStep2Img',
							src: '/admin/images/cluster.png',
							width: 400,
							height: 300
						}
					]
				}
			]
		}
	]
});

function MCV_volumePoolCreateStep2Listener(btn)
{
	var columns = MCV_volumePoolDeviceGrid.columnManager.getColumns();

	for (var i=0; i<columns.length; i++)
	{
		if (columns[i].dataIndex == 'inclusion')
		{
			continue;
		}

		columns[i].setVisible(true);
	}

	// 생성일 경우
	if (btn == 'MCV_volumePoolCreateBtn')
	{
		// 이름
		Ext.getCmp('MCV_volumePoolCreatePoolName').setDisabled(false);

		// IP
		Ext.getCmp('MCV_volumePoolCreateExtIP').setDisabled(true);
		Ext.getCmp('MCV_volumePoolCreateExtIP').hide();

		// 외부 풀 유형
		Ext.getCmp('MCV_volumePoolCreateExtType').setDisabled(true);
		Ext.getCmp('MCV_volumePoolCreateExtType').hide();

		// 볼륨풀 크기
		Ext.getCmp('MCV_volumePoolCreatePoolSizePanel').show();

		Ext.Ajax.request({
			url: '/api/cluster/block/device/list',
			method: 'POST',
			jsonData: {
				entity: {
					scope: 'NO_INUSE',
				}
			},
			callback: function (options, success, response) {
				if (loadBlockDeviceStore(success, response))
					return;

				MCV_volumePoolDeviceGrid.setHeight(240);
				MCV_volumePoolDeviceGrid.setTitle(lang_mcv_volumePool[46]);

				// 필터링 제거
				MCV_volumePoolDeviceStore.clearFilter();

				// 다른 볼륨 풀에서 사용 중인 장치 목록 숨김
				MCV_volumePoolDeviceStore.filter(
					function (r) {
						return (r.get('In_Use') == 0);
					}
				);
			}
		});
	}
	else
	{
		// 이름
		Ext.getCmp('MCV_volumePoolCreatePoolName').setDisabled(true);

		// IP
		Ext.getCmp('MCV_volumePoolCreateExtIP').setDisabled(true);
		Ext.getCmp('MCV_volumePoolCreateExtIP').hide();

		// 외부 풀 유형
		Ext.getCmp('MCV_volumePoolCreateExtType').setDisabled(true);
		Ext.getCmp('MCV_volumePoolCreateExtType').hide();

		// 볼륨풀 크기
		Ext.getCmp('MCV_volumePoolCreatePoolSizePanel').show();

		// 선택된 공유풀 정보
		var pool = MCV_volumePoolGrid.getSelectionModel().getSelection()[0];

		// 이름
		Ext.getCmp('MCV_volumePoolCreatePoolName')
			.setValue(pool.get('Pool_Name'));

		// 생성된 Pool 크기
		Ext.getCmp('MCV_volumePoolCreatePoolSize')
			.setText(pool.get('Pool_Size'));

		// 추가로 선택한 노드 + 볼륨 생성 시 추가한 노드 선택
		Ext.Ajax.request({
			url: '/api/cluster/block/device/list',
			method: 'POST',
			jsonData: {
				entity: {
					scope: 'NO_OSDISK',
				}
			},
			callback: function (options, success, response) {
				if (loadBlockDeviceStore(success, response))
					return;

				MCV_volumePoolDeviceGrid.setHeight(240);
				MCV_volumePoolDeviceGrid.setTitle(lang_mcv_volumePool[46]);

				// 필터링
				MCV_volumePoolDeviceStore.clearFilter();

				if (pool.get('Pool_Type').toUpperCase() == 'LOCAL')
				{
					MCV_volumePoolDeviceStore.filter(
						function (record) {
							return pool.get('Node_List').includes(record.get('Hostname'));
						}
					);
				}

				// 선택 노드
				var nodes    = pool.get('Nodes');
				var selected = [];

				MCV_volumePoolDeviceGrid.store.each(
					function (record)
					{
						for (var i=0; i<nodes.length; i++)
						{
							for (var j=0; j<nodes[i].PVs.length; j++)
							{
								if (record.get('Hostname') != nodes[i].Hostname
										|| record.get('Name') != nodes[i].PVs[j].Name)
									continue;

								record.set('inclusion', record.get('In_Use'));
								selected.push(record);
							}
						}
					}
				);

				// :WARNING Thu 17 Oct 2019 03:33:54 AM KST: by P.G.
				// It does cause duplicated records
				//MCV_volumePoolDeviceGrid.getStore().add(selected);
				MCV_volumePoolDeviceGrid.getSelectionModel().select(selected, true);
			}
		});
	}
}

function MCV_volumePoolCreateStep2ExternalListener(btn)
{
	var columns = MCV_volumePoolDeviceGrid.columnManager.getColumns();

	for (var i=0; i<columns.length; i++)
	{
		columns[i].setVisible(columns[i].dataIndex == 'Hostname' ? true : false);
	}

	// 생성일 경우
	if (btn == 'MCV_volumePoolCreateBtn')
	{
		// 이름
		Ext.getCmp('MCV_volumePoolCreatePoolName').setDisabled(false);

		// IP
		Ext.getCmp('MCV_volumePoolCreateExtIP').setDisabled(false);
		Ext.getCmp('MCV_volumePoolCreateExtIP').show();

		// type
		Ext.getCmp('MCV_volumePoolCreateExtType').setDisabled(false);
		Ext.getCmp('MCV_volumePoolCreateExtType').show();

		// 볼륨풀 크기
		Ext.getCmp('MCV_volumePoolCreatePoolSizePanel').hide();

		Ext.Ajax.request({
			url: '/api/cluster/block/device/list',
			method: 'POST',
			jsonData: {
				entity: {
					scope: 'ALL',
				}
			},
			callback: function (options, success, response) {
				if (loadBlockDeviceStore(success, response))
					return;

				// External 경우 디바이스 목록 중복 제거 - 필터링 제거
				MCV_volumePoolDeviceStore.clearFilter();
				MCV_volumePoolDeviceGrid.setHeight(200);
				MCV_volumePoolDeviceGrid.setTitle(lang_mcv_volumePool[21]);

				// External 경우 디바이스 목록 중복 제거 - 필터링
				var hostname = MCV_volumePoolDeviceStore.collect("Hostname");

				MCV_volumePoolDeviceStore.filter(
					function (record) {
						if (hostname.indexOf(record.get('Hostname')) !== -1)
						{
							hostname.splice(hostname.indexOf(record.get('Hostname')), 1);
							return true;
						}
					}
				);
			}
		});
	}
	else
	{
		// 이름
		Ext.getCmp('MCV_volumePoolCreatePoolName').setDisabled(true);

		// IP
		Ext.getCmp('MCV_volumePoolCreateExtIP').setDisabled(false);
		Ext.getCmp('MCV_volumePoolCreateExtIP').show();

		// type
		Ext.getCmp('MCV_volumePoolCreateExtType').setDisabled(true);
		Ext.getCmp('MCV_volumePoolCreateExtType').show();

		// 볼륨풀 크기
		Ext.getCmp('MCV_volumePoolCreatePoolSizePanel').hide();

		// 선택된 공유풀 정보
		var pool = MCV_volumePoolGrid.getSelectionModel().getSelection()[0];

		// 이름
		Ext.getCmp('MCV_volumePoolCreatePoolName').setValue(pool.get('Pool_Name'));

		// External IP
		Ext.getCmp('MCV_volumePoolCreateExtIP').setValue(pool.get('External_IP'));

		// External 타입(NFS, SNFS)
		Ext.getCmp('MCV_volumePoolCreateExtType').setValue(pool.get('External_Type'));

		// 추가로 선택한 노드 + 볼륨 생성시 추가한 노드 선택
		Ext.Ajax.request({
			url: '/api/cluster/block/device/list',
			method: 'POST',
			jsonData: {
				entity: {
					scope: 'ALL',
				}
			},
			callback: function (options, success, response) {
				if (loadBlockDeviceStore(success, response))
					return;

				MCV_volumePoolDeviceGrid.setHeight(200);
				MCV_volumePoolDeviceGrid.setTitle(lang_mcv_volumePool[21]);

				// 필터링 제거
				MCV_volumePoolDeviceStore.clearFilter();

				// 선택 디바이스
				var selected = [];

				// 노드 목록
				var node_list = pool.get('Node_List');

				// External 경우 디바이스 목록 중복 제거 - 필터링
				var hostname = MCV_volumePoolDeviceStore.collect('Hostname');
				
				MCV_volumePoolDeviceStore.filter(
					function (record) {
						if (hostname.indexOf(record.get('Hostname')) !== -1)
						{
							// 볼륨 풀의 노드 목록의 값과 Hostname 값이 같으면 선택
							if (node_list.indexOf(record.get('Hostname')) !== -1)
							{
								record.set('inclusion', 0);
								selected.push(record);
							}

							hostname.splice(hostname.indexOf(record.get('Hostname')), 1);
							return true;
						}
					}
				);

				MCV_volumePoolDeviceGrid.getSelectionModel().select(selected, true);
			}
		});
	}
}

/** 볼륨 풀 생성 step3 :: 노드별 디스크 선택 */
var MCV_volumePoolCreateStep3Panel = Ext.create('BasePanel', {
	id: 'MCV_volumePoolCreateStep3Panel',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			width: 150,
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">'
							+ lang_mcv_volumePool[92]
							+ '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MCV_volumePoolCreateWindow.layout.setActiveItem(1);

								// 버튼 컨트롤
								MCV_volumePoolCreateBtn();
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					text: lang_mcv_volumePool[94]
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_mcv_volumePool[96]
				}
			]
		},
		{
			xtype: 'BaseFormPanel',
			id: 'MCV_volumePoolCreateStep3Form',
			bodyStyle: 'padding: 0;',
			flex: 1,
			autoScroll: false,
			items: [
				{
					xtype: 'BaseWizardTitlePanel',
					html: lang_mcv_volumePool[93]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items: [
						{
							xtype: 'BasePanel',
							bodyStyle: 'padding: 0;',
							items: [
								{
									xtype: 'textfield',
									fieldLabel: lang_mcv_volumePool[84],
									id: 'MCV_volumePoolCreatePoolName',
									name: 'volumePoolCreatePoolName',
									style: {
										marginLeft: '15px',
										marginBottom: '20px'
									},
									msgTarget: 'side',
									allowBlank: false,
									vtype: 'reg_volumePoolName'
								},
								{
									xtype: 'BaseComboBox',
									fieldLabel: lang_mcv_volumePool[112],
									id: 'MCV_volumePoolCreateExtType',
									hiddenName: 'volumePoolCreateExtType',
									name: 'volumePoolCreateExtType',
									style: {
										marginLeft: '15px',
										marginBottom: '20px'
									},
									store: new Ext.data.SimpleStore({
										fields: ['View', 'Code'],
										data: [
											['NFS', 'NFS'],
											['SNFS', 'SNFS']
										]
									}),
									value: 'NFS',
									displayField: 'View',
									valueField: 'Code',
									listeners: {
										change: function (combo, nval, oval) {
											if (nval == 'NFS')
											{
												Ext.getCmp('MCV_volumePoolCreateExtIP').show();
											}
											else if (nval == 'SNFS')
											{
												Ext.getCmp('MCV_volumePoolCreateExtIP').hide();
											}
										}
									}
								},
								{
									xtype: 'textfield',
									fieldLabel: 'IP',
									id: 'MCV_volumePoolCreateExtIP',
									name: 'volumePoolCreateExtIP',
									style: {
										marginLeft: '15px',
										marginBottom: '20px'
									},
									msgTarget: 'side',
									allowBlank: false
								},
								{
									xtype: 'BasePanel',
									id: 'MCV_volumePoolCreatePoolSizePanel',
									bodyStyle: 'padding: 0;',
									layout: 'hbox',
									maskOnDisable: false,
									style: {
										marginLeft: '15px',
										marginBottom: '20px'
									},
									items: [
										{
											xtype: 'label',
											text: lang_mcv_volumePool[4]+': ',
											width: 120
										},
										{
											xtype: 'label',
											id: 'MCV_volumePoolCreatePoolSize',
											text: '0GiB',
											style: { marginLeft: '15px' }
										}
									]
								},
								{
									xtype: 'BasePanel',
									bodyStyle: 'padding: 0;',
									items: [MCV_volumePoolDeviceGrid]
								}
							]
						}
					]
				}
			]
		}
	]
});

/** 볼륨풀 생성 step4 :: 선택된 디스크 목록 */
// 선택된 디스크 목록 스토어
var MCV_volumePoolSelectedDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumePoolDeviceModel',
		sorters: [
			{ property: 'Serial', direction: 'ASC' },
			{ property: 'Hostname', direction: 'ASC' },
			{ property: 'Name', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		}
	}
);

// 선택된 디스크 목록 그리드
var MCV_volumePoolSelectedDeviceGrid = Ext.create('BaseGridPanel', {
	id: 'MCV_volumePoolSelectedDeviceGrid',
	store: MCV_volumePoolSelectedDeviceStore,
	multiSelect: true,
	title: lang_mcv_volumePool[98],
	height: 180,
	columns: [
		{
			flex: 1,
			text: lang_common[31],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Serial'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[41],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Hostname'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[15],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Name'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[42],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Type'
		},
		{
			flex: 1,
			text: lang_common[17],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Transport'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[43],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Size'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[69],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'In_Use',
			renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
				if (value == '1')
				{
					return '<span style="color:green">'+lang_mcv_volumePool[70]+'</span>';
				}
				else
				{
					return '<span style="color:gray">'+lang_mcv_volumePool[71]+'</span>';
				}
			}
		},
		{
			dataIndex: 'inclusion',
			hidden: true,
		}
	]
});

/** 볼륨 풀 생성 step4 :: 입력 내용 확인 */
var MCV_volumePoolCreateStep4Panel = Ext.create('BasePanel', {
	id: 'MCV_volumePoolCreateStep4Panel',
	layout: {
		type: 'hbox',
		pack: 'start',
		align: 'stretch'
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BaseWizardSidePanel',
			width: 150,
			items: [
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">'
							+ lang_mcv_volumePool[92]
							+ '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MCV_volumePoolCreateWindow.layout.setActiveItem(1);

								// 버튼 컨트롤
								MCV_volumePoolCreateBtn();
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'fontWeight: bold; marginBottom: 20px;',
					html: '<span class="m-wizard-side-link">'
							+ lang_mcv_volumePool[94]
							+ '</span>',
					listeners: {
						afterrender: function () {
							this.el.on('click', function () {
								MCV_volumePoolCreateWindow.layout.setActiveItem(2);

								// 버튼 컨트롤
								MCV_volumePoolCreateBtn();
							});
						}
					}
				},
				{
					xtype: 'label',
					style: 'marginBottom: 20px;',
					text: lang_mcv_volumePool[96]
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
					html: lang_mcv_volumePool[97]
				},
				{
					xtype: 'BaseWizardContentPanel',
					layout: {
						align: 'stretch'
					},
					items: [
						// 볼륨 풀 이름
						{
							xtype: 'BasePanel',
							id:'MCV_volumePoolCreateStep4PoolNamePanel',
							bodyStyle: 'padding:0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									html: lang_mcv_volumePool[84] + ': ',
									width: 130,
									style: {marginBottom: '20px'}
								},
								{
									xtype: 'label',
									id: 'MCV_volumePoolCreateStep4PoolName'
								}
							]
						},
						//스토리지 구성(유형)
						{
							xtype: 'BasePanel',
							id:'MCV_volumePoolCreateStep4StorageTypePanel',
							bodyStyle: 'padding:0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									html: lang_mcv_volumePool[115] + ': ',
									width: 130,
									style: { marginBottom: '20px' }
								},
								{
									xtype: 'label',
									id: 'MCV_volumePoolCreateStep4StorageType'
								}
							]
						},
						// 볼륨 풀크기
						{
							xtype: 'BasePanel',
							id:'MCV_volumePoolCreateStep4PoolSizePanel',
							bodyStyle: 'padding:0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									html: lang_mcv_volumePool[100] + ': ',
									width: 130,
									style: { marginBottom: '20px' }
								},
								{
									xtype: 'label',
									id: 'MCV_volumePoolCreateStep4PoolSize'
								}
							]
						},
						// External IP
						{
							xtype: 'BasePanel',
							id:'MCV_volumePoolCreateStep4ExtIPPanel',
							bodyStyle: 'padding:0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									html: 'External IP' + ': ',
									width: 130,
									style: { marginBottom: '20px' }
								},
								{
									xtype: 'label',
									id: 'MCV_volumePoolCreateStep4ExtIP'
								}
							]
						},
						// 외부 볼륨 풀 유형
						{
							xtype: 'BasePanel',
							id:'MCV_volumePoolCreateStep4ExtTypePanel',
							bodyStyle: 'padding:0;',
							layout: 'hbox',
							maskOnDisable: false,
							items: [
								{
									xtype: 'label',
									html: lang_mcv_volumePool[112] + ': ',
									width: 130,
									style: { marginBottom: '20px' }
								},
								{
									xtype: 'label',
									id: 'MCV_volumePoolCreateStep4ExtType'
								}
							]
						},
						// 선택된 디스크 목록
						{
							xtype: 'BasePanel',
							id: 'MCV_volumePoolCreateStep4SelectedDevicePanel',
							bodyStyle: 'padding: 0;',
							items: [MCV_volumePoolSelectedDeviceGrid]
						}
					]
				}
			]
		}
	]
});

// 볼륨 풀 생성 WINDOW
var MCV_volumePoolCreateWindow = Ext.create('BaseWindowPanel', {
	id: 'MCV_volumePoolCreateWindow',
	layout: 'card',
	title: lang_mcv_volumePool[102],
	maximizable: false,
	autoHeight: true,
	width: 770,
	height: 530,
	activeItem: 0,
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MCV_volumePoolCreateStep1',
			items: [MCV_volumePoolCreateStep1Panel]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MCV_volumePoolCreateStep2',
			items: [MCV_volumePoolCreateStep2Panel]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MCV_volumePoolCreateStep3',
			items: [MCV_volumePoolCreateStep3Panel]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			layout: 'fit',
			id: 'MCV_volumePoolCreateStep4',
			items: [MCV_volumePoolCreateStep4Panel]
		}
	],
	fbar: [
		{
			text: lang_mcv_volumePool[103],
			id: 'MCV_volumePoolCreateCancleBtn',
			width: 70,
			disabled: false,
			border: true,
			handler: function () {
				MCV_volumePoolCreateWindow.close();
			}
		},
		'->',
		{
			text: lang_mcv_volumePool[104],
			id: 'MCV_volumePoolCreatePreviousBtn',
			width: 70,
			disabled: false,
			border: true,
			handler: function () {
				var currentStepPanel = MCV_volumePoolCreateWindow.layout.activeItem;
				var currentStepIndex = MCV_volumePoolCreateWindow.items.indexOf(currentStepPanel);

				MCV_volumePoolCreateWindow.layout.setActiveItem(--currentStepIndex);

				// 버튼 컨트롤
				MCV_volumePoolCreateBtn();
			}
		},
		{
			text: lang_mcv_volumePool[105],
			id: 'MCV_volumePoolCreateNextBtn',
			width: 70,
			disabled: false,
			handler: function () {
				var currentStepPanel = MCV_volumePoolCreateWindow.layout.activeItem;
				var currentStepIndex = MCV_volumePoolCreateWindow.items.indexOf(currentStepPanel);

				MCV_volumePoolCreateWindow.layout.setActiveItem(++currentStepIndex);

				// 버튼 컨트롤
				MCV_volumePoolCreateBtn();
			}
		},
		{
			text: lang_mcv_volumePool[90],
			id: 'MCV_volumePoolCreateOKBtn',
			width: 70,
			disabled: false,
			handler: function (button, event) {
				var oper = this.findParentByType('window').animateTarget.id
							== 'MCV_volumePoolCreateBtn'
								? 'create'
								: 'reconfig';

				// 볼륨풀 생성
				waitWindow(
					lang_mcv_volumePool[0],
					oper == 'create'
						? lang_mcv_volumePool[31]
						: lang_mcv_volumePool[76]
				);

				// 선택된 그리드의 전송값 추출
				var selection = MCV_volumePoolDeviceGrid.getSelectionModel().getSelection();
				var pvs       = [];
				var devices   = [];
				var nodes     = [];

				for (var i=0, len=selection.length; i<len; i++)
				{
					devices.push(selection[i].data);
				}

				// 오름차순 정렬
				devices.sort(function (a, b) {
					return a.Hostname < b.Hostname
							? -1
							: a.Hostname > b.Hostname
								? 1
								: 0;
				});

				for (var i=0, len=devices.length, hostname=null; i<len; i++)
				{
					if (hostname == devices[i].Hostname)
					{
						pvs.push(
							{
								Name: devices[i].Name,
							}
						);

						nodes.pop();

						nodes.push(
							{
								Hostname: hostname,
								PVs: pvs,
							}
						);
					}
					else
					{
						hostname = devices[i].Hostname;
						pvs = [];

						pvs.push(
							{
								Name: devices[i].Name,
							}
						);

						nodes.push(
							{
								Hostname: devices[i].Hostname,
								PVs: pvs,
							}
						);
					}
				}

				// 생성, 수정 구분
				var url   = '/api/cluster/volume/pool/' + oper;
				var parms = {
					Pool_Name: Ext.getCmp('MCV_volumePoolCreatePoolName').getValue(),
					Pool_Type: Ext.getCmp('MCV_volumePoolCreateStep2StorageType').getValue().storageType,
					Pool_Purpose: 'for_data',
					Nodes: nodes,
					Provision: 'thick',
				};

				if (parms.Pool_Type.match(/^(?:EXTERNAL)$/i))
				{
					parms.External_IP   = Ext.getCmp('MCV_volumePoolCreateExtIP').getValue();
					parms.External_Type = Ext.getCmp('MCV_volumePoolCreateExtType').getValue();
				}

				GMS.Ajax.request({
					url: url,
					method: 'POST',
					jsonData: { argument: parms },
					callback: function (options, success, response, decoded) {
						// 데이터 전송 완료 후 wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						if (!success || !decoded.success)
						{
							Ext.MessageBox.alert(lang_mcv_volumePool[0], decoded.msg);
							return;
						}

						// 볼륨풀 목록 LOAD
						MCV_volumePoolLoad();

						Ext.MessageBox.alert(
							lang_mcv_volumePool[0],
							oper == 'create'
								? lang_mcv_volumePool[30]
								: lang_mcv_volumePool[116]
						);

						// 생성 창 닫기
						MCV_volumePoolCreateWindow.hide();
					}
				});
			}
		}
	]
});

// 볼륨풀 생성 버튼 컨트롤
function MCV_volumePoolCreateBtn()
{
	if (MCV_volumePoolCreateWindow.layout.getActiveItem().id == 'MCV_volumePoolCreateStep1')
	{
		Ext.getCmp('MCV_volumePoolCreatePreviousBtn').hide();
		Ext.getCmp('MCV_volumePoolCreateNextBtn').show();
		Ext.getCmp('MCV_volumePoolCreateOKBtn').hide();
	}
	else if (MCV_volumePoolCreateWindow.layout.getActiveItem().id == 'MCV_volumePoolCreateStep2')
	{
		Ext.getCmp('MCV_volumePoolCreatePreviousBtn').show();
		Ext.getCmp('MCV_volumePoolCreateNextBtn').show();
		Ext.getCmp('MCV_volumePoolCreateOKBtn').hide();
		
	}
	else if (MCV_volumePoolCreateWindow.layout.getActiveItem().id == 'MCV_volumePoolCreateStep3')
	{
		var pool_type = Ext.getCmp('MCV_volumePoolCreateStep2StorageType')
							.getValue().storageType;

		// 유형을 선택하지 않았을 경우
		if (typeof(pool_type) == 'undefined')
		{
			Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[108]);
			MCV_volumePoolCreateWindow.layout.setActiveItem('MCV_volumePoolCreateStep2');

			// 버튼 컨트롤
			MCV_volumePoolCreateBtn();
			return false;
		}

		Ext.getCmp('MCV_volumePoolCreatePreviousBtn').show();
		Ext.getCmp('MCV_volumePoolCreateNextBtn').show();
		Ext.getCmp('MCV_volumePoolCreateOKBtn').hide();
	}
	else if (MCV_volumePoolCreateWindow.layout.getActiveItem().id == 'MCV_volumePoolCreateStep4')
	{
		var selection = MCV_volumePoolDeviceGrid.getSelectionModel().getSelection();
		var selected  = [];
		
		// 이름을 입력하지 않았을 경우
		if (Ext.getCmp('MCV_volumePoolCreatePoolName').getValue() == '')
		{
			Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[108]);
			MCV_volumePoolCreateWindow.layout.setActiveItem('MCV_volumePoolCreateStep3');

			// 버튼 컨트롤
			MCV_volumePoolCreateBtn();
			return false;
		}

		if (!Ext.getCmp('MCV_volumePoolCreatePoolName').validate())
		{
			MCV_volumePoolCreateWindow.layout.setActiveItem('MCV_volumePoolCreateStep3');

			// 버튼 컨트롤
			MCV_volumePoolCreateBtn();
			return false;
		}

		var pool_type = Ext.getCmp('MCV_volumePoolCreateStep2StorageType')
							.getValue().storageType;

		// 디스크를 선택하지 않았을 경우
		if (selection.length < 1)
		{
			Ext.getCmp('MCV_volumePoolCreateNextBtn').show();
			Ext.getCmp('MCV_volumePoolCreateOKBtn').hide();

			Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[113]);

			MCV_volumePoolCreateWindow.layout.setActiveItem('MCV_volumePoolCreateStep3');

			// 버튼 컨트롤
			MCV_volumePoolCreateBtn();

			return false;
		}
		else if (pool_type.toUpperCase() == 'Local' && selection.length > 1)
		{
			Ext.getCmp('MCV_volumePoolCreateNextBtn').show();
			Ext.getCmp('MCV_volumePoolCreateOKBtn').hide();

			Ext.MessageBox.alert(
				lang_mcv_volumePool[0],
				lang_mcv_volumePool[114]);

			MCV_volumePoolCreateWindow.layout.setActiveItem('MCV_volumePoolCreateStep3');

			// 버튼 컨트롤
			MCV_volumePoolCreateBtn();

			return false;
		}

		Ext.getCmp('MCV_volumePoolCreatePreviousBtn').show();
		Ext.getCmp('MCV_volumePoolCreateNextBtn').hide();
		Ext.getCmp('MCV_volumePoolCreateOKBtn').show();
		
		// 입력 내용 확인: 볼륨 풀 이름
		var pool_name = Ext.getCmp('MCV_volumePoolCreatePoolName').value;

		Ext.getCmp('MCV_volumePoolCreateStep4PoolName').update(pool_name);

		// 입력 내용 확인: 스토리지 타입
		Ext.getCmp('MCV_volumePoolCreateStep4StorageType').update(pool_type);

		// 선택된 디스크 목록
		MCV_volumePoolSelectedDeviceStore.removeAll();

		// 노드별 장치 목록 - 선택된 목록 LOAD
		for (var i=0; i<selection.length; i++)
		{
			selected.push(selection[i].raw);
		}

		MCV_volumePoolSelectedDeviceStore.loadRawData(selected, false);

		// Gluster/Local 타입일 경우
		if (pool_type.toUpperCase().match(/^(?:GLUSTER|LOCAL)$/))
		{
			MCV_volumePoolDeviceGrid.setTitle(lang_mcv_volumePool[46]);

			// 노드별 장치 목록 - 선택 목록 컨트롤
			var columns = MCV_volumePoolSelectedDeviceGrid.columnManager.getColumns();

			for (var i=0; i<columns.length; i++)
			{
				if (columns[i].dataIndex == 'inclusion')
				{
					continue;
				}
				else if (columns[i].dataIndex == 'In_Use')
				{
					columns[i].setVisible(false);
				}

				columns[i].setVisible(true);
			}

			// External 정보가 아닌 부분 SHOW
			Ext.getCmp('MCV_volumePoolCreateStep4PoolSizePanel').show();

			// External 정보 HIDE
			Ext.getCmp('MCV_volumePoolCreateStep4ExtIPPanel').hide();
			Ext.getCmp('MCV_volumePoolCreateStep4ExtTypePanel').hide();

			// 입력 내용 확인: 볼륨풀 크기
			Ext.getCmp('MCV_volumePoolCreateStep4PoolSize')
				.update(document.getElementById('MCV_volumePoolCreatePoolSize').innerHTML);
		}
		// External 타입일 경우
		else if (pool_type.toUpperCase() == 'EXTERNAL')
		{
			MCV_volumePoolDeviceGrid.setTitle(lang_mcv_volumePool[21]);

			// 노드별 장치 목록 - 선택 목록 컨트롤
			var columns = MCV_volumePoolSelectedDeviceGrid.columnManager.getColumns();

			for (var i=0; i<columns.length; i++)
			{
				if (columns[i].dataIndex == 'inclusion')
				{
					continue;
				}
				else if (columns[i].dataIndex == 'In_Use')
				{
					columns[i].setVisible(false);
				}

				columns[i].setVisible(columns[i].dataIndex == 'Hostname' ? true : false);
			}
			
			// External 정보가 아닌 부분 HIDE
			Ext.getCmp('MCV_volumePoolCreateStep4PoolSizePanel').hide();

			// External 정보 SHOW
			Ext.getCmp('MCV_volumePoolCreateStep4ExtTypePanel').show();

			if (Ext.getCmp('MCV_volumePoolCreateExtType').getValue() == 'NFS')
			{
				Ext.getCmp('MCV_volumePoolCreateStep4ExtIPPanel').show();

				// IP를 입력하지 않았을 경우
				if (Ext.getCmp('MCV_volumePoolCreateExtIP').getValue() == '')
				{
					Ext.MessageBox.alert(
						lang_mcv_volumePool[0],
						lang_mcv_volumePool[109]);

					MCV_volumePoolCreateWindow.layout
						.setActiveItem('MCV_volumePoolCreateStep3');

					// 버튼 컨트롤
					MCV_volumePoolCreateBtn();
					return false;
				}

				// IP 정보 확인
				if (!Ext.getCmp('MCV_volumePoolCreateExtIP').validate())
				{
					MCV_volumePoolCreateWindow.layout
						.setActiveItem('MCV_volumePoolCreateStep3');

					// 버튼 컨트롤
					MCV_volumePoolCreateBtn();
					return false;
				}

				// 입력 내용 확인: External IP
				Ext.getCmp('MCV_volumePoolCreateStep4ExtIP')
					.update(Ext.getCmp('MCV_volumePoolCreateExtIP').getValue());
			}
			else
			{
				Ext.getCmp('MCV_volumePoolCreateStep4ExtIPPanel').hide();
			}

			// 입력 내용 확인: External type
			Ext.getCmp('MCV_volumePoolCreateStep4ExtType')
				.update(Ext.getCmp('MCV_volumePoolCreateExtType').getValue());
		}
	}
}

// 노드별 최대 설정 가능한 동적 할당 크기
function MCV_volumePoolMaxVolumePoolSize()
{
	// 선택한 노드의 개수
	var sm = MCV_volumePoolNodeGrid.getSelectionModel();

	// 선택한 노드 리스트
	var selection = sm.getSelection();

	// 선택한 노드의 볼륨 풀 남은 크기
	var sizes = [];

	// 선택한 노드 중 볼륨 풀 남은 크기 최소값
	var min_size = 0;

	// 선택한 노드의 볼륨 풀 남은 크기 Mb
	var size_mb = 0;

	// 선택한 노드리스트의 최소 남은 용량
	if (selection.length > 0)
	{
		for (var i=0, len=selection.length; i<len; i++)
		{
			var free_size = selection[i].get('In_Use') !== '1'
							// 미사용 중인 노드
							? selection[i].get('Free_Size')
							// 사용 중인 노드
							: selection[i].get('Assign_Size');

			// 선택한 노드의 남은 볼륨 풀 크기 타입
			var unit = free_size.substring(free_size.length - 1);

			// 선택한 노드의 남은 볼륨 풀 크기
			var value = free_size.substring(0, free_size.length - 1);

			if (unit == 'M')
				size_mb = parseInt(value);
			else if (unit == 'G')
				size_mb = value * 1024;
			else if (unit == 'T')
				size_mb = value * 1024 * 1024;
			else if (unit == 'P')
				size_mb = value * 1024 * 1024 * 1024;

			sizes.push(size_mb);
		}

		min_size = sizes.reduce(
			function (previous, current) {
				return previous > current ? current : previous;
			}
		);
	}
	else
	{
		min_size = 0;
	}

	// 씬 풀 메타 LV size인 2GiB 제외
	vol_size_mb = parseFloat(min_size) - 2048;

	var max_size;

	if (parseFloat(min_size) <= 0)
	{
		max_size = '0.00 Byte';
	}
	else
	{
		var value;
		var unit;

		if (vol_size_mb > 1073741824)
		{
			value = ((vol_size_mb / 1024 / 1024 / 1024) * 100) / 100;
			unit  = 'PiB';
		}
		else if (vol_size_mb > 1048576)
		{
			value = ((vol_size_mb / 1024 / 1024) * 100) / 100;
			unit  = 'TiB';
		}
		else if (vol_size_mb > 1024)
		{
			value = ((vol_size_mb / 1024) * 100) / 100;
			unit  = 'GiB';
		}
		else
		{
			value = (vol_size_mb * 100) / 100;
			unit  = 'MiB';
		}

		value = value.toFixed(2);
		max_size = value.toString().substring(0, value.toString().indexOf('.') + 3)
					+ ' '
					+ unit;
	}

	Ext.getCmp('MCV_vpoolThinMaxSize').setText(max_size);
}

// 볼륨 풀 생성 노드 목록 GRID
// 볼륨 풀 생성 노드 목록 GRID 모델
Ext.define(
	'MCV_volumePoolNodeModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Hostname', sortType: 'asHostName' },
			'HW_Status', 'SW_Status', 'Used', 'Free_Size',
			'Size', 'In_Use', 'Assign_Size'
		]
	}
);

// 볼륨 풀 생성 노드 목록 GRID 스토어
var MCV_volumePoolNodeStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCV_volumePoolNodeModel',
		sorters: [
			{ property: 'Hostname', direction: 'ASC' },
			{ property: 'Name', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				idProperty: 'Hostname',
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 데이터 전송 완료 후 wait 제거
				if (waitMsgBox)
				{
					waitMsgBox.hide();
					waitMsgBox = null;
				}

				// 예외 처리에 따른 동작
				if (!success)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcv_volumePool[0] + '",'
						+ '"content": "' + lang_mcv_volumePool[27] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}
			}
		}
	});

// 볼륨 풀 생성 노드 목록 GRID
var MCV_volumePoolNodeGrid = Ext.create('BaseGridPanel', {
	id: 'MCV_volumePoolNodeGrid',
	store: MCV_volumePoolNodeStore,
	multiSelect: false,
	title: lang_mcv_volumePool[21],
	height: 300,
	selModel: {
		selType: 'checkboxmodel',
		checkOnly: 'true',
		listeners: {
			selectall: function () {
				MCV_volumePoolMaxVolumePoolSize();
			},
			deselectall: function () {
				MCV_volumePoolMaxVolumePoolSize();
			}
		}
	},
	columns: [
		{
			flex: 1,
			text: lang_mcv_volumePool[84],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Hostname'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[66],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'HW_Status'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[67],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'SW_Status'
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[5],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Used'
		},
		{
			text: lang_mcv_volumePool[17],
			width: 140,
			autoSizeColumn: true,
			minWidth: 140,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Free_Size'
		},
		{
			flex: 1,
			dataIndex: 'Assign_Size',
			hidden: true
		},
		{
			flex: 1,
			text: lang_mcv_volumePool[69],
			sortable: true,
			menuDisabled: true,
			dataIndex: 'In_Use',
			renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
				if (value == '1')
				{
					// 사용 중
					return '<span style="color:green">'+lang_mcv_volumePool[70]+'</span>';
				}
				else
				{
					// 사용 안함
					return '<span style="color:gray">'+lang_mcv_volumePool[71]+'</span>';
				}
			}
		}
	],
	listeners: {
		selectionchange: function (model, records) {
			MCV_volumePoolMaxVolumePoolSize();
		}
	},
	viewConfig: {
		forceFit: true,
		loadMask: false
	}
});

// 볼륨 풀 동적 할당 PANEL
var MCV_volumePoolThinPanel = Ext.create('BaseFormPanel', {
	id: 'MCV_volumePoolThinPanel',
	frame: false,
	items:[
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			style: { marginBottom: '30px' },
			html: lang_mcv_volumePool[12]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: {marginBottom: '20px'},
			hidden: true,
			items: [
				{
					xtype: 'label',
					id: 'MCV_vpoolThinBasePoolName',
					style: { marginTop: '5px', marginLeft: '10px' }
				}
			]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginBottom: '20px' },
			hidden: true,
			items: [
				{
					xtype: 'label',
					text: lang_mcv_volumePool[1]+': ',
					width: 130
				},
				{
					xtype: 'label',
					id: 'MCV_vpoolThinPoolName'
				}
			]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					text: lang_mcv_volumePool[14]+': ',
					minWidth: 130
				},
				{
					xtype: 'label',
					id: 'MCV_vpoolThinMaxSize',
					text: '0.00 Byte',
					style: { marginLeft: '10px' }
				}
			]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			layout: 'hbox',
			maskOnDisable: false,
			style: { marginBottom: '20px' },
			items: [
				{
					xtype: 'label',
					text: lang_mcv_volumePool[13]+': ',
					minWidth: 130
				},
				{
					xtype: 'textfield',
					id: 'MCV_vpoolThinAssign',
					allowBlank: false,
					vtype: 'reg_realNumber',
					enableKeyEvents: true,
					style: { marginLeft: '10px' }
				},
				{
					xtype: 'BaseComboBox',
					id: 'MCV_vpoolThinAssignType',
					hideLabel: true,
					style: { marginLeft: '10px' },
					width: 70,
					store: new Ext.data.SimpleStore({
						fields: ['AssignType', 'AssignCode'],
						data: [
							['GiB', 'GiB'],
							['TiB', 'TiB']
						]
					}),
					value: 'GiB',
					displayField: 'AssignType',
					valueField: 'AssignCode'
				},
				{
					xtype: 'textfield',
					id: 'MCV_vpoolThinSize',
					hidden: true
				},
				{
					xtype: 'BaseComboBox',
					id: 'MCV_vpoolThinSizeType',
					hideLabel: true,
					style: { marginLeft: '10px' },
					width: 70,
					store: new Ext.data.SimpleStore({
						fields: ['AssignType', 'AssignCode'],
						data: [
							['GiB', 'GiB'],
							['TiB', 'TiB']
						]
					}),
					value: 'GiB',
					displayField: 'AssignType',
					valueField: 'AssignCode',
					hidden: true
				}
			]
		},
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0;',
			items: [ MCV_volumePoolNodeGrid ]
		}
	]
});

// 볼륨 풀 동적 할당 WINDOW
var MCV_volumePoolThinWindow = Ext.create('BaseWindowPanel', {
	id: 'MCV_volumePoolThinWindow',
	title: lang_mcv_volumePool[47],
	maximizable: false,
	autoHeight: true,
	width: 750,
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			bodyStyle: 'padding: 0;',
			items: [ MCV_volumePoolThinPanel ]
		}
	],
	fbar: [
		'->',
		{
			text: lang_mcv_volumePool[10],
			id: 'MCV_vpoolThinCreateBtn',
			width: 70,
			disabled: false,
			handler: function () {
				MCV_vpoolThinCreateBtn();
			}
		},
		{
			text: lang_mcv_volumePool[52],
			id: 'MCV_vpoolThinReconfigBtn',
			width: 70,
			disabled: false,
			handler: function () {
				MCV_vpoolThinReconfigBtn();
			}
		},
		{
			text: lang_mcv_volumePool[51],
			id: 'MCV_vpoolThinDeleteBtn',
			width: 70,
			disabled: false,
			handler: function () {
				MCV_vpoolThinDeleteBtn();
			}
		}
	]
});

// 볼륨 풀 동적 할당 생성 버튼
function MCV_vpoolThinCreateBtn()
{
	if (!Ext.getCmp('MCV_vpoolThinAssign').isValid())
	{
		return false;
	}

	var selectNode = MCV_volumePoolNodeGrid.getSelectionModel().getSelection();

	if (selectNode < 1)
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[86]);
		return false;
	}

	//최대 생성 사능 용량 확인
	var maxSizeObj = document.getElementById('MCV_vpoolThinMaxSize').innerHTML;

	//최대 생성 가능 볼륨타입
	var maxVolumeSizeType = trim(maxSizeObj.substring(maxSizeObj.length-3));

	//최대 생성 가능 볼륨크기
	var maxVolumeSize = trim(maxSizeObj.substring(0, maxSizeObj.length-3));
	var maxVolumeSizeMb;

	if (maxVolumeSizeType == "MiB")
	{
		maxVolumeSizeMb = maxVolumeSize;
	}
	else if (maxVolumeSizeType == "GiB")
	{
		maxVolumeSizeMb = maxVolumeSize * 1024;
	}
	else if (maxVolumeSizeType == "TiB")
	{
		maxVolumeSizeMb = maxVolumeSize * 1024 * 1024;
	}
	else if (maxVolumeSizeType == "PiB")
	{
		maxVolumeSizeMb = maxVolumeSize * 1024 * 1024 * 1024;
	}

	// 입력한 용량 확인(단위)
	var inputVolumeSizeType = Ext.getCmp('MCV_vpoolThinAssignType').getValue();

	// 입력한 용량 확인(크기)
	var inputVolumeSize = Ext.getCmp('MCV_vpoolThinAssign').getValue();
	var inputVolumeSizeMb;

	if (inputVolumeSizeType == "MiB")
	{
		inputVolumeSizeMb = inputVolumeSize;
	}
	else if (inputVolumeSizeType == "GiB")
	{
		inputVolumeSizeMb = inputVolumeSize * 1024;
	}
	else if (inputVolumeSizeType == "TiB")
	{
		inputVolumeSizeMb = inputVolumeSize * 1024 * 1024;
	}
	else if (inputVolumeSizeType == "PiB")
	{
		inputVolumeSizeMb = inputVolumeSize * 1024 * 1024 * 1024;
	}

	if (inputVolumeSizeMb > maxVolumeSizeMb)
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[29]);
		return false;
	}

	var Capacity = inputVolumeSize + inputVolumeSizeType;
	var percent = '';

	percent = Math.floor(inputVolumeSize / maxVolumeSize * 100);

	if (percent == 100)
	{
		percent = percent + '%FREE';
	}
	else
	{
		percent = null;
	}

	// 플 타입
	var selectPoolType = MCV_volumePoolGrid.getSelectionModel().getSelection()[0].get('Pool_Type');

	// 선택한 노드 목록
	var nodeInfoArray = [];
	var selectNode = MCV_volumePoolNodeGrid.getSelectionModel().getSelection();

	for (var i=0, len=selectNode.length; i<len; i++)
	{
		nodeInfoArray.push({ Hostname: selectNode[i].get('Hostname') });
	}

	Ext.MessageBox.confirm(
		lang_mcv_volumePool[0],
		lang_mcv_volumePool[77],
		function (btn, text) {
			if (btn != 'yes')
				return;

			waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[57]);

			Ext.Ajax.request({
				url: '/api/cluster/volume/pool/create',
				timeout: 60000,
				method: 'POST',
				jsonData: {
					argument: {
						Pool_Type: selectPoolType,
						Base_Pool: Ext.getCmp('MCV_vpoolThinBasePoolName').text,
						Pool_Name: Ext.getCmp('MCV_vpoolThinPoolName').text,
						Pool_Purpose: 'for_data',
						Capacity: Capacity,
						Capacity_Percent : percent,
						Nodes: nodeInfoArray,
						Provision: 'thin',
					},
				},
				callback: function (options, success, response) {
					// 데이터 전송 완료 후 wait 제거
					if (waitMsgBox)
					{
						waitMsgBox.hide();
						waitMsgBox = null;
					}

					// 생성창 닫기
					MCV_volumePoolThinWindow.hide();

					var responseData = Ext.decode(response.responseText);

					if (!success || !responseData.success)
					{
						Ext.MessageBox.alert(lang_mcv_volumePool[0], responseData.msg);
						return;
					}

					MCV_volumePoolLoad();
					Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[56]);
				}
			});
		}
	);
}

// 볼륨 풀 동적 할당 관리 수정 버튼
function MCV_vpoolThinReconfigBtn()
{
	if (!Ext.getCmp('MCV_vpoolThinAssign').isValid())
	{
		return false;
	}

	var selection = MCV_volumePoolNodeGrid.getSelectionModel().getSelection();

	if (selection < 1)
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[86]);
		return false;
	}

	// 최대 생성 사능 용량 확인
	var max_size = document.getElementById('MCV_vpoolThinMaxSize').innerHTML;
	var max_size_unit;
	var max_size_value;

	if (max_size == '0.00 Byte')
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[29]);
		return false;
	}
	else
	{
		// 최대 생성 가능 볼륨크기
		max_size_value = trim(max_size.substring(0, max_size.length-3));

		// 최대 생성 가능 볼륨타입
		max_size_unit  = trim(max_size.substring(max_size.length-3));
	}

	if (max_size_unit == "MiB")
	{
		max_size = max_size_vlaue;
	}
	else if (max_size_unit == "GiB")
	{
		max_size = max_size_value * 1024;
	}
	else if (max_size_unit == "TiB")
	{
		max_size = max_size_value * 1024 * 1024;
	}
	else if (max_size_unit == "PiB")
	{
		max_size = max_size_value * 1024 * 1024 * 1024;
	}

	var new_size_unit  = Ext.getCmp('MCV_vpoolThinAssignType').getValue();
	var new_size_value = Ext.getCmp('MCV_vpoolThinAssign').getValue();
	var new_size;

	if (new_size_unit == "MiB")
	{
		new_size = new_size_value;
	}
	else if (new_size_unit== "GiB")
	{
		new_size = new_size_value * 1024;
	}
	else if (new_size_unit == "TiB")
	{
		new_size = new_size_value * 1024 * 1024;
	}
	else if (new_size_unit == "PiB")
	{
		new_size = new_size_value * 1024 * 1024 * 1024;
	}

	if (new_size > max_size)
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[29]);
		return false;
	}

	var curr_size_unit  = Ext.getCmp('MCV_vpoolThinSizeType').getValue();
	var curr_size_value = Ext.getCmp('MCV_vpoolThinSize').getValue();
	var curr_size;

	if (curr_size_unit == "MiB")
	{
		curr_size = curr_size_value;
	}
	else if (curr_size_unit == "GiB")
	{
		curr_size = curr_size_value * 1024;
	}
	else if (curr_size_unit == "TiB")
	{
		curr_size = curr_size_value * 1024 * 1024;
	}
	else if (curr_size_unit == "PiB")
	{
		curr_size = curr_size_value * 1024 * 1024 * 1024;
	}

	if (curr_size > new_size)
	{
		Ext.MessageBox.alert(
			lang_mcv_volumePool[0],
			lang_mcv_volumePool[83].replace('@',curr_size_value + curr_size_unit));

		return false;
	}

	// 노드별 동적 할당 크기
	var size = new_size_value + new_size_unit;

	// 선택한 노드 목록
	var nodes = [];

	for (var i=0; i<selection.length;  i++)
	{
		nodes.push({ Hostname: selection[i].get('Hostname') });
	}

	Ext.MessageBox.confirm(
		lang_mcv_volumePool[0],
		lang_mcv_volumePool[81],
		function (btn, text) {
			if (btn != 'yes')
				return;

			waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[79]);

			// 클러스터 볼륨에서 사용 중인지 체크
			GMS.Ajax.request({
				url: '/api/cluster/volume/list',
				callback: function (options, success, response, decoded) {
					// 예외 처리에 따른 동작
					if (!success || !decoded.success)
						return;

					var vol_list = decoded.entity;
					var target   = Ext.getCmp('MCV_vpoolThinPoolName').text;

					for (var i=0; i<vol_list.length; i++)
					{
						if (vol_list[i].Pool_Name == target)
						{
							Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[72]);
							return false;
						}
					}

					// 볼륨 풀 동적 할당 확장
					GMS.Ajax.request({
						url: '/api/cluster/volume/pool/reconfig',
						timeout: 60000,
						method: 'POST',
						jsonData: {
							argument: {
								Pool_Type: MCV_volumePoolGrid.getSelectionModel().getSelection()[0].get('Pool_Type'),
								Pool_Name: Ext.getCmp('MCV_vpoolThinPoolName').text,
								Base_Pool: MCV_volumePoolGrid.getSelectionModel().getSelection()[0].get('Pool_Name'),
								Capacity: size,
								Nodes: nodes
							}
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							// 생성창 닫기
							MCV_volumePoolThinWindow.hide();

							MCV_volumePoolLoad();
							Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[78]);
						}
					});
				}
			});
		}
	);
}

// 볼륨 풀 동적 할당 관리 제거 버튼
function MCV_vpoolThinDeleteBtn()
{
	Ext.MessageBox.confirm(
		lang_mcv_volumePool[0],
		lang_mcv_volumePool[53],
		function (btn, text) {
			if (btn != 'yes')
				return;

			waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[54]);

			// 클러스터 볼륨에서 사용 중인지 체크
			GMS.Ajax.request({
				url: '/api/cluster/volume/list',
				callback: function (options, success, response, decoded) {
					if (!success || !decoded.success)
						return;

					var vol_list = decoded.entity;
					var target   = Ext.getCmp('MCV_vpoolThinPoolName').text;

					for (var i=0; i<vol_list.length; i++)
					{
						if (vol_list[i].Pool_Name == target)
						{
							Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[64]);
							return false;
						}
					}

					// 볼륨 풀 동적 할당 제거
					GMS.Ajax.request({
						url: '/api/cluster/volume/pool/remove',
						timeout: 60000,
						jsonData: {
							argument: {
								Pool_Name: Ext.getCmp('MCV_vpoolThinPoolName').text,
								Pool_Type: MCV_volumePoolGrid.getSelectionModel().getSelection()[0].get('Pool_Type')
							}
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
								return;

							MCV_volumePoolThinWindow.hide();

							MCV_volumePoolLoad();
							Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[63]);
						}
					});
				}
			});
		}
	);
}

/*
// 볼륨 풀 생성(vg_tier)
function MCV_volumePoolCreateWindowBtn()
{
	// 노드별 장치 목록 검사
	if (MCV_volumePoolDeviceGrid.getSelectionModel().getCount() == 0)
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[65]);
		return false;
	}

	var selection = MCV_volumePoolDeviceGrid.getSelectionModel().getSelection();
	var nodes     = [];

	for (var i=0, hostname=null, pvs=[]; i<selection.length; i++)
	{
		if (hostname == selection[i].get('Hostname'))
		{
			pvs.push({ Name: selection[i].get('Name') });

			nodes.pop();
			nodes.push({ Hostname: hostname, PVs: pvs });
		}
		else
		{
			hostname = selection[i].get('Hostname');
			pvs      = [];

			pvs.push({ Name: selection[i].get('Name') });
			nodes.push({ Hostname: hostname, PVs: pvs });
		}
	}

	Ext.MessageBox.confirm(
		lang_mcv_volumePool[0],
		lang_mcv_volumePool[82],
		function (btn, text) {
			if (btn != 'yes')
				return;

			waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[31]);

			GMS.Ajax.request({
				url: '/api/cluster/volume/pool/create',
				method: 'POST',
				jsonData: {
					argument: {
						Pool_Name: 'vg_tier',
						Pool_Purpose: 'for_tiering',
						Nodes: nodes,
						Provision: 'thick',
					}
				},
				callback: function (options, success, response, decoded) {
					// 데이터 전송 완료 후 wait 제거
					if (waitMsgBox)
					{
						waitMsgBox.hide();
						waitMsgBox = null;
					}

					// 생성창 닫기
					MCV_volumePoolCreateWindow.hide();

					if (!success || !decoded.success)
					{
						Ext.MessageBox.alert(lang_mcv_volumePool[0], decoded.msg);
						return;
					}

					MCV_volumePoolLoad();
					Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[30]);
				}
			});
		}
	);
}
*/

// 배열 정렬
function sortObjectsArray(objectsArray, sortKey)
{
	// Quick Sort:
	var retVal;

	if (1 >= objectsArray.length)
		return objectsArray;

	// middle index
	var pivotIndex = Math.floor((objectsArray.length - 1) / 2);

	// value in the middle index
	var pivotItem = objectsArray[pivotIndex];
	var less = [], more = [];

	// remove the item in the pivot position
	objectsArray.splice(pivotIndex, 1);
	objectsArray.forEach(function (value, index, array)
		{
			// compare the 'sortKey' proiperty
			value[sortKey] <= pivotItem[sortKey]
				? less.push(value)
				: more.push(value);
		}
	);

	retVal = sortObjectsArray(less, sortKey)
				.concat([pivotItem], sortObjectsArray(more, sortKey));

	return retVal;
}

/*
// 볼륨 풀 재설정
function MCV_volumePoolReconfigWindowBtn()
{
	// 노드별 장치 목록 검사
	if (MCV_volumePoolDeviceGrid.getSelectionModel().getCount() == 0)
	{
		Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[65]);
		return false;
	}

	var selection = MCV_volumePoolDeviceGrid.getSelectionModel().getSelection();
	var devices   = [];

	for (var i=0, len=selection.length; i<len; i++)
	{
		devices.push(
			{
				Serial: selection[i].get('Serial'),
				Hostname: selection[i].get('Hostname'),
				Name: seletion[i].get('Name'),
			}
		);
	}

	devices = sortObjectsArray(devices, 'Hostname');

	var hostname = null;
	var nodes    = [];

	for (var i=0, pvs=[]; i<devices.length; i++)
	{
		if (hostname == devices[i].Hostname)
		{
			pvs.push(
				{
					Name: devices[i].Name
				}
			);

			nodes.pop();
			nodes.push({ Hostname: hostname, PVs: pvs });
		}
		else
		{
			hostname = devices[i].Hostname;

			pvs = [];
			pvs.push({ Name: devices[i].Name });

			nodes.push({ Hostname: hostname, PVs: pvs });
		}
	}

	Ext.MessageBox.confirm(
		lang_mcv_volumePool[0],
		lang_mcv_volumePool[75],
		function (btn, text) {
			if (btn != 'yes')
				return;

			waitWindow(lang_mcv_volumePool[0], lang_mcv_volumePool[76]);

			Ext.Ajax.request({
				url: '/api/cluster/volume/pool/reconfig',
				method: 'POST',
				jsonData: {
					argument: {
						Pool_Name: document.getElementById('MCV_volumePoolCreatePoolNameLabel').innerHTML,
						Pool_Purpose: 'for_tiering',
						Nodes: nodes
					}
				},
				callback: function (options, success, response) {
					// 데이터 전송 완료 후 wait 제거
					if (waitMsgBox)
					{
						waitMsgBox.hide();
						waitMsgBox = null;
					}

					// 생성창 닫기
					MCV_volumePoolCreateWindow.hide();

					var responseData = Ext.decode(response.responseText);

					if (!success || !responseData.success)
					{
						Ext.MessageBox.alert(lang_mcv_volumePool[0], responseData.msg);
						return;
					}

					MCV_volumePoolLoad();
					Ext.MessageBox.alert(lang_mcv_volumePool[0], lang_mcv_volumePool[30]);
				}
			});
		}
	);
}
*/

// 클러스터 볼륨 관리-> 볼륨 풀 관리
Ext.define('/admin/js/manager_cluster_volumePool', {
	extend: 'BasePanel',
	id: 'manager_cluster_volumePool',
	bodyStyle: 'padding: 0',
	load: function () {
		MCV_volumePoolLoad();
	},
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			bodyStyle: 'padding: 20px;',
			items: [MCV_volumePoolGrid]
		}
	]
});
