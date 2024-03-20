# 시계열 기반으로 데이터 집계하기

시계열로 매출 금액을 집계하면 어떤 규칙성을 찾을수도 있으며,
어떤 기간과 비교했을때 변화폭을 확인할수도 있다

## 샘플데이터

```sql
CREATE TABLE purchase_log(
    dt              varchar(255)
  , order_id        integer
  , user_id         varchar(255)
  , purchase_amount integer
);

INSERT INTO purchase_log
VALUES
    ('2014-01-01',  1, 'rhwpvvitou', 13900)
  , ('2014-01-01',  2, 'hqnwoamzic', 10616)
  , ('2014-01-02',  3, 'tzlmqryunr', 21156)
  , ('2014-01-02',  4, 'wkmqqwbyai', 14893)
  , ('2014-01-03',  5, 'ciecbedwbq', 13054)
  , ('2014-01-03',  6, 'svgnbqsagx', 24384)
  , ('2014-01-03',  7, 'dfgqftdocu', 15591)
  , ('2014-01-04',  8, 'sbgqlzkvyn',  3025)
  , ('2014-01-04',  9, 'lbedmngbol', 24215)
  , ('2014-01-04', 10, 'itlvssbsgx',  2059)
  , ('2014-01-05', 11, 'jqcmmguhik',  4235)
  , ('2014-01-05', 12, 'jgotcrfeyn', 28013)
  , ('2014-01-05', 13, 'pgeojzoshx', 16008)
  , ('2014-01-06', 14, 'msjberhxnx',  1980)
  , ('2014-01-06', 15, 'tlhbolohte', 23494)
  , ('2014-01-06', 16, 'gbchhkcotf',  3966)
  , ('2014-01-07', 17, 'zfmbpvpzvu', 28159)
  , ('2014-01-07', 18, 'yauwzpaxtx',  8715)
  , ('2014-01-07', 19, 'uyqboqfgex', 10805)
  , ('2014-01-08', 20, 'hiqdkrzcpq',  3462)
  , ('2014-01-08', 21, 'zosbvlylpv', 13999)
  , ('2014-01-08', 22, 'bwfbchzgnl',  2299)
  , ('2014-01-09', 23, 'zzgauelgrt', 16475)
  , ('2014-01-09', 24, 'qrzfcwecge',  6469)
  , ('2014-01-10', 25, 'njbpsrvvcq', 16584)
  , ('2014-01-10', 26, 'cyxfgumkst', 11339)

select * from purchase_log;
```

```sh
dt        |order_id|user_id   |purchase_amount|
----------+--------+----------+---------------+
2014-01-01|       1|rhwpvvitou|          13900|
2014-01-01|       2|hqnwoamzic|          10616|
2014-01-02|       3|tzlmqryunr|          21156|
2014-01-02|       4|wkmqqwbyai|          14893|
2014-01-03|       5|ciecbedwbq|          13054|
2014-01-03|       6|svgnbqsagx|          24384|
2014-01-03|       7|dfgqftdocu|          15591|
2014-01-04|       8|sbgqlzkvyn|           3025|
2014-01-04|       9|lbedmngbol|          24215|
2014-01-04|      10|itlvssbsgx|           2059|
2014-01-05|      11|jqcmmguhik|           4235|
2014-01-05|      12|jgotcrfeyn|          28013|
2014-01-05|      13|pgeojzoshx|          16008|
2014-01-06|      14|msjberhxnx|           1980|
2014-01-06|      15|tlhbolohte|          23494|
2014-01-06|      16|gbchhkcotf|           3966|
2014-01-07|      17|zfmbpvpzvu|          28159|
2014-01-07|      18|yauwzpaxtx|           8715|
2014-01-07|      19|uyqboqfgex|          10805|
2014-01-08|      20|hiqdkrzcpq|           3462|
2014-01-08|      21|zosbvlylpv|          13999|
2014-01-08|      22|bwfbchzgnl|           2299|
2014-01-09|      23|zzgauelgrt|          16475|
2014-01-09|      24|qrzfcwecge|           6469|
2014-01-10|      25|njbpsrvvcq|          16584|
2014-01-10|      26|cyxfgumkst|          11339|
```

