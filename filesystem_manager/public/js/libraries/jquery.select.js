$.fn.extend({
	select: {
		/**
		설명:특정 셀렉트박스 선택된 값 확인
		인자: selectBoxObj(셀렉트박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"셀렉트박스의 id값", "type":"id"}'
		**/
		selectBoxSelectValue: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			var items = new Array();
			$("select["+jsonArgs['type']+"='"+jsonArgs['selectValue']+"']").each(function(){
				items.push($(this).val());
			});
			return items.toString();
		},
		/**
		 설명:특정 셀렉트박스 값설정
		인자: selectBoxObj(셀렉트박스의 id값), selectValue(셀렉트박스 지정값)
		ex: '{"selectValue":"셀렉트박스의 id값", "type":"id","setValue":"설정할값"}'
		**/
		selectBoxSetValue: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$("select["+jsonArgs['type']+"='"+jsonArgs['selectValue']+"']").val(jsonArgs['setValue']);
		}
	}
});

