Ext.Loader.setConfig(
	{
		enabled: true,
		paths: {
			'Ext.ux': '/js/libraries',
			'Ext.ux.Deferred': '/js/ext.ux.deferred/Deferred.js',
			'Ext.ux.Promise': '/js/ext.ux.deferred/Promise.js',
		}
	}
);

var default_timeout = 60000 * 3;

/*
 * Use POST as a default HTTP method
-**/
Ext.override(
	Ext.data.proxy.Ajax,
	{
		timeout: default_timeout,
		getMethod: function (request) { return 'POST'; }
	}
);

Ext.override(
	Ext.Ajax,
	{
		timeout: default_timeout,
		method: 'POST',
	}
);

// 메뉴 스크롤 파일 가져오기
Ext.require([
	'Ext.ux.DialogMsg',
	//'Ext.ux.PagingMemoryProxy',
	'Ext.ux.IFrame',
	'Ext.ux.SearchField',
	'Ext.ux.componentcolumn',
	'Ext.ux.CTemplate',
	'Ext.ux.PreviewPlugin',
	'Ext.ux.Deferred',
	'Ext.ux.Promise',
]);
/*
 * 서포트 페이지 출력
 */
function printSupportPage()
{
	var loadPage = 'manager_cluster_clusterNode';

	$.cookie('gms_page', loadPage, { expires: 1, path: '/' });

	var addMenuContentObj = Ext.getCmp('content-main');
	var addTabObj = addMenuContentObj.child('#' + loadPage);

	if (!addTabObj)
	{
		addTabObj
			= Ext.getCmp('content-main').add(
				Ext.create(
					'/admin/js/' + loadPage,
					{
						itemId: loadPage,
						layout: 'fit'
					}
				));
	}

	Ext.getCmp('content-left').hide();
	Ext.getCmp('content-main').layout.setActiveItem(addTabObj);
	Ext.getCmp('content-main-header-label').update("&nbsp;&nbsp;");

	Ext.getCmp('MCC_cnClusterNodePanel')
		.setBodyStyle('padding-left: 150px; padding-right: 150px;');

	Ext.getCmp('MCC_cnSupportInfo').show();
	Ext.getCmp(loadPage).load();
}

/*
 * 노드 관리 페이지 변경
 */
function pageChange()
{
	// 주기적 호출 제거
	clearInterval(_nowCurrentConditionVar);
	_nowCurrentConditionVar = null;

	clearInterval(_nowCurrentConditionEventVar);
	_nowCurrentConditionEventVar = null;

	clearInterval(_nowCurrentConditionChartVar);
	_nowCurrentConditionChartVar = null;

	// 클러스터 노드 관리 페이지
	var loadPage = 'manager_cluster_clusterNode';

	var record
		= Ext.getCmp('adminTreePanel')
			.getStore()
			.getNodeById(loadPage);

	// 트리 각 메뉴의 text
	var treeText = record.raw.text;

	// 트리 각 메뉴의 ptext
	var treePtext = record.raw.ptext;

	Ext.getCmp('content-main-header-label')
		.update(treePtext + '>>' + treeText);

	Ext.getCmp('content-main-node-combo').hide();

	// 쿠키 생성
	$.cookie('gms_page', loadPage, { expires: 1, path: '/' });
	$.cookie('gms_node', window.location.host, { expires: 1, path: '/' });

	// 마스크 표시
	Ext.getCmp(loadPage).mask();

	// 탭 선택 시 적용 함수 실행
	adminTabLoad(
		loadPage,
		function (loadPage) {
			// 초기 함수 실행
			Ext.getCmp(loadPage).load();

			// 마스크 제거
			Ext.getCmp(loadPage).unmask();
		});
}

/*
 * 노드 관리 메뉴의 콤보박스
 */
// 노드명 정렬
Ext.apply(
	Ext.data.SortTypes,
	{
		asHostName: function (hostname) {
			//if (hostname != 'cluster')
			//	return 0;

			var hostnameData   = hostname.split('-');
			var hostnameNumber = parseInt(hostnameData[1]);

			return hostnameNumber;
		}
	}
);

// 노드 콤보박스 모델
Ext.define(
	'nodeListComBoModel',
	{
		extend: 'Ext.data.Model',
		fields: [
			{ name: 'Mgmt_Hostname', sortType: 'asHostName' },
			'Mgmt_IP'
		]
	}
);

