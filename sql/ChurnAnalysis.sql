-- Query #4: Churn Analysis with Risk Scoring
-- Purpose: Identify churned and at-risk customers with win-back strategy
-- Date: Sep 2, 2026
-- Dataset: Superstore Sales Dataset

with Superstore_cleaned as
(
	select *, cast (replace(replace(Sales,',',''), '$', '') as float) as OrderSales,
	substr(OrderDate,7,4) || '-' || substr(OrderDate,4,2) || '-' || substr(OrderDate,1,2) as OrderDateNew
	from [Superstore Sales Dataset]
),
customer_rfm as
(
	select CustomerName, max(OrderDateNew) as Last_Order_Date, 
	cast((julianday('2018-12-30') - julianday(max(OrderDateNew))) as int) as Days_Since_Last_Purchase,
	count(distinct OrderID) as Total_Orders, 
	sum(OrderSales) as Total_Spent, 
	round(sum(OrderSales)/count(distinct OrderID),2) as Avg_Order_Value
	from Superstore_cleaned
	group by CustomerName
),
customer_churn as
(
	select *,
	case when Days_Since_Last_Purchase > 180 then 'Churned'
	     when Days_Since_Last_Purchase > 90 then 'At-Risk'
	     else 'Active'
	end as Churn_Status,
	(case when Days_Since_Last_Purchase >= 180 then 5 + 2
	      when Days_Since_Last_Purchase >= 90 then 5 + 1
	      else 5 
	 end)
	+
	(case when Total_Orders >= 3 then 0 else 1 end)
	-
	(case when Total_Spent > 500000 then 1 else 0 end)
	as Churn_Risk_Score
	from customer_rfm
),
churn_summary as
(
	select Churn_Status, 
	Count(CustomerName) as Customer_Count,
	round(avg(Days_Since_Last_Purchase),2) as Avg_Recency, 
	round(avg(Total_Orders),2) as Avg_Frequency,
	round(avg(Total_Spent),2) as Avg_Monetary, 
	CASE 
	    WHEN Churn_Status = 'Active' THEN NULL
	    ELSE round(sum(Total_Spent), 0)
	END as Revenue_At_Risk,
	round(avg(Churn_Risk_Score),2) as Avg_Risk_Score	
	from customer_churn
	group by Churn_Status
	order by Revenue_At_Risk desc
)
select * from churn_summary;