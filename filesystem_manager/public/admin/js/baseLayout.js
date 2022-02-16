// 기본 판넬
Ext.define(
	'BasePanel',
	{
		extend: 'Ext.panel.Panel',
		alias: 'widget.BasePanel',
		overflowX: 'hidden',
		overflowY:'auto',
		bodyStyle: 'padding: 15px;',
		border: false,
		viewConfig: { forceFit: true },
		//ui: 'm-content',
		bodyCls: 'm-panelbody',
		autoScroll: false,
	}
);

// 기본 폼
Ext.define(
	'BaseFormPanel',
	{
		extend: 'Ext.form.Panel',
		alias: 'widget.BaseFormPanel',
		defaultType: 'textfield',
		fieldDefaults: { labelWidth: 130 },
		bodyStyle: 'padding: 25px 30px 30px 30px;',
		overflowX: 'hidden',
		overflowY:'auto',
		frame: true,
		border: false,
		viewConfig: { forceFit: true },
		//ui: 'm-content',
		bodyCls: 'm-panelbody',
	}
);

// 기본 윈도우(팝업창)
Ext.define(
	'BaseWindowPanel',
	{
		extend: 'Ext.window.Window',
		alias: 'widget.BaseWindowPanel',
		overflowX: 'hidden',
		overflowY:'auto',
		resizable: false,
		closeAction: 'hide',
		maximizable: false,
		modal: true,
		bodyCls: 'm-panelbody',
		constrain: true,
		viewConfig: { forceFit: true },
	}
);

// 기본 그리드
Ext.define(
	'BaseGridPanel',
	{
		extend: 'Ext.grid.Panel',
		alias: 'widget.BaseGridPanel',
		multiSelect: true,
		selModel: { allowDeselect: true },
		frame: true,
		stripeRows: true,
		columnLines: true,
		scroll: 'vertical',
		autoScroll: false,
		viewConfig: { forceFit: true, loadMask: false },
		//ui: 'm-content',
		bodyCls: 'm-panelbody',
	}
);

// 기본 스토어
Ext.define(
	'BaseStore',
	{
		extend: 'Ext.data.Store',
		actionMethods: { read: 'POST' },
		proxy: {
			type: 'ajax',
			reader: {
				type: 'json',
				root: 'data',
				totalProperty: 'totalCount'
			}
		},
	}
);

/* buffer store */
Ext.define(
	'BaseBufferStore',
	{
		extend: 'Ext.data.Store',
		actionMethods: { read: 'POST' },
		buffered: true,
		remoteFilter: true,
		remoteSort: true,
		leadingBufferZone: 26,
		trailingBufferZone: 26,
		purgePageCount: 0,
		pageSize: 21,
		sortOnLoad: true,
	}
);

// 기본 combo
Ext.define(
	'BaseComboBox',
	{
		extend: 'Ext.form.ComboBox',
		alias: 'widget.BaseComboBox',
		triggerAction:'all',
		queryMode: 'local',
		editable:false,
		typeAhead: true,
	}
);

// 파일 다운로드
Ext.define(
	'BaseFileDownload',
	{
		extend: 'Ext.Component',
		alias: 'widget.FileDownloader',
		autoEl: {
			tag: 'iframe',
			cls: 'x-hidden',
			src: Ext.SSL_SECURE_URL
		},
		load: function (config) {
			var e = this.getEl();
			e.dom.src = config.url + (config.params ? '?' + Ext.urlEncode(config.params) : '');
			e.dom.onload = function() {
				// 예외 처리 내용 확인
				if (typeof(e.dom.contentDocument.body.childNodes[0]) != 'undefined'
					&& typeof(e.dom.contentDocument.body.childNodes[0].data) != 'undefined')
				{
					var downloadException = Ext.decode(e.dom.contentDocument.body.childNodes[0].data);

					if (downloadException.success == false)
					{
						Ext.Msg.show({
							title: lang_admin[4],
							msg: downloadException.msg,
							buttons: Ext.Msg.OK,
							icon: Ext.MessageBox.ERROR
						});

						if (downloadException.code)
						{
							// 예외 처리에 따른 동작
							Ext.MessageBox.show({
								title: lang_admin[4],
								msg: downloadException.msg,
								buttons: Ext.MessageBox.OK,
								fn: function() { locationMain(); }
							});
						}
					}
				}
				else if (typeof(e.dom.contentDocument.body.childNodes[0]) == 'undefined'
						|| e.dom.contentDocument.body.childNodes[0].wholeText == '404')
				{
					Ext.Msg.show({
						title: lang_admin[4],
						msg: lang_admin[5],
						buttons: Ext.Msg.OK,
						icon: Ext.MessageBox.ERROR
					});
				}
			}
		}
	},
);

// 기본 드래그 & 드롭 그리드 - 레이아웃
Ext.define(
	'BaseGridToGridLayout',
	{
		extend: 'Ext.container.Container',
		alias: 'widget.BaseGridToGridLayout',
		layout: { type: 'hbox', align: 'stretch' },
	}
);

// 기본 드래그 & 드롭 그리드 - item 그리드
Ext.define(
	'BaseGridToGrid',
	{
		extend: 'Ext.grid.Panel',
		alias: 'widget.BaseGridToGrid',
		frame: true,
		multiSelect: true,
		stripeRows: true,
		columnLines: true,
		//style: { marginBottom: '20px' },
		margins: '0 5 0 0',
		viewConfig: {
			plugins: {
				ptype: 'gridviewdragdrop'
			},
		},
	}
);

// 기본 버튼

// 기본 챠트

// 기본 레이아웃 확장

// 기본 마법사 타이틀 판넬
Ext.define(
	'BaseWizardTitlePanel',
	{
		extend: 'Ext.panel.Panel',
		alias: 'widget.BaseWizardTitlePanel',
		overflowX: 'hidden',
		overflowY:'auto',
		bodyCls: 'm-wizard-title',
		border: false,
		viewConfig: { forceFit: true },
		layout: 'fit',
	}
);

// 기본 마법사 컨텐츠 판넬
Ext.define(
	'BaseWizardContentPanel',
	{
		extend: 'Ext.panel.Panel',
		alias: 'widget.BaseWizardContentPanel',
		overflowX: 'hidden',
		overflowY:'auto',
		bodyCls: 'm-wizard-content',
		border: false,
		viewConfig: { forceFit: true },
		layout: 'vbox',
	}
);

// 기본 마법사 사이드 판넬
Ext.define(
	'BaseWizardSidePanel',
	{
		extend: 'Ext.panel.Panel',
		alias: 'widget.BaseWizardSidePanel',
		overflowX: 'hidden',
		overflowY:'auto',
		bodyCls: 'm-wizard-side',
		viewConfig: { forceFit: true },
		layout: { type: 'vbox', align: 'stretch' },
		width: 180,
		height: 550,
		autoHeight: true,
	}
);

// 기본 마법사 설명 판넬
Ext.define(
	'BaseWizardDescPanel',
	{
		extend: 'Ext.panel.Panel',
		alias: 'widget.BaseWizardDescPanel',
		overflowX: 'hidden',
		overflowY:'auto',
		bodyCls: 'm-wizard-desc',
		border: false,
		autoScroll: false,
		viewConfig: { forceFit: true },
		layout: { type: 'vbox', align: 'stretch' },
	}
);
