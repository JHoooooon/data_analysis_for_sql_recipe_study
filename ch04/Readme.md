# 여러개의 테이블 조작

## 여러개의 테이블을 세로로 결합

애플리케이션1 과 애플리케이션2 가 있을때, 각각의 사용자를 저장한 테이블이다

```sql
CREATE TABLE app1_mst_users
(
        user_id char(4)
    ,   name    varchar(50)
    ,   email   varchar(150)
)

CREATE TABLE app2_mst_users
(
        user_id char(4)
    ,   name    varchar(50)
    ,   phone   varchar(13)
)

INSERT INTO app1_mst_users
VALUES
(
    'U001',
    'Sato',
    'sato@example.com'
),
(
    'U002',
    'Suzuki',
    'Suzuki@example.com'
);

INSERT INTO app2_mst_users
VALUES
(
    'U001',
    'Ito',
    '080-xxxx-xxxx'
),
(
    'U002',
    'Tanaka',
    '070-xxxx-xxxx'
);

SELECT * FROM app1_mst_users;
SELECT * FROM app2_mst_users;
```

```sh
user_id|name  |email             |
-------+------+------------------+
U001   |Sato  |sato@example.com  |
U002   |Suzuki|Suzuki@example.com|
```

```sh
user_id|name  |phone        |
-------+------+-------------+
U001   |Ito   |080-xxxx-xxxx|
U002   |Tanaka|070-xxxx-xxxx|
```

위의 테이블은 `user_id` 는 동일하지만 내용이 전혀 다르다
이처럼 비슷한 테이블의 데이터를 일괄 처리하고 싶은경우 다음처럼 한다

아래는 `app_name`, `user_id`, `name`, `email` 인 `field` 를 가진
테이블을 생성한다

```sql
SELECT 'app1' app_name, user_id, name, email
FROM app1_mst_users
UNION ALL
SELECT 'app2' app_name, user_id, name, null as email
FROM app1_mst_users
```

```sh
app_name|user_id|name  |email             |
--------+-------+------+------------------+
app1    |U001   |Sato  |sato@example.com  |
app1    |U002   |Suzuki|Suzuki@example.com|
app2    |U001   |Sato  |                  |
app2    |U002   |Suzuki|                  |
```

`union all` 은 반드시 `column` 의 수가 같아야 한다
그렇지 않으면 에러가 나오므로, 주의해야 한다

> `union all` 대신 `union distinct` 혹은 `union` 을 사용하면
> 중복된 데이터는 제외한 결과를 출력한다

## 여러개의 테이블을 가로로 정렬

```sql
CREATE TABLE mst_category
(
        category_id int GENERATED BY DEFAULT AS IDENTITY
    ,   name    varchar(150)
);

CREATE TABLE category_sales
(
        category_id int GENERATED BY DEFAULT AS IDENTITY
    ,   sales    bigint
);
CREATE TABLE product_sale_ranking
(
        category_id int
    ,   rank        int
    ,   product_id  char(4)
    ,   sales       int
);

INSERT INTO mst_category (name)
VALUES
(
       'dvd'
),
(
       'cd'
),
(
       'book'
);

INSERT INTO category_sales (sales)
VALUES
(
    850000
),
(
    500000
);

INSERT INTO product_sale_ranking
VALUES
(
        1
    ,   1
    ,   'D001'
    ,   50000
),
(
        1
    ,   2
    ,   'D002'
    ,   20000
),
(
        1
    ,   3
    ,   'D003'
    ,   10000
),
(
        2
    ,   1
    ,   'C001'
    ,   30000
),
(
        2
    ,   2
    ,   'C002'
    ,   20000
),
(
        2
    ,   3
    ,   'C003'
    ,   10000
);

SELECT * FROM mst_category ;
SELECT * FROM category_sales ;
SELECT * FROM product_sale_ranking  ;

```

```sh
category_id|name|
-----------+----+
          1|dvd |
          2|cd  |
          3|book|

category_id|sales |
-----------+------+
          1|850000|
          2|500000|

category_id|rank|product_id|sales|
-----------+----+----------+-----+
          1|   1|D001      |50000|
          1|   2|D002      |20000|
          1|   3|D003      |10000|
          2|   1|C001      |30000|
          2|   2|C002      |20000|
          2|   3|C003      |10000|
```

카테고리별 마스터 테이블에 카테고리별 매출 또는 카테고리별 상품 매출 순위
를 기반으로 카테고리 내부에서 가장 잘 팔리는 상품 ID 를 보아 테이블로 보도록
한다

```sql
SELECT m.category_id, m.name, p.product_id, c.sales, p.rank
FROM mst_category m
LEFT JOIN category_sales c
ON m.category_id = c.category_id
LEFT JOIN product_sale_ranking p
ON m.category_id = p.category_id AND rank = 1
```

```sh
category_id|name|product_id|sales |rank|
-----------+----+----------+------+----+
          1|dvd |D001      |850000|   1|
          2|cd  |C001      |500000|   1|
          3|book|          |      |    |
```

