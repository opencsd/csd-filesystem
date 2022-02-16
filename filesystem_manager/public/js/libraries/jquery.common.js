$.fn.extend({
	common: {
		/**
		설명: json 인자를 배열로 변경, 1차원배열만 사용
		**/
		jsonArguments: function(){
			var items = new Array();
			for(i=0; i<arguments.length; i++)
			{
				if(typeof arguments[i] == "object")
				{
					var jsonString = arguments[i][0];
					if(typeof jsonString == "string") jsonString = JSON.parse(jsonString);
				}
				else
				{
					var jsonString = arguments[i];
				}
				jQuery.each(jsonString, function(key, val) {
					items[key] = val;
				});
			}
			return  items;
		},
		/**
		 설명: 자바스크립트 파일 동적으로 호출
		인자: url(로드할 자바스크립트 파일경로), callback(파일 로드후 실행할 함수) ==> default(null)
		ex : '{"url":"로드할 자바스크립트 파일경로", "callback": funcName}'
		**/
		loadGetScript: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			jsonArgs['callback'] = jsonArgs['callback'] || null;
			/*$.getScript(jsonArgs['url'], function(data, textStatus, jqxhr) {
			});*/
			//$.getScript(jsonArgs['url'], jsonArgs['callback']);
			$.getScript(jsonArgs['url']).done(function(script, textStatus) {
				if(jsonArgs['callback'] != null) jsonArgs['callback']();
			}).fail(function(jqxhr, settings, exception) {
				alert(exception+'---'+jqxhr+'---'+settings);
			});
		}
		/**
		 설명: 특정 객체 disable
		인자:
		**/
		//disableObj: function ()

		//$('.someElement').attr('disabled', 'disabled');

		//return $('input:checkbox['+jsonArgs['type']+'="'+jsonArgs['selectValue']+'"]').prop("disabled", true);

		/**
		설명: 특정 객체 enable
		**/

		/**
		설명: ajax
		**/

		/**
		설명: cookie
		**/

		/**
		설명: 동적 페이지 호출
		**/

		/**
		설명: 레이어(모달)
		**/



	}
});

/**
ajax 호출시 기본 설정 정의
**/
$.ajaxSetup({
	type: 'POST'
	,async: true
	,cache: false
	,dataType: 'json'
	,timeout: 30000
	,contentType: "application/x-www-form-urlencoded"
});
/*
 $.cookie('werty', 'sunday');
 werty는 쿠키이름, sunday는 그에 대한 값을 넣는 것이다.

$.cookie('werty', 'ok', { expires: 7, path: '/', domain: 'werty.co.kr', secure: true });
expires : 만료일을 의미한다. 위 예제로 보면 7일동안 해당 쿠키를 유지한다는 이야기다.
path : 경로설정이다. 이 사이트의 모든 페이지가 해당된다면 / 이렇게 슬러시만 둔다. 그렇지 않고 특정 폴더라면 경로를 넣으면 된다.
domain : 쿠키가 적용될 도메인이다. 기본 설정은 쿠키가 만들어진 도메인이다.
secure : 기본 설정은 false로 되어있다. true/false 로 입력가능하며 true 일 경우 https 프로토콜만 적용된다.

 $.cookie('werty');
저장된 쿠키중에 werty의 값을 불러온다.

$.cookie('werty', null);
 쿠키를 지우는 방법은 아래와 같다.
*/
