SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Alter the stored procedure
ALTER PROCEDURE [dbo].[int_hooldus_klient_eds_absence_import]
    @aeg1 DATETIME,
    @aeg2 DATETIME,
    @key NVARCHAR(MAX)
AS
BEGIN
    -- Declare variables
    DECLARE @datenow DATETIME, @ag DATETIME
    DECLARE @number INT, @maa INT, @kmk NVARCHAR(32), @x INT, @kinnitatud INT
    DECLARE @myyja NVARCHAR(32), @aeg DATETIME
    DECLARE @result1 XML, @result2 NVARCHAR(MAX)
    DECLARE @err NVARCHAR(32)
    DECLARE @cu NVARCHAR(32)

    -- Set current date and time
    SET @datenow = GETDATE()
    SET @ag = GETDATE()

    -- Create temporary tables to store XML data
    DECLARE @t AS TABLE (x XML)
    DECLARE @t2 AS TABLE (x XML)
    DECLARE @t3 AS TABLE (x XML)
    DECLARE @t4 AS TABLE (x XML)
    DECLARE @t5 AS TABLE (x XML)
    DECLARE @t6 AS TABLE (x XML)

    -- Insert data into temporary tables
    INSERT INTO @t 
    SELECT REPLACE(dat, '<?xml version="1.0" encoding="UTF-8"?>', '') FROM int_import_dat WHERE cu = @key

    -- Create table to store extracted XML data
    DECLARE @xml_data AS TABLE
    (
        id NVARCHAR(255),
        izpildes_laiks DATETIME,
        darba_deveja_nmr_kods NVARCHAR(255),
        darba_deveja_nosaukums NVARCHAR(MAX),
        periods_no DATE,
        periods_lidz DATE,
        sanemsanas_laiks DATETIME
    )

    -- Extract data from XML and insert into @xml_data table
    INSERT @xml_data
    SELECT 
        tab.col.value('id[1]', 'NVARCHAR(MAX)') AS id,
        tab.col.value('izpildes_laiks[1]', 'DATETIME') AS izpildes_laiks,
        tab.col.value('darba_deveja_nmr_kods[1]', 'NVARCHAR(MAX)') AS darba_nmr_kods,
        tab.col.value('darba_deveja_nosaukums[1]', 'NVARCHAR(MAX)') AS darba_deveja_nosaukums,
        tab.col.value('periods_no[1]', 'DATETIME') AS periods_no,
        tab.col.value('periods_lidz[1]', 'DATETIME') AS periods_lidz,
        tab.col.value('sanemsanas_laiks[1]', 'DATETIME') AS sanemsanas_laiks
    FROM @t 
    CROSS APPLY x.nodes('//NM_dn_dnl/pamatdati') tab(col)

    -- Insert data into @t2
    INSERT INTO @t2
    SELECT REPLACE(dat, '<?xml version="1.0" encoding="UTF-8"?>', '') FROM int_import_dat WHERE cu = @key

    -- Create table to store extracted XML data for CertificateData
    DECLARE @xml_data2 AS TABLE
    (
        RegistrationNumber NVARCHAR(255),
        CertificateType NVARCHAR(255),
        CertificateFormType NVARCHAR(255),
        ContinueDate DATETIME,
        PreviousCertificateNumber NVARCHAR(255)
    )

    -- Extract data from XML and insert into @xml_data2 table
    INSERT @xml_data2
    SELECT 
        tab.col.value('RegistrationNumber[1]', 'NVARCHAR(255)') AS RegistrationNumber,
        tab.col.value('CertificateType[1]', 'NVARCHAR(255)') AS CertificateType,
        tab.col.value('CertificateFormType[1]', 'NVARCHAR(255)') AS CertificateFormType,
        tab.col.value('ContinueDay[1]', 'DATETIME') AS ContinueDay,
        tab.col.value('PreviousCertificateNumber[1]', 'NVARCHAR(255)') AS PreviousCertificateNumber
    FROM @t2
    CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData') tab(col)

    -- Insert data into @t3
    INSERT INTO @t3
    SELECT REPLACE(dat, '<?xml version="1.0" encoding="UTF-8"?>', '') FROM int_import_dat WHERE cu = @key

    -- Create table to store extracted XML data for PersonData
    DECLARE @xml_data3 AS TABLE
    (
        RegistrationNumber NVARCHAR(255),
        PersonID NVARCHAR(255),
        FirstName NVARCHAR(255),
        LastName NVARCHAR(255)
    )

    -- Extract data from XML and insert into @xml_data3 table
    INSERT @xml_data3
    SELECT 
        tab.col.value('../RegistrationNumber[1]', 'NVARCHAR(255)') AS RegistrationNumber,
        tab.col.value('PersonID[1]', 'NVARCHAR(255)') AS PersonID,
        tab.col.value('FirstName[1]', 'NVARCHAR(255)') AS FirstName,
        tab.col.value('LastName[1]', 'NVARCHAR(255)') AS LastName
    FROM @t3
    CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/PersonData') tab(col)

    -- Insert data into @t4
    INSERT INTO @t4
    SELECT REPLACE(dat, '<?xml version="1.0" encoding="UTF-8"?>', '') FROM int_import_dat WHERE cu = @key

    -- Create table to store extracted XML data for DisabilityCause
    DECLARE @xml_data4 AS TABLE
    (
        RegistrationNumber NVARCHAR(255),
        DisabilityCauseText NVARCHAR(255)
    )

    -- Extract data from XML and insert into @xml_data4 table
    INSERT @xml_data4
    SELECT 
        tab.col.value('../RegistrationNumber[1]', 'NVARCHAR(255)') AS RegistrationNumber,
        tab.col.value('DisabilityCauseText[1]', 'NVARCHAR(255)') AS DisabilityCauseText
    FROM @t4
    CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/DisabilityCause') tab(col)

    -- Insert data into @t5
    INSERT INTO @t5
    SELECT REPLACE(dat, '<?xml version="1.0" encoding="UTF-8"?>', '') FROM int_import_dat WHERE cu = @key

    -- Create table to store extracted XML data for PeriodDates
    DECLARE @xml_data5 AS TABLE
    (
        RegistrationNumber NVARCHAR(255),
        StartDate DATETIME,
        EndDate DATETIME
    )

    -- Extract data from XML and insert into @xml_data5 table
    INSERT @xml_data5
    SELECT 
        tab.col.value('../RegistrationNumber[1]', 'NVARCHAR(255)') AS RegistrationNumber,
        tab.col.value('StartDate[1]', 'DATETIME') AS StartDate,
        tab.col.value('EndDate[1]', 'DATETIME') AS EndDate
    FROM @t5
    CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/PeriodDates') tab(col)

    -- Insert data into @t6
    INSERT INTO @t6
    SELECT REPLACE(dat, '<?xml version="1.0" encoding="UTF-8"?>', '') FROM int_import_dat WHERE cu = @key

    -- Create table to store extracted XML data for CertificateStatus
    DECLARE @xml_data6 AS TABLE
    (
        RegistrationNumber NVARCHAR(255),
        StatusDate DATETIME,
        StatusText NVARCHAR(255)
    )

    -- Extract data from XML and insert into @xml_data6 table
    INSERT @xml_data6
    SELECT 
        tab.col.value('../RegistrationNumber[1]', 'NVARCHAR(255)') AS RegistrationNumber,
        tab.col.value('StatusDate[1]', 'DATETIME') AS StatusDate,
        tab.col.value('StatusText[1]', 'NVARCHAR(255)') AS StatusText
    FROM @t6
    CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/CertificateStatus') tab(col)

    -- Set @cu based on APP_NAME()
    IF APP_NAME() LIKE '%,user:%' 
        SET @cu = SUBSTRING(APP_NAME(), CHARINDEX(',user:', APP_NAME()) + 6, 32)

    -- Create temporary table to store combined data
    CREATE TABLE #values_temp
    (
        dd_reg_nr NVARCHAR(255),
        RegistrationNumber NVARCHAR(255),
        CertificateType NVARCHAR(255),
        CertificateFormType NVARCHAR(255),
        ContinueDate DATETIME,
        PreviousCertificateNumber NVARCHAR(255),
        PersonID NVARCHAR(255),
        FirstName NVARCHAR(255),
        LastName NVARCHAR(255),
        DisabilityCauseText NVARCHAR(255),
        StartDate DATETIME,
        EndDate DATETIME,
        StatusDate DATETIME,
        StatusText NVARCHAR(255),
        DirUser NVARCHAR(255),
        countRecord INT,
        DocNr NVARCHAR(32),
        DocRow NVARCHAR(32)
    )

    -- Insert data into #values_temp
    INSERT INTO #values_temp
    SELECT 
        (SELECT TOP 1 darba_deveja_nmr_kods FROM @xml_data) AS dd_reg_nr,
        RegistrationNumber,
        CertificateType,
        CertificateFormType,
        ContinueDate,
        PreviousCertificateNumber,
        (SELECT PersonID FROM @xml_data3 xd3 WHERE xd3.RegistrationNumber = xd2.RegistrationNumber) AS PersonID,
        (SELECT FirstName FROM @xml_data3 xd3 WHERE xd3.RegistrationNumber = xd2.RegistrationNumber) AS FirstName,
        (SELECT LastName FROM @xml_data3 xd3 WHERE xd3.RegistrationNumber = xd2.RegistrationNumber) AS LastName,
        (SELECT DisabilityCauseText FROM @xml_data4 xd4 WHERE xd4.RegistrationNumber = xd2.RegistrationNumber) AS DisabilityCauseText,
        (SELECT StartDate FROM @xml_data5 xd5 WHERE xd5.RegistrationNumber = xd2.RegistrationNumber) AS StartDate,
        (SELECT EndDate FROM @xml_data5 xd5 WHERE xd5.RegistrationNumber = xd2.RegistrationNumber) AS EndDate,
        (SELECT StatusDate FROM @xml_data6 xd6 WHERE xd6.RegistrationNumber = xd2.RegistrationNumber) AS StatusDate,
        (SELECT StatusText FROM @xml_data6 xd6 WHERE xd6.RegistrationNumber = xd2.RegistrationNumber) AS StatusText,
        (SELECT kood FROM kasutajad WHERE REPLACE(isikukood, '-', '') = (SELECT PersonID FROM @xml_data3 xd3 WHERE xd3.RegistrationNumber = xd2.RegistrationNumber)) AS DirUser,
        CAST(0 AS INT) AS countRecord,
        CAST('' AS NVARCHAR(32)) AS DocNr,
        CAST('' AS NVARCHAR(32)) AS DocRow
    FROM @xml_data2 xd2

    -- Update #values_temp with additional information
    UPDATE #values_temp 
    SET countRecord = (SELECT COUNT(number) FROM per_ajad_read WHERE persoon = DirUser AND kommentaar = RegistrationNumber)

    UPDATE #values_temp 
    SET DocNr = (SELECT number FROM per_ajad_read WHERE persoon = DirUser AND kommentaar = RegistrationNumber) 
    WHERE countRecord = 1

    UPDATE #values_temp 
    SET DocRow = (SELECT rn FROM per_ajad_read WHERE persoon = DirUser AND kommentaar = RegistrationNumber AND number = DocNr) 
    WHERE countRecord = 1

    -- Select all data from #values_temp
    SELECT * FROM #values_temp

    -- Check if the registration number matches the company's registration number
    IF (SELECT TOP 1 dd_reg_nr FROM #values_temp) = (SELECT TOP 1 setting FROM settings WHERE id LIKE '%firma_regnr%')
    BEGIN
        -- If there are new records to insert
        IF 0 IN (SELECT countRecord FROM #values_temp) 
        BEGIN
            -- Get the next number for per_ajad
            SET @number = (SELECT MAX(number) + 1 FROM per_ajad)

            -- Insert into per_ajad
            INSERT INTO per_ajad (number, ts, selgitus)
            SELECT 
                @number,
                GETDATE(),
                CONCAT('Darbnespēju lapu imports', ' ', GETDATE(), ' ', @cu)  

            -- Insert into per_ajad_read
            INSERT INTO per_ajad_read (number, rn, persoon, nimi, r_liik, r_aeg1, r_aeg2, kommentaar)
            SELECT
                @number,
                ROW_NUMBER() OVER(ORDER BY RegistrationNumber),
                (SELECT kood FROM kasutajad WHERE REPLACE(isikukood, '-', '') = PersonID),
                CONCAT(FirstName, ' ', LastName),
                CASE 
                    WHEN CertificateType = 'A' THEN 'SICK_LIST_A' 
                    WHEN CertificateType = 'B' THEN 'SICK_LIST_B'
                END,
                CAST(DATEADD(HOUR, 24, StartDate) AS DATE),
                CAST(DATEADD(HOUR, 24, EndDate) AS DATE),
                RegistrationNumber
            FROM #values_temp 
            WHERE countRecord = 0 AND StatusText != N'Anulēta'
        END
        -- If there are records to update
        ELSE IF 1 IN (SELECT countRecord FROM #values_temp)
        BEGIN
            -- Update per_ajad_read
            UPDATE per_ajad_read
            SET r_aeg2 = CAST(z.EndDate AS DATE)
            FROM (SELECT * FROM #values_temp WHERE countRecord = 1) z 
            WHERE r_aeg2 IS NULL AND number = z.DocNr AND z.CountRecord = 1 AND z.DocRow = per_ajad_read.rn
        END
    END
    ELSE
    BEGIN
        -- If the registration number doesn't match
        SELECT N'Nepareizs reģistrācijas nr.'
    END

    -- Clean up
    DROP TABLE IF EXISTS #values_temp

    -- Delete processed data from int_import_dat
    DELETE FROM int_import_dat WHERE cu = @key
END
GO
