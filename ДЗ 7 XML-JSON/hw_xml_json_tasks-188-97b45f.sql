/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
-- Через OPENXML
GO
DECLARE @xmlDocument AS XML;

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET 
(BULK 'C:\Users\Сарварбек\OneDrive\Рабочий стол\SQL Обучение\StockItems-188-1fb5df.xml', SINGLE_CLOB) as data;

DECLARE @docHandle INT;

EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument


MERGE Warehouse.StockItems as target
USING (SELECT * 
			FROM OPENXML (@docHandle, N'/StockItems/Item')
			WITH (StockItemName NVARCHAR(100) '@Name'
				 , SupplierID INT 'SupplierID'
				 , UnitPackageID INT 'Package/UnitPackageID'
				 , OuterPackageID INT 'Package/OuterPackageID'
				 , QuantityPerOuter INT 'Package/QuantityPerOuter'
				 , TypicalWeightPerUnit FLOAT 'Package/TypicalWeightPerUnit'
				 , LeadTimeDays INT 'LeadTimeDays'
				 , IsChillerStock BIT 'IsChillerStock'
				 , TaxRate FLOAT 'TaxRate'
				 , UnitPrice FLOAT'UnitPrice')
	  ) AS source (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays,  IsChillerStock
				   , TaxRate, UnitPrice)
		ON (target.StockItemName = source.StockitemName)
WHEN MATCHED THEN UPDATE SET StockItemName = source.StockItemName
						 ,  SupplierID = source.SupplierID
						 ,  UnitPackageID = source.UnitPackageID
						 ,  OuterPackageID = source.OuterPackageID
						 ,  QuantityPerOuter = source.QuantityPerOuter
						 ,  TypicalWeightPerUnit = source.TypicalWeightPerUnit
						 ,  LeadTimeDays = source.LeadTimeDays
						 ,  IsChillerStock = source.IsChillerStock
						 ,  TaxRate = source.TaxRate
						 ,  UnitPrice = source.UnitPrice
WHEN NOT MATCHED THEN INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays,  IsChillerStock
				   , TaxRate, UnitPrice, LastEditedBy)
				   VALUES (source.StockItemName, source.SupplierID, source.UnitPackageID, source.OuterPackageID, source.QuantityPerOuter, source.TypicalWeightPerUnit
				   , source.LeadTimeDays,  source.IsChillerStock, source.TaxRate, source.UnitPrice, 1)
				  OUTPUT deleted.*, $action, inserted.*;

GO
-- Через XQuery 

--!!! merge будет плюс минус аналогичный, не стал копировать повторно
DECLARE @x AS XML;

SELECT @x = BulkColumn
FROM OPENROWSET 
(BULK 'C:\Users\Сарварбек\OneDrive\Рабочий стол\SQL Обучение\StockItems-188-1fb5df.xml', SINGLE_CLOB) as data;

SELECT 
	t.Stockitems.value('(@Name)[1]', 'NVARCHAR(100)') as [name]
	, t.Stockitems.value('(SupplierID)[1]', 'INT') as [SupplierID]
	, t.Stockitems.value('(Package/UnitPackageID)[1]', 'INT') as UnitPackageID
	, t.Stockitems.value('(Package/OuterPackageID)[1]' , 'INT') as OuterPackageID
	, t.Stockitems.value('(Package/QuantityPerOuter)[1]', 'INT') as QuantityPerOuter
	, t.Stockitems.value('(Package/TypicalWeightPerUnit)[1]', 'FLOAT') as TypicalWeightPerUnit
	, t.Stockitems.value('(LeadTimeDays)[1]', 'INT') as LeadTimeDays
	, t.Stockitems.value('(IsChillerStock)[1]', 'BIT') AS IsChillerStock
	, t.Stockitems.value('(TaxRate)[1]', 'FLOAT') AS TaxRate  
	, t.Stockitems.value('(UnitPrice)[1]', 'FLOAT') AS UnitPrice
FROM @x.nodes('/StockItems/Item') as t(StockItems)







/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/


SELECT StockItemName as [@name]
   , SupplierID as [SupplierID]
   , UnitPackageID AS [Package/UnitPackageID]
   , OuterPackageID as [Package/OuterPackageID] 
   , QuantityPerOuter as [Package/QuantityPerOuter] 
   , TypicalWeightPerUnit as [Package/TypicalWeightPerUnit] 
   , LeadTimeDays as [LeadTimeDays] 
   , IsChillerStock as [IsChillerStock]
   , TaxRate as [TaxRate]
   , UnitPrice as [UnitPrice]
FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems')

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/


SELECT StockItemID
	  , StockItemName
	  ,	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
	  ,	JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/




DECLARE @index as int = 0
		, @flag as bit = 1;
DECLARE @result_table TABLE (StockItemID int, StockItemName varchar(100))
WHILE @flag = 1
BEGIN
	IF (SELECT SUM(JSON_PATH_EXISTS(CustomFields, CONCAT('$.Tags[', @index,']'))) FROM Warehouse.StockItems) > 0
		BEGIN
			INSERT INTO @result_table
			SELECT StockItemID
			  , StockItemName
			FROM Warehouse.StockItems
			where JSON_VALUE(CustomFields, CONCAT('$.Tags[', @index,']')) = 'Vintage'

			SET @index += 1
		END
   ELSE 
		BEGIN
			SET @flag = 0
		END 
END
SELECT * FROM @result_table;

	