// 노드 콤보박스 스토어
var nodeListComboStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'nodeListComBoModel',
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
				root: 'entity',
				idProperty: 'Mgmt_Hostname'
			}
		},
		listeners: {
			beforeload: function (store, operation, eOpts) {
				store.removeAll();
			},
			load: function (store, records, success) {
				// 예외 처리에 따른 동작
				if (!success)
				{
					var jsonText = JSON.stringify(store.proxy.reader.rawData);

					if (typeof jsonText == 'undefined')
						jsonText = '{}';

					var checkValue = '{'
						+ '"title" : "' + lang_admin[2] + '",'
						+ '"content" : "' + lang_admin[3] + '",'
						+ '"response" : ' + jsonText
					+ '}';

					return exceptionDataCheck(checkValue);
				}
			}
		}
	}
);

/*
 * 노드 변경 시 해당 노드의 스테이지 확인
 */
function selectClusterNode(mgmt_ip)
{
	// 주기적 호출 제거
	clearInterval(_nowCurrentConditionVar);
	_nowCurrentConditionVar = null;

	clearInterval(_nowCurrentConditionEventVar);
	_nowCurrentConditionEventVar = null;

	clearInterval(_nowCurrentConditionChartVar);
	_nowCurrentConditionChartVar = null;

	// 노드 관리 탭
	var loadPageTab = $.cookie('gms_page');

	if (!loadPageTab.match(/cluster/g) && Ext.getCmp('MCC_cnNodeTab'))
	{
		for (var i=0
			; i<Ext.getCmp('MCC_cnNodeTab').items.keys.length
			; i++)
		{
			Ext.getCmp('MCC_cnNodeTab').items.getAt(i).setDisabled(true);
		}

		Ext.getCmp('MCC_cnNodeTab').down('#'+loadPageTab).setDisabled(false);
	}

	Ext.getCmp('content-main').mask();

	nodeListComboStore.load(
		{
			callback: function (record, operation, success) {
				if (!success)
				{
					console.error('Failed to get node list');
					return;
				}

				var nodeComboObj = Ext.getCmp('content-main-node-combo');
				var nodes        = nodeComboObj.store.proxy.reader.rawData;

				var selected = Ext.util.Cookies.get('gms_node');

				if (!mgmt_ip && selected)
				{
					mgmt_ip = selected;
				}
				else if (!mgmt_ip)
				{
					mgmt_ip = nodes.entity[0].Mgmt_IP.ip;
				}

				var selected = null;

				nodeComboObj.store.each(function (r) {
					if (mgmt_ip == r.data.Mgmt_IP.ip )
					{
						selected = r.data.Mgmt_Hostname;
					}
				});

				$.cookie('gms_node', mgmt_ip, { expires: 1, path: '/' });

				nodeComboObj.select(selected);

				nodeListComboStore.clearFilter();
				nodeListComboStore.filter(function (r) {
					var stage = r.raw.Stage;

					return (stage == 'running'
						|| stage == 'expanding'
						|| stage == 'detaching');
				});
				nodeListComboStore.sort();

				// 노드 관리 페이지
				var loadPage = 'manager_cluster_clusterNode';
				var record = Ext.getCmp('adminTreePanel').getStore()
								.getNodeById(loadPage);

				// TREE 각 메뉴의 text
				var treeText = record.raw.text;

				// TREE 각 메뉴의 ptext
				var treePtext = record.raw.ptext;
				Ext.getCmp('content-main-node-combo').show();

				// 노드 관리 >> 노드별 현황
				var addMenuContentObj = Ext.getCmp('content-main');
				var addTabObj = addMenuContentObj.child('#'+loadPage);

				if (!addTabObj)
				{
					// 호출할 메뉴 경로
					var addMenuPath = '/admin/js/' + loadPage;

					// 메뉴 추가
					addTabObj = Ext.getCmp('content-main').add(
						Ext.create(
							addMenuPath,
							{
								itemId: loadPage,
								layout: 'fit'
							}
						)
					);
				}

				Ext.getCmp('content-main').layout.setActiveItem(addTabObj);

				Ext.getCmp('MCC_cnClusterNodePanel').hide();
				Ext.getCmp('MCC_cnNodeTab').show();
				Ext.getCmp('MCC_cnNodeTab').setActiveTab(loadPageTab);

				Ext.getCmp('content-main').unmask();

				if (loadPageTab !== 'manager_node_condition')
				{
					Ext.getCmp('content-main-header-label')
						.update(treePtext
							+ ' >> '
							+ '<span class="header-link" onclick="pageChange()">'
							+ treeText
							+ '</span> >>');

					for (var i=0
						; i<Ext.getCmp('MCC_cnNodeTab').items.keys.length
						; i++)
					{
						Ext.getCmp('MCC_cnNodeTab').items
							.getAt(i)
							.setDisabled(false);
					}
				}
				else
				{
					Ext.getCmp('content-main-header-label')
						.update(treePtext
							+ ' >> '
							+ '<span>'
							+ treeText
							+ '</span> >>');
				}

				// 탭 선택 시 적용 함수 실행
				adminTabLoad(
					loadPageTab,
					function (loadPageTab) {
						// 초기 함수 실행
						Ext.getCmp(loadPageTab).load('node');
					}
				);
			}
		}
	);

	return;
}

