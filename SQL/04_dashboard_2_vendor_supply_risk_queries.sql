/*
=====================================================================
CASE STUDY 3: HEALTHCARE OPERATIONS & SUPPLY CHAIN PERFORMANCE
Dashboard 2: Vendor & Supply Risk Performance

Organization:
Palmetto Regional Health System (PRHS)

Purpose:
Evaluate vendor reliability, contract risk, critical supply
performance, and departmental exposure to supply chain disruption.

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
1. VENDOR PERFORMANCE SCORECARD
====================================================================*/

-- 1.1 Comprehensive vendor performance
SELECT
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN o.Delivery_Status <> 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS Non_Cancelled_Orders,

    SUM(
        CASE
            WHEN o.Delivery_Status = 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS Cancelled_Orders,

    CAST(
        SUM(
            CASE
                WHEN o.Delivery_Status <> 'Cancelled'
                THEN o.Total_Cost
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Total_Spend,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date IS NOT NULL
                 AND o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS On_Time_Orders,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Actual_Delivery_Date IS NOT NULL
                     AND o.Actual_Delivery_Date <= o.Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Actual_Delivery_Date IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Delivery_Status <> 'Cancelled'
                THEN o.Quantity_Received
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Delivery_Status <> 'Cancelled'
                    THEN o.Quantity_Ordered
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
                WHEN o.Delivery_Status <> 'Cancelled'
                     AND o.Quantity_Received >= o.Quantity_Ordered
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Delivery_Status <> 'Cancelled'
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS Full_Fulfillment_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Delivery_Status = 'Partial Delivery'
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Delivery_Status <> 'Cancelled'
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS Partial_Delivery_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Delivery_Status = 'Cancelled'
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Cancellation_Rate_Pct,

    CAST(
        AVG(
            CASE
                WHEN o.Actual_Delivery_Date IS NOT NULL
                THEN CAST(
                    DATEDIFF(
                        DAY,
                        o.Order_Date,
                        o.Actual_Delivery_Date
                    ) AS DECIMAL(10,2)
                )
            END
        )
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

GROUP BY
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status

ORDER BY
    On_Time_Rate_Pct ASC;


/*====================================================================
2. CRITICAL SUPPLY PERFORMANCE BY VENDOR
====================================================================*/

-- 2.1 Vendor performance specifically for critical supplies
SELECT
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status,

    COUNT(*) AS Critical_Delivered_Orders,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend,

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
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Critical_Fill_Rate_Pct,

    CAST(
        AVG(
            CAST(
                DATEDIFF(
                    DAY,
                    o.Order_Date,
                    o.Actual_Delivery_Date
                ) AS DECIMAL(10,2)
            )
        )
        AS DECIMAL(10,2)
    ) AS Avg_Critical_Delivery_Days

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status

ORDER BY
    Critical_On_Time_Rate_Pct ASC;


/*====================================================================
3. CONTRACT RISK ANALYSIS
====================================================================*/

-- 3.1 Compare vendor performance by contract status
SELECT
    v.Contract_Status,

    COUNT(DISTINCT v.SC_Vendor_ID) AS Vendor_Count,

    COUNT(*) AS Total_Orders,

    CAST(
        SUM(
            CASE
                WHEN o.Delivery_Status <> 'Cancelled'
                THEN o.Total_Cost
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Total_Spend,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Actual_Delivery_Date IS NOT NULL
                     AND o.Actual_Delivery_Date <= o.Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Actual_Delivery_Date IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Delivery_Status <> 'Cancelled'
                THEN o.Quantity_Received
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Delivery_Status <> 'Cancelled'
                    THEN o.Quantity_Ordered
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

GROUP BY
    v.Contract_Status

ORDER BY Total_Spend DESC;


-- 3.2 Detailed performance of expiring-contract vendor(s)
SELECT
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN o.Delivery_Status <> 'Cancelled'
            THEN 1 ELSE 0
        END
    ) AS Non_Cancelled_Orders,

    CAST(
        SUM(
            CASE
                WHEN o.Delivery_Status <> 'Cancelled'
                THEN o.Total_Cost
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Total_Spend,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Actual_Delivery_Date IS NOT NULL
                     AND o.Actual_Delivery_Date <= o.Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.Actual_Delivery_Date IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

WHERE v.Contract_Status = 'Expiring Contract'

GROUP BY
    v.Vendor_Name,
    v.Vendor_Type,
    v.Contract_Status

ORDER BY Total_Spend DESC;

/*====================================================================
4. CRITICAL ITEM RISK ANALYSIS
====================================================================*/

-- 4.1 Critical-item performance by individual supply item
SELECT
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag,

    COUNT(*) AS Delivered_Orders,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Total_Spend,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS On_Time_Orders,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

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
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Late_Order_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    i.Item_Name,
    i.Item_Category,
    i.Critical_Item_Flag

ORDER BY
    On_Time_Rate_Pct ASC,
    Total_Spend DESC;


/*====================================================================
5. CRITICAL ITEM CATEGORY RISK
====================================================================*/

-- 5.1 Critical supply performance by category
SELECT
    i.Item_Category,

    COUNT(*) AS Critical_Delivered_Orders,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Critical_Orders,

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
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Critical_Fill_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    i.Item_Category

ORDER BY
    Critical_On_Time_Rate_Pct ASC;


/*====================================================================
6. CLINICAL DEPARTMENT EXPOSURE
====================================================================*/

-- 6.1 Department exposure to critical supply delays
SELECT
    d.Department_Name,
    d.Service_Line,
    d.Location,

    COUNT(*) AS Critical_Delivered_Orders,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend,

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
    ) AS Late_Critical_Orders,

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
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Critical_Fill_Rate_Pct

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
    d.Service_Line,
    d.Location

ORDER BY
    Critical_On_Time_Rate_Pct ASC;


/*====================================================================
7. VENDOR + CRITICAL ITEM RISK MATRIX
====================================================================*/

-- 7.1 Identify vendor/item combinations with the greatest
--     critical supply delivery risk
SELECT
    v.Vendor_Name,
    v.Contract_Status,
    i.Item_Name,
    i.Item_Category,

    COUNT(*) AS Delivered_Orders,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Total_Spend,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

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
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered), 0)
        AS DECIMAL(10,2)
    ) AS Quantity_Fill_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    v.Vendor_Name,
    v.Contract_Status,
    i.Item_Name,
    i.Item_Category

ORDER BY
    On_Time_Rate_Pct ASC,
    Late_Orders DESC;


/*====================================================================
8. VENDOR + DEPARTMENT EXPOSURE
====================================================================*/

-- 8.1 Determine which departments are most exposed to
--     critical-item delays from individual vendors
SELECT
    v.Vendor_Name,
    v.Contract_Status,
    d.Department_Name,
    d.Service_Line,

    COUNT(*) AS Critical_Delivered_Orders,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Critical_Orders,

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
    ) AS Critical_On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    v.Vendor_Name,
    v.Contract_Status,
    d.Department_Name,
    d.Service_Line

ORDER BY
    Critical_On_Time_Rate_Pct ASC,
    Late_Critical_Orders DESC;


/*====================================================================
9. MONTHLY VENDOR RISK TREND
====================================================================*/

-- 9.1 Monthly vendor delivery performance
SELECT
    YEAR(o.Order_Date) AS Order_Year,

    MONTH(o.Order_Date) AS Order_Month_Number,

    DATENAME(MONTH, o.Order_Date) AS Order_Month_Name,

    v.Vendor_Name,

    v.Contract_Status,

    COUNT(*) AS Delivered_Orders,

    SUM(
        CASE
            WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1 ELSE 0
        END
    ) AS Late_Orders,

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
    ) AS On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

WHERE o.Actual_Delivery_Date IS NOT NULL

GROUP BY
    YEAR(o.Order_Date),
    MONTH(o.Order_Date),
    DATENAME(MONTH, o.Order_Date),
    v.Vendor_Name,
    v.Contract_Status

ORDER BY
    Order_Year,
    Order_Month_Number,
    v.Vendor_Name;