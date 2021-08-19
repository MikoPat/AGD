-- 1)
-- Okapy w 2006 roku w regionach z podsumowaniami
SELECT towar, region, SUM(ilosc) as ilosc
FROM Sprzedaz_hist
		JOIN Dim_Regiony ON Sprzedaz_hist.IdRegion = Dim_Regiony.Id
		JOIN Dim_Towary ON Sprzedaz_hist.IdTowary = Dim_Towary.Id
		JOIN Dim_Czas ON Sprzedaz_hist.IdCzas = Dim_Czas.Id
WHERE Rok = 2006 and Podgrupa = 'okapy'
GROUP BY CUBE (Region, Towar);

-- 2)
-- Okapy w 2006 roku w regionach z podsumowaniami z wykorzystaniem CTE
WITH CTE_OKAPY_PIV AS (
SELECT towar, region, SUM(ilosc) as 'ilosc'
FROM Sprzedaz_hist
		JOIN Dim_Regiony ON Sprzedaz_hist.IdRegion = Dim_Regiony.Id
		JOIN Dim_Towary ON Sprzedaz_hist.IdTowary = Dim_Towary.Id
		JOIN Dim_Czas ON Sprzedaz_hist.IdCzas = Dim_Czas.Id
WHERE Rok = 2006 and Podgrupa = 'okapy'
GROUP BY CUBE (Region,Towar))

SELECT Region, [okapy teleskopowe],[okapy meblowe],[okapy kominowe],[okapy uniwersalne],([okapy teleskopowe]+[okapy meblowe]+[okapy kominowe]+[okapy uniwersalne]) AS [okapy razem]
FROM CTE_OKAPY_PIV
PIVOT (SUM(ilosc) FOR Towar IN ([okapy teleskopowe],[okapy meblowe],[okapy kominowe],[okapy uniwersalne])) AS p;


-- 3)
--Procent realizacji planu w poszczególnych regionach
WITH 
	CTE_HIST_2007 AS
		(SELECT Dim_Regiony.Id AS 'id', SUM(Ilosc) AS 'ilosc'
		 FROM Sprzedaz_hist
			JOIN Dim_Regiony ON Sprzedaz_hist.IdRegion = Dim_Regiony.Id
			JOIN Dim_Towary ON Sprzedaz_hist.IdTowary = Dim_Towary.Id
			JOIN Dim_Czas ON Sprzedaz_hist.IdCzas = Dim_Czas.Id
		WHERE Rok = 2007 and Miesiac>=1 and Miesiac<=4
		GROUP BY Dim_Regiony.Id),
	CTE_PLAN_2007 AS
		(SELECT Dim_Regiony.Id AS 'id', SUM(Ilosc) AS 'ilosc'
		 FROM Sprzedaz_plan
			JOIN Dim_Regiony ON Sprzedaz_plan.IdRegion = Dim_Regiony.Id
			JOIN Dim_Towary ON Sprzedaz_plan.IdTowary = Dim_Towary.Id
			JOIN Dim_Czas ON Sprzedaz_plan.IdCzas = Dim_Czas.Id
		WHERE Rok = 2007 and Miesiac>=1 and Miesiac<=4
		GROUP BY Dim_Regiony.Id)


SELECT  Dim_Regiony.Region,
		CTE_HIST_2007.Ilosc as ilosc_hist,
		CTE_PLAN_2007.Ilosc as ilosc_plan,
		CAST((1.0 *CTE_HIST_2007.Ilosc /CTE_PLAN_2007.Ilosc)*100 AS DECIMAL(6,2)) as [realizacja%]
FROM Dim_Regiony
	LEFT JOIN CTE_PLAN_2007 ON Dim_Regiony.Id = CTE_PLAN_2007.id 
	LEFT JOIN CTE_HIST_2007 ON Dim_Regiony.Id = CTE_HIST_2007.id 
ORDER BY Region



