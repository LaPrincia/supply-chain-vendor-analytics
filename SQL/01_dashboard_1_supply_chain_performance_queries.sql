/*
=====================================================================
CASE STUDY 3: HEALTHCARE OPERATIONS & SUPPLY CHAIN PERFORMANCE
Dashboard 1: Supply Chain Performance Overview

Organization:
Palmetto Regional Health System (PRHS)

Purpose:
Evaluate enterprise supply chain performance across purchasing,
spend, order fulfillment, delivery performance, departments,
supply categories, and critical supply items.

Primary Tables:
    SC_Supply_Orders
    SC_Supply_Items
    SC_Departments
    SC_Vendors

Dashboard Tool:
Tableau

Performance Improvement Framework:
DMAIC
=====================================================================
*/

USE PalmettoRegionalHealthSystemDW;
GO

/*====================================================================
1. DATASET PROFILE
====================================================================*/

-- 1.1 Total number of supply orders
SELECT
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM SC_Supply_Orders;


-- 1.2 Order date range
SELECT
    MIN(Order_Date) AS First_Order_Date,
    MAX(Order_Date) AS Last_Order_Date
FROM SC_Supply_Orders;


-- 1.3 Delivery status distribution
SELECT
    Delivery_Status,
    COUNT(*) AS Order_Count
FROM SC_Supply_Orders
GROUP BY Delivery_Status
ORDER BY Order_Count DESC;


-- 1.4 Orders without an actual delivery date
SELECT
    COUNT(*) AS Missing_Actual_Delivery_Date
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NULL;


-- 1.5 Total departments, vendors, and supply items
SELECT
    (SELECT COUNT(*) FROM SC_Departments) AS Total_Departments,
    (SELECT COUNT(*) FROM SC_Vendors) AS Total_Vendors,
    (SELECT COUNT(*) FROM SC_Supply_Items) AS Total_Supply_Items;


-- 1.6 Supply item categories
SELECT
    Item_Category,
    COUNT(*) AS Item_Count
FROM SC_Supply_Items
GROUP BY Item_Category
ORDER BY Item_Count DESC;


-- 1.7 Critical vs non-critical supply items
SELECT
    Critical_Item_Flag,
    COUNT(*) AS Item_Count
FROM SC_Supply_Items
GROUP BY Critical_Item_Flag
ORDER BY Critical_Item_Flag;


-- 1.8 Vendor contract status
SELECT
    Contract_Status,
    COUNT(*) AS Vendor_Count
FROM SC_Vendors
GROUP BY Contract_Status
ORDER BY Vendor_Count DESC;

/*====================================================================
2. EXECUTIVE KPI ANALYSIS
====================================================================*/