## 날짜별 매출 집계

```sql

SELECT
        dt
    ,   count(dt) purchase_count
    ,   sum(purchase_amount) total_amount
    ,   round(avg(purchase_amount), 2) avg_amount
FROM
    purchase_log
GROUP BY dt;

```

```sh
dt        |purchase_count|total_amount|avg_amount|
----------+--------------+------------+----------+
2014-01-01|             2|       24516|  12258.00|
2014-01-02|             2|       36049|  18024.50|
2014-01-03|             3|       53029|  17676.33|
2014-01-04|             3|       29299|   9766.33|
2014-01-05|             3|       48256|  16085.33|
2014-01-06|             3|       29440|   9813.33|
2014-01-07|             3|       47679|  15893.00|
2014-01-08|             3|       19760|   6586.67|
2014-01-09|             2|       22944|  11472.00|
2014-01-10|             2|       27923|  13961.50|
```

## 이동평균을 사용한 날짜별 추이

`날짜별 매출과 7일 이동평균` 으로 표현하는것이 좋다

```sql
SELECT
        dt
    ,   sum(purchase_amount) total_amount
    --  현재 row 에서 위로 6 row 의 purchase_amount 의 값을 더하고
    --  평균을 계산
    --  row 가 6 개가 되지 못하면 해당 row 의 개수만큼 더하고 나눈다
    ,   avg(sum(purchase_amount)) OVER (
            ORDER BY dt
            ROWS
                BETWEEN 6 PRECEDING AND
                CURRENT ROW
        ) sevent_days_avg
    --  현재 row 에서 위로 6 row 의 purchase_amount 의 값을 더하고
    --  평균을 계산
    --  현재 row 에서 위로 6 row 이니 count(*) 는 7 이 되어야 한다
    --  자신의 row 위로 6 row 가 있다면, 모두 합하고, 평균값을 낸다
    ,   CASE
            WHEN
                7 = COUNT(*) OVER (
                    ORDER BY dt
                    ROWS
                        BETWEEN 6 PRECEDING AND
                        CURRENT ROW
                 )
            THEN
                avg(sum(purchase_amount)) OVER (
                    ORDER BY dt
                    ROWS
                        BETWEEN 6 PRECEDING AND
                        CURRENT ROW
                )
        END seven_day_avg_strict
FROM
    purchase_log pl
GROUP BY dt;
```

```sh
dt        |total_amount|sevent_days_avg   |seven_day_avg_strict|
----------+------------+------------------+--------------------+
2014-01-01|       24516|24516.000000000000|                    |
2014-01-02|       36049|30282.500000000000|                    |
2014-01-03|       53029|37864.666666666667|                    |
2014-01-04|       29299|35723.250000000000|                    |
2014-01-05|       48256|38229.800000000000|                    |
2014-01-06|       29440|36764.833333333333|                    |
2014-01-07|       47679|38324.000000000000|  38324.000000000000|
2014-01-08|       19760|37644.571428571429|  37644.571428571429|
2014-01-09|       22944|35772.428571428571|  35772.428571428571|
2014-01-10|       27923|32185.857142857143|  32185.857142857143|
```

## 당월 매출 누계

```sql
SELECT
        dt
    ,   substring(dt, 1, 7) year_month
    ,   sum(purchase_amount) total_amount
    ,   sum(sum(purchase_amount)) OVER (
            PARTITION BY substring(dt, 1, 7)
            ORDER BY dt
            ROWS
                UNBOUNDED PRECEDING
        ) AS agg
FROM
    purchase_log
GROUP BY dt;

```

