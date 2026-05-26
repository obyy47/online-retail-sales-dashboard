# 🛍️ Online Retail Executive Dashboard (2010 - 2011)
> **An End-to-End Online Retail Executive Dashboard (2010 - 2011) Project: Ms. Excel ➡️ SQL (BigQuery) ➡️ Python ➡️ Power BI**
---

## 📌 Project Overview

> 📦 **Dataset:** 500K+ raw transactional records | 38 countries | Dec 2010 – Dec 2011 | Source: UK-based Non-Store Online Retailer

This project delivers an end-to-end data pipeline and analysis workflow, transforming a raw, chaotic global retail dataset into an enterprise-grade interactive dashboard. The project spans across the complete data analysis lifecycle: **Data Inspection** (Excel), **Data Cleaning & Transformation** (SQL), **Exploratory Data Analysis** (Python), and **Data Modeling & Visualization** (Power BI).
The primary focus is to convert 500K+ anomalous transactional records into a **reliable, single source of truth** — enabling executive-level monitoring of revenue performance, seasonal trends, and geographical market distributions across 38 countries.

---

## 🎯 Objectives

- **Monitor Executive KPIs:** Track real-time Revenue, Items Sold, Total Orders, and Unique Customer growth.
- **Identify Seasonality & Trends:** Analyze Monthly Sales Performance to identify peak periods and operational cut-offs.
- **Geographical Market Analysis:** Breakdown sales distributions to pinpoint core domestic and high-potential international markets.
- **Interactive Decision-Making:** Deliver dynamic slicing capabilities by Time (Year, Quarter, Month) and Market.

---

## 🛠️ Tools & Technologies

| Phase | Tools | Key Functions |
| :--- | :--- | :--- |
| **Inspection** | Microsoft Excel | Initial data profiling, anomaly detection, and schema assessment. |
| **Data Cleaning** | Google BigQuery (SQL) | Handling nulls, filtering cancelled orders, and record deduplication. |
| **EDA** | Python (Pandas, Seaborn, Matplotlib) | Statistical distribution profiling and outlier analysis. |
| **Data Modeling** | Power BI (DAX) | Star Schema development, dynamic Calendar Table, and MoM Growth Metrics. |

---

## 🔄 Project Workflow

1. **Data Inspection (Excel):** Evaluated raw data structures, identified critical system anomalies, and mapped out data transformation requirements.
2. **Data Cleaning (SQL):** Executed advanced queries to filter out cancelled/test transactions and standardized field formats.
3. **Exploratory Data Analysis (Python):** Investigated data distribution, sales correlations, and prepared the final staging dataset.
4. **Data Modeling & Visualization (Power BI):** Formulated a robust Star Schema model, connecting the transaction fact table to a customized dimension Calendar table (1:* relationship) to power complex Time Intelligence metrics.

---

## 🧹 Data Cleaning & SQL Implementation

The raw dataset contained multiple critical anomalies requiring advanced filtering logic:

- **Cancelled Transactions** — Excluded all invoices prefixed with `'C'` using `STARTS_WITH()` 
  to eliminate reversal records from revenue calculations.
- **Invalid StockCode Formats** — Applied `REGEXP_CONTAINS` to retain only valid 5-digit 
  product codes, filtering out system-generated and test entries.
- **Anomalous Descriptions** — Filtered entries containing numeric-only strings, `?` 
  characters, and keywords like `MISSING`, `LOST`, and `DAMAG` via regex pattern matching.
- **Zero & Negative Values** — Enforced `Quantity > 0` and `UnitPrice > 0` constraints 
  to exclude non-commercial transactions.
- **Missing CustomerID** — Applied `NULLIF()` to remove unidentifiable transactions.
- **Unspecified Country** — Excluded records tagged `'Unspecified'` to ensure 
  geographical analysis accuracy.
  
---

<details>
<summary>📂 Click to expand SQL Query</summary>
    
### Sample Cleaning Query in Google BigQuery
```sql
CREATE OR REPLACE TABLE `cleaning-data-online-retail.online_retail_cleaning.online_retail_cleaned` AS
SELECT *
FROM `cleaning-data-online-retail.online_retail_cleaning.online_retail_raw`
WHERE
    -- 1. InvoiceNo: not a canceled transaction & not empty
    NOT STARTS_WITH(InvoiceNo, 'C')
    AND NULLIF(InvoiceNo, '') IS NOT NULL
    
    -- 2. StockCode: valid product format only (5 digits + optional letters)
    AND REGEXP_CONTAINS(StockCode, r'^[0-9]{5}[A-Z]*$')
    
    -- 3. Description: not blank & not text anomaly
    AND NULLIF(Description, '') IS NOT NULL
    AND NOT REGEXP_CONTAINS(Description, r'^\d+$')
    AND NOT REGEXP_CONTAINS(Description, r'^\?+$|MISSING|LOST|DAMAG')
    
    -- 4. Quantity: only valid transactions
    AND Quantity > 0
    
    -- 5. InvoiceDate: cannot be NULL
    AND InvoiceDate IS NOT NULL
    
    -- 6. UnitPrice: must be greater than 0
    AND UnitPrice > 0
    
    -- 7. CustomerID: not blank
    AND NULLIF(CustomerID, '') IS NOT NULL
    
    -- 8. Country: not unspecified
    AND Country != 'Unspecified'
```
</details>

