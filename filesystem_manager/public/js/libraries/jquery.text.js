$.fn.extend({
	text: {
		/**
		설명: 특정 텍스트박스 선택된 값 확인
		인자: selectValue(텍스트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"텍스트박스의 id값", "type":"id"}'
		**/
		textSelectVal: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			var items = new Array();
			$('input:text['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]:texted').val(); //texted---------------??
			return  items.toString();
		},
		/**
		설명: 특정 텍스트박스 선택
		인자: selectValue(텍스트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"텍스트박스의 id값", "type":"id","setValue":"설정할값"}'
		**/
		textSetVal: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:text['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').val(jsonArgs['setValue']);
		},
		/**
		설명: 특정 텍스트박스 enable
		인자: textObj(텍스트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"텍스트박스의 id값", "type":"id"}'
		**/
		textEnable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:text['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", false);
		},
		/**
		설명: 특정 텍스트박스 disable
		인자: textObj(텍스트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"텍스트박스의 id값", "type":"id"}'
		**/
		textDisable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:text['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", true);
		},
		/**
		설명: 특정 텍스트박스 readonly enabled
		인자: textObj(텍스트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"텍스트박스의 id값", "type":"id"}'
		**/
		textReadonlyOn: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:text['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("readonly", true);
		},
		/**
		설명: 특정 텍스트박스 readonly disabled
		인자: textObj(텍스트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"텍스트박스의 id값", "type":"id"}'
		**/
		textReadonlyOff: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:text['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("readonly", false);
		}
	}
});
