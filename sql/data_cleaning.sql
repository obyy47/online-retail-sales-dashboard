
-- Menampilkan raw dataset
select * from `cleaning-data-online-retail.online_retail_cleaning.online_retail_raw`

-- Menampilkan setiap kolom beserta tipe datanya
SELECT 
  column_name, 
  data_type 
FROM 
  `cleaning-data-online-retail.online_retail_cleaning.INFORMATION_SCHEMA.COLUMNS`
WHERE 
  table_name = 'online_retail_raw'

-- Standarisasi Data
CREATE OR REPLACE TABLE `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned` AS
SELECT 
    TRIM(InvoiceNo) AS InvoiceNo,
    UPPER(TRIM(StockCode)) AS StockCode,
    UPPER(TRIM(Description)) AS Description,
    Quantity,
    DATE(InvoiceDate) AS InvoiceDate, -- Ubah ke DATE
    UnitPrice,
    TRIM(CAST(CustomerID AS STRING)) AS CustomerID, -- Ubah ke STRING
    INITCAP(TRIM(Country)) AS Country -- PROPER case
FROM 
    `cleaning-data-online-retail.online_retail_cleaning.online_retail_raw`

-- Menampilkan tipe data setiap kolom yang sudah distandarisasi
SELECT 
  column_name, 
  data_type 
FROM 
  `cleaning-data-online-retail.online_retail_cleaning.INFORMATION_SCHEMA.COLUMNS`
WHERE 
  table_name = 'online_retail_cleaned'

-- Menampilkan hasil standarisasi data
SELECT * FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned` 

-- Menghapus anomali dari setiap kolom
CREATE OR REPLACE TABLE `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned` AS
SELECT *
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`
WHERE
    -- 1. InvoiceNo: bukan transaksi cancel & bukan blank
    NOT STARTS_WITH(InvoiceNo, 'C')
    AND NULLIF(InvoiceNo, '') IS NOT NULL
    -- 2. StockCode: hanya format produk valid (5 angka + optional huruf)
    AND REGEXP_CONTAINS(StockCode, r'^[0-9]{5}[A-Z]*$')
    -- 3. Description: bukan blank & bukan anomaly text
    AND NULLIF(Description, '') IS NOT NULL
    AND NOT REGEXP_CONTAINS(Description, r'^\d+$')
    AND NOT REGEXP_CONTAINS(
        Description,
        r'^\?+$|MISSING|LOST|DAMAG'
    )
    -- 4. Quantity: hanya transaksi valid
    AND Quantity > 0
    -- 5. InvoiceDate: tidak boleh NULL
    AND InvoiceDate IS NOT NULL
    -- 6. UnitPrice: harus lebih dari 0
    AND UnitPrice > 0
    -- 7. CustomerID: bukan blank
    AND NULLIF(CustomerID, '') IS NOT NULL
    -- 8. Country: bukan unspecified
    AND Country != 'Unspecified'

-- Menampilkan dataset yang sudah di remove anomaly
SELECT * FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

-- Cek duplikat
SELECT 
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    COUNT(*) AS total_duplicate
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country

HAVING COUNT(*) > 1

--
SELECT 
    COUNT(InvoiceNo) AS duplikat_InvoiceNo
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

GROUP BY
    InvoiceNo

HAVING COUNT(*) > 1

-- Hapus duplikat
CREATE OR REPLACE TABLE `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned` AS

SELECT *
EXCEPT(row_num)

FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                InvoiceNo,
                StockCode,
                Description,
                Quantity,
                InvoiceDate,
                CustomerID,
                Country
            ORDER BY InvoiceNo
        ) AS row_num

    FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`
)

WHERE row_num = 1

-- Menampilkan dataset yang sudah di remove duplikat
SELECT * FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

-- Mengidentifikasi outlier
-- step 1:
SELECT
    MIN(Quantity) AS min_quantity,
    MAX(Quantity) AS max_quantity,
    AVG(Quantity) AS avg_quantity
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

SELECT
    MIN(UnitPrice) AS min_unitprice,
    MAX(UnitPrice) AS max_unitprice,
    AVG(UnitPrice) AS avg_unitprice
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

--step 2:
SELECT
    APPROX_QUANTILES(Quantity, 4)[OFFSET(1)] AS Q1,
    APPROX_QUANTILES(Quantity, 4)[OFFSET(3)] AS Q3
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

SELECT
    APPROX_QUANTILES(UnitPrice, 4)[OFFSET(1)] AS Q1,
    APPROX_QUANTILES(UnitPrice, 4)[OFFSET(3)] AS Q3
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

-- step 3:
WITH stats_qty AS (
SELECT
    APPROX_QUANTILES(Quantity, 4)[OFFSET(1)] AS Q1,
    APPROX_QUANTILES(Quantity, 4)[OFFSET(3)] AS Q3
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`
)

SELECT *
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`,
stats_qty

WHERE Quantity < (Q1 - 1.5 * (Q3 - Q1))
   OR Quantity > (Q3 + 1.5 * (Q3 - Q1))


WITH stats_uprice AS (
SELECT
    APPROX_QUANTILES(UnitPrice, 4)[OFFSET(1)] AS Q1,
    APPROX_QUANTILES(UnitPrice, 4)[OFFSET(3)] AS Q3
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`
)

SELECT *
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`,
stats_uprice

WHERE UnitPrice < (Q1 - 1.5 * (Q3 - Q1))
   OR UnitPrice > (Q3 + 1.5 * (Q3 - Q1))

-- Membuat final dataset yang siap digunakan untuk analisis
CREATE OR REPLACE TABLE `cleaning-data-online-retail.online_retail_cleaning.online_retail_final` AS

SELECT *
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned`

-- Menampilkan final dataset
SELECT * FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_final`

