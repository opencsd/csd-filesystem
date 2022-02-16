/*
 * 페이지 로드 시 실행 함수
 */
function MCP_powerLoad()
{
	if (waitMsgBox)
	{
		waitMsgBox.hide();
		waitMsgBox = null;
	}
};

/*
 * 전원 재시작/끄기
 */
var MCP_powerPanel = Ext.create('BaseFormPanel', {
	id: 'MCP_powerPanel',
	title: lang_mcp_power[0],
	frame: true,
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			style: { marginBottom: '30px' },
			html: lang_mcp_power[3]
		},
		{
			xtype: 'radiogroup',
			fieldLabel: lang_mcp_power[2],
			width: 500,
			items: [
				{
					boxLabel: lang_mcp_power[1],
					id: 'MCP_powerHalt',
					name: 'powerSet',
					checked: true,
					inputValue: 'shutdown'
				},
				{
					boxLabel: lang_mcp_power[4],
					id: 'MCP_powerReboot',
					name: 'powerSet',
					inputValue: 'reboot'
				}
			]
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcp_power[5],
			id: 'MCP_powerButton',
			handler: function () {
				if (!MCP_powerPanel.getForm().isValid())
					return false;

				var url;

				if (Ext.getCmp('MCP_powerHalt').getValue())
				{
					waitWindow(
						lang_mcp_power[0],
						lang_mcp_power[7].replace('@', 1),
					);

					url = '/api/cluster/system/power/shutdown';
				}
				else if (Ext.getCmp('MCP_powerReboot').getValue())
				{
					waitWindow(
						lang_mcp_power[0],
						lang_mcp_power[8].replace('@', 1),
					);

					url = '/api/cluster/system/power/reboot';
				}

				Ext.getCmp('MCP_powerPanel').getForm().submit({
					method: 'POST',
					url: url,
					success: function (form, action) {
						ping({
							wait: 'offline',
							callback: function (online) {
								if (online)
								{
									console.debug('Waiting for offline...');
								}
								else
								{
									console.debug('Cluster is offline!');
								}
							},
						}).success(function () {
							Ext.MessageBox.alert(
								lang_mcp_power[0],
								lang_mcp_power[9],
							);

							[
								'gms_page',
								'gms_token',
								'signing_key',
								'grafana_sess',
								'language',
							].forEach(
								function (v)
								{
									Ext.util.Cookies.clear(v);
								}
							);

							waitWindow(
								lang_mcp_power[0],
								lang_mcp_power[11],
							);

							ping({
								wait: 'online',
								callback: function (online) {
									if (!online)
									{
										console.debug('Waiting for online...');
									}
									else
									{
										console.debug('Cluster is online!');
									}
								}
							}).success(function () {
								Ext.MessageBox.alert(
									lang_mcp_power[0],
									lang_mcp_power[10],
									function () {
										location.href = window.location.origin;
									},
								);
							});
						});
					},
					failure: function (form, action) {
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						var jsonText = JSON.stringify(action.result);

						if (typeof(jsonText) == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcp_power[0] + '",'
							+ '"content": "' + lang_mcp_power[12] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}]
	});

// 웹서버 연결 함수 (IP 변경)
function MCP_powerHostLocation (params)
{
	params = params || {
		protocol: window.location.protocol.replace(':', ''),
		host: window.location.host,
		port: window.location.port,
		pathname: window.location.pathname,
	};

	if (!'protocol' in params
		|| typeof(params.protocol) == 'undefined'
		|| params.protocol == null || params.protocol == '')
	{
		params.protocol = window.location.protocol;
	}

	if (!'host' in params
		|| typeof(params.host) == 'undefined'
		|| params.host == null || params.host == '')
	{
		params.host = window.location.host;
	}

	if (!'port' in params
		|| typeof(params.port) == 'undefined'
		|| params.port == null || params.port == '')
	{
		params.port = window.location.port == '' ? 80 : window.location.port;
	}

	if (!'pathname' in params)
	{
		params.pathname = window.location.pathname;
	}

	var ts = Math.floor(new Date().getTime() / 1000);

	var url = params.protocol + '//' + params.host + ':' + params.port;
	var src = url + '/common/images/img_logo.png?t=' + ts;

	var imgObj = new Image();

	imgObj.src = src;
	imgObj.onload = function () {
		if (waitMsgBox)
		{
			waitMsgBox.hide();
			waitMsgBox = null;
		}

		// 관리 IP일 경우 비활성화
		Ext.MessageBox.show({
			title: lang_mcp_power[0],
			msg: lang_mcp_power[8],
			buttons: Ext.MessageBox.OK,
			fn: function (buttonId) {
				if (buttonId !== "ok")
					return;

			}
		});
	};

	imgObj.onerror = function () {
		setTimeout(
			function () {
				MCP_powerHostLocation(params);
			},
			5000
		);
	};
};

// 전원 설정
Ext.define('/admin/js/manager_cluster_power', {
	extend: 'BasePanel',
	id: 'manager_cluster_power',
	load: function() {
		MCP_powerLoad();
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			layout: {
				type: 'vbox',
				align : 'stretch'
			},
			bodyStyle: 'padding: 20px;',
			items: [
				{
					xtype: 'BasePanel',
					layout: 'fit',
					bodyStyle: 'padding: 0',
					items: [MCP_powerPanel]
				}
			]
		}
	]
});
