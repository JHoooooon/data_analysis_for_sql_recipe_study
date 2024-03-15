# 여러개의 값에 대한 조작

## 문자열 연결

```sql
CREATE TABLE mst_user_location
(
    user_id varchar(50),
    pref_name varchar(150),
    city_name varchar(50)
);

INSERT INTO mst_user_location
(user_id, pref_name, city_name)
VALUES
(
    'U001',
    '서울특별시',
    '강서구'
),
(
    'U002',
    '경기도수원시',
    '장안구'
),
(
    'U001',
    '제주특별자치도',
    '서귀포시'
);

SELECT * FROM mst_user_location ;

SELECT
    user_id,
    concat(pref_name, ' ', city_name) AS pref_city,
    pref_name || ' ' || city_name AS pref_city
FROM
    mst_user_location ;
```

```sh
user_id|pref_city   |pref_city   |
-------+------------+------------+
U001   |서울특별시 강서구   |서울특별시 강서구   |
U002   |경기도수원시 장안구  |경기도수원시 장안구  |
U001   |제주특별자치도 서귀포시|제주특별자치도 서귀포시|
```

## 여러개의 값 비교

다음은 사용할 테이블이다

```sql
CREATE TABLE quarterly_sales
(
    year char(4),
    q1 integer,
    q2 integer,
    q3 integer,
    q4 integer
);

INSERT INTO quarterly_sales
(
    YEAR,
    q1,
    q2,
    q3,
    q4
)
VALUES
(
    '2015',
    82000,
    83000,
    78000,
    83000
),
(
    '2016',
    82000,
    85000,
    80000,
    81000
),
(
    '2017',
    92000,
    81000,
    NULL,
    null
);

SELECT * FROM quarterly_sales;
```

```sh
year|q1   |q2   |q3   |q4   |
----+-----+-----+-----+-----+
2015|82000|83000|78000|83000|
2016|82000|85000|80000|81000|
2017|92000|81000|     |     |
```

### 분기별 매출 증감 판정

```sql
SELECT
    YEAR,
    q1,
    q2,
    CASE
        WHEN q1 < q2 THEN '+'
        WHEN q1 > q2 THEN '-'
        ELSE '='
    END AS judge_q1_q2,
    q2 - q1 AS diff_q1_q2,
    sign(q2 - q1) AS sign_q1_q2
FROM
    quarterly_sales;
```

```sh
year|q1   |q2   |judge_q1_q2|diff_q1_q2|sign_q1_q2|
----+-----+-----+-----------+----------+----------+
2015|82000|83000|+          |      1000|       1.0|
2016|82000|85000|+          |      3000|       1.0|
2017|92000|81000|-          |    -11000|      -1.0|
```

### 연간 최대 / 최소 4 분기 매출찾기

```sql
SELECT
    YEAR,
    GREATEST (q1, q2, q3, q4) AS greatest,
    LEAST (q1, q2, q3, q4) AS least
FROM
    quarterly_sales
```

```sh
year|greatest|least|
----+--------+-----+
2015|   83000|78000|
2016|   85000|80000|
2017|   92000|81000|
```

### 연간 평균 4분기 매출 계산

```sql
SELECT
    YEAR,
    (
        COALESCE(q1, 0) +
        COALESCE(q2, 0) +
        COALESCE(q3, 0) +
        COALESCE(q4, 0)
    ) / 4 AS average
FROM
    quarterly_sales;
```

```sh
year|average|
----+-------+
2015|  81500|
2016|  82000|
2017|  43250|
```

NULL 이 아닌 컬럼의 수를 세서 평균을 구하는 방법

```sql
SELECT
    YEAR,
    (
        COALESCE(q1, 0) +
        COALESCE(q2, 0) +
        COALESCE(q3, 0) +
        COALESCE(q4, 0)
    ) / (
        sign(COALESCE(q1, 0)) +
        sign(COALESCE(q2, 0)) +
        sign(COALESCE(q3, 0)) +
        sign(COALESCE(q4, 0))
    ) AS average
FROM
    quarterly_sales;

```

```sh
year| average |
----+--------+
2015| 81500.0 |
2016| 82000.0 |
2017| 86500.0 |
```

## 2개의 값 비율 계산

다음은 사용할 광고 통계 정보 테이블이다

