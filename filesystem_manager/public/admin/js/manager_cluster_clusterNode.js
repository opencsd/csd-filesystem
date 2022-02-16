/*
 * 서포트 페이지 출력
 */
function supportPageDynamicChange(padding,  stage)
{
	var loadPage = 'manager_cluster_clusterNode';

	$.cookie('gms_page',  loadPage,  { expires: 1,  path: '/' });

	var addMenuContentObj = Ext.getCmp('content-main');
	var addTabObj = addMenuContentObj.child('#'+loadPage);

	if (!addTabObj)
	{
		addTabObj = Ext.getCmp('content-main').add(
			Ext.create('/admin/js/' + loadPage,  {
				itemId: loadPage, 
				layout: 'fit'
			})
		);
	}

	if (stage == 'support')
	{
		Ext.getCmp('content-left').hide();
		Ext.getCmp('MCC_cnSupportInfo').show();
	}
	else if (stage == 'running')
	{
		Ext.getCmp('content-left').show();
		Ext.getCmp('MCC_cnSupportInfo').hide();
	}

	Ext.getCmp('content-main').layout.setActiveItem(addTabObj);
	Ext.getCmp('MCC_cnClusterNodePanel').setBodyStyle('padding-left:'+padding+'px; padding-right:'+padding+'px;');
	Ext.getCmp('content-main-header-label').update("&nbsp;&nbsp;");
	Ext.getCmp(loadPage).load();
};

/*
 * 페이지 로드 시 실행 함수
 */
function MCC_clusterNodeLoad()
{
	// 노드 관리 페이지
	var pattern  = /manager_node/;
	var page     = Ext.util.Cookies.get('gms_page');

	if (page.match(pattern))
	{
		Ext.getCmp('MCC_cnClusterNodePanel').hide();
		Ext.getCmp(page).load('node');
		Ext.getCmp('MCC_cnNodeTab').show();
	}
	else
	{
		Ext.getCmp('MCC_cnClusterNodePanel').show();
		Ext.getCmp('MCC_cnNodeTab').hide();

		MCC_cnCluesterManagementStore.removeAll();
		MCC_cnNodeManagementStore.removeAll();

		// 클러스터 목록 그리드 로드
		MCC_cnCluesterManagementStore.load();

		// 노드 목록 그리드 로드
		MCC_cnNodeManagementStore.load();

		// 30초 마다 주기적으로 데이터 호출
		_nowCurrentclusterNodeVar
			= setInterval(
				function () {
					MCC_cnClusterManagement();
					MCC_cnNodeManagement();
				},
				30000);
	}
};

/*
 * 클러스터 관리 정보 호출
 */
function MCC_cnClusterManagement()
{
	GMS.Ajax.request({
		url: '/api/cluster/stage/info',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				console.error('Failed to get stage info:', decoded);
				return;
			}

			var nodes = decoded.entity;

			MCC_cnClusterManagementGrid.store.each(
				function (record) {
					record.set('Stage', nodes.Stage);
					record.set('Status_Msg', nodes.Status_Msg);
					record.set('Total_Capacity', nodes.Total_Capacity);
					record.set('Usage_Capacity', nodes.Usage_Capacity);

					var oldManagement = record.get('Management').join(',');
					var newManagement = nodes.Management.join(',');

					if (oldManagement !== newManagement)
					{
						record.set('Management', nodes.Management);
					}
				}
			);
		}
	});
};

/*
 * 노드 관리 정보 호출
 */
