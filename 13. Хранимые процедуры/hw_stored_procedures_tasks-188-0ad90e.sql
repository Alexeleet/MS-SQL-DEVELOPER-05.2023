/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

DROP FUNCTION IF EXISTS client_with_max_purchases
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION client_with_max_purchases ()
RETURNS varchar(max)
AS
BEGIN
	DECLARE @client_name as varchar(max)


	SELECT @client_name = CustomerName
		FROM (
			SELECT Customers.CustomerName, SUM (UnitPrice * Quantity) as Сумма_покупок, MAX (SUM (UnitPrice * Quantity)) OVER () AS Mаксимальная_сумма_покупок
			FROM Sales.Invoices JOIN Sales.InvoiceLines  ON Invoices.InvoiceID = InvoiceLines.InvoiceID
								JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
			GROUP BY Customers.CustomerName) AS Q_1
		WHERE Сумма_покупок = Mаксимальная_сумма_покупок


	RETURN @client_name

END
GO

SELECT [dbo].[client_with_max_purchases] () AS Клиент_с_макс_суммой_покупкой


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/
DROP FUNCTION IF EXISTS client_sum_purchases
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION client_sum_purchases (@p_CustomerID_int as int)
RETURNS float
AS
BEGIN
	DECLARE @sum_purchases as float
	SELECT @sum_purchases = SUM (UnitPrice * Quantity) 
	FROM Sales.Invoices JOIN Sales.InvoiceLines  ON Invoices.InvoiceID = InvoiceLines.InvoiceID
						JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	WHERE Customers.CustomerID = @p_CustomerID_int
	GROUP BY Customers.CustomerName

	RETURN @sum_purchases

END
GO

SELECT [dbo].[client_sum_purchases] (1) AS Сумма_покупок_по_клиенту

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

DROP PROCEDURE IF EXISTS sum_sales_proc
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE sum_sales_proc (@result float OUT)
AS
BEGIN

	SELECT @result = SUM (UnitPrice * Quantity) 
	FROM Sales.Invoices JOIN Sales.InvoiceLines  ON Invoices.InvoiceID = InvoiceLines.InvoiceID
						JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	WHERE InvoiceDate BETWEEN '2014-01-01' AND '2015-01-01'

	Return @result

END
GO

DROP FUNCTION IF EXISTS sum_sales
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION sum_sales ()
RETURNS float
AS
BEGIN
	DECLARE @result as float
	SELECT @result = SUM (UnitPrice * Quantity) 
	FROM Sales.Invoices JOIN Sales.InvoiceLines  ON Invoices.InvoiceID = InvoiceLines.InvoiceID
						JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	WHERE InvoiceDate BETWEEN '2014-01-01' AND '2015-01-01'

	Return @result

END
GO




set statistics time, io ON

SELECT [dbo].sum_sales () AS Сумма_покупок_по_клиенту

set statistics time, io OFF

set statistics time, io ON

DECLARE @finish_result float 
EXEC sum_sales_proc  @result = @finish_result OUT
SELECT @finish_result AS Сумма_покупок_по_клиенту

set statistics time, io OFF


/* В Данном случае используется скалярная функция, план запросов показывает что функция быстрее чем процедура.
Как я понял из обучения, план запросов по функциям скалярным смотреть не корректно, потому что они показываются в SQL Server не корректно
Если смотреть через 
set statistics time, io OFF, то существенной разницы в производительности нет.*/ 

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

SELECT CustomerID, CustomerName,  [dbo].client_sum_purchases (CustomerID) AS Сумма_покупки  FROM Sales.Customers

/*
