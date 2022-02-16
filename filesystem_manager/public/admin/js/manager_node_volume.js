/*
 * Duplicated with manger_node_disk.js
 * We have refactoring our web manager code so we should remove these
 * duplicated code ASAP.
 */

// 블록 장치 모델
Ext.define(
	'MNV_blockDeviceModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'Name',
			'Serial',
			'Vendor',
			'Model',
			'Type',
			'Transport',
			'Size',
			'Is_OS',
			'In_Use',
		]
	}
);

// 블록 장치 스토어
var MNV_blockDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_blockDeviceModel',
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			}
		}
	}
);

// 블록 장치 그리드
var MNV_blockDeviceGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNV_blockDeviceGrid',
		title: lang_mns_smart[6],
		height: 300,
		style: {
			margin: '20px',
		},
		store: MNV_blockDeviceStore,
		selModel: {
			selType: 'checkboxmodel',
			listeners: {
				selectionchange: function (selmodel, selected, eOpts) {
					Ext.getCmp('MNV_PVCreateWindow')
						.down('#doBtn')
						.setDisabled(selected.length == 0);
				},
			},
		},
		columns: [
			{
				flex: 1,
				text: lang_mnd_disk[5],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Name',
			},
			{
				flex: 1,
				text: lang_common[31],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Serial',
			},
			{
				flex: 1,
				text: lang_mnd_disk[7],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Vendor',
			},
			{
				flex: 1,
				text: lang_mnd_disk[8],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Model',
			},
			{
				flex: 1,
				text: lang_common[12],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Type',
			},
			{
				flex: 1,
				text: lang_common[17],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Transport',
			},
			{
				flex: 1,
				text: lang_mnd_disk[9],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Size',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value * 1024);
				}
			},
		],
	}
);

function doBlockLoad()
{
	// 목록 초기화
	MNV_blockDeviceStore.removeAll();

	// 블록 장치 목록 마스크 표시
	var blockDeviceLoadMask = new Ext.LoadMask(
		Ext.getCmp('MNV_blockDeviceGrid'),
		{
			msg: lang_mnd_disk[49],
		}
	);

	blockDeviceLoadMask.show();

	// 블록 장치 목록 받아오기
	GMS.Cors.request({
		url: '/api/block/device/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			blockDeviceLoadMask.hide();

			if (!success || !decoded.success)
			{
				return;
			}

			// 블록 장치 목록 로드
			MNV_blockDeviceStore.loadRawData(decoded);
			MNV_blockDeviceStore.clearFilter();

			MNV_blockDeviceStore.filter(
				function (record) {
					return (!record.get('Name').match(/\/sr/)
						&& !record.get('In_Use'));
				}
			);
		}
	});
};

/*
 * 페이지 로드 시 실행 함수
 */
function MNV_load()
{
	doPVLoad(MNV_PVGrid);
	doVGLoad();
	doLVLoad();
};

// 물리 디스크 모델
Ext.define(
	'MNV_PVModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'PV_Name',
			'PV_Node',
			'PV_Size',
			'PV_SizeByte',
			'PV_VGName',
			{
				name: 'SCSI_ID',
				mapping: 'PV_SCSIInfo.SCSI_ID',
			},
			{
				name: 'SCSI_Vendor',
				mapping: 'PV_SCSIInfo.SCSI_Vendor',
			},
			{
				name: 'SCSI_Model',
				mapping: 'PV_SCSIInfo.SCSI_Model',
			},
		]
	}
);

// 물리 디스크 스토어
var MNV_PVStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_PVModel',
		sorters: [
			{
				property: 'PV_Name',
				direction: 'ASC',
			},
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			},
		},
	}
);

var MNV_PVGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNV_PVGrid',
		title: lang_mnd_disk[4],
		height: 300,
		style: {
			marginBottom: '20px',
		},
		store: MNV_PVStore,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'SINGLE',
			allowDeselect: true,
			listeners: {
				selectionchange: function (selmodel, selected, eOpts) {
					MNV_PVGrid
						.down('#removeBtn')
						.setDisabled(
							selected.length == 0
							|| selected[0].get('PV_VGName') != ''
						);
				}
			},
		},
		columns: [
			{
				flex: 1,
				text: lang_mnd_disk[5],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'PV_Name',
			},
			{
				flex: 1,
				text: lang_mnd_disk[6],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'SCSI_ID',
			},
			{
				flex: 1,
				text: lang_mnd_disk[7],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'SCSI_Vendor',
			},
			{
				flex: 1,
				text: lang_mnd_disk[8],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'SCSI_Model',
			},
			{
				flex: 1,
				text: lang_mnd_disk[9],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'PV_SizeByte',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value);
				}
			},
			{
				flex: 1,
				text: lang_mnd_disk[10],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'PV_VGName',
			},
		],
		tbar: [
			{
				text: lang_mnv_volume[19],
				itemId: 'createBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					MNV_PVCreateWindow.animateTarget = this;
					MNV_PVCreateWindow.show();
				}
			},
			{
				text: lang_mnv_volume[55],
				itemId: 'removeBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					// Validate selected PV can be deleted
					var selection = MNV_PVGrid.getSelectionModel().getSelection();

					Ext.MessageBox.show({
						title: lang_mnv_volume[83],
						msg: lang_mnv_volume[84],
						icon: Ext.MessageBox.QUESTION,
						buttons: Ext.MessageBox.YESNO,
						fn: function (btn, text) {
							if (btn != 'yes')
								return;

							doPVRemove(selection[0].get('PV_Name'));
						}
					});
				}
			},
		],
	}
);

var MNV_PVCreateWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNV_PVCreateWindow',
		title: lang_mnv_volume[76],
		maximizable: false,
		autoHeight: true,
		width: 600,
		layout: 'fit',
		items: [
			MNV_blockDeviceGrid,
		],
		buttons: [
			{
				text: lang_common[5],
				itemId: 'doBtn',
				disabled: true,
				handler: function () {
					var win  = this.up('window');
					var grid = win.down('grid');

					var devices = grid.getSelectionModel().getSelection().map(
						function (record)
						{
							return record.get('Name');
						}
					);

					Ext.MessageBox.confirm(
						lang_mnv_volume[76],
						(devices.length > 1 ? lang_mnv_volume[78] : lang_mnv_volume[77]),
						function (btn, text) {
							if (btn != 'yes')
								return;

							doPVCreate(devices);
						}
					);
				},
			},
			{
				text: lang_common[8],
				itemId: 'cancelBtn',
				handler: function () {
					var win = this.up('window');
					win.close();
				}
			},
		],
		listeners: {
			show: function () {
				doBlockLoad();
			}
		},
	}
);


