SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









ALTER PROCEDURE [dbo].[after_save_klient] @moodul nvarchar(32)=NULL, @number int=NULL, @tegevus nvarchar(32)=NULL, @tyyp nvarchar(32)=NULL, @kood nvarchar(32)=NULL AS
declare @temp table
		(
		rowNr int,
		project nvarchar(255),
		master nvarchar(255)
		)
create table #tempp
		(
		rowNr int,
		project nvarchar(255),
		master nvarchar(255)
		)
create table #projectBalanceSums  (project nvarchar(max), debit decimal(15,4), credit decimal(15,4), total decimal(15,4))
		declare @rowNr int, @project nvarchar(255),@master nvarchar(255), @pcount decimal(15,0), @sql nvarchar(max)
declare @msg nvarchar(max)

if @moodul = 'ressurs'
	begin
		select 
		number, 
		rn,
		objektid,
		(select dbo.levelobjekt(objektid,0)) o0,
		(select dbo.levelobjekt(objektid,1)) o1,
		(select dbo.levelobjekt(objektid,2)) o2,
		(select dbo.levelobjekt(objektid,3)) o3,
		(select dbo.levelobjekt(objektid,4)) o4,
		(select dbo.levelobjekt(objektid,5)) o5,
		(select dbo.levelobjekt(objektid,6)) o6,
		(select dbo.levelobjekt(objektid,7)) o7,
		(select dbo.get_objekt_hierarhiad((select dbo.levelobjekt(objektid,6)))) uObj,
		cast((select dbo.levelobjekt((select dbo.get_objekt_hierarhiad((select dbo.levelobjekt(objektid,6)))),0)) as nvarchar(255)) c0,
		cast((select dbo.levelobjekt((select dbo.get_objekt_hierarhiad((select dbo.levelobjekt(objektid,6)))),2)) as nvarchar(255)) c2,
		cast((select dbo.levelobjekt((select objekt from projektid where kood=ressursid_read.projekt),0)) as nvarchar(255)) p0,
		cast((select dbo.levelobjekt((select objekt from projektid where kood=ressursid_read.projekt),2)) as nvarchar(255)) p2,
		projekt
into #t1 from ressursid_read where number=@number

select 
			number,
			rn, 
			objektid,
			iif(isnull(p0,'')!='',p0,iif(isnull(o0,'')!='',o0,isnull(c0,''))) o0 ,
			iif(isnull(o1,'')!='',o1,'') o1 ,
			iif(isnull(p2,'')!='',p2,iif(isnull(o2,'')!='',o2,isnull(c2,''))) o2 ,
			iif(isnull(o3,'')!='',o3,'') o3 ,
			iif(isnull(o4,'')!='',o4,'') o4 ,
			iif(isnull(o5,'')!='',o5,'') o5 ,
			iif(isnull(o6,'')!='',o6,'') o6 ,
			iif(isnull(o7,'')!='',o7,'') o7 ,
			iif(isnull(o4,'')!='' and isnull(projekt,'')!='',projekt,iif(isnull(o4,'')!='' and isnull(projekt,'')='','10002',projekt)) projekt
into #t2 from #t1

