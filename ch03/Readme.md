# 하나의 테이블에 대한 조작

## 데이터 집약

`SQL` 은 집약함수라고 부르는 여러가지 함수를 제공한다
레코드의 수를 세주는 함수도 있고, 레코드에 저장된 값의 합계, 평균, 최대, 최소를
계산해 주는 함수부터 통계 처리를 사용해 통계 지표를 출력해주는 함수도 있다

## 구룹의 특징

상품평가 테이블에서, 상품에 대한 사용자 평가가 저장된다

```sql
DROP TABLE IF EXISTS review;

CREATE TABLE review
(
    user_id     varchar,
    product_id  varchar,
    score       numeric
);

INSERT INTO review
VALUES
(
    'U001',
    'A001',
    4.0
),
(
    'U001',
    'A002',
    5.0
),
(
    'U001',
    'A003',
    5.0
),
(
    'U002',
    'A001',
    3.0
),
(
    'U002',
    'A002',
    3.0
),
(
    'U002',
    'A003',
    4.0
),
(
    'U003',
    'A001',
    5.0
),
(
    'U003',
    'A002',
    4.0
),


SELECT * FROM review;
```

```sh
user_id|product_id|score|
-------+----------+-----+
U001   |A001      |  4.0|
U001   |A002      |  5.0|
U001   |A003      |  5.0|
U002   |A001      |  3.0|
U002   |A002      |  3.0|
U002   |A003      |  4.0|
U003   |A001      |  5.0|
U003   |A002      |  4.0|
U002   |A003      |  4.0|
```

## 테이블 전체의 특징량 계산

```sql
SELECT
    count(*) AS total_count,
    count(DISTINCT user_id) AS user_count,
    count(DISTINCT product_id) AS product_count,
    sum(score) AS total_score,
    round(avg(score)::numeric, 2) AS avg_score,
    max(score) AS max_score,
    min(score) AS min_score
FROM
    review;
```

```sql
total_count|user_count|product_count|total_score|avg_score|max_score|min_score|
-----------+----------+-------------+-----------+---------+---------+---------+
          9|         3|            3|       37.0|     4.11|      5.0|      3.0|
```

## 그룹화한 데이터의 특징량 계산

```sql
SELECT
    user_id
    ,count(*)
    ,count(DISTINCT product_id)
    ,sum(score)
    ,round(avg(score)::numeric, 2)
    ,max(score)
    ,min(score)
FROM
    review AS r
GROUP BY
    r.user_id;
```

```sh
user_id|count|count|sum |round|max|min|
-------+-----+-----+----+-----+---+---+
U001   |    3|    3|14.0| 4.67|5.0|4.0|
U002   |    4|    3|14.0| 3.50|4.0|3.0|
U003   |    2|    2| 9.0| 4.50|5.0|4.0|
```

## 집약 함수를 적용한 값과 집약 전의 값을 동시에 다루기

개별 리뷰 점수와 사용자 평균 리뷰 점수의 차이를 구하라

```sql
SELECT
    user_id
    ,product_id
    ,score
    ,trunc(avg(score) OVER (PARTITION BY user_id)::numeric, 2) AS user_avg_score
    ,trunc(avg(score) OVER ()::numeric, 2) as avg_score
    ,trunc((score - avg(score) over(PARTITION BY user_id))::numeric, 2) as score_diff
FROM
    review as r
ORDER BY
    user_id, product_id;
```

```sh
user_id|product_id|score|user_avg_score|avg_score|score_diff|
-------+----------+-----+--------------+---------+----------+
U001   |A001      |  4.0|          4.66|     4.11|     -0.66|
U001   |A002      |  5.0|          4.66|     4.11|      0.33|
U001   |A003      |  5.0|          4.66|     4.11|      0.33|
U002   |A001      |  3.0|          3.50|     4.11|     -0.50|
U002   |A002      |  3.0|          3.50|     4.11|     -0.50|
U002   |A003      |  4.0|          3.50|     4.11|      0.50|
U002   |A003      |  4.0|          3.50|     4.11|      0.50|
U003   |A001      |  5.0|          4.50|     4.11|      0.50|
U003   |A002      |  4.0|          4.50|     4.11|     -0.50|
```

