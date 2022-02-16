Ext.Loader.setConfig(
	{
		enabled: true,
		paths: {
			'Ext.ux': '/js/libraries',
			'Ext.ux.Deferred': '/js/ext.ux.deferred/Deferred.js',
			'Ext.ux.Promise': '/js/ext.ux.deferred/Promise.js',
		},
	}
);

// 클러스터 구축 마법사 패널
var MCC_configurePanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCC_configurePanel',
		frame: false,
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				style: { marginBottom: '30px' },
				html: lang_configure[1]
			},
			{
				xtype: 'BaseComboBox',
				id: 'MCC_configureBuild',
				fieldLabel: lang_configure[2],
				labelWidth: 150,
				store: new Ext.data.SimpleStore({
					fields: ['buildType','buildCode'],
					data: [
						[lang_configure[3], 'ClusterInit'],
						[lang_configure[4], 'NodeJoin']
					]
				}),
				value: 'ClusterInit',
				displayField: 'buildType',
				valueField: 'buildCode',
				style: { marginBottom: '20px' },
				listeners: {
					change: function (combo, newValue, oldValue) {
						if (newValue == 'ClusterInit')
						{
							Ext.getCmp('MCC_configureClusterInitPanel').show();
							Ext.getCmp('MCC_configureClusterInitButton').show();
							Ext.getCmp('MCC_configureNodeJoinPanel').hide();
							Ext.getCmp('MCC_configureNodeJoinButton').hide();
							Ext.getCmp('MCC_configureClusterInitPanel').getForm().reset();
						}
						else
						{
							Ext.getCmp('MCC_configureNodeJoinPanel').show();
							Ext.getCmp('MCC_configureNodeJoinButton').show();
							Ext.getCmp('MCC_configureClusterInitPanel').hide();
							Ext.getCmp('MCC_configureClusterInitButton').hide();
							Ext.getCmp('MCC_configureNodeJoinPanel').getForm().reset();
						}
					}
				}
			},
			{
				xtype: 'BaseFormPanel',
				id: 'MCC_configureClusterInitPanel',
				bodyStyle: 'padding: 0;',
				frame: false,
				items: [
					{
						xtype: 'textfield',
						id: 'MCC_configureClusterName',
						name: 'configureClusterName',
						fieldLabel: lang_configure[6],
						labelWidth: 150,
						enableKeyEvents: true,
						allowBlank: false,
						vtype: 'reg_ClusterName',
						style: { marginBottom: '20px' }
					},
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						layout: 'hbox',
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'label',
								text: lang_configure[7] + ': ',
								width: 155
							},
							{
								xtype: 'textfield',
								id: 'MCC_configureIP1_1',
								name: 'configuerIP1_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureIP1_1').setValue(
												Ext.getCmp('MCC_configureIP1_1').getValue().replace(".", "")
											);

											Ext.getCmp('MCC_configureIP1_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureIP1_2',
								name: 'configuerIP1_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureIP1_2').setValue(
												Ext.getCmp('MCC_configureIP1_2').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureIP1_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px',
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureIP1_3',
								name: 'configuerIP1_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureIP1_3').setValue(
												Ext.getCmp('MCC_configureIP1_3').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureIP1_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureIP1_4',
								name: 'configuerIP1_4',
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' }
							},
							{
								xtype: 'label',
								text: '~',
								disabledCls: 'm-label-disable-mask',
								style: {
									marginTop:'3px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureIP2_4',
								name: 'configuerIP2_4',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: {
									marginRight: '5px'
								}
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
								xtype: 'label',
								text: lang_configure[8] + ': ',
								width: 155
							},
							{
								xtype: 'textfield',
								fieldLabel: lang_configure[8],
								id: 'MCC_configureNetmask1_1',
								name: 'configuerNetmask1_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								hideLabel: true,
								width: 55,
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										netMaskInput(form.getValue(), 2, 'MCC_configureNetmask1_');

										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureNetmask1_1').setValue(
												Ext.getCmp('MCC_configureNetmask1_1').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureNetmask1_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureNetmask1_2',
								name: 'configuerNetmask1_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										netMaskInput(form.getValue(), 3, 'MCC_configureNetmask1_');

										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureNetmask1_2').setValue(
												Ext.getCmp('MCC_configureNetmask1_2').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureNetmask1_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureNetmask1_3',
								name: 'configuerNetmask1_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										netMaskInput(form.getValue(), 4, 'MCC_configureNetmask1_');

										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureNetmask1_3').setValue(
												Ext.getCmp('MCC_configureNetmask1_3').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureNetmask1_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureNetmask1_4',
								name: 'configuerNetmask1_4',
								allowBlank: false,
								vtype: 'reg_NETMASK',
								msgTarget: 'side',
								style: { marginRight: '5px' }
							}
						]
					}
				]
			},
			{
				xtype: 'BaseFormPanel',
				id: 'MCC_configureNodeJoinPanel',
				bodyStyle: 'padding: 0;',
				hidden: true,
				frame: false,
				items: [
					{
						xtype: 'BasePanel',
						bodyStyle: 'padding: 0;',
						layout: 'hbox',
						maskOnDisable: false,
						items: [
							{
								xtype: 'label',
								id: 'MCC_configureNodeIPLabel',
								text: lang_configure[16]+': ',
								disabledCls: 'm-label-disable-mask',
								width: 155
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								id: 'MCC_configureNodeIP1_1',
								name: 'configureNodeIP1_1',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								width: 55,
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureNodeIP1_1').setValue(
												Ext.getCmp('MCC_configureNodeIP1_1').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureNodeIP1_2').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureNodeIP1_2',
								name: 'configureNodeIP1_2',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureNodeIP1_2').setValue(
												Ext.getCmp('MCC_configureNodeIP1_2').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureNodeIP1_3').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop:'8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureNodeIP1_3',
								name: 'configureNodeIP1_3',
								enableKeyEvents: true,
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: { marginRight: '5px' },
								listeners: {
									keyup: function (form, e) {
										if (e.getKey() == 190 || e.getKey() == 110)
										{
											Ext.getCmp('MCC_configureNodeIP1_3').setValue(
												Ext.getCmp('MCC_configureNodeIP1_3').getValue().replace(".", "")
											);
											Ext.getCmp('MCC_configureNodeIP1_4').focus();
										}
									}
								}
							},
							{
								xtype: 'label',
								text: ' . ',
								style: {
									marginTop: '8px',
									marginRight: '5px'
								}
							},
							{
								xtype: 'textfield',
								hideLabel: true,
								width: 55,
								id: 'MCC_configureNodeIP1_4',
								name: 'configureNodeIP1_4',
								allowBlank: false,
								vtype: 'reg_IP',
								msgTarget: 'side',
								style: {
									marginRight: '5px'
								}
							}
						]
					}
				]
			}
		]
	}
);

