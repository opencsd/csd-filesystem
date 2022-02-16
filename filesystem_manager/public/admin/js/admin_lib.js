/** 공통 설정 **/
Ext.BLANK_IMAGE_URL = '/js/extjs/resources/themes/images/default/tree/s.gif';
Ext.USE_NATIVE_JSON = true;

//* GMS Custom classes
function _json_escape(json)
{
	return json
		.replace(/[\\]/g, '\\\\')
		.replace(/[\"]/g, '\\\"')
		//.replace(/[\/]/g, '\\/')
		.replace(/[\b]/g, '\\b')
		.replace(/[\f]/g, '\\f')
		.replace(/[\n]/g, '\\n')
		.replace(/[\r]/g, '\\r')
		.replace(/[\t]/g, '\\t');
}

function _get_exception(options)
{
	options = options || {};

	//console.trace('options:', options);

	var exception = '{ ';

	if ('title' in options)
	{
		exception += '"title": "' + options.title + '", ';
	}

	if ('content' in options)
	{
		exception += '"content": "' + options.content + '", ';
	}

	if ('msg' in options)
	{
		exception += '"msg": "' + options.msg + '", ';
	}

	if ('code' in options)
	{
		exception += '"code": "' + options.code + '", ';
	}

	exception += '"response": "' + options.response + '"';
	exception += ' }';

	return exception;
}

function migrate_options(options)
{
	options = options || {};

	if ('callback' in options)
	{
		options.origin = options.callback;
	}

	if (!('method' in options))
	{
		options.method = 'POST';
	}

	/*
	if (!('waitMsgBox' in options))
	{
		options.waitMsgBox = waitMsgBox;
	}
	*/

	if (!('deferred' in options))
	{
		options.deferred = Ext.create('Ext.ux.Deferred');
		options.promise  = options.deferred.promise();
	}

	// Change default timeout to 180s
	if (!('timeout' in options))
	{
		options.timeout = 60000 * 3;
	}

	if (!('headers' in options))
	{
		options.headers = {};
	}

	if (!('authorization' in options.headers))
	{
		options.headers.authorization
			= 'Bearer ' + Ext.util.Cookies.get('gms_token');
	}

	options.callback = function (options, success, response) {
		try {
			//console.trace('Response: ', options.url, ':', response);

			console.debug('options: ', options);
			console.debug('success: ', success);
			console.debug('response: ', response);

			// 데이터 전송 완료 후 wait 제거
			if (options.waitMsgBox)
			{
				options.waitMsgBox.hide();
				options.waitMsgBox = null;
			}

			var decoded;

			if (response.status == 204)
			{
				decoded = {
					success: true,
				};
			}
			else if (response.status == 401)
			{
				Ext.MessageBox.show({
					title: response.status + ': ' + response.statusText,
					msg: _err_login,
					icon: Ext.MessageBox.ERROR,
					buttons: Ext.MessageBox.OK,
					fn: function () {
						$.removeCookie('gms_token');
						location.replace('/');
					}
				});
			}
			else if (typeof(response.responseText) == 'undefined'
					|| response.responseText == '')
			{
				decoded = {
					title: response.status,
					msg: response.statusText + ': '
						+ response.request.options.url,
				};
			}
			else
			{
				decoded = Ext.JSON.decode(response.responseText);
			}

			if (!success
				|| ('success' in decoded && !decoded.success))
			{
				Ext.MessageBox.show({
					title: response.status + ': ' + response.statusText,
					msg: decoded.msg.replace("\n", "<br />"),
					icon: Ext.MessageBox.ERROR,
					buttons: Ext.MessageBox.OK,
				});
			}

			Ext.callback(
				options.origin,
				options.scope,
				[options, success, response, decoded]);
		}
		catch (e) {
			console.error('Exception:', e);
		}
	};

	//console.trace('Request:', options);

	return options;
}

function ajax_handler(options)
{
	options = migrate_options(options);

	this.callParent([options]);

	return options.promise;
}

function cors_handler(options)
{
	this.constructor(options, options.url);

	options = migrate_options(options);

	this.callParent([options]);

	return options.promise;
}

Ext.define(
	'GMS.Ajax',
	{
		extend: 'Ext.data.Connection',
		alternateClassName: ['GMS.Ajax'],
		singleton: true,
		request: ajax_handler,
		listeners: {
			/*
			 * :NOTE Sat 08 Jun 2019 09:01:42 PM KST: P.G.
			 * we can use this listener to handle request later.
			requestcomplete: function (conn, response, options, eOpts) {
				console.debug(conn);
				console.debug(response);
				console.debug(options);
				console.debug(eOpts);
			},
			requestexception: function (conn, response, options, eOpts) {
				// :TODO Sat 08 Jun 2019 09:05:11 PM KST: by P.G.
				// exception handling for request timeout
			},
			*/
		},
	}
);

Ext.define('GMS.Cors', {
	extend: 'Ext.data.Connection',
	alternateClassName: ['GMS.Cors'],
	singleton: true,
	config: {
		autoAbort: false,
		cors: true,
		withCredentials: true,
		useDefaultXhrHeader: false,
	},
	constructor: function (config, url) {
		config = config || {
			method: 'POST',
		};

		console.debug('config:', config);

		if (typeof(config.url) != 'undefined'
			&& !config.url.match(/^http(|s):\/\//))
		{
			var node = Ext.util.Cookies.get('gms_node');

			if (!node)
				node = window.location.host;

			config.url = config.url.replace(/^\/+/g, '');
			config.url = window.location.protocol + '//' + node + '/' + config.url;
		}

		this.initConfig(config);
		this.callParent([config]);
	},
	request: cors_handler,
});

Ext.define(
	'GMS.AjaxProxy',
	{
		extend: 'Ext.data.proxy.Ajax',
		alias: 'proxy.gms',
		reader: {
			type: 'json',
			root: 'entity',
			totalProperty  : 'count',
			successProperty: 'success',
			messageProperty: 'msg',
		},
		//paramsAsJson: true,
		/*
		doRequest: function (operation, callback, scope) {
			var me = this,
				writer  = me.getWriter(),
				request = me.buildRequest(operation),
				method  = me.getMethod(request);

			if (operation.allowWrite())
			{
				request = writer.write(request);
			}

			Ext.apply(request, {
				binary        : me.binary,
				headers       : me.headers,
				timeout       : me.timeout,
				scope         : me,
				callback      : me.createRequestCallback(request, operation, callback, scope),
				method        : method,
				disableCaching: false
			});

			if (method.toUpperCase() !== 'GET' && me.paramsAsJson)
			{
				request = Ext.apply(
					{
						jsonData: request.params
					},
					request
				);

				delete request.params;
			}

			GMS.Ajax.request(request);

			return request;
		},
		*/
		listeners: {
			exception: function (response, operation, eOpts) {
				var decoded;

				if (operation.status == 204)
				{
					decoded = {
						success: true,
					};
				}
				else if (typeof(operation.responseText) === 'undefined'
						|| operation.responseText === '')
				{
					decoded = {
						title: operation.status,
						msg: operation.statusText + ': '
							+ operation.request.options.url,
					};
				}
				else
				{
					decoded = Ext.JSON.decode(operation.responseText);
				}

				Ext.MessageBox.show({
					title: this.exception_title,
					msg: decoded.msg,
					icon: Ext.MessageBox.ERROR,
					buttons: Ext.MessageBox.OK,
				});

				return;
			}
		},
		exception_title: 'Unexpected error',
		exception_content: 'Unexpected error',
	}
);

Ext.define(
	'GMS.Store',
	{
		extends: 'Ext.data.Store',
		actionMethods: { read: 'POST' },
		onProxyLoad: function (operation) {
			var me         = this,
				resultSet  = operation.getResultSet(),
				records    = operation.getRecords(),
				successful = operation.wasSuccessful();

			if (me.isDestroyed) {
				return;
			}

			if (resultSet) {
				me.totalCount = resultSet.total;
			}

			me.loading = false;

			if (successful) {
				me.loadRecords(records, operation);
			}

			if (me.hasListeners.load) {
				me.fireEvent('load', me, records, successful);
			}

			if (me.hasListeners.read) {
				me.fireEvent('read', me, records, successful);
			}

			Ext.callback(
				operation.callback,
				operation.scope || me,
				[records, operation, successful]);
		},
	}
);

// 그룹 체크 기능
Ext.define(
	'Ext.grid.feature.CheckGrouping',
	{
		extend: 'Ext.grid.feature.Grouping',
		requires: 'Ext',
		alias: 'feature.brigrouping',
		constructor: function () {
			this.callParent(arguments);

			this.groupHeaderTpl = [
				'<dl style="height: 13px; border: 0px; margin-block-start: 0px; margin-block-end: 0px; !important">',
					//'<div unselectable="on" class="x-grid-cell-inner" style="text-align:left;">',
					//'<div id="groupcheck{name}" class="x-grid-row-checker" role="presentation" style="float: left;">&nbsp;</div></div>',
					'<dd id="groupcheck{name}" class="x-grid-row-checker x-column-header-text" style="float: left; margin: 0 0 0 0;" x-grid-group-hd-text="{text}">&nbsp;</dd>',
					'<dd style="float: left; padding: 0 0 0 4px; margin: 0;">',
						this.groupHeaderTpl,
					'</dd>',
				'</dl>'
			].join('');
		},
		expanderXPos: 20,
		expanderYPos: -1,
		expanderImageWidth: 9,
		expanderImageHeight: 9,
		onGroupClick: function (view, node, group, e, options) {
			var checkbox = Ext.get('groupcheck' + group);

			if (this.inCheckbox(checkbox, e.getXY()))
			{
				this.toggleCheckbox(group, node, view);
			}
			//else if (this.inExpander(checkbox, e.getXY()))
			else
			{
				this.callParent(arguments);
			}
		},
		inCheckbox: function (checkbox, xy) {
			var x = xy[0],
				y = xy[1];

			return x >= checkbox.getLeft()
					&& x <= checkbox.getRight()
					&& y >= checkbox.getTop()
					&& y <= checkbox.getBottom();
		},
		inExpander: function (checkbox, xy) {
			var expanderLeft = checkbox.getWidth() + checkbox.getLeft()
								+ (this.expanderXPos - checkbox.getWidth()),
				expanderRight = expanderLeft + this.expanderImageWidth,
				expanderTop = checkbox.getTop() + this.expanderYPos,
				expanderBottom = expanderTop + this.expanderImageHeight,
				x = xy[0],
				y = xy[1];

			return x >= expanderLeft && x <= expanderRight
				&& y >= expanderTop && y <= expanderBottom;
		},
		toggleCheckbox: function (group, node, view) {
			var node_el = Ext.get(node),
				sm = view.getSelectionModel(),
				store = sm.store,
				grouper,
				adding,
				records;

			if (!Ext.isEmpty(store.groupers))
			{
				grouper = store.groupers.items[0].property;
			}

			if (!node_el.hasCls('x-grid-row-checked'))
			{
				node_el.addCls('x-grid-row-checked');
				adding = true;
			}
			else
			{
				node_el.removeCls('x-grid-row-checked');
				adding = false;
			}

			records = store.queryBy(
				function (record, id)
				{
					if (record.data[grouper] === group && adding)
					{
						sm.select(record, true);
						return true;
					}

					var n = Ext.get(
						node_el.dom.id
							.replace(group, record.data[grouper])
					);

					if (n.hasCls('x-grid-row-checked'))
					{
						n.removeCls('x-grid-row-checked');
					}

					sm.deselect(record);

					return false;
				},
				this
			);
		},
	}
);

// :TODO 12/25/2019 07:15:05 PM: by P.G.
// we need to implement it.
Ext.define(
	'GMS.Msg',
	{
		extend: 'Ext.window.Window',
		width: 300,
		height: 120,
		autoDestroy: true,
		//title: title,
		modal: true,
		layout: 'fit',
		bodyStyle: {
			'border': 'none',
			'background-color': 'transparent',
		},
		buttonAlign: 'center',
		items: [
			{
				xtype: 'container',
				//html: message
			}
		],
		buttons: [
			{
				text: 'OK',
				listeners: {
					click: {
						fn: function (item, e) {
							this.up('window').close();
						}
					}
				},
			},
		],
	},
);

/*/
...?
//*/

// 언어 설정: 기본값 ko
if ($.cookie('language') == undefined)
{
	$.cookie('language', 'ko', { expires: 365, path: '/' });
};

function trim(str)
{
	return str.replace(/(^\s*)|(\s*$)/g, "");
};

// 문자열 체크 출력 - 하단에 표시
//Ext.form.Field.prototype.msgTarget = 'under';
Ext.form.Field.prototype.msgTarget = 'side';

// 메세지 박스 크기 지정
Ext.Msg.minWidth = 340;

Ext.override(
	Ext.form.field.ComboBox,
	{
		createPicker: function () {
			var me = this,
				picker,
				menuCls = Ext.baseCSSPrefix + 'menu',
				opts = Ext.apply(
					{
						pickerField: me,
						selModel: {
							mode: me.multiSelect ? 'SIMPLE' : 'SINGLE'
						},
						floating: true,
						hidden: true,
						ownerCt: me.ownerCt,
						cls: me.el.up('.' + menuCls) ? menuCls : '',
						store: me.store,
						displayField: me.displayField,
						focusOnToFront: false,
						pageSize: me.pageSize,
						tpl: me.tpl,
						loadMask: me.queryMode === 'local' ? false: true
					},
					me.listConfig,
					me.defaultListConfig
				);

			picker = me.picker = Ext.create('Ext.view.BoundList', opts);

			if (me.pageSize)
			{
				picker.pagingToolbar.on('beforechange', me.onPageChange, me);
			}

			me.mon(picker, {
				itemclick: me.onItemClick,
				refresh: me.onListRefresh,
				scope: me
			});

			me.mon(picker.getSelectionModel(), {
				beforeselect: me.onBeforeSelect,
				beforedeselect: me.onBeforeDeselect,
				selectionchange: me.onListSelectionChange,
				scope: me
			});

			return picker;
		}
	}
);

/*
 * IE8
 */
/*
var agent = navigator.userAgent.toLowerCase();
var trident = agent.match(/Trident\/(\d.\d)/i);

if( trident != null )
{
	if( trident[1] <= "8" )
	{
		Ext.override(Ext.dom.Element, {
			setStyle: function (prop, value) {
				var me = this,
					dom = me.dom,
					hooks = me.styleHooks,
					style = dom.style,
					name = prop,
					hook;

				if (typeof name == 'string') {
					hook = hooks[name];
					if (!hook) {
						hooks[name] = hook = { name: Ext.dom.Element.normalize(name) };
					}
					value = (value == null) ? '' : value;
					if (hook.set) {
						hook.set(dom, value, me);
					} else {
						style[hook.name] = value;
					}
					if (hook.afterSet) {
						hook.afterSet(dom, value, me);
					}
				} else {
					for (name in prop) {
						if (prop.hasOwnProperty(name)) {
							hook = hooks[name];
							if (!hook) {
								hooks[name] = hook = { name: Ext.dom.Element.normalize(name) };
							}
							value = prop[name];
							value = (value == null) ? '' : value;
							if (hook.set) {
								hook.set(dom, value, me);
							} else {
								//style[hook.name] = value;
								style[name] = value;
							}
							if (hook.afterSet) {
								hook.afterSet(dom, value, me);
							}
						}
					}
				}
				return me;
			}
		});
	}
};
*/

/** store memory로 로드 시 버그 **/
Ext.define(
	'Ext.override.data.Store',
	{
		override: 'Ext.data.Store',
		/**
		* @inheritdoc
		* @localdoc fire load event and set proxy data
		*/
		loadRawData: function (data, append)
		{
			var me = this;
			var result = me.proxy.reader.read(data);
			var records = result.records;

			// fire beforeload event
			if (me.hasListeners.beforeload) me.fireEvent('beforeload', me, records, result.success);

			me.lastOptions = Ext.apply({}, append ? me.addRecordOptions : undefined);

			if (result.success)
			{
				// set inline data, e.g. for refresh
				if (me.proxy instanceof Ext.data.proxy.Memory)
				{
					if (append && Ext.isArray(me.proxy.data))
						me.proxy.data.push.apply(me.proxy.data, me.proxy.reader.getRoot(data));
					else
						me.proxy.data = me.proxy.reader.getRoot(data);
				}

				// increment totalCount
				if (append)
					me.totalCount += result.total;
				else
					me.totalCount = result.total;

				me.loadRecords(records, append ? me.addRecordsOptions : undefined);
			}

			// fire load event
			if (me.hasListeners.load)
				me.fireEvent('load', me, records, result.success);
		},
		/**
		* @inheritdoc
		* @localdoc fire load event
		*/
		loadData: function (data, append)
		{
			var me = this,
				length = data.length,
				allData = me.snapshot || me.data, // filtered?
				dataLen = allData.length,
				newData = [],
				totalCount = me.getTotalCount(),
				i;

			me.lastOptions = Ext.apply({}, append ? me.addRecordOptions : undefined);

			for (i=0; i<length; i++)
				newData.push(this.createModel(data[i]));

			// set inline data, e.g. for refresh
			if (me.proxy instanceof Ext.data.proxy.Memory)
				// According to the docs, the proxy's inline data is an array, not an object with total, success, root etc.
				// We rely on it, otherwise the data config is used in a wrong way.
				me.proxy.data = (append && me.proxy.data ? me.proxy.data : []).concat(data);

			this.loadRecords(newData, append ? this.addRecordsOptions : undefined);
			this.totalCount = (append ? totalCount : 0) + (allData.length - dataLen);

			// fire load event
			if (this.hasListeners.load)
				this.fireEvent('load', this, newData, true);
		},
		removeAll: function (silent) {
			var me = this,
				snapshot = me.snapshot,
				data = me.data;

			if (snapshot) {
				snapshot.removeAll(data.getRange());
			}

			if (me.buffered) {
				if (data) {
					if (silent) {
						me.suspendEvent('clear');
					}
					data.clear();
					if (silent) {
						me.resumeEvent('clear');
					}
				}
			}
			else
			{
				me.remove(
					{ start: 0, end: me.getCount() - 1 },
					false,
					silent
				);

				if (silent !== true)
				{
					me.fireEvent('clear', me);
				}
			}
		}
	}
);

// wait 창의 기본값
var waitMsgBox = null;
var waitWindow = function (title, content)
{
	waitMsgBox = Ext.MessageBox.wait(content, title);

	return waitMsgBox;
};

// 진행 상태
var completedListCount = 0;

function progressStatus(url, data)
{
	GMS.Ajax.request({
		url: url,
		timeout: 60000,
		jsonData: {
			Scope: 'node',
		},
		callback: function (options, success, response, decoded) {
			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				progressWindow.hide();
				clearInterval(_nowCurrentInitStageVar);
				_nowCurrentInitStageVar = null;

				return;
			}

			_updateProgress(decoded.stage_info);

			if (decoded.stage_info.stage == 'running')
			{
				clearInterval(_nowCurrentInitStageVar);

				_nowCurrentInitStageVar = null;

				Ext.getCmp('progressWindowCloseBtn').show();

				return;
			}

			_nowCurrentInitStageVar = setInterval(
				function () {
					clearInterval(_nowCurrentInitStageVar);
					progressStatus(url, data);
				},
				1000
			);
		}
	});
}

function initProgress()
{
	Ext.getCmp('progressProcRate').updateProgress('0', '0 %');
	Ext.getCmp('progressTotalRate').updateProgress('0', '0 %');
	Ext.getCmp('progressCompletedList').update('');
}

function _updateProgress(stage_info)
{
	var stage = stage_info.stage;
	var nodes;
	var rate;

	console.debug('stage:', stage_info);

	if (!('proc' in stage_info) || stage_info.proc == null)
		return;

	nodes = 'nodes' in stage_info.proc ? stage_info.proc.nodes : null;
	rate  = 'total_rate' in stage_info.proc ? stage_info.proc.total_rate : 0;

	if (nodes === null || nodes.length == 0)
	{
		return;
	}

	var completed = nodes[nodes.length-1].completed;
	var curr_proc = nodes[nodes.length-1].curr_proc;
	var proc_rate = nodes[nodes.length-1].proc_rate;

	Ext.getCmp('progressCompletedList')
		.update(
			"<span style='line-height:200%'><img src='/admin/images/loading.gif' align='center'>&nbsp;&nbsp;<b>"
			+ curr_proc
			+ ' ...</b></span></br>');

	var completedList = Ext.getCmp('progressCompletedList').html;

	for (var i = completed.length; 0 < i; i--)
	{
		Ext.getCmp('progressCompletedList')
			.update(
				completedList
				+ '<span style="line-height:200%"><img src="/admin/images/icon-tick.png" align="center">&nbsp;&nbsp;'
				+ completed[i-1]
				+ '</span></br>');

		completedList = Ext.getCmp('progressCompletedList').html;
	}

	var totalRate = Math.floor(rate);
	var totalRateValue = totalRate / 100;

	Ext.getCmp('progressTotalRate').updateProgress(totalRateValue, totalRate + ' %');

	if (completedListCount < completed.length)
	{
		Ext.getCmp('progressProcRate').updateProgress('100', '100 %');
		Ext.getCmp('progressProcRate').updateProgress('0', '0 %');

		completedListCount = completed.length;
	}

	var procRate = Math.floor(proc_rate);
	var procRateValue = procRate / 100;

	Ext.getCmp('progressProcRate').updateProgress(procRateValue,procRate + ' %');

	return;
}

// 진행창 패널
var progressPanel = Ext.create(
	'BaseFormPanel',
	{
		id: 'progressPanel',
		frame: false,
		layout: { type: 'vbox' ,align: 'stretch' },
		items: [
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						id: 'progressProcProgress',
						bodyStyle: 'padding: 0;',
						style: { marginBottom: '5px' },
						html: lang_admin[15]
					},
					{
						xtype: 'progressbar',
						id: 'progressProcRate',
						text: '0 %',
						animate: true,
						cls: 'install-progress'
					}
				]
			},
			{
				xtype: 'BasePanel',
				bodyStyle: 'padding: 0;',
				style: { marginBottom: '20px' },
				items: [
					{
						xtype: 'BasePanel',
						id: 'progressTotalProgress',
						bodyStyle: 'padding:0;',
						style: { marginBottom: '5px' },
						html: lang_admin[16]
					},
					{
						xtype: 'progressbar',
						id: 'progressTotalRate',
						text: '0 %',
						animate: true,
						cls: 'install-progress'
					}
				]
			},
			{
				xtype: 'BaseFormPanel',
				id: 'progressCompletedList',
				title: lang_admin[17],
				bodyStyle: 'padding: 5px 10px;',
				height: 180,
				viewConfig: {
					preserveScrollOnRefresh: true
				}
			}
		]
	}
);

