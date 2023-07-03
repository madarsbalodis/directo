USE [ocra_demo_madars_lv]
GO

/****** Object:  StoredProcedure [dbo].[int_hooldus_klientedsimport]    Script Date: 03/07/2023 09:45:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







--insert int_hooldus_klient (rn, nimi, tyyp, aru_tyyp) values ('edsimport', N'EDS faila imports', 'import', 'personal')
--insert int_hooldus_klient_params (aru_id, nimi, tyyp, order_no) values ('edsimport', 'Darbība', N'1|Aplūkot importējamos datus,2|Aplūkot un importēt', 20)
ALTER  procedure  
[dbo].[int_hooldus_klientedsimport]  @aeg1 datetime, @aeg2 datetime ,@key nvarchar(max), @do nvarchar(3)
as  
if (object_id('tempdb..#kasutajad_maksud') is not null)
								begin
									drop table #kasutajad_maksud
								end
Declare @datenow DATETIME
set @datenow = getdate()
--SELECT * from int_import_dat where cu=@key
declare @t as table (x xml)
--declare @t2 as table (x xml)
--declare @t3 as table (x xml)
--declare @t4 as table (x xml)
--declare @t5 as table (x xml)

-- select * from int_import_dat
insert into @t 
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu=@key
create table #kasutajad_maksud (kood nvarchar(32),valem nvarchar(32),rn int, algus datetime,maksuvaba decimal(15,2),lopp datetime,mv_algus datetime,mv_lopp datetime, exist int,ttype nvarchar(32), existPrev int, prevendDate datetime, prevenddate2 datetime)
create table #kasutajad_maksud_insert_update (kood nvarchar(32),valem nvarchar(32),rn int, algus datetime,maksuvaba decimal(15,2),lopp datetime,mv_algus datetime,mv_lopp datetime, exist int,ttype nvarchar(32), existPrev int, prevendDate datetime, prevenddate2 datetime)

create table #XMLRECORDS (perCode nvarchar(20),recordValueTxt nvarchar(255),recordValueDecimal decimal(15,4), StartDate datetime,EndDate datetime,RecordType nvarchar(32),DirCode nvarchar(32), closed int,NGRA int, APG int,papatviegl nvarchar(255),papatvStartDate datetime,papatvEndDate datetime, progressIIN nvarchar(255),progressIINStartDate datetime,progressIINEndDate datetime,taxCombCode nvarchar(255),taxCombConf int,confIIN nvarchar(32),confSocDN nvarchar(32),confSocDD nvarchar(32), confUDR nvarchar(32), userStartDate datetime)


insert #XMLRECORDS (perCode,recordValueTxt,StartDate,RecordType)
SELECT 
tab.col.value('pers_kods[1]', 'nvarchar(255)') AS pers_code 
--,tab.col.value('vards_uzvards[1]', 'nvarchar(255)') AS vards_uzvards 
,tab.col.value('numurs_reg[1]', 'nvarchar(255)') as apl_reg_nr 
,tab.col.value('datums_izd[1]', 'datetime') as izd_dat
--,'XML' as objekts
--,'1' as personals
,'NGRA' as RecType
FROM @t 
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv') tab(col)

-- test
;WITH Records AS (
  SELECT 
  tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code 
  ,tab.col.value('summa[1]', 'decimal(15,2)') as neapliekams_summa
  ,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
  ,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
  ,'PPNM' as record_type
  FROM @t
  CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/prognozetie_mnm/prognozetais_mnm') tab(col)
),
RankedRecords AS (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY pers_code ORDER BY date1) AS rn
  FROM Records
)
INSERT INTO #XMLRECORDS (perCode, recordValueDecimal, StartDate, EndDate, RecordType)
SELECT 
  pers_code, 
  neapliekams_summa, 
  CASE WHEN rn = 1 THEN date1 ELSE DATEADD(DAY, 1, EOMONTH(LAG(date2) OVER(PARTITION BY pers_code ORDER BY date1))) END, 
  date2, 
  record_type
FROM RankedRecords

--insert #XMLRECORDS (perCode,recordValueDecimal,StartDate,EndDate,RecordType)
--SELECT 
--tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code 
--,tab.col.value('summa[1]', 'decimal(15,2)') as neapliekams_summa
--,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
--,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
--,'PPNM'
--FROM @t
--CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/prognozetie_mnm/prognozetais_mnm') tab(col)


insert #XMLRECORDS (perCode,recordValueDecimal,StartDate,EndDate,RecordType)
select isikukood,0,NULL,NULL,'PPNMB' from kasutajad where kood not in (select kood from kasutajad_maksud) and kood not in (select DirCode from #XMLRECORDS) and personal='1'



insert #XMLRECORDS (perCode,recordValueTxt,StartDate,EndDate,RecordType)
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code
,tab.col.value('veids[1]', 'nvarchar(255)') as veids
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
,'PP'
FROM @t
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/pensijas/pensija') tab(col)

/*
insert #XMLRECORDS (perCode,recordValueTxt,StartDate,EndDate,RecordType)
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code
,tab.col.value('veids[1]', 'nvarchar(255)') as veids
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
,'AL'
FROM @t
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/papildu_atvieglojumi/papildu_atvieglojums') tab(col)

*/
insert #XMLRECORDS (perCode,recordValueTxt,StartDate,EndDate,RecordType)
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code
,tab.col.value('veids[1]', 'nvarchar(255)') as veids
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,isnull(tab.col.value('datums_lidz[1]', 'nvarchar(255)'),'2100-31-12') as date2
,'AL'
FROM @t
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/papildu_atvieglojumi/papildu_atvieglojums') tab(col)


