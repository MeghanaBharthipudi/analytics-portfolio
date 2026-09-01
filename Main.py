import pandas as pd
import numpy as np
from datetime import datetime

sales_df = pd.read_csv(r'C:\Users\megha\Desktop\Superstore dataset\Superstore Sales Dataset.csv', sep=';', encoding='latin1')

# ============================================================
# PART 1: DATA LOADING & VALIDATION
# ============================================================

# Load CSV with correct encoding and delimiter

print("="*60)
print("PART 1: DATA INSPECTION")
print("="*60)
print(f"\nDataset shape: {sales_df.shape}")
print(f"\nColumn names:")
print(sales_df.columns.tolist())
print(f"\nMissing values:")
print(sales_df.isnull().sum())
print(f"\nDuplicate Order IDs: {sales_df['Order ID'].duplicated().sum()}")

# ============================================================
# PART 2.1: CLEAN SALES COLUMN (Already in DOLLARS)
# ============================================================

print("\n" + "="*60)
print("PART 2.1: CLEAN SALES COLUMN")
print("="*60)

# Remove $ and commas
sales_df['Sales_Clean'] = sales_df['Sales'].str.replace('$', '', regex=False).str.replace(',', '', regex=False).str.strip()
sales_df['Sales_Clean'] = pd.to_numeric(sales_df['Sales_Clean'], errors='coerce')

print(f"\nSales_Clean (DOLLARS):")
print(f"  Min: ${sales_df['Sales_Clean'].min():,.2f}")
print(f"  Max: ${sales_df['Sales_Clean'].max():,.2f}")
print(f"  Mean: ${sales_df['Sales_Clean'].mean():,.2f}")
print(f"  Total: ${sales_df['Sales_Clean'].sum():,.2f}")

# ============================================================
# PART 2.2: CREATE DATE FEATURES
# ============================================================

print("\n" + "="*60)
print("PART 2.2: CREATE DATE FEATURES")
print("="*60)

sales_df['Order_Date_Parsed'] = pd.to_datetime(sales_df['Order Date'], format='%d/%m/%Y')

sales_df['Year'] = sales_df['Order_Date_Parsed'].dt.year
sales_df['Month'] = sales_df['Order_Date_Parsed'].dt.month
sales_df['Month_Name'] = sales_df['Order_Date_Parsed'].dt.strftime('%B')
sales_df['Quarter'] = sales_df['Order_Date_Parsed'].dt.quarter
sales_df['Year_Month'] = sales_df['Order_Date_Parsed'].dt.strftime('%Y-%m')

print(f"\nDate range: {sales_df['Order_Date_Parsed'].min().date()} to {sales_df['Order_Date_Parsed'].max().date()}")

# ============================================================
# PART 2.3: CALCULATE PROFIT & MARGIN
# ============================================================

print("\n" + "="*60)
print("PART 2.3: CALCULATE PROFIT & MARGIN")
print("="*60)

sales_df['Profit'] = sales_df['Sales_Clean'] * 0.124
sales_df['Profit_Margin_Pct'] = 12.4
sales_df['Cost'] = sales_df['Sales_Clean'] - sales_df['Profit']

print(f"\nFinancial Summary:")
print(f"  Total Sales: ${sales_df['Sales_Clean'].sum():,.2f}")
print(f"  Total Profit: ${sales_df['Profit'].sum():,.2f}")
print(f"  Profit Margin: {(sales_df['Profit'].sum() / sales_df['Sales_Clean'].sum() * 100):.2f}%")

# ============================================================
# PART 2.4: CREATE RFM FEATURES
# ============================================================

print("\n" + "="*60)
print("PART 2.4: CREATE RFM SEGMENTATION")
print("="*60)

reference_date = sales_df['Order_Date_Parsed'].max()
print(f"Reference date: {reference_date.date()}")

customer_rfm = sales_df.groupby('Customer Name').agg({
    'Order_Date_Parsed': lambda x: (reference_date - x.max()).days,
    'Order ID': 'count',
    'Sales_Clean': 'sum'
}).rename(columns={
    'Order_Date_Parsed': 'Recency_Days',
    'Order ID': 'Frequency',
    'Sales_Clean': 'Monetary_Value'
})

customer_rfm['R_Score'] = pd.qcut(customer_rfm['Recency_Days'], 4, labels=[4,3,2,1], duplicates='drop').astype(int)
customer_rfm['F_Score'] = pd.qcut(customer_rfm['Frequency'], 4, labels=[1,2,3,4], duplicates='drop').astype(int)
customer_rfm['M_Score'] = pd.qcut(customer_rfm['Monetary_Value'], 4, labels=[1,2,3,4], duplicates='drop').astype(int)

customer_rfm['RFM_Segment'] = customer_rfm.apply(
    lambda x: 'VIP' if (x['R_Score']==4 and x['F_Score']==4 and x['M_Score']==4)
              else 'Loyal' if (x['R_Score']>=3 and x['F_Score']>=3)
              else 'Dormant' if x['R_Score']==1
              else 'Standard',
    axis=1
)

print(f"\nRFM Segments:")
print(customer_rfm['RFM_Segment'].value_counts())

# ============================================================
# PART 2.5: MERGE RFM BACK
# ============================================================

sales_df = sales_df.merge(
    customer_rfm[['RFM_Segment']],
    left_on='Customer Name',
    right_index=True,
    how='left'
)

# ============================================================
# PART 3.1: EXPORT CLEANED DATA
# ============================================================

print("\n" + "="*60)
print("PART 3.1: EXPORT CLEANED DATA")
print("="*60)

export_columns = [
    'Order ID', 'Order Date', 'Year', 'Month', 'Month_Name', 'Quarter', 'Year_Month',
    'Customer ID', 'Customer Name', 'Segment',
    'Region', 'Category', 'Sub-Category', 'Product Name',
    'Sales_Clean', 'Cost', 'Profit', 'Profit_Margin_Pct',
    'RFM_Segment'
]

sales_df_export = sales_df[export_columns].copy()
sales_df_export.to_csv('superstore_cleaned.csv', index=False)

print(f"✓ Data exported to 'superstore_cleaned.csv'")
print(f"  Shape: {sales_df_export.shape}")

# ============================================================
# PART 3.2: SUMMARY STATISTICS
# ============================================================

print("\n" + "="*60)
print("FINAL SUMMARY")
print("="*60)

print(f"\nBusiness Metrics:")
print(f"  Total Orders: {len(sales_df):,}")
print(f"  Unique Customers: {sales_df['Customer Name'].nunique():,}")
print(f"  Total Sales: ${sales_df['Sales_Clean'].sum():,.2f}")
print(f"  Total Profit: ${sales_df['Profit'].sum():,.2f}")
print(f"  Avg Order Value: ${sales_df['Sales_Clean'].mean():,.2f}")

print(f"\nSales by Region:")
print(sales_df.groupby('Region')['Sales_Clean'].sum().sort_values(ascending=False))

print(f"\nRFM Segments:")
print(sales_df['RFM_Segment'].value_counts())

print(f"\n{'='*60}")
print(f"✓ ETL PIPELINE COMPLETE!")
print(f"{'='*60}")
