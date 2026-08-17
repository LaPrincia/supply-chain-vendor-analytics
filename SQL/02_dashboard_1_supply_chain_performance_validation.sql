/*
=====================================================================
CASE STUDY 3: HEALTHCARE OPERATIONS & SUPPLY CHAIN PERFORMANCE
Dashboard 1: Supply Chain Performance Overview

SQL VALIDATION SCRIPT

Purpose:
Validate executive KPIs, delivery performance, critical-item metrics,
status reconciliation, and dimension joins prior to building the
Tableau dashboard.

Database:
PalmettoRegionalHealthSystemDW
=====================================================================
*/

USE PalmettoRegionalHealthSystemDW;
GO


/*====================================================================
1. RECORD COUNT VALIDATION
====================================================================*/

-- 1.1 Confirm total order population
SELECT
    COUNT(*) AS Total_Orders
FROM SC_Supply_Orders;


-- 1.2 Validate delivered vs cancelled population
SELECT
    SUM(
        CASE
            WHEN Delivery_Status = 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS Cancelled_Orders,

    SUM(
        CASE
            WHEN Actual_Delivery_Date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS Delivered_Orders,

    COUNT(*) AS Total_Orders
FROM SC_Supply_Orders;


/*====================================================================
2. EXECUTIVE KPI VALIDATION
====================================================================*/

-- 2.1 Validate total non-cancelled supply spend
SELECT
    CAST(
        SUM(Total_Cost)
        AS DECIMAL(18,2)
    ) AS Total_Supply_Spend
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.2 Validate non-cancelled order count
SELECT
    COUNT(DISTINCT Order_ID) AS Non_Cancelled_Orders
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.3 Validate average order value
SELECT
    CAST(
        AVG(Total_Cost)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.4 Validate quantity fill rate
SELECT
    SUM(Quantity_Ordered) AS Total_Quantity_Ordered,

    SUM(Quantity_Received) AS Total_Quantity_Received,

    CAST(
        100.0 * SUM(Quantity_Received)
        / NULLIF(SUM(Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.5 Validate on-time delivery rate
SELECT
    COUNT(*) AS Delivered_Orders,

    SUM(
        CASE
            WHEN Actual_Delivery_Date <= Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS On_Time_Orders,

    SUM(
        CASE
            WHEN Actual_Delivery_Date > Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Actual_Delivery_Date <= Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Delivery_Rate_Pct
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NOT NULL;


-- 2.6 Validate full fulfillment rate
SELECT
    COUNT(*) AS Non_Cancelled_Orders,

    SUM(
        CASE
            WHEN Quantity_Received >= Quantity_Ordered
            THEN 1 ELSE 0
        END
    ) AS Fully_Fulfilled_Orders,

    SUM(
        CASE
            WHEN Quantity_Received < Quantity_Ordered
            THEN 1 ELSE 0
        END
    ) AS Under_Fulfilled_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Quantity_Received >= Quantity_Ordered
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Full_Fulfillment_Rate_Pct
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.7 Validate average delivery time
SELECT
    CAST(
        AVG(
            CAST(
                DATEDIFF(
                    DAY,
                    Order_Date,
                    Actual_Delivery_Date
                )
                AS DECIMAL(10,2)
            )
        )
        AS DECIMAL(10,2)
    ) AS Avg_Delivery_Days
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NOT NULL;


-- 2.8 Validate average days late
SELECT
    COUNT(*) AS Late_Orders,

    CAST(
        AVG(
            CAST(
                DATEDIFF(
                    DAY,
                    Expected_Delivery_Date,
                    Actual_Delivery_Date
                )
                AS DECIMAL(10,2)
            )
        )
        AS DECIMAL(10,2)
    ) AS Avg_Days_Late
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date > Expected_Delivery_Date;


-- 2.9 Validate cancellation rate
SELECT
    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN Delivery_Status = 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS Cancelled_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Delivery_Status = 'Cancelled'
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Cancellation_Rate_Pct
FROM SC_Supply_Orders;


/*====================================================================
3. CRITICAL ITEM KPI VALIDATION
====================================================================*/

-- 3.1 Validate critical-item delivery performance
SELECT
    COUNT(*) AS Critical_Delivered_Orders,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Critical_On_Time_Orders,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Critical_Late_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend

FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes';


-- 3.2 Validate critical-item quantity fill rate
SELECT
    SUM(o.Quantity_Ordered) AS Critical_Quantity_Ordered,

    SUM(o.Quantity_Received) AS Critical_Quantity_Received,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Critical_Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Delivery_Status <> 'Cancelled'
    AND i.Critical_Item_Flag = 'Yes';


/*====================================================================
4. DELIVERY STATUS RECONCILIATION
====================================================================*/

-- 4.1 Delivery status counts should reconcile to total orders
SELECT
    Delivery_Status,
    COUNT(*) AS Order_Count
FROM SC_Supply_Orders
GROUP BY Delivery_Status
ORDER BY Delivery_Status;


-- 4.2 Validate missing actual delivery dates
SELECT
    Delivery_Status,
    COUNT(*) AS Missing_Delivery_Date_Count
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NULL
GROUP BY Delivery_Status
ORDER BY Delivery_Status;


-- 4.3 Confirm all cancelled orders have no actual delivery date
SELECT
    COUNT(*) AS Cancelled_Orders_With_Actual_Delivery_Date
FROM SC_Supply_Orders
WHERE
    Delivery_Status = 'Cancelled'
    AND Actual_Delivery_Date IS NOT NULL;


-- 4.4 Confirm no delivered/non-cancelled orders are missing actual delivery date
SELECT
    COUNT(*) AS Non_Cancelled_Orders_Missing_Delivery_Date
FROM SC_Supply_Orders
WHERE
    Delivery_Status <> 'Cancelled'
    AND Actual_Delivery_Date IS NULL;


/*====================================================================
5. FULFILLMENT RECONCILIATION
====================================================================*/

-- 5.1 Validate full vs partial fulfillment population
SELECT
    SUM(
        CASE
            WHEN Quantity_Received >= Quantity_Ordered
            THEN 1 ELSE 0
        END
    ) AS Fully_Fulfilled_Orders,

    SUM(
        CASE
            WHEN Quantity_Received < Quantity_Ordered
            THEN 1 ELSE 0
        END
    ) AS Under_Fulfilled_Orders,

    COUNT(*) AS Non_Cancelled_Orders
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 5.2 Validate explicit partial delivery status count
SELECT
    COUNT(*) AS Partial_Delivery_Orders
FROM SC_Supply_Orders
WHERE Delivery_Status = 'Partial Delivery';


/*====================================================================
6. DATE LOGIC VALIDATION
====================================================================*/

-- 6.1 Validate on-time vs late delivered orders
SELECT
    SUM(
        CASE
            WHEN Actual_Delivery_Date <= Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS On_Time_Orders,

    SUM(
        CASE
            WHEN Actual_Delivery_Date > Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

    COUNT(*) AS Delivered_Orders
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NOT NULL;


-- 6.2 Check for impossible delivery dates
SELECT
    COUNT(*) AS Actual_Delivery_Before_Order_Date
FROM SC_Supply_Orders
WHERE
    Actual_Delivery_Date IS NOT NULL
    AND Actual_Delivery_Date < Order_Date;


-- 6.3 Check for expected delivery dates before order date
SELECT
    COUNT(*) AS Expected_Delivery_Before_Order_Date
FROM SC_Supply_Orders
WHERE Expected_Delivery_Date < Order_Date;


/*====================================================================
7. COST VALIDATION
====================================================================*/

-- 7.1 Validate Total_Cost calculation
SELECT
    COUNT(*) AS Cost_Calculation_Mismatches
FROM SC_Supply_Orders
WHERE
    ABS(
        Total_Cost
        - (Quantity_Ordered * Unit_Cost)
    ) > 0.01;


-- 7.2 Check for null or non-positive costs
SELECT
    SUM(
        CASE
            WHEN Unit_Cost IS NULL
            THEN 1 ELSE 0
        END
    ) AS Null_Unit_Costs,

    SUM(
        CASE
            WHEN Total_Cost IS NULL
            THEN 1 ELSE 0
        END
    ) AS Null_Total_Costs,

    SUM(
        CASE
            WHEN Unit_Cost <= 0
            THEN 1 ELSE 0
        END
    ) AS Non_Positive_Unit_Costs,

    SUM(
        CASE
            WHEN Total_Cost <= 0
            THEN 1 ELSE 0
        END
    ) AS Non_Positive_Total_Costs

FROM SC_Supply_Orders;


/*====================================================================
8. DIMENSION JOIN VALIDATION
====================================================================*/

-- 8.1 Confirm all orders successfully join to all dimensions
SELECT
    COUNT(*) AS Joined_Order_Count
FROM SC_Supply_Orders o

INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID;


-- 8.2 Check for unmatched department IDs
SELECT
    COUNT(*) AS Unmatched_Department_Orders
FROM SC_Supply_Orders o
LEFT JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID
WHERE d.SC_Department_ID IS NULL;


-- 8.3 Check for unmatched supply item IDs
SELECT
    COUNT(*) AS Unmatched_Item_Orders
FROM SC_Supply_Orders o
LEFT JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE i.SC_Item_ID IS NULL;


-- 8.4 Check for unmatched vendor IDs
SELECT
    COUNT(*) AS Unmatched_Vendor_Orders
FROM SC_Supply_Orders o
LEFT JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE v.SC_Vendor_ID IS NULL;


/*====================================================================
9. DUPLICATE VALIDATION
====================================================================*/

-- 9.1 Check for duplicate Order_ID values
SELECT
    Order_ID,
    COUNT(*) AS Duplicate_Count
FROM SC_Supply_Orders
GROUP BY Order_ID
HAVING COUNT(*) > 1;


-- 9.2 Summary duplicate count
SELECT
    COUNT(*) AS Duplicate_Order_ID_Count
FROM
(
    SELECT
        Order_ID
    FROM SC_Supply_Orders
    GROUP BY Order_ID
    HAVING COUNT(*) > 1
) d;


/*====================================================================
10. DASHBOARD KPI RECONCILIATION SUMMARY
====================================================================*/

SELECT
    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN Delivery_Status <> 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS Non_Cancelled_Orders,

    CAST(
        SUM(
            CASE
                WHEN Delivery_Status <> 'Cancelled'
                THEN Total_Cost
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Total_Supply_Spend,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Actual_Delivery_Date IS NOT NULL
                     AND Actual_Delivery_Date <= Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN Actual_Delivery_Date IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS On_Time_Delivery_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Delivery_Status <> 'Cancelled'
                THEN Quantity_Received
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN Delivery_Status <> 'Cancelled'
                    THEN Quantity_Ordered
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Delivery_Status = 'Cancelled'
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Cancellation_Rate_Pct

FROM SC_Supply_Orders;