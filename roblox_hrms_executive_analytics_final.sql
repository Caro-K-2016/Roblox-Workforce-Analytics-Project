
/*
ROBOX HRMS - WORKFORCE INTELLIGENCE & EXECUTIVE ANALYTICS

*/
-- SECTION 1: DATABASE SETUP
-- ----------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS roblox_hrms;
USE roblox_hrms;

-- Checks MySQL's approved directory for LOAD DATA INFILE operations.
SHOW VARIABLES LIKE 'secure_file_priv';

-- ----------------------------------------------------------------------------
-- SECTION 2: RESET TABLES FOR A CLEAN, REPRODUCIBLE BUILD
-- ----------------------------------------------------------------------------
-- Tables are dropped in reverse dependency order so foreign-key constraints
-- do not block the rebuild.

DROP TABLE IF EXISTS health;
DROP TABLE IF EXISTS employee_performance;
DROP TABLE IF EXISTS finance;
DROP TABLE IF EXISTS education;
DROP TABLE IF EXISTS department_performance;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS department;

-- ----------------------------------------------------------------------------
-- SECTION 3: DEPARTMENT DIMENSION
-- ----------------------------------------------------------------------------
-- Department is created first because employee and department_performance
-- depend on department_code.

CREATE TABLE department (
    department_code VARCHAR(20) PRIMARY KEY,
    department VARCHAR(100) NOT NULL
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/department.csv'
INTO TABLE department
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(department_code, department);

-- Basic validation: number of departments loaded.
SELECT COUNT(*) AS department_count
FROM department;

-- ----------------------------------------------------------------------------
-- SECTION 4: EMPLOYEE MASTER / CORE DIMENSION
-- ----------------------------------------------------------------------------
-- Employee is the central entity. Supporting employee-level tables reference
-- employee_id, therefore this table must exist before them.

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    other_names VARCHAR(100),
    last_name VARCHAR(50),
    age INT NULL,
    position VARCHAR(50),
    date_joined DATE,
    phone_number VARCHAR(20),
    gender VARCHAR(10),
    employee_status VARCHAR(20),
    department_code VARCHAR(20),
    email_address VARCHAR(150),

    CONSTRAINT FK_employee_department
        FOREIGN KEY (department_code)
        REFERENCES department(department_code)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employee.csv'
INTO TABLE employee
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    employee_id,
    other_names,
    last_name,
    @age,
    position,
    date_joined,
    phone_number,
    gender,
    employee_status,
    department_code,
    email_address
)
SET age = NULLIF(@age, '');

-- Validation checks for the employee master.
SELECT COUNT(*) AS employee_count
FROM employee;

SELECT COUNT(*) AS employees_missing_age
FROM employee
WHERE age IS NULL;

-- ----------------------------------------------------------------------------
-- SECTION 5: DEPARTMENT PERFORMANCE
-- ----------------------------------------------------------------------------
-- Department performance is time-based. The composite key allows the same
-- department to appear in multiple years while preventing duplicate
-- department-year records.

CREATE TABLE department_performance (
    department_id INT NOT NULL,
    department VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    year YEAR NOT NULL,
    average_performance_score DECIMAL(4,2),
    total_revenue_generated DECIMAL(18,2),
    total_cost DECIMAL(18,2),
    training_hours_completed INT,

    CONSTRAINT PK_department_performance
        PRIMARY KEY (department_id, year),

    CONSTRAINT FK_department_performance_department
        FOREIGN KEY (department_code)
        REFERENCES department(department_code)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/department_performance.csv'
INTO TABLE department_performance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    department_id,
    department,
    department_code,
    year,
    average_performance_score,
    total_revenue_generated,
    total_cost,
    training_hours_completed
);

SELECT COUNT(*) AS department_performance_rows
FROM department_performance;

-- ----------------------------------------------------------------------------
-- SECTION 6: EDUCATION
-- ----------------------------------------------------------------------------
-- One employee may have more than one education record. Therefore, education
-- is deliberately kept at education-record grain rather than employee grain.

CREATE TABLE education (
    education_record_id INT PRIMARY KEY,
    employee_id INT,
    institution_country VARCHAR(50),
    education_level VARCHAR(30),
    institution_name VARCHAR(150),
    degree_title VARCHAR(100),
    field_of_study VARCHAR(100),
    graduation_date DATE,

    CONSTRAINT FK_education_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/education.csv'
INTO TABLE education
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    education_record_id,
    employee_id,
    institution_country,
    education_level,
    institution_name,
    degree_title,
    field_of_study,
    graduation_date
);

