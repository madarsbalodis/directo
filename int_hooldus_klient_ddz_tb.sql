USE [ocra_leta_lv]
GO

/****** Object:  StoredProcedure [dbo].[int_hooldus_klient_ddz_tb]    Script Date: 07/07/2023 11:41:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER     PROCEDURE [dbo].[int_hooldus_klient_ddz_tb] @aeg1 datetime, @aeg2 datetime AS

--version 170220211302
--INSERT INTO int_hooldus_klient (rn, nimi, formaat, aru_tyyp) 
--VALUES ('_ddz_tb', 'DDZ 2021 as table', 'tabel','personal');
--INSERT INTO int_hooldus_klient_params  (aru_id, nimi, tyyp, order_no) 
--VALUES ('_ddz_tb', 'iin_Mcode', '2', 2);

DECLARE @row SMALLINT, @xrep nvarchar(64)
select @xrep = convert(nvarchar(max),getdate(),121)

SET @row=(select rn from int_print where id='int_hooldus_klient_ddz_xml' and dokument='xml' and isnull(suletud,0)=0)
--------------------Worked hours part-----
declare @days table (rowDate date, weekDay int, isOfficialHoliday date, previousDayShorter int,shorterDateDate date, shorterDate nvarchar(1))
create table #person_days (rowDate date, person nvarchar(32),Worked decimal(15,0),weekDay int, workHours nvarchar(64), sf nvarchar(64))

declare @minDay date, @maxDay date, @rowDate DATETIME,@x int, @person nvarchar(32), @salaryFormula nvarchar(32),@x1 int, @weekDay int
set @minDay =  @aeg1
set @maxDay =  @aeg2
--set @aeg1 =  '2021-12-01'
--set @aeg2 = '2021-12-31'

WHILE @minDay <= @maxDay
BEGIN 
	insert @days (rowDate,weekDay,isOfficialHoliday,previousDayShorter)
	select @minDay, DATEPART(WEEKDAY, @minDay), ISNULL((select cast(aeg as date) from per_pyhad where cast(aeg as date)=@minDay),null), ISNULL((select eelnev_lyhem from per_pyhad where cast(aeg as date)=@minDay),0)
  set @minDay = dateadd(day,1,@minDay)
END 

update @days set shorterDateDate = dateadd(day,previousDayShorter * (-1),rowDate) where isnull(previousDayShorter,0)>0
update @days set shorterDate = 'Y' where rowDate in (select shorterDateDate from @days where shorterDateDate is not NULL)
--select * from per_pyhad
--select * from @days
select ppr.persoon into #persons FROM per_palgad_read ppr inner join per_palgad pp on ppr.number=pp.number inner join per_palgavalemid ppv on ppr.valem=ppv.kood 
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date,pp.aeg2) between @aeg1 and @aeg2) and ppv.keskmine_palk='True' and ppv.tyyp='1' GROUP BY persoon


--select * from int_import
--select * from kasutajad_suhe where kasutaja='2490'
--select * from #persons
create table #perLoadSetByDay (ucode nvarchar(32), ts date, date1 date,date2 date, PHour decimal(15,0), Pday int)

declare @userc nvarchar(32), @workloadsplitted nvarchar(255), @uaeg datetime, @uaeg1 datetime, @uaeg2 datetime,@sql nvarchar(max), @sep char(1),@s nvarchar(max)
declare tellimused cursor for select kasutaja ,paevad_tunnid, aeg,aeg1,aeg2 from kasutajad_suhe where isnull(paevad_tunnid,'')!='' and isnull(aeg2,getdate()) > @aeg1 and aeg1 < dateadd(d,1,@aeg2)
open tellimused
FETCH NEXT FROM tellimused INTO @userc, @workloadsplitted,@uaeg,@uaeg1,@uaeg2
WHILE @@FETCH_STATUS = 0
BEGIN
select @sep = ','
		insert #perLoadSetByDay		
		 select @userc, cast(@uaeg as date), cast(@uaeg1 as date),cast(isnull(@uaeg2,@aeg2) as date),*
						   from dbo.get_in_sep(@workloadsplitted,@sep) h where x>''

set @x=@x+1
	FETCH NEXT FROM tellimused INTO @userc, @workloadsplitted,@uaeg,@uaeg1,@uaeg2
END
CLOSE tellimused
DEALLOCATE tellimused


--select dbo.getWorkingDays2('2021-12-07','2021-12-08','1517')
declare tellimused cursor for select rowDate, weekDay from @days
open tellimused
FETCH NEXT FROM tellimused INTO @rowDate, @weekDay
WHILE @@FETCH_STATUS = 0
BEGIN
		declare tellimused1 cursor for select ppr.persoon,ppr.valem FROM per_palgad_read ppr inner join per_palgad pp on ppr.number=pp.number inner join per_palgavalemid ppv on ppr.valem=ppv.kood 
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date,pp.aeg2) between @aeg1 and @aeg2) and ppv.keskmine_palk='True' and ppv.tyyp='1'
GROUP BY persoon, ppr.valem;
			open tellimused1
			FETCH NEXT FROM tellimused1 INTO @person,@salaryFormula 
			WHILE @@FETCH_STATUS = 0
				BEGIN
					insert #person_days
					select @rowDate,@person, isnull(dbo.get_valem_kogus_lv('HOUR_CALCULATION',NULL,NULL,@rowDate,dateadd(ss,-1,dateadd(day,1,@rowDate)),@person),0),@weekDay,'',@salaryFormula
					--select @rowDate,@person, 0,@weekDay,'', @salaryFormula
					--select @rowDate,@person, dbo.get_pyhad_t2(@rowDate,dateadd(ss,-1,dateadd(day,1,@rowDate)),@person)
			set @x1=@x1+1
			FETCH NEXT FROM tellimused1 INTO @person, @salaryFormula 
			END
			CLOSE tellimused1
			DEALLOCATE tellimused1
set @x=@x+1
	FETCH NEXT FROM tellimused INTO @rowDate, @weekDay
END
CLOSE tellimused
DEALLOCATE tellimused









-- event 93557
/*
UPDATE #person_days
SET worked = ISNULL(
    (SELECT #perLoadSetByDay.phour * #person_days.workLoadFactor
     FROM #perLoadSetByDay
     WHERE #person_days.rowDate BETWEEN #perLoadSetByDay.date1 AND #perLoadSetByDay.date2
       AND #perLoadSetByDay.ucode = #person_days.person
       AND #perLoadSetByDay.Pday = #person_days.weekDay),
    8 * #person_days.workLoadFactor)
WHERE #person_days.Worked >= 1 */
-- // event 93557




