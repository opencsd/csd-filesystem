/** 초기 실행 함수 **/
function MCC_compositionLoad()
{
	Ext.getCmp('MCC_compositionTab').setActiveTab(0);
	//초기화
	Ext.getCmp('MCC_compositionRecoveryFile').setValue();

	//로그 백업 데이터 확인
	Ext.Ajax.request({
		url: '/index.php/admin/manager_cluster_composition/compositionLogFind',
		success: function(response) {
			if(waitMsgBox)
			{
				//데이터 전송완료후: wait제거
				waitMsgBox.hide();
				waitMsgBox = null;
			}

			var responseData = exceptionDataDecode(response.responseText);
			if(responseData.success == true)
			{
				Ext.getCmp('MCC_compositionBackupLogFile').show();
				//status file size
				if(responseData.status == 'ok')
				{
					if(responseData.size > 1024)
					{
						var logSize = responseData.size / 1024;
						var logSizeType = "KB";
					}
					else if(responseData.size > 1048576)
					{
						var logSize = responseData.size / 1024 / 1024;
						var logSizeType = "MB";
					}
					else if(responseData.size > 1073741824)
					{
						var logSize = responseData.size / 1024 / 1024 / 1024;
						var logSizeType = "GB";
					}
					else if(responseData.size > 1099511627776)
					{
						var logSize = responseData.size / 1024 / 1024 / 1024 / 1024;
						var logSizeType = "TB";
					}
					else if(responseData.size > 1125899906842624)
					{
						var logSize = responseData.size / 1024 / 1024 / 1024 / 1024 / 1024;
						var logSizeType = "PB";
					}
					var logLink = '<a href="#">'+responseData.file+' ('+logSize.toFixed(2)+' '+logSizeType+')</a>';
					Ext.getCmp('MCC_compositionBackupLogFile').show();
					Ext.getCmp('MCC_compositionBackupLogFile').update(logLink);
					Ext.getCmp('MCC_compositionBackupLogFileName').update(responseData.file);
				}
				else if(responseData.status == 'noexist')
				{
					Ext.getCmp('MCC_compositionBackupLogFile').hide();
					Ext.getCmp('MCC_compositionBackupLogFile').update('');
				}
				else if(responseData.status == 'making')
				{
					Ext.getCmp('MCC_compositionBackupLogFile').show();
					Ext.getCmp('MCC_compositionBackupLogFile').update(lang_mcc_composition[28]);
				}
			}
			else
			{
				//예외처리에 따른 동작
				if(response.responseText == '' || typeof response.responseText == 'undefined') response.responseText = '{}';
				var checkValue = '{"title": "'+lang_mcc_composition[0]+'", "content": "'+lang_mcc_composition[27]+'", "response": '+response.responseText+'}';
				exceptionDataCheck(checkValue);
			}
		}
		,failure: function(response){
			if(waitMsgBox)
			{
				//데이터 전송완료후: wait제거
				waitMsgBox.hide();
				waitMsgBox = null;
			}
			//예외처리에 따른 동작
			var checkValue = '{"title": "'+lang_mcc_composition[0]+'", "content": "'+lang_mcc_composition[27]+'"}';
			exceptionDataCheck(checkValue);
		}
	});
};

/* 
 * 구성 백업 텝
 */
