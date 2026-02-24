#Trig1:

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

#Trig2:

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
        INSERT INTO Sale (SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
        SELECT SaleDate, ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount
        FROM inserted;
    END
END;

#Trig3:

  CREATE TABLE StockAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    OldQuantity INT,
    NewQuantity INT,
    ChangeDate DATETIME DEFAULT GETDATE()
);

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

#Trig4:

CREATE TABLE LowStockAlert (
    AlertID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    AlertDate DATETIME DEFAULT GETDATE()
);

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

#Testing Trigs(Pas meter dans final code, only for testing purpose sa):
SELECT * FROM Stock;

INSERT INTO Sale (ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
VALUES (1, 1, 2, 5, 2250);

INSERT INTO Sale (ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
VALUES (1, 2, 2, 100, 45000);

UPDATE Stock SET Quantity = 3 WHERE ProductID = 1;
