/*
=====================================================================
CASE STUDY 3: HEALTHCARE OPERATIONS & SUPPLY CHAIN PERFORMANCE
Dashboard 2: Vendor & Critical Supply Risk

TABLEAU DATASET

Organization:
Palmetto Regional Health System (PRHS)

Purpose:
Create a Tableau-ready order-level dataset supporting analysis of:

    - Vendor reliability
    - Critical supply risk
    - Contract exposure
    - Department exposure
    - Delivery performance
    - Fulfillment performance
    - Supply spend
    - Monthly performance trends

Grain:
One row per supply order

Primary Tables:
    SC_Supply_Orders
    SC_Supply_Items
    SC_Departments
    SC_Vendors
=====================================================================
*/

USE PalmettoRegionalHealthSystemDW;
GO


SELECT

    /*==============================================================
      ORDER IDENTIFIERS
    ==============================================================*/

    o.Order_ID AS Order_ID,

    o.SC_Department_ID AS Department_ID,

    o.SC_Item_ID AS Item_ID,

    o.SC_Vendor_ID AS Vendor_ID,


    /*==============================================================
      DATE DIMENSIONS
    ==============================================================*/

    o.Order_Date AS Order_Date,

    YEAR(o.Order_Date) AS Order_Year,

    MONTH(o.Order_Date) AS Order_Month_Number,

    DATENAME(MONTH, o.Order_Date) AS Order_Month_Name,

    DATEFROMPARTS(
        YEAR(o.Order_Date),
        MONTH(o.Order_Date),
        1
    ) AS Order_Month_Date,

    o.Expected_Delivery_Date AS Expected_Delivery_Date,

    o.Actual_Delivery_Date AS Actual_Delivery_Date,


    /*==============================================================
      DEPARTMENT DIMENSIONS
    ==============================================================*/

    d.Department_Name AS Department_Name,

    d.Service_Line AS Service_Line,

    d.Location AS Department_Location,


    /*==============================================================
      SUPPLY ITEM DIMENSIONS
    ==============================================================*/

    i.Item_Name AS Item_Name,

    i.Item_Category AS Item_Category,

    i.Critical_Item_Flag AS Critical_Item_Flag,

    i.Par_Level AS Par_Level,

    i.Reorder_Point AS Reorder_Point,


    /*==============================================================
      VENDOR DIMENSIONS
    ==============================================================*/

    v.Vendor_Name AS Vendor_Name,

    v.Vendor_Type AS Vendor_Type,

    v.Contract_Status AS Contract_Status,


    /*==============================================================
      ORDER / FINANCIAL MEASURES
    ==============================================================*/

    o.Quantity_Ordered AS Quantity_Ordered,

    o.Quantity_Received AS Quantity_Received,

    o.Unit_Cost AS Unit_Cost,

    o.Total_Cost AS Total_Cost,

    o.Delivery_Status AS Delivery_Status,


    /*==============================================================
      DELIVERY CALCULATIONS
    ==============================================================*/

    CASE
        WHEN o.Actual_Delivery_Date IS NOT NULL
        THEN DATEDIFF(
            DAY,
            o.Order_Date,
            o.Actual_Delivery_Date
        )
    END AS Delivery_Days,


    CASE
        WHEN o.Actual_Delivery_Date >
             o.Expected_Delivery_Date
        THEN DATEDIFF(
            DAY,
            o.Expected_Delivery_Date,
            o.Actual_Delivery_Date
        )
        ELSE 0
    END AS Days_Late,


    /*==============================================================
      DELIVERY FLAGS
    ==============================================================*/

    CASE
        WHEN o.Actual_Delivery_Date IS NOT NULL
        THEN 1
        ELSE 0
    END AS Delivered_Order_Flag,


    CASE
        WHEN o.Actual_Delivery_Date IS NOT NULL
             AND o.Actual_Delivery_Date <=
                 o.Expected_Delivery_Date
        THEN 1
        ELSE 0
    END AS On_Time_Order_Flag,


    CASE
        WHEN o.Actual_Delivery_Date >
             o.Expected_Delivery_Date
        THEN 1
        ELSE 0
    END AS Late_Order_Flag,


    CASE
        WHEN o.Delivery_Status = 'Cancelled'
        THEN 1
        ELSE 0
    END AS Cancelled_Order_Flag,


    CASE
        WHEN o.Delivery_Status <> 'Cancelled'
        THEN 1
        ELSE 0
    END AS Non_Cancelled_Order_Flag,


    CASE
        WHEN o.Delivery_Status = 'Partial Delivery'
        THEN 1
        ELSE 0
    END AS Partial_Delivery_Flag,


    /*==============================================================
      FULFILLMENT FLAGS
    ==============================================================*/

    CASE
        WHEN o.Delivery_Status <> 'Cancelled'
             AND o.Quantity_Received >=
                 o.Quantity_Ordered
        THEN 1
        ELSE 0
    END AS Fully_Fulfilled_Order_Flag,


    CASE
        WHEN o.Delivery_Status <> 'Cancelled'
             AND o.Quantity_Received <
                 o.Quantity_Ordered
        THEN 1
        ELSE 0
    END AS Under_Fulfilled_Order_Flag,


    /*==============================================================
      CRITICAL SUPPLY FLAGS
    ==============================================================*/

    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
        THEN 1
        ELSE 0
    END AS Critical_Item_Order_Flag,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
        THEN 1
        ELSE 0
    END AS Critical_Delivered_Order_Flag,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
             AND o.Actual_Delivery_Date <=
                 o.Expected_Delivery_Date
        THEN 1
        ELSE 0
    END AS Critical_On_Time_Order_Flag,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date >
                 o.Expected_Delivery_Date
        THEN 1
        ELSE 0
    END AS Critical_Late_Order_Flag,


    /*==============================================================
      CONTRACT RISK FLAGS
    ==============================================================*/

    CASE
        WHEN v.Contract_Status = 'Expiring Contract'
        THEN 1
        ELSE 0
    END AS Expiring_Contract_Flag,


    CASE
        WHEN v.Contract_Status = 'Expiring Contract'
             AND o.Delivery_Status <> 'Cancelled'
        THEN o.Total_Cost
        ELSE 0
    END AS Expiring_Contract_Spend,


    /*==============================================================
      CRITICAL SUPPLY SPEND
    ==============================================================*/

    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
        THEN o.Total_Cost
        ELSE 0
    END AS Critical_Item_Spend,


    /*==============================================================
      QUANTITY FIELDS FOR CRITICAL SUPPLIES
    ==============================================================*/

    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
        THEN o.Quantity_Ordered
        ELSE 0
    END AS Critical_Quantity_Ordered,


    CASE
        WHEN i.Critical_Item_Flag = 'Yes'
             AND o.Actual_Delivery_Date IS NOT NULL
        THEN o.Quantity_Received
        ELSE 0
    END AS Critical_Quantity_Received


FROM SC_Supply_Orders o

INNER JOIN SC_Departments d
    ON o.SC_Department_ID = d.SC_Department_ID

INNER JOIN SC_Supply_Items i
    ON o.SC_Item_ID = i.SC_Item_ID

INNER JOIN SC_Vendors v
    ON o.SC_Vendor_ID = v.SC_Vendor_ID

ORDER BY
    o.Order_Date,
    o.Order_ID;