// 진행창 윈도우
var progressWindow = Ext.create('BaseWindowPanel', {
	id: 'progressWindow',
	title: lang_admin[13],
	maximizable: false,
	closable: false,
	width: 500,
	items: [ progressPanel ],
	buttons: [
		{
			id: 'progressWindowCloseBtn',
			text: lang_common[4],
			hidden: true,
			handler: function () { locationMain(); }
		}
	]
});

// 상태 체크
function clusterStageStatus(loadPage, licenseCheck,  stage, stageData)
{
	if (stage == 'running' || stage == 'support' || stage == 'booting')
	{
		if (licenseCheck != 'true')
		{
			// 라이선스 페이지 :: 라이선스페이지 출력
			return 'license';
		}
	}
	
	if (stage == 'running' || stage == 'expanding')
	{
		// 정상 페이지
		return 'normal';
	}
	else if (stage == 'support')
	{
		if (loadPage.indexOf('manager_node') != -1)
		{
			// 노드 페이지
			/** 각노드별 별도 페이지 출력 */
			return 'node';
		}
		else
		{
			// 클러스터 노드 페이지
			/** 클러스터 노드 관리 페이지의 노드 정보 출력 */
			return 'clusterSupport';
		}
	}
	else
	{
		// 노드 페이지
		/** 각노드별 별도 페이지 출력 */
		return 'node';
	}
};