```sh
dt        |year_month|total_amount|agg   |
----------+----------+------------+------+
2014-01-01|2014-01   |       24516| 24516|
2014-01-02|2014-01   |       36049| 60565|
2014-01-03|2014-01   |       53029|113594|
2014-01-04|2014-01   |       29299|142893|
2014-01-05|2014-01   |       48256|191149|
2014-01-06|2014-01   |       29440|220589|
2014-01-07|2014-01   |       47679|268268|
2014-01-08|2014-01   |       19760|288028|
2014-01-09|2014-01   |       22944|310972|
2014-01-10|2014-01   |       27923|338895|
```

다음처럼 `with` 문을 사용하여 처리도 가능하다

```sql
WITH
    daily_purchase AS (
        SELECT
                dt
            ,   SUBSTRING(dt, 1, 4) "year"
            ,   SUBSTRING(dt, 6, 2) "month"
            ,   SUBSTRING(dt, 9, 2) "date"
            ,   sum(purchase_amount) "total_amount"
        FROM
            purchase_log
        GROUP BY dt
    )
SELECT
        dt
    ,   concat("year", '-', "month") "year_month"
    ,   total_amount
    ,   sum(total_amount) OVER (
            PARTITION BY "year" || '-' || "month"
            ORDER BY dt
            ROWS
                UNBOUNDED PRECEDING
        )
FROM
    daily_purchase;

```

```sh
dt        |year_month|total_amount|sum   |
----------+----------+------------+------+
2014-01-01|2014-01   |       24516| 24516|
2014-01-02|2014-01   |       36049| 60565|
2014-01-03|2014-01   |       53029|113594|
2014-01-04|2014-01   |       29299|142893|
2014-01-05|2014-01   |       48256|191149|
2014-01-06|2014-01   |       29440|220589|
2014-01-07|2014-01   |       47679|268268|
2014-01-08|2014-01   |       19760|288028|
2014-01-09|2014-01   |       22944|310972|
2014-01-10|2014-01   |       27923|338895|
```

그럼 누계값이 아니라 `2014-01` 의 모든 매출의 총계를 구한다면
다음처럼도 될거 같다

```sql
SELECT
    SUBSTRING(dt, 1, 7) year_month,
    sum(purchase_amount) total_amount
FROM
    purchase_log
GROUP BY SUBSTRING(dt, 1, 7);
```

```sh
year_month|total_amount|
----------+------------+
2014-01   |      338895|
```

## 월별 매출의 작대비 구하기

월별 매출 추이를 추출해서 작년이 해당 월의 매출과 비교한다

```sql
DROP TABLE IF EXISTS purchase_log;
CREATE TABLE purchase_log(
    dt              varchar(255)
  , order_id        integer
  , user_id         varchar(255)
  , purchase_amount integer
);


INSERT INTO purchase_log
VALUES
    ('2014-01-01',    1, 'rhwpvvitou', 13900)
  , ('2014-02-08',   95, 'chtanrqtzj', 28469)
  , ('2014-03-09',  168, 'bcqgtwxdgq', 18899)
  , ('2014-04-11',  250, 'kdjyplrxtk', 12394)
  , ('2014-05-11',  325, 'pgnjnnapsc',  2282)
  , ('2014-06-12',  400, 'iztgctnnlh', 10180)
  , ('2014-07-11',  475, 'eucjmxvjkj',  4027)
  , ('2014-08-10',  550, 'fqwvlvndef',  6243)
  , ('2014-09-10',  625, 'mhwhxfxrxq',  3832)
  , ('2014-10-11',  700, 'wyrgiyvaia',  6716)
  , ('2014-11-10',  775, 'cwpdvmhhwh', 16444)
  , ('2014-12-10',  850, 'eqeaqvixkf', 29199)
  , ('2015-01-09',  925, 'efmclayfnr', 22111)
  , ('2015-02-10', 1000, 'qnebafrkco', 11965)
  , ('2015-03-12', 1075, 'gsvqniykgx', 20215)
  , ('2015-04-12', 1150, 'ayzvjvnocm', 11792)
  , ('2015-05-13', 1225, 'knhevkibbp', 18087)
  , ('2015-06-10', 1291, 'wxhxmzqxuw', 18859)
  , ('2015-07-10', 1366, 'krrcpumtzb', 14919)
  , ('2015-08-08', 1441, 'lpglkecvsl', 12906)
  , ('2015-09-07', 1516, 'mgtlsfgfbj',  5696)
  , ('2015-10-07', 1591, 'trgjscaajt', 13398)
  , ('2015-11-06', 1666, 'ccfbjyeqrb',  6213)
  , ('2015-12-05', 1741, 'onooskbtzp', 26024)
```