drop table #persons
--drop table #load
--drop table #load2

----------------------------------------
SELECT distinct kd.kood, kd.nimi, kd.isikukood, kd.aeg_saabus, 
CASE WHEN isnull(ks3.aeg2,'')='' OR (ks3.aeg2>=@aeg2) or ks3.etapp='PM' THEN '' 
ELSE format(ks3.aeg2,'dd.MM.yyyy') END as aeg_lahkus,
isnull(sk.setting, 'DN') as tyyp, ks3.koormus INTO #DDZ_PERSONS
FROM kasutajad kd inner join per_palgad_read ppr on ppr.persoon=kd.kood inner join per_palgad pp on ppr.number=pp.number left join settings_kasutaja sk on kd.kood=sk.kasutaja inner join (select ks.kasutaja, ks.koormus, ks.aeg2, ks.etapp from kasutajad_suhe ks where ks.aeg1=(select max(ks2.aeg1) from kasutajad_suhe ks2 where ks2.kasutaja=ks.kasutaja and ks2.aeg1<=@aeg2)) ks3 on kd.kood=ks3.kasutaja 
WHERE (((pp.aeg1  between @aeg1 and @aeg2) and (convert(date, pp.aeg2) between @aeg1 and @aeg2))) and (sk.id='personal_type' or sk.id is NULL)   order by kd.kood;
-----------------------

UPDATE #person_days SET Worked = IIF(WORKED >= 1,1,WORKED)
--select * from #person_days where person='MARUTA.VILCANE'
update #person_days set worked=isnull((select phour from #perLoadSetByDay where #person_days.rowDate between #perLoadSetByDay.date1 and #perLoadSetByDay.date2 and #perLoadSetByDay.ucode=#person_days.person and #perLoadSetByDay.Pday=#person_days.weekDay),8)*(select koormus from #DDZ_PERSONS where kood=#person_days.person) where #person_days.Worked >=1

update #person_days set worked=worked-iif((select 'a' from @days where rowDate=#person_days.rowDate and shorterDate='Y')='a',1,0) where #person_days.Worked >=1
select person persoon, sum(worked) koefitsientD  into #DDZ_WORKDAYS2 from #person_days group by person

-----------------------
SELECT ppr.persoon, sum(ppr.bruto) as bruto_sum INTO #DDZ_BRUTO
FROM per_palgad_read ppr inner join per_palgad pp on ppr.number=pp.number inner join per_palgavalemid ppv on ppr.valem=ppv.kood
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date, pp.aeg2) between @aeg1 and @aeg2) and ppv.klass not in ('ATVILKUMS','AVANSS','AA')
GROUP BY persoon;

