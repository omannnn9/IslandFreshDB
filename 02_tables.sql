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

ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Phone UNIQUE (Phone);

--6 emplyee table --Ayush
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50),
    Role VARCHAR(20) CHECK (Role IN ('Cashier', 'Manager')),
    HireDate DATE,
    Salary DECIMAL(10,2) CHECK (Salary > 0)
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
