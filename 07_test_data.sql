--1 categories 
INSERT INTO Category (CategoryName, Description) VALUES
('Groceries', 'Food and daily groceries'),
('Beverages', 'Drinks and refreshments'),
('Cleaning', 'Household cleaning products');


--2 suppliers 
INSERT INTO Supplier (SupplierName, Phone, Email, Address) VALUES
('Mauritius Foods Ltd', '57234567', 'contact@maurifoods.mu', 'Port Louis'),
('Island Beverages Co', '58345678', 'sales@islandbev.mu', 'Curepipe'),
('CleanHome Supplies', '59876543', 'info@cleanhome.mu', 'Quatre Bornes');

--3 products
INSERT INTO Product (ProductName, CategoryID, SupplierID, UnitPrice, ReorderLevel) VALUES
('Basmati Rice 5kg', 1, 1, 450.00, 10),
('Orange Juice 1L', 2, 2, 95.00, 20),
('Floor Cleaner 1L', 3, 3, 120.00, 15);

--4 stock levels
INSERT INTO Stock (ProductID, Quantity) VALUES
(1, 50),
(2, 100),
(3, 40);

--5 customers 
INSERT INTO Customer (FirstName, LastName, Phone, Email) VALUES
('Ayaan', 'Patel', '57912345', 'ayaan@gmail.com'),
('Sarah', 'Jean', '59067890', 'sarah@gmail.com'),
('Kevin', 'Ramsamy', '58123456', NULL);

--6 employees 
INSERT INTO Customer (FirstName, LastName, Phone, Email) VALUES
('Ayaan', 'Patel', '57912345', 'ayaan@gmail.com'),
('Sarah', 'Jean', '59067890', 'sarah@gmail.com'),
('Kevin', 'Ramsamy', '58123456', NULL);

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
