--Adding tested procedure to Scheduled event (Not supported by current version)
CREATE EVENT dailyETL
ON SCHEDULE AT '23:59:59'
EVERY 1 DAY
DO
BEGIN
CALL ETLRevenueFactAppend();
CALL ETLProductDimensionAppendNewProducts();
END

---Homework doing the same thing as the procedure: ETLProductDimensionAppendNewProducts, but for new customers--
create procedure ETLProductDimensionAppendNewRentalProduct()
begin

DROP Table If EXISTS ipd;

create table ipd as
select p.categoryid, p.productid, p.productname, p.vendorid, c.categoryname, v.vendorname, p.productprice
from ofosumjj_IS415_ZagiM.product p, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
where p.categoryid = c.categoryid
and p.vendorid = v.vendorid 
AND p.productid NOT IN (SELECT ProductID FROM Product_Dimension);

create table ipd as
select r.categoryid, r.productid, r.productname, r.vendorid, c.categoryname, v.vendorname, r.productpricedaily,r.productpriceweekly
from ofosumjj_IS415_ZagiM.rentalProducts r, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
where r.categoryid = c.categoryid
and r.vendorid = v.vendorid 
AND CONCAT(r.productid,"Rental") NOT IN (SELECT CONCAT(ProductID,ProductType) FROM Product_Dimension);

insert into  ofosumjj_IS415_ZagiMDS.Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID, DateValidFrom,DateValidUntil,Current_Status, CategoryName,ProductType,loaded, ExtractionTimeStamp,ProductDailySalesPrice,ProductWeeklySalesPrice)
SELECT i.productid,i.productname,i.vendorid,i.vendorname,i.categoryid, date(now()),'2030-01-01', 'C', i.categoryname,'Rental',0,now(), i.productpricedaily,i.productpriceweekly
FROM ipd i

insert into ofosumjj_IS415_ZagiMDW.Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID,ProductKey,DateValidFrom,DateValidUntil,Current_Status,CategoryName,ProductType, ProductDailySalesPrice,ProductWeeklyPrice)
select r.ProductID,r.ProductName,r.VendorID,r.VendorName,r.CategoryID,r.ProductKey,r.DateValidFrom,r.DateValidUntil,r.Current_Status,r.CategoryName,r.ProductType, r.ProductDailySalesPrice, r.ProductWeeklySalesPrice
from ofosumjj_IS415_ZagiMDS.Product_Dimension r
where r.loaded = 0;

update ofosumjj_IS415_ZagiMDS.Product_Dimension
set loaded = 1;

end

----Test Code------
insert into ofosumjj_IS415_ZagiM.rentalProducts(productid,categoryid, productname,vendorid, productpricedaily,productpriceweekly)
values ('1X2','CL',"Comfy Harness","MK",2800,4800);

insert into ofosumjj_IS415_ZagiM.rentalProducts(productid,categoryid, productname,vendorid, productpricedaily,productpriceweekly)
values ('1X3','EL',"Sunny Charger","OA",3000,5000);

insert into ofosumjj_IS415_ZagiM.product(productid,productname,productprice,vendorid,categoryid)
values ('9X3','Electric Scooter',100,'OA','EL');


create procedure ETLProductDimensionAppendNewRentalProduct()
begin

DROP Table If EXISTS ipd;

create table ipd as
select r.categoryid, r.productid, r.productname, r.vendorid, c.categoryname, v.vendorname, r.productpricedaily,r.productpriceweekly
from ofosumjj_IS415_ZagiM.rentalProducts r, ofosumjj_IS415_ZagiM.category c, ofosumjj_IS415_ZagiM.vendor v
where r.categoryid = c.categoryid
and r.vendorid = v.vendorid 
AND CONCAT(r.productid,"Rental") NOT IN (SELECT CONCAT(ProductID,ProductType) FROM Product_Dimension);

insert into  ofosumjj_IS415_ZagiMDS.Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID, DateValidFrom,DateValidUntil,Current_Status, CategoryName,ProductType,loaded, ExtractionTimeStamp,ProductDailySalesPrice,ProductWeeklySalesPrice)
SELECT i.productid,i.productname,i.vendorid,i.vendorname,i.categoryid, date(now()),'2030-01-01', 'C', i.categoryname,'Rental',0,now(), i.productpricedaily,i.productpriceweekly
FROM ipd i;

insert into ofosumjj_IS415_ZagiMDW.Product_Dimension(ProductID,ProductName,VendorID,VendorName,CategoryID,ProductKey,DateValidFrom,DateValidUntil,Current_Status,CategoryName,ProductType, ProductDailySalesPrice,ProductWeeklyPrice)
select r.ProductID,r.ProductName,r.VendorID,r.VendorName,r.CategoryID,r.ProductKey,r.DateValidFrom,r.DateValidUntil,r.Current_Status,r.CategoryName,r.ProductType, r.ProductDailySalesPrice, r.ProductWeeklySalesPrice
from ofosumjj_IS415_ZagiMDS.Product_Dimension r
where r.loaded = 0;

update ofosumjj_IS415_ZagiMDS.Product_Dimension
set loaded = 1;

end

