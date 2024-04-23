---RefreshNewProductDimension()--
---ALTER TABLE-----

UPDATE Product_Dimension
SET LOADED = 1, EXTRACTIONTIMESTAMP = NOW() - INTERVAL 10 DAY;

INSERT INTO ofosumjj_IS415_ZagiM.product(productid,productname,productprice,vendorid,categoryid) VALUES('BX1', 'Fancy Bike', 800, 'MK', 'CY');

------Create Procedure -------

CREATE PROCEDURE RefreshNewProductDimension()
BEGIN

DROP TABLE IF EXISTS IPD;

CREATE TABLE IPD AS
SELECT P.categoryid, P.productid, P.productname, P.vendorid, C.categoryname, V.vendorname
FROM ofosumjj_IS415_ZagiM.product P, ofosumjj_IS415_ZagiM.category C, ofosumjj_IS415_ZagiM.vendor V
WHERE P.categoryid = C.categoryid AND P.vendorid = V.vendorid
AND P.productid NOT IN (SELECT productid
FROM Product_Dimension);

INSERT INTO Product_Dimension(ProductID,productname,VendorID,VendorName,CategoryID,DateValidFrom,DateValidUntil,Current_Status,categoryname,ProductType,LOADED,EXTRACTIONTIMESTAMP)
SELECT I.productid, I.productname, I.vendorid, I.vendorname, I.categoryid, DATE(NOW()), '2030-01-01', 'C', I.categoryname, 'Sales', 0, NOW()
FROM IPD I;

INSERT INTO ofosumjj_IS415_ZagiMDW.Product_Dimension(ProductID,productname,VendorID,VendorName,CategoryID,ProductKey,DateValidFrom,DateValidUntil,Current_Status,categoryname,ProductType)
SELECT R.ProductID, R.productname, R.VendorID, R.VendorName, R.CategoryID, R.ProductKey, R.DateValidFrom, R.DateValidUntil, R.Current_Status, R.categoryname, R.ProductType
FROM ofosumjj_IS415_ZagiMDS.Product_Dimension R
WHERE R.LOADED = 0;

UPDATE Product_Dimension
SET LOADED = 1;

END
----Test Procedure---
INSERT INTO ofosumjj_IS415_ZagiM.product(productid,productname,productprice,vendorid,categoryid) VALUES('9X4', 'Sports Car', 200, 'MK', 'CY');
CALL RefreshNewProductDimension();


---RefreshNewCustomerDimension()--
---ALTER TABLE-----
ALTER TABLE Customer_Dimension
ADD LOADED BOOLEAN NOT NULL,ADD EXTRACTIONTIMESTAMP TIMESTAMP NOT NULL;

UPDATE Customer_Dimension 
SET LOADED = 1, EXTRACTIONTIMESTAMP = NOW() - INTERVAL 10 DAY;

------Create Procedure -------
CREATE PROCEDURE RefreshNewCustomerDimension()
BEGIN

DROP TABLE IF EXISTS ICD;

CREATE TABLE ICD AS
SELECT c.customerid, c.customername, c.customerzip
FROM ofosumjj_IS415_ZagiM.customer c
WHERE c.customerid NOT IN (SELECT customerid
FROM Customer_Dimension);

INSERT INTO Customer_Dimension(CustomerID,CustomerName,CustomerZip,DateValidFrom,DateValidUntil,Current_Status,LOADED,EXTRACTIONTIMESTAMP)
SELECT I.CustomerID, I.CustomerName, I.CustomerZip, DATE(NOW()), '2030-01-01', 'C', 0, NOW()
FROM ICD I;

INSERT INTO ofosumjj_IS415_ZagiMDW.Customer_Dimension(CustomerID,CustomerKey,CustomerName,CustomerZip,DateValidFrom,DateValidUntil,Current_Status)
SELECT R.CustomerID, R.CustomerKey, R.CustomerName, R.CustomerZip, R.DateValidFrom, R.DateValidUntil, R.Current_Status
FROM ofosumjj_IS415_ZagiMDS.Customer_Dimension R
WHERE R.LOADED = 0;

UPDATE Customer_Dimension
SET LOADED = 1;

END

-----------Test Procedure------------
INSERT INTO ofosumjj_IS415_ZagiM.customer(customerid,customername,customerzip) VALUES ('9-2-333', 'Sai Surya', '13676');
CALL RefreshNewCustomerDimension();


---RefreshNewStoreDimension
---ALTER TABLE-----
ALTER TABLE Store_Dimension
ADD LOADED BOOLEAN NOT NULL,ADD EXTRACTIONTIMESTAMP TIMESTAMP NOT NULL;