`LEFT OUTER JOIN` 을 사용하여 왼쪽 `table` 을 기준으로 `JOIN` 한다
다음은 `sub query` 를 사용하여 같은 로직을 만들어본다

```sql
SELECT
        m.category_id
    ,   m.name
    ,   (
            SELECT
                    p.product_id
            FROM
                product_sale_ranking p
            WHERE
                p.category_id = m.category_id
                AND RANK = 1
        ) product_id
    ,   (
            SELECT
                    p.rank
            FROM
                product_sale_ranking p
            WHERE
                p.category_id = m.category_id
                AND RANK = 1
        ) rank
    ,   (
            SELECT
                    c.sales
            FROM
                category_sales c
            WHERE
                c.category_id = m.category_id
        ) sales
FROM mst_category m;
```

```sh
category_id|name|product_id|rank|sales |
-----------+----+----------+----+------+
          1|dvd |D001      |   1|850000|
          2|cd  |C001      |   1|500000|
          3|book|          |    |      |
```

완전히 같은 결과를 얻을수 있다

### 조건 플래그를 0 과 1 로 표현

마스터 테이블의 속성 조건을 `0` 또는 `1` 이라는
플래그로 표현하는 방법을 보여준다

```sql
CREATE TABLE mst_users_with_card_number
(
        user_id     char(4)
    ,   card_number char(19)
);

CREATE TABLE purchase_log
(
        purchase_id     char(5)
    ,   user_id         char(4)
    ,   amount          int
    ,   stamp           timestamp
);

INSERT INTO mst_users_with_card_number
VALUES
('U001', '1234-xxxx-xxxx-xxxx'),
('U003',  NULL);
('U002', '5678-xxxx-xxxx-xxxx');

INSERT INTO purchase_log
VALUES
('10001', 'U001', 200, '2017-01-30 10:00:00'),
('10002', 'U001', 500, '2017-02-10 10:00:00'),
('10003', 'U001', 200, '2017-02-12 10:00:00'),
('10004', 'U002', 800, '2017-03-01 10:00:00'),
('10005', 'U002', 400, '2017-03-02 10:00:00');

SELECT * FROM mst_users_with_card_number ;
SELECT * FROM purchase_log pl ;
```

```sh
user_id|card_number        |
-------+-------------------+
U001   |1234-xxxx-xxxx-xxxx|
U003   |                   |
U002   |5678-xxxx-xxxx-xxxx|

purchase_id|user_id|amount|stamp                  |
-----------+-------+------+-----------------------+
10001      |U001   |   200|2017-01-30 10:00:00.000|
10002      |U001   |   500|2017-02-10 10:00:00.000|
10003      |U001   |   200|2017-02-12 10:00:00.000|
10004      |U002   |   800|2017-03-01 10:00:00.000|
10005      |U002   |   400|2017-03-02 10:00:00.000|
```

다음은 신용카드 등록 여부, 구매이력 여부라는 두가지 조건을 `0`, `1` 로 표현한다

```sql
SELECT
        m.user_id
    ,   count(p.user_id) purchase_count
    ,   CASE
            WHEN m.card_number IS NOT NULL THEN 1
            ELSE 0
        END has_card
    -- ,   CASE
    --         WHEN p.user_id = m.user_id THEN 1
    --         ELSE 0
    --     END has_purchase
    --
    --  sign 을 사용하여 처리도 가능하다
    ,   sign(count(p.user_id)) has_purchase
FROM
    mst_users_with_card_number m
LEFT JOIN
    purchase_log p
    ON p.user_id =  m.user_id
GROUP BY m.user_id, m.card_number, p.user_id;
```

```sh
user_id|purchase_count|has_card|has_purchase|
-------+--------------+--------+------------+
U002   |             2|       1|           1|
U003   |             0|       0|           0|
U001   |             3|       1|           1|
```

> 특정 조건을 만족하는지 플래그로 나타내는 방법을 사용하면
> 다양한 분석을 활용할 수 있다

## 계산한 테이블에 이름 부여 재사용

`CTE` (`Common Table Expression`) 을 사용하면, 일시적인 테이블에
이름을 붙여 재사용할수 있다

카테고리별 순위를 가로로 전개하고, `dvd`, `cd`, `book` 카테고리의
상품 매출 순위를 한번에 볼수 있는 형식으로 변환하는 방법이다

```sql
CREATE TABLE product_sales
(
        category_name   varchar(50)
    ,   product_id      char(4)
    ,   sales           int
);

INSERT INTO product_sales
VALUES
(
        'dvd'
    ,   'D001'
    ,   50000
),
(
        'dvd'
    ,   'D002'
    ,   20000
),
(
        'dvd'
    ,   'D003'
    ,   10000
),
(
        'cd'
    ,   'C001'
    ,   30000
),
(
        'cd'
    ,   'C002'
    ,   20000
),
(
        'cd'
    ,   'C003'
    ,   10000
),
(
        'book'
    ,   'B001'
    ,   20000
),
(
        'book'
    ,   'B002'
    ,   15000
),
(
        'book'
    ,   'B003'
    ,   10000
),
(
        'book'
    ,   'B004'
    ,   5000
);

SELECT * FROM  product_sales;
```

