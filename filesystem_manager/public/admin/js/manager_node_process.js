/*
 * 페이지 로드 시 실행 함수
**/
function MNP_processLoad()
{
	// 프로세스 데이터 제거
	MNP_processStore.removeAll();

	// 프로세스 목록 마스크 표시
	var processLoadMask = new Ext.LoadMask(
		Ext.getCmp('MNP_processGrid'),
		{ msg: (lang_mcn_dns[15]) }
	);

	processLoadMask.show();

	// 프로세스 목록 호출
	GMS.Cors.request({
		url: '/api/monitor/process/status',
		method: 'POST',
		jsonData: {
			argument: {
				Limit: Ext.getCmp('MNP_processLimitList').getValue()
			}
		},
		callback: function(options, success, response) {
			// 마스크 제거
			processLoadMask.hide();

			// 응답 데이터
			var responseData = exceptionDataDecode(response.responseText);

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
					+ '"title": "' + lang_mnp_process[0] + '",'
					+ '"content": "' + lang_mnp_process[2] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			clearInterval(_nowCurrentProcessVar);

			// 데이터 로드
			MNP_processStore.loadRawData(responseData);

			// 데이터 로드 성공 메세지
			//Ext.ux.DialogMsg.msg(lang_mnp_process[0], lang_mnp_process[1]);

			// 데이터 주기적 호출
			// TODO: manager_cluster_clusterNode로 나옴
			if (Ext.getCmp('content-main').getLayout().getActiveItem().itemId
					!= 'manager_node_process')
				return;

			_nowCurrentProcessVar
				= setInterval(function() { MNP_processInterval() }, 3000);
		}
	});
};

/*
 * 프로세스 그리드 데이터 주기적 호출
 */
function MNP_processInterval()
{
	// TODO: manager_cluster_clusterNode로 나옴
	if (Ext.getCmp('content-main').getLayout().getActiveItem().itemId
			!= 'manager_node_process')
	{
		clearInterval(_nowCurrentProcessVar);
		return;
	}

	GMS.Cors.request({
		url: '/api/monitor/process/status',
		method: 'POST',
		jsonData: {
			argument: {
				Limit: Ext.getCmp('MNP_processLimitList').getValue()
			}
		},
		callback: function(options, success, response) {
			// 데이터 전송 완료 후 wait 제거
			if (waitMsgBox)
			{
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			var responseData = exceptionDataDecode(response.responseText);

			// 예외 처리에 따른 동작
			if (!success || !responseData.success)
			{
				clearInterval(_nowCurrentProcessVar);

				if (response.responseText == ''
						|| typeof(response.responseText) == 'undefined')
					response.responseText = '{}';

				if (typeof(responseData.msg) === 'undefined')
					responseData.msg = '';

				if (typeof(responseData.code) === 'undefined')
					responseData.code = '';

				var checkValue = '{'
					+ '"title": "' + lang_mnp_process[0] + '",'
					+ '"content": "' + lang_mnp_process[2] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 데이터 로드
			MNP_processStore.loadRawData(responseData);
		}
	});
}

/**
프로세스 그리드
**/
// 프로세스 모델
Ext.define('MNP_processModel',{
	extend: 'Ext.data.Model',
	fields: [
		'PID', 'Name', 'State',
		{ name:'CPUUsage',  sortType: 'asNatural' },
		{ name:'MemUsage', sortType: 'asNatural' },
		{ name:'Runtime', sortType: 'asNatural' },
		'RSS',  'VSS'
	]
});

// 프로세스 스토어
var MNP_processStore = Ext.create('Ext.data.Store', {
	model: 'MNP_processModel',
	sorters: [
		{ property: 'PID', direction: 'ASC' }
	],
	proxy: {
		type: 'memory',
		reader: {
			type: 'json',
			root: 'entity'
		}
	}
});

// 프로세스 그리드
var MNP_processGrid = Ext.create('BaseGridPanel', {
	id: 'MNP_processGrid',
	store: MNP_processStore,
	title: lang_mnp_process[0],
	columns: [
		{
			text: lang_mnp_process[3],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'PID'
		},
		{
			text: lang_mnp_process[4],
			flex: 1,
			sortable : true,
			menuDisabled: true,
			dataIndex: 'Name'
		},
		{
			text: lang_mnp_process[5],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'State'
		},
		{
			text: lang_mnp_process[6],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'CPUUsage'
		},
		{
			text: lang_mnp_process[7],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'MemUsage'
		},
		{
			text: lang_mnp_process[8],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'Runtime'
		},
		{
			text: lang_mnp_process[9],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'RSS'
		},
		{
			text: lang_mnp_process[10],
			flex: 1,
			sortable: true,
			menuDisabled: true,
			dataIndex: 'VSS'
		}
	],
	tbar: [
		'->',
		lang_mnp_process[11] + ': ',
		{
			xtype: 'BaseComboBox',
			id: 'MNP_processLimitList',
			name: 'processLimitList',
			width: 80,
			store: new Ext.data.SimpleStore({
				fields: ['limitValue', 'limitView'],
				data: [
					['25', '25'],
					['50', '50'],
					['75', '75'],
					['100', '100']
				]
			}),
			value: '25',
			displayField: 'limitView',
			valueField: 'limitValue'
		}
	],
	viewConfig: {
		forceFit: true,
		loadMask: false,
		preserveScrollOnRefresh: true
	}
});

// 통합 모니터링 -> 소프트웨어
Ext.define('/admin/js/manager_node_process', {
	extend: 'BasePanel',
	id: 'manager_node_process',
	bodyStyle: 'padding: 0;',
	load: function() {
		MNP_processLoad();
	},
	items: [
		{
			xtype: 'BasePanel',
			layout: 'fit',
			bodyStyle: 'padding: 20px',
			items: [MNP_processGrid]
		}
	]
});