SELECT ppm.persoon, sum (ppm.summa) as soc_sum INTO #DDZ_SOC
FROM per_palgad_maksud ppm inner join per_palgad pp on ppm.number=pp.number inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date, pp.aeg2) between @aeg1 and @aeg2) and pm.versioon=ppm.versioon and pm.klass in ('SOC_DN','SOC_DD') and ppv.klass not in ('AA')
GROUP BY ppm.persoon;

SELECT ppm.persoon, sum(ppm.summa) as iin_sum INTO #DDZ_IIN
FROM per_palgad_maksud ppm inner join per_palgad pp on ppm.number=pp.number inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
WHERE 
--ppm.kuukood=@iin_mcode 
cast(ppm.palga_aeg as date) between cast(@aeg1 as date) and cast(@aeg2 as date) and pm.versioon=ppm.versioon and pm.klass in ('IIN') and ppv.klass not in ('AA')
GROUP BY persoon;



SELECT ppm.persoon, sum (ppm.summa) as risk_sum INTO #DDZ_RISK
FROM per_palgad_maksud ppm inner join per_palgad pp on ppm.number=pp.number inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date,pp.aeg2) between @aeg1 and @aeg2) and pm.versioon=ppm.versioon and pm.klass in ('RISK') 
GROUP BY persoon;



SELECT ppr.persoon, sum(ppr.koefitsient)*8 as koefitsientD
INTO #DDZ_WORKDAYS
FROM per_palgad_read ppr inner join per_palgad pp on ppr.number=pp.number inner join per_palgavalemid ppv on ppr.valem=ppv.kood 
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date,pp.aeg2) between @aeg1 and @aeg2) and ppv.keskmine_palk='True' and ppv.tyyp='1'
GROUP BY persoon;

SELECT ppr.persoon, sum(ppr.koefitsient) as koefitsientH
INTO #DDZ_WORKHOURS
FROM per_palgad_read ppr inner join per_palgad pp on ppr.number=pp.number inner join per_palgavalemid ppv on ppr.valem=ppv.kood 
WHERE (pp.aeg1  between @aeg1 and @aeg2) and (convert(date,pp.aeg2) between @aeg1 and @aeg2) and ppv.graafik='True' and ppv.tyyp  in ('2','3')
GROUP BY persoon;