insert #XMLRECORDS (perCode,recordValueTxt,StartDate,EndDate,RecordType)
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code
,tab.col.value('veids[1]', 'nvarchar(255)') as veids
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
,'PPROGIIN'
FROM @t
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/pazime_progr_iin_likmes/pazime_progr_iin_likme') tab(col)
select perCode,(select kood from kasutajad where isikukood=a.perCode) dirCode, 0 as closed into #PerDirReg from #XMLRECORDS a group by perCode
update #PerDirReg set closed=isnull((select suletud from kasutajad where kood=dirCode),0)

update #XMLRECORDS set EndDate='2099-12-31' where year(EndDate)='1900'
update #XMLRECORDS set DirCode=(select DirCode from #PerDirReg a where a.perCode=#XMLRECORDS.perCode) , closed=(select closed from #PerDirReg a where a.perCode=#XMLRECORDS.perCode)


update #XMLRECORDS set NGRA=(select count(*) from kasutajad_dokumendid  where tyyp='NGRA' and dokument=#XMLRECORDS.recordValueTxt and kasutaja=#XMLRECORDS.DirCode) where RecordType='NGRA' 

if (select count(*) from #XMLRECORDS where RecordType='NGRA' and NGRA=0 and closed=0 and isnull(DirCode,'')!='') >=1
	begin
		insert kasutajad_dokumendid (KASUTAJA,tyyp,dokument,aeg1)
		select DirCode,RecordType,recordValueTxt,cast(StartDate as date) from #XMLRECORDS where RecordType='NGRA' and NGRA=0 and closed=0 and isnull(DirCode,'')!=''
	end
update #XMLRECORDS set APG=(select count(*) from kasutajad_isikud  where tyyp='APG' and nimi=#XMLRECORDS.recordValueTxt and kasutaja=#XMLRECORDS.DirCode) where RecordType='APG' 
if (select count(*) from #XMLRECORDS where RecordType='APG' and APG=0 and closed=0 and isnull(DirCode,'')!='') >=1
	begin
		insert kasutajad_isikud (KASUTAJA,tyyp,nimi,aeg1,aeg2,aktiivne)
		select DirCode,RecordType,recordValueTxt,cast(StartDate as date),cast(EndDate as date),1 from #XMLRECORDS where RecordType='APG' and APG=0 and closed=0 and isnull(DirCode,'')!=''
	end
delete from #XMLRECORDS where ngra>=1
delete from #XMLRECORDS where apg>=1
select perCode, (select count(StartDate) from #XMLRECORDS where RecordType in ('PPNM') and #XMLRECORDS.perCode=a.perCode),(select count(StartDate) from #XMLRECORDS where RecordType in ('PPROGIIN') and #XMLRECORDS.perCode=a.perCode) from #XMLRECORDS a  where RecordType in ('PPNM','PPROGIIN') and 1=2 group by perCode
--select * from #XMLRECORDS where perCode='01109310219'
update #XMLRECORDS set 
							papatviegl=(select recordValueTxt from #XMLRECORDS a where a.perCode=#XMLRECORDS.perCode and RecordType='AL' and cast(#xmlrecords.startDate as date) between cast(a.startDate as date) and cast(a.EndDate as date))
							,	papatvStartDate=(select StartDate from #XMLRECORDS a where a.perCode=#XMLRECORDS.perCode and RecordType='AL' and cast(#xmlrecords.startDate as date) between cast(a.startDate as date) and cast(a.EndDate as date))
						,	papatvEndDate=(select EndDate from #XMLRECORDS a where a.perCode=#XMLRECORDS.perCode and RecordType='AL' and cast(#xmlrecords.startDate as date) between cast(a.startDate as date) and cast(a.EndDate as date))

where RecordType in ('PPNM')
update #XMLRECORDS set 
							progressIIN=(select recordValueTxt from #XMLRECORDS a where a.perCode=#XMLRECORDS.perCode and RecordType='PPROGIIN' and cast(#xmlrecords.endDate as date) between cast(a.startDate as date) and cast(a.EndDate as date))
						,	progressIINStartDate=(select StartDate from #XMLRECORDS a where a.perCode=#XMLRECORDS.perCode and RecordType='PPROGIIN' and cast(#xmlrecords.endDate as date) between cast(a.startDate as date) and cast(a.EndDate as date))
						,	progressIINEndDate=(select EndDate from #XMLRECORDS a where a.perCode=#XMLRECORDS.perCode and RecordType='PPROGIIN' and cast(#xmlrecords.endDate as date) between cast(a.startDate as date) and cast(a.EndDate as date))
where RecordType in ('PPNM') and progressIIN is null


update #XMLRECORDS set progressIIN='PPNMB' where RecordType='PPNMB'

update #XMLRECORDS set taxCombCode=isnull(papatviegl,'')+'['+isnull(progressIIN,'')+']' where RecordType in ('PPNM','PPNMB','PPROGIIN')
update #XMLRECORDS set taxCombConf=isnull((select kood from uuringud_read where sisu=taxCombCode),0) where RecordType in ('PPNM','PPNMB','PPROGIIN')
update #XMLRECORDS set 
							confUDR=isnull((select sisu from uuringud_read where kood=taxCombConf and field='UDR'),'')
						,	confSocDD=isnull((select sisu from uuringud_read where kood=taxCombConf and field='SOC_DD'),'') 
						,	confSocDN=isnull((select sisu from uuringud_read where kood=taxCombConf and field='SOC_DN'),'') 
						,	confIIN=isnull((select sisu from uuringud_read where kood=taxCombConf and field='IIN'),'') 
						,	userStartDate=(select aeg_saabus from kasutajad where kood=DirCode)
where RecordType in ('PPNM','PPNMB','PPROGIIN')
DECLARE @POSxml NVARCHAR(32)

declare @mergedComment nvarchar(255)
declare raso_invoice cursor for select distinct perCode,DirCode from #XMLRECORDS where RecordType in ('PPNM','PPNMB','PPROGIIN')
			open raso_invoice
				FETCH NEXT FROM raso_invoice INTO @mergedComment,@POSxml
					WHILE @@FETCH_STATUS = 0
						begin			
						
					/*if (select count(*) from #XMLRECORDS where perCode=@mergedComment and DirCode=@POSxml and RecordType in ('PPNM'))=1
							begin*/
								select row_number() over(order by perCode,StartDate,DirCode,closed,NGRA,APG,papatviegl,progressIIN,progressIINStartDate,progressIINEndDate,taxCombCode,taxCombConf,confIIN,confSocDN,confSocDD,confUDR) as #,perCode,recordValueDecimal,StartDate,EndDate,DirCode,closed,NGRA,APG,papatviegl,papatvStartDate,papatvEndDate,progressIIN,progressIINStartDate,progressIINEndDate,taxCombCode,taxCombConf,confIIN,confSocDN,confSocDD,confUDR,userStartDate userEndDate into #dataset from #XMLRECORDS where percode=@mergedComment and  RecordType in ('PPNM','PPNMB','PPROGIIN') order by StartDate
							--	select * from #dataset

				--			if(select 1 from #dataset where #=1 and startDate < progressIINStartDate)=1
						--			select dircode,'IINBEZGR',NULL,dateadd(d,-1,progressIINStartDate) from #dataset where #=1
							select 
											DirCode,
											confIIN,
											1 as rn,
											recordValueDecimal as maksuvaba,
											--iif(#=1,startDate,iif(isnull(papatviegl,'')!='',papatvstartDate,isnull(progressIINstartDate,startDate))) as algus,
											startdate as algus,
											enddate as lopp,
											(select dateadd(dd,-(day(startDate)-1),startDate) ) montdaystart,
											(select dateadd(s,-1,dateadd(mm,datediff(m,0,EndDate)+1,0))) montdayend,
											datediff(d,startdate,enddate) as z,
											convert(nvarchar(max),month(startdate))+'-'+convert(nvarchar(max),year(startDate)) a,
											convert(nvarchar(max),month(EndDate))+'-'+convert(nvarchar(max),year(EndDate)) b,
											cast(0 as decimal(15,0)) daydifference,
											(select recordValueDecimal from #dataset where #=a.#+1) nextval,
											iif(isnull(papatviegl,'')!='',papatvstartDate,progressIINstartDate) as mv_algus,
											iif(isnull(papatviegl,'')!='',papatvEndDate,progressIINEndDate) as mv_lopp,
											# as rn1,
											iif(recordValueDecimal > 0,EndDate,NULL) enddate2 into #dataset2 from #dataset a

											update #dataset2 set daydifference=isnull((select sum(z) from #dataset2 a where a.maksuvaba=#dataset2.maksuvaba and a.rn1 < #dataset2.rn1),0)
											update #dataset2 set mv_algus=dateadd(d,iif(daydifference=0,0,daydifference*(-1)),iif(mv_algus is not null,mv_algus,algus))

insert #kasutajad_maksud (kood,valem, rn,algus,maksuvaba,lopp,mv_algus,mv_lopp,ttype)
select DirCode as kood,confIIN as valem,1 as rn, cast(montdaystart as date) as algus,maksuvaba,cast(montdayend as date) as lopp, iif(mv_algus<montdaystart,montdaystart,mv_algus), isnull(mv_lopp,lopp) as mv_lopp,'IIN' from #dataset2


insert #kasutajad_maksud (kood,valem, rn,ttype)
select top 1 DirCode as kood,confSocDD as valem,1 as rn,'SOCDD' from #dataset

insert #kasutajad_maksud (kood,valem, rn,ttype)
select top 1 DirCode as kood,confSocDN as valem,1 as rn,'SOCDN' from #dataset order by rn asc

insert #kasutajad_maksud (kood,valem, rn,ttype)
select top 1 DirCode as kood,confUDR as valem,1 as rn,'UDR' from #dataset order by rn asc



							if (object_id('tempdb..#dataset') is not null)
								begin
									drop table #dataset
								end
							if (object_id('tempdb..#dataset2') is not null)
								begin
									drop table #dataset2
								end
								FETCH NEXT FROM raso_invoice INTO @mergedComment,@POSxml
								END 
						CLOSE raso_invoice
						DEALLOCATE raso_invoice
--select * from #XMLRECORDS where RecordType in ('PPNM','PPROGIIN') order by perCode,StartDate
-- 

update #kasutajad_maksud set exist=(select count(*) from kasutajad_maksud where kood=#kasutajad_maksud.kood and valem=#kasutajad_maksud.valem and rn=#kasutajad_maksud.rn and algus=#kasutajad_maksud.algus and maksuvaba=#kasutajad_maksud.maksuvaba and lopp=#kasutajad_maksud.lopp and mv_algus=#kasutajad_maksud.mv_algus and lopp=#kasutajad_maksud.lopp) WHERE TTYPE='IIN'
UPDATE #kasutajad_maksud SET existPrev = (select count(*)  FROM KASUTAJAD_MAKSUD WHERE VALEM=#kasutajad_maksud.VALEM AND KOOD=#kasutajad_maksud.KOOD AND MV_ALGUS = #kasutajad_maksud.mv_algus AND MV_LOPP!=#kasutajad_maksud.mv_lopp)

update #kasutajad_maksud set prevendDate = iif(existPrev=1,(select mv_lopp  FROM KASUTAJAD_MAKSUD WHERE VALEM=#kasutajad_maksud.VALEM AND KOOD=#kasutajad_maksud.KOOD AND MV_ALGUS = #kasutajad_maksud.mv_algus AND MV_LOPP!=#kasutajad_maksud.mv_lopp),NULL),prevendDate2 = iif(existPrev=1,(select lopp  FROM KASUTAJAD_MAKSUD WHERE VALEM=#kasutajad_maksud.VALEM AND KOOD=#kasutajad_maksud.KOOD AND MV_ALGUS = #kasutajad_maksud.mv_algus AND LOPP!=#kasutajad_maksud.lopp),NULL)

update #kasutajad_maksud set exist=(select count(*) from kasutajad_maksud where kood=#kasutajad_maksud.kood and valem=#kasutajad_maksud.valem and rn=#kasutajad_maksud.rn) WHERE TTYPE!='IIN'

--SELECT * FROM kasutajad_maksud WHERE KOOD='D03377' AND VALEM='iin' AND LOPP>'2023-01-01'

select *  into #kasutajad_maksud_insert from #kasutajad_maksud where exist=0 and kood not in (select kood from #kasutajad_maksud where existPrev >= 1)
insert #kasutajad_maksud_insert_update
select * from #kasutajad_maksud where existPrev>=1 
insert #kasutajad_maksud_insert_update
select * from #kasutajad_maksud where exist=0  and existPrev=0 and  kood in (select kood from #kasutajad_maksud_insert_update)

select * from #XMLRECORDS

select N'<h1>Pievienojamie ieraksti</h1><table width="100%" border="1"><tr><th colspan="4"></th><th colspan="3" align="center">Neapliekams</th></tr><tr><th>Directo kods</th><th>nodokļu formula</th><th>Sākums</th><th>Beigas</th><th>Summa</th><th>Sākums</th><th>Beigas</th></tr>'+CAST ( ( SELECT --td = a.number, '',
					td = a.kood, '',
					td = a.valem, '',
					td = a.algus, '',
					td = a.lopp, '',
					td = a.maksuvaba, '',
					td = a.mv_algus, '',
					td = a.mv_lopp
               from #kasutajad_maksud_insert a where a.kood is not null
              FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) ) +  
    N'</table>' ;
	select N'<h1>Atjaunojamie ieraksti</h1><table width="100%" border="1"><tr><th colspan="4"></th><th colspan="3" align="center">Neapliekams</th></tr><tr><th>Directo kods</th><th>nodokļu formula</th><th>Sākums</th><th>Beigas</th><th>Summa</th><th>Sākums</th><th>Beigas</th></tr>'+CAST ( ( SELECT --td = a.number, '',
					td = a.kood, '',
					td = a.valem, '',
					td = a.algus, '',
					td = a.lopp, '',
					td = a.maksuvaba, '',
					td = a.mv_algus, '',
					td = a.mv_lopp, '',
					TD = A.existPrev, '',
					td = a.prevendDate,'',
					td = a.prevendDate2
               from #kasutajad_maksud_insert_update a where a.kood is not null order by a.kood, existPrev desc
              FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) ) +  
    N'</table>' ;
	select N'<h1>Eksistējošie ieraksti</h1><table width="100%" border="1"><tr><th colspan="4"></th><th colspan="3" align="center">Neapliekams</th></tr><tr><th>Directo kods</th><th>nodokļu formula</th><th>Sākums</th><th>Beigas</th><th>Summa</th><th>Sākums</th><th>Beigas</th></tr>'+CAST ( ( SELECT --td = a.number, '',
					td = a.kood, '',
					td = a.valem, '',
					td = a.algus, '',
					td = a.lopp, '',
					td = a.maksuvaba, '',
					td = a.mv_algus, '',
					td = a.mv_lopp
               from #kasutajad_maksud a where exist >=1
              FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) ) +  
    N'</table>' ;

if @do=2
begin
insert kasutajad_maksud (kood,valem, rn,algus,maksuvaba,lopp,mv_algus,mv_lopp)
select kood,valem, rn,algus,maksuvaba,lopp,mv_algus,mv_lopp from #kasutajad_maksud where exist=0

end
SELECT * FROM #XMLRECORDS WHERE DirCode='D02883'
drop table #PerDirReg
drop table #XMLRECORDS 

-- delete from kasutajad_maksud


delete from int_import_dat where dat like '%NM_e_gramatina%' and cu=@key


select N'Darīts'

GO


