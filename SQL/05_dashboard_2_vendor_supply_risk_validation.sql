/*
=====================================================================
CASE STUDY 3: HEALTHCARE OPERATIONS & SUPPLY CHAIN PERFORMANCE
Dashboard 2: Vendor & Critical Supply Risk

SQL VALIDATION SCRIPT

Purpose:
Validate vendor performance, critical-item risk, contract exposure,
and departmental supply risk prior to building Dashboard 2 in Tableau.

Database:
PalmettoRegionalHealthSystemDW
=====================================================================
*/

USE PalmettoRegionalHealthSystemDW;
GO


/*====================================================================
1. CRITICAL ITEM POPULATION VALIDATION
====================================================================*/

-- 1.1 Total delivered critical-item orders
SELECT
    COUNT(*) AS Critical_Delivered_Orders
FROM SC_Supply_Orders o
INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes';


-- 1.2 Critical on-time vs late order reconciliation
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
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes';


/*====================================================================
2. CRITICAL ITEM SPEND VALIDATION
====================================================================*/

-- 2.1 Critical-item spend for delivered orders
SELECT
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


-- 2.2 Critical-item quantity fill rate
SELECT
    SUM(o.Quantity_Ordered)
        AS Critical_Quantity_Ordered,

    SUM(o.Quantity_Received)
        AS Critical_Quantity_Received,

    CAST(
        100.0 * SUM(o.Quantity_Received)
        / NULLIF(SUM(o.Quantity_Ordered),0)
        AS DECIMAL(10,2)
    ) AS Critical_Fill_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes';


/*====================================================================
3. VENDOR RECONCILIATION
====================================================================*/

-- 3.1 Confirm vendor population
SELECT
    COUNT(*) AS Total_Vendors
FROM SC_Vendors;


-- 3.2 Vendor order counts must reconcile to 1,000
SELECT
    v.Vendor_Name,
    COUNT(*) AS Total_Orders
FROM SC_Supply_Orders o
INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
GROUP BY
    v.Vendor_Name
ORDER BY
    v.Vendor_Name;


-- 3.3 Sum of vendor order counts
SELECT
    SUM(Vendor_Order_Count) AS Reconciled_Total_Orders
FROM
(
    SELECT
        o.SC_Vendor_ID,
        COUNT(*) AS Vendor_Order_Count
    FROM SC_Supply_Orders o
    GROUP BY
        o.SC_Vendor_ID
) x;


/*====================================================================
4. VENDOR DELIVERY PERFORMANCE VALIDATION
====================================================================*/

-- 4.1 Vendor delivery performance
SELECT
    v.Vendor_Name,

    COUNT(*) AS Delivered_Orders,

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
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

WHERE o.Actual_Delivery_Date IS NOT NULL

GROUP BY
    v.Vendor_Name

ORDER BY
    On_Time_Rate_Pct ASC;


/*====================================================================
5. CRITICAL VENDOR PERFORMANCE VALIDATION
====================================================================*/

-- 5.1 Critical-item performance by vendor
SELECT
    v.Vendor_Name,

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
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    v.Vendor_Name

ORDER BY
    Critical_On_Time_Rate_Pct ASC;


/*====================================================================
6. CONTRACT STATUS VALIDATION
====================================================================*/

-- 6.1 Contract status population
SELECT
    Contract_Status,
    COUNT(*) AS Vendor_Count
FROM SC_Vendors
GROUP BY
    Contract_Status;


-- 6.2 Identify expiring-contract vendors
SELECT
    SC_Vendor_ID,
    Vendor_Name,
    Vendor_Type,
    Contract_Status
FROM SC_Vendors
WHERE Contract_Status = 'Expiring Contract';


-- 6.3 Validate expiring-contract vendor spend
SELECT
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
    ) AS Expiring_Contract_Spend

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

WHERE v.Contract_Status = 'Expiring Contract';


-- 6.4 Validate expiring-contract delivery performance
SELECT
    COUNT(*) AS Delivered_Orders,

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
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct

FROM SC_Supply_Orders o

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

WHERE
    v.Contract_Status = 'Expiring Contract'
    AND o.Actual_Delivery_Date IS NOT NULL;


/*====================================================================
7. CRITICAL ITEM DETAIL VALIDATION
====================================================================*/

-- 7.1 Critical-item performance
SELECT
    i.Item_Name,
    i.Item_Category,

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
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Total_Spend

FROM SC_Supply_Orders o

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

WHERE
    o.Actual_Delivery_Date IS NOT NULL
    AND i.Critical_Item_Flag = 'Yes'

GROUP BY
    i.Item_Name,
    i.Item_Category

ORDER BY
    On_Time_Rate_Pct ASC;


/*====================================================================
8. DEPARTMENT EXPOSURE VALIDATION
====================================================================*/

-- 8.1 Critical-item performance by department
SELECT
    d.Department_Name,
    d.Service_Line,

    COUNT(*) AS Critical_Delivered_Orders,

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
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct,

    CAST(
        SUM(o.Total_Cost)
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend

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

ORDER BY
    Critical_On_Time_Rate_Pct ASC;


/*====================================================================
9. DATA QUALITY VALIDATION
====================================================================*/

-- 9.1 Missing vendor IDs
SELECT
    COUNT(*) AS Missing_Vendor_ID
FROM SC_Supply_Orders
WHERE SC_Vendor_ID IS NULL;


-- 9.2 Missing item IDs
SELECT
    COUNT(*) AS Missing_Item_ID
FROM SC_Supply_Orders
WHERE SC_Item_ID IS NULL;


-- 9.3 Missing department IDs
SELECT
    COUNT(*) AS Missing_Department_ID
FROM SC_Supply_Orders
WHERE SC_Department_ID IS NULL;


-- 9.4 Validate all orders join to vendor dimension
SELECT
    COUNT(*) AS Unmatched_Vendor_Orders
FROM SC_Supply_Orders o
LEFT JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID
WHERE v.SC_Vendor_ID IS NULL;


-- 9.5 Validate all orders join to item dimension
SELECT
    COUNT(*) AS Unmatched_Item_Orders
FROM SC_Supply_Orders o
LEFT JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID
WHERE i.SC_Item_ID IS NULL;


-- 9.6 Validate all orders join to department dimension
SELECT
    COUNT(*) AS Unmatched_Department_Orders
FROM SC_Supply_Orders o
LEFT JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID
WHERE d.SC_Department_ID IS NULL;


/*====================================================================
10. DASHBOARD 2 KPI RECONCILIATION SUMMARY
====================================================================*/

SELECT
    COUNT(
        CASE
            WHEN i.Critical_Item_Flag = 'Yes'
                 AND o.Actual_Delivery_Date IS NOT NULL
            THEN 1
        END
    ) AS Critical_Delivered_Orders,

    SUM(
        CASE
            WHEN i.Critical_Item_Flag = 'Yes'
                 AND o.Actual_Delivery_Date IS NOT NULL
                 AND o.Actual_Delivery_Date > o.Expected_Delivery_Date
            THEN 1
            ELSE 0
        END
    ) AS Critical_Late_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN i.Critical_Item_Flag = 'Yes'
                     AND o.Actual_Delivery_Date IS NOT NULL
                     AND o.Actual_Delivery_Date <= o.Expected_Delivery_Date
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN i.Critical_Item_Flag = 'Yes'
                         AND o.Actual_Delivery_Date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS Critical_On_Time_Rate_Pct,

    CAST(
        SUM(
            CASE
                WHEN i.Critical_Item_Flag = 'Yes'
                     AND o.Actual_Delivery_Date IS NOT NULL
                THEN o.Total_Cost
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Critical_Item_Spend,

    CAST(
        SUM(
            CASE
                WHEN v.Contract_Status = 'Expiring Contract'
                     AND o.Delivery_Status <> 'Cancelled'
                THEN o.Total_Cost
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Expiring_Contract_Spend

FROM SC_Supply_Orders o

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID;