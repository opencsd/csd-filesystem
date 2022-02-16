/**
JQUERY, EXTJS의 확장 함수 아님
일반 공통 함수로 사용
JQUERY, EXTJS에서도 호출 가능 한 공통 함수, 변수 내용
*/

/**
공통 변수
*/

// validation 체크

// 아이디 검사
var vc_userid = /^[a-z0-9_-]{3,16}$/;

// 패스워드 검사
var vc_userpw = /^[a-z0-9_-]{3,16}$/;

/**
공통 함수
**/

/**
json 객체를 배열로 리턴
인자: Object Arguments, {"name":"language"}, [{"name":"language"},{"name":"remember"}]
return: array
**/
/*
var jsonArguments = new function() {
	this.returnVal: []
	,this.returnArray: []
	,this.jsonArgumentsValue: arguments
}
*/
function jsonArguments()
{
	var returnVal = [], returnArray = [];
	var jsonArgumentsValue =  arguments;
	for(var argObject in jsonArgumentsValue)
	{
		var jsonArgumentsValueObj = jsonArgumentsValue[argObject];
		//if(jsonArgumentsValueObj.constructor == Array)
		if(Array.isArray(jsonArgumentsValueObj) == true)
		{
			for (var keyObject in jsonArgumentsValueObj)
			{
				var objValue = jsonArgumentsValueObj[keyObject];

				for (var keyValue in objValue)
				{
					returnArray[keyValue] = objValue[keyValue];
				}
				returnVal.push(returnArray);
			}
		}
		else
		{
			for (var keyObject in jsonArgumentsValueObj)
			{
				returnVal[keyObject] = jsonArgumentsValueObj[keyObject];
			}
		}
	}
	return returnVal;
};

/**
쿠키 값 가져오기
인자: {"name":"language"}, [{"name":"language"},{"name":"remember"}]
return: array
**/
function commonGetCookie()
{
	var returnVal = [];
	var jsonArgumentsValue =  arguments;
	for(var argObject in jsonArgumentsValue)
	{
		var jsonArgumentsValueObj = jsonArgumentsValue[argObject];
		if(Array.isArray(jsonArgumentsValueObj) == true)
		{
			for (var keyObject in jsonArgumentsValueObj)
			{
				var objValue = jsonArgumentsValueObj[keyObject];
				var cookieName =objValue['name'];
				var nameEQ = cookieName + "=";
				var ca = document.cookie.split(';');
				for(var i=0;i < ca.length;i++)
				{
					var c = ca[i];
					while (c.charAt(0)==' ') c = c.substring(1,c.length);
					if (c.indexOf(nameEQ) == 0)
					{
						returnVal[cookieName] = c.substring(nameEQ.length,c.length);
					}
				}
			}
		}
		else
		{
			var cookieName = jsonArgumentsValueObj['name'];
			var nameEQ = cookieName + "=";
			var ca = document.cookie.split(';');
			for(var i=0;i < ca.length;i++)
			{
				var c = ca[i];
				while (c.charAt(0)==' ') c = c.substring(1,c.length);
				if (c.indexOf(nameEQ) == 0)
				{
					returnVal[cookieName] = c.substring(nameEQ.length,c.length);
				}
			}
		}
	}
	return returnVal;
};

/**
쿠키 값 설정하기
인자: {"name":"language","value":"ko","expires":"365"}, [{"name":"language","value":"ko","expires":"365"},{"name":"remember","value":"Y","expires":"365"}]
return: void
**/
function commonSetCookie()
{
	var jsonArgumentsValue = arguments;

	for (var argObject in jsonArgumentsValue)
	{
		var today = new Date();
		var expire=new Date();
		var jsonArgumentsValueObj = jsonArgumentsValue[argObject];

		if (Array.isArray(jsonArgumentsValueObj) == true)
		{
			for (var keyObject in jsonArgumentsValueObj)
			{
				var objValue = jsonArgumentsValueObj[keyObject];
				var name;
				var value;
				var expires;

				for (var keyValue in objValue)
				{
					if (keyValue == 'name')
						name = objValue[keyValue];

					if (keyValue == 'value')
						value = objValue[keyValue];

					if (keyValue == 'expires')
						expires = objValue[keyValue];
				}

				expire.setDate(expire.getDate() + parseInt(expires));
				document.cookie=name+"="+escape(value)+";path=/;expires="+expire.toGMTString();
			}
		}
		else
		{
			expire.setDate(expire.getDate() + parseInt(jsonArgumentsValueObj['expires']));
			document.cookie=jsonArgumentsValueObj['name']+"="+escape(jsonArgumentsValueObj['value'])+";path=/;expires="+expire.toGMTString();
		}
	}
};

/**
용량 변환 함수
byte를 용량에 따라 b, kb, mb, gb, tb로 계산하여 리턴
@param int bytes  * @return String
**/
function byteConvertor(bytes)
{
	bytes = parseInt(bytes);
	var s = ['bytes', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
	var e = Math.floor(Math.log(bytes)/Math.log(1024));
	if(e == "-Infinity") return "0 "+s[0];
	else return (bytes/Math.pow(1024, Math.floor(e))).toFixed(2)+" "+s[e];
};

/*
 * RSA Encryption
 */
function gms_encrypt(plain)
{
	var rsa = new JSEncrypt();

	var claims = jwt_decode($.cookie('gms_token'));

	if (!('public_key' in claims))
	{
		console.error('public_key does not exists in the token');
		return null;
	}

	rsa.setPublicKey(claims.public_key);

	return rsa.encrypt(plain);
}
