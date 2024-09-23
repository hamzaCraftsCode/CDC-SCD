CDC_SQL
This SQL script demonstrates a basic Change Data Capture (CDC) process by comparing two versions of a product dataset: products_old (original) and products_new (updated). It performs the following operations:

INSERT: Identifies new records in products_new that are not present in products_old.
UPDATE: Detects records where values (such as product name, category, or price) have changed between the two tables.
DELETE: Finds records in products_old that are no longer present in products_new.
Each of these changes is selected and displayed as part of the CDC process.