SELECT COUNT(*) AS education_records
FROM education;

-- ----------------------------------------------------------------------------
-- SECTION 7: FINANCE
-- ----------------------------------------------------------------------------
-- Finance stores compensation at employee/staff level. Account numbers and
-- tax IDs remain text because identifiers can contain leading zeroes.

CREATE TABLE finance (
    finance_id VARCHAR(20) PRIMARY KEY,
    basic_salary DECIMAL(10,2),
    tax_id VARCHAR(30),
    account_number VARCHAR(30),
    staff_id INT,
    allowances DECIMAL(10,2),
    bank_name VARCHAR(100),

    CONSTRAINT FK_finance_employee
        FOREIGN KEY (staff_id)
        REFERENCES employee(employee_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/finance_dataset.csv'
INTO TABLE finance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    finance_id,
    basic_salary,
    tax_id,
    account_number,
    staff_id,
    allowances,
    bank_name
);

SELECT COUNT(*) AS finance_records
FROM finance;

SELECT
    SUM(COALESCE(basic_salary, 0)) AS total_basic_salary,
    SUM(COALESCE(allowances, 0)) AS total_allowances,
    SUM(COALESCE(basic_salary, 0) + COALESCE(allowances, 0)) AS total_compensation
FROM finance;

-- ----------------------------------------------------------------------------
-- SECTION 8: EMPLOYEE PERFORMANCE
-- ----------------------------------------------------------------------------
-- Composite key: employee + year. This preserves annual performance history.

CREATE TABLE employee_performance (
    employee_id INT NOT NULL,
    year YEAR NOT NULL,
    performance_score DECIMAL(3,2),
    projects_completed INT,
    training_hours INT,
    attendance_rate DECIMAL(5,2),
    bonus_awarded VARCHAR(5),

    CONSTRAINT PK_employee_performance
        PRIMARY KEY (employee_id, year),

    CONSTRAINT FK_employee_performance_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employee_performance.csv'
INTO TABLE employee_performance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    employee_id,
    year,
    performance_score,
    projects_completed,
    training_hours,
    attendance_rate,
    bonus_awarded
);

SELECT COUNT(*) AS employee_performance_rows
FROM employee_performance;

-- ----------------------------------------------------------------------------
-- SECTION 9: HEALTH / EMPLOYEE WELLBEING
-- ----------------------------------------------------------------------------
-- Health data is used for operational wellbeing/risk analysis, not medical
-- diagnosis. The project specifically frames this dataset as operational risk.

CREATE TABLE health (
    health_id VARCHAR(20) PRIMARY KEY,
    employee_id INT,
    created_at DATETIME,
    updated_at DATETIME,
    medical_leave_eligible VARCHAR(5),
    insurance_status VARCHAR(20),
    insurance_provider VARCHAR(100),
    policy_number VARCHAR(20),
    insurance_plan_type VARCHAR(20),
    medical_leave_balance INT,

    CONSTRAINT FK_health_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/health_dataset.csv'
INTO TABLE health
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    health_id,
    employee_id,
    created_at,
    updated_at,
    medical_leave_eligible,
    insurance_status,
    insurance_provider,
    policy_number,
    insurance_plan_type,
    medical_leave_balance
);

SELECT COUNT(*) AS health_records
FROM health;

-- ----------------------------------------------------------------------------
-- SECTION 10: DATA QUALITY & REFERENTIAL-INTEGRITY CHECKS
-- ----------------------------------------------------------------------------
-- These checks are important before executive reporting because incorrect
-- joins can inflate headcount, compensation and performance metrics.

-- 10.1 Employees without a valid department.
SELECT COUNT(*) AS employees_without_department
FROM employee e
LEFT JOIN department d
    ON e.department_code = d.department_code
WHERE d.department_code IS NULL;

-- 10.2 Employees without education records.
SELECT COUNT(*) AS employees_without_education
FROM employee e
LEFT JOIN education ed
    ON e.employee_id = ed.employee_id
WHERE ed.employee_id IS NULL;

-- 10.3 Employees without finance records.
SELECT COUNT(*) AS employees_without_finance
FROM employee e
LEFT JOIN finance f
    ON e.employee_id = f.staff_id
WHERE f.staff_id IS NULL;

-- 10.4 Employees without health records.
SELECT COUNT(*) AS employees_without_health
FROM employee e
LEFT JOIN health h
    ON e.employee_id = h.employee_id
WHERE h.employee_id IS NULL;

-- 10.5 Performance records without a matching employee.
SELECT COUNT(*) AS orphan_employee_performance
FROM employee_performance ep
LEFT JOIN employee e
    ON ep.employee_id = e.employee_id
WHERE e.employee_id IS NULL;

-- 10.6 Department-performance records without a matching department.
SELECT COUNT(*) AS orphan_department_performance
FROM department_performance dp
LEFT JOIN department d
    ON dp.department_code = d.department_code
WHERE d.department_code IS NULL;

-- ----------------------------------------------------------------------------
-- SECTION 11: BASIC JOIN VALIDATION
-- ----------------------------------------------------------------------------
-- This is a technical smoke test, not an executive output. It confirms that
-- the main employee-level relationships are functioning.

SELECT
    e.employee_id,
    e.other_names,
    e.last_name,
    d.department,
    f.basic_salary,
    f.allowances,
    h.insurance_status
FROM employee e
LEFT JOIN department d
    ON e.department_code = d.department_code
LEFT JOIN finance f
    ON e.employee_id = f.staff_id
LEFT JOIN health h
    ON e.employee_id = h.employee_id
LIMIT 10;

-- ----------------------------------------------------------------------------
-- SECTION 12: EXECUTIVE ANALYTICS
-- ----------------------------------------------------------------------------
-- The queries below are the analytical layer intended for stakeholder
-- reporting. Each query is designed around a business question rather than
-- simply demonstrating SQL syntax.
--
-- IMPORTANT GRAIN RULE:
-- Employee performance is annual and education can contain multiple records.
-- Therefore, we aggregate each one before joining to employee-level facts.
-- This prevents row multiplication and protects executive KPIs.
-- ----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- QUERY 1: EXECUTIVE WORKFORCE, COST & WELLBEING OVERVIEW
-- Business question:
--   What does the workforce look like by department, and what is the related
--   compensation and wellbeing exposure?
--
-- Techniques demonstrated:
--   Multiple JOINs + conditional aggregation + subquery.
-- -----------------------------------------------------------------------------

SELECT
    d.department_code,
    d.department,
    COUNT(DISTINCT e.employee_id) AS headcount,
    COUNT(DISTINCT CASE
        WHEN e.employee_status = 'Active' THEN e.employee_id
    END) AS active_employees,
    ROUND(AVG(f.basic_salary), 2) AS avg_basic_salary,
    ROUND(SUM(COALESCE(f.basic_salary, 0)), 2) AS total_basic_salary,
    ROUND(SUM(COALESCE(f.allowances, 0)), 2) AS total_allowances,
    ROUND(SUM(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0)), 2)
        AS total_compensation,
    COUNT(DISTINCT CASE
        WHEN h.insurance_status IS NULL
             OR LOWER(h.insurance_status) NOT IN ('active', 'valid')
        THEN e.employee_id
    END) AS wellbeing_or_insurance_risk_count,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN h.insurance_status IS NULL
                 OR LOWER(h.insurance_status) NOT IN ('active', 'valid')
            THEN e.employee_id
        END)
        / NULLIF(COUNT(DISTINCT e.employee_id), 0),
        2
    ) AS wellbeing_or_insurance_risk_pct