/*
 * 논리 디스크 정보
 */
// 논리 디스크 모델
Ext.define(
	'MNV_VGModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'VG_Name',
			'VG_Size',
			'VG_SizeByte',
			'VG_Used',
			'VG_UsedByte',
			'VG_UseRate',
			'VG_Purpose',
			'VG_PVs',
			'VG_LVNum',
		]
	}
);

// 논리 디스크 스토어
var MNV_VGStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_VGModel',
		sorters: [
			{ property: 'VG_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			}
		}
	}
);

// 논리 디스크 그리드
var MNV_VGGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNV_VGGrid',
		store: MNV_VGStore,
		multiSelect: false,
		title: lang_mnv_volume[8],
		height: 300,
		style: {
			marginBottom: '20px'
		},
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			mode: 'SINGLE',
			allowDeselect: true,
			listeners: {
				selectionchange: function (model, record, index, eOpts) {
					var grid = Ext.getCmp('MNV_VGGrid');

					MNV_VGSelect(grid, record);

					grid.down('#removeBtn').setDisabled(
						record.length == 0 ? true
						: record[0].get('VG_LVNum') > 0 ? true
						: false
					);

					['#extendBtn', '#reduceBtn']
						.forEach(
							function (r)
							{
								grid.down(r).setDisabled(
									record.length == 0
								);
							}
						);
				},
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mnv_volume[4],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'VG_Name'
			},
			{
				dataIndex: 'VG_SizeByte',
				hidden : true
			},
			{
				flex: 1,
				text: lang_mnv_volume[5],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'VG_SizeByte',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value);
				}
			},
			{
				flex: 1,
				text: lang_mnv_volume[6],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'VG_UsedByte',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value);
				}
			},
			{
				xtype: 'componentcolumn',
				flex: 1,
				text: lang_mnv_volume[7],
				sortable : true,
				menuDisabled : true,
				dataIndex: 'VG_UseRate',
				renderer: function (v, m, r) {
					var rateValue = parseFloat(v);

					return {
						xtype: 'progressbar',
						value: rateValue / 100,
						text: v
					}
				}
			}
		],
		tbar: [
			{
				text: lang_mnv_volume[19],
				itemId: 'createBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					// Show the window to select PVs
					Ext.getCmp('volumeGroupName').reset();
					MNV_VGWindow.animateTarget = this;
					MNV_VGWindow.show();
				}
			},
			{
				text: lang_mnd_disk[18],
				itemId: 'extendBtn',
				iconCls: 'b-icon-increase',
				disabled: true,
				handler: function () {
					// Show the window to select PVs
					MNV_VGWindow.animateTarget = this;
					MNV_VGWindow.show();
				}
			},
			{
				text: lang_common[47],
				itemId: 'reduceBtn',
				iconCls: 'b-icon-reduce',
				disabled: true,
				handler: function () {
					// Show the window to select PVs
					MNV_VGWindow.animateTarget = this;
					MNV_VGWindow.show();
				}
			},
			{
				text: lang_mnv_volume[55],
				id: 'removeBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				handler: function () {
					var selection = MNV_VGGrid.getSelectionModel().getSelection();

					Ext.MessageBox.confirm(
						lang_mnd_disk[25],
						lang_mnd_disk[21],
						function (btn, text) {
							if (btn != 'yes')
								return;

							doVGRemove(selection[0].get('VG_Name'));
						}
					);
				}
			},
		],
	}
);

var MNV_VGWindowPVStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_PVModel',
		sorters: [
			{
				property: 'PV_Name',
				direction: 'ASC',
			},
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			},
		},
	}
);

var MNV_VGWindowPVGrid = Ext.create(
	'BaseGridPanel',
	{
		width: 580,
		autoHeight: true,
		store: MNV_VGWindowPVStore,
		selModel: {
			selType: 'checkboxmodel',
			mode: 'MULTI',
			allowDeselect: true,
			showHeaderCheckbox: false,
			listeners: {
				selectionchange: function (selmodel, selected, eOpts) {
					var win = Ext.getCmp('MNV_VGWindow');

					switch (win.animateTarget.itemId)
					{
						case 'createBtn':
							win.down('#doBtn')
								.setDisabled(selected.length == 0);

							break;
						case 'extendBtn':
							win.down('#doBtn')
								.setDisabled(selected.length == 0);

							break;
						case 'reduceBtn':
							var devices
								= getUnselectedDevices(MNV_VGWindowPVGrid);

							win.down('#doBtn')
								.setDisabled(devices.length == 0);

							break;
						default:
					}
				},
			},
		},
		columns: [
			{
				flex: 1,
				text: lang_mnd_disk[5],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'PV_Name',
			},
			{
				flex: 1,
				text: lang_mnd_disk[7],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'SCSI_Vendor',
			},
			{
				flex: 1,
				text: lang_mnd_disk[8],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'SCSI_Model',
			},
			{
				flex: 1,
				text: lang_mnd_disk[9],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'PV_SizeByte',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value);
				}
			},
		],
		listeners: {
			beforedeselect: function (me, record, index, eOpts) {
				var btn = MNV_VGWindow.animateTarget;
				var vgs = MNV_VGGrid.getSelectionModel().getSelection();
				var pvs = MNV_VGWindowPVGrid.getSelectionModel().getSelection();

				switch (btn.itemId)
				{
					case 'reduceBtn':
						if (pvs.length == 1)
						{
							return false;
						}

						/*
						 * TODO: PV extent validation
						if (record.get('PV_VGName') == vg[0].get('VG_Name'))
						{
							return false;
						}
						*/
						break;
					default:
						// TODO: Exception handling
				}

				return true;
			}
		},
	},
);

function getUnselectedDevices(grid)
{
	var vgs = MNV_VGGrid.getSelectionModel().getSelection();

	var pvs = vgs[0].get('VG_PVs').map(
		function (pv)
		{
			return pv.name;
		}
	);

	var devices = [];

	grid.getStore().getRange().forEach(
		function (r)
		{
			if (!grid.getSelectionModel().isSelected(r)
				&& pvs.includes(r.get('PV_Name')))
			{
				devices.push(r.get('PV_Name'));
			}
		}
	);

	return devices;
}

