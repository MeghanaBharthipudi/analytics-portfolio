-- 
--COHORT ANALYSIS
-- 
with Superstore_cleaned as
(
	select *, cast(replace(Replace(Sales, '$',''),',','') as float) as Total_Sales,
	substr(OrderDate,7,4) || '-' || substr(OrderDate,4,2) || '-' || substr(OrderDate,1,2) as OrderDateNew
	from [Superstore Sales Dataset]
),
Customer_journey as
(
	Select CustomerID, CustomerName,substr(min(OrderDateNew),1,7) as First_Purchase_month, substr(max(OrderDateNew),1,7) as Last_Purchase_month,
	cast((julianday(max(OrderDateNew))-julianday(min(OrderDateNew)))/30.44 as INT) as Cohort_Age_Months,Count(Distinct(OrderID)) as Total_Orders,
	Sum(Total_Sales) as Total_Spent, Round(Sum(Total_Sales)/Count(Distinct(OrderID)),2) as Avg_Order_Value
	From Superstore_cleaned
	group by CustomerID,CustomerName
),
Cohort_summary as
(
	select First_Purchase_month as Cohort, count(*) as Cohort_Size, round(avg(Cohort_Age_Months),2) as 'Avg Months Active',
	sum(Total_Orders)/count(CustomerName) as 'Avg Orders Per Customer', sum(Total_Spent) as 'Total Cohort Revenue',
	round(sum(Total_Spent)/count(CustomerName),2) as 'Avg_Lifetime_Value'
	from Customer_journey
	group by Cohort
)
-- Customer_first_purchase as
-- (
-- 	SELECT CustomerID, CustomerName, substr(min(OrderDateNew),1,7) as first_purchase,substr(min(OrderDateNew), 1, 7) as Cohort_Month
-- 	FROM Superstore_cleaned
-- 	GROUP BY CustomerID,CustomerName
-- ),
-- Customer_orders_with_relative_month as
-- (
-- 	select 
-- 		cfp.CustomerID,
-- 		cfp.CustomerName,
-- 		cfp.Cohort_Month,
-- 		substr(sc.OrderDateNew,1,7) as OrderDateNew,
-- 		cast((julianday(substr(sc.OrderDateNew,1,7)) - julianday(cfp.first_purchase)) / 30.44 as INT) as Relative_Month
-- 	from Customer_first_purchase cfp
-- 	join Superstore_cleaned sc
-- 		on cfp.CustomerID = sc.CustomerID
-- 	order by cfp.CustomerID, sc.OrderDateNew
-- )
select * from Cohort_summary