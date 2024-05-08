SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--insert int_hooldus_klient (rn, nimi, formaat, filename) values ('_transakcijas', 'Transakciju saraksts', 'xls', 'transakcijas.xls')

ALTER PROCEDURE [dbo].[int_hooldus_klient_transakcijas2] @aeg1 datetime, @aeg2 datetime AS
declare @caeg2 datetime, @aegfill datetime
set @caeg2 = (select dateadd(ms,-3,dateadd(day,1,DATEADD(dd, DATEDIFF(dd,0,@aeg2), 0))))
set @aeg2 = (select @caeg2)
 SET @aegfill = getdate()
--added customer/supplier name
--added project name
declare @object0 nvarchar(32), @object1 nvarchar(32), @object2 nvarchar(32), @object3 nvarchar(32), @object4 nvarchar(32), @object5 nvarchar(32), @object6 nvarchar(32)

declare @transactions TABLE
(

document int,
doc_type nvarchar(255),
created nvarchar(255),
doc_description nvarchar(255),
-- doc_date date,
test_date date,
invoice_date date,
created_date date,
account nvarchar(32),
account_name nvarchar(255),
supplier nvarchar(32),
supplier_name nvarchar(255),
project nvarchar(255),
project_name nvarchar(255),
object nvarchar(255),
object0 nvarchar(255),
object1 nvarchar(255),
object2 nvarchar(255),
object3 nvarchar(255),
object3n nvarchar(255),
object4 nvarchar(255),
object5 nvarchar(255),
object6 nvarchar(255),
debet decimal(15,4),
credit decimal(15,4),
date_in_row date,
invoice_no nvarchar(255),
klass int
)

-- select * from fin_kanded where number = '1028313'

insert @transactions
SELECT fin_kanded.number AS dokumenta_nr
--, (CASE WHEN (fin_kanded.tyyp='KULUT') THEN ('EXPENSE') WHEN (fin_kanded.tyyp='INV') THEN ('INVENTORY') WHEN (fin_kanded.tyyp='ARVE') THEN ('INVOICE') WHEN (fin_kanded.tyyp='PER_TASU') THEN ('SALARY PAYMENT') WHEN (fin_kanded.tyyp='VMAKS') THEN ('EXPENSE DUE') WHEN (fin_kanded.tyyp='OST') THEN ('PURCHASE') WHEN (fin_kanded.tyyp='LAEK') THEN ('RECEIPT') WHEN (fin_kanded.tyyp='PALK') THEN ('PERSONAL SALARY') WHEN (fin_kanded.tyyp='LS') THEN ('STOCK RECEIPT') WHEN (fin_kanded.tyyp='FIN') THEN ('TRANSACTION') ELSE (CASE WHEN (fin_kanded.tyyp!='KULUT' OR fin_kanded.tyyp='inv' OR fin_kanded.tyyp!='ARVE' OR fin_kanded.tyyp!='PER_TASU' OR fin_kanded.tyyp!='VMAKS' OR fin_kanded.tyyp!='OST' OR fin_kanded.tyyp!='LAEK' OR fin_kanded.tyyp!='PALK' OR fin_kanded.tyyp!='LS' OR fin_kanded.tyyp!='FIN') THEN ('TRANSACTION') END) END) as dokumenta_veids
--,fin_kanded.tyyp as dok_veids
,(select top 1 sisu from int_keel where kood=(select 'kanne_'+fin_kanded.tyyp) and keel='LV') as dok_veids
, looja AS Izveidoja
, substring(seletus,1,255) AS Apraksts_no_transakcijas
, CAST(CAST(aeg AS date) AS date) [Grāmatojuma datums]
, CAST(CAST(r_aeg AS date) AS date) [Rēķina datums]
-- , CAST('2024-01-1993' AS date) [Rēķina datums]
, CAST(CAST(aeg AS date) AS date) AS [Apstrādes datums]
, konto as Konts8
, FIN_KONTOD.NIMI AS Konta_nosaukums
,(CASE WHEN (hankija IS NOT NULL) THEN (SELECT (SELECT TOP 1 kood FROM hankijad WHERE hankijad.kood=hankija)) ELSE (CASE WHEN (klient IS NOT NULL) THEN (SELECT (SELECT TOP 1 kood FROM kliendid WHERE kliendid.kood=klient)) END) END) as Piegādātājs
,(CASE WHEN (hankija IS NOT NULL) THEN (SELECT (SELECT TOP 1 nimi FROM hankijad WHERE hankijad.kood=hankija)) ELSE (CASE WHEN (klient IS NOT NULL) THEN (SELECT (SELECT TOP 1 nimi FROM kliendid WHERE kliendid.kood=klient)) END) END) as Piegādātājs