FROM department d
LEFT JOIN employee e
    ON d.department_code = e.department_code
LEFT JOIN finance f
    ON e.employee_id = f.staff_id
LEFT JOIN health h
    ON e.employee_id = h.employee_id
GROUP BY
    d.department_code,
    d.department
ORDER BY total_compensation DESC;


-- -----------------------------------------------------------------------------
-- QUERY 2: DEPARTMENT PERFORMANCE & FINANCIAL EFFICIENCY
-- Business question:
--   Which departments convert workforce investment into stronger performance
--   and financial output?
--
-- Techniques demonstrated:
--   Multiple JOINs + subqueries + aggregate functions.
-- -----------------------------------------------------------------------------

SELECT
    dp.year,
    d.department_code,
    d.department,
    dp.average_performance_score,
    dp.total_revenue_generated,
    dp.total_cost,
    ROUND(
        dp.total_revenue_generated / NULLIF(dp.total_cost, 0),
        2
    ) AS revenue_to_cost_ratio,
    dp.training_hours_completed,
    COALESCE(w.headcount, 0) AS headcount,
    ROUND(COALESCE(w.total_compensation, 0), 2) AS total_compensation,
    ROUND(
        dp.total_revenue_generated
        / NULLIF(w.headcount, 0),
        2
    ) AS revenue_per_employee,
    ROUND(
        dp.total_cost
        / NULLIF(w.headcount, 0),
        2
    ) AS cost_per_employee
