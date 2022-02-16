var cnt = 0;
var no = 0;

/*
 * NTP 서버 입력창 추가
 */
function addNtpServer()
{
	if (cnt >= 4)
	{
		Ext.MessageBox.alert(lang_mct_time[0], lang_mct_time[37]);
		return;
	}

	no++;
	cnt++;

	Ext.getCmp('MCT_timeSyncNtpServerAddPanel').add([{
		xtype: 'BasePanel',
		layout: 'hbox',
		bodyStyle: 'padding-left: 15px;',
		style: { marginBottom: '10px' },
		id: 'ntpServer' + no,
		maskOnDisable: false,
		items: [
			{
				xtype: 'textfield',
				id: 'timeSyncNtpServer' + no,
				width: 200,
				allowBlank: false
			},
			{
				xtype: 'button',
				iconCls: 'b-icon-delete',
				bodyStyle: 'padding-left: 15px;',
				style: { marginLeft: '5px' },
				id: 'removeNtpServer' + no,
				handler: function(thisButton, eventObject) {
					cnt--;
					activeRemoveButtonId = thisButton.getId().split('removeNtpServer')[1];

					Ext.getCmp('MCT_timeSyncNtpServerAddPanel').remove('ntpServer' + activeRemoveButtonId);
					Ext.getCmp('MCT_timeSyncNtpServerAddPanel').doLayout();
				}
			}
		]
	}]);

	Ext.getCmp('MCT_timeSyncNtpServerAddPanel').doLayout();
}

/*
 * 시간 정보 가져오기
 */
