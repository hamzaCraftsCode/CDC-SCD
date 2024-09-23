# CDC_SQL
This SQL script demonstrates a basic Change Data Capture (CDC) process by comparing two versions of a product dataset: products_old (original) and products_new (updated). It performs the following operations:

- INSERT: Identifies new records in products_new that are not present in products_old.
- UPDATE: Detects records where values (such as product name, category, or price) have changed between the two tables.
- DELETE: Finds records in products_old that are no longer present in products_new.
Each of these changes is selected and displayed as part of the CDC process.

# SCD_SQL
This SQL script demonstrates different types of Slowly Changing Dimensions (SCD) used for managing changes in data over time. The example uses a products table with data updates and changes tracked in various ways.

## Operations:
- SCD Type 1 (Overwrite):
  - Updates the existing records with the new data, overwriting any changes and not preserving history.

- SCD Type 2 (Add New Row):
  - Adds new rows for changes, preserving historical versions of data by maintaining multiple records for each product with effective start and end dates.

- SCD Type 3 (Add New Column):
  - Adds a new column to store the previous version of a changed attribute (e.g., price), preserving one historical version in the same row.

- SCD Type 4 (History Table):
  - Maintains a separate history table to track changes, while the main table always contains the latest version of the data.

Each SCD type ensures that changes in product details (like price, category, or name) are handled appropriately based on the type of change tracking used.

# CDC_PYTHON
This Python script demonstrates how to implement Change Data Capture (CDC) using pandas to identify and capture data changes (inserts, updates, and deletions) between two datasets.

## Operations:
- Insertions:
  - Identifies rows present in the new dataset but not in the old dataset.

- Deletions:
  - Detects rows present in the old dataset but missing from the new dataset.

- Updates:
  - Finds rows where data has changed by merging both datasets on a common key (id) and comparing columns like name, age, and city.

The script uses pandas DataFrames to simulate the old and new datasets, and captures all changes between them for easy tracking.

# SCD_PYTHON
This Python script demonstrates the implementation of different types of Slowly Changing Dimensions (SCD) using pandas to manage changes in datasets over time.

## Operations:
- SCD Type 1 (Overwrite):
  - Updates the existing records in the old dataset with new values, losing any previous information. This is done by directly modifying the old data.

- SCD Type 2 (Add New Row):
  - Preserves history by adding new rows for each change. It tracks the validity of each record using effective and expiry dates, marking older records as not current.

- SCD Type 3 (Add New Column):
  - Captures the previous value of a changed attribute by adding a new column. This allows tracking the most recent change while keeping the current value.

- SCD Type 4 (Using a History Table):
  - Maintains a separate history table that stores all historical changes while the main table only contains the current data. This approach efficiently tracks changes without altering the main table's 
    structure.

Each SCD type demonstrates a different method for managing and retaining data changes over time, allowing for varied data history management strategies.