function MCC_cnNodeManagement()
{
	GMS.Ajax.request({
		url: '/api/cluster/general/nodelist',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			var nodeList = decoded.entity;

			MCC_cnNodeManagementGrid.store.each(
				function (record) {
					for (var i=0; i<nodeList.length; i++)
					{
						if (nodeList[i].Mgmt_Hostname
								!== record.get('Mgmt_Hostname'))
							continue;

						if (record.get('Mgmt_IP') === document.location.host
							&& record.get('Stage') !== nodeList[i].Stage)
						{
							clearInterval(_nowCurrentclusterNodeVar);
							_nowCurrentclusterNodeVar = null;
							location.replace('./');
							continue;
						}

						record.set('HW_Status', nodeList[i].HW_Status);
						record.set('Stage', nodeList[i].Stage);
						record.set('Mgmt_IP', nodeList[i].Mgmt_IP.ip);

						if (nodeList[i].Service_IP.length > 1)
						{
							record.set('Service_IP', nodeList[i].Service_IP.join(', '));
						}

						record.set('Version', nodeList[i].Version);
						record.set('CPU', nodeList[i].CPU);
						record.set('Physical_Block_Size', nodeList[i].Physical_Block_Size);
						record.set('Memory', nodeList[i].Memory);

						var oldManagement = record.get('Management').join(', ');
						var newManagement = nodeList[i].Management.join(', ');

						if (oldManagement !== newManagement)
						{
							record.set('Management', nodeList[i].Management);
						}
					}
				}
			);
		}
	});
};

/*
 * 클러스터 관리 목록
 */
// 클러스터 관리 모델
Ext.define('MCC_cnCluesterManagementModel',{
	extend: 'Ext.data.Model',
	fields: [
		'Name', 'Stage', 'Status_Msg', 'Total_Capacity',
		'Usage_Capacity', 'Management'
	]
});

// 클러스터 관리 스토어
var MCC_cnCluesterManagementStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCC_cnCluesterManagementModel',
		sorters: [
			{ property: 'Name', direction: 'ASC' }
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/stage/info',
			reader: {
				type: 'json',
				root: 'entity',
				idProperty: 'Name',
			}
		},
		listeners: {
			load: function (store, records, success) {
				if (!success)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcc_clusterNode[0] + '",'
						+ '"content": "' + lang_mcc_clusterNode[6] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				MCC_cnClusterManagementGrid.unmask();
			}
		}
	}
);

// 클러스터 관리 그리드
var MCC_cnClusterManagementGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCC_cnClusterManagementGrid',
		store: MCC_cnCluesterManagementStore,
		multiSelect: false,
		title: lang_mcc_clusterNode[7],
		cls: 'line-break',
		viewConfig: {
			markDirty: false,
			loadMask: true,
			trackOver: false
		},
		listeners: {
			beforeselect: function () {
				return false;
			}
		},
		columns: [
			{
				flex: 1,
				text: lang_mcc_clusterNode[16],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Name'
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[17],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Stage'
			},
			{
				flex: 1.5,
				text: lang_mcc_clusterNode[18],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Status_Msg'
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[19],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Total_Capacity'
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[20],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Usage_Capacity'
			},
			{
				text: lang_mcc_clusterNode[15],
				width: 140,
				autoSizeColumn: true,
				minWidth: 140,
				sortable: false,
				menuDisabled: true,
				dataIndex: 'Management',
				xtype: 'componentcolumn',
				renderer: function (value, metaData, record) {
					var scrollMenu = new Ext.menu.Menu();

					for (var i=0; i<value.length; i++)
					{
						scrollMenu.add({
							text: value[i],
							handler: clstMgmtBtnHandler
						});
					}

					return {
						xtype: 'button',
						text: lang_mcc_clusterNode[15],
						menu: scrollMenu
					};
				}
			}
		]
	}
);

function clstMgmtBtnHandler (btn, e)
{
	var me = this;
	me.up('button').setText(btn.text);

	Ext.defer(function () {
		me.up('button').setText(lang_mcc_clusterNode[15]);
	}, 10);

	var stage = btn.text

	Ext.MessageBox.confirm(
		lang_mcc_clusterNode[0],
		lang_mcc_clusterNode[21].replace("@", btn.text),
		function (btn, text) {
			if (btn !== 'yes')
				return;

			clearInterval(_nowCurrentclusterNodeVar);
			_nowCurrentclusterNodeVar = null;

			// 볼륨 삭제 유무 확인
			waitWindow(lang_mcc_clusterNode[0], lang_mcc_clusterNode[22].replace("@", stage));

			GMS.Ajax.request({
				url: '/api/cluster/stage/set',
				jsonData: {
						Stage: stage,
						Scope: 'cluster'
				},
				callback: function (options, success, response, decoded) {
					if (!success || !decoded.success)
					{
						console.error('Failed to set stage:', decoded);
						return;
					}

					Ext.MessageBox.alert(
						lang_mcc_clusterNode[0],
						lang_mcc_clusterNode[23],
						function () {
							if (stage == 'support')
							{
								supportPageDynamicChange(150, stage);
							}
							else if (stage == 'running')
							{
								supportPageDynamicChange(20, stage);
							}

							return true;
						}
					);
				}
			});
		}
	);

	return;
}

