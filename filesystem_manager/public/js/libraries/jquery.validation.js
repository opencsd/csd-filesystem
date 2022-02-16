$.fn.extend({
	validation: {
		/**
		설명: 문자열 체크
		인자: 문자열 {"vc_userid": "idvalue"}
		return: true, false
		**/
		//사용자 아이디
		vc_userid: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			var regx = /^[a-zA-Z]{1}[a-zA-Z0-9_]{3,20}$/;
			return regx.test(jsonArgs['vc_userid']);
		}
		//사용자 패스워드
		,vc_userpw: function(){
			var jsonArgs = $(this).common.jsonArguments(arguments);
			var regx = /^[a-zA-Z0-9\ \~\!\@\#\$\%\^\&\*\(\)\_\+\|\}\{\"\:\?\>\<\`\[\]\;\'\,\.\/]{4,20}$/;
			return regx.test(jsonArgs['vc_userpw']);
		}
	}
});