var MNV_VGWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNV_VGWindow',
		maximizable: false,
		autoHeight: true,
		width: 600,
		layout: 'anchor',
		defaults: {
			anchor: '100% 90%',
		},
		bodyStyle: {
			padding: '20px',
		},
		items: [
			{	
				id: 'volumeGroupName',
				xtype: 'textfield',
				itemId: 'Name',
				fieldLabel: lang_mnv_volume[41],
				labelSeparator: '',
				labelWidth: 100,
				allowBlank: false,
				style: {
					marginBottom: '20px',
				},
			},
			MNV_VGWindowPVGrid,
		],
		buttons: [
			{
				text: lang_common[3],
				itemId: 'doBtn',
				disabled: true,
				handler: function () {
					var win  = this.up('window');
					var grid = win.down('grid');
					var btn  = win.animateTarget;

					var vgs = MNV_VGGrid.getSelectionModel().getSelection();

					switch (btn.itemId)
					{
						case 'createBtn':
							var devices = grid.getSelectionModel().getSelection().map(
								function (record)
								{
									return record.get('PV_Name');
								}
							);

							Ext.MessageBox.confirm(
								lang_mnv_volume[87],
								lang_mnv_volume[88],
								function (btn, text) {
									if (btn != 'yes')
										return;

									doVGCreate(
										win.down('#Name').getValue(),
										devices
									);
								}
							);

							break;
						case 'extendBtn':
							var devices = grid.getSelectionModel().getSelection().map(
								function (record)
								{
									return record.get('PV_Name');
								}
							);

							Ext.MessageBox.confirm(
								lang_mnv_volume[91],
								lang_mnv_volume[92],
								function (btn, text) {
									if (btn != 'yes')
										return;

									doVGExtend(
										vgs[0].get('VG_Name'),
										devices
									);
								}
							);
							break;
						case 'reduceBtn':
							// Get unselected PVs
							var devices
								= getUnselectedDevices(MNV_VGWindowPVGrid);

							Ext.MessageBox.confirm(
								lang_mnv_volume[95],
								lang_mnv_volume[96],
								function (btn, text) {
									if (btn != 'yes')
										return;

									doVGReduce(
										vgs[0].get('VG_Name'),
										devices
									);
								}
							);
							break;
						default:
							// TODO: Exception handling
					}
				},
			},
			{
				text: lang_common[8],
				itemId: 'cancelBtn',
				handler: function () {
					var win = this.up('window');
					win.close();
				}
			},
		],
		listeners: {
			show: function (me, eOpts) {
				var btn = me.animateTarget;
				var title;
				var callback;
				var vgs = MNV_VGGrid.getSelectionModel().getSelection();

				switch (btn.itemId)
				{
					case 'createBtn':
						me.setTitle(lang_mnv_volume[87]);
						me.down('#Name').setReadOnly(false);

						callback = function (grid) {
							grid.getStore().filter(
								function (r) {
									var vg = r.get('PV_VGName');

									return typeof(vg) == undefined || vg == null || vg == '';
								}
							);
						};

						break;
					case 'extendBtn':
						me.setTitle(lang_mnv_volume[91]);
						me.down('#Name').setValue(vgs[0].get('VG_Name'));
						me.down('#Name').setReadOnly(true);

						callback = function (grid) {
							grid.getStore().filter(
								function (r) {
									var vg = r.get('PV_VGName');

									return typeof(vg) == undefined || vg == null || vg == '';
								}
							);
						};

						break;
					case 'reduceBtn':
						me.setTitle(lang_mnv_volume[95]);
						me.down('#Name').setValue(vgs[0].get('VG_Name'));
						me.down('#Name').setReadOnly(true);

						callback = function (grid) {
							var records = [];

							grid.getStore().filter(
								function (r) {
									var vg = r.get('PV_VGName');

									if (vg != vgs[0].get('VG_Name'))
									{
										return false;
									}

									records.push(r);

									return true;
								}
							);

							grid.getSelectionModel().select(records);
						};

						break;
					default:
						// TODO: Exception handling
				}

				doPVLoad(MNV_VGWindowPVGrid, callback);
			},
		},
	}
);

// 논리 디스크 목록 선택시 작업
function MNV_VGSelect(grid, record)
{
	// 선택한 논리 디스크의 개수
	var selectCount = grid.getSelectionModel().getCount();

	if (selectCount == 1)
	{
		// 논리 볼륨 호출
		// 선택한 논리 디스크의 키
		var VGKey = record[0].data.VG_Name;

		// 논리 볼륨의 title 변경
		MNV_LVGrid
			.setTitle(
				"[" + lang_mnv_volume[8] +
				": " + VGKey +
				"] " + lang_mnv_volume[9]
			);

		// 논리 볼륨 정보 초기화
		MNV_LVStore.clearFilter();

		// 논리 볼륨 목록 변경: 선택한 논리 디스크에 할당된 논리 볼륨 출력
		MNV_LVStore.filter(
			function (r) {
				var LV_Name     = r.get('LV_Name');
				var LV_MemberOf = r.get('LV_MemberOf');
				var LV_Purpose  = r.get('LV_Purpose');

				return (LV_MemberOf == VGKey && LV_Purpose != 'os');
			}
		);
	}
	else
	{
		// 논리 볼륨 정보 초기화
		MNV_LVStore.clearFilter();

		// 논리 볼륨의 title 초기화
		MNV_LVGrid.setTitle(lang_mnv_volume[10]);

		// 논리 볼륨 목록 변경: 선택한 논리 디스크에 할당된 논리 볼륨 출력
		MNV_LVStore.filter(
			function (r) {
				var LV_Name = r.get('LV_Name');
				var LV_Purpose = r.get('LV_Purpose');

				return LV_Purpose != 'os';
			}
		);
	}
};

/*
 * 논리 볼륨 정보
 */
// 논리 볼륨 모델
Ext.define(
	'MNV_LVModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'LV_Name',
			'LV_Mount',
			'LV_Size',
			'LV_SizeByte',
			'LV_UseRate',
			'LV_MemberOf',
			'LV_Type',
		],
	}
);

// 논리 볼륨 스토어
var MNV_LVStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_LVModel',
		sorters: [
			{ property: 'LV_Name', direction: 'ASC' }
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity'
			}
		}
	}
);

// 논리 볼륨 언마운트
function MNV_Unmount(type)
{
	waitWindow(lang_mnv_volume[0], lang_mnv_volume[57]);

	var LV_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_Name;
	var VG_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_MemberOf;

	GMS.Cors.request({
		url: '/api/filesystem/common/unmount',
		method: 'POST',
		jsonData: {
			argument: {
				force: type == 'force' ? 'true' : 'false'
			},
			entity: {
				FS_Device: '/dev/' + VG_Name + '/' + LV_Name,
			}
		},
		callback: function (options, success, response, decoded) {
			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[34]);

			MNV_load();
		},
	});
};

