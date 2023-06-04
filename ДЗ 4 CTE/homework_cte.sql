USE WideWorldImporters;

/*Описание/Пошаговая инструкция выполнения домашнего задания:
Для всех заданий, где возможно, сделайте два варианта запросов:

через вложенный запрос
через WITH (для производных таблиц)
Напишите запросы:*/
/* 1 Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices. */
-- Через подзапрос
SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesPerson = 1 and PersonID NOT IN (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04'); 

-- Через CTE + подзапрос
WITH SalesInvoicesCTE AS (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04')
SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesPerson = 1 and PersonID NOT IN (SELECT * FROM SalesInvoicesCTE);

-- Через CTE + JOIN
WITH SalesInvoicesCTE AS (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04')
SELECT PersonID, FullName
FROM Application.People LEFT JOIN SalesInvoicesCTE On People.PersonID = SalesInvoicesCTE.SalespersonPersonID
WHERE SalespersonPersonID IS NULL AND IsSalesPerson = 1;

-- Через EXISTS
SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesPerson = 1 and NOT EXISTS (SELECT * FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04' AND People.PersonID = Invoices.SalespersonPersonID); 

/*Выберите товары с минимальной ценой (подзапросом). 
Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.*/

-- Через подзапрос классический
SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);

-- Через подзапрос с ANY
SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL(SELECT UnitPrice FROM Warehouse.StockItems);

-- Через CTE + JOIN
WITH StockItemsCTE AS (SELECT MIN(UnitPrice) AS MinPrice FROM Warehouse.StockItems)
SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems CROSS JOIN StockItemsCTE
WHERE UnitPrice = MinPrice;


/* Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). */
-- через подзапрос
SELECT * 
FROM Sales.Customers
WHERE CustomerId IN (SELECT TOP 5 Invoices.CustomerID
					FROM Sales.CustomerTransactions JOIN Sales.Invoices ON Invoices.InvoiceID = CustomerTransactions.InvoiceID 
					ORDER BY TransactionAmount DESC);
-- через CTE
WITH TOPCTE AS (SELECT TOP 5 Invoices.CustomerID
					FROM Sales.CustomerTransactions JOIN Sales.Invoices ON Invoices.InvoiceID = CustomerTransactions.InvoiceID 
					ORDER BY TransactionAmount DESC)
SELECT Customers.* 
FROM Sales.Customers JOIN TOPCTE ON Customers.CustomerID = TOPCTE.CustomerID


/* Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, а также имя сотрудника,
который осуществлял упаковку заказов (PackedByPersonID). */


SELECT DISTINCT CityName, DeliveryCityID, PackedByPersonID, People.FullName
FROM Sales.InvoiceLines JOIN Sales.Invoices ON Invoices.InvoiceID = InvoiceLines.InvoiceID
					    JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID
						JOIN Application.Cities ON Cities.CityID = Customers.DeliveryCityID
						JOIN Application.People ON Invoices.PackedByPersonID = People.PersonID
WHERE StockItemID IN (SELECT TOP 3 WITH TIES StockItemID 
																FROM Sales.InvoiceLines 
																GROUP BY StockItemID 
																ORDER BY MAX(UnitPrice) DESC)


SET STATISTICS IO, TIME ON

-- Опционально:
-- Объясните, что делает и оптимизируйте запрос:
SELECT
	Invoices.InvoiceID,
	Invoices.InvoiceDate,
	(SELECT People.FullName
	FROM Application.People
	WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice,
	(SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
	FROM Sales.OrderLines
	WHERE OrderLines.OrderId = (SELECT Orders.OrderId
	FROM Sales.Orders
	WHERE Orders.PickingCompletedWhen IS NOT NULL
	AND Orders.OrderId = Invoices.OrderId)
	) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN (SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY InvoiceId
		HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID

/* Запрос берет из таблицы Sales.Invoices те Счета, по которому прозошла суммарная продажа свыше 27000 за все время и выдает следующие данные
номер счета, дата счета, Имя продажника, Общая сумма по счету, Общая сумма для выбранного количества в заказе
Ниже запрос с оптимизацеий как по читабельности, так и немного по скорости
Результаты скорости отработки можно смотреть в messages
*/

;WITH InovoiceWithFilterCTE AS (SELECT InvoiceID
							, SUM(Quantity*UnitPrice) AS TotalSummByInvoice
							FROM Sales.InvoiceLines 
							GROUP BY InvoiceId 
							HAVING SUM(Quantity*UnitPrice) > 27000)
SELECT InvoiceCTE.InvoiceID
	  , Invoices.InvoiceDate
	  , People.FullName AS SalesPersonName
	  , TotalSummByInvoice
	  , (SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
			FROM Sales.OrderLines
			WHERE Sales.OrderLines.OrderID = Invoices.OrderId) AS  TotalSummForPickedItems
FROM InovoiceWithFilterCTE AS InvoiceCTE JOIN Sales.Invoices ON InvoiceCTE.InvoiceID = Invoices.InvoiceID
						   JOIN Application.People ON People.PersonID = Invoices.SalespersonPersonID

SET STATISTICS IO, TIME OFF
--Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения. Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). Напишите ваши рассуждения по поводу оптимизации.