/*
 * 페이지 로드 시 실행 함수
 */
function MNP_powerLoad()
{
	Ext.getCmp('MNP_powerPanelTitle').update(
		lang_mnp_power[3].replace(
			'@',
			Ext.getCmp('content-main-node-combo').rawValue)
	);
};

/*
 * 전원 재시작/끄기
 */
var MNP_powerPanel = Ext.create('BaseFormPanel', {
	id: 'MNP_powerPanel',
	title: lang_mnp_power[0],
	frame: true,
	items: [
		{
			xtype: 'BasePanel',
			id: 'MNP_powerPanelTitle',
			bodyStyle: 'padding: 0',
			style: { marginBottom: '30px' }
		},
		{
			xtype: 'radiogroup',
			fieldLabel: lang_mnp_power[2],
			width: 500,
			items: [
				{
					boxLabel: lang_mnp_power[1],
					id: 'MNP_powerHalt',
					name: 'powerSet',
					checked: true,
					inputValue: 'shutdown'
				},
				{
					boxLabel: lang_mnp_power[4],
					id: 'MNP_powerReboot',
					name: 'powerSet',
					inputValue: 'reboot'
				}
			]
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mnp_power[5],
			id: 'MNP_powerButton',
			handler: function() {
				if (!MNP_powerPanel.getForm().isValid())
					return false;

				var reqUrl;

				if (Ext.getCmp('MNP_powerHalt').getValue() == true)
				{
					waitWindow(lang_mnp_power[0], lang_mnp_power[11]);
					reqUrl = '/api/system/power/shutdown';
				}
				else if (Ext.getCmp('MNP_powerReboot').getValue() == true)
				{
					waitWindow(lang_mnp_power[0], lang_mnp_power[10]);
					reqUrl = '/api/system/power/reboot';
				}

				Ext.getCmp('MNP_powerPanel').getForm().submit({
					method: 'POST',
					url: reqUrl,
					success: function(form, action) {
						// 메세지 출력
						if (Ext.getCmp('MNP_powerHalt').getValue() == true)
						{
							if(waitMsgBox)
							{
								//데이터 전송완료후: wait제거
								waitMsgBox.hide();
								waitMsgBox = null;
							}

							var returnMsg = lang_mnp_power[7];
							var responseMsg = action.result.msg;
							if(responseMsg)
							{
								returnMsg = responseMsg;
							}
							Ext.MessageBox.alert(lang_mnp_power[0], returnMsg);
						}
						else if (Ext.getCmp('MNP_powerReboot').getValue() == true)
						{
							var cut_data = document.location.href;
							var reader = document.createElement('a');
							reader.href = cut_data;
							var protocol = reader.protocol.replace(':', '');
							var addr = reader.hostname;
							var protData = (reader.port) ? reader.port : '80';
							var page = reader.pathname;

							if (reader.hostname == Ext.getCmp('content-main-node-combo').getValue())
							{
								var addrData = '{'
									+ '"protocol": "' + protocol + '",'
									+ '"address": "' + addr + '",'
									+ '"page": "",'
									+ '"httpPort": "' + protData + '",'
									+ '"httpsPort": "' + protData + '"'
								+ '}';

								setTimeout(function() { MNP_powerHostLocation(addrData); }, 60000);
							}
							else
							{
								// 데이터 전송 완료 후 wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								var responseMsg = action.result.msg;
								var returnMsg   = responseMsg || lang_mnp_power[8];

								Ext.MessageBox.alert(lang_mnp_power[0], returnMsg);
							}
						}
					},
					failure: function(form, action) {
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
							+ '"title": "' + lang_mnp_power[0] + '",'
							+ '"content": "' + lang_mnp_power[9] + '",'
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	]
});

// 웹서버 연결 함수 (IP 변경)
function MNP_powerHostLocation(postAddr)
{
	var responseData = Ext.JSON.decode(postAddr);
	var protocol = responseData.protocol;
	var address = responseData.address;
	var page = responseData.page;
	var httpPort = responseData.httpPort;

	if (typeof(httpPort) == 'undefined' || httpPort == '')
		httpPort = '80';

	var httpsPort = responseData.httpsPort;
	var scriptTimestamp = Math.floor(new Date().getTime() / 1000);
	var imgObj = new Image();

	var src = "http://" + address + ":" + httpPort
			+ "/common/images/img_logo.png?t=" + scriptTimestamp;

	var url = protocol + "://" + address
			+ ":" + (protocol == 'http' ? httpPort : httpsPort);

	imgObj.src = src;
	imgObj.onload = function() {
		// 데이터 전송 완료 후 wait 제거
		if (waitMsgBox)
		{
			waitMsgBox.hide();
			waitMsgBox = null;
		}

		// 관리 IP일 경우 비활성화
		Ext.MessageBox.show({
			title: lang_mnp_power[0],
			msg: lang_mnp_power[8],
			buttons: Ext.MessageBox.OK,
			fn: function(buttonId) {
				if (buttonId === "ok")
				{
					location.href = url;
				}
			}
		});
	};

	imgObj.onerror = function() {
		setTimeout(function() { MNP_powerHostLocation(postAddr); }, 5000);
	};
};

// 전원 설정
Ext.define('/admin/js/manager_node_power', {
	extend: 'BasePanel',
	id: 'manager_node_power',
	load: function() {
		MNP_powerLoad();
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 20px',
			items: [MNP_powerPanel]
		}
	]
});