## 📊 DAX & Data Modeling Features

To build an "anti-error" dashboard capable of dynamic filtering across any timeframe or market without breaking the UI, advanced Time Intelligence DAX Measures were engineered:
-- Example of Month-over-Month (MoM) Customer Growth Logic:

<details>
<summary>📂 Click to expand DAX Query</summary>

```dax
Total Customers = DISTINCTCOUNT('online_retail_final'[CustomerID])

Previous Customers = 
CALCULATE(
    [Total Customers],
    DATEADD(
        Calendar[Date],
        -1,
        MONTH
    )
)

Customers Growth % = 
DIVIDE(
    [Total Customers] - [Previous Customers],
    [Previous Customers],
    0
)
```
</details>

---

## 🐍 Python EDA — Key Visualizations

To uncover sales patterns, market distributions, and revenue correlations, exploratory data analysis was conducted using `Pandas`, `Matplotlib`, and `Seaborn`. Below are the four most impactful analyses:

<details>
<summary>📂 Click to expand Python EDA Snippets</summary>

### 1. 📈 Monthly Revenue Trend
Reveals the Q4 sales surge pattern and confirms the December 2011 data cut-off — validating that the sharp drop is a technical limitation, not an organic sales decline.

```python
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])

monthly_sales = (
    df.groupby(df['InvoiceDate'].dt.to_period('M'))['Revenue']
    .sum()
)

monthly_sales.plot(figsize=(12,5))

plt.title('Monthly Revenue Trend')
plt.xlabel('Month')
plt.ylabel('Revenue (£)')

plt.show()
```

---

### 2. 🌍 Top 10 Countries by Revenue
Confirms the UK as the absolute dominant domestic market, while surfacing Ireland and the Netherlands as the highest-potential international expansion targets.

```python
top_country = (
    df.groupby('Country')['Revenue']
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

top_country.plot(kind='bar', figsize=(10,5))

plt.title('Top 10 Countries by Revenue')
plt.xlabel('Country')
plt.ylabel('Revenue (£)')
plt.xticks(rotation=45)

plt.show()
```

---

### 3. 🛒 Top 10 Best Selling Products
Identifies the highest-volume products by quantity sold, enabling inventory prioritization and supply chain optimization ahead of Q4 cycles.

```python
top_products = (
    df.groupby('Description')['Quantity']
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

top_products.plot(kind='barh', figsize=(10,5))

plt.title('Top 10 Best Selling Products')
plt.xlabel('Total Quantity Sold')
plt.ylabel('Product')

plt.show()
```

---

### 4. 🔥 Correlation Heatmap
Analyzes the relationship between Quantity, UnitPrice, and Revenue — revealing which transactional variables are the strongest revenue drivers.

```python
correlation = df[['Quantity', 'UnitPrice', 'Revenue']].corr()

plt.figure(figsize=(6,4))

sns.heatmap(correlation, annot=True)

plt.title('Correlation Heatmap')
plt.show()
```
</details>

---

## ⚙️ Dashboard Features

- KPI Cards (Revenue, Quantity, Orders, Customers)
- Monthly Sales Trend Analysis
- Sales by Country Visualization
- Interactive Slicers (Year, Quarter, Month, Country)
- Month-over-Month (MoM) Growth Indicators

---

## 🖥️ Dashboard Preview
![Dashboard Preview](images/online_retail_dashboard_preview.png)

---

## 💡 Key Business Insights

- 🇬🇧 **Market Concentration:** The **UK dominates with £6.7M+** in total revenue — dwarfing all international markets combined. Eire (Ireland) and the Netherlands follow as the top two highest-potential international expansion targets.
- 📈 **Q4 Sales Surge:** Monthly sales held a steady baseline of **£0.5M–£0.6M** before a massive escalation in October–November, peaking at **~£1.1M**. Supply chain and logistics must be optimized ahead of Q4 cycles.
- 👥 **Customer & Order Stability:** **4K customers** and **18K orders** moved in sync with transaction spikes, reflecting healthy retention and a sustained **+0.96% MoM customer growth**.
- ⚠️ **December Data Cut-Off:** The sharp drop at year-end is a **technical data cut-off (Dec 9, 2011)** — not an organic sales decline.

---

## 🏁 Conclusion

This end-to-end project demonstrates the successful conversion of raw, transactional data into an optimized, production-ready enterprise dashboard. By resolving data quality issues in SQL/Python and building a proper data model in Power BI, the final artifact serves as a reliable, single source of truth for executive business monitoring and strategic forecasting.

---

## 📚 What I Learned

- Distinguishing a data cut-off from an organic sales decline is critical for honest, non-misleading reporting
- Star Schema + Calendar Table is what unlocks Time Intelligence DAX — flat tables simply can't support MoM/YoY metrics
- `REGEXP_CONTAINS` in BigQuery is far more robust than simple `LIKE` for catching text anomalies in large dirty datasets (500K+ rows)

---

## Author
Robby Adriansyah Fadillah
