SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[int_hooldus_klient_pfpisk] @aeg1 datetime, @aeg2 datetime, @MonthRep nvarchar(10), @YearRep nvarchar(10) as
declare @year int, @month int, @PREVMONTH DATETIME, @prevYear int,@prevMonth2 int, @startYear datetime
SELECT @PREVMONTH = DATEaDD(SS,-1,@AEG1)
select @year = year(@aeg1)
select @month = month(@aeg1)
select @prevYear = year(@PREVMONTH)
select @PREVMONTH2 = month(@PREVMONTH)
SELECT @startYear = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0)
/*
DECLARE @dateprev1 datetime, @dateprev2 datetime, @aegs datetime, @aegtext nvarchar(max), @aegfill datetime, @month nvarchar(32), @year nvarchar(32)
 SET @dateprev1= DATEADD(month, DATEDIFF(month, -1, @aeg1) - 2, 0) 
 SET @dateprev2= DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, @aeg2), 0)) 
 SET @aegs = @aeg1 
 SET @aegtext = convert(varchar, @aegs,105) 
 SET @aegfill = getdate()
DECLARE @iin_def decimal(15,2),  @year_start datetime
SET @iin_def = isnull((select top 1 maksuvaba from per_maksuvalemid where per_maksuvalemid.kood='IIN'),0);
SET @year_start = (select dateadd(year,datediff(year,0,@aeg1),0));
SET @aegs = @aeg1
SELECT @month = MONTH(@aeg2);
SELECT @year = year(@aeg2);
DECLARE @PERSONS_TABLE TABLE
(
kods NVARCHAR(32),
vards nvarchar(255),
pers_kods nvarchar(30),
sakums date,
beigas date,
soc_dn decimal(15,4),
soc_dd decimal(15,4),
bruto decimal(15,4),
ien_nodoklis decimal(15,4)
)

DECLARE @IIN TABLE
(
persona NVARCHAR(32),
metode nvarchar(30),
sakums datetime,
beigas datetime,
p_men_likme decimal(15,4),
p_neapl decimal(15,4),
atv_neapl decimal(15,4),
apg_neapl decimal(15,4),
nmin_kopa decimal(15,4)
)

if @MonthRep is null and @YearRep is not null
	begin

		insert @PERSONS_TABLE
		select 
			kood as kods
		    ,nimi as vards
		    ,isikukood as personas_kods
			,case
			when (aeg_saabus < @year_start) then (@year_start)
			when (aeg_saabus > @year_start) then (cast(aeg_saabus as datetime))
			END as sakuma_datums
			,cast(isnull(case when (aeg_lahkus >= @aeg2) then @aeg2 end,@aeg2) as datetime) as beigu_datums
			,isnull((select sum(summa) from per_palgad_maksud 
		    INNER JOIN per_maksuvalemid ON per_maksuvalemid.kood=per_palgad_maksud.maksuvalem 
		    INNER JOIN per_palgad on per_palgad_maksud.number=per_palgad.number 
		    where persoon=kasutajad.kood 
		    and per_maksuvalemid.klass	='SOC_DN'
		    and per_palgad.aeg1 between (
		        case 
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		         and  per_palgad.aeg2 between(
		             case 
		             when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		             when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		    ),0) as soc_dn
		    ,isnull((select sum(summa) from per_palgad_maksud
		     INNER JOIN per_maksuvalemid ON per_maksuvalemid.kood=per_palgad_maksud.maksuvalem 
		     INNER JOIN per_palgad on per_palgad_maksud.number=per_palgad.number 
		     where persoon=kasutajad.kood 
		      and per_maksuvalemid.klass='SOC_DD'  
		     and per_palgad.aeg1 between (
		         case 
		         when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		         when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		     and  per_palgad.aeg2 between (
		         case 
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start)
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		    ),0)  as soc_dd
			
			  ,
		    isnull((select sum(per_palgad_read.bruto) from per_palgad_read  
		    INNER JOIN per_palgad on per_palgad_read.number=per_palgad.number 
		    where persoon=kasutajad.kood
		    and (per_palgad.aeg1 between (
		        case 
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2) 
		    and  (per_palgad.aeg2 between (
		        case
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2)
		    and per_palgad_read.valem not in (select kood from per_palgavalemid where klass in ('ATVILKUMS', 'Neapliekams'))
		      ),'0') as bruto,
		      isnull((select sum(summa) from per_palgad_maksud 
		  INNER JOIN per_palgad on per_palgad_maksud.number=per_palgad.number 
		  where persoon=kasutajad.kood 
		  and (select top 1  klass from per_maksuvalemid where kood=per_palgad_maksud.maksuvalem)='IIN' 
		  and per_palgad.aeg1 between (
		      case when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		      when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		       and  per_palgad.aeg2 between(
		           case 
		           when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		           when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		    ),0)  as ien_nodoklis
from kasutajad
where 
 cast(isnull(aeg_lahkus,@aeg2) as date) >= cast(@aeg2 as date) and aeg_saabus <= @aeg2 and
   isikukood is not null and
    nimi is not null and
    kood in (select distinct(persoon) from per_palgad_read INNER JOIN per_palgad ON per_palgad.number=per_palgad_read.number where per_palgad.aeg1 between @year_start and @aeg2)


insert @IIN
select
        kood
    ,   valem
    ,   algus
    ,   isnull(lopp,(select top 1 aeg_lahkus from kasutajad where kood=km.kood))
    ,   isnull(maksuvaba,0)
    ,   isnull((select sum(maksuvaba_personal) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,cast(@year_start as date)) and isnull(lopp,@aeg2))  and ppm.persoon=km.kood and (ppm.maksuvalem  not like '%INV%' and ppm.maksuvalem  not like '%INV%')),0)
	,   isnull((select sum(maksuvaba_personal) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,cast(@year_start as date)) and isnull(lopp,@aeg2)) and ppm.persoon=km.kood and (ppm.maksuvalem  like '%INV%' and ppm.maksuvalem  like '%INV%')),0)
     ,   isnull((select sum(maksuvaba_related) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,cast(@year_start as date)) and isnull(lopp,@aeg2)) and ppm.persoon=km.kood),0)
     ,   isnull((select sum(maksuvaba) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,@year_start) and isnull(lopp,@aeg2)) and ppm.persoon=km.kood),0)
    from kasutajad_maksud km where isnull(algus,cast(@year_start as date)) between @year_start and @aeg2 and valem like ('%IIN%')

	end
if @MonthRep is not null and @YearRep is null
		begin

		insert @PERSONS_TABLE
		select 
			kood as kods
		    ,nimi as vards
		    ,isikukood as personas_kods
			,case
			when (aeg_saabus < @year_start) then (@year_start)
			when (aeg_saabus > @year_start) then (cast(aeg_saabus as datetime))
			END as sakuma_datums
			,cast(isnull(case when (aeg_lahkus >= @aeg2) then @aeg2 end,@aeg2) as datetime) as beigu_datums
			,isnull((select sum(summa) from per_palgad_maksud 
		    INNER JOIN per_maksuvalemid ON per_maksuvalemid.kood=per_palgad_maksud.maksuvalem 
		    INNER JOIN per_palgad on per_palgad_maksud.number=per_palgad.number 
		    where persoon=kasutajad.kood 
		    and per_maksuvalemid.klass='SOC_DN'
		    and per_palgad.aeg1 between (
		        case 
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		         and  per_palgad.aeg2 between(
		             case 
		             when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		             when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		    ),0) as soc_dn
		    ,isnull((select sum(summa) from per_palgad_maksud
		     INNER JOIN per_maksuvalemid ON per_maksuvalemid.kood=per_palgad_maksud.maksuvalem 
		     INNER JOIN per_palgad on per_palgad_maksud.number=per_palgad.number 
		     where persoon=kasutajad.kood 
		      and per_maksuvalemid.klass='SOC_DD'  
		     and per_palgad.aeg1 between (
		         case 
		         when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		         when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		     and  per_palgad.aeg2 between (
		         case 
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start)
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		    ),0)  as soc_dd
			
			  ,
		    isnull((select sum(per_palgad_read.bruto) from per_palgad_read  
		    INNER JOIN per_palgad on per_palgad_read.number=per_palgad.number 
		    where persoon=kasutajad.kood
		    and (per_palgad.aeg1 between (
		        case 
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2) 
		    and  (per_palgad.aeg2 between (
		        case
		        when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		        when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2)
		    and per_palgad_read.valem not in (select kood from per_palgavalemid where klass in ('ATVILKUMS', 'Neapliekams'))
		      ),'0') as bruto,
		      isnull((select sum(summa) from per_palgad_maksud 
		  INNER JOIN per_palgad on per_palgad_maksud.number=per_palgad.number 
		  where persoon=kasutajad.kood 
		  and (select top 1  klass from per_maksuvalemid where kood=per_palgad_maksud.maksuvalem)='IIN' 
		  and per_palgad.aeg1 between (
		      case when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		      when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		       and  per_palgad.aeg2 between(
		           case 
		           when(kasutajad.aeg_saabus < @year_start) then (@year_start) 
		           when (kasutajad.aeg_saabus >= @year_start) then (SELECT DATEADD(month, DATEDIFF(month, 0, kasutajad.aeg_saabus), 0))END) and @aeg2
		    ),0)  as ien_nodoklis
from kasutajad
where 
--  cast(isnull(aeg_lahkus,@aeg2) as date) >= cast(@aeg2 as date) and aeg_saabus <= @aeg2 and
 month(aeg_lahkus)=@month and year(aeg_lahkus)=@year and 
   isikukood is not null and
    nimi is not null and
    kood in (select distinct(persoon) from per_palgad_read INNER JOIN per_palgad ON per_palgad.number=per_palgad_read.number where per_palgad.aeg1 between @year_start and @aeg2)


insert @IIN
select
        kood
    ,   valem
    ,   algus
    ,   isnull(lopp,(select top 1 aeg_lahkus from kasutajad where kood=km.kood))
    ,   isnull(maksuvaba,0)
    ,   isnull((select sum(maksuvaba_personal) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,cast(@year_start as date)) and isnull(lopp,@aeg2))  and ppm.persoon=km.kood and (ppm.maksuvalem  not like '%INV%' and ppm.maksuvalem  not like '%INV%')),0)
	,   isnull((select sum(maksuvaba_personal) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,cast(@year_start as date)) and isnull(lopp,@aeg2)) and ppm.persoon=km.kood and (ppm.maksuvalem  like '%INV%' and ppm.maksuvalem  like '%INV%')),0)
     ,   isnull((select sum(maksuvaba_related) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,cast(@year_start as date)) and isnull(lopp,@aeg2)) and ppm.persoon=km.kood),0)
     ,   isnull((select sum(maksuvaba) from per_palgad_maksud ppm where ppm.maksuvalem=km.valem and kuukood in (select distinct(kuukood) from per_palgad where aeg1 between isnull(km.algus,@year_start) and isnull(lopp,@aeg2)) and ppm.persoon=km.kood),0)
    from kasutajad_maksud km where isnull(algus,cast(@year_start as date)) between @year_start and @aeg2 and isnull(lopp,@aeg2) >= @year_start and valem like ('%IIN%')

	end
select (select *, (select 
                            persona,
                            metode,
                            sakums,
                            beigas,
                            p_men_likme,
                            case when(p_neapl = 0 and atv_neapl=0 and apg_neapl=0 and metode not like '%INV%') then (nmin_kopa) else p_neapl end as p_neapl,
                            case when(atv_neapl > nmin_kopa) then (nmin_kopa) when (p_neapl = 0 and apg_neapl=0 and metode like '%INV%') then nmin_kopa end as  atv_neapl,
                            apg_neapl,
                            nmin_kopa  from @IIN where persona=z.kods FOR XML PATH('IIN'),Type, Elements) AS [IINS] from @PERSONS_TABLE z FOR XML PATH('persona'),Type, Elements) AS [personas],








FOR XML PATH('document'),Type, Elements
*/
/*
(SELECT 
			DATEDIFF(day,@aeg1,@aeg2)+1 as dienu_sk,
			substring(@aegtext, 4,2) as taks_menesis,
			substring(@aegtext, 7,4) as taks_gads,
			(select Setting from settings where ID='firma_nimi') as uzn_nos,
			@aegfill as aizpildisanas_laiks,
			(substring(app_name(),charindex(',user:',app_name()+',user:')+6,32)) as izveidoja_kods,
			(select nimi from kasutajad where kood=substring(app_name(),charindex(',user:',app_name()+',user:')+6,32)) as izveidoja,
			(select Setting from settings where ID='firma_regnr') as uzn_regnr,
			(select Setting from settings where ID='firma_juht') as atb_persona,
			'10' as izmaksas_datums,
			isnull(@MonthRep,0) as monthRep,
			isnull(@YearRep,0) as yearRep,
			(select replace(Setting,' ','') from settings where ID='firma_telefon') as uzn_tel
 FOR XML PATH ('settings'),TYPE, ELEMENTS)*/
 create table #t1 