```sql

DROP TABLE IF EXISTS adversising_states_info;

CREATE TABLE advertising_states_info
(
    dt          date,
    ad_id       char(3),
    impressions integer,
    clicks      integer
);

SELECT * FROM advertising_states_info;

INSERT INTO advertising_states_info
VALUES
(
    '2017-04-01',
    '001',
    100000,
    3000
),
(
    '2017-04-01',
    '002',
    120000,
    1200
),
(
    '2017-04-01',
    '003',
    500000,
    10000
),
(
    '2017-04-02',
    '001',
    0,
    0
),
(
    '2017-04-02',
    '002',
    130000,
    1400
),
(
    '2017-04-02',
    '003',
    620000,
    15000
);

SELECT * FROM advertising_states_info;
```

```sh
dt        |ad_id|impressions|clicks|
----------+-----+-----------+------+
2017-04-01|001  |     100000|  3000|
2017-04-01|002  |     120000|  1200|
2017-04-01|003  |     500000| 10000|
2017-04-02|001  |          0|     0|
2017-04-02|002  |     130000|  1400|
2017-04-02|003  |     620000| 15000|
```

### 정수 자료형의 데이터 나누기

`CRT(Click Through Rate)` `(노출당 클릭 비율)` 계산

```sql
    SELECT
    dt,
    ad_id,
    impressions,
    clicks,
    CASE
        WHEN impressions > 0
            --  trunc(numeric. integer) 이다.
            --  trunc 는 numeric 이어야 하므로, clicks 를 캐스팅해주고
            --  나눈다, 이후 100 을 곱한후, 소수점 2자리를 제외한 나머지는
            --  버림 처리하면 원하는 값을 얻을수 있다
            --
            THEN trunc(100 * (clicks::numeric / impressions), 2)

            --  위처럼 복잡하게도 가능하지만, 연산시 앞에 100.0 처럼 실수를 상수로
            --  앞에두고 계산하면 자동적으로 형변환이 일어난다
            --  다음처럼 처리 가능하다
            --
            --  postgresql 에서 실수 연산은 기본 numeric 이 된다
            --
             THEN trunc(100.0 * clicks / impressions, 2)
        ELSE 0
    END
    --  nullif 를 사용할수도 있다
    --  nullif(value1, value2)
    --  nullif 는 value1 이 value2 와 같으면 null 을 반환한다
    --
    trunc(100.0 * clicks / NULLIF(impressions, 0), 2) as nullif
FROM
    advertising_states_info
```

```sh
dt        |ad_id|impressions|clicks|case|nullif|
----------+-----+-----------+------+----+------+
2017-04-01|001  |     100000|  3000|3.00|  3.00|
2017-04-01|002  |     120000|  1200|1.00|  1.00|
2017-04-01|003  |     500000| 10000|2.00|  2.00|
2017-04-02|001  |          0|     0|   0|      |
2017-04-02|002  |     130000|  1400|1.07|  1.07|
2017-04-02|003  |     620000| 15000|2.41|  2.41|
```

## 두값의 거리 계산

사용할 테이블을 만든다

```sql
DROP TABLE IF EXISTS loc_1d;

CREATE TABLE loc_1d
(
    x1  int,
    x2  int
);

SELECT * FROM loc_1d;

INSERT INTO loc_1d
VALUES
(
    5,
    10
),
(
    10,
    5
),
(
    -2,
    4
),
(
    3,
    3
),
(
    0,
    1
);

SELECT * FROM loc_1d;
```

```sh
x1|x2|
--+--+
 5|10|
10| 5|
-2| 4|
 3| 3|
 0| 1|
```

> `거리` 라고 하면 물리적인 공간의 길이를 상상하기 쉽지만, 데이터 분석 분야에서
> `물리적인 공간의 길이가 아닌 거리` 라는 개념이 많이 등장한다
>
> 시험을 보았을때 평균에서 어느정도 떨여져 있는지,
> 작년 매출과 올해 매출에 어느정도의 차이가 있는지 등은 모두 `거리`라 부른다

### 절대값과 평균 제곱근 구하는 쿼리

```sql
SELECT
    abs(x1 - x2) AS abs,
    sqrt(power(x1 - x2, 2)) AS rms
FROM
    loc_1d;
```

```sh
abs|rms|
---+---+
  5|5.0|
  5|5.0|
  6|6.0|
  0|0.0|
  1|1.0|
```

### x,y 평면 위에 있는 두점의 유클리드 거리 계산

```sql
DROP TABLE IF EXISTS loc_2d

CREATE TABLE loc_2d
(
    x1  int,
    y1  int,
    x2  int,
    y2  int
);

INSERT INTO loc_2d
VALUES
(
    0, 0, 2, 2
),
(
    3, 5, 1, 2
),
(
    5, 3, 2, 1
);

SELECT * FROM loc_2d;
```