// 논리 볼륨 그리드
var MNV_LVGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MNV_LVGrid',
		store: MNV_LVStore,
		title: lang_mnv_volume[10],
		selModel: {
			selType: 'checkboxmodel',
			checkOnly: 'true',
			listeners: {
				selectall: function () {
					MNV_LVSelect('selectAll');
				},
				deselectall: function () {
					MNV_LVSelect('deselectAll');
				}
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mnv_volume[4],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LV_Name'
			},
			{
				flex: 1,
				text: lang_mnv_volume[11],
				sortable : true,
				menuDisabled: true,
				dataIndex: 'LV_Mount'
			},
			{
				flex: 1,
				text: lang_mnv_volume[12],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'LV_SizeByte',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value);
				}
			},
			{
				xtype: 'componentcolumn',
				flex: 1,
				text: lang_mnv_volume[13],
				sortable : true,
				menuDisabled : true,
				dataIndex: 'LV_UseRate',
				renderer: function (v, m, r) {
					var rateValue = parseFloat(v);

					return {
						xtype: 'progressbar',
						value: rateValue / 100,
						text: v
					}
				}
			}
		],
		listeners: {
			itemclick: function (grid, record, item, index, e) {
				Ext.defer(function () { MNV_LVSelect() }, 200);
			}
		},
		tbar: [
			{
				text: lang_mnv_volume[19],
				id: 'MNV_LVGridAddBtn',
				iconCls: 'b-icon-add',
				handler: function () {
					// WINDOW OPEN시 동작
					MNV_LVWindow.animateTarget = Ext.getCmp('MNV_LVGridAddBtn');

					// 논리 볼륨 WINDOW
					MNV_LVWindow.show();

					// 생성할 논리 볼륨 크기
					Ext.getCmp('MNV_LVSize').labelEl.update(lang_mnv_volume[64]+': ');

					// 빈값 허용 하지 않음
					Ext.getCmp('MNV_LVSize').setDisabled(false);
					Ext.getCmp('MNV_LVSize').allowBlank = false;
					Ext.getCmp('MNV_LVSize').validate();

					// 생성폼 초기화
					MNV_LVForm.getForm().reset();

					Ext.getCmp('MNV_logicalCRUD').setValue('create');

					// 선택한 볼륩 그룹의 이름, 디스크 용량 표시
					var selectCount = Ext.getCmp('MNV_VGGrid').getSelectionModel().getCount();
					var selected = Ext.getCmp('MNV_VGGrid').getSelectionModel().getSelection();
					
					if (selectCount > 0)
					{
						Ext.getCmp('MNV_VGFormName').setValue(selected[0].raw.VG_Name);
						Ext.getCmp('MNV_LVFormFree').setText(byteConvertor(selected[0].raw.VG_FreeByte));
					}
					else
					{
						// 논리 디스크 첫번째 리스트 선택
						var LVDiskNameObj =  Ext.getCmp('MNV_VGFormName');

						LVDiskNameObj.setValue(LVDiskNameObj.getStore().getAt(0).get(LVDiskNameObj.valueField), true);

						// 선택된 논리 디스크 용량 표시
						var possibilitySize = byteConvertor(LVDiskNameObj.store.data.items[0].raw.VG_FreeByte);

						Ext.getCmp('MNV_LVFormFree').setText(possibilitySize);
					}

					// 논리 볼륨 크기 타입 첫번째 리스트 선택
					var LVVolumeTypeObj = Ext.getCmp('MNV_LVSizeType');

					LVVolumeTypeObj.setValue(LVVolumeTypeObj.getStore().getAt(0).get(LVVolumeTypeObj.valueField), true);

					// 논리 디스크 COMBOBOX 활성화
					Ext.getCmp('MNV_VGFormName').setDisabled(false);

					// 볼륨 타입 활성화
					Ext.getCmp('MNV_LVTypeRadioGroup').setDisabled(false);

					// 선택된 논리 볼륨명 출력
					Ext.getCmp('MNV_LVName').setValue();
					Ext.getCmp('MNV_LVName').setDisabled(false);

					// 논리 볼륨 버튼 생성
					Ext.getCmp('MNV_LVFormBtn').setText(lang_mnv_volume[21]);
				}
			},
			{
				text: lang_mnv_volume[22],
				id: 'MNV_LVGridModifyBtn',
				disabled: true,
				iconCls: 'b-icon-edit',
				handler: function () {
					// 확장할 논리 볼륨 크기
					Ext.getCmp('MNV_LVSize').setDisabled(false);

					// 마운트 정보가 Unmounted 일 때
					if (MNV_LVGrid.selModel.selected.items[0].data.LV_Mount == 'Unmounted')
					{
						Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[66]);

						// Ext.getCmp('MNV_LVSize').setDisabled(true);
						// Ext.getCmp('MNV_LVFormBtn').setDisabled(true);
						return false;
					}

					// WINDOW OPEN시 동작
					MNV_LVWindow.animateTarget = Ext.getCmp('MNV_LVGridModifyBtn');

					// 논리 볼륨 WINDOW
					MNV_LVWindow.show();

					Ext.getCmp('MNV_LVSize').labelEl.update(lang_mnv_volume[43]+': ');

					// 빈값 허용
					Ext.getCmp('MNV_LVSize').allowBlank = true;
					Ext.getCmp('MNV_LVSize').validate();

					// 생성폼 초기화
					MNV_LVForm.getForm().reset();
					Ext.getCmp('MNV_logicalCRUD').setValue('modify');

					// 선택된 논리 볼륨 데이터
					var selectLogicalVolume = MNV_LVGrid.selModel.selected.items[0].data;

					// 선택된 논리 볼륨의 논리 디스크명 출력
					Ext.getCmp('MNV_VGFormName').setValue(selectLogicalVolume.LV_MemberOf);

					// 선택된 논리 디스크 용량 표시
					var LVDiskNameObj =  Ext.getCmp('MNV_VGFormName');
					var possibilitySize = byteConvertor(LVDiskNameObj.lastSelection[0].data.VG_FreeByte);

					Ext.getCmp('MNV_LVFormFree').setText(possibilitySize);

					// 논리 디스크 COMBOBOX 비활성화
					Ext.getCmp('MNV_VGFormName').setDisabled(true);

					// 볼륨 타입 선택
					if (selectLogicalVolume.LV_Type == 'thick' || selectLogicalVolume.LV_Type == 'thin_pool')
					{
						Ext.getCmp('MNV_LVTypeRadioGroup').setValue({volumeType: 'thick'});
					}
					else
					{
						Ext.getCmp('MNV_LVTypeRadioGroup').setValue({volumeType: 'thin'});
					}

					// 볼륨 타입 비활성화
					Ext.getCmp('MNV_LVTypeRadioGroup').setDisabled(true);

					// 선택된 논리 볼륨명 출력
					var allotmentlogicalKey = selectLogicalVolume.LV_Name;

					Ext.getCmp('MNV_LVName').setValue(allotmentlogicalKey);
					Ext.getCmp('MNV_LVName').setDisabled(true);

					var selectLogicalVolumeSizeObj = selectLogicalVolume.LV_Size;
					var selectLogicalVolumeType = trim(selectLogicalVolumeSizeObj.substring(selectLogicalVolumeSizeObj.length-3));
					var selectLogicalVolumeSize = trim(selectLogicalVolumeSizeObj.substring(0, selectLogicalVolumeSizeObj.length-3));

					// 논리 볼륨 크기
					Ext.getCmp('MNV_LVSize').setValue(selectLogicalVolumeSize);

					// 논리 볼륨 크기 타입
					var LVVolumeTypeObj =  Ext.getCmp('MNV_LVSizeType');

					LVVolumeTypeObj.setValue(selectLogicalVolumeType,true);

					// 논리 볼륨 버튼 수정
					Ext.getCmp('MNV_LVFormBtn').setText(lang_mnv_volume[23]);
				}
			},
			{
				text: lang_mnv_volume[55],
				id: 'MNV_LVGridDelBtn',
				iconCls: 'b-icon-delete',
				disabled: true,
				listeners: {
					render: function (cmp) {
						Ext.create(
							'Ext.tip.ToolTip',
							{
								target: cmp.el,
								html: lang_mnv_volume[65],
							}
						);
					}
				},
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mnv_volume[0],
						lang_mnv_volume[24],
						function (btn, text) {
							if (btn != 'yes')
								return;

							// 선택된 그리드의 전송값 추출
							var LVKeys = [];
							var LV = MNV_LVGrid.getSelectionModel().getSelection();

							for (var i=0, len=LV.length; i<len; i++)
							{
								LVKeys.push(
									LV[i].data.LV_MemberOf
									+ "/"
									+ LV[i].data.LV_Name);
							}

							waitWindow(lang_mnv_volume[0], lang_mnv_volume[25]);

							GMS.Cors.request({
								url: '/api/lvm/lv/delete',
								method: 'POST',
								jsonData: {
									entity: {
										LV_LVs: LVKeys
									}
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
									{
										return;
									}

									Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[26]);
									MNV_load()
								}
							});
						}
					);
				}
			},
			{
				text: lang_mnv_volume[56],
				id: 'MNV_LVGridMountBtn',
				iconCls: 'b-icon-mount-1',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mnv_volume[0],
						lang_mnv_volume[28],
						function (btn, text) {
							if (btn != 'yes')
								return;

							waitWindow(lang_mnv_volume[0], lang_mnv_volume[29]);

							var VG_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_MemberOf;
							var LV_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_Name;

							GMS.Cors.request({
								url: '/api/filesystem/common/mount',
								method: 'POST',
								jsonData: {
									entity: {
										FS_Device: '/dev/' + VG_Name + '/' + LV_Name,
										FS_Type: 'XFS',
									}
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
									{
										return;
									}

									Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[30]);
									MNV_load();
								},
							});
						}
					);
				}
			},
			{
				text: lang_mnv_volume[32],
				id: 'MNV_LVGridUnMountBtn',
				iconCls: 'b-icon-mount-1',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mnv_volume[0],
						lang_mnv_volume[33],
						function (btn, text) {
							if (btn != 'yes')
								return;

							waitWindow(lang_mnv_volume[0], lang_mnv_volume[57]);

							var VG_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_MemberOf;
							var LV_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_Name;

							GMS.Cors.request({
								url: '/api/filesystem/common/unmountable',
								method: 'POST',
								jsonData: {
									entity: {
										FS_Device: '/dev/' + VG_Name + '/' + LV_Name,
										FS_Type: 'XFS',
									}
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
									{
										return;
									}

									if (decoded.entity.Unmountable != 'true')
									{
										Ext.MessageBox.confirm(
											lang_mnv_volume[0],
											lang_mnv_volume[63],
											function(btn, text) {
												if (btn == 'yes')
													MNV_Unmount('force');
											}
										);

										return;
									}

									MNV_Unmount('normal');
								},
							});
						}
					);
				}
			},
			{
				text: lang_mnv_volume[58],
				id: 'MNV_LVGridFormatBtn',
				iconCls: 'b-icon-format',
				disabled: true,
				handler: function () {
					Ext.MessageBox.confirm(
						lang_mnv_volume[0],
						lang_mnv_volume[36],
						function (btn, text) {
							if (btn != 'yes')
								return;

							waitWindow(lang_mnv_volume[0], lang_mnv_volume[37]);

							var LV_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_Name;
							var VG_Name = MNV_LVGrid.selModel.selected.items[0].data.LV_MemberOf;

							GMS.Cors.request({
								url: '/api/filesystem/common/format',
								method: 'POST',
								jsonData: {
									entity: {
										FS_Device: '/dev/' + VG_Name + '/' + LV_Name,
										FS_Type: 'XFS',
									}
								},
								callback: function (options, success, response, decoded) {
									if (!success || !decoded.success)
									{
										return;
									}

									Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[38]);
								}
							});
						}
					);
				}
			}
		]
	}
);

