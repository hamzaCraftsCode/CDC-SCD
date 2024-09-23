-------------------------------------------------------------------------------------------------------
-- Step 1: Setting Up the Environment
-- We will create two tables representing the old and new versions of a dataset and populate them with dummy data.
-- The products_old table represents the original dataset.
-- The products_new table represents the updated dataset.
-------------------------------------------------------------------------------------------------------
-- Create the old version of the dataset
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

-- Create the new version of the dataset
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
-- Step 2: Capturing Changes
-- We will now capture the changes (inserts, updates, and deletions) by comparing the two tables.

-- 2.1 Capturing Inserts
-- Inserts are rows that exist in the products_new table but not in products_old.
-- Using a LEFT JOIN, we identify rows that are present in products_new but missing in products_old. These rows are considered as inserts.
-------------------------------------------------------------------------------------------------------
-- Capture the inserted rows
SELECT 
    'INSERT' AS change_type,
    new.product_id,
    new.product_name,
    new.category,
    new.price,
    new.updated_at
FROM 
    products_new AS new
LEFT JOIN 
    products_old AS old
ON 
    new.product_id = old.product_id
WHERE 
    old.product_id IS NULL;

-- Result:
-- | change_type | product_id | product_name | category   | price | updated_at |
-- | INSERT      | 4          | Shoes        | Footwear   | 50.00 | 2023-02-01 |

-------------------------------------------------------------------------------------------------------
-- 2.2 Capturing Updates
-- Updates are rows that exist in both products_old and products_new but have different data.
-- Using an INNER JOIN, we find matching rows between products_old and products_new but filter for cases where at least one column has changed.
-- An INNER JOIN ensures that only records with matching product_id values in both tables are included in the result. These records represent the data points that exist in both versions (old and new) but might have changes in some columns.
-------------------------------------------------------------------------------------------------------
-- Capture the updated rows
SELECT 
    'UPDATE' AS change_type,
    new.product_id,
    old.product_name AS old_product_name,
    new.product_name AS new_product_name,
    old.category AS old_category,
    new.category AS new_category,
    old.price AS old_price,
    new.price AS new_price,
    new.updated_at
FROM 
    products_old AS old
INNER JOIN 
    products_new AS new
ON 
    old.product_id = new.product_id
WHERE 
    old.product_name <> new.product_name
    OR old.category <> new.category
    OR old.price <> new.price;

-- Result:
-- | change_type | product_id | old_product_name | new_product_name | old_category | new_category | old_price | new_price | updated_at |
-- | UPDATE      | 1          | Laptop           | Laptop           | Electronics  | Electronics  | 800.00    | 850.00    | 2023-02-01 |

-------------------------------------------------------------------------------------------------------
-- 2.3 Capturing Deletions
-- Deletions are rows that exist in products_old but not in products_new.
-- Using a LEFT JOIN, we identify rows that are present in products_old but missing in products_new. These rows are considered as deletions.
-------------------------------------------------------------------------------------------------------
-- Capture the deleted rows
SELECT 
    'DELETE' AS change_type,
    old.product_id,
    old.product_name,
    old.category,
    old.price,
    old.updated_at
FROM 
    products_old AS old
LEFT JOIN 
    products_new AS new
ON 
    old.product_id = new.product_id
WHERE 
    new.product_id IS NULL;

-- Result:
-- | change_type | product_id | product_name | category | price | updated_at |
-- | DELETE      | 3          | T-Shirt      | Apparel  | 20.00 | 2023-01-01 |

-------------------------------------------------------------------------------------------------------
-- Step 3: Combining All Changes
-- We can combine the above results using UNION ALL to create a complete change data capture (CDC) result.
-------------------------------------------------------------------------------------------------------
-- Combine all changes into a single result set
SELECT 
    'INSERT' AS change_type,
    new.product_id,
    new.product_name,
    new.category,
    new.price,
    new.updated_at
FROM 
    products_new AS new
LEFT JOIN 
    products_old AS old
ON 
    new.product_id = old.product_id
WHERE 
    old.product_id IS NULL

UNION ALL

SELECT 
    'UPDATE' AS change_type,
    new.product_id,
    new.product_name,
    new.category,
    new.price,
    new.updated_at
FROM 
    products_old AS old
INNER JOIN 
    products_new AS new
ON 
    old.product_id = new.product_id
WHERE 
    old.product_name <> new.product_name
    OR old.category <> new.category
    OR old.price <> new.price

UNION ALL

SELECT 
    'DELETE' AS change_type,
    old.product_id,
    old.product_name,
    old.category,
    old.price,
    old.updated_at
FROM 
    products_old AS old
LEFT JOIN 
    products_new AS new
ON 
    old.product_id = new.product_id
WHERE 
    new.product_id IS NULL;

-- Result:
-- | change_type | product_id | product_name | category   | price | updated_at |
-- | INSERT      | 4          | Shoes        | Footwear   | 50.00 | 2023-02-01 |
-- | UPDATE      | 1          | Laptop       | Electronics| 850.00| 2023-02-01 |
-- | DELETE      | 3          | T-Shirt      | Apparel    | 20.00 | 2023-01-01 |