// 호스트명 정렬
Ext.apply(Ext.data.SortTypes, {
	asHostName: function (hostname) {
		var hostnameData   = hostname.split('-');
		var hostnameNumber = parseInt(hostnameData[1]);

		return hostnameNumber;
	}
});

/*
 * 노드 관리 목록
 */
// 노드 관리 모델
Ext.define('MCC_cnNodeManagementModel', {
	extend: 'Ext.data.Model',
	fields: [
		{
			name: 'Mgmt_Hostname',
			sortType: 'asHostName',
		},
		'HW_Status',
		{
			name: 'Mgmt_IP',
			mapping: 'Mgmt_IP.ip',
		},
		'Service_IP',
		'Stage',
		'Version',
		'Management',
		'CPU',
		'Physical_Block_Size',
		'Memory'
	]
});

// 노드 관리 스토어
var MCC_cnNodeManagementStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCC_cnNodeManagementModel',
		sorters: [
			{
				property: 'Mgmt_Hostname',
				direction: 'ASC'
			}
		],
		proxy: {
			type: 'ajax',
			url: '/api/cluster/general/nodelist',
			reader: {
				type: 'json',
				idProperty: 'Mgmt_Hostname',
				root: 'entity'
			}
		},
		listeners: {
			load: function (store, records, success) {
				MCC_cnNodeManagementGrid.unmask();

				if (success !== true)
				{
					// 예외 처리에 따른 동작
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof(jsonText) === 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title": "' + lang_mcc_clusterNode[0] + '",'
						+ '"content": "' + lang_mcc_clusterNode[6] + '",'
						+ '"response": ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}

				for (var i=0; i<records.length; i++)
				{
					if (records[i].get('Service_IP').length <= 1)
						continue;

					records[i].set(
						'Service_IP',
						records[i].get('Service_IP').join(', ')
					);
				}

				Ext.getCmp('MCC_cnNodeManagementNodeTotal')
					.setText(lang_mcc_clusterNode[32] + ': ' + records.length);

				MCC_cnNodeManagement();

				// 데이터 로드 성공 메세지
				//Ext.ux.DialogMsg.msg(lang_mcc_clusterNode[0], lang_mcc_clusterNode[3]);
			}
		}
	}
);

