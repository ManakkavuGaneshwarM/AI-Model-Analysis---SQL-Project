create database GenAItoolAnalysis;

use GenAItoolAnalysis;

-- Table to store information about different models
CREATE TABLE Models (
    ModelID INT PRIMARY KEY,
    ModelName VARCHAR(255) NOT NULL
);

-- Table to store information about various capabilities
CREATE TABLE Capabilities (
    CapabilityID INT PRIMARY KEY,
    CapabilityName VARCHAR(255) NOT NULL
);

-- Table to store benchmark scores for different models and capabilities
CREATE TABLE Benchmarks (
    BenchmarkID INT PRIMARY KEY,
    ModelID INT,
    CapabilityID INT,
    BenchmarkName VARCHAR(255) NOT NULL,
    ScoreGemini FLOAT,
    ScoreGPT4 FLOAT,
    Description TEXT,
    FOREIGN KEY (ModelID) REFERENCES Models(ModelID),
    FOREIGN KEY (CapabilityID) REFERENCES Capabilities(CapabilityID)
);

-- Insert data into the Models table
INSERT INTO Models (ModelID, ModelName) VALUES
(1, 'Gemini Ultra'),
(2, 'GPT-4');

-- Insert data into the Capabilities table
INSERT INTO Capabilities (CapabilityID, CapabilityName) VALUES
(1, 'General'),
(2, 'Reasoning'),
(3, 'Math'),
(4, 'Code'),
(5, 'Image'),
(6, 'Video'),
(7, 'Audio');

-- Insert data into the Benchmarks table
INSERT INTO Benchmarks (BenchmarkID, ModelID, CapabilityID, BenchmarkName, ScoreGemini, ScoreGPT4, Description) VALUES
(1, 1, 1, 'MMLU', 90.00, 86.40, 'Representation of questions in 57 subjects'),
(2, 2, 1, 'MMLU', 86.40, NULL, 'Representation of questions in 57 subjects'),
(3, 1, 2, 'Big-Bench Hard', 83.60, 83.10, 'Diverse set of challenging tasks requiring multi-step reasoning'),
(4, 2, 2, 'Big-Bench Hard', 83.10, NULL, 'Diverse set of challenging tasks requiring multi-step reasoning'),
(5, 1, 2, 'DROP', 82.4, 80.9, 'Reading comprehension (Fl Score)'),
(6, 2, 2, 'DROP', 80.9, NULL, 'Reading comprehension (Fl Score)'),
(7, 1, 2, 'HellaSwag', 87.80, 95.30, 'Commonsense reasoning for everyday tasks'),
(8, 2, 2, 'HellaSwag', 95.30, NULL, 'Commonsense reasoning for everyday tasks'),
(9, 1, 3, 'GSM8K', 94.40, 92.00, 'Basic arithmetic manipulations, incl. Grade School math problems'),
(10, 2, 3, 'GSM8K', 92.00, NULL, 'Basic arithmetic manipulations, incl. Grade School math problems'),
(11, 1, 3, 'MATH', 53.20, 52.90, 'Challenging math problems, incl. algebra, geometry, pre-calculus, and others'),
(12, 2, 3, 'MATH', 52.90, NULL, 'Challenging math problems, incl. algebra, geometry, pre-calculus, and others'),
(13, 1, 4, 'HumanEval', 74.40, 67.00, 'Python code generation'),
(14, 2, 4, 'HumanEval', 67.00, NULL, 'Python code generation'),
(15, 1, 4, 'Natura12Code', 74.90, 73.90, 'Python code generation. New held out dataset HumanEval-like, not leaked on the web'),
(16, 2, 4, 'Natura12Code', 73.90, NULL, 'Python code generation'),
(17, 1, 5, 'MIMMU', 59.40, 56.80, 'Multi-discipline college-level reasoning problems'),
(18, 2, 5, 'VQAv2', 77.80, 77.20, 'Natural image understanding'),
(19, 1, 5, 'TextVQA', 82.30, 78.00, 'OCR on natural images'),
(20, 2, 5, 'DocVQA', 90.90, 88.40, 'Document understanding'),
(21, 1, 5, 'Infographic VQA', 80.30, 75.10, 'Infographic understanding'),
(22, 2, 5, 'MathVista', 53.00, 49.90, 'Mathematical reasoning in visual contexts'),
(23, 1, 6, 'VATEX', 62.7, 56, 'English video captioning (CIDEr)'),
(24, 2, 6, 'Perception Test MCQA', 54.70, 46.30, 'Video question answering'),
(25, 1, 7, 'CoV0ST 2', 40.1, 29.1, 'Automatic speech translation (BLEU score)'),
(26, 2, 7, 'FLEURS', 7.60, 17.60, 'Automatic speech recognition (word error rate)')

