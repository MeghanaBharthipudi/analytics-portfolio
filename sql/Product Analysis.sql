with Superstore_cleaned as
(
	select *, cast (replace(replace(Sales,',',''), '$', '') as float) as OrderSales,
	substr(OrderDate,7,4) || '-' || substr(OrderDate,4,2) || '-' || substr(OrderDate,1,2) as OrderDateNew
	from [Superstore Sales Dataset]
),
product_pairs as
(
select s1.CustomerName,s1.ProductName as 'P1',s2.ProductName as 'P2',s1.OrderSales as 'P1 Sales' , s2.OrderSales as 'P2 Sales' , s1.OrderID
from Superstore_cleaned s1
join Superstore_cleaned s2
on s1.OrderID = s2.OrderID
where P1 <> P2
)

select *,count(*)
from product_pairs p
where p.OrderID in (select count(*) from product_pairs i where i.P1 = p.p1 and i.p2 = p.p2)