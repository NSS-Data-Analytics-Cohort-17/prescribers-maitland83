--1)a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. 

SELECT total_claim_count, npi
FROM prescription
ORDER BY total_claim_count DESC;

--  b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT total_claim_count, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
FROM prescription
	INNER JOIN prescriber USING (npi)
ORDER BY total_claim_count DESC;

--2)a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription
	LEFT JOIN prescriber USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

--  b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM drug
	INNER JOIN prescription USING (drug_name)
	INNER JOIN prescriber USING (npi)
WHERE opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;


--  c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
	---Answer:15
SELECT specialty_description
FROM prescriber
	LEFT JOIN prescription USING (npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL;


--  d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that
	---specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT specialty_description, 
	SUM(CASE
		WHEN opioid_drug_flag LIKE 'Y' THEN total_claim_count
		ELSE 0
	END) AS opioid_claims,
	SUM(total_claim_count) AS total_claims,
	ROUND(
        100.0 * SUM(CASE 
		WHEN opioid_drug_flag LIKE 'Y' THEN total_claim_count
		ELSE 0
	END) / SUM(total_claim_count),
	2) AS opioid_percentage
FROM prescription
	 JOIN prescriber USING (npi)
	 JOIN drug USING (drug_name)
GROUP BY specialty_description
ORDER BY opioid_percentage DESC;


	
	GROUP BY specialty_description
ORDER BY total_claims DESC;

(SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription
	 JOIN prescriber USING (npi))
GROUP BY specialty_description
ORDER BY total_claims DESC;




--3)a. Which drug (generic_name) had the highest total drug cost? PIRFENIDONE

SELECT generic_name, total_drug_cost
FROM drug
	INNER JOIN prescription USING (drug_name)
ORDER BY total_drug_cost DESC;

--  b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::MONEY AS cost_per_day
FROM drug
	INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

--4)a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have 
	---opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
	---Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
	
SELECT drug_name, opioid_drug_flag,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither'
	END AS drug_type
FROM drug
ORDER BY drug_type;	

--  b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
	---Hint: Format the total costs as MONEY for easier comparision.

	SELECT SUM(total_drug_cost)::MONEY AS total_cost,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither'
	END AS drug_type
FROM drug
	INNER JOIN prescription USING (drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;


--5)a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT (cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--  b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population. 
	--Largest:  Nashville-Davidson--Murfreesboro--Franklin, TN 1830410
	--Smallest: Morristown, TN	116352

SELECT cbsaname, SUM(population) AS pop
FROM cbsa
	INNER JOIN population USING (fipscounty)
GROUP BY cbsaname
ORDER BY pop DESC;

--  c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population
FROM population
	LEFT JOIN cbsa USING (fipscounty)
	LEFT JOIN fips_county USING (fipscounty)
WHERE cbsaname IS NULL
ORDER BY population DESC
LIMIT 1;

--6)a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
	---OXYCODONE HCL, 4538

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

--  b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
	INNER JOIN drug USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;

--  c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_last_org_name,nppes_provider_first_name,drug_name, total_claim_count, opioid_drug_flag
FROM prescription
	INNER JOIN drug USING (drug_name)
	RIGHT JOIN prescriber USING (npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;


--7)The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they
	--had for each opioid. Hint: The results from all 3 parts will have 637 rows	
--  a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management)
	---in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
	---Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need
	---the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
	CROSS JOIN drug
WHERE specialty_description LIKE 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';
	
--  b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had
	---any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi AS npi, drug.drug_name AS drug_name, SUM(total_claim_count) AS total_claims
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING(drug_name)
WHERE specialty_description LIKE 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name;



--  c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
	---Hint -Google the COALESCE function.

SELECT prescriber.npi AS npi, drug.drug_name AS drug_name, COALESCE(SUM(total_claim_count), 0) AS total_claims
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription USING(drug_name)
WHERE specialty_description LIKE 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name;	



              --READ ME 2 BONUS--
--1)How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT
FROM

--2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a
--    single query to answer this question.
--3)Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
-- a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
-- b. Now, report the same for Memphis.
-- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
--4)Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
--5)a. Write a query that finds the total population of Tennessee.
-- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.			