```sh
category_name|product_id|sales|
-------------+----------+-----+
dvd          |D001      |50000|
dvd          |D002      |20000|
dvd          |D003      |10000|
cd           |C001      |30000|
cd           |C002      |20000|
cd           |C003      |10000|
book         |B001      |20000|
book         |B002      |15000|
book         |B003      |10000|
book         |B004      | 5000|
```

다음은 `CTE` 구문을 사용하여 카테고리별 순위를 붙힌다

```sql

WITH rank_table AS (
    SELECT
            p.category_name
        ,   p.product_id
        ,   p.sales
        ,    row_number() OVER (PARTITION BY category_name ORDER BY sales DESC) rank
        FROM product_sales p
)
SELECT
    *
FROM
    rank_table;
```

```sh
category_name|product_id|sales|rank|
-------------+----------+-----+----+
book         |B001      |20000|   1|
book         |B002      |15000|   2|
book         |B003      |10000|   3|
book         |B004      | 5000|   4|
cd           |C001      |30000|   1|
cd           |C002      |20000|   2|
cd           |C003      |10000|   3|
dvd          |D001      |50000|   1|
dvd          |D002      |20000|   2|
dvd          |D003      |10000|   3|
```

다음은 순위목록만을 뽑아오는 로직이다

```sql
WITH product_sales_ranking AS (
    SELECT
            p.category_name
        ,   p.product_id
        ,   p.sales
        ,    row_number() OVER (PARTITION BY category_name ORDER BY sales DESC) rank
        FROM product_sales p
), ranking as (
    SELECT
            DISTINCT rank
    FROM product_sales_ranking
    ORDER BY rank ASC
)
SELECT
    *
FROM
    ranking;
```

```sh
rank|
----+
   1|
   2|
   3|
   4|
```

다음은 `book`, `cd`, `dvd` 의 각 랭킹을 가로로 출력하는 쿼리이다

```sql
WITH
    product_sales_ranking AS (
        SELECT
                p.product_id
            ,   p.category_name
            ,   p.sales
            ,   row_number() OVER (PARTITION BY p.category_name ORDER BY sales) rank
        FROM
            product_sales p
    )
    ,ranking AS (
        SELECT
            DISTINCT rank
        FROM
            product_sales_ranking
    )
SELECT
        r.rank
    ,   p1.category_name    dvd
    ,   p1.product_id       dvd_product_id
    ,   p1.sales            dvd_sales
    ,   p2.category_name    cd
    ,   p2.product_id       cd_product_id
    ,   p2.sales            cd_sales
    ,   p2.category_name    book
    ,   p2.product_id       book_product_id
    ,   p2.sales            book_sales
FROM
    ranking r
LEFT JOIN
    product_sales_ranking p1
    ON      p1.rank = r.rank
    AND     p1.category_name = 'dvd'
LEFT JOIN
    product_sales_ranking p2
    ON      p2.rank = r.rank
    AND     p2.category_name = 'cd'
LEFT JOIN
    product_sales_ranking p3
    ON      p3.rank = r.rank
    AND     p3.category_name = 'book'
ORDER BY rank ASC;
```

```sh
rank|dvd|dvd_product_id|dvd_sales|cd|cd_product_id|cd_sales|book|book_product_id|book_sales|
----+---+--------------+---------+--+-------------+--------+----+---------------+----------+
   1|dvd|D003          |    10000|cd|C003         |   10000|cd  |C003           |     10000|
   2|dvd|D002          |    20000|cd|C002         |   20000|cd  |C002           |     20000|
   3|dvd|D001          |    50000|cd|C001         |   30000|cd  |C001           |     30000|
   4|   |              |         |  |             |        |    |               |          |
```

## 유사 테이블 만들기

```sql

WITH
mst_device AS (
    SELECT 1 AS device_id,
    'PC'    AS  dvice_name
    UNION ALL
    SELECT 2 AS device_id,
    'SP'    AS  dvice_name
    UNION ALL
    SELECT 3 AS device_id,
    'APP'    AS  dvice_name
)
SELECT *
FROM mst_device;
```

```sh
device_id|dvice_name|
---------+----------+
        1|PC        |
        2|SP        |
        3|APP       |
```

### values 구문을 사용하여 유사 테이블을 만들기

```sql
WITH
    mst_device(device_id, device_name) AS (
        VALUES
            (1, 'PC'),
            (2, 'SP'),
            (3, 'APP')
    )
SELECT *
FROM mst_device;
```

```sh
device_id|device_name|
---------+-----------+
        1|PC         |
        2|SP         |
        3|APP        |
```

### 순번을 사용해 테이블 작성

```sql
WITH
series AS (
    SELECT generate_series(1, 5) AS idx
)
SELECT * from series
```

```sh
idx|
---+
  1|
  2|
  3|
  4|
  5|
```