// 라이선스 체크
function MA_licenseCheck(loadPage, callback)
{
	GMS.Ajax.request({
		url: '/api/system/license/summary',
		jsonData: {
			loadPage: loadPage
		},
		callback: function (options, success, response, decoded) {
			// 예외 처리에 따른 동작
			if (!success || !decoded.success)
			{
				Ext.getCmp(treeid).unmask();
				return;
			}

			var stage        = decoded.stage_info.stage;
			var stageData    = decoded.stage_info.data;
			var licenceValue = decoded.entity[0];

			// 라이선스
			licenseCheck = decoded.return;
			licenseADS   = licenceValue.ADS;
			licenseSMB   = licenceValue.CIFS;
			licenseNFS   = licenceValue.NFS;
			licenseNode  = licenceValue.Node;

			if (callback instanceof Function)
			{
				callback(licenseCheck, stage, stageData);
			}
		}
	});
};

/** 자연 정렬 타입 추가 **/
Ext.apply(Ext.data.SortTypes, {
	asNatural: function (str) {
		// Pad all the numbers we can find with 10 zeros to the left, then trim
		// down to the last 10 digits. A primitive natural sort occurs.
		// WARN: May do odd things to any numbers longer than 10 digits. It will
		// also not work as you might expect on decimals.
		return str.replace(/(\d+)/g, "0000000000$1").replace(/0*(\d{10,})/g, "$1");
	}
});

