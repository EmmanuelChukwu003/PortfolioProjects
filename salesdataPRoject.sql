--Inspecting data
SELECT *
froM salesdata

--Inspecting unique values
SELECT DISTINCT status from salesdata
SELECT DISTINCT year_id from salesdata
SELECT DISTINCT PRODUCTLINE from salesdata
SELECT DISTINCT COUNTRY from salesdata
SELECT DISTINCT DEALSIZE from salesdata
SELECT DISTINCT TERRITORY from salesdata

--ANALYSIES
--grouping sales by product line

SELECT productline, sum(sales) as Revenue
FROM salesData
GROUP BY productline
ORDER BY 2 DESC

--grouping sales by year
SELECT year_id, sum(sales) as Revenue
FROM salesData
GROUP BY year_id
ORDER BY 2 DESC

--2005 has the lowes sales as they did not operate for the full year as  shown in this query

SELECT DISTINCT MONTH_ID from salesdata
WHERE year_id=2005

--Identifying what deal size created the most revenue
SELECT DEALSIZE, sum(sales) as Revenue
FROM SalesData
GROUP BY dealsize
ORDER BY 2 desc

--what was the best mothn for sales in a specific year? How much was earned in that month?

SELECT month_id, sum(sales) as Revenue, COUNT(ordernumber) AS Frequency
FROM SalesData
WHERE year_id=2003 --change to see other years
GROUP BY month_id
ORDER BY 2 DESC


--November seems to be the best moth, what product do they sell in that month? Classic I beleive

SELECT month_id, productline, sum(sales) as Revenue, COUNT(ordernumber) AS Frequency
FROM SalesData
WHERE year_id=2003 and MONTH_ID=11 --change to see other years
GROUP BY month_id, productline
ORDER BY 3 DESC

--WHO is our best customer? (using RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from SalesData) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from SalesData)) Recency
	from SalesData
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar)+ cast(rfm_frequency as varchar)+ cast(rfm_monetary as varchar)rfm_cell_string
	into #rfm
	FROM rfm_calc as c

	SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	

	CASE
		WHEN rfm_cell_strinG IN (111,112,121,122,123,132,211,212,114,141) THEN 'lost_customers' --lost customers
		WHEN rfm_cell_strinG IN (133,34,143,255,334,343,344,144) THEN 'slipping away, cannot lose' --(Big spenders who haven't purchased lately) slipping away
		when rfm_cell_string IN (311,411,331) THEN 'new customers'
		WHEN rfm_cell_string IN (222,223,233,322) THEN 'potential churners'
		WHEN rfm_cell_string IN (323,333, 321, 422, 332, 432) THEN 'active'
		WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
		ELSE 'inconclusive'

	END rfm_segment
	FROM #RFM

	--What products are most often sold together
	--	select * FROM SalesData WHERE ORDERNUMBER= 10411
SELECT DISTINCT Ordernumber, STUFF(

	(SELECT ',' + productcode
	FROM SalesData as p
	WHERE ORDERNUMBER IN 
	(
	SELECT ORDERNUMBER 
	FROM (
		SELECT ORDERNUMBER, COUNT(*) AS RN
		FROM SalesData
		where status= 'Shipped'
		GROUP BY ORDERNUMBER) as m

	WHERE rn=2) --this shows what 2 products were sold together, this number can be changed e.g.3

	and p.ORDERNUMBER=s.ORDERNUMBER

	FOR xml path (''))
	
	, 1,1,'') AS ProductCode
	
	FROM SalesData AS s
	order by 2 DESC