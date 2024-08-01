SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[int_hooldus_klient_send_payment_reminder_emails]
    @aeg1 DATETIME,
    @aeg2 DATETIME,
    @obj NVARCHAR(510) = NULL,
    @paymentTerm NVARCHAR(64) = NULL,
    @isApproved BIT = NULL,
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
            @testEmail NVARCHAR(100) = 'balodis.madars@gmail.com',
            @attachmentName NVARCHAR(MAX); -- Declare the variable

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
        EmailBody NVARCHAR(MAX)
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
        a.klient_nimi + '_' + CONVERT(NVARCHAR(MAX), a.number) + N' rekins.pdf' AS AttachmentName,
        REPLACE(REPLACE(@emailTxt, '@firmaninimi', @companyName), '@firmaemail', @firmaemail) AS EmailBody
    FROM 
        mr_arved a
    WHERE 
        ISNULL(a.saldo, 0) <> 0 
        AND a.ts BETWEEN @aeg1 AND @aeg2
        AND (@obj IS NULL OR a.objekt = @obj)
        AND (@paymentTerm IS NULL OR a.tingimus = @paymentTerm)
        AND (@isApproved IS NULL OR (@isApproved = 1 AND a.kinnitatud = 1) OR (@isApproved = 0 AND (a.kinnitatud = 0 OR a.kinnitatud IS NULL)));

    -- Always display client data
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

    -- Insert into mail_out table instead of sending emails
    INSERT INTO mail_out (from_email, from_nimi, to_email, subjekt, ts, cu, manuse_url, manuse_nimi, sisu)
    SELECT 
        @firmaemail,      -- From email
        @companyName,     -- From name
        'balodis.madars@gmail.com', -- To email (Replace with actual email variable if needed)
        @subjectEmail,    -- Subject of the email
        GETDATE(),        -- Timestamp of the insertion
        'AIM',            -- Custom user or identifier
        AttachmentUrl,    -- Attachment URL
        AttachmentName,   -- Attachment name
        EmailBody         -- Email body/content
    FROM #TempClientData;

    -- Clean up
    DROP TABLE #TempClientData;
END;



select * from mail_out order by ts desc