FROM department_performance dp
INNER JOIN department d
    ON dp.department_code = d.department_code
LEFT JOIN (
    SELECT
        e.department_code,
        COUNT(DISTINCT e.employee_id) AS headcount,
        SUM(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0))
            AS total_compensation
    FROM employee e
    LEFT JOIN finance f
        ON e.employee_id = f.staff_id
    GROUP BY e.department_code
) AS w
    ON dp.department_code = w.department_code
ORDER BY
    dp.year DESC,
    revenue_to_cost_ratio DESC;


-- -----------------------------------------------------------------------------
-- QUERY 3: EDUCATION, JOB PLACEMENT & COMPENSATION
-- Business question:
--   How does employees' education background relate to where they are placed
--   and the compensation attached to those roles?
--
-- Important analytical design:
--   Education can have multiple rows per employee. The subquery first reduces
--   education to one analytical record per employee before joining to finance.
-- -----------------------------------------------------------------------------

SELECT
    d.department,
    e.position,
    ed.education_level,
    ed.field_of_study,
    COUNT(DISTINCT e.employee_id) AS employees,
    ROUND(AVG(f.basic_salary), 2) AS avg_basic_salary,
    ROUND(AVG(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0)), 2)
        AS avg_total_compensation
FROM employee e
INNER JOIN department d
    ON e.department_code = d.department_code
LEFT JOIN (
    SELECT
        education.employee_id,
        education_level,
        field_of_study
    FROM education
    INNER JOIN (
        SELECT
            employee_id,
            MAX(graduation_date) AS latest_graduation_date
        FROM education
        GROUP BY employee_id
    ) latest
        ON education.employee_id = latest.employee_id
       AND education.graduation_date = latest.latest_graduation_date
) AS ed
    ON e.employee_id = ed.employee_id
LEFT JOIN finance f
    ON e.employee_id = f.staff_id
GROUP BY
    d.department,
    e.position,
    ed.education_level,
    ed.field_of_study
ORDER BY
    employees DESC,
    avg_total_compensation DESC;


-- -----------------------------------------------------------------------------
-- QUERY 4: EMPLOYEE COST VS PRODUCTIVITY
-- Business question:
--   Which employees or employee groups combine compensation investment with
--   measurable productivity?
--
-- Techniques demonstrated:
--   Multiple JOINs + annual-performance subquery + aggregates + CASE logic.
-- -----------------------------------------------------------------------------

SELECT
    e.employee_id,
    CONCAT_WS(' ', e.other_names, e.last_name) AS employee_name,
    d.department,
    e.position,
    ROUND(COALESCE(f.basic_salary, 0), 2) AS basic_salary,
    ROUND(COALESCE(f.allowances, 0), 2) AS allowances,
    ROUND(
        COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0),
        2
    ) AS total_compensation,
    ROUND(ep.avg_performance_score, 2) AS avg_performance_score,
    ep.total_projects_completed,
    ROUND(ep.avg_training_hours, 2) AS avg_training_hours,
    ROUND(ep.avg_attendance_rate, 2) AS avg_attendance_rate,
    CASE
        WHEN ep.avg_performance_score >= 0.80
             AND ep.avg_attendance_rate >= 90
            THEN 'High productivity / strong attendance'
        WHEN ep.avg_performance_score < 0.60
             AND ep.avg_attendance_rate < 80
            THEN 'Performance attention required'
        ELSE 'Monitor'
    END AS productivity_segment
FROM employee e
LEFT JOIN department d
    ON e.department_code = d.department_code
LEFT JOIN finance f
    ON e.employee_id = f.staff_id
LEFT JOIN (
    SELECT
        employee_id,
        AVG(performance_score) AS avg_performance_score,
        SUM(COALESCE(projects_completed, 0)) AS total_projects_completed,
        AVG(COALESCE(training_hours, 0)) AS avg_training_hours,
        AVG(attendance_rate) AS avg_attendance_rate
    FROM employee_performance
    GROUP BY employee_id
) AS ep
    ON e.employee_id = ep.employee_id
ORDER BY
    avg_performance_score DESC,
    total_compensation DESC;