// 논리 볼륨 목록 선택 시
function MNV_LVSelect()
{
	var selectCount = Ext.getCmp('MNV_LVGrid').getSelectionModel().getCount();
	var selected
			= Ext.getCmp('MNV_LVGrid').getSelectionModel().getSelection();

	if (selectCount < 1)
	{
		Ext.getCmp('MNV_LVGridModifyBtn').disable();
		Ext.getCmp('MNV_LVGridDelBtn').disable();
		Ext.getCmp('MNV_LVGridMountBtn').disable();
		Ext.getCmp('MNV_LVGridFormatBtn').disable();
		Ext.getCmp('MNV_LVGridUnMountBtn').disable();
	}

	if (selectCount == 1)
	{
		// 수정 버튼 활성화
		Ext.getCmp('MNV_LVGridModifyBtn').enable();

		// 마운트 버튼 활성화
		if (selected[0].raw.LV_Mount == 'Unmounted')
		{
			Ext.getCmp('MNV_LVGridMountBtn').enable();

			// 마운트 비활성화
			Ext.getCmp('MNV_LVGridUnMountBtn').disable();

			// 포맷 버튼 활성화
			Ext.getCmp('MNV_LVGridFormatBtn').enable();

			// 삭제 버튼 비활성화
			Ext.getCmp('MNV_LVGridDelBtn').enable();
		}
		else if (selected[0].raw.LV_Purpose == 'thin_pool')
		{
			// 마운트 비활성화
			Ext.getCmp('MNV_LVGridMountBtn').disable();

			// 마운트 해제 비활성화
			Ext.getCmp('MNV_LVGridUnMountBtn').disable();

			// 포맷 버튼 활성화
			Ext.getCmp('MNV_LVGridFormatBtn').disable();

		}
		else
		{
			// 마운트 비활성화
			Ext.getCmp('MNV_LVGridMountBtn').disable();
			
			// 마운트 해제 활성화
			Ext.getCmp('MNV_LVGridUnMountBtn').enable();

			// 포맷 버튼 활성화
			Ext.getCmp('MNV_LVGridFormatBtn').disable();

			// 삭제 버튼 활성화
			Ext.getCmp('MNV_LVGridDelBtn').disable();
		}

		return;
	}

	if (selectCount > 1)
	{
		// 수정 버튼 비활성화
		Ext.getCmp('MNV_LVGridModifyBtn').disable();

		// 포맷 버튼 활성화
		Ext.getCmp('MNV_LVGridFormatBtn').disable();

		// 마운트 버튼 활성화
		Ext.getCmp('MNV_LVGridMountBtn').disable();

		// 언마운트 버튼 비활성화
		Ext.getCmp('MNV_LVGridUnMountBtn').disable();

		// 삭제 버튼 활성화
		Ext.getCmp('MNV_LVGridDelBtn').enable();

		//마운트가 안된 논리 볼륨선택시 삭제버튼 비활성화
		for (var i=0, len=selected.length; i<len; i++)
		{
			if (selected[i].data.LV_Mount != 'Unmounted')
			{
				// 삭제 버튼 비활성화
				Ext.getCmp('MNV_LVGridDelBtn').disable();
			}
		}

		return;
	}

};

