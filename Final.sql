---01_create_database
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'IslandFreshDB')
BEGIN
    ALTER DATABASE IslandFreshDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE IslandFreshDB;
END
GO

CREATE DATABASE IslandFreshDB;
GO

USE IslandFreshDB;
GO

---02_tables
--1 category table -Oman
CREATE TABLE Category (
CategoryID INT IDENTITY(1,1) PRIMARY KEY,
CategoryName VARCHAR(50) NOT NULL UNIQUE,
Description VARCHAR(100)
);
GO

--2 supplier table -Ashfar
CREATE TABLE Supplier (
SupplierID INT IDENTITY(1,1) PRIMARY KEY,
SupplierName VARCHAR(100) NOT NULL,
Phone VARCHAR(15),
Email VARCHAR(100),
Address VARCHAR(150)
);
GO

--3 product table -Yohan
CREATE TABLE Product (
ProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductName VARCHAR(100) NOT NULL,
CategoryID INT NOT NULL,
SupplierID INT NOT NULL,
UnitPrice DECIMAL(7,2) NOT NULL CHECK (UnitPrice > 0),
ReorderLevel INT NOT NULL DEFAULT 10,
FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);
GO

--4 stock table -Farhaan
CREATE TABLE Stock (
StockID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT NOT NULL UNIQUE,
Quantity INT NOT NULL CHECK (Quantity >= 0),
LastUpdated DATETIME,
FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
GO

--5 customer table --Yohan
CREATE TABLE Customer (
CustomerID INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(50) NOT NULL,
LastName VARCHAR(50),
Phone VARCHAR(15),
Email VARCHAR(100)
);
GO

--6 employee table --Ayush
CREATE TABLE Employee (
EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(50) NOT NULL,
LastName VARCHAR(50),
Role VARCHAR(20) CHECK (Role IN ('Cashier', 'Manager')),
HireDate DATE,
Salary DECIMAL(10,2) CHECK (Salary > 0),
Phone VARCHAR(15),
Email VARCHAR(50)
);
GO

--7 sale table --Oman
CREATE TABLE Sale (
SaleID INT IDENTITY(1,1) PRIMARY KEY,
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
GO

--audit table
CREATE TABLE AuditLog(
AuditID INT IDENTITY(1,1) PRIMARY KEY,
UserName VARCHAR(100),
ActionType VARCHAR(20),
TableName VARCHAR(50),
ActionDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE StockAudit (
AuditID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT,
OldQuantity INT,
NewQuantity INT,
ChangeDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE LowStockAlert (
AlertID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT,
Quantity INT,
AlertDate DATETIME DEFAULT GETDATE()
);
GO

---03_constraints
ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Phone UNIQUE (Phone);
GO

---04_stored_procedures
--1 add product
CREATE PROCEDURE sp_AddProduct
@ProductName VARCHAR(100),
@CategoryID INT,
@SupplierID INT,
@UnitPrice DECIMAL(7,2),
@ReorderLevel INT
AS
BEGIN
INSERT INTO Product (ProductName, CategoryID, SupplierID, UnitPrice, ReorderLevel)
VALUES (@ProductName, @CategoryID, @SupplierID, @UnitPrice, @ReorderLevel);
END;
GO

--2 update product price
CREATE PROCEDURE sp_UpdateProductPrice
@ProductID INT,
@NewPrice DECIMAL(7,2)
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

--3 view all products
CREATE PROCEDURE sp_ViewProducts
AS
BEGIN
SELECT p.ProductID, p.ProductName, c.CategoryName, s.SupplierName, p.UnitPrice
FROM Product p
JOIN Category c ON p.CategoryID = c.CategoryID
JOIN Supplier s ON p.SupplierID = s.SupplierID;
END;
GO

--4 process sale
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

SELECT @Price = UnitPrice FROM Product WHERE ProductID = @ProductID;

IF @Price IS NULL
BEGIN
    PRINT 'Product not found';
    RETURN;
END

SET @Total = @Price * @QuantitySold;

INSERT INTO Sale (ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
VALUES (@ProductID, @CustomerID, @EmployeeID, @QuantitySold, @Total);

END;
GO

---05_triggers
---Trig1:
CREATE TRIGGER trg_UpdateStockAfterSale
ON Sale
AFTER INSERT
AS
BEGIN
UPDATE s
SET s.Quantity = s.Quantity - i.QuantitySold,
s.LastUpdated = GETDATE()
FROM Stock s
INNER JOIN inserted i ON s.ProductID = i.ProductID;
END;
GO

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
RETURN;
END

INSERT INTO Sale (SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
SELECT SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount FROM inserted;

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
GO

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
GO

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
GO

---06_security
IF DATABASE_PRINCIPAL_ID('ManagerRole') IS NULL
BEGIN
    CREATE ROLE ManagerRole;
END
GO

IF DATABASE_PRINCIPAL_ID('CashierRole') IS NULL
BEGIN
    CREATE ROLE CashierRole;
END
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON Product TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Category TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Supplier TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Stock TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Sale TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Customer TO ManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Employee TO ManagerRole;
GO

GRANT SELECT ON Product TO CashierRole;
GRANT SELECT ON Stock TO CashierRole;
GRANT SELECT ON Customer TO CashierRole;
GRANT INSERT ON Sale TO CashierRole;
GO

DENY UPDATE ON Product TO CashierRole;
DENY DELETE ON Product TO CashierRole;
DENY SELECT ON Employee TO CashierRole;
GO

---07_test_data
INSERT INTO Category (CategoryName, Description) VALUES
('Groceries', 'Food and daily groceries'),
('Beverages', 'Drinks and refreshments'),
('Cleaning', 'Household cleaning products');
GO

INSERT INTO Supplier (SupplierName, Phone, Email, Address) VALUES
('Mauritius Foods Ltd', '57234567', 'contact@maurifoods.mu', 'Port Louis'),
('Island Beverages Co', '58345678', 'sales@islandbev.mu', 'Curepipe'),
('CleanHome Supplies', '59876543', 'info@cleanhome.mu', 'Quatre Bornes');
GO

INSERT INTO Product (ProductName, CategoryID, SupplierID, UnitPrice, ReorderLevel) VALUES
('Basmati Rice 5kg', 1, 1, 450.00, 10),
('Orange Juice 1L', 2, 2, 95.00, 20),
('Floor Cleaner 1L', 3, 3, 120.00, 15);
GO

INSERT INTO Stock (ProductID, Quantity, LastUpdated) VALUES
(1, 50, GETDATE()),
(2, 100, GETDATE()),
(3, 40, GETDATE());
GO

INSERT INTO Customer (FirstName, LastName, Phone, Email) VALUES
('Ayaan', 'Patel', '57912345', 'ayaan@gmail.com'),
('Sarah', 'Jean', '59067890', 'sarah@gmail.com'),
('Kevin', 'Ramsamy', '58123456', NULL);
GO

INSERT INTO Employee (FirstName, LastName, Role, HireDate, Salary, Phone, Email) VALUES
('Ayaan', 'Patel', 'Manager', '2023-01-01', 50000, '57912345', 'ayaan@gmail.com'),
('Sarah', 'Jean', 'Cashier', '2023-02-15', 25000, '59067890', 'sarah@gmail.com'),
('Kevin', 'Ramsamy','Cashier','2023-03-20',22000,'58123456',NULL);
GO

EXEC sp_ProcessSale 1,1,2,5;
GO

EXEC sp_ProcessSale 2,2,2,3;
GO

---08 Indexing
CREATE INDEX idx_ProductName ON Product(ProductName);
GO
