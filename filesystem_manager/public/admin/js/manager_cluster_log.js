function MCL_logExist()
{
	return;
}

var MCL_logPanel = Ext.create('BaseFormPanel', {
	id: 'MCL_logPanel',
	title: lang_mcl_log[0],
	frame: true,
	items: [
		{
			xtype: 'BasePanel',
			bodyStyle: 'padding: 0',
			html: lang_mcl_log[1]+'<br><br>'+lang_mcl_log[3]
		},
		{
			xtype: 'BasePanel',
			id: 'MCL_logCheckPanel',
			bodyStyle: 'padding: 0',
			hidden: true,
			html: '<br><br><img src="/admin/images/loading.gif"> '+lang_mcl_log[4]
		},
		{
			xtype: 'FileDownloader',
			id: 'MCL_logSystemFileDownloader'
		}
	],
	buttonAlign: 'left',
	buttons: [
		{
			text: lang_mcl_log[0],
			id: 'MCL_logSystemButton',
			disabled: true,
			handler: function() {
				Ext.getCmp('MCL_logSystemButton').disable();

				/** 주기적 갱신 **/
				clearInterval(_nowCurrentLogExistVar);
				_nowCurrentLogExistVar = setInterval(function() { MCL_logExist() }, 10000);

				// TOOD: reimplemente log downloading
				Ext.getCmp('MCL_logSystemFileDownloader').load({
					url: '/index.php/admin/manager_cluster_log/download'
				});
			}
		}
	]
});

Ext.define('/admin/js/manager_cluster_log', {
	extend: 'BasePanel',
	id: 'manager_cluster_log',
	load: function() {
		MCL_logExist();
	},
	bodyStyle: 'padding: 0;',
	items: [
		{
			xtype: 'BasePanel',
			id: 'MCL_logForm',
			bodyStyle: 'padding: 20px;',
			items: [MCL_logPanel]
		}
	]
});