-- 4)
-- Wartość bieżącego obrotu ze sprzedażą poszczególnych okapów zestwiona z tą wartością z poprzedniego kwartału, w roku 2006r., dodanie stosunku do poprzeniego kwartału.
WITH CTE_TOW AS(
	SELECT DT.Towar, DC.Kwartal, SUM(SH.Obrot) as 'obrot'
	FROM Sprzedaz_hist SH
		JOIN Dim_Towary DT ON SH.IdTowary = DT.Id
		JOIN Dim_Czas DC ON SH.IdCzas = DC.Id
	WHERE DC.Rok = 2006 and DT.Podgrupa = 'okapy'
	GROUP BY DT.Towar, DC.Kwartal)

SELECT CT1.Towar,CT1.Kwartal,
CT1.obrot AS [Obrot biezacy kwartal],
CT2.obrot AS [Obrot poprzedni kwartal],
CASE
	WHEN CT1.obrot - CT2.obrot > 0 THEN 'wzrost'
	WHEN CT1.obrot - CT2.obrot < 0 THEN 'spadek'
	ELSE '-' 
END AS [zmiana]
FROM CTE_TOW AS CT1
LEFT JOIN CTE_TOW AS CT2 ON CT1.Towar = CT2.Towar
AND CT1.Kwartal -1 = CT2.Kwartal
ORDER BY Towar,Kwartal;

-- 5)
-- Suma liczby sprzedanych sztuk okapów kominowych, narastającą miesiącami, w roku 2006r.
WITH CTE_KOMIN AS (
SELECT DT.Towar, DC.Miesiac, SUM(SH.Ilosc) as 'ilosc'
FROM (Sprzedaz_hist SH JOIN Dim_Czas DC
	ON SH.IdCzas = DC.Id) JOIN Dim_Towary DT
	ON SH.IdTowary = DT.Id
WHERE DT.Towar = 'okapy kominowe'  and DC.Rok = 2006
GROUP BY DT.Towar, DC.Miesiac)


SELECT CK1.Towar, 
		CK1.Miesiac,
		MIN(CK1.ilosc) as 'ilosc biezacy miesiac ',
		SUM(CK2.ilosc) as 'suma poprzednich miesięcy'
FROM CTE_KOMIN CK1 
	 JOIN CTE_KOMIN CK2 ON CK1.Towar = CK2.Towar AND CK1.Miesiac >= CK2.Miesiac
GROUP BY CK1.Towar,CK1.Miesiac;


-- 6)
-- Dla każdego okapu sprzedaż (obrot) zestawiona ze sprzedażą w całej podgrupie "okapy" i całej grupie "BI" w 2006r.- procentowy udział

WITH 
CTE_OKAPY AS (
	SELECT DT.Towar, SUM(Obrot) as 'obrot', 1 AS 'a'
	FROM Sprzedaz_hist SH JOIN Dim_Towary DT ON SH.IdTowary = DT.Id 
								JOIN Dim_Czas DC ON SH.IdCzas = DC.Id
	WHERE DT.Podgrupa = 'okapy' and DC.Rok = 2006
	GROUP BY Towar),


CTE_TOW AS (
	SELECT SUM(SH.Obrot) as 'obrot', 1 AS 'a'
	FROM Sprzedaz_hist SH JOIN Dim_Towary DT ON SH.IdTowary = DT.Id 
								JOIN Dim_Czas DC ON SH.IdCzas = DC.Id
	WHERE DT.Podgrupa = 'okapy' and DC.Rok = 2006),


CTE_BI AS (
	SELECT SUM(Obrot) as 'obrot', 1 AS 'a'
	FROM Sprzedaz_hist SH JOIN Dim_Towary DT ON SH.IdTowary = DT.Id 
							JOIN Dim_Czas DC ON SH.IdCzas = DC.Id
	WHERE DT.Grupa = 'BI' and DC.Rok = 2006)


SELECT CTE_OKAPY.Towar,
		CTE_OKAPY.obrot,
		CAST((1.0 *CTE_OKAPY.obrot /CTE_TOW.obrot)*100 AS DECIMAL(6,2)) as [udzial w podgrupie okapy %],
		CAST((1.0 *CTE_OKAPY.obrot /CTE_BI.obrot)*100 AS DECIMAL(6,2)) as [udzial w BI %] 
FROM CTE_OKAPY
	JOIN CTE_TOW ON CTE_OKAPY.a = CTE_TOW.a
	JOIN CTE_BI ON CTE_OKAPY.a = CTE_BI.a
ORDER BY Towar