function MCT_timeLoad()
{
	// 마스크 표시
	var timeLoadMask = new Ext.LoadMask(
		Ext.getCmp('MCT_timeSetForm'),
		{ msg:(lang_mct_time[39]) }
	);

	timeLoadMask.show();

	var timeCurrentLoadMask = new Ext.LoadMask(
		Ext.getCmp('MCT_timeCurrentPanel'),
		{ msg:(lang_mct_time[39]) }
	);

	timeCurrentLoadMask.show();

	// 시간 정보 호출
	Ext.Ajax.request({
		url: '/api/cluster/system/time/info',
		method: 'POST',
		callback: function(options, success, response) {
			// 마스크 제거
			timeLoadMask.hide();
			timeCurrentLoadMask.hide();

			var responseData = exceptionDataDecode(response.responseText);

			// 예외 처리에 따른 동작
			if (!success || !responseData.success)
			{
				// 마스크 제거
				timeLoadMask.hide();
				timeCurrentLoadMask.hide();

				// 실패 시 로컬 시간 출력
				var now = new Date();

				document.getElementById('MCT_timeCurrentTimeStamp').innerHTML
					= now.getTime();

				nowCurrentTimer();

				// 주기적 호출 제거
				clearInterval(_nowCurrentTimerVar);

				_nowCurrentTimerVar
					= setInterval(function() { nowCurrentTimer() }, 1000);

				// 실패 시 수동 시간 설정 선택
				Ext.getCmp('MCT_timeSetManualRadio').setValue(true);

				// 실패 시 수동 시간 출력
				Ext.getCmp('MCT_timeManualHour').setValue(now.getHours());
				Ext.getCmp('MCT_timeManualMinute').setValue(now.getMinutes());
				Ext.getCmp('MCT_timeManualSecond').setValue(now.getSeconds());

				if (response.responseText == ''
						|| typeof(response.responseText) == 'undefined')
					response.responseText = '{}';

				if (typeof(responseData.msg) === 'undefined')
					responseData.msg = '';

				if (typeof(responseData.code) === 'undefined')
					responseData.code = '';

				var checkValue = '{'
					+ '"title": "' + lang_mct_time[0] + '",'
					+ '"content": "' + lang_mct_time[2] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 현재 시간 정보 출력
			document.getElementById('MCT_timeCurrentTimeStamp').innerHTML
				= responseData.entity.Datetime;

			nowCurrentTimer();

			// 현재 시간 주기적 호출
			if (responseData.entity.Datetime)
			{
				var datetime = responseData.entity.Datetime.split(' ');
				var date = datetime[0];
				var time = datetime[1].split(':');

				Ext.getCmp('MCT_timeManualDate').setValue(date);
				Ext.getCmp('MCT_timeManualHour').setValue(time[0]);
				Ext.getCmp('MCT_timeManualMinute').setValue(time[1]);
				Ext.getCmp('MCT_timeManualSecond').setValue(time[2]);

				clearInterval(_nowCurrentTimerVar);

				_nowCurrentTimerVar
					= setInterval(function() { nowCurrentTimer() }, 1000);
			}

			// NTP 시간 동기화 활성화 여부
			var NTP_Enabled = responseData.entity.NTP_Enabled == 'true' ? true : false;

			Ext.getCmp('MCT_timeSetSyncRadio').setValue(NTP_Enabled);

			// NTP 서버 주소 출력
			var NTP_Servers = responseData.entity.NTP_Servers.split(',');

			for (var i=0; i<NTP_Servers.length; i++)
			{
				if (i == 0)
				{
					// 기존의 작업에서 추가된 입력창 제거
					for (var j=1; j<=no; j++)
					{
						if (Ext.getCmp('timeSyncNtpServer'+i))
							Ext.getCmp('MCT_timeSyncNtpServerAddPanel').remove('ntpServer' + j);
					}

					cnt = no = 0;

					Ext.getCmp('timeSyncNtpServer'+i).setValue(NTP_Servers[i]);

					continue;
				}

				// NTP 서버 입력창 추가
				addNtpServer();
				Ext.getCmp('timeSyncNtpServer'+i).setValue(NTP_Servers[i]);
			}

			// 대륙 정보 적재
			MCT_load_continents();

			// 도시 정보 적재
			MCT_load_timezones();

			Ext.getCmp('MCT_timeZoneCombo').setValue(responseData.entity.Timezone, true);
		}
	});

	/*
	MCT_timeSetForm.getForm().load({
		url: '/api/cluster/system/time/info',
		method: 'POST',
		success: function(form, action) {
			// 마스크 제거
			timeLoadMask.hide();
			timeCurrentLoadMask.hide();

			// 현재 시간 정보 출력
			document.getElementById('MCT_timeCurrentTimeStamp').innerHTML = action.result.data.nowDate;
			nowCurrentTimer();

			// 현재 시간 주기적 호출
			if (action.result.data.nowDate)
			{
				clearInterval(_nowCurrentTimerVar);
				_nowCurrentTimerVar = setInterval(function() { nowCurrentTimer() },1000);
			}

			// NTP 서버 주소 출력
			var timeSyncNtpAddrArray = action.result.data.timeSyncNtpAddr.split(',');

			for (var i=0; i<timeSyncNtpAddrArray.length; i++)
			{
				if (i == 0)
				{
					// 기존의 작업에서 추가된 입력창 제거
					for (var j=1; j<=no; j++)
					{
						if (Ext.getCmp('timeSyncNtpServer'+i))
							Ext.getCmp('MCT_timeSyncNtpServerAddPanel').remove('ntpServer' + j);
					}

					cnt = no = 0;

					Ext.getCmp('timeSyncNtpServer'+i).setValue(timeSyncNtpAddrArray[i]);

					continue;
				}

				if (Ext.getCmp('MCT_timeSetSyncRadio').getValue() == true)
				{
					// NTP 서버 입력창 추가
					addNtpServer();
					Ext.getCmp('timeSyncNtpServer'+i).setValue(timeSyncNtpAddrArray[i]);
				}
			}

			// 표준시간대 대륙 정보
			MCT_timeContinentsStore.loadRawData(action.result.continents, false);

			// 표준시간대 현재 설정 정보
			MCT_timeZoneStore.loadRawData(action.result.zone, false);

			// 데이터 로드 성공 메세지
			//Ext.ux.DialogMsg.msg(lang_mct_time[0], lang_mct_time[1]);
		},
		failure: function(form, action) {
			// 마스크 제거
			timeLoadMask.hide();
			timeCurrentLoadMask.hide();

			// 실패 시 로컬 시간 출력
			var nowDate = new Date().getTime();
			document.getElementById('MCT_timeCurrentTimeStamp').innerHTML = nowDate;
			nowCurrentTimer();

			// 주기적 호출 제거
			clearInterval(_nowCurrentTimerVar);
			_nowCurrentTimerVar = setInterval(function(){nowCurrentTimer()},1000);

			// 실패 시 수동 시간 설정 선택
			Ext.getCmp('MCT_timeSetManualRadio').setValue(true);

			// 실패 시 수동 시간 출력
			var now = new Date();

			Ext.getCmp('MCT_timeManualHour').setValue(now.getHours());
			Ext.getCmp('MCT_timeManualMinute').setValue(now.getMinutes());
			Ext.getCmp('MCT_timeManualSecond').setValue(now.getSeconds());

			// 예외 처리에 따른 동작
			var jsonText = JSON.stringify(action.result);

			if (typeof(jsonText) == 'undefined')
				jsonText = '{}';

			var checkValue = `{
				"title": "${lang_mct_time[0]}",
				"content": "${lang_mct_time[2]}",
				"response": ${jsonText}
			}`;

			exceptionDataCheck(checkValue);
		}
	});
	*/
};

function MCT_load_continents()
{
	Ext.Ajax.request({
		url: '/api/cluster/system/time/continents',
		method: 'POST',
		callback: function(options, success, response) {
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
					+ '"title": "' + lang_mct_time[0] + '",'
					+ '"content": "' + lang_mct_time[2] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 표준시간대 대륙 정보
			var continents = responseData.entity.reduce(
				(acc, cur, i) => {
					acc.push({ Continent: cur });
					return acc;
				},
				[]
			);

			MCT_timeContinentsStore.loadRawData(continents, false);
		}
	});
}

/*
 * 표준시간대 정보 가져오기
 */
function MCT_load_timezones()
{
	Ext.Ajax.request({
		url: '/api/cluster/system/time/timezones',
		async: false,
		jsonData: {
			'Continent': Ext.getCmp('MCT_timeContinentsCombo').getValue()
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
				if (response.responseText == ''
						|| typeof(response.responseText) == 'undefined')
					response.responseText = '{}';

				if (typeof(responseData.msg) === 'undefined')
					responseData.msg = '';

				if (typeof(responseData.code) === 'undefined')
					responseData.code = '';

				var checkValue = '{'
					+ '"title": "' + lang_mct_time[0] + '",'
					+ '"content": "' + lang_mct_time[3] + '",'
					+ '"msg": "' + responseData.msg + '",'
					+ '"code": "' + responseData.code + '",'
					+ '"response": ' + response.responseText
				+ '}';

				return exceptionDataCheck(checkValue);
			}

			// 표준시간대 시간 정보
			MCT_timeZoneStore.loadRawData(responseData.entity, false);
		}
	});
};

