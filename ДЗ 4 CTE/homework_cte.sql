USE WideWorldImporters;

/*��������/��������� ���������� ���������� ��������� �������:
��� ���� �������, ��� ��������, �������� ��� �������� ��������:

����� ��������� ������
����� WITH (��� ����������� ������)
�������� �������:*/
/* 1 �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. ������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices. */
-- ����� ���������
SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesPerson = 1 and PersonID NOT IN (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04'); 

-- ����� CTE + ���������
WITH SalesInvoicesCTE AS (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04')
SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesPerson = 1 and PersonID NOT IN (SELECT * FROM SalesInvoicesCTE);

-- ����� CTE + JOIN
WITH SalesInvoicesCTE AS (SELECT SalespersonPersonID FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04')
SELECT PersonID, FullName
FROM Application.People LEFT JOIN SalesInvoicesCTE On People.PersonID = SalesInvoicesCTE.SalespersonPersonID
WHERE SalespersonPersonID IS NULL AND IsSalesPerson = 1;

-- ����� EXISTS
SELECT PersonID, FullName
FROM Application.People
WHERE IsSalesPerson = 1 and NOT EXISTS (SELECT * FROM Sales.Invoices WHERE InvoiceDate = '2015-07-04' AND People.PersonID = Invoices.SalespersonPersonID); 

/*�������� ������ � ����������� ����� (�����������). 
�������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.*/

-- ����� ��������� ������������
SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);

-- ����� ��������� � ANY
SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL(SELECT UnitPrice FROM Warehouse.StockItems);

-- ����� CTE + JOIN
WITH StockItemsCTE AS (SELECT MIN(UnitPrice) AS MinPrice FROM Warehouse.StockItems)
SELECT StockItemID, StockItemName, UnitPrice 
FROM Warehouse.StockItems CROSS JOIN StockItemsCTE
WHERE UnitPrice = MinPrice;


/* �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� �� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). */
-- ����� ���������
SELECT * 
FROM Sales.Customers
WHERE CustomerId IN (SELECT TOP 5 Invoices.CustomerID
					FROM Sales.CustomerTransactions JOIN Sales.Invoices ON Invoices.InvoiceID = CustomerTransactions.InvoiceID 
					ORDER BY TransactionAmount DESC);
-- ����� CTE
WITH TOPCTE AS (SELECT TOP 5 Invoices.CustomerID
					FROM Sales.CustomerTransactions JOIN Sales.Invoices ON Invoices.InvoiceID = CustomerTransactions.InvoiceID 
					ORDER BY TransactionAmount DESC)
SELECT Customers.* 
FROM Sales.Customers JOIN TOPCTE ON Customers.CustomerID = TOPCTE.CustomerID


/* �������� ������ (�� � ��������), � ������� ���� ���������� ������, �������� � ������ ����� ������� �������, � ����� ��� ����������,
������� ����������� �������� ������� (PackedByPersonID). */


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

-- �����������:
-- ���������, ��� ������ � ������������� ������:
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

/* ������ ����� �� ������� Sales.Invoices �� �����, �� �������� �������� ��������� ������� ����� 27000 �� ��� ����� � ������ ��������� ������
����� �����, ���� �����, ��� ����������, ����� ����� �� �����, ����� ����� ��� ���������� ���������� � ������
���� ������ � ������������ ��� �� �������������, ��� � ������� �� ��������
���������� �������� ��������� ����� �������� � messages
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
--����� ��������� ��� � ������� ��������� ������������� �������, ��� � � ������� ��������� �����\���������. �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). �������� ���� ����������� �� ������ �����������.