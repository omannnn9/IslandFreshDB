---01_create_database
CREATE DATABASE IslandFreshDB;
GO

USE IslandFreshDB;
GO


---02_tables
--1 category table -Oman 
CREATE TABLE Category (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(100)
);

--2 supplier table -Ashfar
CREATE TABLE Supplier (
    SupplierID INT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    Address VARCHAR(150)
);

--3 product table -Yohan
CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    UnitPrice DECIMAL(7,2) NOT NULL CHECK (UnitPrice > 0),
    ReorderLevel INT NOT NULL DEFAULT 10,
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

--4 stock table -Farhaan
CREATE TABLE Stock (
    StockID INT PRIMARY KEY,
    ProductID INT NOT NULL UNIQUE,
    Quantity INT NOT NULL CHECK (Quantity >= 0),
    LastUpdated DATETIME,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);



--5 customer table --Yohan
CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50),
    Phone VARCHAR(15),
    Email VARCHAR(100)
);


--6 employee table --Ayush
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50),
    Role VARCHAR(20) CHECK (Role IN ('Cashier', 'Manager')),
    HireDate DATE,
    Salary DECIMAL(10,2) CHECK (Salary > 0),
    Phone VARCHAR(15),
    Email VARCHAR(50)
);

--7 sale table --Oman
CREATE TABLE Sale (
    SaleID INT PRIMARY KEY,
    SaleDate DATETIME DEFAULT GETDATE(),
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    EmployeeID INT NOT NULL,
    QuantitySold INT NOT NULL CHECK (QuantitySold > 0),
    TotalAmount DECIMAL(7,2) NOT NULL CHECK (TotalAmount >= 0),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

--audit table
CREATE TABLE AuditLog(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    UserName VARCHAR(100),
    ActionType VARCHAR(20),
    TableName VARCHAR(50),
    ActionDate DATETIME DEFAULT GETDATE()
    );

CREATE TABLE StockAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    OldQuantity INT,
    NewQuantity INT,
    ChangeDate DATETIME DEFAULT GETDATE()
    );

CREATE TABLE LowStockAlert (
    AlertID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    AlertDate DATETIME DEFAULT GETDATE()
);

---03_constraints
-- prevent duplicate customers by phone number

ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Phone UNIQUE (Phone);


---04_stored_procedures
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

GO

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

GO
--3 view all products & aupplier
CREATE PROCEDURE sp_ViewProducts
AS
BEGIN
    SELECT p.ProductID, p.ProductName, c.CategoryName, s.SupplierName, p.UnitPrice
    FROM Product p
    JOIN Category c ON p.CategoryID = c.CategoryID
    JOIN Supplier s ON p.SupplierID = s.SupplierID;
END;