-- 2.1 Total supply spend
SELECT
    SUM(Total_Cost) AS Total_Supply_Spend
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.2 Total completed/non-cancelled orders
SELECT
    COUNT(DISTINCT Order_ID) AS Non_Cancelled_Orders
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.3 Average order value
SELECT
    AVG(Total_Cost) AS Average_Order_Value
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.4 Overall quantity fill rate
SELECT
    SUM(Quantity_Ordered) AS Total_Quantity_Ordered,
    SUM(Quantity_Received) AS Total_Quantity_Received,
    CAST(
        100.0 * SUM(Quantity_Received)
        / NULLIF(SUM(Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Fill_Rate_Pct
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled';


-- 2.5 Date-based on-time delivery performance
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


-- 2.6 Full order fulfillment rate
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


-- 2.7 Average delivery time
SELECT
    CAST(
        AVG(
            CAST(
                DATEDIFF(DAY, Order_Date, Actual_Delivery_Date)
                AS DECIMAL(10,2)
            )
        )
        AS DECIMAL(10,2)
    ) AS Avg_Delivery_Days
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NOT NULL;


-- 2.8 Average days late for late deliveries
SELECT
    COUNT(*) AS Late_Orders,

    CAST(
        AVG(
            CAST(
                DATEDIFF(
                    DAY,
                    Expected_Delivery_Date,
                    Actual_Delivery_Date
                ) AS DECIMAL(10,2)
            )
        )
        AS DECIMAL(10,2)
    ) AS Avg_Days_Late
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date > Expected_Delivery_Date;


-- 2.9 Cancellation rate
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


-- 2.10 Validate missing delivery dates against cancelled orders
SELECT
    Delivery_Status,
    COUNT(*) AS Missing_Delivery_Date_Count
FROM SC_Supply_Orders
WHERE Actual_Delivery_Date IS NULL
GROUP BY Delivery_Status
ORDER BY Missing_Delivery_Date_Count DESC;


/*====================================================================
3. SPEND & COST ANALYSIS
====================================================================*/

-- 3.1 Monthly supply spend and order volume
SELECT
    YEAR(Order_Date) AS Order_Year,
    MONTH(Order_Date) AS Order_Month,
    DATENAME(MONTH, Order_Date) AS Month_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    CAST(SUM(Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,
    CAST(AVG(Total_Cost) AS DECIMAL(18,2)) AS Avg_Order_Value
FROM SC_Supply_Orders
WHERE Delivery_Status <> 'Cancelled'
GROUP BY
    YEAR(Order_Date),
    MONTH(Order_Date),
    DATENAME(MONTH, Order_Date)
ORDER BY
    Order_Year,
    Order_Month;


-- 3.2 Supply spend by department
SELECT
    d.Department_Name,
    d.Service_Line,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,
    CAST(AVG(o.Total_Cost) AS DECIMAL(18,2)) AS Avg_Order_Value,
    CAST(
        100.0 * SUM(o.Total_Cost)
        / SUM(SUM(o.Total_Cost)) OVER ()
        AS DECIMAL(10,2)
    ) AS Spend_Pct
FROM SC_Supply_Orders o
INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY
    d.Department_Name,
    d.Service_Line
ORDER BY Total_Spend DESC;


-- 3.3 Supply spend by item category
SELECT
    i.Item_Category,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(o.Quantity_Ordered) AS Quantity_Ordered,
    SUM(o.Quantity_Received) AS Quantity_Received,
    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,
    CAST(
        100.0 * SUM(o.Total_Cost)
        / SUM(SUM(o.Total_Cost)) OVER ()
        AS DECIMAL(10,2)
    ) AS Spend_Pct
FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY i.Item_Category
ORDER BY Total_Spend DESC;


-- 3.4 Supply spend by individual item
SELECT
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(o.Quantity_Ordered) AS Quantity_Ordered,
    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,
    CAST(AVG(o.Unit_Cost) AS DECIMAL(18,2)) AS Avg_Unit_Cost
FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag
ORDER BY Total_Spend DESC;


-- 3.5 Spend by vendor
SELECT
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,
    CAST(AVG(o.Total_Cost) AS DECIMAL(18,2)) AS Avg_Order_Value,
    CAST(
        100.0 * SUM(o.Total_Cost)
        / SUM(SUM(o.Total_Cost)) OVER ()
        AS DECIMAL(10,2)
    ) AS Spend_Pct
FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status
ORDER BY Total_Spend DESC;


-- 3.6 Critical vs non-critical item spend
SELECT
    i.Critical_Item_Flag,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,
    CAST(
        100.0 * SUM(o.Total_Cost)
        / SUM(SUM(o.Total_Cost)) OVER ()
        AS DECIMAL(10,2)
    ) AS Spend_Pct
FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY i.Critical_Item_Flag
ORDER BY Total_Spend DESC;

/*====================================================================
4. DELIVERY & FULFILLMENT PERFORMANCE ANALYSIS
====================================================================*/

-- 4.1 Delivery performance by vendor
SELECT
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS On_Time_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        AVG(CAST(
            DATEDIFF(DAY, o.Order_Date, o.Actual_Delivery_Date)
            AS DECIMAL(10,2)
        ))
        AS DECIMAL(10,2)
    ) AS Avg_Delivery_Days,

    CAST(
        AVG(
            CASE
                WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
                THEN CAST(
                    DATEDIFF(
                        DAY,
                        o.Expected_Delivery_Date,
                        o.Actual_Delivery_Date
                    ) AS DECIMAL(10,2)
                )
            END
        )
        AS DECIMAL(10,2)
    ) AS Avg_Days_Late

FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status
ORDER BY On_Time_Rate_Pct ASC;


-- 4.2 Fulfillment performance by vendor
SELECT
    v.Vendor_Name,

    COUNT(*) AS Non_Cancelled_Orders,

    SUM(CASE
        WHEN o.Quantity_Received >= o.Quantity_Ordered
        THEN 1 ELSE 0
    END) AS Fully_Fulfilled_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Quantity_Received >= o.Quantity_Ordered
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Full_Fulfillment_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY v.Vendor_Name
ORDER BY Full_Fulfillment_Rate_Pct ASC;


-- 4.3 Delivery performance by department
SELECT
    d.Department_Name,
    d.Service_Line,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY
    d.Department_Name,
    d.Service_Line
ORDER BY On_Time_Rate_Pct ASC;


-- 4.4 Delivery performance by supply category
SELECT
    i.Item_Category,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY i.Item_Category
ORDER BY On_Time_Rate_Pct ASC;


-- 4.5 Critical vs non-critical supply delivery performance
SELECT
    i.Critical_Item_Flag,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend

FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY i.Critical_Item_Flag
ORDER BY i.Critical_Item_Flag DESC;


-- 4.6 Performance by individual supply item
SELECT
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend

FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag
ORDER BY On_Time_Rate_Pct ASC;

/*====================================================================
5. SUPPLY CHAIN RISK & ROOT-CAUSE ANALYSIS
====================================================================*/

-- 5.1 Vendor performance: spend + delivery + fulfillment
SELECT
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status,

    COUNT(*) AS Delivered_Orders,

    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2)) AS Total_Spend,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered),0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Quantity_Received >= o.Quantity_Ordered
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Full_Fulfillment_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status
ORDER BY On_Time_Rate_Pct ASC, Total_Spend DESC;


-- 5.2 Critical-item delivery risk by vendor
SELECT
    v.Vendor_Name,

    COUNT(*) AS Critical_Item_Orders,

    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2))
        AS Critical_Item_Spend,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Critical_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered),0)
        AS DECIMAL(10,2)
    ) AS Critical_Fill_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'
