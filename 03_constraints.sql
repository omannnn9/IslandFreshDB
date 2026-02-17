
-- prevent duplicate customers by phone number 
 ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Phone UNIQUE (Phone);

