
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


#Pas_meter_dans_final_code(only for testing purposes):
INSERT INTO Sale (ProductID, CustomerID, EmployeeID, QuantitySold, TotalAmount)
VALUES (1, 1, 1, 2, 900);

SELECT * FROM Employee;
