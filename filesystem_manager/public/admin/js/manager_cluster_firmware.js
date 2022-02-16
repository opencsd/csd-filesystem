/**
페이지로드시 실행함수
**/
	function MSP_firmwareLoad()
	{

	};


/**
버전 업그레이드 파일 업로드
**/
	var MSP_firmwareFileuploadForm = Ext.create('BaseFormPanel', {
		id: 'MSP_firmwareFileuploadForm'
		,title: lang_mcf_firmware[8]
		,height: 230
		,items: [{
			xtype: 'BasePanel'
			,id: 'MSP_firmwareDesc'
			,border: false
			,style: {marginBottom: '30px'}
			,html: lang_mcf_firmware[9]+'<br>'+lang_mcf_firmware[10]
		},{
			xtype: 'filefield'
			,id: 'MSP_firmwareAddFile'
			,name: 'firmwareAddFile'
			,emptyText: lang_mcf_firmware[11]
			,fieldLabel: lang_mcf_firmware[12]
			//,vtype: 'reg_firmwareAddFile'
			,anchor: '50%'
			,buttonText: lang_mcf_firmware[11]
			,buttonConfig: {
				iconCls: 'b-icon-upload'
			}
		}]
		,buttonAlign: 'left'
		,buttons: [{
			text: lang_mcf_firmware[13]
			,handler: function(){
				if(!Ext.getCmp('MSP_firmwareFileuploadForm').getForm().isValid()) return false;
				waitWindow(lang_mcf_firmware[0], lang_mcf_firmware[16]);

				Ext.getCmp('MSP_firmwareFileuploadForm').getForm().submit({
					method: 'POST'
					,url: '/index.php/admin/manager_cluster_firmware/firmware_upload'
					,success: function(form, action) {
						if(waitMsgBox)
						{
							//데이터 전송완료후: wait제거
							waitMsgBox.hide();
							waitMsgBox = null;
						}
						//메세지 출력
						var returnMsg = lang_mcf_firmware[14];
						 var responseMsg = action.result.msg;
						if(responseMsg)
						{
							returnMsg = responseMsg;
						}
						Ext.MessageBox.alert(lang_mcf_firmware[0], returnMsg);
						//이후 업그레이드 실행
						locationMain();
					}
					,failure: function(form, action) {
						if(waitMsgBox)
						{
							//데이터 전송완료후: wait제거
							waitMsgBox.hide();
							waitMsgBox = null;
						}
						//예외처리에 따른 동작
						var jsonText = JSON.stringify(action.result);
						if(typeof jsonText == 'undefined') jsonText = '{}';
						var checkValue = '{"title": "'+lang_mcf_firmware[0]+'", "content": "'+lang_mcf_firmware[15]+'", "response": '+jsonText+'}';
						exceptionDataCheck(checkValue);
					}
				});
			}
		}]
	});

//버전 관리
Ext.define('/admin/js/manager_cluster_firmware', {
	extend: 'BasePanel'
	,id: 'manager_cluster_firmware'
	,load: function() {
		if(waitMsgBox)
		{
			waitMsgBox.hide();
			waitMsgBox = null;
		}
		MSP_firmwareLoad();
	}
	,bodyStyle: 'padding: 0;'
	,items: [{
		xtype: 'BasePanel'
		,layout: {
			type: 'vbox'
			,align : 'stretch'
		}
		,bodyStyle: 'padding: 0;'
		,items: [{
			xtype: 'BasePanel'
			,layout: 'fit'
			,bodyStyle: 'padding-left:15px; padding-top:15px; padding-right:15px; padding-bottom:35px;'
			,items: [MSP_firmwareFileuploadForm]
		}]
	}]
});
