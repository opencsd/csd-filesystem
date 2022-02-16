/*
 * 페이지 로드 시 실행 함수
 */
// 블록 장치 목록 로딩
function MND_infoLoad()
{
	// 목록 초기화
	MND_blockDeviceStore.removeAll();

	// 블록 장치 목록 마스크 표시
	var physicalDiskLoadMask = new Ext.LoadMask(
		Ext.getCmp('MND_blockDeviceGrid'),
		{
			msg: lang_mnd_disk[49],
		}
	);

	physicalDiskLoadMask.show();

	// 블록 장치 목록 받아오기
	GMS.Cors.request({
		url: '/api/block/device/list',
		method: 'POST',
		callback: function (options, success, response, decoded) {
			physicalDiskLoadMask.hide();

			if (!success || !decoded.success)
			{
				return;
			}

			// 블록 장치 목록 로드
			MND_blockDeviceStore.loadRawData(decoded);
			MND_blockDeviceStore.clearFilter();

			MND_blockDeviceStore.filter(
				function (record) {
					return (!record.get('Name').match(/\/sr/));
				}
			);
		}
	});
};

/*
 * 블록 장치 목록
 */
// 블록 장치 모델
Ext.define(
	'MND_blockDeviceModel',
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
			'Mount',
			//{ name: 'SCSI_ID', mapping: 'PV_SCSIInfo.SCSI_ID' },
		]
	}
);

// 블록 장치 스토어
var MND_blockDeviceStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MND_blockDeviceModel',
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
var MND_blockDeviceGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MND_blockDeviceGrid',
		store: MND_blockDeviceStore,
		multiSelect: false,
		title: lang_mns_smart[6],
		height: 300,
		style: {
			marginBottom: '20px',
		},
		columns: [
			{
				flex: 1,
				text: lang_mnd_disk[5],
				sortable: true,
				dataIndex: 'Name',
			},
			{
				flex: 1,
				text: lang_common[31],
				sortable: true,
				dataIndex: 'Serial',
			},
			{
				flex: 1,
				text: lang_mnd_disk[7],
				sortable: true,
				dataIndex: 'Vendor',
			},
			{
				flex: 1,
				text: lang_mnd_disk[8],
				sortable: true,
				dataIndex: 'Model',
			},
			{
				flex: 0.5,
				text: lang_common[12],
				sortable: true,
				dataIndex: 'Type',
			},
			{
				flex: 1,
				text: lang_common[17],
				sortable: true,
				dataIndex: 'Transport',
			},
			{
				flex: 1,
				text: lang_mnd_disk[9],
				sortable: true,
				dataIndex: 'Size',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return byteConvertor(value * 1024);
				}
			},
			{
				flex: 1,
				text: lang_common[48],
				sortable: true,
				dataIndex: 'Is_OS',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return value ? 'OS' : '';
				}
			},
			{
				flex: 1,
				text: lang_mcv_volumePool[69],
				sortable: true,
				dataIndex: 'In_Use',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return value ? lang_common[45] : lang_common[46];
				}
			},
			{
				flex: 1.5,
				text: lang_mnv_volume[56],
				sortable: true,
				dataIndex: 'Mount',
				renderer: function (value, metaData, record, rowIdx, colIdx, store, view) {
					return value.sort().join("<br />");
				},
			},
		],
		/*
		viewConfig: {
			listeners: {
				refresh: function (dataview) {
					dataview.panel.columns.forEach(
						function (c) {
							if (c.autoSizeColumn)
								c.autoSize();
						}
					)
				}
			},
		},
		*/
	}
);

// 볼륨-> 디스크 설정
Ext.define(
	'/admin/js/manager_node_disk',
	{
		extend: 'BasePanel',
		id: 'manager_node_disk',
		bodyStyle: {
			padding: 0,
		},
		items: [
			{
				xtype: 'BasePanel',
				layout: {
					type: 'vbox',
					align : 'stretch'
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
						minHeight: 100,
						items: [MND_blockDeviceGrid],
					},
				]
			}
		],
		load: function() {
			MND_infoLoad();
		},
	}
);