// 노드 관리 그리드
var MCC_cnNodeManagementGrid = Ext.create(
	'BaseGridPanel',
	{
		id: 'MCC_cnNodeManagementGrid',
		store: MCC_cnNodeManagementStore,
		multiSelect: false,
		title: lang_mcc_clusterNode[8],
		cls: 'line-break',
		height: 300,
		viewConfig: { markDirty: false, loadMask: true },
		listeners: {
			beforeselect: function () {
				return false;
			}
		},
		header: {
			titlePosition: 0,
			items:[
				{
					xtype: 'label',
					id: 'MCC_cnNodeManagementNodeTotal',
					style: 'padding-right: 5px;',
				}
			]
		},
		columns: [
			{
				flex: 1,
				text: lang_mcc_clusterNode[9],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Mgmt_Hostname',
			},
			{
				flex: 0.5,
				text: lang_mcc_clusterNode[14],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'HW_Status',
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[13],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Stage',
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[11],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Mgmt_IP',
			},
			{
				flex: 1.5,
				text: lang_mcc_clusterNode[12],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Service_IP',
			},
			{
				flex: 2.5,
				text: lang_mcc_clusterNode[29],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'CPU',
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[30],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Memory',
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[31],
				menuDisabled: true,
				sortable: true,
				dataIndex: 'Physical_Block_Size',
			},
			{
				flex: 1,
				text: lang_mcc_clusterNode[10],
				sortable: true,
				menuDisabled: true,
				dataIndex: 'Version'
			},
			{
				text: lang_mcc_clusterNode[15],
				width: 140,
				autoSizeColumn: true,
				minWidth: 140,
				sortable: false,
				menuDisabled: true,
				dataIndex: 'Management',
				xtype: 'componentcolumn',
				renderer: function (value, metaData, record) {
					var scrollMenu = new Ext.menu.Menu();

					//console.log('IP:', record.get('Mgmt_IP'));
					//console.log('value:', value);

					// if the current page is not the support page
					if (Ext.getCmp('MCC_cnSupportInfo').hidden !== false)
					{
						var stage = record.get('Stage');

						if (stage == 'running')
						{
							scrollMenu.add({
								text: lang_mcc_clusterNode[8],
								handler: function (btn, e) {
									selectClusterNode(record.get('Mgmt_IP'));

									$.cookie(
										'gms_page',
										'manager_node_condition',
										{ expires: 1, path: '/' });
								}
							});
						}
					}

					for (var i=0; i<value.length; i++)
					{
						// TODO: remove below code if we support the
						//       attaching/detaching
						if (value[i].match(/^(attach|detach)$/))
						{
							continue;
						}

						scrollMenu.add({
							text: value[i],
							handler: function (btn, e) {
								var me = this;

								me.up('button').setText(btn.text);

								Ext.defer(function () {
									me.up('button').setText(lang_mcc_clusterNode[15]);
								}, 10);

								nodeMgmtBtnHandler(btn, e, record);
							}
						});
					}

					if (value.length > 0)
					{
						return {
							xtype: 'button',
							text: lang_mcc_clusterNode[15],
							menu: scrollMenu
						}
					}
				}
			}
		]
	}
);

function nodeMgmtBtnHandler(btn, e, record)
{
	var clicked = btn.text;
	var message;

	if (clicked.match(/^(expand|attach|detach)$/))
	{
		message = lang_mcc_clusterNode[33]
			.replace('@', record.get('Mgmt_Hostname'));
	}
	else
	{
		message = lang_mcc_clusterNode[25]
			.replace('@', record.get('Mgmt_Hostname'))
			.replace('@', clicked);
	}

	Ext.MessageBox.confirm(
		lang_mcc_clusterNode[0],
		message,
		function (btn, text) {
			if (btn !== 'yes')
				return;

			clearInterval(_nowCurrentclusterNodeVar);
			_nowCurrentclusterNodeVar = null;

			if (clicked.match(/^(expand|attach|detach)$/))
			{
				waitWindow(
					lang_mcc_clusterNode[0],
					lang_mcc_clusterNode[34]
						.replace('@', record.get('Mgmt_Hostname'))
				);

				nodeMgmtMemberHandle({ action: clicked, record: record });
			}
			else
			{
				waitWindow(
					lang_mcc_clusterNode[0],
					lang_mcc_clusterNode[26]
						.replace('@', record.get('Mgmt_Hostname'))
						.replace('@', clicked)
				);

				nodeMgmtStageHandle({ stage: clicked, record: record });
			}
		}
	);
}

function nodeMgmtMemberHandle(params)
{
	params = params || {};

	action = params.action;
	record = params.record;

	if (action == null || !action.match(/^(expand|attach|detach)$/))
	{
		console.error('Invalid parameter: action');
		return;
	}

	if (action.match(/^(attach|detach)$/))
	{
		console.error(action + 'ing is not supported');
		return;
	}

	if (record == null)
	{
		console.error('Invalid parameter: record');
		return;
	}

	// 노드 라이선스 체크
	var checkNodeCount = 0;

	Ext.each(
		MCC_cnNodeManagementStore.data.items,
		function (record) {
			if (record.get('Stage').match(/^(running|support)$/))
			{
				checkNodeCount++;
			}
		}
	);

	if (licenseNode != 'Unlimited' && checkNodeCount >= licenseNode)
	{
		Ext.MessageBox.alert(lang_mcc_clusterNode[0], lang_mcl_license[24]);
		return false;
	}

	initProgress();

	progressWindow.show();

	progressStatus('/api/cluster/stage/get');

	GMS.Ajax.request({
		url: '/api/cluster/init/' + action,
		jsonData: {
			Manage_IP: record.get('Mgmt_IP')
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				progressWindow.hide();

				clearInterval(_nowCurrentclusterNodeVar);

				_nowCurrentclusterNodeVar = setInterval(
					function () {
						MCC_cnClusterManagement();
						MCC_cnNodeManagement();
					},
					30000
				);

				return;
			}

			Ext.getCmp('progressProcRate').updateProgress('100', '100 %');
			Ext.getCmp('progressTotalRate').updateProgress('100', '100 %');

			Ext.MessageBox.show({
				title: lang_mcc_clusterNode[0],
				msg: lang_mcc_clusterNode[35]
						.replace('@', record.get('Mgmt_Hostname')),
				buttons: Ext.MessageBox.OK,
				fn: function (buttonId) {
					if (buttonId === 'ok')
					{
						locationMain();
					}
				}
			});
		}
	});

	// 클러스터 상태
	MNS_stageClusterStatus(record.get('Mgmt_IP'));
}

