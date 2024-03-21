# 다면적 축을 사용해 데이터 집약

시계열로 매출 금액의 추이를 표현하는것 이외에도, 상품 카테고리에 주목해서
매출 내역을 집계하거나 구성하는 비율을 집계하는 등 리포트의 표현방법은 굉장히 다양하다

```sql

DROP TABLE IF EXISTS purchase_detail_log;

CREATE TABLE purchase_detail_log(
    dt           varchar(255)
  , order_id     integer
  , user_id      varchar(255)
  , item_id      varchar(255)
  , price        integer
  , category     varchar(255)
  , sub_category varchar(255)
);

INSERT INTO purchase_detail_log
VALUES
    ('2017-01-18', 48291, 'usr33395', 'lad533', 37300,  'ladys_fashion', 'bag')
  , ('2017-01-18', 48291, 'usr33395', 'lad329', 97300,  'ladys_fashion', 'jacket')
  , ('2017-01-18', 48291, 'usr33395', 'lad102', 114600, 'ladys_fashion', 'jacket')
  , ('2017-01-18', 48291, 'usr33395', 'lad886', 33300,  'ladys_fashion', 'bag')
  , ('2017-01-18', 48292, 'usr52832', 'dvd871', 32800,  'dvd'          , 'documentary')
  , ('2017-01-18', 48292, 'usr52832', 'gam167', 26000,  'game'         , 'accessories')
  , ('2017-01-18', 48292, 'usr52832', 'lad289', 57300,  'ladys_fashion', 'bag')
  , ('2017-01-18', 48293, 'usr28891', 'out977', 28600,  'outdoor'      , 'camp')
  , ('2017-01-18', 48293, 'usr28891', 'boo256', 22500,  'book'         , 'business')
  , ('2017-01-18', 48293, 'usr28891', 'lad125', 61500,  'ladys_fashion', 'jacket')
  , ('2017-01-18', 48294, 'usr33604', 'mem233', 116300, 'mens_fashion' , 'jacket')
  , ('2017-01-18', 48294, 'usr33604', 'cd477' , 25800,  'cd'           , 'classic')
  , ('2017-01-18', 48294, 'usr33604', 'boo468', 31000,  'book'         , 'business')
  , ('2017-01-18', 48294, 'usr33604', 'foo402', 48700,  'food'         , 'meats')
  , ('2017-01-18', 48295, 'usr38013', 'foo134', 32000,  'food'         , 'fish')
  , ('2017-01-18', 48295, 'usr38013', 'lad147', 96100,  'ladys_fashion', 'jacket')
 ;

 SELECT * FROM purchase_detail_log;

```

```sh
dt        |order_id|user_id |item_id|price |category     |sub_category|
----------+--------+--------+-------+------+-------------+------------+
2017-01-18|   48291|usr33395|lad533 | 37300|ladys_fashion|bag         |
2017-01-18|   48291|usr33395|lad329 | 97300|ladys_fashion|jacket      |
2017-01-18|   48291|usr33395|lad102 |114600|ladys_fashion|jacket      |
2017-01-18|   48291|usr33395|lad886 | 33300|ladys_fashion|bag         |
2017-01-18|   48292|usr52832|dvd871 | 32800|dvd          |documentary |
2017-01-18|   48292|usr52832|gam167 | 26000|game         |accessories |
2017-01-18|   48292|usr52832|lad289 | 57300|ladys_fashion|bag         |
2017-01-18|   48293|usr28891|out977 | 28600|outdoor      |camp        |
2017-01-18|   48293|usr28891|boo256 | 22500|book         |business    |
2017-01-18|   48293|usr28891|lad125 | 61500|ladys_fashion|jacket      |
2017-01-18|   48294|usr33604|mem233 |116300|mens_fashion |jacket      |
2017-01-18|   48294|usr33604|cd477  | 25800|cd           |classic     |
2017-01-18|   48294|usr33604|boo468 | 31000|book         |business    |
2017-01-18|   48294|usr33604|foo402 | 48700|food         |meats       |
2017-01-18|   48295|usr38013|foo134 | 32000|food         |fish        |
2017-01-18|   48295|usr38013|lad147 | 96100|ladys_fashion|jacket      |
```

## 카테고리별 매출과 소계 계산

대분류, 소분류가 all 이면 전체 매출 합계(총계), 두번째 소분류가 all 레코드이면
대분류의 매출 합계(소계), 대분류, 소분류가 all 이 아니면 해당 카테고리의 소계를 출력

