SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[int_hooldus_klient_capex]
    @projekt NVARCHAR,
    @aeg1 DATETIME,
    @aeg2 DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure the special record exists in int_hooldus_klient
    IF NOT EXISTS (SELECT 1 FROM int_hooldus_klient WHERE rn = '_capex')
    BEGIN
        INSERT INTO int_hooldus_klient (rn, nimi, formaat)
        VALUES ('_capex', 'CAPEX', 'xml');
    END

    -- Create a temporary table for project data
    CREATE TABLE #projects (
        first_stproj NVARCHAR(32),
        proj_from_bugget NVARCHAR(32),
        budget_proj_master NVARCHAR(32),
        projectMasterCount DECIMAL(15, 0),
        first_master NVARCHAR(32),
        pname NVARCHAR(255),
        contr_summa DECIMAL(15, 4),
        responsible NVARCHAR(255),
        sdate NVARCHAR(MAX),
        edate NVARCHAR(MAX)
    );

    -- Insert data into the temporary table
    INSERT INTO #projects (first_stproj, proj_from_bugget, budget_proj_master)
    SELECT
        dproject,
        project,
        dbo.get_master_project_lv_ver(dproject, project)
    FROM
    (
        SELECT kood AS project
        FROM projektid
        WHERE master LIKE 'CAPEX%'
    ) AS capex_projects
    CROSS JOIN
    (
        SELECT DISTINCT projekt AS dproject
        FROM fin_eelarved_read
        WHERE number IN (40020, 40019) AND ISNULL(projekt, '') != ''
    ) AS fin_projects;

    -- Update temporary table with additional information
    UPDATE #projects
    SET projectMasterCount = (SELECT COUNT(*) FROM projektid WHERE master = first_stproj),
        pname = (SELECT nimi FROM projektid WHERE kood = first_stproj),
        contr_summa = ISNULL((SELECT SUM(summa) FROM lepingud_read WHERE projekt = first_stproj), 0),
        responsible = (SELECT nimi FROM kasutajad WHERE kood = (SELECT juht FROM projektid WHERE kood = first_stproj)),
        edate = (SELECT CONVERT(NVARCHAR(MAX), aeg2, 104) FROM projektid WHERE kood = first_stproj),
        sdate = (SELECT CONVERT(NVARCHAR(MAX), aeg1, 104) FROM projektid WHERE kood = first_stproj);

    -- Generate XML output
    SELECT
        SUBSTRING(CONVERT(NVARCHAR(MAX), YEAR(@aeg1)), 3, 2) AS a,
        (SELECT * ,
            ISNULL((SELECT SUM(summa) FROM lepingud_read WHERE projekt = projektid.kood), 0) AS contr_summa,
            (SELECT * FROM fin_eelarved_read WHERE projekt = projektid.kood AND tyyp LIKE 'prog_%' AND tyyp LIKE '%' + SUBSTRING(CONVERT(NVARCHAR(MAX), YEAR(@aeg1)), 3, 2) + '%' FOR XML PATH('row'), TYPE, ELEMENTS) AS rows,
            (SELECT * FROM fin_eelarved_read WHERE projekt = projektid.kood AND tyyp LIKE '%PB%' AND tyyp LIKE '%' + CONVERT(NVARCHAR(MAX), YEAR(@aeg1)) + '%' FOR XML PATH('row'), TYPE, ELEMENTS) AS rowsact,
            (SELECT ISNULL(SUM(or_arved_read.summa), 0) AS summa FROM or_arved_read LEFT JOIN or_arved ON or_arved.number = or_arved_read.number WHERE ISNULL(Or_arved_read.projekt, Or_arved.projekt) = projektid.kood) AS invoicesum
        FROM projektid WHERE master IN (SELECT kood FROM projektid WHERE kood LIKE 'CAPEX%') FOR XML PATH('capex_master_project'), TYPE, ELEMENTS) AS capex_master_projects,
        (SELECT *,
            ISNULL((SELECT SUM(summa) FROM lepingud_read WHERE projekt = projektid.kood), 0) AS contr_summa,
            (SELECT * FROM fin_eelarved_read WHERE projekt = projektid.kood AND tyyp LIKE 'prog_%' AND tyyp LIKE '%' + SUBSTRING(CONVERT(NVARCHAR(MAX), YEAR(@aeg1)), 3, 2) + '%' FOR XML PATH('row'), TYPE, ELEMENTS) AS rows,
            (SELECT * FROM fin_eelarved_read WHERE projekt = projektid.kood AND tyyp LIKE '%PB%' AND tyyp LIKE '%' + CONVERT(NVARCHAR(MAX), YEAR(@aeg1)) + '%' FOR XML PATH('row'), TYPE, ELEMENTS) AS rowsact,
            (SELECT ISNULL(SUM(or_arved_read.summa), 0) AS summa FROM or_arved_read LEFT JOIN or_arved ON or_arved.number = or_arved_read.number WHERE ISNULL(Or_arved_read.projekt, Or_arved.projekt) = projektid.kood) AS invoicesum
        FROM projektid WHERE master IN (SELECT kood FROM projektid WHERE master IN (SELECT kood FROM projektid WHERE kood LIKE 'CAPEX%')) FOR XML PATH('capex_project'), TYPE, ELEMENTS) AS capex_projects,
        (SELECT *,
            (SELECT ISNULL(SUM(or_arved_read.summa), 0) AS summa FROM or_arved_read LEFT JOIN or_arved ON or_arved.number = or_arved_read.number WHERE ISNULL(Or_arved_read.projekt, Or_arved.projekt) = #projects.first_stproj) AS invoicesum
        FROM #projects WHERE budget_proj_master IS NOT NULL FOR XML PATH('project'), TYPE, ELEMENTS) AS projects
    FOR XML PATH('document'), TYPE, ELEMENTS;

    -- Clean up temporary table
    DROP TABLE #projects;

    SET NOCOUNT OFF;
END
GO
