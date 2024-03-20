drop table if exists purchase_log;

CREATE TABLE purchase_log
(
        dt                  date
    ,   order_id            int
    ,   user_id             uuid
    ,   purchase_amount     bigint
);

INSERT INTO purchase_log
VALUES
    (
            '2014-01-01'
        ,   1
        ,   uuid_generate_v4()
        ,   13900
    ),
    (
            '2014-01-01'
        ,   2
        ,   uuid_generate_v4()
        ,   10616
    ),
    (
            '2014-01-02'
        ,   3
        ,   uuid_generate_v4()
        ,   21156
    ),
    (
            '2014-01-02'
        ,   4
        ,   uuid_generate_v4()
        ,   14893
    ),
    (
            '2014-01-03'
        ,   5
        ,   4uid_generate_v4()
        ,   13054
    ),
    (
            '2014-01-03'
        ,   6
        ,   4uid_generate_v4()
        ,   24384
    ),
    (
            '2014-01-03'
        ,   7
        ,   4uid_generate_v4()
        ,   15591
    ),
    (
            '2014-01-04'
        ,   8
        ,   uuid_generate_v4()
        ,   3025
    ),
    (
            '2014-01-04'
        ,   9
        ,   uuid_generate_v4()
        ,   24215
    ),
    (
            '2014-01-04'
        ,   10
        ,   uuid_generate_v4()
        ,   2059
    ),
    (
            '2014-01-04'
        ,   11
        ,   uuid_generate_v4()
        ,   7324
    ),
    (
            '2014-01-04'
        ,   12
        ,   uuid_generate_v4()
        ,   9521
    );

SELECT * FROM purchase_log;

SELECT
        dt
    ,   count(dt) purchase_count
    ,   sum(purchase_amount) total_amount
    ,   round(avg(purchase_amount), 2) avg_amount
FROM
    purchase_log
GROUP BY dt
ORDER BY dt;

SELECT
        dt
    ,   sum(purchase_amount) total_amount
    ,   round(avg(purchase_amount) OVER (ORDER BY dt ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) sevent_days_avg
FROM
    purchase_log
GROUP BY dt;

SELECT
        dt
    ,   sum(purchase_amount) OVER (
            PARTITION BY substring(dt, 1, 7)
            ORDER BY dt
            ROWS BETWEEN
                UNBOUNDED PRECEDING 
        )
FROM
    purchase_log;


WITH
    daily_purchase AS (
        SELECT
                dt
            ,   SUBSTRING(dt, 1, 4) year
            ,   SUBSTRING(dt, 6, 2) month
            ,   SUBSTRING(dt, 9, 2) day
            ,   sum(purchase_amount) total_amount
        FROM
            purchase_log
        GROUP BY dt
    )
SELECT
    *
FROM
    daily_purchase;

SELECT 
    SUBSTRING(dt, 1, 7) year_month,
    sum(purchase_amount) total_amount
FROM
    purchase_log
GROUP BY SUBSTRING(dt, 1, 7);

SELECT * from purchase_log;

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
    )
    calc_index AS (
        SELECT
                year || '-' || month "year_mount"
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
            ,   sum(
                    CASE
                        WHEN year = '2015' THEN year_month_amount
                    END
                ) OVER (
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