function nodeMgmtStageHandle(params)
{
	params = params || {};

	record = params.record;

	if (record == null)
	{
		console.error('Invalid parameter: record');
		return;
	}

	GMS.Ajax.request({
		url: '/api/cluster/stage/set',
		jsonData: {
			Stage: params.stage,
			Scope: record.getId(),
			Data: params.data,
		},
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				return;
			}

			if (record.get('Mgmt_IP') == document.location.hostname)
			{
				Ext.MessageBox.alert(
					lang_mcc_clusterNode[0],
					lang_mcc_clusterNode[27]
						.replace('@', record.get('Mgmt_Hostname')),

					function () {
						if (params.stage == 'support')
						{
							supportPageDynamicChange(150, params.stage);
						}
						else if (params.stage == 'running')
						{
							supportPageDynamicChange(20, params.stage);
						}

						return true;
					}
				);
			}
			else
			{
				Ext.MessageBox.alert(
					lang_mcc_clusterNode[0],
					lang_mcc_clusterNode[27]
						.replace('@', record.get('Mgmt_Hostname'))
				);

				MCC_cnClusterManagement();
				MCC_cnNodeManagement();
			}
		}
	});
}

/*
 * 클러스터 노드 관리
 */
Ext.define('/admin/js/manager_cluster_clusterNode', {
	extend: 'BasePanel',
	id: 'manager_cluster_clusterNode',
	bodyStyle: 'padding: 0;',
	load: function () {
		MCC_clusterNodeLoad();

		for (var i=0; i<Ext.getCmp('MCC_cnNodeTab').items.keys.length; i++)
		{
			Ext.getCmp('MCC_cnNodeTab').items.getAt(i).setDisabled(false);
		}
	},
	items: [
		{
			xtype: 'BasePanel',
			layout: { type: 'vbox', align : 'stretch' },
			bodyStyle: 'padding: 0',
			items: [
				{
					xtype: 'BasePanel',
					layout: 'fit',
					id: 'MCC_cnSupportInfo',
					hidden: true,
					bodyCls: 'm-info-panel',
					html: '<img src="/admin/images/img_nodemgt.png" height="84" width="84"> <br>'
							+ lang_staging[6].replace("@", lang_staging[1])
				},
				{
					xtype: 'BasePanel',
					id: 'MCC_cnClusterNodePanel',
					flex: 1,
					layout: { type: 'vbox', align : 'stretch' },
					bodyStyle: 'padding: 20px;',
					items: [
						{
							xtype: 'BasePanel',
							id: 'MCC_cnClusterManagementPanel',
							layout: 'fit',
							height: 103,
							bodyStyle: 'padding: 0',
							style: { marginBottom: '20px' },
							items: [ MCC_cnClusterManagementGrid ]
						},
						{
							xtype: 'BasePanel',
							id: 'MCC_cnNodeManagementPanel',
							layout: 'fit',
							flex: 1,
							bodyStyle: 'padding: 0',
							items: [ MCC_cnNodeManagementGrid ]
						}
					]
				},
				{
					xtype: 'tabpanel',
					id: 'MCC_cnNodeTab',
					activeTab: 0,
					frame: false,
					border: false,
					hidden: true,
					flex: 1,
					bodyStyle: 'padding: 0px;',
					listeners: {
						render: function (tabPanel) {
							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_condition',
									{
										title: lang_mnc_condition[0],
										itemId: 'manager_node_condition',
										layout: 'fit',
										iconCls: 't-icon-condition'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_disk',
									{
										title: lang_mnd_disk[0],
										itemId: 'manager_node_disk',
										layout: 'fit',
										iconCls: 't-icon-disk'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_volume',
									{
										title: lang_mnv_volume[0],
										itemId: 'manager_node_volume',
										layout: 'fit',
										iconCls: 't-icon-volume'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_process',
									{
										title: lang_mnp_process[0],
										itemId: 'manager_node_process',
										layout: 'fit',
										iconCls: 't-icon-process'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_raid',
									{
										title: lang_mnr_raid[19],
										itemId: 'manager_node_raid',
										layout: 'fit',
										iconCls: 't-icon-raid'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_network',
									{
										title: lang_mnn_network[0],
										itemId: 'manager_node_network',
										layout: 'fit',
										iconCls: 't-icon-network'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_power',
									{
										title: lang_mnp_power[0],
										itemId: 'manager_node_power',
										layout: 'fit',
										iconCls: 't-icon-power'
									}
								)
							);

							Ext.getCmp('MCC_cnNodeTab').add(
								Ext.create(
									'/admin/js/manager_node_smart',
									{
										title: 'S.M.A.R.T.',
										itemId: 'manager_node_smart',
										layout: 'fit',
										iconCls: 't-icon-smart'
									}
								)
							);
						},
						tabchange: function (tabPanel, newCard, oldCard) {
							// 주기적 호출 제거
							clearInterval(_nowCurrentConditionVar);
							_nowCurrentConditionVar = null;

							clearInterval(_nowCurrentConditionEventVar);
							_nowCurrentConditionEventVar = null;

							clearInterval(_nowCurrentConditionChartVar);
							_nowCurrentConditionChartVar = null;

							// 로드할 페이지
							var loadPage = newCard.itemId;

							// 마스크 표시
							for (var i=0; i<tabPanel.items.keys.length; i++)
							{
								Ext.getCmp('MCC_cnNodeTab').items.getAt(i).setDisabled(true);
							}

							tabPanel.down('#'+loadPage).setDisabled(false);
							Ext.getCmp(tabPanel.activeTab.initialConfig.itemId).mask();

							// 스테이지 확인
							MA_licenseCheck(
								loadPage,
								function (licenseCheck, stage, stageData) {
									// 마스크 제거
									Ext.getCmp(tabPanel.activeTab.initialConfig.itemId).unmask();

									if (loadPage !== 'manager_node_condition')
									{
										// 성능 통계 그래프 오류로 인해 오버뷰 페이지는
										// 해당 페이지에서 성능 통계 데이터 로드 후 해제함
										for (var i=0; i<tabPanel.items.keys.length; i++)
										{
											Ext.getCmp('MCC_cnNodeTab').items.getAt(i).setDisabled(false);
										}
									}

									// 응답 데이터
									var stageStatusValue = clusterStageStatus( loadPage, licenseCheck,  stage, stageData );

									// 별도 페이지를 보여줘야 하는 경우
									if (stageStatusValue === 'node')
									{
										var stagePage = 'manager_node_stage';
										var addMenuContentObj = Ext.getCmp('content-main');
										var addTabObj = addMenuContentObj.child('#'+stagePage);

										if (!addTabObj)
										{
											addTabObj = Ext.getCmp('content-main').add(
												Ext.create(
													'/admin/js/'+stagePage,
													{
														itemId: stagePage,
														layout: 'fit'
													}
												)
											);
										}

										Ext.getCmp('content-main').layout.setActiveItem(addTabObj);
										Ext.getCmp(stagePage).load('node');
									}
									else
									{
										// 탭 선택 시 적용 함수 실행
										adminTabLoad(
											loadPage,
											function (loadPage) {
												// 초기 함수 실행
												$.cookie('gms_page', loadPage, { expires: 1, path: '/' });
												Ext.getCmp(loadPage).load();
											}
										);
									}
								}
							);
						}
					}
				}
			]
		}
	]
});