-- -----------------------------------------------------------------------------
-- QUERY 5: WORKFORCE RISK & COST EXPOSURE
-- Business question:
--   Where are employee wellbeing risks concentrated, and what compensation
--   exposure is associated with those employees?
-- -----------------------------------------------------------------------------

SELECT
    d.department,
    COUNT(DISTINCT e.employee_id) AS employees,
    COUNT(DISTINCT CASE
        WHEN h.insurance_status IS NULL
             OR LOWER(h.insurance_status) NOT IN ('active', 'valid')
        THEN e.employee_id
    END) AS employees_with_insurance_risk,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN h.insurance_status IS NULL
                 OR LOWER(h.insurance_status) NOT IN ('active', 'valid')
            THEN e.employee_id
        END)
        / NULLIF(COUNT(DISTINCT e.employee_id), 0),
        2
    ) AS insurance_risk_pct,
    ROUND(
        SUM(
            CASE
                WHEN h.insurance_status IS NULL
                     OR LOWER(h.insurance_status) NOT IN ('active', 'valid')
                THEN COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0)
                ELSE 0
            END
        ),
        2
    ) AS compensation_exposed_to_risk,
    ROUND(AVG(h.medical_leave_balance), 2) AS avg_medical_leave_balance
FROM employee e
INNER JOIN department d
    ON e.department_code = d.department_code
LEFT JOIN health h
    ON e.employee_id = h.employee_id
LEFT JOIN finance f
    ON e.employee_id = f.staff_id
GROUP BY d.department
ORDER BY
    compensation_exposed_to_risk DESC,
    insurance_risk_pct DESC;


-- -----------------------------------------------------------------------------
-- QUERY 6: EXECUTIVE DEPARTMENT SCORECARD
-- Business question:
--   What single scorecard can leadership use to compare departments across
--   workforce scale, cost, performance, productivity and risk?
--
-- This is the strongest candidate for a Power BI executive summary dataset.
-- It combines all major business domains while maintaining department grain.
-- -----------------------------------------------------------------------------

SELECT
    d.department_code,
    d.department,
    COALESCE(w.headcount, 0) AS headcount,
    COALESCE(w.active_employees, 0) AS active_employees,
    ROUND(COALESCE(w.total_compensation, 0), 2) AS total_compensation,
    ROUND(COALESCE(w.avg_compensation, 0), 2) AS avg_compensation,
    ROUND(COALESCE(p.avg_performance_score, 0), 2) AS avg_department_performance,
    COALESCE(p.total_projects_completed, 0) AS total_projects_completed,
    ROUND(COALESCE(p.avg_attendance_rate, 0), 2) AS avg_attendance_rate,
    COALESCE(dp.total_revenue_generated, 0) AS total_revenue_generated,
    COALESCE(dp.total_cost, 0) AS total_department_cost,
    ROUND(
        COALESCE(dp.total_revenue_generated, 0)
        / NULLIF(dp.total_cost, 0),
        2
    ) AS revenue_to_cost_ratio,
    COALESCE(dp.training_hours_completed, 0)
        AS department_training_hours,
    COALESCE(r.risk_employee_count, 0) AS risk_employee_count,
    ROUND(
        100.0 * COALESCE(r.risk_employee_count, 0)
        / NULLIF(w.headcount, 0),
        2
    ) AS risk_employee_pct
FROM department d

-- Workforce and finance subquery: one row per department.
LEFT JOIN (
    SELECT
        e.department_code,
        COUNT(DISTINCT e.employee_id) AS headcount,
        COUNT(DISTINCT CASE
            WHEN e.employee_status = 'Active' THEN e.employee_id
        END) AS active_employees,
        SUM(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0))
            AS total_compensation,
        AVG(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0))
            AS avg_compensation
    FROM employee e
    LEFT JOIN finance f
        ON e.employee_id = f.staff_id
    GROUP BY e.department_code
) AS w
    ON d.department_code = w.department_code

-- Employee performance subquery: one row per department.
LEFT JOIN (
    SELECT
        e.department_code,
        AVG(ep.performance_score) AS avg_performance_score,
        SUM(COALESCE(ep.projects_completed, 0)) AS total_projects_completed,
        AVG(ep.attendance_rate) AS avg_attendance_rate
    FROM employee e
    INNER JOIN employee_performance ep
        ON e.employee_id = ep.employee_id
    GROUP BY e.department_code
) AS p
    ON d.department_code = p.department_code