## 그룹 내부 순서

인기상품의 상품 ID, 카테고리, 스코어 정보를 가진 인기 상품 테이블

```sql
DROP TABLE if exists popular_products;

CREATE TABLE popular_products
(
    product_id  varchar(50)
    ,category    varchar(50)
    ,score       decimal
);

INSERT INTO popular_products
VALUES
(
    'A001'
    ,'action'
    ,94
),
(
    'A002'
    ,'action'
    ,81
),
(
    'A003'
    ,'action'
    ,78
),
(
    'A004'
    ,'action'
    ,64
),
(
    'D001'
    ,'dream'
    ,90
),
(
    'D002'
    ,'dream'
    ,82
),
(
    'D003'
    ,'dream'
    ,78
),
(
    'D004'
    ,'dream'
    ,58
);

SELECT * from popular_products;
```

```sh
product_id|category|score|
----------+--------+-----+
A001      |action  |   94|
A002      |action  |   81|
A003      |action  |   78|
A004      |action  |   64|
D001      |dream   |   90|
D002      |dream   |   82|
D003      |dream   |   78|
D004      |dream   |   58|
```

## order by 순서 정의

```sql
SELECT
        product_id
    ,   score
    ,   row_number() over (ORDER BY score DESC) row
    ,   rank() over (ORDER BY score DESC) rank
    ,   dense_rank() over (ORDER BY score DESC) dense_rank
    --  현재행을 기준으로 앞의 행
    ,   lag(product_id) over (ORDER BY score DESC) lag_1
    --  현재행을 기준으로 앞의 2행
    ,   lag(product_id, 2) over (ORDER BY score DESC) lag_2
    --  현재행을 기준으로 뒤의 행
    ,   lead(product_id) over (ORDER BY score DESC) lead_2
    --  현재행을 기준으로 뒤의 2행
    ,   lead(product_id, 2) over (ORDER BY score DESC) lead_2
FROM
    popular_products
```

```sh
product_id|score|row|rank|dense_rank|lag_1|lag_2|lead_2|lead_2|
----------+-----+---+----+----------+-----+-----+------+------+
A001      |   94|  1|   1|         1|     |     |D001  |D002  |
D001      |   90|  2|   2|         2|A001 |     |D002  |A002  |
D002      |   82|  3|   3|         3|D001 |A001 |A002  |A003  |
A002      |   81|  4|   4|         4|D002 |D001 |A003  |D003  |
A003      |   78|  5|   5|         5|A002 |D002 |D003  |A004  |
D003      |   78|  6|   5|         5|A003 |A002 |A004  |D004  |
A004      |   64|  7|   7|         6|D003 |A003 |D004  |      |
D004      |   58|  8|   8|         7|A004 |D003 |      |      |
```

## ORDER BY 구문과 집약함수 조합

order by 구문과 집약함수를 조합하면,
집약함수의 적용범위를 유연하게 지정할수 있다

순위 상위에서 현재행까지의 스코어를 모두 더한값과,
현재 행과 앞뒤의 행 하나씩, 전체 3개의 행의 평균 스코어를 계산하라

```sql
SELECT
        product_id
    ,   score
    ,   lag(score) over (ORDER BY score DESC) lag_score
    ,   lead(score) over (ORDER BY score DESC) lead_score
    ,   sum(score) OVER (
        ORDER BY score DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
    ,   round(avg(score) OVER (
        ORDER BY score DESC
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) row_avg
FROM
    popular_products
ORDER BY
    score DESC;
```

```sh
product_id|score|lag_score|lead_score|sum|row_avg|
----------+-----+---------+----------+---+-------+
A001      |   94|         |        90| 94|  92.00|
D001      |   90|       94|        82|184|  88.67|
D002      |   82|       90|        81|266|  84.33|
A002      |   81|       82|        78|347|  80.33|
A003      |   78|       81|        78|425|  79.00|
D003      |   78|       78|        64|503|  73.33|
A004      |   64|       78|        58|567|  66.67|
D004      |   58|       64|          |625|  61.00|
```

