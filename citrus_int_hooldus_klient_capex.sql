SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[int_hooldus_klient_capex]

    @aeg1 DATETIME,
    @aeg2 DATETIME,
    @projekt NVARCHAR(MAX) = NULL
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
          AND (@projekt IS NULL OR kood = @projekt) -- Filter by @projekt if provided
    ) AS capex_projects
    CROSS JOIN
    (
        SELECT DISTINCT projekt AS dproject
        FROM fin_eelarved_read
        WHERE number IN (40020, 40019) AND ISNULL(projekt, '') != ''
          AND (@projekt IS NULL OR projekt = @projekt) -- Filter by @projekt if provided
    ) AS fin_projects;

    -- Update temporary table with additional information
    UPDATE #projects
    SET contr_summa = ISNULL((
        SELECT SUM(COALESCE(l.kokku_myyk, lr.summa, 0))
        FROM lepingud l
        LEFT JOIN lepingud_read lr ON l.number = lr.number
        WHERE l.projekt = #projects.first_stproj OR lr.projekt = #projects.first_stproj
    ), 0);

    -- Generate XML output
    SELECT
        FORMAT(@aeg1, 'dd.MM.yyyy') AS start_date,
        FORMAT(@aeg2, 'dd.MM.yyyy') AS end_date,
        (
            SELECT *,
                ISNULL((
                    SELECT SUM(COALESCE(l.kokku_myyk, lr.summa, 0))
                    FROM lepingud l
                    LEFT JOIN lepingud_read lr ON l.number = lr.number
                    WHERE l.projekt = projektid.kood OR lr.projekt = projektid.kood
                ), 0) AS contr_summa,
                (
                    SELECT * FROM fin_eelarved_read
                    WHERE projekt = projektid.kood
                    AND tyyp LIKE 'prog_%'
                    AND tyyp LIKE '%' + SUBSTRING(CONVERT(NVARCHAR(MAX), YEAR(@aeg1)), 3, 2) + '%'
                    FOR XML PATH('row'), TYPE, ELEMENTS
                ) AS rows,
                (
                    SELECT * FROM fin_eelarved_read
                    WHERE projekt = projektid.kood
                    AND tyyp LIKE '%PB%'
                    AND tyyp LIKE '%' + CONVERT(NVARCHAR(MAX), YEAR(@aeg1)) + '%'
                    FOR XML PATH('row'), TYPE, ELEMENTS
                ) AS rowsact,
                (
                    SELECT ISNULL(SUM(or_arved_read.summa), 0) AS summa 
                    FROM or_arved_read 
                    INNER JOIN or_arved ON or_arved.number = or_arved_read.number 
                    WHERE (ISNULL(Or_arved_read.projekt, Or_arved.projekt) = projektid.kood
                           OR ISNULL(Or_arved_read.projekt, Or_arved.projekt) LIKE projektid.kood + '.%'
                           OR ISNULL(Or_arved_read.projekt, Or_arved.projekt) LIKE projektid.kood + '/%')
                      AND or_arved.kinnitatud = 1
                ) AS invoicesum
            FROM projektid
            WHERE master IN (SELECT kood FROM projektid WHERE kood LIKE 'CAPEX%')
              AND (@projekt IS NULL OR kood = @projekt) -- Filter by @projekt if provided
            FOR XML PATH('capex_master_project'), TYPE, ELEMENTS
        ) AS capex_master_projects,
        (
            SELECT *,
                ISNULL((
                    SELECT SUM(COALESCE(l.kokku_myyk, lr.summa, 0))
                    FROM lepingud l
                    LEFT JOIN lepingud_read lr ON l.number = lr.number
                    WHERE l.projekt = projektid.kood OR lr.projekt = projektid.kood
                ), 0) AS contr_summa,
                (
                    SELECT * FROM fin_eelarved_read
                    WHERE projekt = projektid.kood
                    AND tyyp LIKE 'prog_%'
                    AND tyyp LIKE '%' + SUBSTRING(CONVERT(NVARCHAR(MAX), YEAR(@aeg1)), 3, 2) + '%'
                    FOR XML PATH('row'), TYPE, ELEMENTS
                ) AS rows,
                (
                    SELECT * FROM fin_eelarved_read
                    WHERE projekt = projektid.kood
                    AND tyyp LIKE '%PB%'
                    AND tyyp LIKE '%' + CONVERT(NVARCHAR(MAX), YEAR(@aeg1)) + '%'
                    FOR XML PATH('row'), TYPE, ELEMENTS
                ) AS rowsact,
                (
                    SELECT ISNULL(SUM(or_arved_read.summa), 0) AS summa 
                    FROM or_arved_read 
                    INNER JOIN or_arved ON or_arved.number = or_arved_read.number 
                    WHERE (ISNULL(Or_arved_read.projekt, Or_arved.projekt) = projektid.kood
                           OR ISNULL(Or_arved_read.projekt, Or_arved.projekt) LIKE projektid.kood + '.%'
                           OR ISNULL(Or_arved_read.projekt, Or_arved.projekt) LIKE projektid.kood + '/%')
                      AND or_arved.kinnitatud = 1
                ) AS invoicesum
            FROM projektid
            WHERE master IN (SELECT kood FROM projektid WHERE master IN (SELECT kood FROM projektid WHERE kood LIKE 'CAPEX%'))
              AND (@projekt IS NULL OR master = @projekt) -- Filter by @projekt if provided
            FOR XML PATH('capex_project'), TYPE, ELEMENTS
        ) AS capex_projects,
        (
            SELECT *,
                (
                    SELECT ISNULL(SUM(or_arved_read.summa), 0) AS summa 
                    FROM or_arved_read 
                    INNER JOIN or_arved ON or_arved.number = or_arved_read.number 
                    WHERE (ISNULL(Or_arved_read.projekt, Or_arved.projekt) = #projects.first_stproj
                           OR ISNULL(Or_arved_read.projekt, Or_arved.projekt) LIKE #projects.first_stproj + '.%'
                           OR ISNULL(Or_arved_read.projekt, Or_arved.projekt) LIKE #projects.first_stproj + '/%')
                      AND or_arved.kinnitatud = 1
                ) AS invoicesum
            FROM #projects
            WHERE budget_proj_master IS NOT NULL
              AND (@projekt IS NULL OR budget_proj_master = @projekt) -- Filter by @projekt if provided
            FOR XML PATH('project'), TYPE, ELEMENTS
        ) AS projects
    FOR XML PATH('document'), TYPE, ELEMENTS;

    -- Clean up temporary table
    DROP TABLE #projects;

    SET NOCOUNT OFF;
END
GO