/*
 * URL(GET) 페이지 변경
 */
function pageSelect(type)
{
	var urlArray, urlName, urlValue;
	var urlLoadPage = document.location.href;
	var urlLoadPageData = urlLoadPage.split("?");

	if (urlLoadPageData[1])
	{
		var urlGetData = urlLoadPageData[1].split("&");

		for (var i in urlGetData)
		{
			urlArray = urlGetData[i].split("=");
			urlName  = urlArray[0];
			urlValue = urlArray[1];

			if (type == 'page')
			{
				if (urlName == 'adminLoadPage')
				{
					return urlValue;
				}
			}
			else if (type == 'tab')
			{
				if (urlName == 'adminLoadPageTab')
				{
					return urlValue;
				}
			}
		}
	}
	else
	{
		if (type == 'page')
			return $.cookie('gms_page');
	}
};

/*
 * 윈도우 크기가 변경되었을 경우 content-left의 표시 유무
 */
Ext.EventManager.onWindowResize(
	function () {
		var width = Ext.getBody().getViewSize().width;

		if (width < 1200)
		{
			Ext.getCmp('content-left').collapse();
		}
		else
		{
			Ext.getCmp('content-left').expand();
		}
	}
);

/**
 * Main function
 */
Ext.onReady(
	function ()
	{
		// 언어 리스트 데이터
		var langData = [
			{
				lang: 'ko',
				name: admin_languageList_ko
			},
			{
				lang: 'en',
				name: admin_languageList_en
			}
		];

		// 언어 리스트 모델
		Ext.define('langModel', {
			extend: 'Ext.data.Model',
			fields: [
				{ name: 'lang', type: 'string' },
				{ name: 'name', type: 'string' }
			],
			idProperty: 'lang'
		});

		// 언어 리스트 스토어
		var langStore = Ext.create(
			'Ext.data.Store',
			{
				model: 'langModel',
				data: langData
			}
		);

		// 언어 리스트 콤보박스
		var langList = Ext.create(
			'BaseComboBox',
			{
				id: 'langList',
				displayField: 'name',
				width: 90,
				store: langStore,
				queryMode: 'local',
				editable:false,
				typeAhead: true,
				value: $.cookie('language'),
				valueField: 'lang',
				displayField: 'name',
				listeners: {
					select: {
						scope: this,
						fn: function (cb, records) {
							var record = records[0];

							$.cookie(
								'language',
								record.data.lang,
								{ expires: 1, path: '/' }
							);

							location.reload();
						}
					}
				}
			}
		);

		/*
		* 클러스터 정보 출력
		*/
		GMS.Ajax.request({
			url: '/api/cluster/status',
			callback: function (options, success, response, decoded) {
				// 노드의 stage가 running이 아닐 시
				if (typeof(decoded.entity) == 'undefined')
				{
					Ext.getCmp('content-left').hide();
					Ext.getCmp('content-main-header-label').update('');
				}
				else
				{
					Ext.getCmp('adminHeaderVersion')
						.update('Ver. ' + decoded.entity.Version);

					// 클러스터 명 출력
					document.title = 'AnyStor-E ' + decoded.entity.Name;
				}
			},
		});

		/*
		* 관리자 헤더
		*/
		var adminHeaderPanel = Ext.create(
			'BasePanel',
			{
				id: 'adminHeaderPanel',
				layout: 'border',
				height: 65,
				bodyStyle: 'padding: 12px 0px; background: none;',
				items: [
					{
						id: 'adminHeaderLogo',
						region: 'west',
						border: false,
						width: 200,
						bodyStyle: 'background: none;',
						html: '<img src="/common/images/main_logo.png">'
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0; background: none',
						region: 'east',
						width: 380,
						layout: 'hbox',
						autoScroll: false,
						items:[
							{
								xtype: 'label',
								id: 'adminHeaderVersion',
								cls: 'm-custom-version',
								width: 200,
								flex: 1
							},
							{
								xtype: 'button',
								id: 'adminHeaderManual',
								text: admin_manualButton,
								width: 70,
								height: 22,
								listeners: {
									el: {
										click: function (btn) {
											manualWindowOpen('intro', '#AnyStor-E-관리자-매뉴얼');
										}
									}
								}
							},
							{
								xtype: 'button',
								id: 'adminHeaderLogOut',
								text: admin_logOutButton,
								width: 70,
								height: 22,
								handler: function () {
									$.removeCookie('gms_token');

									Ext.Ajax.request({
										url: '/api/manager/sign_out',
										success: function (response) {
											locationMain();
										},
										failure: function (response) {
											alert(response.status + ": " + response.statusText);
										}
									});
								}
							},
							{
								xtype: 'BasePanel',
								bodyStyle: 'padding: 0; background: none;',
								style: { marginTop: '10px' },
								items: langList
							}
						]
					}
				]
			});

		/*
		* 관리자 왼쪽 트리
		*/
		// 관리자 왼쪽 트리 모델
		Ext.define('adminTreeModel',{
			extend: 'Ext.data.Model',
			fields: ['id', 'text']
		});

		// 관리자 왼쪽 트리 스토어
		var adminTreeStore = Ext.create(
			'Ext.data.TreeStore',
			{
				model: 'adminTreeModel',
				root: {
					expanded: true
				},
				proxy: {
					type: 'gms',
					url: '/api/cluster/tree',
					reader: {
						type: 'json',
						root: 'entity',
					},
					listeners: {
						exception: function (me,  response,  operation,  eOpts) {
							var json = Ext.decode(response.responseText);

							if (response.status == 403 && json.stage_info.stage == 'support')
							{
								printSupportPage();
							}
							else
							{
								console.trace(response.responseText);
							}
						}
					}
				},
				listeners: {
					load: function (store, node, records, success, eOpts) {
						if (node.childNodes.length != 0)
							return;

						var jsonText = JSON.stringify(store.proxy.reader.rawData);

						if (typeof(jsonText) == 'undefined')
						{
							jsonText = '{}';
						}

						var checkValue = '{'
							+ '"title"    : "' + lang_admin[0] + '",'
							+ '"content"  : "' + lang_admin[1] + '",'
							+ '"response" : ' + jsonText
						+ '}';

						return exceptionDataCheck(checkValue);
					}
				}
			});

		// 관리자 왼쪽 트리 패널
		var adminTreePanel = Ext.create(
			'Ext.tree.Panel',
			{
				id: 'adminTreePanel',
				rootVisible: false,
				overflowY: 'auto',
				border: false,
				bodyBorder: false,
				store: adminTreeStore,
				listeners: {
					select: function (selModel, record) {
						// waitWindow(lang_admin[0], lang_admin[12]);

						// json의 id 값으로 구분
						if (!record.raw || !record.raw.id) return;

						// TREE 각 메뉴의 id
						var treeid = record.raw.id;

						// TREE 각 메뉴의 text
						var treeText = record.raw.text;

						// TREE 각 메뉴의 ptext
						var treePtext = record.raw.ptext;

						// TREE 메인을 선택 했을 경우 첫 번째 메뉴를 출력한다.
						if (!treePtext)
						{
							// 메뉴 그룹을 선택 했을 경우 첫 번째 메뉴로 이동
							treeid    = record.raw.smenu;
							treePtext = record.raw.text;
							treeText  = record.raw.stext;

							var record
								= Ext.getCmp('adminTreePanel')
									.getStore()
									.getNodeById(treeid);

							Ext.getCmp('adminTreePanel')
								.getSelectionModel()
								.select(record);

							return true;
						}

						// 호출 할 메뉴 경로
						var addMenuPath = "/admin/js/"+treeid;

						// 호출 메뉴를 추가할 영역
						var addMenuContentObj = Ext.getCmp('content-main');

						// 추가되어진 메뉴
						var addTabObj = addMenuContentObj.child('#'+treeid);

						// 메뉴 추가
						if (!addTabObj)
						{
							addTabObj = Ext.getCmp('content-main').add(
								Ext.create(
									addMenuPath,
									{
										itemId: treeid,
										layout: 'fit'
									}
								)
							);
						}

						Ext.getCmp('content-main').layout.setActiveItem(addTabObj);

						Ext.getCmp('content-main-header-label')
							.update(treePtext+" >> "+treeText);

						// 노드 콤보박스 제거
						Ext.getCmp('content-main-node-combo').hide();
						Ext.getCmp('content-main').mask();

						// AnyStor-E 라이선스 체크
						MA_licenseCheck(
							null,
							function (licenseCheck, stage, stageData) {
								// 페이지 막음 해제
								Ext.getCmp('content-main').unmask();

								if (!stage)
								{
									Ext.MessageBox.alert(
										lang_admin[0],
										lang_admin[22] +  '<br>{ "stage" : "undef" }');

									return false;
								}

								var stageStatusValue
									= clusterStageStatus(treeid, licenseCheck, stage, stageData);

								// 정상 페이지
								if (stageStatusValue == 'normal')
								{
									// 노드 관리 페이지일 경우
									if (treeid == 'manager_cluster_clusterNode'
										&& !$.cookie('gms_page').indexOf('manager_node'))
									{
										selectClusterNode();
									}
									else
									{
										// 메뉴 선택 시 쿠키 생성
										$.cookie('gms_page', treeid, { expires: 1, path: '/' });

										// 탭 선택 시 적용 함수 실행
										adminTabLoad(
											treeid,
											function (loadPage) {
												// 초기 함수 실행
												Ext.getCmp(loadPage).load();
											}
										);
									}
								}
								else if (stageStatusValue == 'clusterSupport')
								{
									printSupportPage();
								}
								else if (stageStatusValue == 'node')
								{
									// 진행 창을 보여 줘야 하는 경우
									var loadPage = 'manager_node_stage';
									var addMenuContentObj = Ext.getCmp('content-main');
									var addTabObj = addMenuContentObj.child('#' + loadPage);

									if (!addTabObj)
									{
										addTabObj = Ext.getCmp('content-main').add(
											Ext.create(
												'/admin/js/' + loadPage,
												{
													itemId: loadPage,
													layout: 'fit'
												}
											)
										);
									}

									Ext.getCmp('content-left').hide();
									Ext.getCmp('content-main').layout.setActiveItem(addTabObj);
									Ext.getCmp('content-main-header-label').update("&nbsp;&nbsp;");
									Ext.getCmp(loadPage).load();
								}
								else if (stageStatusValue == 'license')
								{
									// 라이선스 만료 페이지를 보여줘야하는 경우
									var loadPage = 'manager_cluster_license';
									var addMenuContentObj = Ext.getCmp('content-main');
									var addTabObj = addMenuContentObj.child('#' + loadPage);

									if (!addTabObj)
									{
										addTabObj = Ext.getCmp('content-main').add(
											Ext.create(
												'/admin/js/' + loadPage,
												{
													itemId: loadPage,
													layout: 'fit'
												}
											)
										);
									}

									Ext.getCmp('content-left').hide();
									Ext.getCmp('content-main').layout.setActiveItem(addTabObj);
									Ext.getCmp('content-main-header-label').update("&nbsp;&nbsp;");
									Ext.getCmp('MCL_licensePanel').setBodyStyle('padding-left:150px; padding-right:150px;');
									Ext.getCmp('MCL_licenseInfo').show();
									Ext.getCmp(loadPage).load();
								}
							}
						);
					},
					itemclick: function (view, rec, node, index, e, options) {
						if (rec.data.id != 'manager_cluster_clusterNode'
							|| $.cookie('gms_page').indexOf('manager_node'))
						{
							return;
						}

						// waitWindow(lang_admin[0], lang_admin[12]);
						var treeid = 'manager_cluster_clusterNode';

						// TREE 각 메뉴의 text
						var treeText = rec.raw.text;

						// TREE 각 메뉴의 ptext
						var treePtext = rec.raw.ptext;

						// 매뉴 선택 시 쿠키 생성
						$.cookie('gms_page', treeid, { expires: 1, path: '/' });

						// 호출할 MENU 경로
						var addMenuPath = '/admin/js/' + treeid;

						// 호출 MENU를 추가할 영역
						var addMenuContentObj = Ext.getCmp('content-main');

						// 추가되어진 MENU
						var addTabObj = addMenuContentObj.child('#' + treeid);

						Ext.getCmp('content-main').layout.setActiveItem(addTabObj);

						// 탭 선택 시 적용 함수 실행
						adminTabLoad(
							treeid,
							function (loadPage) {
								// 초기 함수 실행
								Ext.getCmp(loadPage).load();
							}
						);

						// title
						Ext.getCmp('content-main-header-label')
							.update(treePtext + ' >> ' + treeText);

						Ext.getCmp('content-main-node-combo').hide();
					},
					afterlayout: function () {
						var treeid = pageSelect('page');

						if (treeid == '' || treeid == undefined)
						{
							treeid = 'manager_cluster_overview';
						}
						else if (treeid.indexOf('manager_node') != -1)
						{
							treeid = 'manager_cluster_clusterNode';
						}

						// record 값이 없을 경우
						var record
							= Ext.getCmp('adminTreePanel')
								.getStore()
								.getNodeById(treeid);

						if (record == '' || record == undefined)
						{
							var record
								= Ext.getCmp('adminTreePanel')
									.getStore()
									.getNodeById('manager_cluster_overview');
						}

						Ext.getCmp('adminTreePanel')
							.getSelectionModel()
							.select(record);
					}
				},
				viewConfig: {
					markDirty: false
				}
			});

		/*
		* 관리자 전체 페이지
		*/
		Ext.create(
			'Ext.container.Viewport',
			{
				renderTo: Ext.getBody(),
				layout: 'border',
				items: [
					{
						xtype: 'BasePanel',
						id: 'content-top',
						itemId: 'adminHeader',
						region: 'north',
						bodyStyle: 'padding: 0; background: none;',
						minWidth: 800,
						items: adminHeaderPanel
					},
					{
						id: 'content-left',
						itemId: 'adminTree',
						title: lang_admin[0],
						region: 'west',
						weight: -20,
						collapsible: true,
						split:true,
						layout: 'fit',
						width: 250,
						minWidth: 200,
						maxWidth: 350,
						items: [ adminTreePanel ],
						listeners: {
							collapse: function () {
								$.cookie(
									'adminTreeExpand',
									'collapse',
									{ expires: 1, path: '/' }
								);
							},
							expand: function () {
								$.cookie(
									'adminTreeExpand',
									'expand',
									{ expires: 1, path: '/' }
								);
							}
						}
					},
					{
						id: 'content-main',
						itemId: 'adminContent',
						layout: 'card',
						region: 'center',
						margins: '0 5 0 0',
						minHeight: 100,
						minWidth: 800,
						autoScroll: false,
						header: {
							titlePosition: 1,
							items:[
								{
									xtype: 'BasePanel',
									bodyStyle: 'padding: 0; background: none;',
									id: 'content-main-header',
									layout: 'hbox',
									items: [
										{
											xtype: 'label',
											id: 'content-main-header-label',
											style: 'padding-right: 5px;'
										},
										{
											xtype: 'BaseComboBox',
											hideLabel: true,
											id: 'content-main-node-combo',
											hidden: true,
											store: nodeListComboStore,
											displayField: 'Mgmt_Hostname',
											valueField: 'Mgmt_IP',
											width: 130,
											bodyCls: 'm-custom-transparent',
											border: false,
											listeners: {
												change: function (combo, newValue, oldValue) {
													if (!newValue || !oldValue)
														return;

													selectClusterNode(newValue.ip);
												}
											}
										}
									]
								}
							]
						}
					}
				],
				listeners: {
					afterRender: function () {
						// 트리 접음, 펼침 쿠키값
						var loadTreeConfig = $.cookie('adminTreeExpand');

						if (typeof(loadTreeConfig) != 'undefined'
							&& loadTreeConfig == 'collapse')
						{
							Ext.defer(
								function () {
									Ext.getCmp('content-left').collapse();
								},
								200
							);
						}
						else
						{
							Ext.defer(
								function () {
									Ext.getCmp('content-left').expand();
								},
								200
							);
						}
					}
				}
			}
		);
	}
);
