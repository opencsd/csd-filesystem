// 클러스터 상태
function MNS_stageClusterStatus(ip)
{
	if (typeof(ip) == 'undefined' || ip == null)
	{
		console.error('Invalid parameter: ip');
		return;
	}

	var url = window.location.protocol + '//' + ip
			+ '/api/cluster/status';

	// 클러스터 정보 출력
	GMS.Cors.request({
		url: url,
		method: 'POST',
		waitMsgBox: null,
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
			{
				clearInterval(_nowCurrentStageVar);
				_nowCurrentStageVar = null;

				return;
			}

			var stage = decoded.stage_info.stage;
			var data  = decoded.stage_info.data;

			console.log('stage:', stage);

			clearInterval(_nowCurrentStageVar);

			// GET/SET 불가능: 별도의 웹 페이지 노출
			if (stage == 'booting')
			{
				Ext.getCmp('MNS_stagePanel')
					.update(lang_staging[6].replace('@', lang_staging[2]));

				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else if (stage == 'support' && data == 'node')
			{
				Ext.getCmp('MNS_stagePanel')
					.update(lang_staging[6].replace('@', lang_staging[1]));

				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else if (stage == 'attaching' && data == 'node')
			{
				Ext.getCmp('MNS_stagePanel')
					.update(lang_staging[6].replace('@', 'attaching'));

				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else if (stage == 'detached')
			{
				Ext.getCmp('MNS_stagePanel')
					.update(lang_staging[6].replace('@', 'detaching'));

				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else if (stage == 'configured')
			{
				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else if (stage == 'initializing' || stage == 'expanding')
			{
				_nowCurrentStageVar = null;

				// 진행률 초기화
				Ext.getCmp('progressProcRate').updateProgress('0', '0 %');
				Ext.getCmp('progressTotalRate').updateProgress('0', '0 %');
				Ext.getCmp('progressCompletedList').update('');

				progressWindow.show();

				progressStatus('/api/cluster/stage/get');
			}
			else if (stage == 'uninitialized')
			{
				if (Ext.getCmp('MNS_stagePanel') != undefined)
				{
					Ext.getCmp('MNS_stagePanel')
						.update(lang_staging[6].replace('@', 'uninitialized'));
				}

				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else if (stage == 'upgrading')
			{
				Ext.getCmp('MNS_stagePanel')
					.update(lang_staging[6].replace('@', lang_staging[4]));

				_nowCurrentStageVar = setInterval(
					function () { MNS_stageClusterStatus(ip) },
					1000
				);
			}
			else
			{
				_nowCurrentStageVar = null;
				//locationMain();
				console.log('locationMain()');
			}
		}
	});
}

// 클러스터 관리 -> 클러스터 노드 관리
Ext.define('/admin/js/manager_node_stage', {
	extend: 'BasePanel',
	id: 'manager_node_stage',
	bodyStyle: 'padding: 0;',
	load: function (data) {
		// 데이터 전송 완료 후 wait 제거
		if (waitMsgBox)
		{
			waitMsgBox.hide();
			waitMsgBox = null;
		}

		MNS_stageClusterStatus(data);
	},
	items: [
		{
			xtype: 'BasePanel',
			id: 'MNS_stagePanel',
			layout: 'fit',
			bodyStyle: 'padding: 5px;',
			bodyCls: 'm-stage-panel',
			html: '&nbsp;'
		}
	]
});
