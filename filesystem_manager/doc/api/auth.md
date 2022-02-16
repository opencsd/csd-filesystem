# 인증 설정 API

## API 개요

### 1. [/auth/info](#authinfo)
### 2. [/auth/ldap/info](#authldapinfo)
### 3. [/auth/ldap/enable](#authldapenable)
### 4. [/auth/ldap/disable](#authldapdisable)

## API 설명

* 인증 방식을 설정/관리하는 API

### /auth/info

* 인증 설정을 조회하는 API

#### 요청

```
{
    "secure-key" : "<KEY>"
}
```

#### 응답
```
{
    "return" : "true|false",
    "code"   : "AUTH_CONFIG_OK|AUTH_CONFIG_FAILURE",
    "msg"    : "<MSG>",
    "entity" : {
        "Local" : {
            "Enabled" : "true|false"
        },
        "LDAP" : {
            "Enabled" : "true|false"
        },
        "ADS" : {
            "Enabled" : "true|false"
        }
    }
}
```

이름           | 설명                                | 자료형 |
-------------- | ----------------------------------- | ------ |
**return**         | true 혹은 false                     | String |
**code**           | AUTH_INFO_OK 혹은 AUTH_INFO_FAILURE | String |
**msg**            | API 반환 결과에 따른 메시지         | String |
**Local->Enabled** | 로컬 시스템 인증 활성화 여부        | String |
**LDAP->Enabled**  | LDAP 인증 활성화 여부               | String |
**ADS->Enabled**   | ADS 인증 활성화 여부                | String |

### /auth/ldap/info

* LDAP 인증 설정을 조회하는 API

#### 요청

```
{
    "secure-key" : "<KEY>"
}
```

#### 응답
```
{
    "return" : "true|false",
    "code"   : "AUTH_INFO_OK|AUTH_INFO_FAILURE",
    "msg"    : "<MSG>",
    "entity" : {
        "URI"        : "ldap://192.168.0.1",
        "BaseDN"     : "dc=gluesys,dc=com",
        "BindDN"     : "uid=admin,cn=users,dc=gluesys,dc=com",
        "BindPw"     : "gluesys",
        "RootBindDN" : "uid=root,cn=users,dc=gluesys,dc=com",
        "RootBindPw" : "gluesys",
        "PasswdDN"   : "gluesys",
        "ShadowDN"   : "cn=users,dc=gluesys,dc=com",
        "GroupDN"    : "cn=users,dc=gluesys,dc=com",
        "SSL"        : "SSL/TLS"
    }
}
```

이름       | 설명                                          | 자료형 |
---------- | --------------------------------------------- | ------ |
**return**     | true 혹은 false                               | String |
**code**       | AUTH_INFO_OK 혹은 AUTH_INFO_FAILURE           | String |
**msg**        | API 반환 결과에 따른 메시지                   | String |
**URI**        | LDAP 서버의 URI(예: ldap://192.168.0.1)       | String |
**BaseDN**     | 검색 기준 DN(Distinguished Name)              | String |
**BindDN**     | LDAP 조회 권한이 있는 DN                      | String |
**BindPw**     | LDAP 조회 권한이 있는 DN의 암호               | String |
**RootBindDN** | LDAP 데이터 변경 권한이 있는 DN               | String |
**RootBindPw** | LDAP 데이터 변경 권한이 있는 DN의 암호        | String |
**PasswdDN**   | LDAP 사용자 일반 정보를 사상하는 DN           | String |
**ShadowDN**   | LDAP 사용자 보안 정보를 사상하는 DN           | String |
**GroupDN**    | LDAP 그룹 정보를 사상하는 DN                  | String |
**SSL**        | SSL 활성화 여부(None, SSL/TLS, StartTLS)      | String |


### /auth/ldap/enable

* LDAP 인증을 활성화하는 API

#### 요청
```
{
    "secure-key" : "<KEY>",
    "entity"     : {
        "URI"        : "ldap://192.168.0.1",
        "BaseDN"     : "dc=gluesys,dc=com",
        "BindDN"     : "uid=admin,cn=users,dc=gluesys,dc=com",
        "BindPw"     : "gluesys",
        "RootBindDN" : "uid=root,cn=users,dc=gluesys,dc=com",
        "RootBindPw" : "gluesys",
        "PasswdDN"   : "gluesys",
        "ShadowDN"   : "cn=users,dc=gluesys,dc=com",
        "GroupDN"    : "cn=users,dc=gluesys,dc=com",
        "SSL"        : "SSL/TLS"
    }
}
```

이름       | 설명                                     | 자료형 | 필수 여부 |
---------- | ---------------------------------------- | ------ | --------- |
**URI**        | LDAP 서버의 URI(예: ldap://192.168.0.1)  | String | Y         |
**BaseDN**     | 검색 기준 DN(Distinguished Name)         | String | Y         |
**BindDN**     | LDAP 조회 권한이 있는 DN                 | String | Y         |
**BindPw**     | LDAP 조회 권한이 있는 DN의 암호          | String | Y         |
**RootBindDN** | LDAP 데이터 변경 권한이 있는 DN          | String | Y         |
**RootBindPw** | LDAP 데이터 변경 권한이 있는 DN의 암호   | String | Y         |
**PasswdDN**   | LDAP 사용자 일반 정보를 사상하는 DN      | String | Y         |
**ShadowDN**   | LDAP 사용자 보안 정보를 사상하는 DN      | String | Y         |
**GroupDN**    | LDAP 그룹 정보를 사상하는 DN             | String | Y         |
**SSL**        | SSL 활성화 여부(None, SSL/TLS, StartTLS) | String | Y         |

#### 응답

```
{
    "return" : "true|false",
    "code"   : "AUTH_CONFIG_OK|AUTH_CONFIG_FAILURE",
    "msg"    : "<MSG>",
}
```

이름    | 설명                                    | 자료형 |
------- | -----------                             | ------ |
**return**  | true 혹은 false                         | String |
**code**    | AUTH_CONFIG_OK 혹은 AUTH_CONFIG_FAILURE | String |
**msg**     | API 반환 결과에 따른 메시지             | String |

### /auth/ldap/disable

* LDAP 인증을 비활성화하는 API

#### 요청

```
{
    "secure-key" : "<KEY>"
}
```

#### 응답

```
{
    "return" : "true|false",
    "code"   : "AUTH_CONFIG_OK|AUTH_CONFIG_FAILURE",
    "msg"    : "<MSG>"
}
```

이름    | 설명                                    | 자료형 |
------- | -----------                             | ------ |
**return**  | true 혹은 false                         | String |
**code**    | AUTH_CONFIG_OK 혹은 AUTH_CONFIG_FAILURE | String |
**msg**     | API 반환 결과에 따른 메시지             | String |