> **윈도 프레임지정**
>
> 프레임 지정이란 현재 레코드 위치를 기반으로 상대적인 윈도를
> 정의하는 구문이다

| 프레임 지정 구문                    | 설명                                              |
| :---------------------------------- | :------------------------------------------------ |
| `ROWS BETWEEN keyword AND keyword`  | 현재 `row` 를 기준으로 `row` 단위로 대상 지정     |
| `RANGE BETWEEN keyword AND keyword` | 현재 `row` 를 기준으로 값의 범위 단위로 대상 지정 |

| keyword               | 설명         |
| :-------------------- | :----------- |
| `CURRENT ROW`         | 현재 행      |
| `n PRECEDING`         | `n` 행 앞    |
| `n FOLLOWING`         | `n` 행 뒤    |
| `UNBOUNDED PRECEDING` | 이전 행 전부 |
| `UNBOUNDED FOLLOWING` | 이후 행 전부 |

```sql
SELECT
        product_id
    ,   row_number() OVER (ORDER BY score DESC) AS row
    ,   array_agg(product_id)
        OVER (
            ORDER BY score DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) whole_agg
    ,   array_agg(product_id)
        OVER (
            ORDER BY score DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) cum_agg
    ,   array_agg(product_id)
        OVER (
            ORDER BY score DESC
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ) local_egg
FROM
    popular_products;
```

```sh
product_id|row|whole_agg                                |cum_agg                                  |local_egg       |
----------+---+-----------------------------------------+-----------------------------------------+----------------+
A001      |  1|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001}                                   |{A001,D001}     |
D001      |  2|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001}                              |{A001,D001,D002}|
D002      |  3|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001,D002}                         |{D001,D002,A002}|
A002      |  4|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001,D002,A002}                    |{D002,A002,A003}|
A003      |  5|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001,D002,A002,A003}               |{A002,A003,D003}|
D003      |  6|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001,D002,A002,A003,D003}          |{A003,D003,A004}|
A004      |  7|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001,D002,A002,A003,D003,A004}     |{D003,A004,D004}|
D004      |  8|{A001,D001,D002,A002,A003,D003,A004,D004}|{A001,D001,D002,A002,A003,D003,A004,D004}|{A004,D004}     |
```

> 윈도 함수에 프레임 지정이 없으면, `ORDER BY` 가 없는 경우, 모든 행
> `ORDER BY` 구문이 있는 경우 첫 행에서 현재 행까지 `default` 프레임으로
> 지정된다

## PARTITION BY 와 ORDER BY 조함

`partition by` 구문과 `order by` 를 조함해서 사용할수도 있다
카테고리별의 순위를 계산하는 쿼리이다

```sql
SELECT
            category
        ,   product_id
        ,   score
        ,   row_number() OVER (PARTITION BY category ORDER BY score desc) row
        ,   rank() OVER (PARTITION BY category ORDER BY score desc) rank
        ,   dense_rank() OVER (PARTITION BY category ORDER BY score desc) dense
FROM
    popular_products
ORDER BY category, row;
```

```sh
category|product_id|score|row|rank|dense|
--------+----------+-----+---+----+-----+
action  |A001      |   94|  1|   1|    1|
action  |A002      |   81|  2|   2|    2|
action  |A003      |   78|  3|   3|    3|
action  |A004      |   64|  4|   4|    4|
dream   |D001      |   90|  1|   1|    1|
dream   |D002      |   82|  2|   2|    2|
dream   |D003      |   78|  3|   3|    3|
dream   |D004      |   58|  4|   4|    4|
```

각 카테고리의 상위 n 개 추출
여기서는 2개 추출한다

```sql
SELECT
    *
FROM
    (
        SELECT
            category,
            product_id,
            score,
            rank() over (PARTITION BY category ORDER BY score DESC)
        FROM
            popular_products
    )
WHERE
    rank <= 2;
```