, fin_kanded_read.projekt as projekts
, (select top 1 nimi from projektid where kood=fin_kanded_read.projekt)
, objekt AS Objekts

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='0') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='0') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt0

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='1') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='1') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt1
, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='2') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='2') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt2

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='3') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='3') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt3

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='3') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select nimi from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='3') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt3n

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='4') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select kood from fin_objektid_tasemed where tase='4') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt4

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='5') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='5') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt5

, case when (isnull((select count(kood) from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='6') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'') <= 1) then (isnull((select kood from fin_objektid where tyyp in (select nimi from fin_objektid_tasemed where tase='6') AND (fin_kanded_read.objekt LIKE ''+kood+',%' or fin_kanded_read.objekt LIKE ''+kood+'' or fin_kanded_read.objekt LIKE '%,'+kood+',%' or fin_kanded_read.objekt LIKE '%,'+kood+'' or fin_kanded_read.objekt=kood)),'')) else ('<font style="color:red"><b>More than one object<b></font>') end as objekt6

,(CASE WHEN (baas1deebet IS NOT NULL or baas1deebet >= 0.0000001) THEN baas1deebet END) AS Debeta_summa
, (CASE WHEN (baas1kreedit IS NOT NULL or baas1kreedit >= 0.0000001) THEN baas1kreedit END) AS Kredīta_summa
, r_aeg as rindas_datums
, isnull(case 
                when (fin_kanded.tyyp='LS') then (select top 1 hankija_arve from ladu_sissetulekud where number=fin_kanded.number)
                when (fin_kanded.tyyp='OST') then (select top 1 hankija_arve from or_arved where number=fin_kanded.number)
        end,'')
, fin_kontod.klass
FROM fin_kanded_read WITH (NOLOCK) 
INNER JOIN fin_kanded ON (fin_kanded_read.number=fin_kanded.number) and (fin_kanded.tyyp=fin_kanded_read.tyyp) 
inner join FIN_KONTOD on FIN_KONTOD.KOOD=FIN_KANDED_READ.KONTO 
WHERE 
CAST(r_aeg AS date) BETWEEN CAST(@aeg1 AS date) AND CAST(@aeg2 AS date)
-- AND NOT (konto >= '0' AND konto <= '599999')
AND fin_kontod.klass NOT IN (0, 1, 2, 5) -- Exclude accounts with klass 0, 1, 2, 5
AND fin_kontod.klass IN (3, 4)
ORDER by AEG2 DESC
-- WHERE 
-- CAST(r_aeg AS date) BETWEEN CAST(@aeg1 AS date) AND CAST(@aeg2 AS date)
-- ORDER by AEG2  DESC

set @object0 = (select count(object0) from @transactions where object0 is not null)
set @object1 = (select count(object1) from @transactions where object0 is not null)
set @object2 = (select count(object2) from @transactions)
set @object3 = (select count(object3) from @transactions)
set @object4 = (select count(object4) from @transactions)
set @object5 = (select count(object5) from @transactions)
set @object6 = (select count(object6) from @transactions)


SELECT 
    z.document AS [Dok. Nr.],
    z.doc_type AS [Dok. veids],
    z.created AS [Izveidoja],
    z.doc_description AS [Apraksts],
    z.test_date AS [Grāmatojuma datums], 
    z.invoice_date AS [Rēķina datums],
    z.created_date AS [Izveidošanas datums],
    z.account AS [Konts],
    z.account_name AS [Konta nosaukums],
    z.supplier AS [Piegādātājs/Klients],
    z.supplier_name AS [Piegādātāja/Klienta nosaukums],
    z.project AS [projekts],
    z.project_name AS [projekta nosaukums],
    z.OBJECT AS [Objekts],
    SUM(z.debet) AS [Debeta summa],
    SUM(z.credit) AS [Kredīta summa],
    CASE
        WHEN z.klass = 3 THEN COALESCE(SUM(z.credit), 0) - COALESCE(SUM(z.debet), 0)
        WHEN z.klass = 4 THEN COALESCE(SUM(z.debet), 0) - COALESCE(SUM(z.credit), 0)
        ELSE 0
    END AS [Summa]
FROM 
    @transactions z
WHERE 
    z.klass IN (3, 4)
GROUP BY
    z.document,
    z.doc_type,
    z.created,
    z.doc_description,
    z.test_date,
    z.invoice_date,
    z.created_date,
    z.account,
    z.account_name,
    z.supplier,
    z.supplier_name,
    z.project,
    z.project_name,
    z.OBJECT,
    z.klass
ORDER BY 
    z.invoice_date DESC, z.document DESC;


GO