```sh
x1|y1|x2|y2|
--+--+--+--+
 0| 0| 2| 2|
 3| 5| 1| 2|
 5| 3| 2| 1|
```

```sql
--  유클리드 거리 계산
--  sqrt(power(x1 - x2, 2) + power(y1 - y2, 2)) = x1,y1 과 x2,y2 의 거리

SELECT
    sqrt(
        power(x1 - x2, 2) +
        power(y1 - y2, 2)
    ) AS dist
FROM
    loc_2d;
```

```sh
dist              |
------------------+
2.8284271247461903|
 3.605551275463989|
 3.605551275463989|
```

```sql
--  위의 계산을 postgresql 에서는 point(x1, y1)<-> point(x2, y2)를
--  통해 쉽게 사용가능하다

SELECT
    sqrt(
        power(x1 - x2, 2) +
        power(y1 - y2, 2)
    ) AS dist
FROM
    loc_2d;

```

```sh
dist              |
------------------+
2.8284271247461903|
3.6055512754639896|
3.6055512754639896|
```

## 날짜 / 시간 계산

```sql
DROP TABLE IF EXISTS smt_users_with_dates;

CREATE TABLE smt_users_with_dates
(
    user_id         char(4),
    register_stamp  timestamp,
    birth_date      date
);

INSERT INTO smt_users_with_dates
VALUES
('u001', '2016-02-28 10:00:00', '2000-02-29'),
('u002', '2016-02-29 10:00:00', '2000-02-29'),
('u003', '2016-03-01 10:00:00', '2000-02-29');

SELECT * FROM smt_users_with_dates ;
```

```sh
user_id|register_stamp         |birth_date|
-------+-----------------------+----------+
u001   |2016-02-28 10:00:00.000|2000-02-29|
u002   |2016-02-29 10:00:00.000|2000-02-29|
u003   |2016-03-01 10:00:00.000|2000-02-29|
```

회원등록 시간 1시간 후와 30분 전의 시간,
등록일의 다음날과 1달 전의 날짜

```sql
SELECT
    register_stamp AS register_stamp,
    register_stamp + '1 hour'::INTERVAL AS "1hour after",
    register_stamp - '30 minutes'::INTERVAL AS "30minutes before",
    register_stamp::date AS "register stamp date",
    (register_stamp + '1 day'::INTERVAL)::date AS "1 dayafter",
    (register_stamp::date - '1 month'::INTERVAL)::date AS "1 month before"
FROM
    smt_users_with_dates;
```

```sh
register_stamp         |1hour after            |30minutes before       |register stamp date|1 dayafter|1 month before|
-----------------------+-----------------------+-----------------------+-------------------+----------+--------------+
2016-02-28 10:00:00.000|2016-02-28 11:00:00.000|2016-02-28 09:30:00.000|         2016-02-28|2016-02-29|    2016-01-28|
2016-02-29 10:00:00.000|2016-02-29 11:00:00.000|2016-02-29 09:30:00.000|         2016-02-29|2016-03-01|    2016-01-29|
2016-03-01 10:00:00.000|2016-03-01 11:00:00.000|2016-03-01 09:30:00.000|         2016-03-01|2016-03-02|    2016-02-01|
```

### 날짜 데이터들의 차이 계산

회원등록일과 현재 날짜간의 차이

```sql
SELECT
    current_date AS today,
    register_stamp::date AS registed_day,
    current_date - register_stamp::date AS diff_days
FROM
    smt_users_with_dates ;
```

```sh
today     |registed_day|diff_days|
----------+------------+---------+
2024-03-15|  2016-02-28|     2938|
2024-03-15|  2016-02-29|     2937|
2024-03-15|  2016-03-01|     2936|
```

### 사용자의 생년월일로 나이 계산

```sql
--   extract 에서 현재 날짜에서 year 값 추출하고, 생일에서 year 값을 추출하여 뺀다
SELECT
    user_id,
    birth_date,
    EXTRACT('year' FROM current_date) - EXTRACT('year' FROM birth_date) AS age
FROM
    smt_users_with_dates;

--  age 함수를 사용하여 year 값을 추출한다
SELECT
    user_id,
    birth_date,
    EXTRACT('year' FROM age(current_date, birth_date)) AS age
FROM
    smt_users_with_dates ;

--  등록시점과 현재나이 시점의 나이를 문자열로 계산하는 쿼리
--  모든 year month day 를 합치고 integer 를 만든다음
--  현재날짜에서 생일을 뺀후 / 10000 을 해주면 나이가 계산된다
--  공식같으므로 조금 외울 필요가 있다
--  아래의 공식으로 하면 모든 db 상에서 상호호환 가능하다

SELECT
    user_id,
    birth_date,
    floor(
        (
            REPLACE(current_date::varchar, '-', '')::integer -
            REPLACE(birth_date::varchar, '-', '')::integer
        ) / 10000
    )::integer AS age
FROM
    smt_users_with_dates;
```

```sh
user_id|birth_date|age|
-------+----------+---+
u001   |2000-02-29| 24|
u002   |2000-02-29| 24|
u003   |2000-02-29| 24|
```

## IP 주소 다루기

```sql
SELECT
    cast('127.0.0.1' AS inet) < cast('127.0.0.2' AS inet) AS lt,
    cast('127.0.0.1' AS inet) > cast('127.0.0.2' AS inet) AS gt;
```

```sh
lt  |gt   |
----+-----+
true|false|
```

`IP` 주소가 포함되는지 확인

```sql

--  cidr 규칙에 따라, ip/subnet_mast_bit(octet) 를 사용한다
--  '127.0.0.0/8' 는 네트워크 부분이 127 이므로 나머지 부분은 host 로 사용가능하다
--  '127.0.0.1' 는 host 로 사용되므로 True 이다

SELECT
    cast('127.0.0.1' AS inet) << cast('127.0.0.0/8' AS inet) AS is_contained;
```

```sh
is_contained|
------------+
true        |
```

## 정수 또는 문자열로 IP 주소 다루기

```sql
--  ip 는 . 으로 구분되어 있으므로, split_part 를 사용하여 . 으로 쪼갤수 있다
--  쪼갠 ip 주소를 integer 로 캐스팅하여 header 로 나타낸다

SELECT
    ip,
    split_part(ip, '.', 1)::integer AS part_1,
    split_part(ip, '.', 2)::integer AS part_2,
    split_part(ip, '.', 3)::integer AS part_3,
    split_part(ip, '.', 4)::integer AS part_4
FROM
    (
        SELECT '127.0.0.1' AS ip
    )
```

```sh
ip       |part_1|part_2|part_3|part_4|
---------+------+------+------+------+
127.0.0.1|   127|     0|     0|     1|
```

```sql
--  각 추출한 ip 주소를 2^24, 2^16, 2^8, 2^0 만큼 곱하면
--  정수 자료형이 되므로, 대소 비교 및 범위 판정이 가능하다
--  이렇게 할 이유가 있는지는 아직 모르겠다...


SELECT
    ip,
    (split_part(ip, '.', 1)::integer) * 2^24 AS part_1,
    (split_part(ip, '.', 2)::integer) * 2^16 AS part_2,
    (split_part(ip, '.', 3)::integer) * 2^8 AS part_3,
    (split_part(ip, '.', 4)::integer) * 2^0 AS part_4,
    (split_part(ip, '.', 1)::integer) * 2^24 +
    (split_part(ip, '.', 2)::integer) * 2^16  +
    (split_part(ip, '.', 3)::integer) * 2^8  +
    (split_part(ip, '.', 4)::integer) * 2^0 AS ip_int
FROM
    (
        SELECT '127.0.0.1' AS ip
    )
```

```sh
ip       |part_1    |part_2|part_3|part_4|ip_int    |
---------+----------+------+------+------+----------+
127.0.0.1|2130706432|   0.0|   0.0|   1.0|2130706433|
```

```sql
--  ip 주소 0 으로 메우기
--
--  ip 주소를 비교하는 다른 방법으로는 10 진수 부분을 3자리의 0 으로 체운후 문자열로 만드는것이다
--
--  ip 주소 범위를 비교할만한 상황이 마땅히 떠오르지 않는다
--  이렇게 하면 대소 비교시 유용하다고 한다..

SELECT
    ip,
    lpad(split_part(ip, '.', 1), 3, '0') ||
    lpad(split_part(ip, '.', 2), 3, '0') ||
    lpad(split_part(ip, '.', 3), 3, '0') ||
    lpad(split_part(ip, '.', 4), 3, '0') AS ip_padding
FROM
    (
        SELECT '192.168.0.1' AS ip
    )

```

```sh
ip         |ip_padding  |
-----------+------------+
192.168.0.1|192168000001|
```