```sh
category|product_id|score|rank|
--------+----------+-----+----+
action  |A001      |   94|   1|
action  |A002      |   81|   2|
dream   |D001      |   90|   1|
dream   |D002      |   82|   2|
```

카테고리별 순위 순서에서 상위 1개의 상품 ID 를 추출할 경우
`FIRST_VALUE` 윈도 함수를 사용하여 처리가능하다

```sql
SELECT
        DISTINCT category
    ,   first_value(product_id) OVER (
            PARTITION BY category
            ORDER BY score DESC
        )
FROM
    popular_products;
```

```sh
category|first_value|
--------+-----------+
dream   |D001       |
action  |A001       |
```

## 세로기반 데이터를 가로 기반으로 변환

날짜별 `KPI` 데이터이다

```sql
DROP TABLE IF EXISTS daily_kpi;

CREATE TABLE daily_kpi
(
    dt          date,
    indicator   varchar,
    val         int
);

INSERT INTO daily_kpi
VALUES
(
    '2017-01-01'
    ,'impressions'
    ,1800
),
(
    '2017-01-01'
    ,'sessions'
    ,500
),
(
    '2017-01-01'
    ,'users'
    ,200
),
(
    '2017-01-02'
    ,'impressions'
    ,2000
),
(
    '2017-01-02'
    ,'sessions'
    ,700
),
(
    '2017-01-02'
    ,'users'
    ,250
)

SELECT * FROM daily_kpi ;
```

```sh
dt        |indicator  |val |
----------+-----------+----+
2017-01-01|impressions|1800|
2017-01-01|sessions   | 500|
2017-01-01|users      | 200|
2017-01-02|impressions|2000|
2017-01-02|sessions   | 700|
2017-01-02|users      | 250|
```

`impressions`, `users`, `sessions` 중 가장 큰값을 추출하여 행으로
만들어 출력

```sql
SELECT
        dt
    ,   max(case when indicator = 'impressions' then val end) impressions
    ,   max(case when indicator = 'sessions' then val end) sessions
    ,   max(case when indicator = 'users' then val end) users
FROM
    daily_kpi
GROUP BY dt
```

```sh
dt        |impressions|sessions|users|
----------+-----------+--------+-----+
2017-01-01|       1800|     500|  200|
2017-01-02|       2000|     700|  250|
```

## 가로 기반 데이터를 세로 기반으로 변환

```sql
SELECT * FROM quarterly_sales;
```

```sh
year|q1   |q2   |q3   |q4   |
----+-----+-----+-----+-----+
2015|82000|83000|78000|83000|
2016|82000|85000|80000|81000|
2017|92000|81000|     |     |
```

다음의 데이터를 year, quarter, sales 로 변환한다

```sql

SELECT
    year
    ,   case
            when p.idx = 1 then 'q1'
            when p.idx = 2 then 'q2'
            when p.idx = 3 then 'q3'
            when p.idx = 4 then 'q4'
        end as quarter
    ,   case
            when p.idx = 1 then q1
            when p.idx = 2 then q2
            when p.idx = 3 then q3
            when p.idx = 4 then q4
        end as sales
FROM
    quarterly_sales
cross join (
            SELECT 1 as idx
        UNION ALL SELECT 2 as idx
        UNION ALL SELECT 3 as idx
        UNION ALL SELECT 4 as idx
    ) as p
```

```sh
year|quarter|sales|
----+-------+-----+
2015|q1     |82000|
2015|q2     |83000|
2015|q3     |78000|
2015|q4     |83000|
2016|q1     |82000|
2016|q2     |85000|
2016|q3     |80000|
2016|q4     |81000|
2017|q1     |92000|
2017|q2     |81000|
2017|q3     |     |
2017|q4     |     |
```

임의의 길이를 가진 배열을 행으로 전개

다음을 살펴보자

```sql
SELECT
    unnest(ARRAY['A001', 'A002', 'A003']) as product_id;
```

