---Do this for daily refresh (LateArrivingfactrefresh renedition 5)---

CREATE PROCEDURE  DailyFactRefresh()
BEGIN

DROP TABLE intermediateRevenueFactTable;

CREATE TABLE intermediateRevenueFactTable as
SELECT sv.noofitems as UnitsSold, sv.noofitems*p.productprice as DollarsGenerated, st.CustomerID, st.StoreID, sv.ProductID, st.tdate, st.tid,'Sales' as RevenueType, 'NumberOfItemsSold' as UnitsOfMeasure
FROM ofosumjj_IS415_ZagiM.product p, ofosumjj_IS415_ZagiM.soldvia sv, ofosumjj_IS415_ZagiM.salestransaction st
WHERE p.ProductID = sv.ProductID
AND sv.Tid = st.Tid
AND rt.tdate > (SELECT DATE((SELECT MAX(f_timestamp) FROM ofosumjj_IS415_ZagiMDS.CoreFact)));

ALTER TABLE intermediateRevenueFactTable
MODIFY RevenueType VARCHAR(80);

ALTER TABLE intermediateRevenueFactTable
MODIFY UnitsOfMeasure VARCHAR(80);

INSERT INTO intermediateRevenueFactTable(UnitsSold, DollarsGenerated, CustomerID, StoreID, ProductID, tdate, tid, RevenueType, UnitsOfMeasure)
SELECT rv.duration as UnitsSold, rv.duration*r.productpricedaily as DollarsGenerated, rt.CustomerID, rt.StoreID, rv.ProductID, rt.tdate, rt.tid,'Rental, Daily' as RevenueType, 'NumberOfDaysRented' as UnitsOfMeasure
FROM ofosumjj_IS415_ZagiM.rentalProducts r, ofosumjj_IS415_ZagiM.rentvia rv, ofosumjj_IS415_ZagiM.rentaltransaction rt
WHERE r.ProductID = rv.ProductID
AND rv.Tid = rt.Tid
AND rt.tdate > (SELECT DATE((SELECT MAX(f_timestamp) FROM ofosumjj_IS415_ZagiMDS.CoreFact)));
AND rv.rentaltype = 'D';

INSERT INTO intermediateRevenueFactTable(UnitsSold, DollarsGenerated, CustomerID, StoreID, ProductID, tdate, tid, RevenueType, UnitsOfMeasure)
SELECT rv.duration as UnitsSold, rv.duration*r.productpriceweekly as DollarsGenerated, rt.CustomerID, rt.StoreID, rv.ProductID, rt.tdate, rt.tid,'Rental, Weekly' as RevenueType, 'NumberOfWeeksRented' as UnitsOfMeasure
FROM ofosumjj_IS415_ZagiM.rentalProducts r, ofosumjj_IS415_ZagiM.rentvia rv, ofosumjj_IS415_ZagiM.rentaltransaction rt
WHERE r.ProductID = rv.ProductID
AND rv.Tid = rt.Tid
AND rt.tdate > (SELECT DATE((SELECT MAX(f_timestamp) FROM ofosumjj_IS415_ZagiMDS.CoreFact)));
AND rv.rentaltype = 'W';

INSERT INTO CoreFact(CustomerKey, ProductKey, LocationKey,
UnitsSold, RevenueGenerated, CalendarKey, TID, f_timestamp, loaded, RevenueType, UnitsOfMeasure)
SELECT c.CustomerKey, p.ProductKey, s.StoreKey, i.UnitsSold,
i.DollarsGenerated, ca.CalendarKey, i.tid, NOW(), FALSE, i.RevenueType, i.UnitsOfMeasure
FROM intermediateRevenueFactTable i, Customer_Dimension c,
Store_Dimension s, Product_Dimension p, Calendar_Dimension ca
WHERE i.CustomerID = c.CustomerID
AND i.StoreID = s.StoreID
AND i.ProductID = p.ProductID
AND left(p.ProductType,1) = LEFT(i.RevenueType, 1)
AND i.tdate = ca.fulldate;

INSERT INTO ofosumjj_IS415_ZagiMDW.CoreFact(CustomerKey, ProductKey, LocationKey, UnitsSold, RevenueGenerated, CalendarKey, TID, RevenueType, UnitsOfMeasure)
SELECT CustomerKey, ProductKey, LocationKey, UnitsSold, RevenueGenerated, CalendarKey, TID, RevenueType, UnitsOfMeasure
FROM CoreFact
WHERE loaded = 0;

UPDATE CoreFact
SET loaded = 1;

END

--Class 4/9/24, Retry dailyrefresh tommorow--

