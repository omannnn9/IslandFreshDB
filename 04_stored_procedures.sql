--1 add product
CREATE PROCEDURE sp_AddProduct
    @ProductName VARCHAR(100),
    @CategoryID INT,
    @SupplierID INT,
    @UnitPrice DECIMAL(10,2),
    @ReorderLevel INT
AS
BEGIN
    INSERT INTO Product (ProductName, CategoryID, SupplierID, UnitPrice, ReorderLevel)
    VALUES (@ProductName, @CategoryID, @SupplierID, @UnitPrice, @ReorderLevel);
END;

--2 update product price with try catch if product does not exist
CREATE PROCEDURE sp_UpdateProductPrice
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        UPDATE Product
        SET UnitPrice = @NewPrice
        WHERE ProductID = @ProductID;

        IF @@ROWCOUNT = 0
            PRINT 'Product does not exist';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred';
    END CATCH
END;

--3 view all products & aupplier
CREATE PROCEDURE sp_ViewProducts
AS
BEGIN
    SELECT p.ProductID, p.ProductName, c.CategoryName, s.SupplierName, p.UnitPrice
    FROM Product p
    JOIN Category c ON p.CategoryID = c.CategoryID
    JOIN Supplier s ON p.SupplierID = s.SupplierID;
END;