update ressursid_read set objektid=z.objekt, projekt=z.projekt from (
select number, rn,objektid, replace(replace(replace(replace(convert(nvarchar(max),isnull(o0,'')+','+isnull(o2,'')+','+isnull(o4,'')+','+isnull(o6,'')),',,',','),',,',','),',,',','),',,',',') objekt, projekt from #t2) z
where ressursid_read.number=z.number and ressursid_read.rn=z.rn

drop table #t1
drop table #t2
	end
if @moodul='sissetulek'
	BEGIN
		update ladu_sissetulekud set hankija_arve=(select top 1 replace(hankija_arve,' ','') from ladu_sissetulekud where number=@number) where number=@number
	END

if @moodul='oarve'
	BEGIN
		update or_arved set 
		hankija_arve=(select top 1 replace(hankija_arve,' ','') from or_arved where number=@number),
		hankija_nimi=(SELECT TOP 1 supplier.nimi FROM hankijad supplier WHERE supplier.kood = or_arved.hankija_kood)
		where number=@number
	END
if @moodul='arve' --and 1=2
	BEGIN
		declare project  insensitive cursor for 
		select rn, projekt, (select master from projektid with(nolock) where kood=mr_arved_read.projekt) from mr_arved_read where number = @number and isnull(projekt,'')!=''
		open project 
		FETCH NEXT FROM project INTO @rowNr, @project, @master
			WHILE @@FETCH_STATUS = 0
						BEGIN
							if isnull(@master,'')!='' 

							BEGIN
								begin
								while @master is not  null or @master=@project
								begin
								set @project = @master
								set @master = (select master from projektid where kood=@project)
								insert @temp
								select @rowNr, @project, @master
								end
								end
													end
												ELSE
												insert @temp
												select @rowNr, @project, @master
					FETCH NEXT FROM project INTO @rowNr, @project, @master
						END 
				CLOSE project 
			DEALLOCATE project
		select * from @temp
		delete from @temp where isnull(master,'')!=''
		select @pcount = count(distinct project) from @temp
		--update mr_arved set kommentaar=@pcount where number=@number

		if @pcount=1
		BEGIN
			if (isnull((select projekt from mr_arved where number=@number),'')='')
				BEGIN
					update mr_arved 
						set 
							projekt=(select distinct project from @temp)
					where number=@number 
				end
		end
		else
		update mr_arved 
						set 
							projekt=NULL
					where number=@number
	END
if @moodul='projekt'
	begin
	select * from projektid where kood=@kood
	if (select suletud from projektid where kood=@kood)=1
		begin
			
			declare project  insensitive cursor for 
		select @kood, (select master from projektid with(nolock) where kood=@kood)
		open project 
		FETCH NEXT FROM project INTO @project, @master
			WHILE @@FETCH_STATUS = 0
						BEGIN
							insert #tempp
							select @rowNr, @project, @master
							if isnull(@master,'')!=''

							BEGIN
								begin
								while @master is not  null
								begin
								set @project = @master
								set @master = (select master from projektid where kood=@project)
								insert #tempp
								select @rowNr, @project, @master
								end
								end
													end
												ELSE
												insert #tempp
												select @rowNr, @project, @master
					FETCH NEXT FROM project INTO @project, @master
						END 
				CLOSE project 
			DEALLOCATE project

		select @pcount = count(distinct project) from @temp
		
		insert #projectBalanceSums (project)
		select distinct (project) from #tempp
		declare @accountsList nvarchar(max)
		select @accountsList = ''''+replace(param1,',',''',''')+'''' from tr_params where kood='Project_closing_Accounts'
		
	select @sql= '
	update #projectBalanceSums set debit=isnull((select sum(baas1deebet) from fin_kanded_read where projekt=project and baas1deebet>=0 and konto in ('+@accountsList+')),0) 
	
	update #projectBalanceSums set debit=debit+isnull((select sum(baas1kreedit*(-1)) from fin_kanded_read where projekt=project and baas1kreedit<0 and konto in ('+@accountsList+')),0)
	
	update #projectBalanceSums set credit=isnull((select sum(baas1kreedit) from fin_kanded_read where projekt=project and baas1kreedit>=0  and konto in('+@accountsList+')),0)

	update #projectBalanceSums set debit=debit+isnull((select sum(baas1deebet*(-1)) from fin_kanded_read where projekt=project and baas1deebet<0 and konto in('+@accountsList+')),0)'
	
	exec(@sql)
		update #projectBalanceSums set total=debit - credit
		select * from #projectBalanceSums
		if (select count(*) from #projectBalanceSums where total<>0)>=1
			begin
				delete from int_asp_alerts where unit=@moodul and number=@kood
				update projektid set suletud=0 where kood=@kood

				declare @msg1 nvarchar(max)

				select @msg1 = convert(nvarchar(max),(select N'Projektu nevar slēgt, jo kādā no Transporta parametra Control kontiem ('+(select param1 from tr_params where kood='Project_closing_Accounts')+') ir atlikums: \n Projekta '+convert(nvarchar(max),@kood)+' bilance ir '+convert(nvarchar(max),total) from #projectBalanceSums where total<>0 for xml path (''),type,elements))
				INSERT INTO int_asp_alerts (unit,NUMBER,tekst) SELECT @moodul, @kood, @msg1 

				
			end
		
			end
			if (select suletud from projektid where kood=@kood)='0'
			begin
			
				delete from int_asp_alerts where unit=@moodul and number=@kood
				select * from int_asp_alerts
			end
	
	end
drop table #tempp
drop table #projectBalanceSums




GO
