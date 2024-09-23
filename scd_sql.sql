-------------------------------------------------------------------------------------------------------
-- Setup the Environment and Create Example Tables
-------------------------------------------------------------------------------------------------------
-- Old Version of the Data (Existing data in the data warehouse)
CREATE TABLE products_old (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    updated_at DATE
);

-- Insert some dummy data into the old table
INSERT INTO products_old (product_id, product_name, category, price, updated_at) VALUES
(1, 'Laptop', 'Electronics', 800.00, '2023-01-01'),
(2, 'Smartphone', 'Electronics', 600.00, '2023-01-01'),
(3, 'T-Shirt', 'Apparel', 20.00, '2023-01-01');

-- New Version of the Data (The latest data from the source system)
CREATE TABLE products_new (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    updated_at DATE
);

-- Insert some dummy data into the new table (simulating changes)
INSERT INTO products_new (product_id, product_name, category, price, updated_at) VALUES
(1, 'Laptop', 'Electronics', 850.00, '2023-02-01'), -- Updated price
(2, 'Smartphone', 'Electronics', 600.00, '2023-02-01'), -- No change
(4, 'Shoes', 'Footwear', 50.00, '2023-02-01'); -- New product added

-------------------------------------------------------------------------------------------------------
-- SCD Type 1: Overwrite
-- In SCD Type 1, we simply overwrite the existing data with the new data. No history is preserved.
-------------------------------------------------------------------------------------------------------
-- Update the existing records in the products_old table with data from products_new
MERGE INTO products_old AS old
USING products_new AS new
ON old.product_id = new.product_id
WHEN MATCHED THEN
    UPDATE SET 
        old.product_name = new.product_name,
        old.category = new.category,
        old.price = new.price,
        old.updated_at = new.updated_at
WHEN NOT MATCHED BY TARGET THEN
    INSERT (product_id, product_name, category, price, updated_at)
    VALUES (new.product_id, new.product_name, new.category, new.price, new.updated_at);

-- Result: The products_old table now contains updated data with no history preserved.
SELECT * FROM products_old;

-------------------------------------------------------------------------------------------------------
-- SCD Type 2: Add New Row (Preserve History)
-- In SCD Type 2, we add a new row whenever there's a change in the data. This approach preserves the full history of changes.
-------------------------------------------------------------------------------------------------------
-- Create a new version of the table to implement SCD Type 2 with versioning
CREATE TABLE products_scd2 (
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    effective_start_date DATE,
    effective_end_date DATE,
    is_current BOOLEAN
);

-- Insert existing data into the SCD2 table
INSERT INTO products_scd2 (product_id, product_name, category, price, effective_start_date, effective_end_date, is_current)
SELECT product_id, product_name, category, price, updated_at, NULL, TRUE FROM products_old;

-- Process the changes
MERGE INTO products_scd2 AS scd2
USING products_new AS new
ON scd2.product_id = new.product_id AND scd2.is_current = TRUE
WHEN MATCHED AND (scd2.product_name <> new.product_name OR scd2.price <> new.price OR scd2.category <> new.category) THEN
    -- Expire the old record
    UPDATE SET 
        scd2.effective_end_date = new.updated_at,
        scd2.is_current = FALSE
WHEN NOT MATCHED BY TARGET THEN
    -- Insert new records
    INSERT (product_id, product_name, category, price, effective_start_date, effective_end_date, is_current)
    VALUES (new.product_id, new.product_name, new.category, new.price, new.updated_at, NULL, TRUE);

-- Insert any brand new records into the SCD2 table
INSERT INTO products_scd2 (product_id, product_name, category, price, effective_start_date, effective_end_date, is_current)
SELECT new.product_id, new.product_name, new.category, new.price, new.updated_at, NULL, TRUE
FROM products_new AS new
WHERE NOT EXISTS (
    SELECT 1 FROM products_scd2 AS scd2
    WHERE scd2.product_id = new.product_id
);

-- Result: The products_scd2 table now contains historical changes
SELECT * FROM products_scd2;

-------------------------------------------------------------------------------------------------------
-- SCD Type 3: Add New Column
-- In SCD Type 3, we add a new column to capture the change and retain the previous value. This method only preserves one historical version.
-------------------------------------------------------------------------------------------------------
-- Create the SCD Type 3 table
CREATE TABLE products_scd3 (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    previous_price DECIMAL(10, 2), -- Column to capture the previous value
    updated_at DATE
);

-- Insert existing data into the SCD3 table
INSERT INTO products_scd3 (product_id, product_name, category, price, previous_price, updated_at)
SELECT product_id, product_name, category, price, NULL, updated_at FROM products_old;

-- Update records in the SCD3 table based on changes in the new data
MERGE INTO products_scd3 AS scd3
USING products_new AS new
ON scd3.product_id = new.product_id
WHEN MATCHED AND scd3.price <> new.price THEN
    UPDATE SET
        scd3.previous_price = scd3.price,
        scd3.price = new.price,
        scd3.updated_at = new.updated_at
WHEN NOT MATCHED BY TARGET THEN
    INSERT (product_id, product_name, category, price, previous_price, updated_at)
    VALUES (new.product_id, new.product_name, new.category, new.price, NULL, new.updated_at);

-- Result: The products_scd3 table now contains the current and one historical value
SELECT * FROM products_scd3;

-------------------------------------------------------------------------------------------------------
-- SCD Type 4: Using History Table
-- In SCD Type 4, we maintain a separate history table that stores all changes, while the main table always contains the latest version.
-------------------------------------------------------------------------------------------------------
-- Create the main table
CREATE TABLE products_main (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    updated_at DATE
);

-- Create the history table
CREATE TABLE products_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    updated_at DATE
);

-- Insert existing data into the main table
INSERT INTO products_main (product_id, product_name, category, price, updated_at)
SELECT product_id, product_name, category, price, updated_at FROM products_old;

-- Transfer any historical data from the main table to the history table before update
INSERT INTO products_history (product_id, product_name, category, price, updated_at)
SELECT product_id, product_name, category, price, updated_at
FROM products_main;

-- Update the main table with the latest data
MERGE INTO products_main AS main
USING products_new AS new
ON main.product_id = new.product_id
WHEN MATCHED THEN
    UPDATE SET
        main.product_name = new.product_name,
        main.category = new.category,
        main.price = new.price,
        main.updated_at = new.updated_at
WHEN NOT MATCHED BY TARGET THEN
    INSERT (product_id, product_name, category, price, updated_at)
    VALUES (new.product_id, new.product_name, new.category, new.price, new.updated_at);

-- Result: The main table contains only the latest data, and the history table stores the historical changes
SELECT * FROM products_main;
SELECT * FROM products_history;




