SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[int_hooldus_klient_send_payment_reminder_emails]
    @aeg1 DATETIME,
    @aeg2 DATETIME,
    @obj NVARCHAR(510) = NULL,
    @paymentTerm NVARCHAR(64) = NULL,
    @isApproved BIT = 0,
    @sendEmails BIT = 0,
    @testMode BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @attachmentUrl NVARCHAR(MAX),
            @companyName NVARCHAR(MAX),
            @subjectEmail NVARCHAR(MAX),
            @emailTxt NVARCHAR(MAX),
            @firmaemail NVARCHAR(MAX),
            @testEmail NVARCHAR(100) = 'Ilze.Avotina@myfitness.lv';

    -- Set variable values
    SELECT @attachmentUrl = 'https://login.directo.ee/' + DB_NAME() + '/yld_print.asp?mida=xsl&row=4444&moodul=arve&number=rekinsnr&ver=&print=yes&mail=&rns=&aspdf=1';
    SELECT @companyName = setting FROM settings WHERE id = 'firma_nimi';
    SELECT @firmaemail = ISNULL((SELECT setting FROM settings WHERE id = 'firma_email'), 'NoEmail');
    SELECT @subjectEmail = @companyName + N': Rēķins';

    SELECT @emailTxt = N'<br/>
        Labdien,<br/><br/><br/>
        Pielikumā nosūtām rēķinu par @firmaninimi sporta kluba pakalpojumu abonēšanu, saskaņā ar noslēgto līgumu.<br/><br/><br/>
        JŪSU IEVĒRĪBAI :<br/>
        -Ja Jums ir noslēgts līgums ar Banku par e-rēķinu saņemšanu, šis rēķins IR INFORMATĪVS! (tas tiks piegādāts Jūsu internetbankā, kurā ir iespējams to ērti apmaksāt).<br/>
        -Ja Jums nav noslēgts šāds līgums ar Banku, lūdzam pielikumā esošo rēķinu apmaksāt līdz rēķinā norādītajam datumam.<br/>
        Lūdzam pārliecināties, ka Jūsu norēķini ir veikti savlaicīgi.<br/><br/><br/>
        P.S. Uzticiet savlaicīgu rēķina apmaksu savai Bankai – pieslēdzot automātisko rēķina apmaksu!<br/><br/>
        Uz tikšanos treniņos!<br/>
        @firmaninimi<br/>
        _______________________________________________________________________<br/>
        Dear member,<br/><br/><br/>
        Please find attached invoice for @firmaninimi sports club services, according to the contract.<br/><br/>
        TO YOUR ATTENTION:<br/>
        - If You have signed a contract with your bank for e-invoicing, this INVOICE IS INFORMATIVE! (it will be delivered to your internet bank where it can conveniently be paid).<br/>
        - If You have not entered into such an agreement with the bank, please pay the attached invoice by a given date.<br/><br/><br/>
        Please make sure that your settlement is made in a timely manner.<br/><br/>
        P.S. Use the automatic invoice paying option at your bank not to miss the due date of the invoice.<br/><br/>
        See you in training!<br/>
        @firmaninimi<br/>';

    -- Temporary table to store client data
    CREATE TABLE #TempClientData (
        RN NVARCHAR(10),
        RekinaNumurs NVARCHAR(50),
        KlientaKods NVARCHAR(50),
        KlientaVards NVARCHAR(100),
        Epasts NVARCHAR(100),
        Valoda NVARCHAR(10),
        KopejaisSaldo NVARCHAR(50),
        Objekts NVARCHAR(510),
        IrApstiprinats NVARCHAR(10),
        SubjectEmail NVARCHAR(MAX),
        AttachmentUrl NVARCHAR(MAX),
        AttachmentName NVARCHAR(MAX),
        EmailBody NVARCHAR(MAX),
        CountInEvents INT
    );

    -- Insert data into temporary table
    INSERT INTO #TempClientData
    SELECT 
        CONVERT(NVARCHAR(10), ROW_NUMBER() OVER (ORDER BY a.number)) AS RN,
        CONVERT(NVARCHAR(50), a.number) AS RekinaNumurs,
        a.klient_kood AS KlientaKods,
        a.klient_nimi AS KlientaVards,
        ISNULL((SELECT email FROM kliendid WHERE kood = a.klient_kood), 'N/A') AS Epasts,
        ISNULL((SELECT keel FROM kliendid WHERE kood = a.klient_kood), 'LV') AS Valoda,
        CONVERT(NVARCHAR(50), a.saldo) AS KopejaisSaldo,
        a.objekt AS Objekts,
        CASE WHEN a.kinnitatud = 1 THEN 'jā' ELSE 'nē' END AS IrApstiprinats,
        @subjectEmail AS SubjectEmail,
        REPLACE(@attachmentUrl, 'rekinsnr', CONVERT(NVARCHAR(MAX), a.number)) AS AttachmentUrl,
        a.klient_nimi + '_' + CONVERT(NVARCHAR(MAX), a.number) + N' rēķins.pdf' AS AttachmentName,
        REPLACE(REPLACE(@emailTxt, '@firmaninimi', @companyName), '@firmaemail', @firmaemail) AS EmailBody,
        ISNULL((SELECT COUNT(*) FROM events WHERE sisu = 'Invoice' AND src_number = CONVERT(NVARCHAR(64), a.number) AND src_unit = 'arve'), 0) AS CountInEvents
    FROM 
        mr_arved a
    WHERE 
        ISNULL(a.saldo, 0) <> 0 
        AND a.ts BETWEEN @aeg1 AND @aeg2
        AND (@obj IS NULL OR a.objekt = @obj)
        AND (@paymentTerm IS NULL OR a.tingimus = @paymentTerm)
        AND (@isApproved = 0 OR (@isApproved = 1 AND a.kinnitatud = 1))
        AND NOT EXISTS (SELECT 1 FROM events e WHERE e.src_number = CONVERT(NVARCHAR(64), a.number) AND e.src_unit = 'arve' AND e.sisu = 'Invoice');


    -- Always display client data

    -- Declare a variable to store the total count
    DECLARE @TotalCount INT;

    -- Calculate the total count and store it in the variable
    SELECT @TotalCount = COUNT(*) FROM #TempClientData;

    -- Display the total count as a "Kopā" row in one column
    SELECT 'Kopā: ' + CAST(@TotalCount AS NVARCHAR(10)) + ' ieraksti';


    SELECT 
        RN,
        RekinaNumurs,
        KlientaKods,
        KlientaVards,
        Epasts,
        Valoda,
        KopejaisSaldo,
        Objekts,
        IrApstiprinats
    FROM #TempClientData;

    IF @sendEmails = 1
    BEGIN
        DECLARE @EmailsSent INT = 0;

        -- Insert into events table
        INSERT INTO events (tyyp, status, sisu, k_email, aeg1, ts, aeg_loodud, cu, looja, feedback, src_number, src_unit)
        SELECT 
            'MAIL',
            'SENT',
            'Invoice',
            CASE WHEN @testMode = 1 THEN @testEmail ELSE Epasts END,
            GETDATE(),
            GETDATE(),
            GETDATE(),
            'Debt reminder',
            'Debt reminder',
            SubjectEmail,
            RekinaNumurs,
            'arve'
        FROM #TempClientData 
        WHERE CountInEvents = 0;

        SET @EmailsSent = @@ROWCOUNT;

        -- Insert into mail_out table
        INSERT INTO mail_out (from_email, from_nimi, to_email, subjekt, ts, cu, manuse_url, manuse_nimi, sisu)
        SELECT 
            @firmaemail,
            @companyName,
            CASE WHEN @testMode = 1 THEN @testEmail ELSE Epasts END,
            SubjectEmail,
            GETDATE(),
            'AIM',
            AttachmentUrl,
            AttachmentName,
            EmailBody
        FROM #TempClientData
        WHERE CountInEvents = 0 AND (@testMode = 1 OR Epasts != 'N/A');

        -- Modified result message as requested
        SELECT CAST(@EmailsSent AS NVARCHAR(10)) + ' E-pasti ir sagatavoti nosūtīšanai' AS Result;
    END

    -- Clean up
    DROP TABLE #TempClientData;
END;