// 클러스터 구축 윈도우
var MCC_configureWindow = Ext.create('BaseWindowPanel', {
	id: 'MCC_configureWindow',
	title: lang_configure[0],
	maximizable: false,
	closable: false,
	width: 560,
	height: 315,
	items: [MCC_configurePanel],
	fbar:[
		{
			text: lang_configure[10],
			handler: function () {
				Ext.MessageBox.confirm(
					lang_configure[0],
					lang_configure[22],
					function (btn, text) {
						if (btn != 'yes')
							return;

						Ext.Ajax.request({
							url: '/api/manager/sign_out',
							success: function (response) {
								locationMain();
							},
							failure: function (response) {
								alert(response.status + ": " + response.statusText);
							}
						});
				});
			}
		},
		'->',
		{
			text: lang_configure[9],
			id: 'MCC_configureClusterInitButton',
			handler: function () {
				// 넷마스크의 null 허용하지 않음
				Ext.getCmp('MCC_configureNetmask1_1').allowBlank = false;
				Ext.getCmp('MCC_configureNetmask1_2').allowBlank = false;
				Ext.getCmp('MCC_configureNetmask1_3').allowBlank = false;
				Ext.getCmp('MCC_configureNetmask1_4').allowBlank = false;

				if (!Ext.getCmp('MCC_configureClusterInitPanel').getForm().isValid())
					return;

				// 클러스터명
				var cluster_name = Ext.getCmp('MCC_configureClusterName').getValue();

				// IP 주소
				var svc_ip_start
					= Ext.getCmp('MCC_configureIP1_1').getValue()
						+ '.' + Ext.getCmp('MCC_configureIP1_2').getValue()
						+ '.' + Ext.getCmp('MCC_configureIP1_3').getValue()
						+ '.' + Ext.getCmp('MCC_configureIP1_4').getValue();

				var svc_ip_end
					= Ext.getCmp('MCC_configureIP1_1').getValue()
						+ '.' + Ext.getCmp('MCC_configureIP1_2').getValue()
						+ '.' + Ext.getCmp('MCC_configureIP1_3').getValue()
						+ '.' + Ext.getCmp('MCC_configureIP2_4').getValue();

				// 넷마스크
				var svc_ip_netmask
					= Ext.getCmp('MCC_configureNetmask1_1').getValue()
							+ '.' + Ext.getCmp('MCC_configureNetmask1_2').getValue()
							+ '.' + Ext.getCmp('MCC_configureNetmask1_3').getValue()
							+ '.' + Ext.getCmp('MCC_configureNetmask1_4').getValue();

				Ext.MessageBox.confirm(
					lang_configure[3],
					lang_configure[12],
					function (btn, text) {
						if (btn != 'yes')
							return;

						waitWindow(lang_configure[3], lang_configure[13]);

						GMS.Ajax.request({
							url: '/api/cluster/init/create',
							timeout: 600000,
							method: 'POST',
							jsonData: {
								Cluster_Name: cluster_name,
								Service_IP: {
									Start: svc_ip_start,
									End: svc_ip_end,
									Netmask: svc_ip_netmask,
								},
							},
							callback: function (options, success, response, decoded) {
								if (!success || !decoded.success)
								{
									clearInterval(_nowCurrentStageVar);

									_nowCurrentStageVar = null;

									progressWindow.hide();

									return;
								}

								Ext.getCmp('progressProcRate').updateProgress('100', '100 %');
								Ext.getCmp('progressTotalRate').updateProgress('100', '100 %');

								Ext.MessageBox.show({
									title: lang_configure[3],
									msg: lang_configure[14],
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
						MNS_stageClusterStatus(window.location.host);
					}
				);
			}
		},
		{
			text: lang_configure[9],
			id: 'MCC_configureNodeJoinButton',
			hidden: true,
			handler: function () {
				if (!Ext.getCmp('MCC_configureNodeJoinPanel').getForm().isValid())
					return;

				Ext.MessageBox.show({
					title: lang_configure[4],
					msg: lang_configure[17],
					buttons: Ext.Msg.YESNO,
					buttonText: {
						yes: lang_configure[18],
						no: lang_configure[19]
					},
					icon: Ext.Msg.QUESTION,
					fn: function (btn) {
						// 등록까지만 노드 추가
						// 클러스터 노드의 관리 IP
						var Cluster_IP = Ext.getCmp('MCC_configureNodeIP1_1').getValue()
										+ '.' + Ext.getCmp('MCC_configureNodeIP1_2').getValue()
										+ '.' + Ext.getCmp('MCC_configureNodeIP1_3').getValue()
										+ '.' + Ext.getCmp('MCC_configureNodeIP1_4').getValue();

						var Manual_Active = btn == 'yes' ? 'N' : 'Y';

						// 노드 라이선스 체크
						if (Manual_Active == 'N')
						{
							MA_licenseCheck();
						}

						$.cookie('selectedNode', window.location.host, { expires: 1, path: '/' });

						waitWindow(lang_configure[4], lang_configure[20]);

						// 노드 추가만 하기
						GMS.Ajax.request({
							url: '/api/cluster/init/join',
							timeout: 600000,
							method: 'POST',
							jsonData: {
								Cluster_IP: Cluster_IP,
								Manual_Active: Manual_Active
							},
							callback: function (options, success, response, decoded) {
								var manual = options.jsonData.Manual_Active;

								// 예외 처리에 따른 동작
								if (!success || !decoded.success)
								{
									if (manual == 'N')
									{
										clearInterval(_nowCurrentStageVar);
										clearInterval(_nowCurrentInitStageVar);

										_nowCurrentStageVar = null;
										_nowCurrentInitStageVar = null;

										progressWindow.hide();
									}

									return;
								}

								if (manual == 'N')
								{
									Ext.getCmp('progressProcRate').updateProgress('100', '100 %');
									Ext.getCmp('progressTotalRate').updateProgress('100', '100 %');
								}

								Ext.MessageBox.show({
									title: manual == 'N' ? lang_configure[4] : lang_configure[0],
									msg: lang_configure[21],
									buttons: Ext.MessageBox.OK,
									fn: function (buttonId) {
										if (buttonId === "ok")
										{
											if (manual == 'Y')
											{
												window.location.replace('http://' + Cluster_IP);
											}
											else
											{
												locationMain();
											}
										}
									}
								});
							}
						});

						// 노드 라이선스 체크
						if (Manual_Active == 'N')
						{
							// 클러스터 상태
							MNS_stageClusterStatus(window.location.host);
						}
					}
				});
			}
		}
	]
});

/*
 * 클러스터 구축 마법사
 */
function MII_configLoad()
{
	MCC_configureWindow.show();
}

Ext.onReady(function () { MII_configLoad(); });
