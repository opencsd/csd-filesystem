# Library: Common::ArgCheck

## 인덱스

#### 1. [is_argument_type](#1-is_argument_type-1)
#### 2. [check_arguments](#2-check_arguments-1)

## 개요

* 함수 외부에서 들어오는 Argument의 데이터 타입을 간단히 체크하는 기능을 제공하는 Library

##  목록

### 1. is_argument_type

* 대상 Argument가 예상한 데이터 타입이 맞는지 확인하는 함수
* 예상 타입으로 쓸 수 있는 문자는 다음과 같다 (대소문자 상관 없음)

> hash: Hash 타입
>
> string: String 타입
>
>   network_address_string: 네트워크 주소 스타일의 String 타입 Ex) xx.xx.xx.xx
>
>   not_empty_string: 빈 값('')을 허용하지 않는 String 타입
>
> scalar: Scalar 타입
> 
> array: Array 타입
>
>   not_empty_array: 비어있는 array([] or [''])를 허용하지 않는 Array 타입
>
> number: Number 타입
>
>   non_zero_number: 0을 허용하지 않는 Number 타입
>
> optional: 필수가 아닌 타입
>
> undef 일 때는 별다른 타입 검사를 하지 않지만 무엇인가 정의 되어 있으면 optional과 함께 정의된 타입이 맞는지 확인
>
> Ex) 'string|optional'

 * 예상 타입을 여러개 지정할 때 구분자는 무엇이든 상관없다

  * hash|string|optional => ok
  * scalar string => ok
  * array,string,hash => ok
  * arraystring => ok
  * scalar or hash or array => ok
  * optional array

> #### 인자값
> Argument   | Description                   | Type   | Required   |
> --------   | -----------                   | :----: | :--------: | 
> **FIRST**  | 예상 타입(복수 선택 가능)     | String | Y          | 
> **SECOND** | 대상 Argument                 | Any    | Y          | 
> 
> * * *
> 
> #### 결과값: Integer
> Argument     | Description                                              | Type    |
> --------     | -----------                                              | :-----: |
> **RETURN**   | 판단 결과, 대상 Argument가 예상 타임이 맞으면 1 아니면 0 | Integer |
>
> * * *
>
> #### 예제
> ```perl
> use Common::ArgCheck qw /is_argument_type/;
> 
> sub Func
> {
>     my $aaa = shift;
>     my $bbb = shift;
>     if(is_argument_type('Hash', $aaa)){
>         print "aaa는 hash 입니다.";
>     }
>     else{ print "aaa는 hash가 아닙니다."; }
>
>     if(is_argument_type('array,string', $bbb)){
>         print "bbb는 array 이거나 string 형태입니다.";
>     }
> }
> ```

* * *

### 2. check_arguments

* 대상 Argument가 예상한 형태가 맞는지 확인하는 함수
* 예상 타입으로 쓸 수 있는 문자는 is_argument_type에서 지원하는 것과 같다
* 사용자가 정의한 Argument(이하 Reference Argument)의 예상 형태와 실제 받은 Argument를 같이 주면
  실제 받은 Argument 중에 Reference Argument와 맞지 않는 부분(invalid)에 대한 정보를 ArrayRef(pointer)에 담아 전달
* $arg->{aaa}{bb}{c}와 $arg->{aaa}{dddd}가 Reference Argument와 맞지 않으면 ['aaa/bb/c','aaa/dddd']와 같은 ArrayRef를 반환(return)함
* 모든 Argument가 Reference Argument와 타입이 맞으면 빈 ArrayRef([])를 반환함
* check_arguments_return_invalid_items을 호출해도 같은 일을 함

> #### 인자값
> Argument   | Description                            | Type    | Required   |
> --------   | -----------                            | :----:  | :--------: | 
> **FIRST**  | 예상 Argument 형태(Reference Argument) | HashRef | Y          | 
> **SECOND** | 대상 Argument                          | Any     | Y          | 
> 
> * * *
> 
> #### 결과값: ArrayRef
> Argument     | Description                                            | Type     |
> --------     | -----------                                            | :----:   |
> **RETURN**   | 판단 결과, Reference Argument와 맞지 않는 argumnt 목록 | ArrayRef |
>
> * * *
>
> #### 예제
> ```perl
> use Common::ArgCheck qw /check_arguments/;
> 
> sub Func
> {
>     my $args = shift;
>     my $reference = {
>         Network => {
>             Service => {
>                 Slaves => 'array',
>                 Mode   => 'number',
>             },
>             Storage => {
>                 Slaves  => 'array',
>                 Mode    => 'number',
>                 Ipaddr  => 'network_address_string',
>                 Netmask => 'network_address_string',
>             },
>             Management => {
>                 Interface => 'string',
>                 Ipaddr    => 'network_address_string|optional',
>                 Netmask   => 'network_address_string|optional',
>             },
>         },
>         Volume => {
>             Base_Pvs => 'not_empty_array',
>             Tier_Pvs => 'array|optional',
>         },
>     };
>
>     my @invalid = @{check_arguments($reference, $args)};
>     if(scalar(@invalid) ne 0){
>         printf ( "Some argument(s) is wrong!(%s)\n", join(',',@invalid) );
>         return -1;
>     }
>
>     return 0;
> }
> ```

* * *