/*
 * 현재 시간 주기적 호출 함수
 */
function stampToDate(timestamp)
{
	var now        = new Date(timestamp);
	var nowYear    = now.getFullYear();
	var nowMonth   = (now.getMonth()+1);
	var nowDate    = now.getDate();
	var nowHours   = now.getHours();
	var nowMinutes = now.getMinutes();
	var nowSeconds = now.getSeconds();

	if ((""+nowMonth).length == 1) nowMonth = "0" + nowMonth;
	if ((""+nowDate).length == 1) nowDate = "0" + nowDate;
	if ((""+nowHours).length == 1) nowHours = "0" + nowHours;
	if ((""+nowMinutes).length == 1) nowMinutes = "0" + nowMinutes;
	if ((""+nowSeconds).length == 1) nowSeconds = "0" + nowSeconds;

	if (isNaN(nowYear))
	{
		clearInterval(_nowCurrentTimerVar);
		return false;
	}

	return nowYear + "-" + nowMonth + "-" + nowDate + " "
			+ nowHours + ":" + nowMinutes + ":" + nowSeconds;
};

function nowCurrentTimer()
{
	if (!document.getElementById('MCT_timeCurrentTimeStamp').innerHTML)
		return;

	var stringDate = document.getElementById('MCT_timeCurrentTimeStamp').innerHTML;
	var timestamp  = parseInt(new Date(stringDate).getTime().toString().substring(0, 10)) * 1000;

	// 현재 시간
	var nowTime = stampToDate(timestamp);

	// 1초씩 증가
	var nowIncreaseTime = stampToDate(timestamp + 1000);

	if (nowIncreaseTime)
		document.getElementById('MCT_timeCurrentTimeStamp').innerHTML
			= nowIncreaseTime;

	if (nowTime)
		document.getElementById("MCT_timeCurrentTime").innerHTML
			= nowTime;

	return;
};