GROUP BY v.Vendor_Name
ORDER BY Critical_On_Time_Rate_Pct ASC;


-- 5.3 Department exposure to late critical-item deliveries
SELECT
    d.Department_Name,
    d.Service_Line,

    COUNT(*) AS Critical_Item_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Critical_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct,

    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2))
        AS Critical_Item_Spend

FROM SC_Supply_Orders o
INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'
GROUP BY
    d.Department_Name,
    d.Service_Line
ORDER BY Critical_On_Time_Rate_Pct ASC;


-- 5.4 Most frequently delayed individual items
SELECT
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Late_Order_Rate_Pct,

    CAST(SUM(o.Total_Cost) AS DECIMAL(18,2))
        AS Total_Spend

FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag
ORDER BY Late_Order_Rate_Pct DESC, Late_Orders DESC;


-- 5.5 Partial-delivery analysis by vendor
SELECT
    v.Vendor_Name,

    COUNT(*) AS Total_Non_Cancelled_Orders,

    SUM(CASE
        WHEN o.Delivery_Status = 'Partial Delivery'
        THEN 1 ELSE 0
    END) AS Partial_Delivery_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Delivery_Status = 'Partial Delivery'
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Partial_Delivery_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE o.Delivery_Status <> 'Cancelled'
GROUP BY v.Vendor_Name
ORDER BY Partial_Delivery_Rate_Pct DESC;


-- 5.6 Cancellation analysis by vendor
SELECT
    v.Vendor_Name,

    COUNT(*) AS Total_Orders,

    SUM(CASE
        WHEN o.Delivery_Status = 'Cancelled'
        THEN 1 ELSE 0
    END) AS Cancelled_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Delivery_Status = 'Cancelled'
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Cancellation_Rate_Pct

FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
GROUP BY v.Vendor_Name
ORDER BY Cancellation_Rate_Pct DESC;


-- 5.7 Monthly delivery performance trend
SELECT
    YEAR(o.Order_Date) AS Order_Year,
    MONTH(o.Order_Date) AS Order_Month,
    DATENAME(MONTH, o.Order_Date) AS Month_Name,

    COUNT(*) AS Delivered_Orders,

    SUM(CASE
        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1 ELSE 0
    END) AS Late_Orders,

    CAST(
        100.0 * SUM(CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        AVG(
            CAST(
                DATEDIFF(
                    DAY,
                    o.Order_Date,
                    o.Actual_Delivery_Date
                ) AS DECIMAL(10,2)
            )
        ) AS DECIMAL(10,2)
    ) AS Avg_Delivery_Days

FROM SC_Supply_Orders o
WHERE o.Actual_Delivery_Date IS NOT NULL
GROUP BY
    YEAR(o.Order_Date),
    MONTH(o.Order_Date),
    DATENAME(MONTH, o.Order_Date)
ORDER BY
    Order_Year,
    Order_Month;