// 설정 백업 판넬
var MCC_compositionBackupConfigPanel = Ext.create('BaseFormPanel', {
	id: 'MCC_compositionBackupConfigPanel',
	title: lang_mcc_composition[1],
	frame: true,
	items: [
		{
			xtype: 'panel',
			border: false,
			style: { marginTop: '10px',marginBottom: '20px' },
			html: lang_mcc_composition[2]
		},
		{
			xtype: 'button',
			text: lang_mcc_composition[1],
			id: 'MCC_compositionBackupConfigBtn',
			handler: function() {
				if (!Ext.getCmp('MCC_compositionBackupConfigPanel').getForm().isValid())
					return false;

				waitWindow(lang_mcc_composition[0], lang_mcc_composition[3]);

				Ext.getCmp('MCC_compositionBackupConfigPanel').getForm().submit({
					method: 'POST',
					url: '/index.php/admin/manager_cluster_composition/compositionConfigCreate',
					success: function(form, action) {
						if(waitMsgBox)
						{
							//데이터 전송완료후: wait제거
							waitMsgBox.hide();
							waitMsgBox = null;
						}
						Ext.getCmp('FileDownloader').load({
							url: '/index.php/admin/manager_cluster_composition/compositionConfigDownload'
							,params: {
								"backupDataFile": action.result.backupData
							}
						});
					},
					failure: function(form, action) {
						// 데이터 전송 완료 후: wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var jsonText = JSON.stringify(action.result);

						if (typeof jsonText == 'undefined')
							jsonText = '{}';

						var checkValue = '{'
							+ '"title": "' + lang_mcc_composition[0] + '",'
							+ '"content": "' + lang_mcc_composition[4] + '", '
							+ '"response": ' + jsonText
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}
	]
});

// 로그 백업 판넬
var MCC_compositionBackupLogPanel = Ext.create('BasePanel', {
	id: 'MCC_compositionBackupLogPanel',
	title: lang_mcc_composition[5],
	frame: true,
	items: [
		{
			xtype: 'panel',
			border: false,
			style: { marginTop: '10px' },
			html: lang_mcc_composition[6]
		},
		{
			xtype: 'button',
			minWidth: 70,
			style: { marginTop: '20px' },
			text: lang_mcc_composition[5],
			width: 100,
			height: 23,
			handler: function() {
				waitWindow(lang_mcc_composition[0], lang_mcc_composition[7]);

				Ext.Ajax.request({
					url: '/index.php/admin/manager_cluster_composition/compositionLogCreate',
					success: function(response) {
						// 데이터 전송 완료 후: wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						var responseData = exceptionDataDecode(response.responseText);

						// 로그 백업 확인
						if (responseData.success == true)
						{
							MSC_compositionLoad();
						}
						// 예외 처리에 따른 동작
						else
						{
							if (response.responseText == ''
									|| typeof response.responseText == 'undefined')
								response.responseText = '{}';

							var checkValue = '{'
								+ '"title": "' + lang_mcc_composition[0] + '",'
								+ '"content": "' + lang_mcc_composition[8] + '", '
								+ '"response": ' + response.responseText
							+ '}';

							exceptionDataCheck(checkValue);
						}
					},
					failure: function(response) {
						// 데이터 전송 완료 후: wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var checkValue = '{'
							+ '"title": "' + lang_mcc_composition[0] + '",'
							+ '"content": "' + lang_mcc_composition[8] + '"'
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		},
		{
			xtype: 'label',
			text: ' ',
			width: 60
		},
		{
			xtype: 'label',
			id: 'MCC_compositionBackupLogFile',
			width: 300,
			style: { marginTop: '20px' },
			hidden: true,
			listeners: {
				render: function(label) {
					label.getEl().on({
						click: function(el) {
							Ext.getCmp('FileDownloader').load({
								url: '/index.php/admin/manager_cluster_composition/compositionLogDownload',
								params: {
									"backupDataFile": document.getElementById('MCC_compositionBackupLogFileName').innerHTML
								}
							});
						},
						scope: label
					});
				}
			}
		},
		{
			xtype: 'label',
			id: 'MCC_compositionBackupLogFileName',
			hidden: true
		}
	]
});

// 구성 백업 판넬
var MCC_compositionBackup = Ext.create('BasePanel', {
	id: 'MCC_compositionBackup',
	defaults: { style: { marginBottom: '20px' } },
	items: [ MCC_compositionBackupConfigPanel, MCC_compositionBackupLogPanel ]
});

/*
 * 구성 복원 텝
 */
// 설정 복원 판넬
var MCC_compositionRecoveryConfigPanel = Ext.create('BaseFormPanel', {
	id: 'MCC_compositionRecoveryConfigPanel',
	title: lang_mcc_composition[9],
	frame: true,
	items: [
		{
			xtype: 'BasePanel',
			id: 'MCC_compositionRecoveryConfigDesc',
			border: false,
			style: { marginBottom: '20px' },
			html: lang_mcc_composition[10] + '<br>'
				+ lang_mcc_composition[26] + '<br>'
				+ lang_mcc_composition[11]
		},
		{
			xtype: 'container',
			id: 'MCC_compositionRecoveryConfigFileContainer',
			layout: 'column',
			border: false,
			items: [
				{
					xtype: 'filefield',
					id: 'MCC_compositionRecoveryConfigFile',
					name: 'compositionRecoveryConfigFile',
					labelWidth: 170,
					emptyText: lang_mcc_composition[12],
					fieldLabel: lang_mcc_composition[13],
					anchor: '50%',
					buttonText: lang_mcc_composition[14],
					allowBlank: false,
					vtype: 'reg_compositionRecoveryFile',
					style: { marginLeft: '20px' },
					buttonConfig: { iconCls: 'b-icon-add' }
				},
				{
					xtype: 'textfield',
					id: 'MCC_compositionRecoveryFile',
					hidden: true
				},
				{
					xtype: 'button',
					minWidth: 100,
					style: { marginLeft: '20px', marginBottom: '20px' },
					text: lang_mcc_composition[15],
					width: 100,
					height: 23,
					iconCls: 'b-icon-upload',
					handler: function() {
						// 복구 파일명 초기화
						Ext.getCmp('MCC_compositionRecoveryFile').setValue();

						// 복원 가능 리스트 출력
						var recoveryChkboxes = new Array();

						Ext.getCmp('MCC_compositionRecoveryConfigFieldset').remove('MCC_compositionRecoveryFieldTotalChk',true);
						Ext.getCmp('MCC_compositionRecoveryConfigFieldset').remove('MCC_compositionRecoveryFieldItems',true);
						Ext.getCmp('MCC_compositionRecoveryConfigFieldset').hide();

						if (!Ext.getCmp('MCC_compositionRecoveryConfigPanel').getForm().isValid())
							return false;

						waitWindow(lang_mcc_composition[0], lang_mcc_composition[16]);

						Ext.getCmp('MCC_compositionRecoveryConfigPanel').getForm().submit({
							method: 'POST',
							url: '/index.php/admin/manager_cluster_composition/compositionAddFileUpload',
							success: function(form, action) {
								// 데이터 전송 완료 후: wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								// 메세지 출력
								var returnMsg = lang_mcc_composition[17];
								var responseMsg = action.result.msg;

								if (responseMsg)
								{
									returnMsg = responseMsg;
								}

								Ext.MessageBox.alert(lang_mcc_composition[0], returnMsg);

								// 설정 복원 버튼 enable
								Ext.getCmp('MCC_compositionRecoveryConfigBtn').setDisabled(false);

								var responseData = action.result;

								// 업로드 복구 파일명
								Ext.getCmp('MCC_compositionRecoveryFile').setValue(responseData.configInfo.filename);

								// 복원 가능 목록 출력
								var chkLength = responseData.configInfo.config.length;

								for (i = 0; i < chkLength; i++)
								{
									recoveryChkboxes.push(
										{
											boxLabel: responseData.configInfo.config[i],
											name: 'recoveryChk',
											inputValue: responseData.configInfo.config[i],
											checked: true,
											cls: 'm-custom-check-group'
										}
									);
								}

								// 설정 정보 복원 전체 선택 checkbox
								Ext.getCmp('MCC_compositionRecoveryConfigFieldset').add({
									xtype: 'checkbox',
									boxLabel: lang_mcc_composition[18],
									id: 'MCC_compositionRecoveryFieldTotalChk',
									name: 'compositionRecoveryFieldTotalChk',
									checked: true,
									inputValue: 'all',
									style: { marginLeft: '10px', marginTop: '20px' },
									listeners: {
										change: function (cb, nv, ov) {
											if (nv == true)
											{
												var checkboxes = Ext.getCmp('MCC_compositionRecoveryFieldItems').query('[isCheckbox]');

												Ext.Array.each(checkboxes, function (checkbox) {
													checkbox.setValue(true);
												});

												// 설정 복원 버튼 enable
												Ext.getCmp('MCC_compositionRecoveryConfigBtn').setDisabled(false);
											}
											else
											{
												var checkboxes = Ext.getCmp('MCC_compositionRecoveryFieldItems').query('[isCheckbox]');

												Ext.Array.each(checkboxes, function (checkbox) {
													checkbox.setValue(false);
												});

												// 설정 복원 버튼 disable
												Ext.getCmp('MCC_compositionRecoveryConfigBtn').setDisabled(true);
											}
										}
									}
								});

								// 설정 정보 복원 선택 checkbox
								Ext.getCmp('MCC_compositionRecoveryConfigFieldset').add({
									xtype: 'checkboxgroup',
									id: 'MCC_compositionRecoveryFieldItems',
									columns: 3,
									allowBlank: false,
									msgTarget: 'under',
									style: { marginLeft: '20px', marginBottom: '20px' },
									items: recoveryChkboxes,
									listeners: {
										change: function(field, newValue, oldValue, eOpts){
											var recoveryChkObj = newValue.recoveryChk;

											if (typeof recoveryChkObj != 'undefined')
											{
												// 설정 복원 버튼 enable
												Ext.getCmp('MCC_compositionRecoveryConfigBtn').setDisabled(false);

												if (chkLength == recoveryChkObj.length)
												{
													Ext.getCmp('MCC_compositionRecoveryFieldTotalChk').setValue(true);
												}
												else
												{
													if (Ext.getCmp('MCC_compositionRecoveryFieldTotalChk').getValue() == true)
													{
														Ext.getCmp('MCC_compositionRecoveryFieldTotalChk').suspendEvents(false);
														Ext.getCmp('MCC_compositionRecoveryFieldTotalChk').setValue(false);
														Ext.getCmp('MCC_compositionRecoveryFieldTotalChk').resumeEvents();
													}
												}
											}
											else
											{
												Ext.getCmp('MCC_compositionRecoveryFieldTotalChk').setValue(false);

												// 설정 복원 버튼 disable
												Ext.getCmp('MCC_compositionRecoveryConfigBtn').setDisabled(true);
											}
										}
									}
								});

								Ext.getCmp('MCC_compositionRecoveryConfigFieldset').show();
							},
							failure: function(form, action) {
								// 데이터 전송 완료 후: wait 제거
								if (waitMsgBox)
								{
									waitMsgBox.hide();
									waitMsgBox = null;
								}

								// 예외 처리에 따른 동작
								var jsonText = JSON.stringify(action.result);

								if (typeof jsonText == 'undefined')
									jsonText = '{}';

								var checkValue = '{'
									+ '"title": "' + lang_mcc_composition[0] + '",'
									+ '"content": "' + lang_mcc_composition[19] + '",'
									+ '"response": ' + jsonText
								+ '}';

								exceptionDataCheck(checkValue);
							}
						});
					}
				}
			]
		},
		{
			xtype: 'fieldset',
			id: 'MCC_compositionRecoveryConfigFieldset',
			title: lang_mcc_composition[20],
			hidden: true,
			style: { marginBottom: '20px' }
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcc_composition[9],
			id: 'MCC_compositionRecoveryConfigBtn',
			disabled: true,
			handler: function() {
				var recoveryFieldData = [];

				Ext.each(
					Ext.getCmp('MCC_compositionRecoveryFieldItems').items.items,
					function(item) {
						if (item.checked == true)
						{
							recoveryFieldData.push('"'+item.inputValue+'"');
						}
					}
				);

				var recoveryJsonData = new Array(recoveryFieldData);
				var recoveryJsonData = "["+recoveryJsonData+"]";

				waitWindow(lang_mcc_composition[0], lang_mcc_composition[21]);

				Ext.Ajax.request({
					url: '/index.php/admin/manager_cluster_composition/compositionConfigRecovery',
					params: {
						"recoveryData": recoveryJsonData,
						"recoveryFile": Ext.getCmp('MCC_compositionRecoveryFile').getValue()
					},
					success: function(response) {
						// 데이터 전송 완료 후: wait 제거
						if(waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						var responseData = exceptionDataDecode(response.responseText);

						if (responseData.success == true)
						{
							Ext.MessageBox.alert(lang_mcc_composition[0], lang_mcc_composition[22]);
						}
						// 예외 처리에 따른 동작
						else
						{
							if (response.responseText == '' || typeof response.responseText == 'undefined')
								response.responseText = '{}';

							var checkValue = '{'
								+ '"title": "' + lang_mcc_composition[0] + '",'
								+ '"content": "' + lang_mcc_composition[23] + '",'
								+ '"response": ' + response.responseText
							+ '}';

							exceptionDataCheck(checkValue);
						}
					},
					failure: function(response) {
						// 데이터 전송 완료 후: wait 제거
						if (waitMsgBox)
						{
							waitMsgBox.hide();
							waitMsgBox = null;
						}

						// 예외 처리에 따른 동작
						var checkValue = '{'
							+ '"title": "' + lang_mcc_composition[0] + '",'
							+ '"content": "' + lang_mcc_composition[23] + '"'
						+ '}';

						exceptionDataCheck(checkValue);
					}
				});
			}
		}]
});

// 구성 백업 판넬
var MCC_compositionRecovery = Ext.create('BasePanel', {
	id: 'MCC_compositionRecovery',
	defaults: { style: { marginBottom: '20px' } },
	items: [MCC_compositionRecoveryConfigPanel]
});

// 구성 백업/복구
Ext.define('/admin/js/manager_cluster_composition', {
	extend: 'BasePanel',
	id: 'manager_cluster_composition',
	load: function() {
		if(waitMsgBox)
		{
			waitMsgBox.hide();
			waitMsgBox = null;
		}
		Ext.getCmp('MCC_compositionTab').setActiveTab(0);
		//초기화
		Ext.getCmp('MCC_compositionRecoveryFile').setValue();
	},
	bodyStyle: 'padding:0;',
	items: [
		{
			xtype: 'tabpanel',
			id: 'MCC_compositionTab',
			activeTab: 0,
			frame: false,
			defaults: {
				overflowX: 'hidden',
				overflowY:'auto',
				bodyCls: 'm-panelbody',
				bodyStyle: 'padding:0px;',
				border: false
			},
			items: [
				{
					xtype: 'BasePanel',
					title: lang_mcc_composition[24],
					layout: 'fit',
					bodyStyle: 'padding:0px;',
					items: [MCC_compositionBackup]
				},
				{
					xtype: 'BasePanel',
					title: lang_mcc_composition[25],
					layout: 'fit',
					bodyStyle: 'padding:0px;',
					items: [MCC_compositionRecovery]
				}
			]
		}
	]
});
