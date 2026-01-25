--1 update stock after sale 

CREATE TRIGGER trg_UpdateStockAfterSale
ON Sale
AFTER INSERT
AS
BEGIN
    UPDATE Stock
    SET Quantity = Quantity - i.QuantitySold,
        LastUpdated = GETDATE()
    FROM Stock s
    INNER JOIN inserted i ON s.ProductID = i.ProductID;
END;

