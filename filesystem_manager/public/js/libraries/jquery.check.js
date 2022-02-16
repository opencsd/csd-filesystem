$.fn.extend({
	check: {
		/**
		설명: 특정 체크박스 선택된 값 확인
		인자: selectValue(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkSelectVal: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			var items = new Array();
			$('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]:checked').each(function(){
				items.push($(this).val());
			});
			return  items.toString();
		},
		/**
		설명: 특정 체크박스 선택
		인자: selectValue(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkSelect: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("checked", true);
		},
		/**
		설명: 특정 체크박스 해제
		인자: checkObj(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkUnSelect: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("checked", false);
		},
		/**
		설명: 특정 체크박스 enable
		인자: checkObj(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkEnable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", false);
		},
		/**
		설명: 특정 체크박스 disable
		인자: checkObj(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkDisable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", true);
		},
		/**
		설명: 체크박스 전체 선택개수
		인자: checkObj(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkSelectCount: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			return $('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]:checked').length;
		},
		/**
		설명: 체크박스선택 유무
		인자: checkObj(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		checkIsSelect: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			if($('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').is(':checked') == true)
			{
				return true;
			}
			else
			{
				return false;
			}
		},
		/**
		설명: 체크박스 전체선택 반전
		인자: allCheckId(전체선택 check box ID), checkObj(체크박스의 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"체크박스의 id값", "type":"id"}'
		**/
		//리스트의 체크박스 선택시 정체 체크박스의 표시 여부 조정...
		checkAllSelect: function (checkObj) {
			var type = type || "id";
			if($('input:checkbox[id="'+allCheckId+'"]').is(':checked') == true) // -- 관려내용 수정 인자를 어떻게....--------------------------------------
			{
				$('input:checkbox['+type+'="'+checkObj+'"]').prop("checked", true);
			}
			else
			{
				$('input:checkbox['+type+'="'+checkObj+'"]').prop("checked", false);
			}
		}
	}
});