/*
 * 현재 시간 정보
 */
var MCT_timeCurrentPanel = Ext.create(
	'BasePanel',
	{
		id: 'MCT_timeCurrentPanel',
		title: lang_mct_time[4],
		frame: true,
		style: { marginBottom: '20px' },
		items: [
			{
				xtype: 'BasePanel',
				layout: 'hbox',
				bodyStyle: 'padding: 0 0 0 20px;',
				maskOnDisable: false,
				items: [
					{
						xtype: 'label',
						id: 'MCT_timeCurrentTime_label',
						text: lang_mct_time[5]+': ',
						width: 130
					},
					{
						xtype: 'label',
						id: 'MCT_timeCurrentTime'
					},
					{
						xtype: 'label',
						hidden: true,
						id: 'MCT_timeCurrentTimeStamp'
					}
				]
			}
		]
	}
);

/*
 * 시간 설정
 */

// 시간 모델
Ext.define(
	'MCT_timeManualHourModel',
	{
		extend: 'Ext.data.Model',
		fields: ['manualHourValue']
	}
);

// 시간 스토어
var MCT_timeManualHourStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeManualHourModel',
		data: [
			['00'], ['01'], ['02'], ['03'], ['04'], ['05'],
			['06'], ['07'], ['08'], ['09'], ['10'], ['11'],
			['12'], ['13'], ['14'], ['15'], ['16'], ['17'],
			['18'], ['19'], ['20'], ['21'], ['22'], ['23']
		]
	}
);

// 분 모델
Ext.define(
	'MCT_timeManualMinuteModel',
	{
		extend: 'Ext.data.Model',
		fields: ['manualMinuteValue']
	}
);

// 분 스토어
var MCT_timeManualMinuteStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeManualMinuteModel',
		data: [
			['00'], ['01'], ['02'], ['03'], ['04'], ['05'],
			['06'], ['07'], ['08'], ['09'], ['10'], ['11'],
			['12'], ['13'], ['14'], ['15'], ['16'], ['17'],
			['18'], ['19'], ['20'], ['21'], ['22'], ['23'],
			['24'], ['25'], ['26'], ['27'], ['28'], ['29'],
			['30'], ['31'], ['32'], ['33'], ['34'], ['35'],
			['36'], ['37'], ['38'], ['39'], ['40'], ['41'],
			['42'], ['43'], ['44'], ['45'], ['46'], ['47'],
			['48'], ['49'], ['50'], ['51'], ['52'], ['53'],
			['54'], ['55'], ['56'], ['57'], ['58'], ['59']
		]
	}
);

// 초 모델
Ext.define('MCT_timeManualSecondModel',{
	extend: 'Ext.data.Model',
	fields: ['manualSecondValue']
});

// 초 스토어
var MCT_timeManualSecondStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeManualSecondModel',
		data: [
			['00'], ['01'], ['02'], ['03'], ['04'], ['05'],
			['06'], ['07'], ['08'], ['09'], ['10'], ['11'],
			['12'], ['13'], ['14'], ['15'], ['16'], ['17'],
			['18'], ['19'], ['20'], ['21'], ['22'], ['23'],
			['24'], ['25'], ['26'], ['27'], ['28'], ['29'],
			['30'], ['31'], ['32'], ['33'], ['34'], ['35'],
			['36'], ['37'], ['38'], ['39'], ['40'], ['41'],
			['42'], ['43'], ['44'], ['45'], ['46'], ['47'],
			['48'], ['49'], ['50'], ['51'], ['52'], ['53'],
			['54'], ['55'], ['56'], ['57'], ['58'], ['59']
		]
	}
);

// NTP 서버 주기 모델
Ext.define('MCT_timeSyncNtpCycleModel',{
	extend: 'Ext.data.Model',
	fields: ['cycleName', 'cycleValue']
});

// NTP 서버 주기 스토어
var MCT_timeSyncNtpCycleStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeSyncNtpCycleModel',
		data: [
			[lang_mct_time[28], "0"],
			[lang_mct_time[29], "1"],
			[lang_mct_time[30], "2"],
			[lang_mct_time[31], "3"]
		]
	}
);

