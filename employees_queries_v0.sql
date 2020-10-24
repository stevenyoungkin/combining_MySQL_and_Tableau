-- #### Combining MySQL and Tableau Tasks ###

USE employees_mod;

/* Task 1: Create a visualization that provides a breakdown between the male and female employees working in the company
 each year, starting from 1990. */
 
SELECT 
    YEAR(de.from_date) AS calender_year,
    e.gender,
    COUNT(DISTINCT e.emp_no) AS num_of_employees
FROM
    t_dept_emp AS de
        INNER JOIN
    t_employees AS e ON e.emp_no = de.emp_no
GROUP BY YEAR(de.from_date) , e.gender
HAVING calender_year >= 1990;

-- --------------------------------------------------------------------------

/* Task 2: Compare the number of male managers to the number of female managers from different departments for each year, 
starting from 1990. */

WITH calender_year AS (
	SELECT DISTINCT year(hire_Date) AS calender_year 
    FROM t_employees
	ORDER BY calender_year
)
, emp_manager AS (
SELECT 
    e.gender,
    dm.dept_no,
    dm.emp_no,
    YEAR(dm.from_date) AS from_year,
    YEAR(dm.to_date) AS to_year
FROM
    t_employees AS e
        INNER JOIN
    t_dept_manager AS dm ON dm.emp_no = e.emp_no
)
, manager_active_year AS (
SELECT 
    d.dept_name,
    em.gender,
    em.emp_no,
    em.from_year,
    em.to_year,
    cy.calender_year,
    CASE
        WHEN cy.calender_year BETWEEN from_year AND to_year THEN 1
        ELSE 0
    END AS active_man
FROM
    emp_manager AS em
        JOIN
    t_departments AS d ON d.dept_no = em.dept_no
        CROSS JOIN
    calender_year AS cy
ORDER BY em.emp_no , calender_year
)
SELECT 
    may.dept_name,
    may.gender,
    may.calender_year,
    COUNT(may.active_man) AS num_of_managers
FROM
    manager_active_year AS may
WHERE
    may.active_man = 1
GROUP BY may.dept_name , may.gender , may.calender_year
ORDER BY may.dept_name , may.calender_year , may.gender;

/* Discussion: My solution is a bit different than in the course. I use WITH clauses here to go ahead and determine the distinct calender years, 
which employees are managers (and their gender), and which years they are active. The last SELECT aggregates the active managers and groups them by department, 
gender, and the corresponding calender year. In the course, they skip this last part because Tableau will do the aggregation itself once you place the pill 
inside the rows. 
Note: in the solution video, the teacher actually demonstrates that Tableau will show the number of managers per gender for whatever year you hover 
over (in this case 1996). The numbers were the same as what I have, so I'm confident that my solution works.
*/

-- --------------------------------------------------------------------------

/* Task 3: Compare the average salary of female versus male employees in the entire company until year 2002, and add a filter allowing you to see 
that per each department.
*/

SELECT 
    e.gender,
    d.dept_name,
    ROUND(AVG(s.salary), 2) AS avg_salary,
    YEAR(de.from_date) AS calender_year
FROM
    t_employees AS e
        JOIN
    t_dept_emp AS de ON e.emp_no = de.emp_no
        JOIN
    t_departments AS d ON de.dept_no = d.dept_no
        JOIN
    t_salaries AS s ON s.emp_no = e.emp_no
GROUP BY d.dept_no , e.gender , calender_year
HAVING calender_year <= 2002
ORDER BY d.dept_no;

/* Note: when using a measure in the "Rows" section in Tableau, one must always aggregate the data in a certain way. Additionally, the average salary for 
all departments is computed in Tableau for this exercise.
*/

-- --------------------------------------------------------------------------

/* Task 4: Create an SQL stored procedure that will allow you to obtain the average male and female salary per department within a certain salary range. 
Let this range be defined by two values the user can insert when calling the procedure. Finally, visualize the obtained result-set in Tableau as a double bar chart.  
*/

DROP PROCEDURE IF EXISTS avg_sal_dept;
DELIMITER $$
CREATE PROCEDURE avg_sal_dept(IN p_salary_min FLOAT, IN p_salary_max FLOAT)
BEGIN
	SELECT 
    e.gender, ROUND(AVG(s.salary), 2) AS avg_salary, d.dept_name
FROM
    t_employees AS e
        JOIN
    t_salaries AS s ON e.emp_no = s.emp_no
        JOIN
    t_dept_emp AS de ON de.emp_no = e.emp_no
        JOIN
    t_departments AS d ON d.dept_no = de.dept_no
WHERE
    s.salary BETWEEN p_salary_min AND p_salary_max
GROUP BY d.dept_no , e.gender
ORDER BY d.dept_name;
END$$
DELIMITER ;
CALL employees_mod.avg_sal_dept(50000.00,90000.00);

/* Note: in Tableau, a legend can be applied to a worksheet only, while a filter can be applied to a worksheet and a dashboard.
*/
-- --------------------------------------------------------------------------