```sql
WITH
sub_category_amount AS (
    SELECT
            category
        ,   sub_category
        ,   sum(price) amount
    FROM
        purchase_detail_log
    GROUP BY
        category, sub_category
    ORDER BY category, sub_category
),
category_amount AS (
    SELECT
            category
        ,   'all' sub_category
        ,   sum(price) amount
    FROM
        purchase_detail_log
    GROUP BY
        category
    ORDER BY category, sub_category
),
total_amount AS (
    SELECT
            'all' category
        ,   'all' sub_category
        ,   sum(price) amount
    FROM
        purchase_detail_log
    ORDER BY category, sub_category
)
SELECT
    *
FROM
    sub_category_amount
UNION ALL
SELECT
    *
FROM
    category_amount
UNION ALL
SELECT
    *
FROM
    total_amount
```

```sh
category     |sub_category|amount|
-------------+------------+------+
book         |business    | 53500|
cd           |classic     | 25800|
dvd          |documentary | 32800|
food         |fish        | 32000|
food         |meats       | 48700|
game         |accessories | 26000|
ladys_fashion|bag         |127900|
ladys_fashion|jacket      |369500|
mens_fashion |jacket      |116300|
outdoor      |camp        | 28600|
book         |all         | 53500|
cd           |all         | 25800|
dvd          |all         | 32800|
food         |all         | 80700|
game         |all         | 26000|
ladys_fashion|all         |497400|
mens_fashion |all         |116300|
outdoor      |all         | 28600|
all          |all         |861100|
```

`UNION ALL` 은 성능상 좋지 않으며 조금더 성능이 좋은 `ROLLUP` 을 사용하여
계산할수 있다

```sql
SELECT
        COALESCE (category, 'all') category
    ,   COALESCE (sub_category, 'all') sub_category
    ,   SUM (price) amount
FROM
    purchase_detail_log pdl
GROUP BY
    ROLLUP (category, sub_category);

```

```sh
category     |sub_category|amount|
-------------+------------+------+
all          |all         |861100|
ladys_fashion|bag         |127900|
food         |fish        | 32000|
food         |meats       | 48700|
dvd          |documentary | 32800|
mens_fashion |jacket      |116300|
book         |business    | 53500|
outdoor      |camp        | 28600|
game         |accessories | 26000|
ladys_fashion|jacket      |369500|
cd           |classic     | 25800|
game         |all         | 26000|
book         |all         | 53500|
ladys_fashion|all         |497400|
outdoor      |all         | 28600|
mens_fashion |all         |116300|
cd           |all         | 25800|
dvd          |all         | 32800|
food         |all         | 80700|
```

`ROLLUP` 은 소계를 구할 컬럼값을 순서대로 넣어주면,
해당 컬럼의 값의 모든 소계를 구해서 반환한다

`COALESCE` 를 사용하여 `ROLLUP` 시 값이 `NULL` 일경우 `all` 로 변환해주면
모든 `NULL` 값은 `all` 로 표현되어 출력된다

> 예를들어 `category` 의 모든 총계를 구한다고 하자
> 이 경우에는 `sub_category` 가 없으며, 오직 `category` 기준으로 모든 소계를 합산한다
>
> 이러한 경우에는 `sub_category` 는 `NULL` 이 되므로, `all` 로 변환하는게
> 시각적으로 정리되어 좋을것이다

## ABC 분석으로 잘 팔리는 상품 판별

`ABC 분석` 은 제고 관리등에서 사용하는 분석 방법이다
매출 중요도에 따라 상품을 나누고, 그에 맞는 전략을 만들때 사용한다

다음의 분류법으로 나눈다

- A: 상위 0 ~ 70%
- B: 상위 70 ~ 90%
- C: 상위 90 ~ 100%

```sql
WITH
    monthly_amount AS (
        SELECT
                category
            ,   sum(price) amount
        FROM
            purchase_detail_log pdl
        GROUP BY
            category
    ),
    sales_composite_ratio AS (
        SELECT
                category
            ,   amount
            ,   round(100
                    * amount
                    / sum(amount) OVER ()
                    , 2
                ) composite_ratio
            ,   round(100
                    * sum(amount) OVER (ORDER BY amount DESC)
                    / sum(amount) OVER ()
                    , 2
                ) cumulative_ratio
        FROM
            monthly_amount
    )
SELECT
        *
    ,   CASE
            WHEN cumulative_ratio <= 70 THEN 'A'
            WHEN cumulative_ratio <= 90 THEN 'B'
            WHEN cumulative_ratio <= 100 THEN 'C'
        END
FROM
    sales_composite_ratio;
```