UPDATE Store_Dimension
SET LOADED = 1, EXTRACTIONTIMESTAMP = NOW() - INTERVAL 10 DAY;

INSERT INTO ofosumjj_IS415_ZagiM.store(storeid,regionid,storezip) VALUES('S15', 'N', '13676');

------Create Procedure -------
CREATE PROCEDURE RefreshNewStoreDimension()
BEGIN

DROP TABLE IF EXISTS ISD;

CREATE TABLE ISD AS
SELECT s.storeid, s.storezip, r.regionid, r.regionname
FROM ofosumjj_IS415_ZagiM.store s , ofosumjj_IS415_ZagiM.region r
WHERE s.regionid = r.regionid AND s.storeid NOT IN (SELECT StoreID
FROM ofosumjj_IS415_ZagiMDS.Store_Dimension);

INSERT INTO Store_Dimension
(StoreID,StoreZip,RegionID,RegionName,DateValidFrom,DateValidUntil,Current_Status,LOADED,EXTRACTIONTIMESTAMP)
SELECT I.storeid, I.storezip, I.regionid, I.regionname, DATE(NOW()), '2030-01-01', 'C', 0, NOW()
FROM ISD I;

INSERT INTO ofosumjj_IS415_ZagiMDW.Store_Dimension(StoreID,StoreKey,StoreZip,RegionID,RegionName,DateValidFrom,DateValidUntil,Current_Status)
SELECT SD.StoreID, SD.StoreKey, SD.StoreZip, SD.RegionID, SD.RegionName, SD.DateValidFrom, SD.DateValidUntil, SD.Current_Status
FROM ofosumjj_IS415_ZagiMDS.Store_Dimension SD
WHERE SD.LOADED = 0;

UPDATE Store_Dimension
SET LOADED = 1;

END

-----------Test Procedure------------
INSERT INTO ofosumjj_IS415_ZagiM.store(storeid,regionid,storezip) VALUES('S16', 'T', '13576');
CALL RefreshNewStoreDimension();







---Run All The PROCEDUREs
CREATE PROCEDURE RefreshEverything()
BEGIN

CALL ETLProductDimensionAppendNewRentalProduct();
CALL LateArrivingfactrefresh();
CALL RefreshNewProductDimension();
CALL RefreshNewCustomerDimension();
CALL RefreshNewStoreDimension();
CALL ETLProductDimensionType2Change();
CALL ETLCustomerDimensionType2Change();

END


---ofosumjj_IS415_ZagiM
---Check Your WORK

---Check Your transacatiosn soldvia + rentvia = transacatiosn
SELECT COUNT(*), RevenueType
GROUP By ReveueType;


---Check Your product


---Check Your customer





---Type PROCEDUREs
CREATE PROCEDURE ETLProductDimensionType2Change()
BEGIN

DROP TABLE IF EXISTS ipd_type2;

CREATE TABLE ipd_type2 AS
SELECT p.categoryid, p.productid, p.productname, p.vendorid, c.categoryname, v.vendorname
FROM ofosumjj_IS415_ZagiM.product p, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
WHERE p.categoryid = c.categoryid
AND p.vendorid = v.vendorid
AND (p.productname NOT IN (SELECT productname
FROM ofosumjj_IS415_ZagiMDS.Product_Dimension)
OR v.vendorname NOT IN (SELECT VendorName
FROM ofosumjj_IS415_ZagiMDS.Product_Dimension)
OR c.categoryname NOT IN (SELECT categoryname
FROM ofosumjj_IS415_ZagiMDS.Product_Dimension));


INSERT INTO Product_Dimension(CategoryID, ProductID, productname, VendorID, categoryname, VendorName, DateValidFrom, DateValidUntil, LOADED, EXTRACTIONTIMESTAMP, ProductType, Current_Status)
SELECT i.categoryid, i.productid, i.productname, i.vendorid, i.categoryname, i.vendorname, DATE(NOW()), '2030-01-01', 0, NOW(), 'Sales', 'C'
FROM ipd_type2 i;

UPDATE Product_Dimension SET DateValidUntil = Date(NOW()) - INTERVAL 1 DAY, Current_Status = 'N'
WHERE loaded = 1 AND ProductID IN (SELECT productid from ipd_type2) AND Current_Status='C';


INSERT INTO ofosumjj_IS415_ZagiMDW.Product_Dimension(ProductKey, CategoryID, ProductID, productname, VendorID, categoryname, VendorName, DateValidFrom, DateValidUntil, ProductType, Current_Status)
SELECT p.ProductKey, p.CategoryID, p.ProductID, p.productname, p.VendorID, p.categoryname, p.VendorName, p.DateValidFrom, p.DateValidUntil, p.ProductType, p.Current_Status
FROM ofosumjj_IS415_ZagiMDS.Product_Dimension p
WHERE loaded=0;


