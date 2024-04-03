SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER  procedure  
[dbo].[int_hooldus_klient_darbnespeju_lapu_imports]  @aeg1 datetime, @aeg2 datetime ,@key nvarchar(max)--, @do nvarchar(3)
as  
Declare @datenow DATETIME, @ag datetime
declare @number int, @maa int, @kmk nvarchar(32), @x int, @kinnitatud int
DECLARE @myyja nvarchar(32), @aeg datetime
declare @result1 xml, @result2 nvarchar(max)
declare @err nvarchar(32)
set @datenow = getdate()
set @ag = getdate()
--SELECT * from int_import_dat where cu=@key
/*
CREATE TABLE [dbo].[int_import_dat] (
    cu nvarchar(512),
    dat nvarchar(max)
)
*/
--insert int_hooldus_klient (rn, nimi, formaat, aru_tyyp) values ('_darbnespeju_lapu_imports', N'Darbnespēju lapu imports', 'import', 'personal')
--insert int_hooldus_klient_params (aru_id, nimi, tyyp, order_no) values ('_darbnespeju_lapu_imports', 'Darbība', N'1|Aplūkot importējamos datus,2|Aplūkot un importēt', 20)

declare @t as table (x xml)
declare @t2 as table (x xml)
declare @t3 as table (x xml)
declare @t4 as table (x xml)
declare @t5 as table (x xml)
declare @t6 as table (x xml)

insert into @t 
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu = @key

declare @xml_data as table
(
id nvarchar(255),
izpildes_laiks datetime,
darba_deveja_nmr_kods nvarchar(255),
darba_deveja_nosaukums nvarchar(MAX),
periods_no date,
periods_lidz date,
sanemsanas_laiks datetime
)

insert @xml_data
SELECT 
tab.col.value('id[1]', 'nvarchar(max)') AS id 
,tab.col.value('izpildes_laiks[1]', 'datetime') AS izpildes_laiks 
,tab.col.value('darba_deveja_nmr_kods[1]', 'nvarchar(max)') as darba_nmr_kods
,tab.col.value('darba_deveja_nosaukums[1]', 'nvarchar(max)') as darba_deveja_nosaukums
,tab.col.value('periods_no[1]','datetime') as periods_no
,tab.col.value('periods_lidz[1]','datetime') as periods_lidz
,tab.col.value('sanemsanas_laiks[1]','datetime') as sanemsanas_laiks
--,'XML' as objekts
--,'1' as personals
FROM @t 
CROSS APPLY x.nodes('//NM_dn_dnl/pamatdati') tab(col)





insert into @t2
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu = @key
declare @xml_data2 as table
(
	RegistrationNumber nvarchar(255)
	,CertificateType nvarchar(255)
	,CertificateFormType nvarchar(255)
	,ContinueDate datetime
	,PreviousCertificateNumber nvarchar(255)

	
	
)


insert @xml_data2
SELECT 
tab.col.value('RegistrationNumber[1]', 'nvarchar(255)') AS RegistrationNumber
,tab.col.value('CertificateType[1]', 'nvarchar(255)') AS CertificateType
,tab.col.value('CertificateFormType[1]', 'nvarchar(255)') as CertificateFormType	
,tab.col.value('ContinueDay[1]', 'datetime') as ContinueDay	
,tab.col.value('PreviousCertificateNumber[1]', 'nvarchar(255)') as PreviousCertificateNumber	

FROM @t2
CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData') tab(col)






insert into @t3
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu = @key
declare @xml_data3 as table
(
	RegistrationNumber nvarchar(255)
	,PersonID nvarchar(255)
	,FirstName nvarchar(255)
	,LastName nvarchar(255)

	
	
)


insert @xml_data3
SELECT 
tab.col.value('../RegistrationNumber[1]', 'nvarchar(255)') AS RegistrationNumber
,tab.col.value('PersonID[1]','nvarchar(255)') AS PersonID
,tab.col.value('FirstName[1]','nvarchar(255)') AS FirstName
,tab.col.value('LastName[1]','nvarchar(255)') as LastName	

FROM @t3
CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/PersonData') tab(col)




insert into @t4
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu = @key
declare @xml_data4 as table
(
	RegistrationNumber nvarchar(255)
	,DisabilityCauseText nvarchar(255)
)


insert @xml_data4
SELECT 
tab.col.value('../RegistrationNumber[1]', 'nvarchar(255)') AS RegistrationNumber
,tab.col.value('DisabilityCauseText[1]', 'nvarchar(255)') AS DisabilityCauseText
FROM @t4
CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/DisabilityCause') tab(col)






insert into @t5
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu = @key
declare @xml_data5 as table
(
	RegistrationNumber nvarchar(255)
	,StartDate datetime
	,EndDate datetime
	
)


insert @xml_data5
SELECT 
tab.col.value('../RegistrationNumber[1]', 'nvarchar(255)') AS RegistrationNumber
,tab.col.value('StartDate[1]', 'datetime') AS StartDate
,tab.col.value('EndDate[1]', 'datetime') AS EndDate
FROM @t5
CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/PeriodDates') tab(col)






insert into @t6
select replace(dat,'<?xml version="1.0" encoding="UTF-8"?>','') from int_import_dat where cu = @key
declare @xml_data6 as table
(
	RegistrationNumber nvarchar(255)
	,StatusDate datetime
	,StatusText nvarchar(255)
	
)


insert @xml_data6
SELECT 
tab.col.value('../RegistrationNumber[1]', 'nvarchar(255)') AS RegistrationNumber
,tab.col.value('StatusDate[1]', 'datetime') AS StartDate
,tab.col.value('StatusText[1]', 'nvarchar(255)') AS EndDate
FROM @t6
CROSS APPLY x.nodes('//NM_dn_dnl/dati/CertificateData/CertificateStatus') tab(col)



