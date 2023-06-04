/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

USE WideWorldImporters;

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
WITH CountSalesCTE AS (
	SELECT FORMAT(CAST(STR(10000 * Year(invoiceDate) + 100 * Month(invoiceDate) + 1) AS date), 'd', 'de-de') AS Дата
		, SUBSTRING(CustomerName, 16, len(CustomerName) - 16) as Name
	FROM Sales.Invoices JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	where Invoices.CustomerID in (2,3,4,5,6))
SELECT * FROM CountSalesCTE
PIVOT (count(Name) FOR Name IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])) AS pivotTable


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT *
FROM(
	SELECT CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2 
	FROM Sales.Customers 
	where CustomerName LIKE 'Tailspin Toys%'
	) AS Q
UNPIVOT (AddressLine FOR Property IN ([DeliveryAddressLine1], [DeliveryAddressLine2], [PostalAddressLine1], [PostalAddressLine2])) AS unpvt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
SELECT CountryID, CountryName, Code
FROM(
	SELECT 
	CountryID, CountryName, CAST(IsoAlpha3Code as varchar) AS IsoAlpha3Code, CASt(IsoNumericCode AS VARCHAR) AS IsoNumericCode
	FROM Application.Countries) AS T
UNPIVOT (Code FOR Property IN ([IsoAlpha3Code] , [IsoNumericCode])) as unpvt

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT CustomerID, CustomerName, q1.*
FROM Sales.Customers 
					CROSS APPLY (SELECT TOP 2 StockItemID, UnitPrice, InvoiceDate
								 FROM Sales.Invoices 
									JOIN Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
									JOIN Sales.Customers as c on c.CustomerID = Invoices.CustomerID
								 WHERE c.CustomerID = customers.CustomerID
								 ORDER BY UnitPrice DESC) AS q1