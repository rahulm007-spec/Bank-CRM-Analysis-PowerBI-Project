
-- ----------------------------------- OBJECTIVE QUESTIONS -------------------------------------
-- 1. What is the distribution of account balances across different regions? (Visual answer in DOC  ) 
-- ------------------------
-- 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year

-- Changing column name to Bank_DOJ
alter table customerinfo rename column `Bank DOJ` to Bank_DOJ ;

SELECT CustomerId, Surname, EstimatedSalary, 
STR_TO_DATE(Bank_DOJ, '%d-%m-%Y') AS Bank_DOJ
FROM customerinfo
WHERE QUARTER(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) = 4
ORDER BY EstimatedSalary DESC
LIMIT 5;

-- 3.	Calculate the average number of products used by customers who have a credit card;

select avg(NumofProducts) as Avg_numof_products
from bank_churn
where HasCrCard = 1;


-- Question 4. Determine the churn rate by gender for the most recent year in the dataset. (Answered with the help of Power BI measure)

-- 5.	Compare the average credit score of customers who have exited and those who remain;

select ec.ExitCategory, avg(bc.CreditScore) as Avg_Creditscore
from bank_churn bc
join exitcustomer ec on bc.exited=ec.exitId 
group by ec.ExitCategory;

-- 6.Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?

select GenderCategory,round(avg(EstimatedSalary),2) as Avg_estimated_sal, count(bc.CustomerId) as Active_Customers
from customerinfo ci
join gender g on ci.genderID=g.genderID
join bank_churn bc on bc.customerID=ci.customerID
join activecustomer ac on  bc.IsActiveMember=ac.ActiveID
where ActiveCategory='Active Member'
group by GenderCategory;


-- 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate;

With creditscoresegment as ( Select CustomerId, Exited,
    case when creditscore between 781 and 850 then 'Excellent'
        when creditscore between 701 and 780 then 'Very Good'
        when creditscore between 611 and 700 then 'Good'
        when creditscore between 510 and 610 then 'Fair' 
        else 'Poor'end as CreditScoreSegment
    from bank_churn)

select CreditScoreSegment,
    avg(case when Exited = 1 then 1 else 0 end) as Exit_Rate
from creditscoresegment
group by creditscoresegment
order by exit_rate desc
limit 1;

-- 8.Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.

select g.GeographyLocation, count(b.CustomerId) as Active_Customers
from geography g
join customerinfo c on g.geographyid = c.geographyid
join bank_churn b on c.customerid = b.customerid
where b.tenure > 5 and b.IsActiveMember=1
group by g.geographylocation
order by active_customers desc
limit 1;

-- 9. What is the impact of having a credit card on customer churn, based on the available data?

with CreditCardImpact as (Select b.HasCrCard,
count(Case when b.Exited = 1 then 1 end) as ChurnedCount,
count(*) as TotalCount,
ROUND((count(Case when b.Exited = 1 then 1 end) / count(*)) * 100, 2) as ChurnRatePercentage
from Bank_Churn b
group by b.HasCrCard)

Select Case when HasCrCard = 1 then 'Has Credit Card'
when HasCrCard = 0 then 'No Credit Card'
end as CreditCardStatus,ChurnedCount,TotalCount,ChurnRatePercentage
from CreditCardImpact;

-- Question 10. For customers who have exited, what is the most common number of products they had used?
Select NumOfProducts,COUNT(*) as ExitedCount
from Bank_Churn 
where Exited = 1
group by NumOfProducts
order by ExitedCount desc
Limit 1;

-- Question 11. Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.

SELECT  YEAR(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) AS Year, MONTH(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) AS Month,
COUNT(*) AS Customers_Joined
FROM customerinfo 
GROUP BY YEAR(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')), MONTH(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y'))
ORDER BY Year, Month;

-- 12.Analyze the relationship between the number of products and the account balance for customers who have exited.(DOC has the answer)
-- 13.Identify any potential outliers in terms of balance among customers who have remained with the bank.(DOC has the answer) 
-- 14.How many different tables are given in the dataset, out of these tables which table only consists of categorical variables?(DOC has the answer)

-- 15.	 Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
-- Also, rank the gender according to the average value;

select geo.GeographyLocation,  GenderCategory,round(avg(c.estimatedsalary),2) as Avg_salary,
rank() over (partition by GeographyLocation order by avg(c.EstimatedSalary) desc) as 'Rank'
from customerinfo c
join geography geo on c.geographyid = geo.geographyid
join gender gn on gn.genderid=c.genderid
group by geo.geographylocation, GenderCategory
order by geo.geographylocation;

-- 16.	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

Select case when age between 18 and 30 then 'Adults (18-30)'
	when age between 31 and 50 then 'Middle-aged (30-50)'
    else 'Old-aged (50+)' end as Age_brackets,
	avg(b.tenure) as Avg_tenure