-- Department-level financial/performance dataset. The latest available year
-- is selected so the scorecard does not duplicate departments across years.
LEFT JOIN (
    SELECT
        dp.department_code,
        dp.total_revenue_generated,
        dp.total_cost,
        dp.training_hours_completed
    FROM department_performance dp
    INNER JOIN (
        SELECT
            department_code,
            MAX(year) AS latest_year
        FROM department_performance
        GROUP BY department_code
    ) latest
        ON dp.department_code = latest.department_code
       AND dp.year = latest.latest_year
) AS dp
    ON d.department_code = dp.department_code

-- Risk subquery: one row per department.
LEFT JOIN (
    SELECT
        e.department_code,
        COUNT(DISTINCT e.employee_id) AS risk_employee_count
    FROM employee e
    LEFT JOIN health h
        ON e.employee_id = h.employee_id
    WHERE h.insurance_status IS NULL
       OR LOWER(h.insurance_status) NOT IN ('active', 'valid')
    GROUP BY e.department_code
) AS r
    ON d.department_code = r.department_code

ORDER BY
    total_department_cost DESC,
    risk_employee_pct DESC;


-- -----------------------------------------------------------------------------
-- QUERY 7: EXECUTIVE OUTLIER ANALYSIS
-- Business question:
--   Which departments have compensation above the organisation average while
--   performance is below the organisation average?
--
-- This query demonstrates nested aggregate subqueries and turns raw metrics
-- into a management attention flag.
-- -----------------------------------------------------------------------------

SELECT
    d.department,
    ROUND(w.avg_compensation, 2) AS avg_department_compensation,
    ROUND(p.avg_performance_score, 2) AS avg_department_performance,
    ROUND(org.avg_compensation, 2) AS organisation_avg_compensation,
    ROUND(org.avg_performance, 2) AS organisation_avg_performance,
    CASE
        WHEN w.avg_compensation > org.avg_compensation
             AND p.avg_performance_score < org.avg_performance
            THEN 'Priority review: high cost / lower performance'
        WHEN w.avg_compensation > org.avg_compensation
            THEN 'Higher compensation exposure'
        WHEN p.avg_performance_score < org.avg_performance
            THEN 'Performance improvement opportunity'
        ELSE 'Within benchmark'
    END AS executive_attention_flag
FROM department d
INNER JOIN (
    SELECT
        e.department_code,
        AVG(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0))
            AS avg_compensation
    FROM employee e
    LEFT JOIN finance f
        ON e.employee_id = f.staff_id
    GROUP BY e.department_code
) AS w
    ON d.department_code = w.department_code
INNER JOIN (
    SELECT
        e.department_code,
        AVG(ep.performance_score) AS avg_performance_score
    FROM employee e
    INNER JOIN employee_performance ep
        ON e.employee_id = ep.employee_id
    GROUP BY e.department_code
) AS p
    ON d.department_code = p.department_code
CROSS JOIN (
    SELECT
        AVG(avg_compensation) AS avg_compensation,
        AVG(avg_performance) AS avg_performance
    FROM (
        SELECT
            e.department_code,
            AVG(COALESCE(f.basic_salary, 0) + COALESCE(f.allowances, 0))
                AS avg_compensation,
            AVG(ep.performance_score) AS avg_performance
        FROM employee e
        LEFT JOIN finance f
            ON e.employee_id = f.staff_id
        LEFT JOIN employee_performance ep
            ON e.employee_id = ep.employee_id
        GROUP BY e.department_code
    ) department_metrics
) AS org
ORDER BY
    CASE
        WHEN w.avg_compensation > org.avg_compensation
             AND p.avg_performance_score < org.avg_performance
            THEN 1
        WHEN p.avg_performance_score < org.avg_performance
            THEN 2
        WHEN w.avg_compensation > org.avg_compensation
            THEN 3
        ELSE 4
    END,
    w.avg_compensation DESC;
/*
----------------------------------------------------------------------------
END OF EXECUTIVE ANALYTICS LAYER
----------------------------------------------------------------------------
Recommended Power BI datasets:
  Query 1 -> Workforce / wellbeing overview
  Query 2 -> Department efficiency
  Query 3 -> Education / placement / compensation
  Query 5 -> Workforce risk
  Query 6 -> Executive department scorecard
  Query 7 -> Executive attention / outlier analysis

These outputs are deliberately aggregated at their reporting grain to avoid
double-counting employees when one-to-many tables such as education or
annual employee_performance are involved.
----------------------------------------------------------------------------
*/
