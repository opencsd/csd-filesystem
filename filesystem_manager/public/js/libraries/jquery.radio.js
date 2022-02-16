$.fn.extend({
	radio: {
		/**
		설명:특정 레디오버튼 선택된 값 확인
		인자: radioObj(레디오버튼의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"레디오버튼의 id값", "type":"id"}'
		**/
		radioSelectVal: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			var items = new Array();
			$('input:radio['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]:checked').each(function(){
				items.push($(this).val());
			});
			return items.toString();
		},
		/**
		설명: 특정 레디오버튼 선택
		인자: radioObj(레디오버튼의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"레디오버튼의 id값", "type":"id"}'
		**/
		radioSelect: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:radio['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("checked", true);
		},
		/**
		설명: 특정 레디오버튼 해제
		인자: radioObj(레디오버튼의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"레디오버튼의 id값", "type":"id"}'
		**/
		radioUnSelect: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:radio['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("checked", false);
		},
		/**
		설명: 특정 레디오버튼 enable
		인자: radioObj(레디오버튼의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"레디오버튼의 id값", "type":"id"}'
		**/
		radioEnable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:radio['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", false);
		},
		/**
		설명: 특정 레디오버튼 disable
		인자: radioObj(레디오버튼의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"레디오버튼의 id값", "type":"id"}'
		**/
		radioDisable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:radio['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", true);
		},
		/**
		설명: 레디오버튼 전체 선택개수
		인자: radioObj(레디오버튼의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"레디오버튼의 id값", "type":"id"}'
		**/
		radioSelectCount: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:radio['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]:checked').length;
		}
	}
});
