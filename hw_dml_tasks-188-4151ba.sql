/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO Sales.Customers ( CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID
							, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage
							, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition,
							WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, 
						    PostalAddressLine2, PostalPostalCode, LastEditedBy )
SELECT TOP 5  CustomerName + 'test' AS CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID
							, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage
							, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition,
							WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, 
						    PostalAddressLine2, PostalPostalCode, LastEditedBy 
FROM Sales.Customers

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Sales.Customers WHERE CustomerID = 1067


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Sales.Customers
SET CustomerName += 'test'
WHERE CustomerID = 1066

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers as target
USING (SELECT  CustomerName + 'test3' AS CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID
							, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage
							, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition,
							WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, 
						    PostalAddressLine2, PostalPostalCode, LastEditedBy 
	    FROM Sales.Customers
		WHERE CustomerID = 1065
	  ) AS source (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID
							, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage
							, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition,
							WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, 
						    PostalAddressLine2, PostalPostalCode, LastEditedBy)
		ON (target.CustomerName = source.CustomerName)
WHEN MATCHED THEN UPDATE SET CustomerName = source.CustomerName
, BillToCustomerID = source.BillToCustomerID
, CustomerCategoryID = source.CustomerCategoryID
, BuyingGroupID = source.BuyingGroupID
, PrimaryContactPersonID = source.PrimaryContactPersonID
, AlternateContactPersonID = source.AlternateContactPersonID
, DeliveryMethodID = source.DeliveryMethodID
, DeliveryCityID = source.DeliveryCityID
, PostalCityID = source.PostalCityID
, CreditLimit = source.CreditLimit
, AccountOpenedDate = source.AccountOpenedDate
, StandardDiscountPercentage = source.StandardDiscountPercentage
, IsStatementSent = source.IsStatementSent
, IsOnCreditHold = source.IsOnCreditHold
, PaymentDays = source.PaymentDays
, PhoneNumber = source.PhoneNumber
, FaxNumber = source.FaxNumber
, DeliveryRun = source.DeliveryRun
, RunPosition = source.RunPosition
, WebsiteURL = source.WebsiteURL
, DeliveryAddressLine1 = source.DeliveryAddressLine1
, DeliveryAddressLine2 = source.DeliveryAddressLine2
, DeliveryPostalCode = source.DeliveryPostalCode
, DeliveryLocation = source.DeliveryLocation
, PostalAddressLine1 = source.PostalAddressLine1
, PostalAddressLine2 = source.PostalAddressLine2
, PostalPostalCode = source.PostalPostalCode
, LastEditedBy = source.LastEditedBy
WHEN NOT MATCHED THEN INSERT (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID
							, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage
							, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition,
							WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, 
						    PostalAddressLine2, PostalPostalCode, LastEditedBy)
				   VALUES (source.CustomerName, source.BillToCustomerID, source.CustomerCategoryID, source.BuyingGroupID, source.PrimaryContactPersonID, source.AlternateContactPersonID
							, source.DeliveryMethodID, source.DeliveryCityID, source.PostalCityID, source.CreditLimit, source.AccountOpenedDate, source.StandardDiscountPercentage
							, source.IsStatementSent, source.IsOnCreditHold, source.PaymentDays, source.PhoneNumber, source.FaxNumber, source.DeliveryRun, source.RunPosition,
							source.WebsiteURL, source.DeliveryAddressLine1, source.DeliveryAddressLine2, source.DeliveryPostalCode, source.DeliveryLocation, source.PostalAddressLine1, 
						    source.PostalAddressLine2,source.PostalPostalCode, source.LastEditedBy)
				  OUTPUT deleted.*, $action, inserted.*;
 

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO

SELECT @@SERVERNAME

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out "C:\1\bcp.txt" -T -w -t"fff" -S  DESKTOP-3GTTROL'

SELECT *
INTO [WideWorldImporters].Sales.CustomersTest
FROM [WideWorldImporters].Sales.Customers
WHERE 1 = 2 


BULK INSERT [WideWorldImporters].Sales.CustomersTest
		FROM "C:\1\bcp.txt"
		WITH ( BATCHSIZE = 1000
			 , DATAFILETYPE = 'widechar'
			 , FIELDTERMINATOR = 'fff' 
			 , ROWTERMINATOR = '\n'
			 , KEEPNULLS
			 , TABLOCK
			)