/*
 * 논리 볼륨 생성
 */
// 논리 디스크 combo 모델
Ext.define(
	'MNV_VGComboModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'VG_Name',
			'VG_FreeByte',
			'VG_Purpose',
		]
	}
);

// 논리 디스크 combo 스토어
var MNV_VGComboStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_VGComboModel',
		sorters: [
			{ property: 'VG_Name', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			},
		},
	}
);

// 논리 볼륨 모델
Ext.define(
	'MNV_LVModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			'LV_Name',
			'LV_Mount',
			'LV_Size',
			'LV_SizeByte',
			'LV_UseRate',
			'LV_MemberOf',
		],
	}
);

// 논리 볼륨 스토어
var MNV_LVComboStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MNV_LVModel',
		sorters: [
			{ property: 'LV_Name', direction: 'ASC' },
		],
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
				root: 'entity',
			},
		},
	}
);

//논리 디스크 목록 선택시 작업
function MNV_VGComboSelect(record)
{
	// 선택한 논리 디스크 이름
	var VGKey = record;

	// 논리 볼륨 정보 초기화
	MNV_LVComboStore.clearFilter();

	// 논리 볼륨 목록 변경: 선택한 논리 디스크에 할당된 논리 볼륨 출력
	MNV_LVComboStore.filter(
		function (r) {
			var LV_Name     = r.get('LV_Name');
			var LV_MemberOf = r.get('LV_MemberOf');
			var LV_Purpose  = r.get('LV_Purpose');

			return (LV_MemberOf == VGKey
				&& LV_Name != 'lv_home'
				&& LV_Name != 'lv_swap'
				&& LV_Name != 'lv_root'
				&& LV_Purpose != 'os');
		}
	);

	if (MNV_LVComboStore.data.length == 0)
	{
		Ext.getCmp('MNV_LVType').disable();
		Ext.getCmp('MNV_LVFormName').setValue('');
	}
	else
	{
		MNV_LVComboStore.each(
			function (record) {
				// 동적 할당: 활성화
				if (record.data.LV_Name.slice(0, 3) == 'tp_')
				{
					Ext.getCmp('MNV_LVType').enable();
					Ext.getCmp('MNV_LVFormName').setValue(record.data.LV_Name);
					return false;
				}
				// 동적 할당: 비활성화
				else
				{
					Ext.getCmp('MNV_LVType').disable();
					Ext.getCmp('MNV_LVFormName').setValue('');
				}
			}
		);
	}
};

// 논리 볼륨 생성폼
var MNV_LVForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MNV_LVForm',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				style: {marginBottom: '30px'},
				html: lang_mnv_volume[40]
			},
			{
				xtype: 'BasePanel',
				layout: 'hbox',
				bodyStyle: 'padding: 0;',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BaseComboBox',
						id: 'MNV_VGFormName',
						name: 'volumeVGFormName',
						fieldLabel: lang_mnv_volume[41],
						store: MNV_VGComboStore,
						valueField: 'VG_Name',
						displayField: 'VG_Name',
						listeners: {
							change: function (list, record) {
								MNV_VGComboSelect(record);
							}
						},
						listConfig: {
							listeners: {
								itemclick: function (list, record) {
									var size = byteConvertor(record.get('VG_FreeByte'));
									Ext.getCmp('MNV_LVFormFree').setText(size);
								}
							}
						}
					}
				]
			},
			{
				xtype: 'BaseComboBox',
				id: 'MNV_LVFormName',
				name: 'volumeLVFormName',
				store: MNV_LVComboStore,
				valueField: 'LV_Name',
				displayField: 'LV_Name',
				fieldLabel: lang_mnv_volume[74],
				hidden: true,
				style: { marginBottom: '20px' }
			},
			{
				xtype: 'textfield',
				id: 'MNV_LVName',
				name: 'volumeLogicalName',
				fieldLabel: lang_mnv_volume[42],
				allowBlank: false,
				vtype: 'reg_ID',
				style: { marginBottom: '20px' }
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: {marginBottom: '20px'},
				items: [
					{
						xtype: 'radiogroup',
						fieldLabel: lang_mnv_volume[69],
						anchor: 'none',
						id: 'MNV_LVTypeRadioGroup',
						layout: {
							autoFlex: false
						},
						defaults: {
							margin: '0 50 0 0'
						},
						items: [
							{
								boxLabel: lang_mnv_volume[71],
								name: 'volumeType',
								inputValue: 'thick',
								checked: true
							},
							{
								boxLabel: lang_mnv_volume[70],
								name: 'volumeType',
								inputValue: 'thin',
								id: 'MNV_LVType',
								width: 130,
								listeners: {
									afterrender: function () {
										Ext.defer(
											function () {
												if (Ext.getCmp('MNV_LVType').disabled)
												{
													Ext.QuickTips.init();
													Ext.QuickTips.register({
														target: 'MNV_LVType',
														text: lang_mnv_volume[73],
														width: 310,
														dismissDelay: 5000,
													});
												}
											},
											500
										);
									},
									destroy: function () {
										Ext.defer(
											function () {
												if (Ext.getCmp('MNV_LVType').disabled)
													Ext.QuickTips.destroy();
											},
											500
										);
									}
								}
							}
						],
						listeners: {
							change: function (field, newValue, oldValue) {
								switch (newValue['volumeType'])
								{
									case 'thick':
										Ext.getCmp('MNV_LVAssignMax').show();
										break;
									case 'thin':
										Ext.getCmp('MNV_LVAssignMax').hide();
										break;
								}
							}
						}
					}
				]
			},
			{
				xtype: 'BasePanel',
				id:'MNV_LVAssignMax',
				bodyStyle: 'padding:0;',
				layout: 'hbox',
				maskOnDisable: false,
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'label',
						text: lang_mnv_volume[20] + ': ',
						width: 135
					},
					{
						xtype: 'label',
						id: 'MNV_LVFormFree'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				layout: 'hbox',
				maskOnDisable: false,
				items: [
					{
						xtype: 'textfield',
						id: 'MNV_LVSize',
						name: 'volumeLogicalSize',
						fieldLabel: lang_mnv_volume[64],
						allowBlank: false,
						vtype: 'reg_realNumber',
						width: 280
					},
					{
						xtype: 'BaseComboBox',
						id: 'MNV_LVSizeType',
						name: 'volumeLVSizeType',
						hideLabel: true,
						store: ['MiB', 'GiB', 'TiB', 'PiB'],
						width: 70,
						value: 'MiB',
						style: { marginLeft: '10px' }
					}
				]
			},
			{
				xtype: 'textfield',
				hidden : true,
				id: 'MNV_logicalCRUD',
				name: 'volumelogicalCRUD',
				value: 'create'
			}
		]
	}
);

