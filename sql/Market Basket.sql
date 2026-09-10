-- Market Basket Analysis
-- Find all pairs of products that are frequently purchased together in the same order. 
-- For each pair, calculate association metrics to determine strength of relationship.

with Superstore_cleaned as
(
select CustomerID,CustomerName,ProductName,OrderId,Total_Sales,Category
from(
	select *, cast(replace(Replace(Sales, '$',''),',','') as float) as Total_Sales,
	substr(OrderDate,7,4) || '-' || substr(OrderDate,4,2) || '-' || substr(OrderDate,1,2) as OrderDateNew
	from [Superstore Sales Dataset]
	)
),
Product_pairs as
(
select s1.CustomerID, s1.CustomerName, s1.OrderID as OrderID, s1.ProductName as P1, s2.ProductName as P2, s1.Category as P1_Category, s2.Category as P2_Category
from Superstore_cleaned as s1
join Superstore_cleaned as s2
on s1.OrderID = s2.OrderID
where s1.ProductName <> s2.ProductName
and s1.ProductName < s2.ProductName
),
Orders_by_product as
(
select P1 as ProductName,P1_Category as Category, count(DISTINCT(OrderID)) as product_total_orders, count(DISTINCT(OrderID))/(select count(DISTINCT(OrderID)) from Superstore_cleaned)*100 as 'product%'
from Product_pairs
group by P1,P1_Category
),
Product_frequency as
(
select P1, P2, P1_Category, P2_Category,count(DISTINCT(OrderID)) as frequency, 
(count(*)/(select count(Distinct(OrderId)) from Superstore_cleaned))*100 as Support,
count(*)/obp.product_total_orders*100 as confidence
from Product_pairs as pp
join Orders_by_product as obp
on pp.P1 = obp.ProductName
group by pp.P1, pp.P2, pp.P1_Category, pp.P2_Category,obp.ProductName,obp.'product%'
Order by frequency desc
)


-- Same query as before, but let's see if ANY pairs pass the filters
select * from Product_frequency
where frequency >= 5
and confidence >= 20
order by confidence desc
limit 30;