UPDATE ofosumjj_IS415_ZagiMDW.Product_Dimension dwp1, ofosumjj_IS415_ZagiMDW.Product_Dimension dwp2
SET dwp1.DateValidUntil = Date(NOW()) - INTERVAL 1 DAY,dwp1.Current_Status = 'N'
WHERE dwp1.ProductID = dwp2.ProductID
AND dwp2.DateValidFrom > dwp1.DateValidFrom
AND dwp1.Current_Status = 'C';


UPDATE Product_Dimension
SET loaded = 1
WHERE loaded = 0;


END
----------------------------------
UPDATE ofosumjj_IS415_ZagiM.product
SET productname ='Micro Camera'
WHERE productname ='Mega Camera';

CALL ProductRefresh_Type2Changes(); 
------------------------------- ****** CUSTOMER TYPE 2 CHANGES REFRESH ****** -------------------------------

UPDATE ofosumjj_IS415_ZagiM.customer
SET customername = 'Marth'
WHERE customername = 'Miles';


UPDATE ofosumjj_IS415_ZagiM.customer
SET customerzip = '13676'
WHERE customerid = '5-6-777';

------- Test individually the below queries and then Create a Procedure ------

CREATE PROCEDURE ETLCustomerDimensionType2Change()
BEGIN

DROP TABLE IF EXISTS icd_type2;

CREATE TABLE icd_type2 AS
SELECT c.customerid, c.customername, c.customerzip
FROM ofosumjj_IS415_ZagiM.customer c
WHERE CONCAT(c.customername,c.customerid) NOT IN (SELECT CONCAT(CustomerName,CustomerID)
FROM ofosumjj_IS415_ZagiMDS.Customer_Dimension)
OR CONCAT(c.customerzip,c.customerid) NOT IN (SELECT CONCAT(CustomerZip,CustomerID)
FROM ofosumjj_IS415_ZagiMDS.Customer_Dimension);

INSERT INTO Customer_Dimension(CustomerID,CustomerName,CustomerZip, DateValidFrom, DateValidUntil, LOADED, EXTRACTIONTIMESTAMP,Current_Status)
SELECT i.customerid, i.customername, i.customerzip, DATE(NOW()), '2030-01-01', 0, NOW(), 'C'
FROM icd_type2 i;

UPDATE Customer_Dimension
SET DateValidUntil = Date(NOW()) - INTERVAL 1 DAY,
Current_Status = 'N'
WHERE loaded = 1 AND CustomerID IN (SELECT customerid from icd_type2) AND Current_Status='C';

INSERT INTO ofosumjj_IS415_ZagiMDW.Customer_Dimension(CustomerKey,CustomerID,CustomerName,CustomerZip, DateValidFrom, DateValidUntil,Current_Status)
SELECT c.CustomerKey, c.CustomerID, c.CustomerName, c.CustomerZip, c.DateValidFrom, c.DateValidUntil, c.Current_Status
FROM ofosumjj_IS415_ZagiMDS.Customer_Dimension c
WHERE loaded=0;

UPDATE ofosumjj_IS415_ZagiMDW.Customer_Dimension dwc1, ofosumjj_IS415_ZagiMDW.Customer_Dimension dwc2
SET dwc1.DateValidUntil = Date(NOW()) - INTERVAL 1 DAY,dwc1.Current_Status = 'N'
WHERE dwc1.CustomerID = dwc2.CustomerID
AND dwc2.DateValidFrom > dwc1.DateValidFrom
AND dwc1.Current_Status = 'C';

UPDATE Customer_Dimension
SET LOADED = 1
WHERE LOADED = 0;

END
--------------------------
UPDATE ofosumjj_IS415_ZagiM.customer
SET customername = 'Royce'
WHERE customername = 'Tina';

UPDATE ofosumjj_IS415_ZagiM.customer
SET customerzip = '60611'
WHERE customerid = '7-8-999';
CALL CustomerRefresh_Type2Changes();

----Refresh Everything----
CREATE PROCEDURE RefreshEverything()
BEGIN

CALL ETLProductDimensionAppendNewRentalProduct();
CALL LateArrivingfactrefresh();
CALL RefreshNewProductDimension();
CALL RefreshNewCustomerDimension();
CALL RefreshNewStoreDimension();
CALL ETLProductDimensionType2Change();
CALL ETLCustomerDimensionType2Change();

END