(
	number int,
	persoon nvarchar(255),
	empl_name nvarchar(255),
	kuukood int,
	pid nvarchar(32),
	Sdate date,
	Edate date,
	koefitsient decimal(15,2),
	valem nvarchar(255),
	SFclass nvarchar(255),
	SFtype nvarchar(32),
	BrutoSum decimal(15,2),
	free decimal(15,2),
	IIN_PERS decimal(15,2),
	IIN_REL decimal(15,2),
	SOC_EMPLOYEE decimal(15,2),
	SOC_EMPLOYER decimal(15,2),
	iin decimal(15,2),
	IIN_T nvarchar(32),
	Costs decimal(15,2)
)
if isnull(@monthrep,'')!='' and isnull(@YearRep,'')=''
	begin
--insert simple salary formulas
insert into #t1
select 
			b.number,
			a.persoon,
			(select nimi from kasutajad where kood=a.persoon) empl_name,
			b.kuukood,
			(select isikukood from kasutajad where kood=a.persoon) pid,
			iif((select aeg_saabus from kasutajad where kood=a.persoon) < @startYear,@startYear,(select aeg_saabus from kasutajad where kood=a.persoon)) Sdate,
			(select aeg_lahkus from kasutajad where kood=a.persoon) Edate,
			sum(a.koefitsient),
			a.valem,
			(select klass from per_palgavalemid where kood=a.valem) SFclass,
			isnull((select tsd from per_palgavalemid where kood=a.valem),'1001') SFtype,
			cast(sum(a.bruto) as decimal(15,2)) as BrutoSum,
			ROUND(ISNULL((select sum(ISNULL(maksuvaba,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as free,
			ROUND(ISNULL((select sum(ISNULL(maksuvabA_PERSONAL,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as IIN_PERS,
			ROUND(ISNULL((select sum(ISNULL(maksuvabA_RELATED,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as IIN_REL,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='soc_dn')),0),2) as SOC_EMPLOYEE,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='soc_dD')),0),2) as SOC_EMPLOYER,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='IIN')),0),2) as iin,
			(SELECT DISTINCT(MAKSUVALEM)+',' from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND ISNULL(maksuvaba,0)<>0 FOR XML PATH('')) IIN_T,
			0 costs
from per_palgad_read a 
inner join per_palgad b on a.number=b.number 
where year(b.aeg1)=@year and a.persoon in (select kood from kasutajad where convert(nvarchar(max),year(aeg_lahkus))+'-'+convert(nvarchar(max),month(aeg_lahkus))=convert(nvarchar(max),@year)+'-'+convert(nvarchar(max),@month)) and (select klass from per_palgavalemid where kood=a.valem)!='AA'
GROUP BY b.number,a.persoon,b.kuukood,a.valem



--insert honorarium salary formulas
insert into #t1
select 
			b.number,
			a.persoon,
			(select nimi from kasutajad where kood=a.persoon) empl_name,
			b.kuukood,
			(select isikukood from kasutajad where kood=a.persoon) pid,
			cast(dateadd(mm,-1,@aeg1) as date) Sdate,
			cast(dateadd(ss,-1,@aeg1) as date) Edate,
			sum(a.koefitsient),
			a.valem,
			(select klass from per_palgavalemid where kood=a.valem) SFclass,
			isnull((select tsd from per_palgavalemid where kood=a.valem),'1001') SFtype,
			cast(sum(a.bruto) as decimal(15,2)) as BrutoSum,
			ROUND(ISNULL((select sum(ISNULL(maksuvaba,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as free,
			ROUND(ISNULL((select sum(ISNULL(maksuvabA_PERSONAL,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as IIN_PERS,
			ROUND(ISNULL((select sum(ISNULL(maksuvabA_RELATED,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as IIN_REL,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='soc_dn')),0),2) as SOC_EMPLOYEE,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='soc_dD')),0),2) as SOC_EMPLOYER,		ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='IIN')),0),2) as iin,
			(SELECT DISTINCT(MAKSUVALEM)+',' from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND ISNULL(maksuvaba,0)<>0 FOR XML PATH('')) IIN_T,
			cast(sum(a.bruto) * 0.25 as decimal(15,2)) as Costs
from per_palgad_read a 
inner join per_palgad b on a.number=b.number 
where convert(nvarchar(max),year(b.aeg1))+'-'+convert(nvarchar(max),month(b.aeg1))=convert(nvarchar(max),@prevYear)+'-'+convert(nvarchar(max),@prevmonth2) and (select klass from per_palgavalemid where kood=a.valem)='AA'
GROUP BY b.number,a.persoon,b.kuukood,a.valem

select * from #t1 for xml path ('docss')



end
if isnull(@monthrep,'')='' and isnull(@YearRep,'')!=''
	begin
--insert simple salary formulas
insert into #t1
select 
			b.number,
			a.persoon,
			(select nimi from kasutajad where kood=a.persoon) empl_name,
			b.kuukood,
			(select isikukood from kasutajad where kood=a.persoon) pid,
			iif((select aeg_saabus from kasutajad where kood=a.persoon) < @aeg1,@aeg1,(select aeg_saabus from kasutajad where kood=a.persoon)) Sdate,
			isnull((select aeg_lahkus from kasutajad where kood=a.persoon),@aeg2) Edate,
			sum(a.koefitsient),
			a.valem,
			(select klass from per_palgavalemid where kood=a.valem) SFclass,
			isnull((select tsd from per_palgavalemid where kood=a.valem),'1001') SFtype,
			cast(sum(a.bruto) as decimal(15,2)) as BrutoSum,
			ROUND(ISNULL((select sum(ISNULL(maksuvaba,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as free,
			ROUND(ISNULL((select sum(ISNULL(maksuvabA_PERSONAL,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as IIN_PERS,
			ROUND(ISNULL((select sum(ISNULL(maksuvabA_RELATED,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood),0),2) as IIN_REL,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='soc_dn')),0),2) as SOC_EMPLOYEE,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='soc_dD')),0),2) as SOC_EMPLOYER,
			ROUND(ISNULL((select sum(ISNULL(SUMMA,0)) from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND MAKSUVALEM IN (SELECT DISTINCT KOOD FROM per_MAKSUVALEMID WHERE KLASS='IIN')),0),2) as iin,
			(SELECT DISTINCT(MAKSUVALEM)+',' from per_palgad_maksud where persoon=a.persoon and palgavalem=a.valem and kuukood=b.kuukood AND ISNULL(maksuvaba,0)<>0 FOR XML PATH('')) IIN_T,
			0 costs
from per_palgad_read a 
inner join per_palgad b on a.number=b.number 
where year(b.aeg1)=@year and a.persoon in (select kood from kasutajad where cast(isnull(aeg_lahkus,@aeg2) as date) >= cast(@aeg2 as date)  and aeg_saabus <= @aeg2) and (select klass from per_palgavalemid where kood=a.valem)!='AA'
GROUP BY b.number,a.persoon,b.kuukood,a.valem

end
select (SELECT 
				DISTINCT PERSOON [@employee],
				empl_name [@e_name],
				pid [@pid],
				Sdate [@sdate],
				Edate [@edate],
				SFTYPE [@salary_type],
				SUM(BrutoSum) [@bruto] ,
				SUM(FREE) [@free],
				SUM(IIN_PERS) [@iin_pers],
				SUM(IIN_REL) [@iin_rel],
				SUM(SOC_EMPLOYEE) [@soc_employee],
				SUM(SOC_EMPLOYER) [@soc_employer],
				SUM(IIN) [@iin],
				sum(costs) [@costs]
FROM #T1 A WHERE SFclass!='atvilkums' GROUP BY SFTYPE, PERSOON,empl_name,pid,sdate,edate for xml path ('row'),Type, Elements)  as [rows],
(SELECT 
			--DATEDIFF(day,@aeg1,@aeg2)+1 as dienu_sk,
			@month as [@rep_month],
			@year as [@rep_year],
			(select Setting from settings where ID='firma_nimi') as [@company_name],
			getdate() as [@report_time],
			--(substring(app_name(),charindex(',user:',app_name()+',user:')+6,32)) as ,
			(select nimi from kasutajad where kood=substring(app_name(),charindex(',user:',app_name()+',user:')+6,32)) [@created],
			(select Setting from settings where ID='firma_regnr') as [@CompanyRegNo],
			(select Setting from settings where ID='firma_juht') as [@CoManager],
			'10' as [@payDate],
			--@month as month1,@year as year3,
			--isnull(@MonthRep,0) as monthRep,
			--(@YearRep,0) as yearRep,
			(select replace(Setting,' ','') from settings where ID='firma_telefon') [@CompPhone]
 FOR XML PATH ('settings'),TYPE, ELEMENTS)


for xml path ('document') ,Type, Elements

DROP TABLE #T1




GO
