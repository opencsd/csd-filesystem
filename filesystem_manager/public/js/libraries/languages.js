Ext.namespace('Ext.ux');

Ext.ux.languages = [
	['en', 'en'],
	['ko', 'ko'],
];

/*
Ext.define(Ext.ux.langData = [
	['en', 'en'],
	['ko', 'ko']
];

Ext.ux.langCombo = Ext.create('Ext.form.field.ComboBox', {
	store: Ext.ux.langData,
	displayField: 'language',
	queryMode: 'local',
	emptyText: 'Select a language...',
	hideLabel: true,
	listeners: {
		select: {
			fn: function(cb, records) {
				var record = records[0];
				window.location.search = Ext.urlEncode({"lang":record.get("code")});
			},
			scope: this
		}
	}
});
*/
