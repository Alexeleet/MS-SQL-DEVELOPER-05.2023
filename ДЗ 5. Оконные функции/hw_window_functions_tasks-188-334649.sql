/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
* https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time, io on
SELECT inv.InvoiceID,  CustomerName, InvoiceDate, SUM(Quantity * UnitPrice) AS [Сумма продажи]
	   , (SELECT SUM(Quantity * UnitPrice) 
			FROM Sales.Invoices JOIN Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
			WHERE InvoiceDate >= '2015-01-01' and month(InvoiceDate) <= month(inv.InvoiceDate) and year(InvoiceDate) <= year(inv.InvoiceDate) 
         ) AS [Нарастающий итог по месяцу]
FROM Sales.Invoices as inv
JOIN Sales.InvoiceLines ON inv.InvoiceID = InvoiceLines.InvoiceID
JOIN Sales.Customers AS c ON c.CustomerID = inv.Customerid
WHERE InvoiceDate >= '2015-01-01'
GROUP BY inv.InvoiceId, CustomerName, InvoiceDate
ORDER BY InvoiceDate,  InvoiceID;
 
/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
SELECT *, SUM([Сумма продажи]) OVER (ORDER BY Year(InvoiceDate), month(InvoiceDate) ) AS [Сумма продажи]
FROM
(SELECT inv.InvoiceID,  CustomerName, InvoiceDate, SUM(Quantity * UnitPrice) AS [Сумма продажи]
FROM Sales.Invoices as inv
	JOIN Sales.InvoiceLines ON inv.InvoiceID = InvoiceLines.InvoiceID
	JOIN Sales.Customers AS c ON c.CustomerID = inv.Customerid
WHERE InvoiceDate >= '2015-01-01'
GROUP BY inv.InvoiceId, CustomerName, InvoiceDate) AS Q1
ORDER BY InvoiceDate, InvoiceID
set statistics time, io off
/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
SELECT * FROM
(
	SELECT InvoiceLines.stockItemId, StockItemName,  year(InvoiceDate) [год], month(invoiceDate) [месяц], sum(quantity) AS [Количество продано], 
		ROW_NUMBER () OVER (PARTITION BY year(InvoiceDate), month(invoiceDate) ORDER BY (sum(quantity)) DESC) AS row_number_
		FROM Sales.Invoices as inv
		JOIN Sales.InvoiceLines ON inv.InvoiceID = InvoiceLines.InvoiceID
		JOIN Warehouse.StockItems ON StockItems.StockItemID = InvoiceLines.StockItemID
	WHERE InvoiceDate BETWEEN '2016-01-01' AND '2016-12-31'
	GROUP BY InvoiceLines.stockItemId, StockItemName, year(InvoiceDate), month(invoiceDate)
) AS Query_1
WHERE row_number_ <= 2
ORDER BY месяц

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT StockItemID
, StockItemName
, Brand
, UnitPrice 
, ROW_NUMBER() OVER(PARTITION BY LEFT(StockItemName,  1) ORDER BY StockItemName) AS   row_number_
, SUM(QuantityPerOuter) OVER () AS Общее_количество_товаров
, SUM(QuantityPerOuter) OVER (PARTITION BY LEFT(StockItemName,  1)) AS Количество_конкретного_товара
, LEAD(StockItemID) OVER (ORDER BY StockItemName) AS Следующий_id_товара
, LAG(StockItemID) OVER (ORDER BY StockItemName) AS Предыдущий_id_товара
, LAG(StockItemName, 2, 'No items') OVER (ORDER BY StockItemName) AS id_товара_2строки_назад
, NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS Группа_по_весу
FROM Warehouse.StockItems

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
SELECT SalespersonPersonID, SaleName, CustomerID,  CustomerName, InvoiceDate, SUM(Quantity * UnitPrice) AS [Сумма сделки]
FROM (
	SELECT LAST_VALUE(InvoiceLines.InvoiceID) OVER (PARTITION BY SalespersonPersonID ORDER BY InvoiceLines.InvoiceID  rows between unbounded preceding  and unbounded following) AS LastinvoiceId
		  , InvoiceLines.InvoiceID, SalespersonPersonID, salesperson.FullName AS SaleName, inv.CustomerID, Customers.CustomerName, InvoiceDate, Quantity, UnitPrice
	FROM Sales.Invoices as inv
		JOIN Sales.InvoiceLines ON inv.InvoiceID = InvoiceLines.InvoiceID
		JOIN Application.People AS salesperson ON salesperson.PersonID = SalespersonPersonID
		JOIN sales.Customers ON Customers.customerID = inv.CustomerID
	 ) AS Query_1
WHERE InvoiceID = LastinvoiceId
GROUP BY SalespersonPersonID, SaleName, customerID,  CustomerName, InvoiceDate
ORDER BY SalespersonPersonID


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

-- !!!! Так как в условии не прописано, что товары не могут быть одинаковыми, выбрал самые дорогие товары (в том числе одинаковые)
-- Также не понятно о какой дате покупки идет речь, если самый дорогой товар могли покупать в разные даты, поэтому вывел самую ранюю дату покупки 
-- дорогого товара.
SELECT *
FROM (
	SELECT inv.CustomerID, CustomerName, StockItemID, UnitPrice
	, InvoiceDate,  DENSE_RANK() OVER (PARTITION BY inv.CustomerID ORDER BY UnitPrice DESC, StockItemID, InvoiceDate) AS dense_rank_
	FROM Sales.Invoices as inv
			JOIN Sales.InvoiceLines ON inv.InvoiceID = InvoiceLines.InvoiceID
			JOIN Sales.Customers ON Customers.CustomerID = inv.CustomerID
	 ) AS Query_1
WHERE dense_rank_ <= 2
ORDER BY CustomerId, UnitPrice DESC



--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 