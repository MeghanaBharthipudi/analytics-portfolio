-- Query #3: RFM Segmentation Analysis
-- Purpose: Customer segmentation using Recency, Frequency, Monetary with risk profiling
-- Date: Sep 2, 2026
-- Dataset: Superstore Sales Dataset

with customer_rfm as
(
select CustomerID,CustomerName,Count(Distinct OrderId) as Frequency, sum(Total_Sales) as Monetary, cast((julianday('2018-12-30') - julianday(Max(OrderDateNew))) as int) as Recency_Days
from(
	select *, cast(replace(Replace(Sales, '$',''),',','') as float) as Total_Sales,
	substr(OrderDate,7,4) || '-' || substr(OrderDate,4,2) || '-' || substr(OrderDate,1,2) as OrderDateNew
	from [Superstore Sales Dataset]
	)
group by CustomerID,CustomerName
),
rfm_scores as
(
select *,
ntile(4) over (order by Recency_Days desc) as r_score,
ntile(4) over (order by Frequency asc) as f_score,
ntile(4) over (order by Monetary asc) as m_score
from customer_rfm
),
customer_segments as
(
select *, CASE WHEN r_score >= 3 and f_score >=3 and m_score >=3 then 'VIP'
when r_score >= 3 and f_score >=3 then 'Loyal'
when r_score = 1 then 'Dormant'
when f_score = 1 then 'One-time'
else 'Standard'
end as Segment 
from rfm_scores
)
select Segment, Count(*) as Customer_Count, round(avg(Recency_Days),2) as Avg_Recency_Days,
round(avg(Frequency),2) as Avg_Frequency, round(avg(Monetary),2) as Avg_Monetary, round(sum(Monetary),0) as Total_Segment_Revenue, 
round(sum(Monetary)/(SELECT SUM(Monetary) FROM customer_segments)*100, 2) as Revenue_Pct
from customer_segments
group by Segment
order by Total_Segment_Revenue desc;