INSERT INTO ofosumjj_IS415_ZagiM.rentaltransaction (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('T9102', '3-4-555', 'S10', '2024-03-15');
INSERT INTO `ofosumjj_IS415_ZagiM`.`rentvia` (`productid`, `tid`, `rentaltype`, `duration`) VALUES ('5X5', 'T9102', 'W', '3');

INSERT INTO ofosumjj_IS415_ZagiM.rentaltransaction (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('T9921', '3-4-555', 'S10', '2024-03-15');
INSERT INTO `ofosumjj_IS415_ZagiM`.`rentvia` (`productid`, `tid`, `rentaltype`, `duration`) VALUES ('5X5', 'T9921', 'D', '3');

INSERT INTO ofosumjj_IS415_ZagiM.salestransaction (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('X591', '3-4-555', 'S10', '2023-03-27');
INSERT INTO ofosumjj_IS415_ZagiM.soldvia (`productid`, `tid`, `noofitems`) VALUES ('1X3', 'X591', '4'), ('6X6', 'X591', '1');












---- ETL Part 8 ----
-- DAILY REFRESHING OF DIMENSION TABLES: ProductDimension example

--in ZAGIMORE_DataStaging, add colmuns "timestamp" and "load status" to the ProductDimension table

ALTER TABLE Product_Dimension ADD loaded BOOLEAN NOT NULL ,
ADD ExtractionTimeStamp TIMESTAMP NOT NULL ;

--set extraction time of all current product dimension values to current time - 10 days for all timestamp values for all instances of ProductDimension so far

--setting "loaded" values to 1 for all instances of ProductDimension so far

UPDATE Product_Dimension
SET loaded = 1,
ExtractionTimeStamp = NOW() - INTERVAL 10 day;         

-- setting up an example of changes in the product dimension by creating a new product
-- creating a new product
insert into ofosumjj_IS415_ZagiM.product(productid,productname,productprice,vendorid,categoryid)
values ('9X1','Fancy Bike',800,'MK','CY')

--creating intermediate product dimension, containing all current sales products,

create table ipd as
select p.categoryid, p.productid, p.productname, p.vendorid, c.categoryname, v.vendorname, p.productprice
from ofosumjj_IS415_ZagiM.product p, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
where p.categoryid = c.categoryid
and p.vendorid = v.vendorid 
AND p.productid NOT IN (SELECT ProductID FROM Product_Dimension);

--------Correction Code-----

create table ipd as
select p.categoryid, p.productid, p.productname, p.vendorid, c.categoryname, v.vendorname, p.productprice
from ofosumjj_IS415_ZagiM.product p, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
where p.categoryid = c.categoryid
and p.vendorid = v.vendorid 
AND p.productid = '9X1' ;


---------------------------------------------


DROP Table ipd
-- testing: adding only new instances of Product Dimension in the Product Dimension table in Data Staging area

insert into Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID, DateValidFrom,DateValidUntil,Current_Status, CategoryName,ProductType,loaded, ExtractionTimeStamp)
SELECT i.productid,i.productname,i.vendorid,i.vendorname,i.categoryid, date(now()),'2030-01-01', 'C', i.categoryname,'Sales',0,now(), i.productprice
FROM ipd i
WHERE i.productid NOT IN (SELECT ProductID FROM Product_Dimension);

-- testing: now adding the same into the Data Warehouse
insert into ofosumjj_IS415_ZagiMDW.Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID,ProductKey,DateValidFrom,DateValidUntil,Current_Status,CategoryName,ProductType, productsalesprice)
select r.ProductID,r.ProductName,r.VendorID,r.VendorName,r.CategoryID,r.ProductKey,r.DateValidFrom,r.DateValidUntil,r.Current_Status,r.CategoryName,r.ProductType, r.productsalesprice
from ofosumjj_IS415_ZagiMDS.Product_Dimension r
where r.loaded = 0;

--- update fields in the data staging
UPDATE Product_Dimension
SET loaded = 1

--Writing a procedure for ETL Daily refresh new product dimension instances
create procedure ETLProductDimensionAppendNewProducts()
begin
DROP Table If EXISTS ipd;

create table ipd as
select p.categoryid, p.productid, p.productname, p.vendorid, c.categoryname, v.vendorname, p.productprice
from ofosumjj_IS415_ZagiM.product p, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
where p.categoryid = c.categoryid
and p.vendorid = v.vendorid 
AND p.productid NOT IN (SELECT ProductID FROM Product_Dimension);

insert into Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID, DateValidFrom,DateValidUntil,Current_Status, CategoryName,ProductType,loaded, ExtractionTimeStamp)
SELECT i.productid,i.productname,i.vendorid,i.vendorname,i.categoryid, date(now()),'2030-01-01', 'C', i.categoryname,'Sales',0,now(), i.productprice
FROM ipd i
WHERE i.productid NOT IN (SELECT ProductID FROM Product_Dimension);


insert into ofosumjj_IS415_ZagiMDW.Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID,ProductKey,DateValidFrom,DateValidUntil,Current_Status,CategoryName,ProductType, productsalesprice)
select r.ProductID,r.ProductName,r.VendorID,r.VendorName,r.CategoryID,r.ProductKey,r.DateValidFrom,r.DateValidUntil,r.Current_Status,r.CategoryName,r.ProductType, r.productsalesprice
from ofosumjj_IS415_ZagiMDS.Product_Dimension r
where r.loaded = 0;

update Product_Dimension
set loaded = 1;

end


--adding two new product to test procedure
insert into ofosumjj_IS415_ZagiM.product(productid,productname,productprice,vendorid,categoryid)
values ('9X2','Fanciest Bike',1800,'MK','CY');

insert into ofosumjj_IS415_ZagiM.product(productid,productname,productprice,vendorid,categoryid)
values ('9X3','Electric Scooter',100,'OA','EL');


--- tesing the procedure
CALL ETLProductDimensionAppendNewProducts()


--Adding tested procedure to Scheduled event (Not supported by current version)
CREATE EVENT dailyETL
ON SCHEDULE AT '23:59:59'
EVERY 1 DAY
DO
BEGIN
CALL ETLRevenueFactAppend();
CALL ETLProductDimensionAppendNewProducts();
END
