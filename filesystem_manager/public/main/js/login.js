function login_submit()
{
	$('#loginError')
		.removeClass('checkError')
		.removeClass('PwcheckError')
		.removeClass('IdcheckError');

	$('#loginError').html('');

	// 전송 데이터
	var userid = document.getElementById('memberid').value;
	var passwd = document.getElementById('passwd').value;

	// input, button 포커스 제거
	$('#memberid').blur();
	$('#passwd').blur();
	$('#login_button').blur();

	// 아이디, 패스워드 문자열 체크
	var validateid = { vc_userid: userid };
	var validatepw = { vc_userpw: passwd };

	if ($(this).validation.vc_userid(validateid) == false)
	{
		$('#loginError')
			.removeClass('checkError')
			.removeClass('PwcheckError')
			.addClass('IdcheckError');

		$('#loginError').html(loginUserIDValidate);

		return false;
	}

	if ($(this).validation.vc_userpw(validatepw) == false)
	{
		$('#loginError')
			.removeClass('checkError')
			.removeClass('IdcheckError')
			.addClass('PwcheckError');

		$('#loginError').html(loginUserPwValidate);

		return false;
	}

	var remember = document.getElementById('remember').checked ? 'Y' : 'N';
	var rsa = new JSEncrypt();

	rsa.setPublicKey(atob(decodeURI($.cookie('signing_key'))));

	passwd = rsa.encrypt(passwd);

	var postData = {
		ID: userid,
		Password: passwd,
	};

	$('#loginModal').css('display', 'block');

	if ($.cookie('language') == 'ko')
	{
		$('#loginLoading').addClass('loader');
		$('#loginLoading').html('로그인 중입니다.');
	}
	else
	{
		$('#loginLoading').addClass('loader');
		$('#loginLoading').html('You are logging in.');
	}

	// 로그인 실행
	$.ajax({
		url: '/api/manager/sign_in',
		contentType: 'application/json; charset=utf-8',
		dataType: 'json',
		data: JSON.stringify(postData),
		timeout: 60 * 1000,
		success: function (data, status, jqxhr) {
			$('#loginModal').css('display', 'none');
			$('#loginLoading').removeClass('loader');
			$('#loginLoading').html('');

			if (!data.success)
			{
				$('#loginError')
					.removeClass('IdcheckError')
					.removeClass('PwcheckError')
					.addClass('checkError');

				$('#loginError').html(data.msg);

				return false;
			}

			$.cookie(
				'gms_token',
				data.entity.token,
				{
					expires: 1,
					path: '/'
				}
			);

			if (remember == 'Y')
			{
				$.cookie(
					'remember',
					remember,
					{
						expires: 30,
						path: '/',
					}
				);

				$.cookie(
					'memberid',
					userid,
					{
						expires: 30,
						path: '/',
					}
				);
			}
			else
			{
				$.cookie(
					'remember',
					"",
					{
						expires: 0,
						path: '/',
					}
				);

				$.cookie(
					'memberid',
					"",
					{
						expires: 0,
						path: '/'
					}
				);
			}

			switch (data.stage_info.stage)
			{
				case 'installed':
					location.replace('./config');
					break;
				case 'configured':
					location.replace('./init');
					break;
				default:
					location.replace('./manager');
					break;
			}

			return true;
		},
		error: function (jqxhr, status, errorMsg) {
			$('#loginModal').css('display', 'none');
			$('#loginLoading').removeClass('loader');
			$('#loginLoading').html('');

			$('#loginError')
				.removeClass('IdcheckError')
				.removeClass('PwcheckError')
				.addClass('checkError');

			$('#loginError').html(loginFalse);

			return false;
		}
	});
};

// 언어 선택 변경
var languageChange = {
	setLanguage: function () {
		listObj = arguments[0];
		$.cookie('language', listObj.value, { expires: 365, path: '/' });
		location.reload(true);
	}
};


// 언어 선택
var initLogin = function ()
{
	// 언어 쿠키 값에 따른 언어 선택
	this.getLangValue = $.cookie('language');

	// 셀렉트 박스 설정 값
	this.loginSetLang = { 'selectValue': 'langSelectBox', 'type': 'id', 'setValue': getLangValue };

	// 현재 언어 표시
	$(this).select.selectBoxSetValue(loginSetLang);

	// 아이디 저장 쿠키 값에 따른 선택 체크
	this.getRememberValue = $.cookie('remember');

	if (this.getRememberValue != 'Y')
	{
		$('#memberid').focus();
		return;
	}

	// 체크 박스 설정 값: 아이디 저장 체크 박스 선택
	this.loginSetRemember = {'selectValue': 'remember', 'type': 'id'};

	$(this).check.checkSelect(loginSetRemember);

	// text 박스 설정 값: 아이디 값 내용 출력
	this.getuseridValue = $.cookie('memberid');
	this.loginSetUserid = {'selectValue': 'memberid', 'type': 'id','setValue': getuseridValue};

	if (typeof(getuseridValue) != 'undefined')
	{
		$('#memberid').removeClass('input_ID').addClass('input_NONE');
		$('#passwd').focus();
		$(this).text.textSetVal(loginSetUserid);
	}
	else
	{
		$('#memberid').removeClass('input_ID').addClass('input_NONE');
		$('#memberid').focus();
	}

	if ($.cookie('signing_key') == null)
	{
		$.ajax({
			url: '/',
			type: 'GET',
			dataType: 'html',
			complete: function () {
				if ($.cookie('signing_key') == null)
				{
				}

				return;
			},
		});
	}
};

$(document).ready(
	function () {
		// 아이디 텍스트 박스 이벤트
		$('#memberid')
			.focusout(
				function () {
					if ($(this).val().length > 0)
					{
						$('#memberid')
							.removeClass('input_ID')
							.addClass('input_NONE');
					}
					else
					{
						$('#memberid')
							.removeClass('input_NONE')
							.addClass('input_ID');
					}
				}
			)
			.focusin(
				function () {
					$('#memberid')
						.removeClass('input_ID')
						.addClass('input_NONE');
				}
			);

		// 패스워드 텍스트 박스 이벤트
		$('#passwd')
			.focusout(
				function () {
					if ($(this).val().length > 0)
					{
						$('#passwd')
							.removeClass('input_PW')
							.addClass('input_NONE');
					}
					else
					{
						$('#passwd')
							.removeClass('input_NONE')
							.addClass('input_PW');
					}
				}
			)
			.focusin(
				function () {
					$('#passwd')
						.removeClass('input_PW')
						.addClass('input_NONE');
				}
			);

		// 아이디 엔터 이벤트
		$('#memberid').keydown(
			function (e) {
				if (e.keyCode == 13)
					login_submit();
			}
		);

		// 패스워드 엔터 이벤트
		$('#passwd').keydown(
			function (e) {
				if (e.keyCode == 13)
					login_submit();
			}
		);

		// 쿠키값 적용 선택
		initLogin();
	}
);