Ext.apply(
	Ext.form.field.VTypes,
	{
		/** 공통 **/
		// 숫자 체크
		reg_Number: function (v) { return /^[1-9][0-9]*$/.test(v); },
		reg_NumberText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[12]+'<br>'+lang_vtype[2]+' : '+lang_vtype[17].replace("@","1~9"),

		// 실수 체크
		reg_realNumber:  function (v) {
			return /(^[1-9]$)|(^[1-9][0-9]*(\.?[0-9]{1,2})$)|(^[0]+(\.?[0-9]{1,2})$)/.test(v);
		},
		reg_realNumberText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[12]+'<br>'+lang_vtype[2]+' : '+lang_vtype[33],

		// 숫자 체크 0 포함
		reg_allNumber:  function (v) {
			return /(^[0]$)|(^[1-9][0-9]*$)/.test(v);
		},
		reg_allNumberText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[12],

		reg_ID:  function (v) {
			return /^[a-zA-Z]{1}[a-zA-Z0-9-_]{3,19}$/.test(v);
		},
		reg_IDText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "-, _" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[13]+', '+lang_vtype[6]+' 4~20 '+lang_vtype[8],

		reg_IdExcept:  function (v) {
			return /^[a-zA-Z]{1}[a-zA-Z0-9-_]{4,19}$/.test(v);
		},
		reg_IdExceptText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "-, _" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[13]+', '+lang_vtype[6]+' 5~20 '+lang_vtype[8],

		// 공유 설명: reg_DESC
		reg_DESC:  function (v) {
			return /^[\uac00-\ud7a3\u3131-\u314e\u314f-\u31630-9a-zA-Z\s_]{2,40}$/.test(v);
		},
		reg_DESCText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[10]+', '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "_, '+lang_vtype[26]+'" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 2~40 '+lang_vtype[8],

		reg_PW:  function (v) {
			return /^[a-zA-Z0-9\ \~\!\@\#\$\%\^\&\*\(\)\_\+\|\}\{\"\:\?\>\<\`\[\]\;\'\,\.\/]{4,20}$/.test(v);
		},
		reg_PWText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : '+lang_vtype[16]+' '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 4~20 '+lang_vtype[8],

		// 사용자 패스워드 길이 예외
		reg_userPW:  function (v) {
			return /^[a-zA-Z0-9\ \~\!\@\#\$\%\^\&\*\(\)\_\+\|\}\{\"\:\?\>\<\`\[\]\;\'\,\.\/]{5,20}$/.test(v);
		},
		reg_userPWText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : '+lang_vtype[16]+' '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 5~20 '+lang_vtype[8],

		reg_HOSTNAME:  function (v) {
			return /(^[a-zA-Z0-9]([a-z0-9_\.-]+)\.([a-z\.]{2,6})$)|(^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$)/.test(v);
		},
		reg_HOSTNAMEText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[14],

		reg_NETWORKHOSTNAME:  function (v) {
			return /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/.test(v);
		},
		reg_NETWORKHOSTNAMEText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[29]+'<br>'+lang_vtype[3]+' : "., -" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[30],

		reg_PORT:  function (v) {
			return /^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{1,3}|[0-9])$/.test(v);
		},
		reg_PORTText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[12]+'<br>'+lang_vtype[2]+' : '+lang_vtype[15].replace("@","0~65565"),

		reg_IP:  function (v) {
			return /^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/.test(v);
		},
		reg_IPText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[12]+'"<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~3 '+lang_vtype[8]+', '+lang_vtype[18].replace("@","255"),

		reg_SNAPSHOT:  function (v) {
			return /^([1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-6])$/.test(v);
		},
		reg_SNAPSHOTText:  lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[12]+'"<br>'+lang_vtype[2]+' :  '+lang_vtype[15].replace("@","1~256"),

		reg_NETMASK:  function (v) {
			return /^(0|128|192|224|240|248|252|254|255)$/.test(v);
		},
		reg_NETMASKText:   lang_vtype[0]+'<br>'+lang_vtype[2]+' : '+lang_vtype[32].replace("@","0, 128, 192, 224, 240, 248, 252, 254, 255"),

		reg_Zero:  function (v) {
			return /^(0)$/.test(v);
		},
		reg_ZeroText:   lang_vtype[0]+'<br>'+lang_vtype[2]+' : '+lang_vtype[34].replace("@","0"),

		reg_DOMAIN:  function (v) {
			return /^[a-zA-Z0-9]([a-z0-9_\.-]+)\.([a-z\.]{2,6})$/.test(v);
		},
		reg_DOMAINText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[19],

		reg_PHONE:  function (v) {
			return /^[0-9]{2,3}-?[0-9]{3,4}-?[0-9]{4}$/.test(v);
		},
		reg_PHONEText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[12]+'"<br>'+lang_vtype[3]+' : "-" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[20],

		reg_VLAN:  function (v) {
			return /^(409[0-6]|40[0-8][0-9]|[1-3][0-9]{3}|[1-9][0-9]{1,2}|[0-9])$/.test(v);
		},
		reg_VLANText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[12]+'"<br>'+lang_vtype[2]+' : '+lang_vtype[18].replace("@","4096"),

		/** 초기 설정 **/
		// 클러스터명
		reg_ClusterName: function (v) {
			return /^[a-zA-Z0-9]{1,10}$/.test(v);
		},
		reg_ClusterNameText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+'1~10 '+lang_vtype[8],

		/** 시스템 관리 **/
		// 버전 관리 - 버전 업그레이드 파일 확장자
		reg_firmwareAddFile:  function (v) {
			return /\.(gpf|gpmf)$/.test(v);
		},
		reg_firmwareAddFileText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[21]+'<br>'+lang_vtype[2]+' : '+lang_vtype[22],

		// 라이선스 - 라이선스키
		reg_licenseNumber:  function (v) {
			return /^[A-Za-z0-9]{12}$/.test(v);
		},
		reg_licenseNumberText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 12 '+lang_vtype[8],

		// 라이선스 - 라이선스파일 확장자
		reg_licenseFile:  function (v) {
			return /\.(lic)$/.test(v);
		},
		reg_licenseFileText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[21]+'<br>'+lang_vtype[2]+' : '+lang_vtype[23],

		// 시간 설정 - NTP 서버: reg_HOSTNAME

		/** 알림 **/
		// 전자메일 - 관리자 메일주소: email
		// 전자메일 - 보내는 메일주소: email
		// 전자메일 - SMTP 주소: reg_HOSTNAME
		// 전자메일 - 계정 아이디: reg_ID, email
		reg_smtpID:  function (v) {
			return /(^[a-zA-Z]{1}[a-zA-Z0-9-_]{3,19}$)|(^[a-z0-9_-]+[a-z0-9_.-]*@[a-z0-9_-]+[a-z0-9\!\#\$\%\&\*\+\-\/\=\?\^\_\`\{\|\}\~\.\@]*\.[a-z]{2,5}$)/.test(v);
		},
		reg_smtpIDText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+', '+lang_vtype[25]+'<br>'+lang_vtype[3]+' : "-, _" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[13]+', '+lang_vtype[6]+' 4~20 '+lang_vtype[8],

		// 전자메일 - 계정 패스워드: reg_PW
		// SNMP - SNMP Trap: reg_HOSTNAME
		// Rsyslog - 로그 서버주소: reg_HOSTNAME
		// Rsyslog - 로그 포트: reg_PORT

		/** 구성백업 **/
		// 구성 백업 복구 - 설정복원 파일
		reg_compositionRecoveryFile:  function (v) {
			return /\.(backup)$/.test(v);
		},
		reg_compositionRecoveryFileText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[21]+'<br>'+lang_vtype[2]+' : '+lang_vtype[27],

		/** 고객지원 **/
		// 고객지원 - 생성/수정: 고객사
		reg_supportClient:  function (v) {
			return /^[^\/:*?\"\'<>|]{1,50}$/.test(v);
		},
		reg_supportClientText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "\/, :, *, ?, &#34;, &#39;, <, >, |" '+lang_vtype[4]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~50 '+lang_vtype[8],

		// 고객지원 - 생성/수정: 모델명
		reg_supportModel:  function (v) {
			return /^[a-zA-Z0-9]{1}[a-zA-Z0-9_\.-]{1,49}$/.test(v);
		},
		reg_supportModelText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "A~Z, a~z, 0~9"<br>'+lang_vtype[3]+' : "-, ., _" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~50 '+lang_vtype[8]+', '+lang_vtype[17].replace("@","A~Z, a~z, 0~9"),

		// 고객지원 - 생성/수정: 고객사버전
		reg_supportVersion:  function (v) {
			return /^[a-zA-Z0-9]{1}[a-zA-Z0-9_\.-]{1,19}$/.test(v);
		},
		reg_supportVersionText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "A~Z, a~z, 0~9"<br>'+lang_vtype[3]+' : "-, ., _" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~20 '+lang_vtype[8]+', '+lang_vtype[17].replace("@","A~Z, a~z, 0~9"),

		// 고객지원 - 생성/수정: 스토리지 내용
		reg_supportStorageList:  function (v) {
			return /^[a-zA-Z0-9\!\@\#\%\^\&\_\+\-\=\.]{1,20}$/.test(v);
		},
		reg_supportStorageListText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "A~Z, a~z, 0~9"<br>'+lang_vtype[3]+' : "!, @, #, %, ^, &, _, +, -, =, ." '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~20 '+lang_vtype[8]+', '+lang_vtype[24],

		// 고객지원 - 생성/수정: 제목
		reg_supportTitle:  function (v) {
			return /^[^\/:*?<>.|\"\']{1,100}$/.test(v);
		},
		reg_supportTitleText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[7]+'<br>'+lang_vtype[3]+' : "\/, :, *, ?, &#34;, &#39;, <, >, ., |" '+lang_vtype[4]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~100 '+lang_vtype[8],

		// 고객지원 - 생성/수정: 담당자
		reg_supportCharge:  function (v) {
			return /^[^\/:*?<>.|\"\']{1,20}$/.test(v);
		},
		reg_supportChargeText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[7]+'<br>'+lang_vtype[3]+' : "\/, :, *, ?, &#34;, &#39;, <, >, ., |" '+lang_vtype[4]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~20 '+lang_vtype[8],

		// 고객지원 - 생성/수정: 처리결과
		reg_supportResult:  function (v) {
			return /^[^\/:*?<>.|\"\']{1,30}$/.test(v);
		},
		reg_supportResultText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[7]+'<br>'+lang_vtype[3]+' : "\/, :, *, ?, &#34;, &#39;, <, >, ., |" '+lang_vtype[4]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~30 '+lang_vtype[8],

		// 고객지원 - 생성/수정: 내용
		reg_supportContent:  function (v) {
			return /^[^\'\"]+$/.test(v);
		},
		reg_supportContentText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "'+lang_vtype[7]+'"<br>'+lang_vtype[3]+' : "\', &#34;" '+lang_vtype[4],

		// 고객지원 - 중계포트 : reg_PORT

		/** 볼륨 **/
		//디스크 설정 - 논리 디스크명: reg_ID
		//볼륨 설정 - 논리 볼륨명: reg_ID
		//볼륨 설정 - 확장할 논리 볼륨크기 => reg_Number
		//사용량 - 파일 할당수 => reg_allNumber
		//사용량 - 용량 할당 => reg_allNumber

		//볼륨 관리 - 스냅샷 명
		reg_snapshotName:  function (v) {
			return /^[A-Za-z0-9_-]{0,255}$/.test(v);
		},
		reg_snapshotNameText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : _- '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+lang_vtype[18].replace("@",' 255 '+lang_vtype[8]),

		/** 네트워크 **/
		//네트워크 정보 - 호스트 이름: reg_HOSTNAME
		//네트워크 정보 - DNS 주소: reg_HOSTNAME
		//네트워크 장치 - MTU => reg_Number
		//보안 방화벽 - 도메인: reg_DOMAIN
		//네트워크 주소 - 아이피 주소: reg_IP
		//네트워크 주소 - 게이트웨이: reg_IP
		//라우팅 - 넷마스크 주소: reg_NETMASK
		//라우팅 - 게이트 웨이: reg_IP
		//보안 방화벽 - 아이피주소: reg_IP
		//보안 방화벽 - 아이피 범위: reg_IP
		//보안 방화벽 - 넷마스크: reg_NETMASK
		//보안 방화벽 - Zone 설명: reg_DESC
		reg_vipGroupName: function (v) {
			return /^[^\:*?<>.|\"|\%|\$|\=|\+|\`|\#|\@|\!|\~]+$/.test(v);
		},

		reg_vlanID: function (v) { return parseInt(v) > 1 && parseInt(v) < 4095; },
		reg_vlanIDText: lang_vtype[0] + '<br>' + lang_vtype[1] + ' : ' + lang_vtype[15].replace("@", "2~4094"),

		// 보안 방화벽 - Zone이름
		reg_zoneFormName:  function (v) {
			return /^[A-Za-z0-9_]{4,20}$/.test(v);
		},
		reg_zoneFormNameText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "_" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 4~20 '+lang_vtype[8],
		
		/** 볼륨풀 **/
		//볼륨풀 생성 -  이름
		reg_volumePoolName:  function (v) {
			return /^[A-Za-z0-9_]{3,19}[a-zA-Z]{1}$/.test(v);
		},
		reg_volumePoolNameText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "_" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 4~20 '+lang_vtype[8]+','+lang_vtype[35],

		/** 계정 **/
		//사용자 - 사용자 아이디: reg_IdExcept
		//사용자 - 사용자 별칭: reg_DESC
		//그룹 - 그룹명: reg_ID
		//그룹 - 그룹설명: reg_DESC
		//사용자 - 사용자 비밀번호: reg_PW
		//외부인증 - 도메인 이름: reg_HOSTNAME
		//외부인증 - 도메인 컨트롤러: reg_HOSTNAME
		//관리자 - 관리자 전화번호, 담당자 전화번호: reg_PHONE
		//관리자 - 관리자 이메일: email
		//관리자 - 담당자 전화번호 => reg_adminPhone
		//관리자 - 담당자 이메일 => email
		//관리자 - 비밀번호: reg_PW
		//관리자 - 회사명: reg_DESC
		//관리자 - 담당자: reg_DESC

		//사용자 - 일괄설정 파일
		reg_userFile:  function (v) {
			return /\.(csv)$/.test(v);
		},
		reg_userFileText:   lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[21]+'<br>'+lang_vtype[2]+' : '+lang_vtype[28],

		// 외부인증 - Net Bios 이름
		reg_externalADNetBios:  function (v) {
			return /^[a-zA-Z0-9-]{1,15}$/.test(v);
		},
		reg_externalADNetBiosText:  lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[11]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "-" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 1~15 '+lang_vtype[8],

		/** 공유 **/
		// 서비스 프로토콜 FTP - Passive 시작포트 => reg_allNumber
		// 서비스 프로토콜 FTP - Passive 마지막포트 => reg_allNumber
		// 서비스 프로토콜 FTP - 포트 번호 => reg_allNumber
		// 서비스 프로토콜 FTP - 최대 연결 개수 => reg_allNumber
		// 서비스 프로토콜 CIFS - WINS 서버: reg_HOSTNAME
		// 서비스 프로토콜 CIFS - 설명: reg_DESC

		// 서비스 프로토콜 CIFS - 작업그룹
		reg_protocolCifsWorkGroup: function (v) {
			stringByteLength = v.replace(/[\0-\x7f]|([0-\u07ff]|(.))/g, "$&$1$2").length;

			if (stringByteLength > 15)
				return false;
			else
				return /^[^\/:*?\"\'<>|]{0,15}$/.test(v);
		},
		reg_protocolCifsWorkGroupText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "\/, :, *, ?, &#34;, &#39;, <, >, |" '+lang_vtype[4]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 0~15 Byte',

		// 서비스 프로토콜 NFS - 공통옵션
		reg_protocolNfsGlobal: function (v) {
			return /^[^\"\']$/.test(v);
		},
		reg_protocolNfsGlobalText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : "&#34;, &#39;" '+lang_vtype[4],

		// 공유 설정 - 공유명
		reg_shareInfoName: function (v) {
			return /^[\uac00-\ud7a3\u3131-\u314e\u314f-\u31630-9a-zA-Z\s_-]{2,20}$/.test(v);
		},
		reg_shareInfoNameText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[10]+', '+lang_vtype[31]+', '+lang_vtype[12]+'<br>'+lang_vtype[3]+' : "_, '+lang_vtype[26]+'" '+lang_vtype[5]+'<br>'+lang_vtype[2]+' : '+lang_vtype[6]+' 2~20 '+lang_vtype[8],

		// 공유 설정 - 공유 경로: reg_PATH
		reg_shareInfoPath: function (v) {
			return /^[^\:*?<>.|\"|\%|\$|\=|\+|\`|\#|\@|\!|\~]+$/.test(v);
		},
		reg_shareInfoPathText: lang_vtype[0]+'<br>'+lang_vtype[1]+' : '+lang_vtype[9]+'<br>'+lang_vtype[3]+' : ":, *, ?, &#34;, <, >, ., |, `, #, @, !, ~" '+lang_vtype[4],
	}
);

Ext.apply(
	Ext.form.VTypes,
	{
		publicip: function (v) {
			var errmsg = 'Invalid public IP address',
				parts  = [];

			v = Ext.util.Format.trim(v || '').split('.');

			for (var i=0; i<v.length; i++)
			{
				var num = parseInt(v[i]);

				if (Ext.isNumber(num) && num >= 0 && num <= 255)
				{
					parts.push(num);
				}
				else
				{
					return errmsg;
				}
			}

			if (parts.length !== 4)
			{
				return errmsg;
			}

			// RFC 1918
			if (parts[0] === 127 || parts[0] === 10
				|| (parts[0] === 192 && parts[1] === 168)
				|| (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31))
			{
				return errmsg;
			}

			return true;
		},
	}
);

// 넷마스크 주소 입력 체크
function netMaskInput(value, nInput, inputId)
{
	for (var i=nInput; i<=4; i++)
	{
		var inputObj = inputId + i;

		if (value != '' && (value == '0' || value != '255'))
		{
			Ext.getCmp(inputObj).vtype = 'reg_Zero';
			Ext.getCmp(inputObj).setValue('0');
			Ext.getCmp(inputObj).validate();
		}
		else if (value == '255')
		{
			Ext.getCmp(inputObj).allowBlank = true;
			Ext.getCmp(inputObj).setValue('');
			Ext.getCmp(inputObj).clearInvalid();
			Ext.getCmp(inputObj).vtype = 'reg_NETMASK';
			Ext.getCmp(inputObj).validate();
		}
	}
}

/*
 * 팝업 윈도우 이동 컨트롤
 */
Ext.override(
	Ext.Window,
	{
		constraint: true,
		constrainHeader: true,
	}
);

/*
 * grid row plugin의 각 그리드의 row 마다 colspan이 잘못 들어가는 버그
 */
Ext.grid.plugin.RowExpander.override({
	getRowBodyFeatureData: function (record, idx, rowValues) {
		var me = this;
		me.self.prototype.setupRowData.apply(me, arguments);

		if (!me.grid.ownerLockable) {
			rowValues.rowBodyColspan = rowValues.rowBodyColspan ;
		}
		rowValues.rowBody = me.getRowBodyContents(record);
		rowValues.rowBodyCls = me.recordsExpanded[record.internalId] ? '' : me.rowBodyHiddenCls;
	}
});

/*
 * Infinite grid row 선택시 length undefined error
 */
Ext.override(Ext.selection.Model, {
	getStoreRecord: function (record) {	//4.2.3
		var store = this.store,
			records, rec, len, id, i;

		if (record) {
			if (record.hasId()) {
				return store.getById(record.getId());
			} else {
				records = store.data.items;
				//len = records.length;
				len = records ? records.length : 0;
				id = record.internalId;

				for (i = 0; i < len; ++i) {
					rec = records[i];
					if (id === rec.internalId) {
						return rec;
					}
				}
			}
		}
		return null;
	},
	storeHasSelected: function (record) {	//4.2.0
		var store = this.store,
			records,
			len, id, i;

		if (record.hasId() && store.getById(record))
		{
			return true;
		}
		else
		{
			records = store.data.items;
			//len = records.length;
			len = records ? records.length : 0;
			id = record.internalId;

			for (i=0; i<len; ++i)
			{
				if (id === records[i].internalId) {
					return true;
				}
			}
		}

		return false;
	}
});

/**
 * action column 관련 디버그
 * 그리드의 action column 아이콘 선택 시 그리드 선택: line 80
 */
Ext.grid.column.Action.override({
	processEvent: function (type, view, cell, recordIndex, cellIndex, e, record, row) {
		var me = this,
			target = e.getTarget(),
			match,
			item, fn,
			key = type == 'keydown' && e.getKey(),
			disabled;

		if (key && !Ext.fly(target).findParent(view.getCellSelector()))
		{
			target = Ext.fly(cell).down('.' + Ext.baseCSSPrefix + 'action-col-icon', true);
		}

		if (target && (match = target.className.match(me.actionIdRe)))
		{
			item = me.items[parseInt(match[1], 10)];
			disabled = item.disabled
				|| (item.isDisabled
					? item.isDisabled.call(
						item.scope
						|| me.origScope
						|| me, view, recordIndex, cellIndex, item, record)
					: false);

			if (item && !disabled)
			{
				if (type == 'click' || (key == e.ENTER || key == e.SPACE))
				{
					fn = item.handler || me.handler;

					if (fn)
					{
						fn.call(
							item.scope
							|| me.origScope
							|| me, view, recordIndex, cellIndex, item, e, record, row);
					}

					return false;
				}
				else if (type == 'mousedown' && item.stopSelection !== false)
				{
					return false;
				}
			}
		}

		return me.callParent(arguments);
	}
});

/*
 * CheckboxModel 관련 디버그
 * header의 체크박스 선택시 그리드의 itemclick 동작 하지 않음
 */
Ext.selection.CheckboxModel.override({
	onHeaderClick: function (headerCt, header, e) {
		if (header.isCheckerHd) {
			e.stopEvent();
			var me = this,
			isChecked = header.el.hasCls(Ext.baseCSSPrefix + 'grid-hd-checker-on');

			me.preventFocus = true;

			if (isChecked)
			{
				me.deselectAll();
				// 이벤트 등록
				me.fireEvent('deselectall', me);
			}
			else
			{
				me.selectAll();
				// 이벤트 등록
				me.fireEvent('selectall', me);
			}

			delete me.preventFocus;
		}
	}
});

/*
 * 웹서버 연결 함수 (아이피 변경, 재시작 시)
 * 내용: 웹서버 재기동, 아이피 변경시 웹페이비 연결 함수
 * 인자: postAddr(json = '{"protocol": "프로토콜", "address": "주소", "page": "페이지명", "httpPort": "http 포트", "httpsPort": "https 포트"}')
 */
function hostLocation(postAddr)
{
	var decoded = Ext.JSON.decode(postAddr);

	var protocol = decoded.protocol;
	var address = decoded.address;
	var page = decoded.page;
	var httpPort = decoded.httpPort;

	if (typeof(httpPort) == 'undefined' || httpPort == '')
		httpPort = '80';

	var httpsPort = decoded.httpsPort;
	var scriptTimestamp = Math.floor(new Date().getTime() / 1000);
	var imgObj = new Image();

	var src = "http://"+address+":"+httpPort+"/common/images/img_logo.png?t="+scriptTimestamp;
	var url;

	if (protocol == 'http')
		url = protocol+"://"+address+":"+httpPort;
	else if (protocol == 'https')
		url = protocol+"://"+address+":"+httpsPort;

	imgObj.src = src;
	imgObj.onload = function () { location.href = url; };
	imgObj.onerror = function () {
		setTimeout("hostLocation('"+postAddr+"');", 5000);
	};
};

/*
 * 메뉴얼 창 띄우기
 */
var winRef;
function manualWindowOpen(pmenu,id)
{
	var width = 1300;
	var height = 700;
	var left = (screen.width/2)-(width/2);
	var top = (screen.height/2)-(height/2);
	var opts = 'location=0, directoryies=0, staus=0, toolbar=0, memubar=0, scrollbars=1, resizable=0, width='+width+', height='+height+', top='+top+', left='+left;

	var url = '';

	if (typeof(pmenu) !== 'undefined' && typeof(id) !== 'undefined')
	{
		// create new, since none is open
		url = '../manual/' + $.cookie('language') + '#' + pmenu + '.xhtml' + id;
	}
	else
	{
		// create new, since none is open
		url = '../manual/' + $.cookie('language');
	}

	winRef = window.open(url, 'wind1');
}

/*
 * 프린트
 */
function printHTML(input)
{
	var agt = navigator.userAgent.toLowerCase();

	if (agt.indexOf("msie") != -1)
	{
		var iframePrint = document.createElement("iframe");

		iframePrint.name = "printAllContent";
		iframePrint.id = "printAllContent";
		document.body.appendChild(iframePrint);
		printAllContent.document.write(input.outerHTML);

		/** 인쇄실행 **/
		printAllContent.document.execCommand("Print");
		document.body.removeChild(iframePrint);
	}
	else
	{
		var iframe = document.createElement("iframe");

		document.body.appendChild(iframe);
		iframe.contentWindow.document.write(input.outerHTML);
		iframe.contentWindow.print();
		document.body.removeChild(iframe);
	}
};

/*
 * 메인 페이지로 이동
 */
function locationMain()
{
	location.href = $.cookie('gms_token') ? '/manager' : '/';
};

/*
 * json 데이터 이쁘게...
 */
if (!library) var library = {};

library.json = {
	replacer: function (match, pIndent, pKey, pVal, pEnd) {
		var key = '<span class=json-key>';
		var val = '<span class=json-value>';
		var str = '<span class=json-string>';
		var r = pIndent || '';

		if (pKey)
			r = r + key + pKey.replace(/[": ]/g, '') + '</span>: ';

		if (pVal)
			r = r + (pVal[0] == '"' ? str : val) + pVal + '</span>';

		return r + (pEnd || '');
	},
	prettyPrint: function (obj) {
		var jsonLine = /^( *)("[\w]+": )?("[^"]*"|[\w.+-]*)?([,[{])?$/mg;

		return "<pre>"+JSON.stringify(obj, null, 3)
				.replace(/&/g, '&amp;').replace(/\\"/g, '&quot;')
				.replace(/</g, '&lt;').replace(/>/g, '&gt;')
				.replace(jsonLine, library.json.replacer)+"</pre>";
	}
};

/**
 * exceptionDataCheck
 *
 * @description show message box if exception happend on Ajax request
 * @param exception {object} Ajax response
 * @returns {undefined}
 */
function exceptionDataCheck(exception)
{
	exception = Ext.JSON.decode(exception);

	/*
	 * TODO: validation for timedout
	 *
	 * aborted: undefined
	 * request: {id: 1, headers: {…}, options: {…}, async: true, binary: false, ...}
	 * requestId: 1
	 * responseText: "{}"
	 * status: 0
	 * statusText: "communication failure"
	 * timedout: true
	 * __proto__: Object
	 */

	/*
	if (typeof(exception.msg) != 'undefined'
			&& exception.msg != '')
	{
		Ext.MessageBox.show({
		title, _html_escape(exception.msg));
		});
	}
	*/
	if (typeof(exception.content) != 'undefined'
			&& exception.content != '')
	{
		Ext.MessageBox.show({
			title: exception.title,
			msg: _html_escape(exception.content),
			icon: Ext.MessageBox.ERROR,
			buttons: Ext.MessageBox.OK,
		});
	}
	//
	else if (!('response' in exception)
		|| typeof(exception.response) != 'object')
	{
		/*
		 * TODO: Unknown exception
		 */
		console.trace('Unknown exception: ', exception);

		Ext.MessageBox.show({
			title: exception.title,
			msg: _html_escape(exception.msg),
			icon: Ext.MessageBox.ERROR,
			buttons: Ext.MessageBox.OK,
		});
	}
	else if (typeof(exception.response.msg) != 'undefined'
		&& exception.response.msg != ''
		&& exception.response.msg != 'undefined')
	{
		Ext.MessageBox.show({
			title: exception.title,
			msg: _html_escape(exception.response.msg),
			icon: Ext.MessageBox.ERROR,
			buttons: Ext.MessageBox.OK,
		});
	}

	return;
};

function _html_escape(string)
{
	if (!string)
		return null;

	return string.replace(/(?:\\r\\n|\\r|\\n)/g, '<br>')
}

function exceptionDataDecode(value)
{
	return value != '' ? Ext.JSON.decode(value) : false;
};

/*
 * 주기적 호출 변수
 */

// 클러스터 관리-> 오버뷰
var _nowCurrentOverviewClstVar;
var _nowCurrentOverviewNodeVar;
var _nowCurrentOverviewEventVar;
var _nowCurrentOverviewChartVar;

// 노드 관리-> 노드 현황
var _nowCurrentConditionVar;
var _nowCurrentConditionEventVar;
var _nowCurrentConditionChartVar;

// 통합 모니터링 -> 시스템 현황: CPU 주기적 갱신
var _nowCurrentCpuVar;

// 통합 모니터링 -> 시스템 현황: MEMORY 주기적 갱신
var _nowCurrentMemoryVar;

// 통합 모니터링 -> I/O 현황: NETWORK 주기적 갱신
var _nowCurrentNetworkVar;

// 통합 모니터링 -> I/O 현황: 디스크 주기적 갱신
var _nowCurrentDiskVar;

// 통합 모니터링 -> 프로세스
var _nowCurrentProcessVar;

// 통합 모니터링 -> 서비스(CIFS)
var _monitoringServiceCifsVar;

// 통합 모니터링 -> 서비스(NFS)
var _monitoringServiceNfsVar;

// 시스템 관리-> 시간 설정: 현재 시간 주기적 갱신
var _nowCurrentTimerVar;

// 노드 스테이지 주기적 갱신
var _nowCurrentStageVar;

// 클러스터 노드 관리 갱신
var _nowCurrentclusterNodeVar;

// initializing 스테이지
var _nowCurrentInitStageVar;

// 로그 생성 확인 주기적 호출
var _nowCurrentLogExistVar;

// S.M.A.R.T. 테스트
var _nowCurrentSmartTestVar;

/** 노드 관리 node list 호출 유무 **/
var nodeListLoadExists = false;

/** Master 노드 IP **/
var MasterNodeUri = '';

/* 라이선스 목록 */
var licenseCheck;
var licenseADS;
var licenseSMB;
var licenseNFS;
var licenseNode;
var licenseVolumeSize;

/*
 * 내용 : 관리자 메뉴트리선택시 실행 함수
 */
function adminTabLoad(loadPage, callback)
{
	// 클러스터 노드 관리 갱신
	clearInterval(_nowCurrentclusterNodeVar);
	_nowCurrentclusterNodeVar = null;

	// 노드 스테이지 주기적 갱신
	clearInterval(_nowCurrentStageVar);
	_nowCurrentStageVar = null;

	// 시스템 상태 -> 통합 모니터링: CPU, 메모리 주기적 갱신
	clearInterval(_nowCurrentCpuVar);
	clearInterval(_nowCurrentMemoryVar);
	_nowCurrentCpuVar = null;
	_nowCurrentMemoryVar = null;

	// 통합 모니터링-> I/O 현황
	clearInterval(_nowCurrentNetworkVar);
	clearInterval(_nowCurrentDiskVar);
	_nowCurrentNetworkVar = null;
	_nowCurrentDiskVar = null;

	// 통합 모니터링 -> 프로세스
	clearInterval(_nowCurrentProcessVar);
	_nowCurrentProcessVar = null;

	// 통합 모니터링 -> 서비스(CIFS)
	clearInterval(_monitoringServiceCifsVar);
	_monitoringServiceCifsVar = null;

	// 통합 모니터링 -> 서비스(NFS)
	clearInterval(_monitoringServiceNfsVar);
	_monitoringServiceNfsVar = null;

	// 시스템 관리 -> 시간 설정: 현재 시간 갱신 중지
	clearInterval(_nowCurrentTimerVar);
	_nowCurrentTimerVar = null;

	// 오버뷰 -> 클러스터 상태
	clearInterval(_nowCurrentOverviewClstVar);
	_nowCurrentOverviewClstVar = null;

	clearInterval(_nowCurrentOverviewNodeVar);
	_nowCurrentOverviewNodeVar = null;

	// 오버뷰 -> 최근 이벤트
	clearInterval(_nowCurrentOverviewEventVar);
	_nowCurrentOverviewEventVar = null;

	// 오버뷰 -> 성능 통계
	clearInterval(_nowCurrentOverviewChartVar);
	_nowCurrentOverviewChartVar = null;

	// 노드별 현황 -> 노드 상태
	clearInterval(_nowCurrentConditionVar);
	_nowCurrentConditionVar = null;

	// 노드별 현황 -> 최근 이벤트
	clearInterval(_nowCurrentConditionEventVar);
	_nowCurrentConditionEventVar = null;

	// 노드별 현황 -> 성능 통계
	clearInterval(_nowCurrentConditionChartVar);
	_nowCurrentConditionChartVar = null;

	// 클러스터 관리 -> 로그 백업(주기적갱신)
	_nowCurrentLogExistVar;
	_nowCurrentLogExistVar = null;

	// S.M.A.R.T. test
	clearInterval(_nowCurrentSmartTestVar);
	_nowCurrentSmartTestVar = null;

	// grafana 챠트 제거
	if (loadPage != 'manager_cluster_overview')
	{
		if (Ext.getCmp('MCO_overviewCPUframe'))
			Ext.getCmp('MCO_overviewCPUChartSvg').remove(Ext.getCmp('MCO_overviewCPUframe'),true);

		if (Ext.getCmp('MCO_overviewNetworkframe'))
			Ext.getCmp('MCO_overviewNetworkChartSvg').remove(Ext.getCmp('MCO_overviewNetworkframe'),true);

		if (Ext.getCmp('MCO_overviewDiskIOframe'))
			Ext.getCmp('MCO_overviewDiskIOChartSvg').remove(Ext.getCmp('MCO_overviewDiskIOframe'),true);
	}

	if (loadPage != 'manager_node_condition')
	{
		if (Ext.getCmp('MNC_conditionCPUframe'))
			Ext.getCmp('MNC_conditionCPUNodeChartSvg').remove(Ext.getCmp('MNC_conditionCPUframe'),true);

		if (Ext.getCmp('MNC_conditionNetworkframe'))
			Ext.getCmp('MNC_conditionNetworkNodeChartSvg').remove(Ext.getCmp('MNC_conditionNetworkframe'),true);

		if (Ext.getCmp('MNC_conditionDiskIOframe'))
			Ext.getCmp('MNC_conditionStorageNodeChartSvg').remove(Ext.getCmp('MNC_conditionDiskIOframe'),true);
	}

	callback(loadPage);

	/*
	 * 클러스터 관리 >> 이벤트 작업 상태 아이콘
	 */
	GMS.Ajax.request({
		url: '/api/cluster/task/count',
		callback: function (options, success, response, decoded) {
			if (!success || !decoded.success)
				return;

			var errCnt = 0;
			var errDisplay = 'none;';
			var warnCnt = 0;
			var warnDisplay = 'none;';

			if (decoded.entity.err > 0)
			{
				errCnt = decoded.entity.err;
				errDisplay = 'inline;';
			}
			else if (decoded.entity.warn > 0)
			{
				warnCnt = decoded.entity.warn;
				warnDisplay = 'inline;';
			}

			Ext.getCmp('adminTreePanel').getStore()
				.getNodeById('manager_cluster_event')
				.set(
					"text",
					lang_common[20] + '&nbsp&nbsp;'
					+ "<span id='badgeEventTask' style='DISPLAY: " + errDisplay + "' class='badgeTask'>"
						+ errCnt
					+ "</span>"
					+ "<span id='badgeEventEvent' style='DISPLAY: " + warnDisplay + "' class='badgeEvent'>"
						+ warnCnt
					+ "</span>"
				);
		}
	});
};

/*
 * prefix_to_netmask
 *
 * @description Convert to decimal formatted netmask from CIDR netmask prefix
 * @param {string} prefix CIDR netmask prefix
 * @return {string} Decimal formatted netmask
 */
function prefix_to_netmask(prefix)
{
	var netmask = [];

	for (var i=0; i<4; i++)
	{
		var n = Math.min(prefix, 8);

		netmask.push(256 - Math.pow(2, 8-n));

		prefix -= n;
	}

	return netmask.join('.');
}


/**
 * netmask_to_prefix
 *
 * @description Convert to CIDR netmask prefix from decimal formatted netmask
 * @param {string} netmask Decimal formatted netmask
 * @returns {string} CIDR netmask prefix
 */
function netmask_to_prefix(netmask)
{
	var prefix   = 0;
	var splitted = netmask.match(/(\d+)/g);

	for (var i in splitted)
	{
		prefix += (((splitted[i] >>> 0).toString(2)).match(/1/g) || []).length;
	}

	return prefix;
}

/**
 * getChildComponents
 *
 * @description get child components
 * @param {array} selectors Array of selectors
 * @returns {items} child components which matched with the selectors
 */
function getChildComponents(selectors)
{
	var items = [];

	selectors.forEach(
		function (selector)
		{
			Ext.ComponentQuery.query('#me ' + selector)
				.forEach(function (v) { items.push(v); });
		}
	);

	return items;
}

function getDeviceType(model)
{
	if (!model.data.hasOwnProperty('Device'))
	{
		return null;
	}

	if (isBonding(model) && !isVLAN(model))
	{
		return 'bonding';
	}
	else if (isVLAN(model))
	{
		return 'vlan';
	}
	else
	{
		return 'device';
	}
}

function isBonding(model)
{
	return model.get('Device').match(/^bond/);
}

function isVLAN(model)
{
	return model.get('Device').match(/\.\d+$/);
}

function getDashboardURI(params)
{
	params = params || {
		ip: '127.0.0.1',
		port: 8890,
		name: 'anystor-cluster-graphs',
		panel_id: 1,
		from: 'now-24h',
		refresh: '10s',
	};

	if (params.ip == null
		|| typeof(params.ip) == 'undefined')
	{
		params.ip = '127.0.0.1';
	}

	if (params.port == null
		|| typeof(params.port) == 'undefined')
	{
		params.port = 8890;
	}

	var uri = 'http://' + params.ip + ':' + params.port
				+ '/dashboard-solo/db/' + params.name
				+ '?' + 'orgId=1'
				+ '&' + 'panelId=' + params.panel_id
				+ '&' + 'from=' + params.from
				+ '&' + 'refresh=' + params.refresh;

	return uri;
}

/*
 * Master node handling
 */

var MASTER = {
	host: null,
	online: false,
};

var ping_interval;

function ping(params)
{
	params = params || {
		protocol: window.location.protocol,
		host: window.location.host,
		port: window.location.port == '' ? 80 : window.location.port,
		path: '/common/images/img_logo.png',
		timeout: 1 * 1000,
		wait: 'none',
		callback: function (status) { alert('ping: ' + status); },
	};

	if (!'protocol' in params
		|| typeof(params.protocol) == 'undefined'
		|| params.protocol == null || params.protocol == '')
	{
		params.protocol = window.location.protocol.replace(':', '');
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

	if (!'path' in params
		|| typeof(params.path) == 'undefined'
		|| params.path == null || params.path == '')
	{
		params.path = 'common/images/img_logo.png';
	}

	if (!'timeout' in params
		|| typeof(params.timeout) == 'undefined'
		|| params.timeout == null || params.timeout == '')
	{
		params.timeout = 1 * 1000;
	}

	if (!'wait' in params
		|| typeof(params.wait) == 'undefined'
		|| params.wait == null || params.wait == '')
	{
		params.wait = 'none';
	}


	var interval;
	var dfd = Ext.create('Ext.ux.Deferred');

	var handler = function () {
		var timeout = setTimeout(
			function () {
				if ('callback' in params
					&& typeof(params.callback) == 'function')
				{
					params.callback(false);
				}

				if (params.wait == 'none')
				{
					dfd.promise().reject(params);
				}
				else if (params.wait == 'offline')
				{
					dfd.promise().resolve(params);
					clearInterval(interval);
				}
			},
			params.timeout,
		);

		var ts = Math.floor(new Date().getTime() / 1000);
		var img = new Image();
		var src = params.protocol + '://' + params.host

		src += ':' + params.port
		src += '/' + params.path + '?t=' + ts;

		img.src    = src;
		img.onload = function () {
			clearTimeout(timeout);

			if ('callback' in params
				&& typeof(params.callback) == 'function')
			{
				params.callback(true);
			}

			if (params.wait == 'none')
			{
				dfd.promise().resolve(params);
			}
			else if (params.wait == 'online')
			{
				dfd.promise().resolve(params);
				clearInterval(interval);
			}
		};
	};

	if (params.wait != 'none')
	{
		interval = setInterval(handler, params.timeout);
	}
	else
	{
		handler();
	}

	return dfd.promise();
}
