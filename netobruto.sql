USE [ocra_demo_madars_lv]
GO

/****** Object:  StoredProcedure [dbo].[after_kinnita_klient]    Script Date: 30/06/2023 12:22:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[after_kinnita_klient] @tyyp nvarchar(32), @number nvarchar(32)
AS

if (@tyyp='ressurs')
BEGIN
declare @monthcode nvarchar(256)= (select kommentaar from ressursid where number=@number)
if ((LEN(@monthcode)=6) AND (ISNUMERIC(@monthcode)=1)) --NETO TO BRUTO
BEGIN

	-- ______________________________________________________________________________INPUT VALUE SELECTION BLOCK

	create table #INPUT (   --Table for all needed neto->bruto values 
		PERSON nvarchar(64),
		NETbonusrow money,
		NETbonus money,
		TAXfree money,
		LIM20gross money,
		GROSSother money,
		NETother money,
		project nvarchar(64),
		rowdate datetime
	)
	create table #netbonus (  --Neto bonus table, taken from 'Resources'
		PERSON nvarchar(64),
		NETbonus money,
		project nvarchar(64),
		rowdate datetime
	)
	create table #taxfree (  --Income tax relief table, from tax calculations
		PERSON nvarchar(64),
		TAXfree money
	)
	create table #lim20gross (  --Income tax formula limit table, from tax formulas
		PERSON nvarchar(64),
		LIM20gross money
	)
	create table #salaryother (  --Neto and bruto salaries from 'Salaries'
		PERSON nvarchar(64),
		NETother money,
		GROSSother money
	)


	insert into #netbonus 
	select 
		rr.tegija,
		SUM(CAST(rr.kommentaar AS money)),
		rr.projekt,
		rr.aeg
	from ressursid r 
	inner join ressursid_read rr on r.number=rr.number 
	where r.kommentaar=@monthcode
		and ISNUMERIC(rr.kommentaar)=1
		and ((select klass from artiklid as ai where ai.kood=rr.artikkel)='NETOBRUTO') 
		and r.number=@number
	group by rr.projekt, rr.aeg, tegija;

	insert into #taxfree
	select 
		persoon, 
		sum(maksuvaba)
	from per_palgad_maksud
	where kuukood=@monthcode
	group by persoon;

	insert into #lim20gross
	select distinct 
		pm.persoon, 
		sum(mr.alates)
	from per_palgad_maksud pm 
	inner join per_maksuvalemid_read mr on pm.maksuvalem=mr.kood 
	inner join per_maksuvalemid m on mr.kood=m.kood 
	where m.klass='IIN' 
		and pm.kuukood=@monthcode 
		and pm.versioon=mr.versioon 
		and pm.rn>0 
		group by pm.persoon, pm.maksuvalem, pm.rn;

	insert into #salaryother
	select 
		pr.persoon, 
		sum(pr.neto),
		sum(pr.bruto)
	from per_palgad_read pr 
	inner join per_palgad p on p.number=pr.number 
	where p.kuukood=@monthcode
	group by persoon;

	insert into #INPUT   --Inserting all temp table values into one INPUT temp table
	select
		nb.PERSON,
		ISNULL(nb.NETbonus, 0),
		(select SUM(NETbonus) from #netbonus ne where ne.PERSON=nb.PERSON group by ne.PERSON),
		ISNULL(tf.TAXfree, 0),
		ISNULL(l2g.LIM20gross, 0),
		ISNULL(so.GROSSother, 0),
		ISNULL(so.NETother, 0),
		nb.project,
		nb.rowdate
	from #netbonus nb
		inner join #taxfree tf on nb.PERSON = tf.PERSON
		inner join #lim20gross l2g on nb.PERSON = l2g.PERSON
		inner join #salaryother so on nb.PERSON = so.PERSON



	-- _________________________________________________________________________________NETO -> BRUTO calculation block

	declare @PERSON nvarchar(64),     -- cursor variables
			@NETbonus money,
			@NETbonusrow money,
			@TAXfree money,
			@LIM20gross money,
			@GROSSother money,
			@NETother money,
			@project nvarchar(64),
			@rowdate datetime

	declare @NETtotal money     --neto salary + neto bonus
	declare @GROSStotal money     --bruto salary in calculation (NETtotal / 0.89)
	declare @GROSSbonus money     --total bruto bonus in calculation for person
	declare @LIM20net money     --neto lim20 (multiplied by 0.712)
	declare @TAXfree20 money     --taxfree * 0.2
	declare @NETcalc money      --NETtotal - TAXfree20
	declare @GROSStotal20 money      --LIM20gross
	declare @NETtotal23 money       --NETcalc - LIM20net
	declare @GROSStotal23 money        --NETtotal23/0.682

	declare @PROPORTION float			--Proportional division for update
	declare @GROSSbonusrow money 		--Proportional gross bonus for row

	declare @val07 money		--calculation coeficient changes in 2021
	declare @val06 money
	declare @val08 money
	if ((SELECT SUBSTRING(@monthcode,1,4))='2020')
	BEGIN
		set @val07 = 0.712
		set @val06 = 0.682
		set @val08 = 0.89
	END
	ELSE
	BEGIN
		set @val07 = 1
		set @val06 = 0.716
		set @val08 = 1
	END


	declare netobruto cursor for
		select PERSON, NETbonusrow, NETbonus, TAXfree, LIM20gross, GROSSother, NETother, project, rowdate
		from #INPUT

	OPEN netobruto
	FETCH NEXT FROM netobruto into @PERSON, @NETbonusrow, @NETbonus, @TAXfree, @LIM20gross, @GROSSother, @NETother, @project, @rowdate
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		IF @PERSON!=''
		BEGIN
		set @NETtotal = (@NETbonus + @NETother)
		--update ressursid set kommentaar=kommentaar+CONVERT(NVARCHAR(MAX),@NETtotal) WHERE NUMBER=@NUMBER
		--
		IF  ( --_____________IF TEST FOR RIGHT ALGORITHM SIDE (quickest calculation)
				(
					(@TAXfree>=@NETtotal) 
					AND 
					((@NETtotal/@val08)<=1667)
				)
				OR
				(
					(@TAXfree>=@NETtotal) 
					AND 
					((@NETtotal/@val08)>1667)
					AND
					(@TAXfree>=(@NETtotal + ((@NETtotal/@val08-1667)*0.15)))
				)
			)
							BEGIN
								set @GROSStotal=@NETtotal/@val08
								set @GROSSbonus=@GROSStotal-@GROSSother --FINAL VALUE
							END



		ELSE IF ( --_____________IF TEST FOR LEFT ALGORITHM SIDE
					(
						@TAXfree<@NETtotal
					)
					OR
					(
						(@TAXfree>=@NETtotal) 
						AND 
						((@NETtotal/@val08)>1667)
						AND
						(@TAXfree<(@NETtotal + ((@NETtotal/@val08-1667)*0.15)))
					)
				)

				--EXEC DBO.after_kinnita_klient 'RESURSS',3
							BEGIN
									set @LIM20net=@LIM20gross*@val07
									set @TAXfree20=@TAXfree*0.23
									set @NETcalc=@NETtotal-@TAXfree20

									--update ressursid set kommentaar=kommentaar+CONVERT(NVARCHAR(MAX),@TAXfree20) WHERE NUMBER=@NUMBER
									IF (@NETcalc<@LIM20net)
										BEGIN
											set @GROSStotal=@NETcalc/@val07
											set @GROSSbonus=@GROSStotal-@GROSSother --FINAL VALUE
										END
									ELSE IF (@NETcalc>=@LIM20net)
										BEGIN
											set @GROSStotal20 = @LIM20gross
											set @NETtotal23=@NETcalc-@LIM20net
											set @GROSStotal23=@NETtotal23/@val06
											set @GROSStotal=@GROSStotal20+@GROSStotal23
											set @GROSSbonus=@GROSStotal-@GROSSother --FINAL VALUE
										END
							END

		set @GROSSbonus=ROUND(@GROSSbonus, 2)

		--update ressursid set kommentaar=kommentaar+'/'+CONVERT(NVARCHAR(MAX),@NETbonusrow)+'/' WHERE NUMBER=@NUMBER

		set @PROPORTION=ROUND((cast(@NETbonusrow as float)/cast(@NETbonus as float)),10)
		set @GROSSbonusrow=ROUND(@GROSSbonus*@PROPORTION,2)
		--update ressursid set kommentaar=kommentaar+'/'+CONVERT(NVARCHAR(MAX),@NUMBER)+'/' WHERE NUMBER=@NUMBER

		IF ISNULL(@PROJECT,'')=''
			BEGIN
				update ressursid_read	-- setting the FINAL VALUE into the corresponding sum field
				SET
					summa=@GROSSbonusrow,
					hind=@GROSSbonusrow/kogus
				where number=@number
				and tegija=@PERSON
				--and PROJEKT=@project
				and aeg=@rowdate
			END
			IF ISNULL(@PROJECT,'')!=''
			BEGIN
				update ressursid_read	-- setting the FINAL VALUE into the corresponding sum field
				SET
					summa=@GROSSbonusrow,
					hind=@GROSSbonusrow/kogus
				where number=@number
				and tegija=@PERSON
				and PROJEKT=@project
				and aeg=@rowdate
			END
		END
		FETCH NEXT FROM netobruto into @PERSON, @NETbonusrow, @NETbonus, @TAXfree, @LIM20gross, @GROSSother, @NETother, @project, @rowdate
	END

	close netobruto
	deallocate netobruto

	drop table #INPUT
	drop table #lim20gross
	drop table #salaryother
	drop table #taxfree
	drop table #netbonus


	
END

END
GO