```sql
WITH
    daily_purchase as (
        SELECT
                dt
            ,   substring(dt, 1, 4) "year"
            ,   substring(dt, 6, 2) "month"
            ,   substring(dt, 9, 2) "day"
            ,   sum(purchase_amount) "total_amount"
        FROM
            purchase_log
        GROUP BY dt
    )
SELECT
        month
    ,   sum(
            CASE
                WHEN year = '2014' THEN total_amount
            END
        ) "2014"
    ,   sum(
            CASE
                WHEN year = '2015' THEN total_amount
            END
        ) "2015"
    ,   round(100.0 *
        sum(
            CASE
                WHEN year = '2015' THEN total_amount
            END
        ) /
        sum(
            CASE
                WHEN year = '2014' THEN total_amount
            END
        ), 2) || '%' rate
FROM
    daily_purchase
group by month
ORDER BY month;
```

```sh
month|2014 |2015 |rate   |
-----+-----+-----+-------+
01   |13900|22111|159.07%|
02   |28469|11965|42.03% |
03   |18899|20215|106.96%|
04   |12394|11792|95.14% |
05   | 2282|18087|792.59%|
06   |10180|18859|185.26%|
07   | 4027|14919|370.47%|
08   | 6243|12906|206.73%|
09   | 3832| 5696|148.64%|
10   | 6716|13398|199.49%|
11   |16444| 6213|37.78% |
12   |29199|26024|89.13% |
```

비율을 계산하여 출력한 결과이다

## Z 차트로 업적의 추이 확인

Z 차트는 `월차매출`, `매출누계`, `이동년계` 라는 3 개의 지표로 구성되어
계절 변동의영향을 배제하고 트렌드를 분석한다

- `월차매출`: 월 매출 합계

- `매출누계` : 해당월 매출에서 이전 월까지의 매출 누계

- `이동년계` : 해당월 과 이전 11 개월까지의 매출 합계

### Z 차트 분석 정리

#### 매출 누계에서 주목할점

월차매출이 일정할 경우, 매출 누계는 직선이 된다
가로축에서 오른쪽으로 갈수록 기울기가 급해지는 곡선(안쪽으로 둥글게된 곡선)은
매출의 상승, 기울기가 완만해지는 곡선(바깥쪽으로 둥글게된 곡선)은 매출의 감소를 뜻한다

#### 이동년계에서 주목할 점

작년과 올해의 매출이 일정하다면 이동년계가 직선이 된다
오른쪽위로 올라간다면 매출이 오른다는 뜻이고, 오른쪽 아래로 내려간다면
감소한다는 뜻이다

이는 1년동안 매출의 추이를 읽어내기에 적합하다

```sql
WITH
    daily_purchase AS (
        SELECT
                SUBSTRING(dt, 1, 4) "year"
            ,   SUBSTRING(dt, 6, 2) "month"
            ,   SUBSTRING(dt, 9, 2) "date"
            ,   sum(purchase_amount) "total_amount"
        FROM
            purchase_log
        GROUP BY dt
    ),
    monthly_purchase AS (
        SELECT
            year,
            month,
            sum(total_amount) year_month_amount
        FROM
            daily_purchase
        GROUP BY
            year, month
    ),
    calc_index AS (
        SELECT
                year
            ,   month
            ,   year_month_amount
            ,   sum(
                    CASE
                        WHEN year = '2015' THEN year_month_amount
                    END
                ) OVER (
                    ORDER BY year, month
                    ROWS
                        UNBOUNDED PRECEDING
                ) "agg_month_amount"
            ,   sum(year_month_amount) OVER (
                    ORDER BY year, month
                    ROWS BETWEEN
                        11 PRECEDING AND CURRENT ROW
                ) "year_avt_amount"
        FROM
            monthly_purchase
        ORDER BY
            year, month
    )
SELECT
    *
FROM
    calc_index
WHERE
    year = '2015';

```

