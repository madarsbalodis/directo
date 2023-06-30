USE [ocra_demo_madars_lv]
GO

/****** Object:  StoredProcedure [dbo].[int_hooldus_klientedsimport]    Script Date: 30/06/2023 16:40:36 ******/
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


insert #XMLRECORDS (perCode,recordValueTxt,StartDate,EndDate,RecordType)
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_kods
,tab.col.value('vards_uzvards[1]', 'nvarchar(255)') AS apg_vards_uzvards 
,tab.col.value('datums_no[1]', 'datetime') AS apg_sakums 
,tab.col.value('datums_lidz[1]', 'datetime') as apg_beigas 
,'APG'
FROM @t 
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/apgadajamie/apgadajamais') tab(col)



insert #XMLRECORDS (perCode,recordValueDecimal,StartDate,EndDate,RecordType)
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code 
,tab.col.value('summa[1]', 'decimal(15,2)') as neapliekams_summa
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
,'PPNM'
FROM @t
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/prognozetie_mnm/prognozetais_mnm') tab(col)

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
	--select * from kasutajad_maksud where kood in (select kood from #kasutajad_maksud_insert)
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
/*
insert into @t 
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat
declare @xml_data as table
(
pers_code nvarchar(255),
vards_uzvards nvarchar(255),
apl_reg_nr nvarchar(255),
izd_dat datetime,
objekts nvarchar(32),
personals nvarchar(32),
int_kods nvarchar(32),
directo_kods nvarchar(32),
inc_tax_free nvarchar(32),
inc_tax_freeb nvarchar(32),
closed nvarchar(32),
exist nvarchar(32),
lastrn decimal(15,0)
)
insert @xml_data
SELECT 
tab.col.value('pers_kods[1]', 'nvarchar(255)') AS pers_code 
,tab.col.value('vards_uzvards[1]', 'nvarchar(255)') AS vards_uzvards 
,tab.col.value('numurs_reg[1]', 'nvarchar(255)') as apl_reg_nr 
,tab.col.value('datums_izd[1]', 'datetime') as izd_dat
,'XML' as objekts
,'1' as personals
,tab.col.value('pers_kods[1]', 'nvarchar(255)') AS pers_code
,(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('pers_kods[1]', 'nvarchar(255)')) as directo_kods
,isnull((select meetod_tulumaks from kasutajad where replace(isikukood,'-','')=tab.col.value('pers_kods[1]', 'nvarchar(255)')),'1') as inc_tax_free
,'2'
,(select suletud from kasutajad where replace(isikukood,'-','')=tab.col.value('pers_kods[1]', 'nvarchar(255)')) as closed
,isnull((select top 1 'Yes' 
  from kasutajad_dokumendid 
  where 
  kasutaja=(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('pers_kods[1]', 'nvarchar(255)'))
  and tyyp='NGRA' and aeg1=tab.col.value('datums_izd[1]', 'datetime') and dokument=tab.col.value('numurs_reg[1]', 'nvarchar(255)')),'No')
,isnull((select max(rn) from kasutajad_dokumendid where kasutaja=(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('pers_kods[1]', 'nvarchar(255)'))),0)
FROM @t 
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv') tab(col)







insert into @t2
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat
declare @xml_data2 as table
(
	apg_vards_uzvards nvarchar(255)
	,apg_sakums datetime
	,apg_beigas datetime
	,ieregistrets datetime
	,pers_kods nvarchar(32)
	,directo_kods nvarchar(32)
	,closed nvarchar(32)
    ,exist nvarchar(32)
    ,lastrn decimal(15,0)
)
insert @xml_data2
SELECT 
tab.col.value('vards_uzvards[1]', 'nvarchar(255)') AS apg_vards_uzvards 
,tab.col.value('datums_no[1]', 'datetime') AS apg_sakums 
,tab.col.value('datums_lidz[1]', 'datetime') as apg_beigas 
,tab.col.value('datums_ier[1]', 'datetime') as ieregistrets
,tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_kods
,(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)')) as directo_kods
,(select suletud from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)')) as closed
,isnull(
    (select top 1 'Yes' 
  from kasutajad_isikud 
  where 
  kasutaja=(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)'))
  and tyyp='APG'
  and aktiivne='True'
  and nimi=tab.col.value('vards_uzvards[1]', 'nvarchar(255)')
   and aeg1=tab.col.value('datums_no[1]', 'datetime')
   and aeg2=tab.col.value('datums_lidz[1]', 'datetime'))
   
    ,'No')
    ,isnull((select max(rn) from kasutajad_isikud where kasutaja=(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('pers_kods[1]', 'nvarchar(255)'))),0)
FROM @t2 
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/apgadajamie/apgadajamais') tab(col)






insert into @t4
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat
declare @xml_data4 as table
(
pers_code nvarchar(255),
directo_code nvarchar(255),
date1 datetime,
date2 datetime,
neapliekams_summa decimal(15,2)
,closed nvarchar(32)
,rn nvarchar(10)
,rnd nvarchar(10)
)
insert @xml_data4
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code 
,(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)')) as directo_kods
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
,tab.col.value('summa[1]', 'decimal(15,2)') as neapliekams_summa
,(select suletud from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)')) as closed
,(select count(rn) from kasutajad_maksud  where kood=(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)'))) as rn
,(select count(rn) from kasutajad_maksud  where kood=(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)')) and valem='IIN2018' and algus=tab.col.value('datums_no[1]', 'nvarchar(255)') and lopp=tab.col.value('datums_lidz[1]', 'nvarchar(255)')  ) as rd
FROM @t4
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/prognozetie_mnm/prognozetais_mnm') tab(col)


--pensionari
insert into @t5
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat
declare @xml_data5 as table
(
pers_code nvarchar(255),
directo_code nvarchar(255),
date1 datetime,
date2 datetime,
veids nvarchar(255)
)
insert @xml_data5
SELECT 
tab.col.value('../../pers_kods[1]', 'nvarchar(255)') AS pers_code 
,(select kood from kasutajad where replace(isikukood,'-','')=tab.col.value('../../pers_kods[1]', 'nvarchar(255)')) as directo_kods
,tab.col.value('datums_no[1]', 'nvarchar(255)') as date1
,tab.col.value('datums_lidz[1]', 'nvarchar(255)') as date2
,tab.col.value('veids[1]', 'nvarchar(255)') as veids
FROM @t5
CROSS APPLY x.nodes('//nm_e_gramatinas/gigv/pensijas/pensija') tab(col)
if ((select count(pers_code) from @xml_data5)>0)
begin
declare @pens TABLE
(
  pers_code nvarchar(32),
  directo_code nvarchar(32),
  pensionars_dat1_reg datetime,
  pensionars_dat1_izd datetime,
  pensionars_dat2_izd datetime,
  pensionars_dat1_2gr datetime,
  pensionars_dat2_2gr datetime,
  pensionars_dat1_3gr datetime,
  pensionars_dat2_3gr datetime 
)
insert @pens
select 
  distinct pers_code
  , directo_code
  , (select top 1 date1 from @xml_data5 z where (z.veids=N'Pensionārs' or z.veids=N'Pensionārs (citas valsts)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat1_reg
  , (select top 1 date1 from @xml_data5 z where (z.veids=N'Pensija (izdienas pensijas saņēmēji)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat1_izd
  , (select top 1 date2 from @xml_data5 z where (z.veids=N'Pensija (izdienas pensijas saņēmēji)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat2_izd
   , (select top 1 date1 from @xml_data5 z where (z.veids=N'Pensijas saņēmējs (2. grupas invaliditāte)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat1_2gr
    , (select top 1 date2 from @xml_data5 z where (z.veids=N'Pensijas saņēmējs (2. grupas invaliditāte)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat2_2gr
      , (select top 1 date1 from @xml_data5 z where (z.veids=N'Pensijas saņēmējs (3. grupas invaliditāte)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat1_3gr
    , (select top 1 date2 from @xml_data5 z where (z.veids=N'Pensijas saņēmējs (3. grupas invaliditāte)')  and  z.pers_code=a.pers_code order by date1 desc) as pensionars_dat2_3gr
from @xml_data5 a 
group by pers_code,directo_code
select * from  @pens
select distinct veids from  @xml_data5

end

select top 1 N'<p align="center"><b>Nodokļu grāmatiņas dati</b><p>'

SELECT 'xml satur:<b>',count(pers_code),'ierakstus</b>' from @xml_data

SELECT 'xml nav atpazīti :<b>',count(pers_code),'ieraksti</b>' from @xml_data where directo_kods is null

--select * from @xml_data where directo_kods is not null
if ((select count(pers_code) from @xml_data where directo_kods is null)> 0 )
  begin
    select * from @xml_data where directo_kods is null
  end

select 'Pievienojami ieraksti:',count(pers_code), 'ieraksti' from @xml_data where closed is null and exist='No'

if ((select count(pers_code) from @xml_data where directo_kods is not null and closed is null and exist='No') > 0 )
  begin
    select * from @xml_data where directo_kods is not  null and closed is null and exist='No' 
  end

  select 'Eksistējoši ieraksti, kurus nemaina', count(pers_code), 'ieraksti' from @xml_data where (closed='1') or (closed is null and exist='Yes')

if ((select count(pers_code) from @xml_data where directo_kods is not null and (closed='1') or (closed is null and exist='Yes'))> 0 )
  begin
    select * from @xml_data where directo_kods is not  null and (closed='1') or (closed is null and exist='Yes')
  end




select top 1 N'<p align="center">Apgādājamās personas</p>' from @xml_data2
select 'XML satur', count(apg_vards_uzvards), 'ierakstus par apgādāmajām personām' from @xml_data2
--select * from @xml_data2
if ((select count(apg_vards_uzvards) from @xml_data2 where exist='No')>0)
BEGIN
select 'XML satur', count(apg_vards_uzvards), 'ierakstus par apgādāmajām personām, kuras nav iereģistrētas DIRECTO un darbinieks ir darba attiecībās' from @xml_data2 where exist='No' and closed is null
select * from @xml_data2 where exist='No' and closed is null
end
if ((select count(apg_vards_uzvards) from @xml_data2 where exist='No' and closed is not null)>0)
BEGIN
select 'XML satur', count(apg_vards_uzvards), 'ierakstus par apgādāmajām personām, kuras nav iereģistrētas DIRECTO un darbinieki nav darba attiecībās' from @xml_data2 where exist='No' and closed is not null
end
select 'Nav atjaunoti', count(pers_kods), 'ieraksti' from @xml_data2 where closed is null and exist='Yes'


select top 1 N'<p align="center">Neapliekamais minimums</p>' from @xml_data4
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu' from @xml_data4
IF ((select count(pers_code) from @xml_data4 where rnd='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras ir Directo, bet neapliekamis Min nav ievadīts' from @xml_data4 where rnd='0' and directo_code is not null and directo_code not in (select directo_code from @pens)
end
IF ((select count(pers_code) from @xml_data4 where rnd='0' and directo_code is null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav Directo, bet neapliekamis Min norādīts EDS' from @xml_data4 where rnd='0' and directo_code is null and directo_code not in (select directo_code from @pens)
end
IF ((select count(pers_code) from @xml_data4 where rnd!='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav nepieciešams atjaunot, jo Directo dati sakrīt ar EDS' from @xml_data4 where rnd!='0' and directo_code is not null and directo_code not in (select directo_code from @pens)
end
select * from @xml_data4 where rnd='0' and directo_code is not null and directo_code not in (select directo_code from @pens)
declare @regpens TABLE
(
pers_code nvarchar(32),
directo_code nvarchar(32),
datums datetime,
rnd decimal(15,0)
)
insert @regpens
select pers_code, directo_code, pensionars_dat1_reg,(select count(rn) from kasutajad_maksud  where kood=z.directo_code and valem='IIN_PENS') from @pens z where pensionars_dat1_reg	<= @datenow


select top 1 N'<p align="center">Neapliekamais minimums pensionāri</p>' from @regpens 
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu pensionāriem' from @regpens
select * from @regpens
IF ((select count(pers_code) from @regpens where rnd='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras ir Directo, bet neapliekamis Min nav ievadīts' from @regpens where rnd='0' and  directo_code is not null 
end
IF ((select count(pers_code) from @regpens where rnd='0' and directo_code is null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav Directo, bet neapliekamis Min norādīts EDS' from @regpens where rnd='0'and  directo_code is null 
end
IF ((select count(pers_code) from @regpens where rnd!='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav nepieciešams atjaunot, jo Directo dati sakrīt ar EDS' from @regpens where rnd!='0' and   directo_code is not null 
end

declare @izdpens TABLE
(
pers_code nvarchar(32),
directo_code nvarchar(32),
datums datetime,
datums2 datetime,
rnd decimal(15,0)
)
insert @izdpens
select pers_code
, directo_code
, pensionars_dat1_izd
, pensionars_dat2_izd
,(select count(rn) from kasutajad_maksud  where kood=z.directo_code and valem='IIN_PENS') from @pens z where (pensionars_dat1_izd	<= @datenow or pensionars_dat2_izd <= @datenow )


select top 1 N'<p align="center">Neapliekamais minimums izdienas pensionāri</p>' from @izdpens 
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu pensionāriem' from @izdpens
select * from @izdpens
IF ((select count(pers_code) from @izdpens where rnd='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras ir Directo, bet neapliekamis Min nav ievadīts' from @izdpens where rnd='0' and  directo_code is not null 
end
IF ((select count(pers_code) from @izdpens where rnd='0' and directo_code is null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav Directo, bet neapliekamis Min norādīts EDS' from @izdpens where rnd='0'and  directo_code is null 
end
IF ((select count(pers_code) from @izdpens where rnd!='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav nepieciešams atjaunot, jo Directo dati sakrīt ar EDS' from @izdpens where rnd!='0' and   directo_code is not null 
end


declare @pens1_2 TABLE
(
pers_code nvarchar(32),
directo_code nvarchar(32),
datums datetime,
datums2 datetime,
rnd decimal(15,0)
)
insert @pens1_2
select pers_code
, directo_code
, pensionars_dat1_2gr
, pensionars_dat2_2gr	
,(select count(rn) from kasutajad_maksud  where kood=z.directo_code and valem='IIN_INV_I_II') from @pens z where (pensionars_dat1_2gr	<= @datenow or pensionars_dat2_2gr <= @datenow )


select top 1 N'<p align="center">Neapliekamais minimums 1. un 2. grupas pensijas saņēmēji</p>' from @pens1_2 
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu pensionāriem' from @pens1_2
select * from @pens1_2
IF ((select count(pers_code) from @pens1_2 where rnd='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras ir Directo, bet neapliekamis Min nav ievadīts' from @pens1_2 where rnd='0' and  directo_code is not null 
end
IF ((select count(pers_code) from @pens1_2 where rnd='0' and directo_code is null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav Directo, bet neapliekamis Min norādīts EDS' from @pens1_2 where rnd='0'and  directo_code is null 
end
IF ((select count(pers_code) from @pens1_2 where rnd!='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav nepieciešams atjaunot, jo Directo dati sakrīt ar EDS' from @pens1_2 where rnd!='0' and   directo_code is not null 
end


declare @pens3 TABLE
(
pers_code nvarchar(32),
directo_code nvarchar(32),
datums datetime,
datums2 datetime,
rnd decimal(15,0)
)
insert @pens3
select pers_code
, directo_code
, pensionars_dat1_3gr
, pensionars_dat2_3gr	
,(select count(rn) from kasutajad_maksud  where kood=z.directo_code and valem='IIN_INV_III') from @pens z where (pensionars_dat1_3gr	<= @datenow or pensionars_dat2_3gr <= @datenow )


select top 1 N'<p align="center">Neapliekamais minimums 3 grupas pensijas saņēmēji</p>' from @pens3 
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu pensionāriem' from @pens3
select * from @pens3
IF ((select count(pers_code) from @pens3 where rnd='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras ir Directo, bet neapliekamis Min nav ievadīts' from @pens3 where rnd='0' and  directo_code is not null 
end
IF ((select count(pers_code) from @pens3 where rnd='0' and directo_code is null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav Directo, bet neapliekamis Min norādīts EDS' from @pens3 where rnd='0'and  directo_code is null 
end
IF ((select count(pers_code) from @pens3 where rnd!='0' and directo_code is not null )>0)
BEGIN
select 'XML satur', count(pers_code), N'ierakstus par neapliekamo minimumu, personām, kuras nav nepieciešams atjaunot, jo Directo dati sakrīt ar EDS' from @pens3 where rnd!='0' and   directo_code is not null 
end

if (@do='2')
--Pievieno Algas grāmatiņas datus--
BEGIN
insert kasutajad_dokumendid (kasutaja,dokument, aeg1, tyyp, rn)
select directo_kods,apl_reg_nr,izd_dat, 'NGRA',lastrn+1 from @xml_data where closed is null and exist='No' and directo_kods is not null

update kasutajad
set meetod_tulumaks=z.inc_tax_freeb
from (select directo_kods, inc_tax_freeb from @xml_data where (closed is null and exist='No' and directo_kods is not null)) z
WHERE
kasutajad.kood=z.directo_kods

update kasutajad
set meetod_tulumaks=z.inc_tax_freeb
from (select directo_kods, inc_tax_freeb from @xml_data where closed is null and exist='Yes' and inc_tax_free='1' and inc_tax_freeb='2') z
WHERE
kasutajad.kood=z.directo_kods

--Pievieno Apgādājamo personu datus datus--
insert kasutajad_isikud (kasutaja,tyyp, aeg1, aeg2, aktiivne, nimi)
select directo_kods,'APG',apg_sakums,apg_beigas, 'True', apg_vards_uzvards from @xml_data2 where closed is null and directo_kods is not null


--Pievienot Neapliekamā minimuma datus IIN2018--

insert into kasutajad_maksud (kood, valem, maksuvaba, algus, lopp, rn)
select directo_code, 'IIN2018',neapliekams_summa, date1, date2, '1' from @xml_data4 where rnd='0' and directo_code not in (select directo_code from @pens)

update kasutajad_maksud set rn='2' where valem like '%IIN%' and lopp is null

--Pievienot Neapliekamā minimuma datus IIN_PENS--
insert into kasutajad_maksud (kood, valem, algus, rn)
select directo_code, 'IIN_PENS', datums, '1' from @regpens where rnd='0'

--Pievienot Neapliekamā minimuma datus IIN_PENS--
insert into kasutajad_maksud (kood, valem, algus, rn)
select directo_code, 'IIN_PENS', datums, '1' from @regpens where rnd='0'

--Pievienot Neapliekamā minimuma datus IIN_PENS (izdienas)--
insert into kasutajad_maksud (kood, valem, algus, lopp, rn)
select directo_code, 'IIN_PENS', datums, datums2, '1' from @izdpens where rnd='0'

--Pievienot Neapliekamā minimuma datus IIN_INV_I_II (izdienas)--
insert into kasutajad_maksud (kood, valem, algus, lopp, rn)
select directo_code, 'IIN_INV_I_II', datums, datums2, '1' from @pens1_2 where rnd='0'

--Pievienot Neapliekamā minimuma datus IIN_INV_III (izdienas)--
insert into kasutajad_maksud (kood, valem, algus, lopp, rn)
select directo_code, 'IIN_INV_III', datums, datums2, '1' from @pens3 where rnd='0'
*/
delete from int_import_dat where dat like '%NM_e_gramatina%' and cu=@key


select N'Darīts'
--END

/*

*/
/*


update kasutajad_maksud
 set algus=z.mv_algus, lopp=z.mv_lopp, mv_algus=NULl, mv_lopp=NULL from
  (select kood, valem, rn, mv_algus, mv_lopp from kasutajad_maksud where valem='IIN2018' and rn='1') z where kasutajad_maksud.valem=z.valem and kasutajad_maksud.rn=z.rn and kasutajad_maksud.kood=z.kood*/
  

--select directo_code, 'IIN2018',neapliekams_summa, date1, date2, rn+1 from @xml_data4 

/*
delete from kasutajad_dokumendid where tyyp='NGRA'
delete from kasutajad_isikud where tyyp='NGRA'
delete from kasutajad_maksud where valem='IIN2018'
*/





GO