-- // Replacing null values in the benchmarks table. 

update Benchmarks
set ScoreGPT4 = isnull(ScoreGPT4,
					  (select round(avg(ScoreGPT4), 1)
					  from Benchmarks));

select ScoreGPT4 from Benchmarks;

-- 1. What are the Average Scores for each Capability on both Gemini Model And GPT-4 Model ?

select 
	CapabilityID,
	Round(AVG(ScoreGemini), 1) as Avg_Score_Gemini,
	Round(AVG(ScoreGPT4), 1) as Avg_Score_GPT4
from Benchmarks
group by CapabilityID
order by CapabilityID asc;

-- 2. Which benchmark does the Gemini Ultra outperformed the GPT-4 in terms of scores ? 

select 
	BenchmarkName,
	ScoreGemini,
	case 
		when ScoreGemini > ScoreGPT4 then 'Outperformed'
		else 'underperformed' 
	end as Performance
from Benchmarks; 

-- 3. What are the highest scores acheived by Gemini Ultra and GPT-4 for each benchmark in the image category ?

select 
	Max(ScoreGemini) as highscore1,
	Max(ScoreGPT4) as highscore2
from Benchmarks
where BenchmarkID = 5; 

-- 4. Calculate the percentage improvement of Gemini Ultra over GPT-4 for each benchmark. 

select 
	round(((ScoreGemini - ScoreGPT4) / ScoreGPT4) * 100, 1) as percentage_improvement 
from Benchmarks;

-- 5. Retrieve the benchmarks where both models above the average for their respective models. 

select
	b.BenchmarkName,
	b.ScoreGemini
from Benchmarks b
inner join (
	select 
		BenchmarkName, 
		AVG(ScoreGemini) as avg_gemini_score
	from Benchmarks
	group by BenchmarkName
) as c on b.BenchmarkName = c.BenchmarkName
where b.ScoreGemini > c.avg_gemini_score;

-- 6. Which benchmark shows that Gemini Ultra is expected to outperform GPT-4 based on their next score ? 

Declare @Model1_id int = 1;
Declare @Model2_id int = 2;

with RankedScores as (
	select *,
		rank() over(partition by BenchmarkName order by ScoreGemini desc) as Score_rank
	from Benchmarks
)
select 
	b1.BenchmarkID as Model1_id,
	b1.BenchmarkName as BenchMark_Name,
	b1.ScoreGemini as Model1_Gemini_Score,
	b2.BenchmarkID as Model2_id,
	b2.BenchmarkName as BenchMark__Name,
	b2.ScoreGPT4 as Model1_GPT_Score
from RankedScores b1
join RankedScores b2 on b1.BenchmarkName = b2.BenchmarkName and b1.Score_rank = 1 and b2.Score_rank = 2
where b1.BenchmarkID = @Model1_id and b2.BenchmarkID = @Model2_id;

-- 7. Classification of Benchmarks into categories based on their performance scores. 

select 
	BenchmarkName,
	ScoreGemini,
	case
		when ScoreGemini >= 90 then 'High Performance'
		when ScoreGemini >= 70 and ScoreGemini < 90 then 'Average Performance'
		when ScoreGemini < 70 then 'Low Performance'
		else '---'
	end as Performance_Category
from Benchmarks
order by ScoreGemini desc;

-- 8. Retrieve the rankings for each capability based on Gemini Ultra scores. 

select 
	c.CapabilityName,
	b.BenchmarkName,
	b.ScoreGemini, 
	rank() over (partition by c.CapabilityID order by b.ScoreGemini desc) as Gemini_Ultra_Rankings
from Capabilities c
join Benchmarks b on c.CapabilityID = b.CapabilityID
where b.ModelID = 1
order by ScoreGemini desc;

-- 9. Convert the Capability Names and Benchmark Names to uppercase

select 
	upper(c.CapabilityName) as CAPABILITY_NAME,
	upper(b.BenchmarkName) as BENCHMARK_NAME
from Benchmarks b
join Capabilities c on b.CapabilityID = c.CapabilityID;

-- 10. Provide the Benchmarks along with their description in a concatenate format. 
-- changing the data type of Description column to concatenate 

alter table Benchmarks
alter column Description varchar(max);

select 
	BenchmarkName + ' - ' + Description as BenchmarkDetails
from Benchmarks;