DECLARE @cu nvarchar(32)
IF APP_NAME() LIKE '%,user:%' SET @cu=SUBSTRING(APP_NAME(),CHARINDEX(',user:',APP_NAME())+6,32)

	select 
	(select top 1 darba_deveja_nmr_kods from @xml_data) as dd_reg_nr,
		RegistrationNumber
		,CertificateType
		,CertificateFormType
		,ContinueDate
		,PreviousCertificateNumber
		,(select PersonID from @xml_data3 xd3 where xd3.RegistrationNumber=xd2.RegistrationNumber) as PersonID
		,(select FirstName from @xml_data3 xd3 where xd3.RegistrationNumber=xd2.RegistrationNumber) as FirstName
		,(select LastName from @xml_data3 xd3 where xd3.RegistrationNumber=xd2.RegistrationNumber)as LastName
		,(select DisabilityCauseText from @xml_data4 xd4 where xd4.RegistrationNumber=xd2.RegistrationNumber)as DisabilityCauseText
		,(select StartDate from @xml_data5 xd5 where xd5.RegistrationNumber=xd2.RegistrationNumber)as StartDate
		,(select EndDate from @xml_data5 xd5 where xd5.RegistrationNumber=xd2.RegistrationNumber)as EndDate
		,(select StatusDate from @xml_data6 xd6 where xd6.RegistrationNumber=xd2.RegistrationNumber)as StatusDate
		,(select StatusText from @xml_data6 xd6 where xd6.RegistrationNumber=xd2.RegistrationNumber)as StatusText
		,(select kood from kasutajad where replace(isikukood,'-','')=(select PersonID from @xml_data3 xd3 where xd3.RegistrationNumber=xd2.RegistrationNumber)) as DirUser
		, cast(0 as int) countRecord
		, cast('' as nvarchar(32)) DocNr
		, cast('' as nvarchar(32)) DocRow
	into #values_temp
	from @xml_data2 xd2


	update #values_temp set countRecord=(select count(number) from per_ajad_read where persoon=DirUser and kommentaar=RegistrationNumber)
	update #values_temp set DocNr = (select number from per_ajad_read where persoon=DirUser and kommentaar=RegistrationNumber) where countRecord=1
	update #values_temp set DocRow = (select rn from per_ajad_read where persoon=DirUser and kommentaar=RegistrationNumber and number=DocNr) where countRecord=1
	
	select * from #values_temp


if (select top 1 dd_reg_nr from #values_temp) = (select top 1 setting from settings where id like '%firma_regnr%')
begin
	if 0 in (select countRecord from #values_temp) 
		begin
			
			set @number = (select max(number)+1 from per_ajad)

			insert into per_ajad (
				number
				,ts
				,selgitus
			)
				select 
					@number
					,getdate()
					,concat('Darbnespēju lapu imports',' ',getdate(),' ',@cu)  
					

				insert into per_ajad_read (number,rn,persoon,nimi,r_liik,r_aeg1,r_aeg2,kommentaar)

					select
						@number
						,ROW_NUMBER() OVER(ORDER BY RegistrationNumber)
						,(select kood from kasutajad where replace(isikukood,'-','') = PersonID)
						,concat(FirstName,' ',LastName )
						,(case when (CertificateType = 'A') then ('SICK_LIST') when (CertificateType = 'B') then ('SICK_LIST_B')end)
						,cast(DATEADD(HOUR,24,StartDate) as date)
						,cast(DATEADD(HOUR,24,EndDate) as date)
						,RegistrationNumber
					from #values_temp where countRecord = 0 and StatusText != N'Anulēta'
		end
		else if 1 in (select countRecord from #values_temp)
			begin
				update per_ajad_read
				set r_aeg2 = cast(z.EndDate as date)
				from (select * from #values_temp where countRecord = 1)z 
				where r_aeg2 is null and number = z.DocNr and z.CountRecord = 1 and z.DocRow = per_ajad_read.rn
			end
end
		else
			begin
				select N'Nepareizs reģistrācijas nr.'
			end

		

	/*
select count(distinct RegistrationNumber), count(EndDate) from #values_temp

declare @regnr nvarchar(max)
 select @regnr = RegistrationNumber from #values_temp

	if (select count(kommentaar) from per_ajad_read where kommentaar = @regnr) = 0 
		begin
			
			set @number = (select max(number)+1 from per_ajad)

			insert into per_ajad (
				number
				,ts
			)
				select 
					@number
					,getdate()
					

				insert into per_ajad_read (number,persoon,nimi,r_liik,r_aeg1,r_aeg2,kommentaar	)

					select
						@number
						,(select kood from kasutajad where replace(isikukood,'-','') = PersonID)
						,concat(FirstName,' ',LastName )
						,(case when (CertificateType = 'A') then ('SICK_LIST') when (CertificateType = 'B') then ('SICK_LIST_B')end)
						,StartDate
						,EndDate
						,RegistrationNumber
					from #values_temp 
			end
		else
			begin
			*/
			/*
				update per_ajad_read
				set 
				r_aeg2 = z.EndDate
				,kommentaar = z.RegistrationNumber
				from (select * from #values_temp where RegistrationNumber = @regnr)z

				where z.RegistrationNumber = @regnr
				*/
				

/*
		update per_ajad_read
		set r_aeg2 = z.EndDate
		from (select * from #values_temp)z 
		where r_aeg2 is null and @number = number
*/



DROP TABLE IF EXISTS  #values_temp

delete from int_import_dat where cu = @key


GO
