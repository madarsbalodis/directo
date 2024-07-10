SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[int_hooldus_klient_pfpisk_tb] @aeg1 datetime, @aeg2 datetime, @year_rep bit AS

--INSERT INTO int_hooldus_klient (rn, nimi, formaat, aru_tyyp) 
--VALUES ('_pfpisk_tb', 'PFPISK as table', 'tabel','personal');

--INSERT INTO int_hooldus_klient_params  (aru_id, nimi, tyyp, order_no) 
--VALUES ('_pfpisk_tb', 'gads', 'checkbox', 1);

DECLARE @person NVARCHAR(50)
DECLARE @begin DATE -- gada sākums
DECLARE @start DATE -- DA sākums
DECLARE @end DATE -- DA beigas
DECLARE @check BIT -- pārbaude temp tabulu veidošanai
DECLARE @row SMALLINT
DECLARE @CalcType nvarchar(32)
create table #pfpisk_bruto (persoon nvarchar(32), bruto_sum decimal(15,4), tsd nvarchar(15))
create table #pfpisk_soc (persoon nvarchar(32), soc_sum decimal(15,4), tsd nvarchar(15))
create table #pfpisk_iin (persoon nvarchar(32), iin_sum decimal(15,4), tsd nvarchar(15))
create table #pfpisk_iin_atv (persoon nvarchar(32), maksuvaba decimal(15,4),maksuvaba_personal decimal(15,4),maksuvaba_related decimal(15,4), tsd nvarchar(15))
create table #pfpisk_taxfree (persoon nvarchar(32), salary_sum decimal(15,4),taxfree_sum decimal(15,4), tsd nvarchar(15))
create table #pfpisk_DA (kasutaja nvarchar(32), aeg1 datetime, aeg2 datetime, rn int, rv int, etapp nvarchar(32), lop_alus nvarchar(32), CalcType nvarchar(32))
declare @repMonth decimal(15,0)
declare @repYear decimal(15,0)
select @repMonth = month(@aeg1), @repYear = year(@aeg1)
select @repYear = iif(@repMonth<4,@repyear,@repyear+1)

SET @row=(select rn from int_print where id='int_hooldus_klient_pfpisk' and dokument='xml_till_04'+convert(nvarchar(max),@repYear) and suletud<>1)
SET @begin=DATEFROMPARTS(YEAR(@aeg1),1,1)
SET @check=0

--atlasām DA rindas, kurās ir norādīts beigu ziņu kods un beigu datums ir pārskata periodā
/*
insert into #pfpisk_DA
SELECT kasutaja, CASE WHEN aeg1<=@begin THEN @begin ELSE aeg1 END as aeg1, aeg2, rn, rv, etapp, lop_alus, 'Salary'
FROM kasutajad_suhe

insert #pfpisk_DA
		select a.persoon, b.aeg1, b.aeg2,a.rn,a.rn, '11','','Honorarium'  from per_palgad_read a inner join per_palgad b on a.number=b.number inner join per_palgavalemid c on a.valem=c.kood where cast(b.aeg1 as date) between cast(@aeg1 as date) and cast(@aeg2 as date)  and cast(b.aeg2 as date) between cast(@aeg1 as date) and cast(@aeg2 as date) and c.klass='AA'
*/
IF @year_rep=0
INSERT into #pfpisk_DA SELECT kasutaja, CASE WHEN aeg1<=@begin THEN @begin ELSE aeg1 END as aeg1, aeg2, rn, rv, etapp, lop_alus,kommentaar
FROM kasutajad_suhe
WHERE
lop_alus IS NOT NULL and lop_alus!='' and lop_alus!='PM' and (aeg2 between @aeg1 and @aeg2) and isnull(charindex('papildu',kommentaar),0)=0 and aeg1 IS NOT NULL
ELSE
INSERT into #pfpisk_DA SELECT kasutaja, CASE WHEN aeg1<=@begin THEN @begin ELSE aeg1 END as aeg1, @aeg2, rn, rv, etapp, lop_alus,'SALARY'
FROM kasutajad_suhe
WHERE
(aeg2 IS NULL or aeg2 > @aeg2) and isnull(charindex('papildu',kommentaar),0)=0 and aeg1 IS NOT NULL

