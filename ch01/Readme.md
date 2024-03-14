# 하나의 값 조작하기

## 코드값을 레이블로 변경

```sql
CREATE TABLE mst_users
(
user_id varchar,
register_date date,
register_device int
)

INSERT INTO mst_users
VALUES
(
    'U001',
    current_date,
    1
),
(
    'U002',
    current_date,
    2
),
(
    'U003',
    current_date,
    3
);

SELECT * FROM mst_users;
```

다음처럼 쿼리가 이뤄진다

```sh
user_id|register_date|register_device|
-------+-------------+---------------+
U001   |   2024-03-14|              1|
U002   |   2024-03-14|              2|
U003   |   2024-03-14|              3|
```

이를 다음처럼 레이블로 변경가능하다

```sql
SELECT
    m.user_id,
    CASE
        WHEN m.register_device = 1 THEN '데스크톱'
        WHEN m.register_device = 2 THEN '테블릿'
        WHEN m.register_device = 3 THEN '스마트폰'
        ELSE ''
    END
FROM
    mst_users m;
```

```sh
user_id|case|
-------+----+
U001   |데스크톱|
U002   |테블릿 |
U003   |스마트폰|
```

## URL 에서 요소추출

```sql
DROP TABLE IF EXISTS access_log

CREATE TABLE access_log
(
    stamp timestamp,
    refferer_host varchar
);

INSERT INTO access_log
VALUES
    (
        current_timestamp,
        'https://www.other.com'
    ),
    (
        current_timestamp,
        'https://www.other.net'
    ),
    (
        current_timestamp,
        'https://www.other.com'
    );

SELECT * FROM access_log;
```

```sh
stamp                  |refferer_host        |
-----------------------+---------------------+
2024-03-14 17:16:58.956|https://www.other.com|
2024-03-14 17:16:58.956|https://www.other.net|
2024-03-14 17:16:58.956|https://www.other.com|
```

이를 `host` 부분만 가져온다

```sql
SELECT
    a.stamp,
    substring(a.refferer_host FROM 'https?://([^/]*)') AS host
FROM
    access_log a;
```

```sh
stamp                  |host         |
-----------------------+-------------+
2024-03-14 17:16:58.956|www.other.com|
2024-03-14 17:16:58.956|www.other.net|
2024-03-14 17:16:58.956|www.other.com|
```

## URL 에서 경로와 요청 배개변수 값 추출

```sql
DROP TABLE IF EXISTS access_log

CREATE TABLE access_log
(
    stamp timestamp,
    refferer_host varchar
);

INSERT INTO access_log
VALUES
    (
        current_timestamp,
        'https://www.other.com/video/detail?id=001'
    ),
    (
        current_timestamp,
        'https://www.other.net/video#ref'
    ),
    (
        current_timestamp,
        'https://www.other.com/book/detail?id=002'
    );


SELECT
    a.stamp,
    substring(a.refferer_host FROM '//[^/]+([^?#]+)') AS PATH,
    substring(a.refferer_host FROM 'id=([^&]*)') AS id
FROM
    access_log a;
```

```sh
stamp                  |path         |id |
-----------------------+-------------+---+
2024-03-14 17:29:29.714|/video/detail|001|
2024-03-14 17:29:29.714|/video       |   |
2024-03-14 17:29:29.714|/book/detail |002|
```

## 문자열을 배열로 분해

```sql
SELECT
    a.stamp,
    a.refferer_host,
    split_part(substring(a.refferer_host FROM '//[^/]+([^?#]+)'), '/', 2) AS path2,
    split_part(substring(a.refferer_host FROM '//[^/]+([^?#]+)'), '/', 3) AS path3
FROM
    access_log a;

```

```sh
stamp                  |refferer_host                            |path2|path3 |
-----------------------+-----------------------------------------+-----+------+
2024-03-14 17:29:29.714|https://www.other.com/video/detail?id=001|video|detail|
2024-03-14 17:29:29.714|https://www.other.net/video#ref          |video|      |
2024-03-14 17:29:29.714|https://www.other.com/book/detail?id=002 |book |detail|
```

