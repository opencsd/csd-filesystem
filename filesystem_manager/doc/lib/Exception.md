# Library: Common::Exception

## 인덱스

#### 1. [handle_exception](#1-handle_exception-1)

## 개요

* try-catch 구조에서 예외 상황이 발생했을 때 이를 간단하게 처리하는 기능을 제공
* Try::Tiny or TryCatch 등 try-catch 구조를 사용할 수 있도록 하는 라이브러리가 필수로 요구됨

##  목록

### 1. handle_exception

* 예외 상황 발생시 예외 메시지를 로그에 남기고 프로시져를 종료하는 함수
* 메시지의 형태는 다음과 같다.

 * [Thu Mar 23 13:40:22 KST 2017] exception!! in "Block::DeviceInfo::_choose_block_devices_to_display" at /usr/gms/libgms/Block/DeviceInfo.pm line 141.
 * [`date`] `Exception Message` in `Function Name` at `File Name` line ###

> #### 인자값
> Argument   | Description            | Type   | Required   |
> --------   | -----------            | :----: | :--------: | 
> **FIRST**  | Exception Message 내용 | String | Y          | 
> 
> * * *
> 
> #### 결과값: HashRef
> Argument     | Description | Type   |
> --------     | ----------- | :----: |
> **RETURN**   | --          | NONE   |
>
> * * *
>
> #### 예제
> ```perl
> use Try::Tiny;
> use Common::Exception qw /handle_exception/;
> 
> sub Func
> {
>     try{ ... }
>     catch{ handle_exception($_); }
> }
> ```

* * *