```sh
product_id|
----------+
A001      |
A002      |
A003      |
```

`unnest` 함수를 사용하여 `ARRAY` 를 테이블로 만들었다

```sql
DROP TABLE IF EXISTS purchase_log;

CREATE TABLE purchase_log
(
        purchase_id char(10)
    ,   product_id  varchar
)

INSERT INTO purchase_log
VALUES
(
    '100001',
    'A001,A002,A003'
),
(
    '100002',
    'A001,A002'
),
(
    '100003',
    'A001'
);

SELECT * FROM purchase_log;
```

```sh
purchase_id|product_id    |
-----------+--------------+
100001     |A001,A002,A003|
100002     |A001,A002     |
100003     |A001          |
```

이렇게 이루어진 테이블이 있다면, `product_id` 를 각 `purchase_id` 로
매핑해주어야 한다

```sql
SELECT
    purchase_id,
    id
FROM
    purchase_log p
CROSS JOIN unnest(string_to_array(p.product_id, ',')) as id


SELECT
        purchase_id
    ,   regexp_split_to_table(product_id, ',') as id
FROM
    purchase_log p
```

```sh
purchase_id|id  |
-----------+----+
100001     |A001|
100001     |A002|
100001     |A003|
100002     |A001|
100002     |A002|
100003     |A001|
```

피벗 테이블을 사용해 문자열을 행으로 전개 해보자
`1 ~ n` 개 까지의 정수를 하나의 행으로 나태낸다

```sql
SELECT
unnest(ARRAY[1, 2, 3]) idx

SELECT
    idx
FROM (
        SELECT 1 idx
        UNION ALL SELECT 2 idx
        UNION ALL SELECT 3 idx
        UNION ALL SELECT 4 idx
    );
```

```sh
unnest|
------+
     1|
     2|
     3|
```

다음은 열로 나타낸다

```sql
SELECT
        split_part('1,2,3', ',', 1)
    ,   split_part('1,2,3', ',', 2)
    ,   split_part('1,2,3', ',', 3)
```

```sh
split_part|split_part|split_part|
----------+----------+----------+
1         |2         |3         |
```

쉼표로 구분된 상품 ID 수를 계산한다

```sql
SELECT
        purchase_id
    ,   product_id
    ,   1
        + char_length(product_id)
        - char_length(replace(product_id, ',', ''))
FROM
    purchase_log;

```

```sh
purchase_id|product_id    |?column?|
-----------+--------------+--------+
100001     |A001,A002,A003|       3|
100002     |A001,A002     |       2|
100003     |A001          |       1|
```

> 위는 `char_length(product_id)` `-` `char_length(replace(product_id, ',', ''))` 는
> 원래 문자열의 개수에서 쉼표를 뺀 문자열의 개수를 처리하므로 쉼표 개수만큼의 값이 나온다
>
> 이는 배열의 특성상 쉼표 하나가 있다면 원소는 2개이므로, `1` 을 더해 배열의 개수를 계산한다

위의 방법을 종합적으로 처리하면 다음과 같다

```sql
    SELECT
        purchase_id
    ,   product_id
    ,   i.idx
    ,   split_part(p.product_id, ',', i.idx) as product_id
FROM
    purchase_log p
JOIN (
    SELECT 1 as idx
    UNION ALL
    SELECT 2 as idx
    UNION ALL
    SELECT 3 as idx
    UNION ALL
    SELECT 4 as idx
) i ON (
    i.idx <= (
        1
        + char_length(p.product_id)
        - char_length(replace(p.product_id, ',', ''))
    )
)
```

```sh
purchase_id|product_id    |idx|product_id|
-----------+--------------+---+----------+
100001     |A001,A002,A003|  1|A001      |
100001     |A001,A002,A003|  2|A002      |
100001     |A001,A002,A003|  3|A003      |
100002     |A001,A002     |  1|A001      |
100002     |A001,A002     |  2|A002      |
100003     |A001          |  1|A001      |
```
