/*
=====================================================================
CASE STUDY 3: HEALTHCARE OPERATIONS & SUPPLY CHAIN PERFORMANCE
Dashboard 1: Supply Chain Performance Overview

TABLEAU DATASET

Purpose:
Create a clean, row-level reporting dataset for Tableau that combines
supply orders with department, vendor, and item dimensions.

Important:
Every output field is explicitly aliased so column headers display
consistently when exported or connected to Tableau.

Database:
PalmettoRegionalHealthSystemDW
=====================================================================
*/

USE PalmettoRegionalHealthSystemDW;
GO


/*====================================================================
TABLEAU-READY DATASET
====================================================================*/

SELECT
    /*--------------------------------------------------------------
      ORDER IDENTIFIERS
    --------------------------------------------------------------*/
    o.Order_ID AS Order_ID,

    o.SC_Department_ID AS Department_ID,

    o.SC_Item_ID AS Item_ID,

    o.SC_Vendor_ID AS Vendor_ID,


    /*--------------------------------------------------------------
      DATE FIELDS
    --------------------------------------------------------------*/
    o.Order_Date AS Order_Date,

    YEAR(o.Order_Date) AS Order_Year,

    MONTH(o.Order_Date) AS Order_Month_Number,

    DATENAME(MONTH, o.Order_Date) AS Order_Month_Name,

    DATEFROMPARTS(
        YEAR(o.Order_Date),
        MONTH(o.Order_Date),
        1
    ) AS Order_Month,

    DATEPART(QUARTER, o.Order_Date) AS Order_Quarter_Number,

    CONCAT(
        'Q',
        DATEPART(QUARTER, o.Order_Date)
    ) AS Order_Quarter,

    o.Expected_Delivery_Date AS Expected_Delivery_Date,

    o.Actual_Delivery_Date AS Actual_Delivery_Date,


    /*--------------------------------------------------------------
      DEPARTMENT DIMENSION
    --------------------------------------------------------------*/
    d.Department_Name AS Department_Name,

    d.Location AS Department_Location,

    d.Service_Line AS Service_Line,


    /*--------------------------------------------------------------
      SUPPLY ITEM DIMENSION
    --------------------------------------------------------------*/
    i.Item_Name AS Item_Name,

    i.Item_Category AS Item_Category,

    i.Critical_Item_Flag AS Critical_Item_Flag,

    i.Par_Level AS Par_Level,

    i.Reorder_Point AS Reorder_Point,


    /*--------------------------------------------------------------
      VENDOR DIMENSION
    --------------------------------------------------------------*/
    v.Vendor_Name AS Vendor_Name,

    v.Vendor_Type AS Vendor_Type,

    v.Contract_Status AS Contract_Status,


    /*--------------------------------------------------------------
      ORDER QUANTITY & COST
    --------------------------------------------------------------*/
    o.Quantity_Ordered AS Quantity_Ordered,

    o.Quantity_Received AS Quantity_Received,

    o.Unit_Cost AS Unit_Cost,

    o.Total_Cost AS Total_Cost,


    /*--------------------------------------------------------------
      DELIVERY STATUS
    --------------------------------------------------------------*/
    o.Delivery_Status AS Delivery_Status,


    /*--------------------------------------------------------------
      DERIVED DELIVERY METRICS
    --------------------------------------------------------------*/

    -- Total calendar days from order to actual delivery
    CASE
        WHEN o.Actual_Delivery_Date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            o.Order_Date,
            o.Actual_Delivery_Date
        )
        ELSE NULL
    END AS Delivery_Days,


    -- Days late; returns 0 for on-time/early deliveries
    CASE
        WHEN o.Actual_Delivery_Date IS NULL
        THEN NULL

        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN DATEDIFF(
            DAY,
            o.Expected_Delivery_Date,
            o.Actual_Delivery_Date
        )

        ELSE 0
    END AS Days_Late,


    -- Number of days early, if applicable
    CASE
        WHEN o.Actual_Delivery_Date IS NULL
        THEN NULL

        WHEN o.Actual_Delivery_Date < o.Expected_Delivery_Date
        THEN DATEDIFF(
            DAY,
            o.Actual_Delivery_Date,
            o.Expected_Delivery_Date
        )

        ELSE 0
    END AS Days_Early,


    /*--------------------------------------------------------------
      DELIVERY FLAGS
    --------------------------------------------------------------*/

    -- 1 = delivered on or before expected date
    -- 0 = delivered late
    -- NULL = not delivered/cancelled
    CASE
        WHEN o.Actual_Delivery_Date IS NULL
        THEN NULL

        WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
        THEN 1

        ELSE 0
    END AS On_Time_Flag,


    -- 1 = delivered after expected date
    -- 0 = delivered on time/early
    -- NULL = not delivered/cancelled
    CASE
        WHEN o.Actual_Delivery_Date IS NULL
        THEN NULL

        WHEN o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1

        ELSE 0
    END AS Late_Delivery_Flag,


    -- Human-readable version for Tableau charts
    CASE
        WHEN o.Actual_Delivery_Date IS NULL
        THEN 'Not Delivered'

        WHEN o.Actual_Delivery_Date <= o.Expected_Delivery_Date
        THEN 'On Time'

        ELSE 'Late'
    END AS Derived_Delivery_Performance,


    /*--------------------------------------------------------------
      FULFILLMENT METRICS
    --------------------------------------------------------------*/

    -- Quantity shortage on the order
    CASE
        WHEN o.Delivery_Status = 'Cancelled'
        THEN NULL

        WHEN o.Quantity_Received < o.Quantity_Ordered
        THEN o.Quantity_Ordered - o.Quantity_Received

        ELSE 0
    END AS Quantity_Shortfall,


    -- Row-level quantity fill percentage
    CASE
        WHEN o.Delivery_Status = 'Cancelled'
            OR o.Quantity_Ordered = 0
        THEN NULL

        ELSE CAST(
            100.0 * o.Quantity_Received
            / NULLIF(o.Quantity_Ordered, 0)
            AS DECIMAL(10,2)
        )
    END AS Order_Fill_Rate_Pct,


    -- 1 = quantity received >= quantity ordered
    CASE
        WHEN o.Delivery_Status = 'Cancelled'
        THEN NULL

        WHEN o.Quantity_Received >= o.Quantity_Ordered
        THEN 1

        ELSE 0
    END AS Full_Fulfillment_Flag,


    -- Human-readable fulfillment status
    CASE
        WHEN o.Delivery_Status = 'Cancelled'
        THEN 'Cancelled'

        WHEN o.Quantity_Received >= o.Quantity_Ordered
        THEN 'Fully Fulfilled'

        ELSE 'Under Fulfilled'
    END AS Fulfillment_Status,


    /*--------------------------------------------------------------
      ORDER STATUS FLAGS
    --------------------------------------------------------------*/

    CASE
        WHEN o.Delivery_Status = 'Cancelled'
        THEN 1
        ELSE 0
    END AS Cancellation_Flag,


    CASE
        WHEN o.Delivery_Status = 'Partial Delivery'
        THEN 1
        ELSE 0
    END AS Partial_Delivery_Flag,


    CASE
        WHEN o.Delivery_Status <> 'Cancelled'
        THEN 1
        ELSE 0
    END AS Non_Cancelled_Order_Flag,


    CASE
        WHEN o.Actual_Delivery_Date IS NOT NULL
        THEN 1
        ELSE 0
    END AS Delivered_Order_Flag,


    /*--------------------------------------------------------------
      CRITICAL ITEM FLAGS
    --------------------------------------------------------------*/

    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
        THEN 1
        ELSE 0
    END AS Critical_Item_Numeric_Flag,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
        THEN 1
        ELSE 0
    END AS Critical_Delivered_Order_Flag,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
             AND o.Actual_Delivery_Date <= o.Expected_Delivery_Date
        THEN 1
        ELSE 0
    END AS Critical_On_Time_Flag,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
             AND o.Actual_Delivery_Date > o.Expected_Delivery_Date
        THEN 1
        ELSE 0
    END AS Critical_Late_Flag,


    /*--------------------------------------------------------------
      REPORTING SPEND FIELDS
    --------------------------------------------------------------*/

    -- Excludes cancelled orders from realized supply spend
    CASE
        WHEN o.Delivery_Status <> 'Cancelled'
        THEN o.Total_Cost
        ELSE 0
    END AS Reportable_Supply_Spend,


    -- Critical-item spend excluding cancelled orders
    CASE
        WHEN o.Delivery_Status <> 'Cancelled'
             AND i.Critical_Item_Flag = 'Yes'
        THEN o.Total_Cost
        ELSE 0
    END AS Critical_Item_Spend,


    /*--------------------------------------------------------------
      CONTRACT RISK FLAGS
    --------------------------------------------------------------*/

    CASE
        WHEN v.Contract_Status = 'Expiring Contract'
        THEN 1
        ELSE 0
    END AS Expiring_Contract_Flag


FROM SC_Supply_Orders o

INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID;


GO