## 날짜와 타입스템프 다루기

타입스탬프를 다룰시, `timezone` 이 없는 자료형을 사용하는것이 좋다
이는 리턴값의 자료형을 맞추기 용이하다

```sql
SELECT
    current_date AS dt,
    --  타입존이 포함된 timestamp
    current_timestamp AS dts,
    --  타임존이 포함되지 않은 timestamp
    localtimestamp AS stamp;
```

## 지정한 값의 날짜 / 시각 데이터 추출

```sql
SELECT
    --  cast 함수를 사용하여 형변환 가능
    cast('2016-01-30' AS date) AS dt,
    cast('2016-01-30 12:00:00' AS timestamp) AS dts,
    --  postgresql 에서는 :: 을 사용하여 쉽게 형변환 가능
    '2016-01-30'::date AS dt2,
    '2016-01-30 12:00:00'::timestamp AS dts2;
```

## 날짜 / 시각에서 특정 필드 추출

```sql
SELECT
    EXTRACT (YEAR FROM stamp) AS year,
    EXTRACT (MONTH FROM stamp) AS month,
    EXTRACT (DAY FROM stamp) AS day,
    EXTRACT (HOUR FROM stamp) AS HOUR
FROM
    (
        SELECT
            cast('2016-01-30 12:00:00' AS timestamp) AS stamp
    );
```

`EXTRACT` 함수는 추출가능한 여러 `field` 들이 존재한다

| field           | desc                                          |
| :-------------- | :-------------------------------------------- |
| century         | 세기                                          |
| day             | 일                                            |
| decade          | 연도 필드를 10 으로 나눈 값                   |
| dow             | 일요일(0) ~ 토요일(6) 까지의 정수             |
| doy             | 연중 날짜 (1 ~ 365/366)                       |
| epoch           | 1970-01-01 00:00:00 UTC 부터 지정한 날까지 초 |
| hour            | 0 ~ 23 까지 시간                              |
| isodow          | 월요일(1) ~ 일요일(7) 까지의 정수             |
| isoyear         | 날짜가 속하는 ISO 8601 지정 연도              |
| julian          | 율리우스력 날짜                               |
| microseconds    | 마이크로초                                    |
| millennium      | 1000 년의 기간                                |
| milliseconds    | 밀리초                                        |
| minute          | 분                                            |
| month           | 달                                            |
| quarter         | 연도 분기(1 ~ 4)                              |
| second          | 초                                            |
| timezone        | 초 단위로 측정된 UTC 시간대의 오프셋          |
| timezone_hour   | timezone offset 의 시간                       |
| timezone_minute | timezone offset 의 분                         |
| week            | 주                                            |
| year            | 년                                            |

이 쿼리는 다음처럼 처리도 가능하다

```sql
SELECT
    substr(stamp::text, 1, 4) AS year,
    substr(stamp::text, 6, 2) AS month,
    substr(stamp::text, 9, 2) AS day,
    substr(stamp::text, 12, 2) AS hour
FROM
    (
        SELECT
            cast('2016-01-30 12:00:00' AS timestamp) AS stamp
    );
```

## 결손 값을 디폴트 값으로 대치

결손 값이란 `NULL` 값을 말한다

```sql
DROP TABLE IF EXISTS purchase_with_coupon;

CREATE TABLE purchase_with_coupon
(
    purchase_id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    amount int,
    coupon  int
);

INSERT INTO purchase_with_coupon (amount, coupon)
VALUES
(
    3280,
    NULL
),
(
    4650,
    500
),
(
    3870,
    NULL
);

SELECT * FROM purchase_with_coupon ;
```

```sh
purchase_id|amount|coupon|
-----------+------+------+
          1|  3280|      |
          2|  4650|   500|
          3|  3870|      |
```

여기서 말하는바는, `amount` 를 `coupon` 값 만큼 빼야 하는데
`NULL` 이 있어서 `NULL` 을 반환한다는 것이다

이를 해결하기 위해서는 `COALESCE` 를 사용한다

```sql
SELECT
    COALESCE(amount - coupon, amount) AS payment
FROM purchase_with_coupon ;
```
