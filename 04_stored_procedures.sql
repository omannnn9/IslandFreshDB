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

--2 update product price 
CREATE PROCEDURE sp_UpdateProductPrice
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    UPDATE Product
    SET UnitPrice = @NewPrice
    WHERE ProductID = @ProductID;
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