```sh
year|month|year_month_amount|agg_month_amount|year_avt_amount|
----+-----+-----------------+----------------+---------------+
2015|01   |            22111|           22111|         160796|
2015|02   |            11965|           34076|         144292|
2015|03   |            20215|           54291|         145608|
2015|04   |            11792|           66083|         145006|
2015|05   |            18087|           84170|         160811|
2015|06   |            18859|          103029|         169490|
2015|07   |            14919|          117948|         180382|
2015|08   |            12906|          130854|         187045|
2015|09   |             5696|          136550|         188909|
2015|10   |            13398|          149948|         195591|
2015|11   |             6213|          156161|         185360|
2015|12   |            26024|          182185|         182185|
```

## 매출을 파악할때 중요 포인트

매출의 결과의 원이이라 할수 있는 구매횟수, 구매 단가 등의 주변 데이터를 고려해야 한다
다음은, 판매월, 판매횟수, 평균구매액, 매출액, 누계 매출액, 작년 매출액, 작년비를구한다

```sql
WITH
    daily_purchase AS (
        SELECT
                dt
            ,   substring(dt, 1, 4) "year"
            ,   substring(dt, 6, 2) "month"
            ,   substring(dt, 9, 2) "day"
            ,   sum(purchase_amount) "total_amount"
        FROM
            purchase_log
        GROUP BY dt
    ),
    monthly_purchase AS (
        SELECT
                year
            ,   month
            ,   sum(orders) AS orders
            ,   avg(purchase_amount) AS avg_amount
            ,   sum(purchase_amount) AS monthly
        FROM
            daily_purchase
        GROUP BY
            year, month
    )
SELECT
        concat(year, '-', month) year_month
    ,   orders
    ,   avg_amount
    ,   monthly
    ,   sum(monthly)
        OVER (
            PARTITION BY year
            ORDER BY month
            ROWS
                UNBOUNDED PRECEDING
        ) agg_amount
    ,   lag(monthly, 12)
        OVER (
                ORDER BY year, month
                ROWS BETWEEN
                    12 PRECEDING AND 12 PRECEDING
        ) last_year
    ,   round(
            100.0
            *   monthly
            /   lag(monthly, 12)
                OVER (
                    ORDER BY year, month
                    ROWS BETWEEN
                        12 PRECEDING AND 12 PRECEDING
                )
        , 2) rate
FROM
    monthly_purchase
ORDER BY
    year_month;
```

데이터가 없어서, 일단 이렇게 쿼리로만 본다
여기서 이해해야할 부분은 다음부분이다

```sql
    ,   lag(monthly, 12)
        OVER (
                ORDER BY year, month
                ROWS BETWEEN
                    12 PRECEDING AND 12 PRECEDING
        ) last_year
```

다음 부분의 `ROWS BETWEEN 12 PRECEDING AND 12 PRECEDING` 에 대해서 이해해야
쿼리가 이해된다

위의 구문은, `현재 row 에서 위로 12 행이고, 현재 row 에서 위로 12 행까지`
를 `window frame` 으로 잡는다

말이 이상할수 있는데, `현재 row` 에서 `위로 12행` 은 해당 월의 12 개월 행을
뜻한다.

해당 `현재 row 에서 12 개월 이전 행` 에서 `현재 row 에서 12 개월 이전 행` 까지
`frame` 으로 잡으니 해당하는 `12 개월 이전 행` 만 `frame` 에 해당된다