select * from #DDZ_WORKHOURS
SELECT 
			#ddz_persons.kood as persona,
			#ddz_persons.aeg_saabus as DA_sakums,
			#ddz_persons.aeg_lahkus as DA_beigas, 
			CASE 
				WHEN #ddz_persons.tyyp IN ('Pens','DP') THEN 'DP'
           		WHEN #ddz_persons.tyyp IN ('Pens_izd','inv','DI') THEN 'DI' 
				ELSE 'DN' 
			END as DA_veids, 
			#ddz_persons.koormus as slodze,
			#ddz_workdays.koefitsientD as koefD,
			-- rēķina vērtību priekš koefD2
			cast(iif(not(exists(select distinct ucode from #perLoadSetByDay where ucode=#ddz_persons.kood)),isnull(#ddz_workdays2.koefitsientD,0) --* #ddz_persons.koormus
			,isnull(#ddz_workdays2.koefitsientD,0))  as decimal(15,2)) as koefD2,
			--cast(iif(not(exists(select distinct ucode from #perLoadSetByDay where ucode=#ddz_persons.kood)),1,0)  as decimal(15,2)) as koefD2,
			#ddz_workhours.koefitsientH as koefH,
			#ddz_persons.isikukood as personas_kods,
			#ddz_persons.nimi as vards_uzvards,
			#ddz_bruto.bruto_sum as darba_ienakumi,
			#ddz_soc.soc_sum as vsaoi,
			#ddz_iin.iin_sum,
			#ddz_risk.risk_sum,
			(isnull(#ddz_workdays.koefitsientD,0)*#ddz_persons.koormus + isnull(#ddz_workhours.koefitsientH,0)) as stundu_skaits
into #rows
FROM #ddz_persons 
                         left join #ddz_workdays on #ddz_persons.kood=#ddz_workdays.persoon
						 left join #ddz_workdays2 on #ddz_persons.kood=#ddz_workdays2.persoon
                         left join #ddz_workhours on #ddz_persons.kood=#ddz_workhours.persoon
                         left join #ddz_bruto on #ddz_persons.kood=#ddz_bruto.persoon
                         left join #ddz_soc on #ddz_persons.kood=#ddz_soc.persoon
                         left join #ddz_iin on #ddz_persons.kood=#ddz_iin.persoon  
                         left join #ddz_risk on #ddz_persons.kood=#ddz_risk.persoon;


SELECT '<a href="javascript:nop()" onclick="javascript:avaWin(''yld_print.asp?1=1¶m1=1&row='+CONVERT(nvarchar,@row,104)+'&moodul=int_hooldus_klient_ddz_xml&print=no&mida=xsl&aeg1='+CONVERT(nvarchar,@aeg1,104)+'&aeg2='+CONVERT(nvarchar,@aeg2,104)+'&param0='+convert(nvarchar(max),@xrep)+'&1=1'')">XML fails</a>'
select 
		persona [Directo kods],
		DA_sakums  [DA sākums],
		DA_beigas [DA beigas],
		da_veids [DA veids],
		slodze [Noslodze],
		convert(nvarchar(max),iif(isnull(koefD,0) > 0 and isnull(koefD2,0) = 0,'<font color="red">'+convert(nvarchar(max),koefd * isnull(slodze,1))+'</font>',iif(isnull(koefd,0)=0 and isnull(koefd2,0)=0,'<font color="green">'+convert(nvarchar(max),isnull(koefh,0))+'</font>','<font color="blue">'+convert(nvarchar(max),isnull(koefd2,0))+'</font>'))) as [Nostrādātās stundas],
		-- convert(nvarchar(max),iif(isnull(koefD,0) > 0 and isnull(koefD2,0) = 0,'<font color="red">'+convert(nvarchar(max),koefd * isnull(slodze,1))+'</font>',iif(isnull(koefd,0)=0 and isnull(koefd2,0)=0,'<font color="green">'+convert(nvarchar(max),isnull(koefh,0) * isnull(slodze,1))+'</font>','<font color="blue">'+convert(nvarchar(max),isnull(koefd2,0) * isnull(slodze,1))+'</font>'))) as [Nostrādātās stundas],
		personas_kods [Personas kods],
		vards_uzvards [Vārds, uzvārds],
		darba_ienakumi [Ienākumi],
		vsaoi [VSAOI],
		iin_sum as [IIN summa],
		risk_sum [RISK nod summa]
from #rows

-- SELECT 
--     persona [Directo kods],
--     DA_sakums [DA sākums],
--     DA_beigas [DA beigas],
--     da_veids [DA veids],
--     slodze [Noslodze],
-- 	-- rēķina nostrādātās stundas
--     CONVERT(nvarchar(max), (koefD * slodze)) as [Nostrādātās stundas], -- Example calculation
--     personas_kods [Personas kods],
--     vards_uzvards [Vārds, uzvārds],
--     darba_ienakumi [Ienākumi],
--     vsaoi [VSAOI],
--     iin_sum as [IIN summa],
--     risk_sum [RISK nod summa]
-- FROM #rows


select 
		persona,
		DA_sakums,
		DA_beigas,
		da_veids,
		iif(isnull(koefD,0) > 0 and isnull(koefD2,0) = 0,koefd,iif(isnull(koefd,0)=0 and isnull(koefd2,0)=0,isnull(koefh,0),isnull(koefd2,0))) as w_hours,
		personas_kods p_id,
		vards_uzvards Pname,
		darba_ienakumi Income,
		isnull(vsaoi,0) [VSAOI],
		isnull(iin_sum ,0) as IIN,
		risk_sum [RISK nod summa] into #results
from #rows


--drop table dbo.ddz_report_result
/*
create table dbo.ddz_report_result
(
	dir_user nvarchar(32),
	start_date nvarchar(64),
	end_date nvarchar(64),
	type nvarchar(10),
	worked_hours decimal(15,2),
	pid nvarchar(20),
	name nvarchar(255),
	income_sum decimal(15,4),
	soc_sum decimal(15,4),
	inc_tax_sum decimal(15,4),
	risk_tax_sum decimal(15,4),
	ts DATETIME,
	x nvarchar(64)
)
*/

insert ddz_report_result (dir_user,start_date,end_date,type,worked_hours,pid,name,income_sum,soc_sum,inc_tax_sum,risk_tax_sum, ts,x)
select persona,convert(nvarchar(max),DA_sakums,104),DA_beigas,DA_veids,w_hours,p_id,Pname,Income,VSAOI,IIN,[RISK nod summa],getdate(),@xrep from #results

select @xrep
drop table #perLoadSetByDay
drop table #person_days









GO