// 표준시간대 대륙 모델
Ext.define(
	'MCT_timeContinentsModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Continent']
	}
);

// 표준시간대 대륙 스토어
var MCT_timeContinentsStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeContinentsModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		}
	}
);

// 표준시간대 모델
Ext.define(
	'MCT_timeZoneModel',
	{
		extend: 'Ext.data.Model',
		fields: ['Offset', 'Timezone']
	}
);

// 표준시간대 설정 스토어
var MCT_timeZoneStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeZoneModel',
		proxy: {
			type: 'memory',
			reader: {
				type: 'json',
			}
		}
	}
);

// 동기화 시간 모델
Ext.define(
	'MCT_timeSyncTimeModel',
	{
		extend: 'Ext.data.Model',
		fields: ['syncTimeView', 'syncTimeCode']
	}
);

// 동기화 시간 스토어
var MCT_timeSyncTimeStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeSyncTimeModel',
		data: [
			[lang_mct_time[33], ''],
			[lang_mct_time[13], '*'],
			['00',  '00'], ['01',  '01'], ['02',  '02'],
			['03',  '03'], ['04',  '04'], ['05',  '05'],
			['06',  '06'], ['07',  '07'], ['08',  '08'],
			['09',  '09'], ['10',  '10'], ['11',  '11'],
			['12',  '12'], ['13',  '13'], ['14',  '14'],
			['15',  '15'], ['16',  '16'], ['17',  '17'],
			['18',  '18'], ['19',  '19'], ['20',  '20'],
			['21',  '21'], ['22',  '22'], ['23',  '23']
		]
	}
);

// 동기화 분 모델
Ext.define('MCT_timeSyncMinuteModel', {
	extend: 'Ext.data.Model',
	fields: ['syncMinuteView', 'syncMinuteCode']
});

// 동기화 분 스토어
var MCT_timeSyncMinuteStore = Ext.create(
	'Ext.data.Store',
	{
		model: 'MCT_timeSyncMinuteModel',
		data:[
			/*[lang_mct_time[33], ''], */
			[lang_mct_time[32], '*'],
			['00', '00'], ['01', '01'], ['02', '02'],
			['03', '03'], ['04', '04'], ['05', '05'],
			['06', '06'], ['07', '07'], ['08', '08'],
			['09', '09'], ['10', '10'], ['11', '11'],
			['12', '12'], ['13', '13'], ['14', '14'],
			['15', '15'], ['16', '16'], ['17', '17'],
			['18', '18'], ['19', '19'], ['20', '20'],
			['21', '21'], ['22', '22'], ['23', '23'],
			['24', '24'], ['25', '25'], ['26', '26'],
			['27', '27'], ['28', '28'], ['29', '29'],
			['30', '30'], ['31', '31'], ['32', '32'],
			['33', '33'], ['34', '34'], ['35', '35'],
			['36', '36'], ['37', '37'], ['38', '38'],
			['39', '39'], ['40', '40'], ['41', '41'],
			['42', '42'], ['43', '43'], ['44', '44'],
			['45', '45'], ['46', '46'], ['47', '47'],
			['48', '48'], ['49', '49'], ['50', '50'],
			['51', '51'], ['52', '52'], ['53', '53'],
			['54', '54'], ['55', '55'], ['56', '56'],
			['57', '57'], ['58', '58'], ['59', '59']
		]
	}
);