```sh
category     |amount|composite_ratio|cumulative_ratio|case|
-------------+------+---------------+----------------+----+
ladys_fashion|497400|          57.76|           57.76|A   |
mens_fashion |116300|          13.51|           71.27|B   |
food         | 80700|           9.37|           80.64|B   |
book         | 53500|           6.21|           86.85|B   |
dvd          | 32800|           3.81|           90.66|C   |
outdoor      | 28600|           3.32|           93.98|C   |
game         | 26000|           3.02|           97.00|C   |
cd           | 25800|           3.00|          100.00|C   |
```

## 팬 차트로 상품의 매출 증가율 확인

팬 차트는 어떤 기준 시점을 100% 로 두고, 이후의 숫자 변동을 확인할수
있도록 해주는 그래프이다

펜차트를 사용하면 변화가 백분율로 표시되므로, 작은 변화도
쉽게 인지하고 상황 판단을 할수 있다

날짜, 카테고리, 매출, rate 를 구한다
팬 차트이므로, rate 는 시작월을 100% 로 해서 이후 월들의 비율을 측정한다

```sql
WITH
    daily_category_amount AS (
        SELECT
                dt
            ,   category
            ,   substring(dt, 1, 4) AS "y"
            ,   substring(dt, 6, 2) AS "m"
            ,   sum(price) AS amount
        FROM
            purchase_detail_log pdl
        GROUP BY
            dt, category
    ),
    monthly_category_amount as (
        SELECT
                concat("y", '-', "m") year_month
            ,   category
            ,   amount
            ,   FIRST_VALUE (amount) OVER (
                    PARTITION BY y, m, category
                    ORDER BY y, m, category
                    ROWS UNBOUNDED PRECEDING
                ) base_amount
            ,   (
                    100
                    * amount
                    / FIRST_VALUE (amount) OVER (
                        PARTITION BY y, m, category
                        ORDER BY y, m, category
                        ROWS UNBOUNDED PRECEDING
                    )
                ) rate
        from
            daily_category_amount
        )
select
    *
from monthly_category_amount;
```

여기서 중요한 부분이 `FIRST_VALUE` 이다
`ROWS UNBOUNDED PRECEDING` 을 통해서, 현재 로우에서 최상단 로우까지
프레임을 잡고 그중 첫번째 로우에서 `amount` 값을 가져오는 로직이다

이렇게 가장 첫번째 `row` 의 `amount` 를 `100%` 로 잡고
현재 `row` 의 `amount` 를 나누고 `100` 을 곱하면, 현재 비율이 나오며
비교 가능한 팬 차트가 형성된다

> 팬 차트는 어떤 시점에서 매출 금액을 기준점으로 채택할 것인가가 중요하다
> 책에서는 8월 매출이 매년 늘어나느 상품이 있다면, 8 월을 기주으로 잡을 경우
> 해당 상품은 이후로 계속 감소하는 그래프가 된다
>
> 이러한 부분을 고려해서 변동이 적은 달을 기준으로 매출 변화를 확인하는것이 좋다

## 히스토그램으로 구매 가격대 집계

도수 분포표를 만들어야 한다

```sql
WITH
    stats AS (
        SELECT
                max(price) + 1 max_price
            ,   min(price) min_price
            ,   max(price) + 1 - min(price) range_price
            ,   10 bucket_num
        FROM purchase_detail_log pdl
    )
SELECT
        price
    ,   min_price
    ,   price - min_price diff
    ,   range_price
    -- 계층 범위: 금액 범위를 계층 수로 나눈것
    ,  1.0 * range_price / bucket_num bucket_range
    -- 계층 판정: FLOOR(정규화 금액 / 계층 범위)
    ,   floor(
            1.0
            * (price - min_price)
            / (1.0 * range_price / bucket_num)
        ) + 1 bucket
FROM purchase_detail_log
CROSS JOIN stats;
```

이부분은 다시 살펴볼 내용인거 같다
히스토그램 관련된 부분을 보고 다시 봐야 겠다..