// 논리 볼륨 생성 WINDOW
var MNV_LVWindow = Ext.create(
	'BaseWindowPanel',
	{
		id: 'MNV_LVWindow',
		title: lang_mnv_volume[53],
		maximizable: false,
		autoHeight: true,
		width: 600,
		layout: 'fit',
		items: [MNV_LVForm],
		buttons: [
			{
				text: lang_mnv_volume[48],
				id: 'MNV_LVFormBtn',
				handler: function () {
					if (!MNV_LVForm.getForm().isValid())
						return false;

					// 할당 가능한 용량 확인
					var errorMsg = true;

					MNV_VGComboStore.each(
						function (record) {
							if (Ext.getCmp('MNV_VGFormName').getValue() != record.get('VG_Name'))
								return;

							var size = Ext.getCmp('MNV_LVSize').getValue();
							var unit = Ext.getCmp('MNV_LVSizeType').getValue();

							var allowByteSize = 0;

							if (unit == 'MiB')
								allowByteSize = size * 1024 * 1024;
							else if (unit == 'GiB')
								allowByteSize = size * 1024 * 1024 * 1024;
							else if (unit == 'TiB')
								allowByteSize = size * 1024 * 1024 * 1024 * 1024;
							else if (unit == 'PiB')
								allowByteSize = size * 1024 * 1024 * 1024 * 1024 * 1024;

							if (Ext.getCmp('MNV_LVType').getValue() != true
								&& record.get('VG_FreeByte') < allowByteSize)
							{
								errorMsg = false;
							}
						}
					);

					// 할당 가능한 용량 초과 시 실패 메세지
					if (errorMsg == false)
					{
						Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[62]);
						return false;
					}

					var setExecutionDesc;
					var setSuccessDesc;
					var setFailureDesc;
					var setUrl;

					var LV_Type     = Ext.getCmp('MNV_LVType').getValue();
					var LV_TPName   = Ext.getCmp('MNV_LVFormName').getValue();
					var LV_MemberOf = Ext.getCmp('MNV_VGFormName').getValue();
					var LV_Name     = Ext.getCmp('MNV_LVName').getValue();
					var LV_Size     = Ext.getCmp('MNV_LVSize').getValue();
					var LV_SizeType = Ext.getCmp('MNV_LVSizeType').getValue();
					var LV_Options  = new Array();

					if (Ext.getCmp('MNV_logicalCRUD').getValue() == 'create')
					{
						// 용량 예외 처리
						// - 100M 이상 설정
						if (LV_Size < 100 && LV_SizeType == 'MiB')
						{
							Ext.MessageBox.alert(lang_mnv_volume[0], lang_mnv_volume[59]);
							return false;
						}

						setExecutionDesc = lang_mnv_volume[60];
						setSuccessDesc = lang_mnv_volume[49];
						setFailureDesc = lang_mnv_volume[50];
						setUrl = '/api/lvm/lv/create';
					}
					else
					{
						setExecutionDesc = lang_mnv_volume[61];
						setSuccessDesc = lang_mnv_volume[51];
						setFailureDesc = lang_mnv_volume[52];
						setUrl = '/api/lvm/lv/update';
					}

					waitWindow(lang_mnv_volume[0], setExecutionDesc);

					GMS.Cors.request({
						url: setUrl,
						method: 'POST',
						jsonData: {
							entity: {
								LV_MemberOf: LV_MemberOf,
								LV_Name: LV_Name,
								LV_Size: LV_Size + ' ' + LV_SizeType,
								LV_Type: LV_Type ? 'thin' : 'thick',
								LV_Options: LV_Type == 'thin' ? ['--thinpool', LV_TPName] : [],
							}
						},
						callback: function (options, success, response, decoded) {
							if (!success || !decoded.success)
							{
								return;
							}

							// 데이터 로드 성공 메세지
							Ext.MessageBox.alert(lang_mnv_volume[0], setSuccessDesc);

							MNV_LVWindow.hide();

							MNV_load();
						}
					});
				}
			}
		]
	}
);

function doPVLoad(grid, callback)
{
	// 물리 디스크 마스크 표시
	var PVLoadMask = new Ext.LoadMask(grid, { msg: lang_mnd_disk[49] });

	PVLoadMask.show();

	grid.getStore().removeAll();

	GMS.Cors.request({
		url: '/api/lvm/pv/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			PVLoadMask.hide();

			if (!success || !decoded.success)
			{
				return;
			}

			// 물리 디스크목록 로드
			grid.getStore().loadRawData(decoded);
			grid.getStore().clearFilter();

			if (typeof(callback) == 'function')
			{
				callback(grid);
			}
		}
	});
}