var MCT_timeSetForm = Ext.create(
	'BaseFormPanel',
	{
		id: 'MCT_timeSetForm',
		title: lang_mct_time[0],
		items: [
			{
				xtype: 'fieldset',
				id: 'MCT_timeZone',
				title: lang_mct_time[14],
				items: [
					{
						layout: 'panel',
						layout: 'hbox',
						border: false,
						bodyStyle: 'padding: 0; background: none;',
						style: { marginBottom: '20px' },
						items: [
							{
								xtype: 'BaseComboBox',
								fieldLabel: lang_mct_time[15],
								id: 'MCT_timeContinentsCombo',
								name: 'timeContinentsCombo',
								style: { marginTop: '20px',marginRight: '20px' },
								width: 300,
								store: MCT_timeContinentsStore,
								value: 'Asia',
								valueField: 'Continent',
								displayField: 'Continent',
								listeners: {
									change: function(field, newValue, oldValue) {
										MCT_load_timezones();
									}
								}
							},
							{
								xtype: 'BaseComboBox',
								id: 'MCT_timeZoneCombo',
								name: 'timeZoneCombo',
								hideLabel: true,
								style: { marginTop: '20px' },
								width: 350,
								store: MCT_timeZoneStore,
								valueField: 'Timezone',
								displayField: 'Offset'
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCT_timeManual',
				bodyStyle: 'padding: 0',
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'radiofield',
						checked: false,
						id: 'MCT_timeSetManualRadio',
						name: 'timeSetRadio',
						inputValue: 'timeManual',
						boxLabel: lang_mct_time[16],
						listeners: {
							change: function() {
								var flag = this.getValue();

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeManualDatePanel').query('.field, .button, .label'),
									function(c) { c.setDisabled(!flag); }
								);

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeSyncDatePanel').query('.field, .button, .label'),
									function(c) { c.setDisabled(flag); }
								);

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeSyncNtpServerAddPanel').query('.field, .button'),
									function(c) { c.setDisabled(flag); }
								);

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeSyncNtpServerPanel').query('.field, .label'),
									function(c) { c.setDisabled(flag); }
								);
							}
						}
					},
					{
						xtype: 'BasePanel',
						id: 'MCT_timeManualDatePanel',
						bodyStyle: 'padding: 0;',
						items: [
							{
								xtype: 'BasePanel',
								layout: 'hbox',
								maskOnDisable: false,
								bodyStyle: 'padding-left: 20px;',
								style: { marginBottom: '20px', marginTop: '20px' },
								items: [
									{
										xtype: 'label',
										id: 'MCT_timeManualDateLabel',
										text: lang_mct_time[17]+': ',
										width: 130,
										disabledCls: 'm-label-disable-mask'
									},
									{
										xtype: 'datefield',
										id: 'MCT_timeManualDate',
										name: 'timeManualDate',
										hideLabel: true,
										format: 'Y/m/d',
										altFormats: 'Y-m-d',
										editable:false,
										value: new Date()
									}
								]
							},
							{
								xtype: 'BasePanel',
								layout: 'hbox',
								maskOnDisable: false,
								bodyStyle: 'padding-left: 20px;',
								style: { marginBottom: '20px' },
								items: [
									{
										xtype: 'label',
										id: 'MCT_timeManualTimeLabel',
										text: lang_mct_time[18]+': ',
										width: 130,
										disabledCls: 'm-label-disable-mask'
									},
									{
										xtype: 'BaseComboBox',
										id: 'MCT_timeManualHour',
										name: 'timeManualHour',
										store: MCT_timeManualHourStore,
										hideLabel: true,
										value: '00',
										valueField: 'manualHourValue',
										displayField: 'manualHourValue',
										style: { marginRight: '10px' }
									},
									{
										xtype: 'BaseComboBox',
										store: MCT_timeManualMinuteStore,
										id: 'MCT_timeManualMinute',
										name: 'timeManualMinute',
										hideLabel: true,
										value: '00',
										valueField: 'manualMinuteValue',
										displayField: 'manualMinuteValue',
										style: { marginRight: '10px' }
									},
									{
										xtype: 'BaseComboBox',
										store: MCT_timeManualSecondStore,
										id: 'MCT_timeManualSecond',
										name: 'timeManualSecond',
										hideLabel: true,
										value: '00',
										valueField: 'manualSecondValue',
										displayField: 'manualSecondValue'
									}
								]
							}
						]
					}
				]
			},
			{
				xtype: 'BasePanel',
				id: 'MCT_timeSync',
				border: false,
				bodyStyle: 'padding: 0',
				items: [
					{
						xtype: 'radiofield',
						id: 'MCT_timeSetSyncRadio',
						name: 'timeSetRadio',
						inputValue: 'timeSync',
						boxLabel: lang_mct_time[19],
						labelWidth: 300,
						listeners: {
							change: function() {
								var flag = this.getValue();

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeSyncDatePanel').query('.field, .button, .label'),
									function(c) { c.setDisabled(!flag); }
								);

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeSyncNtpServerPanel').query('.field, .button'),
									function(c) { c.setDisabled(!flag); }
								);

								Ext.Array.forEach(
									Ext.getCmp('MCT_timeManualDatePanel').query('.field, .button, .label'),
									function(c) { c.setDisabled(flag); }
								);
							}
						}
					},
					{
						xtype: 'BasePanel',
						layout: 'hbox',
						maskOnDisable: false,
						bodyStyle: 'padding: 0px;',
						style: { marginBottom: '10px', marginLeft: '260px' },
						id: 'MCT_timeSyncDatePanel',
						items: [
							{
								xtype: 'button',
								text: lang_mct_time[20],
								width: 90,
								iconCls: 'b-icon-add',
								handler: function() { addNtpServer(); }
							}
						]
					},
					{
						xtype: 'BasePanel',
						layout: 'hbox',
						bodyStyle: 'padding-left: 20px;',
						style: { marginBottom: '5px' },
						id: 'MCT_timeSyncNtpServerPanel',
						items: [
							{
								xtype: 'label',
								text: lang_mct_time[20]+': ',
								width: 130,
								disabledCls: 'm-label-disable-mask'
							},
							{
								xtype: 'textfield',
								id: 'timeSyncNtpServer0',
								style: { marginBottom: '5px' },
								width: 200,
								allowBlank: false
							}
						]
					},
					{
						xtype: 'BasePanel',
						id: 'MCT_timeSyncNtpServerAddPanel',
						bodyStyle: 'padding-left: 135px;'
					}
				]
			}
		],
		buttonAlign: 'left',
		buttons: [
			{
				text: lang_mct_time[23],
				id: 'MCT_timeFormBtn',
				handler: function() {
					if (!MCT_timeSetForm.getForm().isValid())
						return false;

					waitWindow(lang_mct_time[0], lang_mct_time[24]);

					// NTP 서버 문자열 병합
					var ntp_servers = [];

					for (var i=0; i<=no; i++)
					{
						if (Ext.getCmp('timeSyncNtpServer' + i))
						{
							ntp_servers.push(Ext.getCmp('timeSyncNtpServer'+i).getValue());

							Ext.getCmp('MCT_timeSyncNtpServerAddPanel').remove('ntpServer' + i);
						}
					}

					var continents = Ext.getCmp('MCT_timeContinentsCombo').getValue();
					var timezone   = Ext.getCmp('MCT_timeZoneCombo').getValue();

					var datetime = (new Date(Ext.getCmp('MCT_timeManualDate').getValue() 
						         - (new Date()).getTimezoneOffset() * 60000)).toISOString().substring(0, 10);
						datetime = datetime + ' ' + Ext.getCmp('MCT_timeManualHour').getValue();
						datetime = datetime + ':' + Ext.getCmp('MCT_timeManualMinute').getValue();
						datetime = datetime + ':' + Ext.getCmp('MCT_timeManualSecond').getValue();

					GMS.Ajax.request({
						url: '/api/cluster/system/time/config',
						jsonData: {
							Continent: continents,
							Timezone: timezone,
							NTP_Enabled: Ext.getCmp('MCT_timeSetSyncRadio').getValue() ? 'true' : 'false',
							NTP_Servers: ntp_servers,
							Datetime: datetime,
						},
						callback: function (options, success, response, decoded) {
							// 예외 처리에 따른 동작
							if (!success || !decoded.success)
							{
								return;
							}

							Ext.MessageBox.alert(
								lang_mct_time[0],
								lang_mct_time[25],
								function (buttonId, value, opt) {
									MCT_timeLoad();
								}
							);
						},
					});
				}
			}
		]
	}
);

// 시간 설정
Ext.define(
	'/admin/js/manager_cluster_time',
	{
		extend: 'BasePanel',
		id: 'manager_cluster_time',
		load: function() {
			// if(waitMsgBox)
			// {
			// 	waitMsgBox.hide();
			// 	waitMsgBox = null;
			// }
			// waitWindow(lang_mct_time[0], lang_mct_time[27]);
			MCT_timeLoad();
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
						bodyStyle: 'padding: 0;',
						items: [MCT_timeCurrentPanel]
					},
					{
						xtype: 'BasePanel',
						layout: 'fit',
						flex: 6,
						bodyStyle: 'padding: 0;',
						items: [MCT_timeSetForm]
					}
				]
			}
		]
	}
);
