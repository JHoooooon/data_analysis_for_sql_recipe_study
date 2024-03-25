# 사용자 전체의 특징과 경향 찾기

다음은 EC 사이트에서 사용자를 저장한느 사용자용 마스터테이블과, 유저의 각 액션을 저장하는 액션 로그 테이블을 기준으로 쿼리한다

```sql
DROP TABLE IF EXISTS mst_users;
CREATE TABLE mst_users(
    user_id         varchar(255)
  , sex             varchar(255)
  , birth_date      varchar(255)
  , register_date   varchar(255)
  , register_device varchar(255)
  , withdraw_date   varchar(255)
);

INSERT INTO mst_users
VALUES
    ('U001', 'M', '1977-06-17', '2016-10-01', 'pc' , NULL        )
  , ('U002', 'F', '1953-06-12', '2016-10-01', 'sp' , '2016-10-10')
  , ('U003', 'M', '1965-01-06', '2016-10-01', 'pc' , NULL        )
  , ('U004', 'F', '1954-05-21', '2016-10-05', 'pc' , NULL        )
  , ('U005', 'M', '1987-11-23', '2016-10-05', 'sp' , NULL        )
  , ('U006', 'F', '1950-01-21', '2016-10-10', 'pc' , '2016-10-10')
  , ('U007', 'F', '1950-07-18', '2016-10-10', 'app', NULL        )
  , ('U008', 'F', '2006-12-09', '2016-10-10', 'sp' , NULL        )
  , ('U009', 'M', '2004-10-23', '2016-10-15', 'pc' , NULL        )
  , ('U010', 'F', '1987-03-18', '2016-10-16', 'pc' , NULL        )
;

DROP TABLE IF EXISTS action_log;
CREATE TABLE action_log(
    session  varchar(255)
  , user_id  varchar(255)
  , action   varchar(255)
  , category varchar(255)
  , products varchar(255)
  , amount   integer
  , stamp    varchar(255)
);

INSERT INTO action_log
VALUES
    ('989004ea', 'U001', 'purchase', 'drama' , 'D001,D002', 2000, '2016-11-03 18:10:00')
  , ('989004ea', 'U001', 'view'    , NULL    , NULL       , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'favorite', 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'review'  , 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D001'     , NULL, '2016-11-03 18:00:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D002'     , NULL, '2016-11-03 18:01:00')
  , ('989004ea', 'U001', 'add_cart', 'drama' , 'D001,D002', NULL, '2016-11-03 18:02:00')
  , ('989004ea', 'U001', 'purchase', 'drama' , 'D001,D002', 2000, '2016-11-03 18:10:00')
  , ('47db0370', 'U002', 'add_cart', 'drama' , 'D001'     , NULL, '2016-11-03 19:00:00')
  , ('47db0370', 'U002', 'purchase', 'drama' , 'D001'     , 1000, '2016-11-03 20:00:00')
  , ('47db0370', 'U002', 'add_cart', 'drama' , 'D002'     , NULL, '2016-11-03 20:30:00')
  , ('87b5725f', 'U001', 'add_cart', 'action', 'A004'     , NULL, '2016-11-04 12:00:00')
  , ('87b5725f', 'U001', 'add_cart', 'action', 'A005'     , NULL, '2016-11-04 12:00:00')
  , ('87b5725f', 'U001', 'add_cart', 'action', 'A006'     , NULL, '2016-11-04 12:00:00')
  , ('9afaf87c', 'U002', 'purchase', 'drama' , 'D002'     , 1000, '2016-11-04 13:00:00')
  , ('9afaf87c', 'U001', 'purchase', 'action', 'A005,A006', 1000, '2016-11-04 15:00:00')
;
```

## 사용자의 액션 수 집계

액션과 관련된 지표를 집겨한다

액션명, 액션 사용률, 액션 수, 전제 액션 사용률, 1명당 액션 수

```sql
WITH
    stats AS (
            SELECT count(DISTINCT "session") AS total_uu
            FROM
            action_log al
        )
SELECT
    action,
    --  액션uu
    count(DISTINCT session) AS action_uu,
    --  전체uu
    total_uu,
    --  액션 사용율
    (
        trunc(
            100
            * count(action)
            / sum(count(action)) OVER ()
            , 2
        )
    ) AS action_usage_rate,
    --  유저 액션 사용률
    (
        trunc(
            100
            * count(DISTINCT session)
            / total_uu
            , 2
        )
    ) AS user_usage_rate,
    --  1 인당 액션수
    count(DISTINCT session),
    (
        trunc(
            1.0
            * count(1)
            / count(DISTINCT session)
            , 2
        )
    ) AS count_per_user
FROM
    action_log al
CROSS JOIN stats
GROUP BY action, total_uu

SELECT
    user_id,
    count(user_id) AS "count"
FROM
    action_log al
```

### 로그인 사용자와 비로그인 사용자를 구분하여 집계

다음은 `action_log` 에서 로그데이터를 기준으로 해서 로그인되었는지 아닌지
집계하는 테이블이다

책에서는 빈문자열이면 로그인하지 않은 유저로 구분처리한다

```sql
SELECT
    user_id,
    count(user_id) AS "count"
FROM
    action_log al

WITH
    action_log_with_status AS (
        SELECT
            "session"
        ,   user_id
        ,   ACTION
        ,   CASE
                WHEN COALESCE(user_id, '') <> '' THEN 'login'
                ELSE 'guest'
            END
        FROM
            action_log al
        )
SELECT
    *
FROM action_log_with_status;
```

로그인 상태에 따라 액션수등을 따로 집계하는 쿼리를 작성한다

```sql
WITH
    action_log_with_status AS (
        SELECT
            "session"
        ,   user_id
        ,   ACTION
        ,   CASE
                WHEN COALESCE(user_id, '') <> '' THEN 'login'
                ELSE 'guest'
            END "login_status"
        FROM
            action_log al
        )
SELECT
        coalesce(action, 'all') action
    ,   coalesce(login_status, 'all') login_status
    ,   count(DISTINCT session) action_uu
    ,   count(1) action_count
FROM action_log_with_status
GROUP BY
    ROLLUP (action, login_status);
```

### 회원과 비회원 구분해서 집계

현재 로그인하지 않았지만, 이전에 한번이라도 로그인했다면 회원으로 계산 집계
하는 쿼리

```sql
WITH
    action_log_with_status AS (
        SELECT
            "session"
        ,   user_id
        ,   ACTION
        ,   CASE
                WHEN
                    coalesce(
                        max(user_id) OVER (
                            PARTITION BY session
                            ORDER BY stamp
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                        ), ''
                    ) <> '' THEN 'member'
                ELSE 'none'
            END "member_status"
        FROM
            action_log al
    )
SELECT
    *
FROM
    action_log_with_status;
```