function doVGLoad()
{
	// 논리 디스크 마스크 표시
	var VGLoadMask = new Ext.LoadMask(
		Ext.getCmp('MNV_VGGrid'),
		{ msg: (lang_mnv_volume[75]) }
	);

	VGLoadMask.show();

	MNV_VGStore.removeAll();

	// 논리 디스크 목록 호출
	GMS.Cors.request({
		url: '/api/lvm/vg/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			VGLoadMask.hide();

			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				return;
			}

			// 논리 디스크 목록 로드 & 필터 초기화
			MNV_VGStore.loadRawData(decoded);
			MNV_VGStore.clearFilter();

			/*
			MNV_VGStore.filter(
				function (r) {
					return (r.get('VG_Purpose') != 'os');
				}
			);
			*/

			// 볼륨 생성 시 논리 디스크 목록
			MNV_VGComboStore.loadRawData(decoded);
			MNV_VGComboStore.clearFilter();

			/*
			MNV_VGComboStore.filter(
				function (r) {
					return (r.get('VG_Purpose') != 'os');
				}
			);
			*/
		},
	});
}

function doLVLoad()
{
	// 논리 볼륨 마스크 표시
	var LVLoadMask = new Ext.LoadMask(
		Ext.getCmp('MNV_LVGrid'),
		{ msg: (lang_mnv_volume[75]) }
	);

	LVLoadMask.show();

	// 초기 버튼 컨트롤
	Ext.getCmp('MNV_LVGridModifyBtn').setDisabled(true);
	Ext.getCmp('MNV_LVGridDelBtn').setDisabled(true);
	Ext.getCmp('MNV_LVGridMountBtn').setDisabled(true);
	Ext.getCmp('MNV_LVGridUnMountBtn').setDisabled(true);
	Ext.getCmp('MNV_LVGridFormatBtn').setDisabled(true);

	// 목록 데이터 제거
	MNV_LVStore.removeAll();

	// 논리 볼륨 목록 호출
	GMS.Cors.request({
		url: '/api/lvm/lv/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			// 마스크 제거
			LVLoadMask.hide();

			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				return;
			}

			// 논리 볼륨 목록 로드 & 필터 초기화
			MNV_LVStore.loadRawData(decoded);
			MNV_LVStore.clearFilter();

			/*
			// 논리 볼륨 목록 숨김
			MNV_LVStore.filter(
				function (r) {
					return (!r.get('LV_Name').match(/home|swap|root/)
							&& r.get('LV_Purpose') != 'os');
				}
			);
			*/

			// 볼륨 생성 시 논리 볼륨 목록
			MNV_LVComboStore.loadRawData(decoded);
			MNV_LVComboStore.clearFilter();

			/*
			MNV_LVComboStore.filter(
				function (r) {
					return (!r.get('LV_Name').match(/home|swap|root/)
						&& r.get('LV_Purpose') != 'os');
				}
			);
			*/
		},
	});
}

function doPVCreate(devices)
{
	waitWindow(
		lang_mnv_volume[76],
		(devices.length > 1 ? lang_mnv_volume[80] : lang_mnv_volume[79]),
	);

	GMS.Cors.request({
		url: '/api/lvm/pv/create',
		method: 'POST',
		jsonData: {
			entity: {
				PV_Names: devices,
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mnv_volume[76],
				msg: (devices.length > 1 ? lang_mnv_volume[82] : lang_mnv_volume[81]),
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});

			MNV_PVCreateWindow.hide();

			MNV_load();
		}
	});
}

function doPVRemove(pv)
{
	waitWindow(lang_mnv_volume[83], lang_mnv_volume[85]);

	GMS.Cors.request({
		url: '/api/lvm/pv/delete',
		method: 'POST',
		jsonData: {
			entity: {
				PV_PVs: [pv],
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mnv_volume[83],
				msg: lang_mnv_volume[86],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});

			MNV_load();
		}
	});
}

function doVGCreate(name, devices)
{
	waitWindow(lang_mnv_volume[87], lang_mnv_volume[89]);

	GMS.Cors.request({
		url: '/api/lvm/vg/create',
		method: 'POST',
		jsonData: {
			entity: {
				VG_Name: name,
				VG_PVs: devices,
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mnv_volume[87],
				msg: lang_mnv_volume[90],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});

			MNV_VGWindow.hide();

			MNV_load();
		}
	});
}

function doVGExtend(name, devices)
{
	waitWindow(lang_mnv_volume[91], lang_mnv_volume[93]);

	GMS.Cors.request({
		url: '/api/lvm/vg/extend',
		method: 'POST',
		jsonData: {
			entity: {
				VG_Name: name,
				VG_PVs: devices,
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mnv_volume[91],
				msg: lang_mnv_volume[94],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});

			MNV_VGWindow.hide();

			MNV_load();
		}
	});
}

function doVGReduce(name, devices)
{
	waitWindow(lang_mnv_volume[95], lang_mnv_volume[97]);

	GMS.Cors.request({
		url: '/api/lvm/vg/reduce',
		method: 'POST',
		jsonData: {
			entity: {
				VG_Name: name,
				VG_PVs: devices,
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mnv_volume[95],
				msg: lang_mnv_volume[98],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});

			MNV_VGWindow.hide();

			MNV_load();
		}
	});
}

function doVGRemove(name)
{
	waitWindow(lang_mnv_volume[99], lang_mnv_volume[101]);

	GMS.Cors.request({
		url: '/api/lvm/vg/delete',
		method: 'POST',
		jsonData: {
			entity: {
				VG_Names: name,
			}
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			Ext.MessageBox.show({
				title: lang_mnv_volume[99],
				msg: lang_mnv_volume[102],
				icon: Ext.MessageBox.INFO,
				buttons: Ext.MessageBox.OK,
			});

			MNV_load();
		}
	});
}

// 볼륨 -> 볼륨 설정
Ext.define(
	'/admin/js/manager_node_volume',
	{
		extend: 'BasePanel',
		id: 'manager_node_volume',
		bodyStyle: {
			padding: 0,
		},
		load: function () {
			MNV_load();
		},
		items: [
			{
				xtype: 'BasePanel',
				layout: {
					type: 'vbox',
					align: 'stretch',
				},
				bodyStyle: {
					padding: '20px',
				},
				items: [
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: {
							padding: 0,
						},
						flex: 1,
						items: [MNV_PVGrid]
					},
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: {
							padding: 0,
						},
						flex: 1,
						items: [MNV_VGGrid],
					},
					{
						xtype: 'BasePanel',
						layout: 'fit',
						bodyStyle: {
							padding: 0,
						},
						flex: 1,
						items: [MNV_LVGrid],
					},
				]
			}
		],
	},
);