--4 
CREATE PROCEDURE sp_ProcessSale
    @ProductID INT,
    @CustomerID INT,
    @EmployeeID INT,
    @QuantitySold INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Price DECIMAL(7,2);
    DECLARE @Total DECIMAL(7,2);
    DECLARE @NewSaleID INT;

    -- Get the unit price
    SELECT @Price = UnitPrice FROM Product WHERE ProductID = @ProductID;

    IF @Price IS NULL
    BEGIN
        PRINT 'Error: Product ID ' + CAST(@ProductID AS VARCHAR) + ' not found.';
        RETURN;
    END

    -- 1. Calculate the New ID here so it can be passed to the trigger
    SELECT @NewSaleID = ISNULL(MAX(SaleID), 0) + 1 FROM Sale;
    SET @Total = @Price * @QuantitySold;

    -- 2. Pass the @NewSaleID explicitly in the INSERT
    INSERT INTO Sale (SaleID, SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
    VALUES (@NewSaleID, GETDATE(), @ProductID, @CustomerID, @EmployeeID, @QuantitySold, @Total);

    PRINT 'Sale successful. Total Amount: Rs ' + CAST(@Total AS VARCHAR);
END;
GO

---05_triggers
---Trig1:

CREATE TRIGGER trg_UpdateStockAfterSale
ON Sale
AFTER INSERT
AS
BEGIN
    -- Update the Stock table by reducing the quantity sold
    UPDATE s
    SET s.Quantity = s.Quantity - i.QuantitySold,
        s.LastUpdated = GETDATE()
    FROM Stock s
    INNER JOIN inserted i ON s.ProductID = i.ProductID;
END;

---Trig2:

CREATE TRIGGER trg_PreventLowStockSale
ON Sale
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Stock s ON i.ProductID = s.ProductID
        WHERE i.QuantitySold > s.Quantity
    )
    BEGIN
        RAISERROR('Cannot process sale: not enough stock available', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    ELSE
    BEGIN
        -- We MUST include SaleID here because it is NOT NULL in the table
        INSERT INTO Sale (SaleID, SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
        SELECT SaleID, SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount
        FROM inserted;
    END
END;
GO

---Trig3:

CREATE TRIGGER trg_LogStockChanges
ON Stock
AFTER UPDATE
AS
BEGIN
    INSERT INTO StockAudit (ProductID, OldQuantity, NewQuantity)
    SELECT d.ProductID, d.Quantity, i.Quantity
    FROM deleted d
    INNER JOIN inserted i ON d.StockID = i.StockID
    WHERE d.Quantity <> i.Quantity;
END;

---Trig4:

CREATE TRIGGER trg_LowStockAlert
ON Stock
AFTER UPDATE
AS
BEGIN
    INSERT INTO LowStockAlert (ProductID, Quantity)
    SELECT ProductID, Quantity
    FROM inserted
    WHERE Quantity < 5;
END;

---Trig5 :
CREATE TRIGGER trg_Audit_Product
ON Product
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT * FROM inserted) 
       AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLog (UserName, ActionType, TableName)
        VALUES (SYSTEM_USER, 'INSERT', 'Product');
    END

    IF EXISTS (SELECT * FROM deleted) 
       AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO AuditLog (UserName, ActionType, TableName)
        VALUES (SYSTEM_USER, 'DELETE', 'Product');
    END

    IF EXISTS (SELECT * FROM inserted) 
       AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO AuditLog (UserName, ActionType, TableName)
        VALUES (SYSTEM_USER, 'UPDATE', 'Product');
    END
END;


---06_security

CREATE ROLE ManagerRole;
CREATE ROLE CashierRole;


GRANT SELECT, INSERT, UPDATE, DELETE ON Product TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Category TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Supplier TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Stock TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Sale TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Customer TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Employee TO ManagerRole;




GRANT SELECT ON Product TO CashierRole;
GRANT SELECT ON Stock TO CashierRole;
GRANT SELECT ON Customer TO CashierRole;

GRANT INSERT ON Sale TO CashierRole;

DENY UPDATE ON Product TO CashierRole;
DENY DELETE ON Product TO CashierRole;
DENY SELECT ON Employee TO CashierRole;





-- Manager Login and User
CREATE LOGIN ManagerLogin WITH PASSWORD = 'Manager@123';
CREATE USER ManagerUser FOR LOGIN ManagerLogin;
ALTER ROLE ManagerRole ADD MEMBER ManagerUser;

-- Cashier Login and User
CREATE LOGIN CashierLogin WITH PASSWORD = 'Cashier@123';
CREATE USER CashierUser FOR LOGIN CashierLogin;
ALTER ROLE CashierRole ADD MEMBER CashierUser;



UPDATE Product
SET UnitPrice = 500
WHERE ProductID = 1;

---07_test_data
--1 categories 
INSERT INTO Category (CategoryID, CategoryName, Description) VALUES
(1, 'Groceries', 'Food and daily groceries'),
(2, 'Beverages', 'Drinks and refreshments'),
(3, 'Cleaning', 'Household cleaning products');


--2 suppliers 
INSERT INTO Supplier (SupplierID, SupplierName, Phone, Email, Address) VALUES
(1, 'Mauritius Foods Ltd', '57234567', 'contact@maurifoods.mu', 'Port Louis'),
(2, 'Island Beverages Co', '58345678', 'sales@islandbev.mu', 'Curepipe'),
(3, 'CleanHome Supplies', '59876543', 'info@cleanhome.mu', 'Quatre Bornes');

--3 products
INSERT INTO Product (ProductID, ProductName, CategoryID, SupplierID, UnitPrice, ReorderLevel) VALUES
(1, 'Basmati Rice 5kg', 1, 1, 450.00, 10),
(2, 'Orange Juice 1L', 2, 2, 95.00, 20),
(3, 'Floor Cleaner 1L', 3, 3, 120.00, 15);

--4 stock levels
INSERT INTO Stock (StockID, ProductID, Quantity) VALUES
(1, 1, 50),
(2, 2, 100),
(3, 3, 40);

--5 customers 
INSERT INTO Customer (CustomerID, FirstName, LastName, Phone, Email) VALUES
(1, 'Ayaan', 'Patel', '57912345', 'ayaan@gmail.com'),
(2, 'Sarah', 'Jean', '59067890', 'sarah@gmail.com'),
(3, 'Kevin', 'Ramsamy', '58123456', NULL);

--6 employees 
INSERT INTO Employee (EmployeeID, FirstName, LastName, Role, HireDate, Salary, Phone, Email) VALUES
(1, 'Ayaan', 'Patel', 'Manager', '2023-01-01', 50000.00, '57912345', 'ayaan@gmail.com'),
(2, 'Sarah', 'Jean', 'Cashier', '2023-02-15', 25000.00, '59067890', 'sarah@gmail.com'),
(3, 'Kevin', 'Ramsamy','Cashier','2023-03-20', 22000.00, '58123456', NULL);

--7 sales using stored procedure logic
EXEC sp_ProcessSale 
    @ProductID = 1,
    @CustomerID = 1,
    @EmployeeID = 2,
    @QuantitySold = 5;


EXEC sp_ProcessSale 
    @ProductID = 2,
    @CustomerID = 2,
    @EmployeeID = 2,
    @QuantitySold = 3;



--8 Normalization


--9 Indexing
CREATE INDEX idx_ProductName
ON Product(ProductName);
