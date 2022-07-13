----------------------------------------------------
-- Finding the total number of parts made per theme.
----------------------------------------------------

/*
 Create View dbo.analytics_main as
 Select 
	s.set_num, 
	s.name as set_name, 
	s.year, 
	s.theme_id, 
	cast(s.num_parts as numeric) num_parts, 
	t.name as theme_name, 
	t.parent_id, 
	p.name as parent_theme_name
 From dbo.sets s
 Left Join dbo.themes t
		on s.theme_id = t.id
 Left Join dbo.themes p
		on t.parent_id = p.id
*/

Select * From dbo.analytics_main

Select 
	theme_name as Title, 
	SUM(num_parts) as TotalParts
From dbo.analytics_main
--where parent_theme_name is not null
Group by theme_name
Order by 2 desc



---------------------------------------------------
-- Finding the total number of parts made per year.
---------------------------------------------------

Select 
	Year, 
	SUM(num_parts) as TotalParts
From dbo.analytics_main
--Where parent_theme_name is not null
Group by year
Order by 2 desc



------------------------------------------------------
-- Finding how many sets were created in each century.
------------------------------------------------------

/*
ALTER View [dbo].[analytics_main] as

Select 
	s.set_num, 
	s.name as set_name, 
	s.year, 
	s.theme_id, 
	cast(s.num_parts as numeric) num_parts, 
	t.name as theme_name, 
	t.parent_id, 
	p.name as parent_theme_name,
Case
	When s.year BETWEEN 1901 AND 2000 then '20th Century'
	When s.year BETWEEN 2001 AND 2100 then '21st Century'
End 
as Century
From dbo.sets s
Left Join dbo.themes t
	on s.theme_id = t.id
Left Join dbo.themes p
	on t.parent_id = p.id
GO
*/

Select * From dbo.analytics_main

Select 
	Century, 
	COUNT(set_num) as TotalSets
From dbo.analytics_main
--Where parent_theme_name is not null
Group by Century



--------------------------------------------------------------------------------
-- Finding what percentage of sets released in the 21st century were car themed.
--------------------------------------------------------------------------------

With CTE as
(
	Select 
		Century, 
		theme_name, 
		COUNT(set_num) as total_set_num
	From analytics_main
	Where Century = '21st Century'
	Group by Century, theme_name
)
Select 
	SUM(total_set_num) as TotalSets, 
	SUM(Percentage) as Percentage
From(
	Select Century, 
	theme_name, 
	total_set_num, 
	SUM(total_set_num) OVER() as total, 
	CAST(1.0000 * total_set_num / SUM(total_set_num) OVER()as decimal(5,4)) * 100 as Percentage
	From CTE
	)m
Where theme_name like '%car%'



--------------------------------------------------------------------
-- Finding the most popular theme for each year in the 21st century.
--------------------------------------------------------------------

Select 
	Year, 
	theme_name as Title, 
	total_set_num as NumberOfSets
From (
	Select Year, 
	theme_name, 
	COUNT(set_num) as total_set_num, 
	ROW_NUMBER() OVER (partition by Year order by COUNT(set_num) desc) rn
	from analytics_main
	where Century = '21st Century'
		 AND parent_theme_name is not null
	Group by Year, theme_name
)m
Where rn = 1
Order by Year desc



-----------------------------------------------------
-- Finding what color was produced the most on parts.
-----------------------------------------------------

Select 
	color_name as Color, 
	SUM(quantity) as PartsThisColor
From
	(
	Select 
		inv.color_id, 
		inv.inventory_id, 
		inv.part_num, 
		CAST(inv.quantity as numeric) quantity, 
		inv.is_spare, 
		c.name as color_name, 
		c.rgb, 
		p.name as part_name, 
		p.part_material, 
		pc.name as category_name
	From inventory_parts inv
	Inner Join colors c
		on inv.color_id = c.id
	Inner Join parts p
		on inv.color_id = p.part_num
	Inner Join part_categories pc
		on inv.color_id = pc.id
	)main
Group by color_name
Order by 2 desc