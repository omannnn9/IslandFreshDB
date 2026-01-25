--1 price must be positive
CREATE RULE Rule_PositivePrice AS @Price > 0;
EXEC sp_bindrule 'Rule_PositivePrice', 'Product.UnitPrice';

--2 prevent duplicate customers by phone number 
 ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Phone UNIQUE (Phone);

