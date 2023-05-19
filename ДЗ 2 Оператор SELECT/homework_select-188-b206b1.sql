/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID
	 , StockItemName 
FROM Warehouse.StockItems
WHERE StockItemName LIKE 'Animal%' or StockItemName LIKE '%urgent%' ;

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT Sup.SupplierID
	  , SupplierName
FROM Purchasing.Suppliers AS Sup 
	 LEFT JOIN Purchasing.PurchaseOrders AS Orders ON Sup.SupplierID = Orders.SupplierID
WHERE PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT OrderLines.OrderID
        , CONVERT(NVARCHAR, OrderDate, 104) AS OrderDate
		, DATENAME(MONTH, OrderDate) AS OrderDateMonthName
		, DATEPART(QUARTER, OrderDate) AS OrderDateQuarter
		, CASE WHEN MONTH(OrderDate) BETWEEN 1 AND 4 THEN 1
			   WHEN MONTH(OrderDate) BETWEEN 5 AND 8 THEN 2
			   WHEN MONTH(OrderDate) BETWEEN 9 AND 12 THEN 3 END AS OrderDateTercile
		, Customers.CustomerName
FROM Sales.Orders
	LEFT JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
	LEFT JOIN Sales.Customers ON Orders.CustomerID = Customers.CustomerID
WHERE UnitPrice > 100 OR (Quantity > 20 AND OrderLines.PickingCompletedWhen IS NOT NULL)
ORDER BY OrderDateQuarter, OrderDateTercile, OrderDate;

DECLARE @pagesize int = 100
		, @pagenum int = 11
		

SELECT OrderLines.OrderID
        , CONVERT(NVARCHAR, OrderDate, 104) AS OrderDate
		, DATENAME(MONTH, OrderDate) AS OrderDateMonthName
		, DATEPART(QUARTER, OrderDate) AS OrderDateQuarter
		, CASE WHEN MONTH(OrderDate) BETWEEN 1 AND 4 THEN 1
			   WHEN MONTH(OrderDate) BETWEEN 5 AND 8 THEN 2
			   WHEN MONTH(OrderDate) BETWEEN 9 AND 12 THEN 3 END AS OrderDateTercile
		, Customers.CustomerName
FROM Sales.Orders
	LEFT JOIN Sales.OrderLines ON Orders.OrderID = OrderLines.OrderID
	LEFT JOIN Sales.Customers ON Orders.CustomerID = Customers.CustomerID
WHERE UnitPrice > 100 OR (Quantity > 20 AND OrderLines.PickingCompletedWhen IS NOT NULL)
ORDER BY OrderDateQuarter, OrderDateTercile, OrderDate
	OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY
/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/


SELECT DeliveryMethodName
	   ,ExpectedDeliveryDate
	   ,Suppliers.SupplierName
	   ,PreferredName AS ContactPerson
FROM Purchasing.Suppliers 
	LEFT JOIN Purchasing.PurchaseOrders AS PO ON Suppliers.SupplierID = PO.SupplierID
	LEFT JOIN Application.DeliveryMethods AS DM ON DM.DeliveryMethodID = PO.DeliveryMethodID
	LEFT JOIN Application.People ON People.PersonID = PO.ContactPersonID
WHERE ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31' AND DM.DeliveryMethodName IN ('Air Freight' 
	,'Refrigerated Air Freight') AND IsOrderFinalized = 1;


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT  TOP(10) ContactPerson.PreferredName AS [Имя_клиента] 
	   ,SalesPerson.PreferredName AS [Имя_сотрудника]  
FROM Sales.Orders
	 LEFT JOIN Application.People AS SalesPerson ON SalesPerson.PersonID = Orders.SalespersonPersonId
	 LEFT JOIN Application.People AS ContactPerson ON ContactPerson.PersonID = Orders.ContactPersonID
ORDER BY OrderDate DESC;


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT ContactPersonID
       , People.PreferredName
	   , People.PhoneNumber
FROM Sales.Orders 
	 LEFT JOIN Sales.OrderLines ON OrderLines.OrderID = Orders.OrderID
	 LEFT JOIN Warehouse.StockItems ON StockItems.StockItemID = OrderLines.StockItemID
	 LEFT JOIN Application.People ON Orders.ContactPersonID = People.PersonID
WHERE StockItems.StockItemName = 'Chocolate frogs 250g'