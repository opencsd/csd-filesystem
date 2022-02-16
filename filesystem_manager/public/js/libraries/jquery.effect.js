$.fn.extend({
	effect: {
		/**
		 설명: 특정 객체 disable
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id)
		ex: {"selectValue":"효과를 적용할 객체 id값", "type":"id"}' 
		**/
		effectDisable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", true);
		},
		/**
		 설명: 특정 객체 enable
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"효과를 적용할 객체 id값", "type":"id"}' 
		**/
		effectEnable: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", false);
		},
		/**
		 설명: 특정 객체 readonly
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id)
		ex: '{"selectValue":"효과를 적용할 객체 id값", "type":"id"}' 
		**/
		effectReadonly: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("readOnly", true);
		},
		/**
		 설명: 특정 객체 show
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id), speed(시간) ==> default(1000), callback(효과설정후 호출 함수) ==> default(null)
		ex : '{"selectValue":"효과를 적용할 객체 id값", "type":"id", "speed": 2000, "callback": callfunc}' 
		**/
		effectShow: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			jsonArgs['speed'] = jsonArgs['speed'] || 1000;
			jsonArgs['callback'] = jsonArgs['callback'] || null;
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').show(jsonArgs['speed'], jsonArgs['callback']);
		},
		/**
		 설명: 특정 객체 hide
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id), speed(시간) ==> default(1000), callback(효과설정후 호출 함수) ==> default(null)
		ex : '{"selectValue":"효과를 적용할 객체 id값", "type":"id", "speed": 2000, "callback": callfunc}' 
		**/
		effectHide: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			jsonArgs['speed'] = jsonArgs['speed'] || 1000;
			jsonArgs['callback'] = jsonArgs['callback'] || null;
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').hide(jsonArgs['speed'], jsonArgs['callback']);
		},
		/**
		 설명: 특정 객체 toggle
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id), speed(시간) ==> default(1000), callback(효과설정후 호출 함수) ==> default(null)
		ex : '{"selectValue":"효과를 적용할 객체 id값", "type":"id", "speed": 2000, "callback": callfunc}' 
		**/
		effectToggle: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			jsonArgs['speed'] = jsonArgs['speed'] || 1000;
			jsonArgs['callback'] = jsonArgs['callback'] || null;
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').toggle(jsonArgs['speed'], jsonArgs['callback']);
		},
		/**
		 설명: 특정 객체 슬라이드
		인자: ---------------------------- 할까 말까???
		**/
		/**
		 설명: 특정 객체 addClass
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id), class(추가할 클래스명)
		ex : '{"selectValue":"효과를 적용할 객체 id값", "type":"id", "class": "add class"}' 
		**/
		effectAddClass: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').addClass(jsonArgs['class']);
		},
		/**
		 설명: 특정 객체 removeClass
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id), class(제거할 클래스명)
		ex : '{"selectValue":"효과를 적용할 객체 id값", "type":"id", "class": "remove class"}' 
		**/
		effectRemoveClass: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').removeClass(jsonArgs['class']);
		},
		/**
		 설명: 특정 객체 toggleClass
		인자: effectObj(효과를 적용할 객체 id값), type('id', 'name','class') ==> default(id), class(토글할 클래스명)
		ex : '{"selectValue":"효과를 적용할 객체 id값", "type":"id", "class": "add class"}' 
		**/
		effectToggleClass: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['type'] = jsonArgs['type'] || "id";
			$('*['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').toggleClass(jsonArgs['class']);
		}			
	}
});