insert #pfpisk_DA
		select a.persoon, b.aeg1, b.aeg2,a.rn,a.rn, '11','','Honorarium'  from per_palgad_read a inner join per_palgad b on a.number=b.number inner join per_palgavalemid c on a.valem=c.kood where cast(b.aeg1 as date) between cast(@aeg1 as date) and cast(@aeg2 as date)  and cast(b.aeg2 as date) between cast(@aeg1 as date) and cast(@aeg2 as date) and c.klass='AA'

IF (SELECT count(kasutaja) from #pfpisk_DA)>0 -- ja pārskata periodā ir darbinieki, kam beigušās DA, tad turpinām
BEGIN

UPDATE da1 -- tiek atjaunots DA sākuma datums, salīdzinot, kurš ir agrākais no saistītām DA rindām, bet jābūt ne vēlākam par gada sākumu
SET da1.aeg1=
(CASE
WHEN da1.aeg1>(SELECT min(da2.aeg1) FROM kasutajad_suhe da2 WHERE da2.kasutaja=da1.kasutaja and da2.rv=da1.rv) AND @begin<(SELECT min(da2.aeg1) FROM kasutajad_suhe da2 WHERE da2.kasutaja=da1.kasutaja and da2.rv=da1.rv) THEN (SELECT min(da2.aeg1) FROM kasutajad_suhe da2 WHERE da2.kasutaja=da1.kasutaja and da2.rv=da1.rv)
WHEN da1.aeg1>(SELECT min(da2.aeg1) FROM kasutajad_suhe da2 WHERE da2.kasutaja=da1.kasutaja and da2.rv=da1.rv) AND @begin>(SELECT min(da2.aeg1) FROM kasutajad_suhe da2 WHERE da2.kasutaja=da1.kasutaja and da2.rv=da1.rv) THEN @begin
ELSE aeg1 END) FROM #pfpisk_DA da1 where CalcType = 'Salary'

-- izveidojam personu info tabulu
SELECT da.kasutaja, kd.nimi, kd.isikukood, da.aeg1, da.aeg2, da.CalcType INTO #pfpisk_pers
FROM #pfpisk_DA da
INNER JOIN kasutajad kd on da.kasutaja=kd.kood

-- apstrādājam katru personu, atlasot info atbilstoši tās DA beigu un sākuma adatumam
DECLARE db_cursor CURSOR FOR 
SELECT kasutaja, aeg1, aeg2,CalcType
FROM #pfpisk_DA 

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @person, @start, @end, @calcType

WHILE @@FETCH_STATUS = 0  
BEGIN

IF @check=0 -- pirmais cikls, kurā tiek izveidotas temp tabulas ar select into
BEGIN
if @CalcType='Salary'
	begin
			-- bruto summas no algu aprēķiniem
			insert INTO #pfpisk_bruto
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as bruto_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass not in ('ATVILKUMS','AVANSS','AA') and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')

			-- soc summas no nodokļu aprēķiniem
			insert INTO #pfpisk_soc
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as soc_sum, isnull(ppv.tsd,'1001') as tsd  
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('SOC_DN') and ppv.klass not in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			-- iin summas no nodokļu aprēķiniem
			insert INTO #pfpisk_iin 
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as iin_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('IIN') and ppv.klass not in ('AA') and ppm.persoon=@person
			GROUP BY persoon,  isnull(ppv.tsd,'1001')

			-- atvieglojumu summs no nodokļu aprēķiniem
			insert INTO #pfpisk_iin_atv
			SELECT ppm.persoon, sum(isnull(ppm.maksuvaba,0)) as maksuvaba, sum(isnull(ppm.maksuvaba_personal,0)) as maksuvaba_personal, sum(isnull(ppm.maksuvaba_related,0)) as maksuvaba_related, isnull(ppv.tsd,'1001') as tsd  
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass not in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			-- neapliekamās summas no algu formulām
			insert INTO #pfpisk_taxfree
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as salary_sum, sum(isnull(ppv.maksustatav,0)) as taxfree_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass not in ('ATVILKUMS','AVANSS','AA') and isnull(ppv.maksustatav,0)>0 and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')
			SET @check=1
			END

			ELSE -- ja nav pirmais cikls, tad papildinām jau izveidotās temp tabulas
			BEGIN

			INSERT INTO #pfpisk_bruto 
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as bruto_sum, isnull(ppv.tsd,'1001') as tsd
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass not in ('ATVILKUMS','AVANSS','AA') and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_soc
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as soc_sum, isnull(ppv.tsd,'1001') as tsd
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('SOC_DN') and ppv.klass not in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_iin 
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as iin_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('IIN') and ppv.klass not in ('AA') and ppm.persoon=@person
			GROUP BY persoon,  isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_iin_atv
			SELECT ppm.persoon, sum(isnull(ppm.maksuvaba,0)) as maksuvaba, sum(isnull(ppm.maksuvaba_personal,0)) as maksuvaba_personal, sum(isnull(ppm.maksuvaba_related,0)) as maksuvaba_related, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass not in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_taxfree
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as salary_sum, sum(isnull(ppv.maksustatav,0)) as taxfree_sum, isnull(ppv.tsd,'1001') as tsd
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass not in ('ATVILKUMS','AVANSS','AA') and isnull(ppv.maksustatav,0)>0 and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')
			END
		end
if @CalcType='Honorarium'
	begin
			-- bruto summas no algu aprēķiniem
			insert INTO #pfpisk_bruto
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as bruto_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass in ('AA') and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')

			-- soc summas no nodokļu aprēķiniem
			insert INTO #pfpisk_soc
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as soc_sum, isnull(ppv.tsd,'1001') as tsd  
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('SOC_DN') and ppv.klass in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			-- iin summas no nodokļu aprēķiniem
			insert INTO #pfpisk_iin 
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as iin_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('IIN') and ppv.klass in ('AA') and ppm.persoon=@person
			GROUP BY persoon,  isnull(ppv.tsd,'1001')

			-- atvieglojumu summs no nodokļu aprēķiniem
			insert INTO #pfpisk_iin_atv
			SELECT ppm.persoon, sum(isnull(ppm.maksuvaba,0)) as maksuvaba, sum(isnull(ppm.maksuvaba_personal,0)) as maksuvaba_personal, sum(isnull(ppm.maksuvaba_related,0)) as maksuvaba_related, isnull(ppv.tsd,'1001') as tsd  
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			-- neapliekamās summas no algu formulām
			insert INTO #pfpisk_taxfree
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as salary_sum, sum(isnull(ppv.maksustatav,0)) as taxfree_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass in ('AA') and isnull(ppv.maksustatav,0)>0 and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')
			SET @check=1
			END

			ELSE -- ja nav pirmais cikls, tad papildinām jau izveidotās temp tabulas
			BEGIN

			INSERT INTO #pfpisk_bruto 
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as bruto_sum, isnull(ppv.tsd,'1001') as tsd
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass in ('AA') and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_soc
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as soc_sum, isnull(ppv.tsd,'1001') as tsd
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('SOC_DN') and ppv.klass in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_iin 
			SELECT ppm.persoon, sum(isnull(ppm.summa,0)) as iin_sum, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_maksuvalemid pm on ppm.maksuvalem=pm.kood 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and pm.versioon=ppm.versioon and pm.klass in ('IIN') and ppv.klass in ('AA') and ppm.persoon=@person
			GROUP BY persoon,  isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_iin_atv
			SELECT ppm.persoon, sum(isnull(ppm.maksuvaba,0)) as maksuvaba, sum(isnull(ppm.maksuvaba_personal,0)) as maksuvaba_personal, sum(isnull(ppm.maksuvaba_related,0)) as maksuvaba_related, isnull(ppv.tsd,'1001') as tsd 
			FROM per_palgad_maksud ppm 
			inner join per_palgad pp on ppm.number=pp.number 
			inner join per_palgavalemid ppv on ppm.palgavalem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass in ('AA') and ppm.persoon=@person
			GROUP BY ppm.persoon,  isnull(ppv.tsd,'1001')

			INSERT INTO #pfpisk_taxfree
			SELECT ppr.persoon, sum(isnull(ppr.bruto,0)) as salary_sum, sum(isnull(ppv.maksustatav,0)) as taxfree_sum, isnull(ppv.tsd,'1001') as tsd
			FROM per_palgad_read ppr 
			INNER JOIN per_palgad pp on ppr.number=pp.number 
			INNER JOIN per_palgavalemid ppv on ppr.valem=ppv.kood
			WHERE (convert(date, pp.aeg) between @start and EOMONTH(@end)) and (convert(date, pp.aeg2) between @start and EOMONTH(@end)) and ppv.klass in ('AA') and isnull(ppv.maksustatav,0)>0 and ppr.persoon=@person
			GROUP BY persoon, isnull(ppv.tsd,'1001')
			END
      FETCH NEXT FROM db_cursor INTO @person, @start, @end, @calcType
END 
CLOSE db_cursor  
DEALLOCATE db_cursor 

-- saite uz xml izdrukas formu norādītajam periodam
IF @year_rep=0
SELECT '<a href="javascript:nop()" onclick="javascript:avaWin(''yld_print.asp?1=1&param0=1&row='+CONVERT(nvarchar,@row,104)+'&moodul=int_hooldus_klient_pfpisk&print=no&mida=xsl&aeg1='+CONVERT(nvarchar,@aeg1,104)+'&aeg2='+CONVERT(nvarchar,@aeg2,104)+'&1=1'')">XML faila eksports</a>'
ELSE
SELECT '<a href="javascript:nop()" onclick="javascript:avaWin(''yld_print.asp?1=1&param1=1&row='+CONVERT(nvarchar,@row,104)+'&moodul=int_hooldus_klient_pfpisk&print=no&mida=xsl&aeg1='+CONVERT(nvarchar,@aeg1,104)+'&aeg2='+CONVERT(nvarchar,@aeg2,104)+'&1=1'')">XML faila eksports</a>'

-- apvienojam visas temp tabulas kopējā rezultātu tabulā, personas kods kā saite uz personas kartiņu, et nosaukums kā saite uz algas atskaiti
SELECT 
(SELECT '<a href="javascript:avaDok(''persoon'','''+CONVERT(nvarchar(32),kood)+''')">'+CONVERT(nvarchar(32),kood)+'</a>' FROM kasutajad WHERE kood=pp.kasutaja) as kods,
(SELECT ' <a href="javascript:nop()" onclick="javascript:avaWin(''per_aru_palgad.asp?t_period=0&aeg1='+CONVERT(nvarchar,pp.aeg1,104)+'&aeg2='+CONVERT(nvarchar,EOMONTH(pp.aeg2),104)+'&d_klass2=PERSONAL&persoon='+pp.kasutaja+'&pv_tyyp=0&d_klass3=palk&read=-1&kasutatud_maksud=-1&sortby=0&vaade=1&xsl_row1=5197&clr1=1&showall=yes'')">'+pp.nimi+'</a>') as vards,
pp.isikukood as pers_kods, pp.aeg1 as periods_no, pp.aeg2 as periods_lidz, pb.tsd as ien_veids, pb.bruto_sum, ps.soc_sum, pi.iin_sum, pia.maksuvaba as atviegl_sum, pia.maksuvaba_personal as neapl_min, pia.maksuvaba_related as atviegl_apg, 
CASE
WHEN (pia.maksuvaba-pia.maksuvaba_personal-pia.maksuvaba_related) > 0.03 THEN (pia.maksuvaba-pia.maksuvaba_personal-pia.maksuvaba_related) ELSE 0.00 END as atviegl_pap,
CASE 
WHEN ptf.salary_sum > ptf.taxfree_sum THEN ptf.taxfree_sum
WHEN ptf.salary_sum < ptf.taxfree_sum and ptf.taxfree_sum>0 THEN ptf.salary_sum END as neapl_ien
FROM #pfpisk_pers pp 
inner join #pfpisk_bruto pb on pp.kasutaja=pb.persoon
left join #pfpisk_soc ps on ps.persoon=pb.persoon and ps.tsd=pb.tsd
left join #pfpisk_iin pi on pi.persoon=pb.persoon and pi.tsd=pb.tsd
left join #pfpisk_iin_atv pia on pia.persoon=pb.persoon and pia.tsd=pb.tsd
left join #pfpisk_taxfree ptf on ptf.persoon=pb.persoon and ptf.tsd=pb.tsd
END

ELSE SELECT N'Nav rezultātu šim periodam' -- ja nav neviena darbinieka, kam pārskata periodā beidzas DA



GO