from customerinfo c
join bank_churn b on c.customerid = b.customerid
where b.exited = 1
group by Age_brackets
order by Age_brackets;


-- 17. Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not?(Ans in DOC)
-- 18. Is there any correlation between the salary and the Credit score of customers?(Ans in DOC ) 
-- -------------------

-- 19.	Rank each bucket of credit score as per the number of customers who have churned the bank.

With Segments as (Select CreditScore,
Case when CreditScore between 300 and 579 then 'Poor'
when CreditScore between 580 and 669 then 'Fair'
when CreditScore between 670 and 739 then 'Good'
when CreditScore between 740 and 799 then 'VeryGood'
when CreditScore between 800 and 850 then 'Excellent'
end as CreditScoreSegment,Exited
from Bank_Churn),

ChurnedCustomers as (Select CreditScoreSegment,COUNT(*) AS ChurnedCount
from Segments
where Exited = 1 -- Only include churned customers
group by CreditScoreSegment)

Select CreditScoreSegment,ChurnedCount,
Rank() over (order by ChurnedCount desc) as 'Rank'
from ChurnedCustomers;


-- 20.According to the age buckets find the number of customers who have a credit card.Also retrieve those buckets that have lesser than average number of credit cards per bucket;

with creditinfo as (
select case when age between 18 and 30 then 'Adult (18-30)'
when age between 31 and 50 then 'Middle-aged (31-50)'
else 'Old-aged (50+)' end as agebrackets,
count(c.customerid) as CrCard_holders
from customerinfo c
join bank_churn b on c.customerid = b.customerid
where b.hascrcard = 1  
group by agebrackets)

select *
from creditinfo
where CrCard_holders < (Select avg(CrCard_holders) from creditinfo);

--  21.Rank the Locations as per the number of people who have churned the bank and average balance of the customers.

With Locations as (Select g.GeographyLocation,count(Case when bc.Exited = 1 then 1 end) as ChurnedCount,
avg(bc.Balance) as AvgBalance
from bank_churn bc
join customerinfo ci on bc.CustomerId = ci.CustomerId
join geography g on ci.GeographyID = g.GeographyID
group by g.GeographyLocation)

Select GeographyLocation,ChurnedCount,AvgBalance,
Rank() over (order by  ChurnedCount desc, AvgBalance desc) as 'Rank'
from Locations;

--  22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.

Select CONCAT(ci.CustomerID, '_', ci.Surname) AS CustomerID_Surname	
from CustomerInfo ci	
join bank_churn bc ON ci.CustomerID = bc.CustomerID;

-- 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

select customerid, creditscore, tenure, balance, numofproducts, hascrcard, isactivemember, exited,
    (select ExitCategory from exitcustomer ec where bc.exited = ec.exitID) as ExitCategory
from bank_churn bc;

-- 25.	Write the query to get the customer IDs, their last name, and whether they are active  or not for the customers whose surname ends with “on”;

Select c.CustomerId, c.Surname as Last_name,  
    case when b.isactivemember = 1 then 'active' 
    else 'inactive' end as active_status
from customerinfo c
join bank_churn b on c.customerid = b.customerid
where c.surname like '%on'
order by c.surname;

-- ---------------------------------

-- 26.	Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns.
-- One more point to consider is that the data in the Exited Column is absolutely correct and accurate.

select * from bank_churn b join customerinfo c on b.customerid = c.customerid
where b.exited =1 and b.isactivemember =1;

-- ----------------------------------------------------------- SUBJECTIVE QUESTIONS ------------------------------------------------------------------------------------------ 

-- Rest questions are answered in the DOC file using power bi for analysis and visualization:- 
-- -------------------------------------

-- 9.	Utilize SQL queries to segment customers based on demographics and account details.

Select GeographyLocation, 
    case when estimatedsalary < 50000 then 'Low'
        when estimatedsalary < 100000 then 'Medium'
        else 'High'end as Income_Segment,
		GenderCategory ,
    count(c.customerid) as NumberofCustomers
from customerinfo c
join geography g on c.geographyid = g.geographyid
join gender gn on c.genderid=gn.genderid
group by  geographylocation, Income_Segment, GenderCategory
order by geographylocation;

-- 10. How can we create a conditional formatting setup to visually highlight customers at risk of churn and 
-- to evaluate the impact of credit card rewards on customer retention?

SELECT CustomerID, Balance, Tenure, IsActiveMember			  
 FROM bank_churn								               
WHERE Balance < 1000 OR Tenure < 6 OR IsActiveMember = 0;

Select  HasCrCard, avg(Exited) as ChurnRate 
from bank_churn 
group by HasCrCard;

-- 14.	In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?

Alter Table bank_churn
Rename Column HasCrCard to Has_creditcard;
Select * from bank_churn;

## ======================================= END OF SUBJECTIVE QUESTIONS =======================================