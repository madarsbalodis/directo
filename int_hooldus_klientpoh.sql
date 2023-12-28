USE [ocra_merko_buve_lv]
GO

/****** Object:  StoredProcedure [dbo].[int_hooldus_klientPOH]    Script Date: 28/12/2023 09:24:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[int_hooldus_klientPOH] @aeg1 datetime, @aeg2 datetime, @aru nvarchar(32), @projekt NVARCHAR(max), @nonull bit=null
AS
if isnull(@aru,'')='' BEGIN
	select 'Aruanne?'
	return
end

DECLARE @cu nvarchar(32)
IF APP_NAME() LIKE '%,user:%' SET @cu=SUBSTRING(APP_NAME(),CHARINDEX(',user:',APP_NAME())+6,32)
/*
	insert into int_hooldus_klient (rn,nimi,formaat,oigus,aru_tyyp) select 'POH','Projektide omahind','tabel','int_hooldus_klientPOH','fin'
	delete int_hooldus_klient_params where aru_id='POH';insert into int_hooldus_klient_params (aru_id,nimi,tyyp,order_no) values ('POH','Aruanne','SELECT '',''+STUFF(CONVERT(NVARCHAR(max), (select top 20 '',''+kood+''|''+ltrim(replace(kirjeldus,''*oh*'','''')) FROM fin_aru_kasu with (nolock) where kirjeldus like ''*oh*%'' ORDER BY kood FOR XML PATH (''''))), 1, 1, '''')',10),('POH','Projekt','put_projekt',40),('POH','välista tühjad','checkbox',50)
	--SELECT STUFF(CONVERT(NVARCHAR(max), (select top 20 ','+kood+'|'+ltrim(replace(kirjeldus,'*oh*','')) FROM fin_aru_kasu with (nolock) where kirjeldus like '*oh*%' ORDER BY kood FOR XML PATH (''))), 1, 1, '')
	--
	int_aruanded
*/
select convert(nvarchar,@aeg1,104)+':'+convert(nvarchar,@aeg2,104) as Period,format(getdate(),'dd.MM.yyyy HH:mm') as [Report Date], @cu as [Report User]
set @aeg2=dateadd(ss,-1, @aeg2+1)
create table #tulem (t_objekt nvarchar(32), t_projekt nvarchar(32), enne nvarchar(max), rn int, nimi nvarchar(255))
declare @kontoin table (k nvarchar(32) primary key)
declare @level int=2, @kontod nvarchar(max)='', @sql nvarchar(max)='', @rn int=0, @rida int, @field nvarchar(255), @kaive money, @k money, @fields nvarchar(max)='', @fields_sum nvarchar(max)='', @fields_null nvarchar(max)=' WHERE ('
select @kontod+=kontod+'+' from fin_aru_kasu_read with (nolock) where kood=@aru and tyyp=1 and kontod!=''
insert into @kontoin select distinct x from dbo.get_in_konto(@kontod) where x!=''
insert into #tulem (t_objekt,t_projekt,rn) select distinct dbo.levelobjekt(objekt,@level),projekt,1
	from fin_kanded_read with (nolock) where 
		r_aeg between @aeg1 and @aeg2 and projekt!=''
		AND (@projekt IS NULL OR projekt IN (SELECT value FROM STRING_SPLIT(@projekt,',')))
		and konto in (select k from @kontoin)
delete #tulem where t_objekt is null or t_objekt=''
select @sql+='alter table #tulem add '+quotename(isnull(tekst,convert(nvarchar,number)))+' money;',
	@fields+=','+quotename(isnull(tekst,convert(nvarchar,number))), 
	@fields_null+=quotename(isnull(tekst,convert(nvarchar,number)))+'!=0 OR ',
	@fields_sum+=',sum('+quotename(isnull(tekst,convert(nvarchar,number)))+')'
	from fin_aru_kasu_read where kood=@aru order by number
exec(@sql)
if @nonull =1 set @fields_null+='rn!=1)' else set @fields_null=''
while 1=1 begin
	set @rida=null
	select top (1) @rn=number, @rida=number, @kontod=kontod, @field=quotename(isnull(tekst,convert(nvarchar,number))), @k=case when kontoklass=4 then 1 else -1 end from fin_aru_kasu_read with (nolock) where kood=@aru and tyyp=1 and kontod!='' and number>@rn order by number
	if @rida is null break
	set @rn=@rida
			set @sql='declare @kontoin table (k nvarchar(32) primary key);insert into @kontoin select distinct x from dbo.get_in_konto(@kontod) where x!='''';update #tulem set '+@field+'=(select @k*sum(isnull(baas1deebet,0)-isnull(baas1kreedit,0)) from fin_kanded_read f with (nolock) where f.r_aeg between @aeg1 and @aeg2 and f.projekt=#tulem.t_projekt and '',''+f.objekt+'','' like ''%''+#tulem.t_objekt+''%''
		and konto in (select k from @kontoin));UPDATE #tulem SET enne=isnull(enne,'''')+''&''+convert(nvarchar,@rida)+''=''+convert(nvarchar,'+@field+') where '+@field+'!=0'
--	print @sql
	EXECUTE sp_executesql @sql,N'@aeg1 datetime, @aeg2 datetime, @kontod nvarchar(max), @k money, @rida int',@aeg1=@aeg1, @aeg2=@aeg2, @kontod=@kontod, @k=@k, @rida=@rida
end
set @rn=0
while 1=1 begin
	set @rida=null
	select top (1) @rn=number, @rida=number, @kontod=kontod, @field=quotename(isnull(tekst,convert(nvarchar,number))), @k=case when kontoklass=4 then -1 else 1 end from fin_aru_kasu_read with (nolock) where kood=@aru and tyyp=2 and kontod!='' and number>@rn order by number
	if @rida is null break
			set @sql='UPDATE #tulem SET '+@field+'=@k*dbo.liida(@kontod,enne);UPDATE #tulem SET enne=isnull(enne,'''')+''&''+convert(nvarchar,@rida)+''=''+convert(nvarchar,'+@field+') where '+@field+'!=0'
--	print @sql
	EXECUTE sp_executesql @sql,N'@kontod nvarchar(max), @k money, @rida int',@kontod=@kontod, @k=@k, @rida=@rida
end
insert into #tulem (t_objekt,rn) SELECT distinct t_objekt,0 FROM #tulem where rn=1 
update #tulem set nimi=o.nimi from fin_objektid o with (nolock) where #tulem.rn=0 and #tulem.t_objekt=o.kood
update #tulem set nimi=p.nimi from projektid p with (nolock) where #tulem.rn=1 and #tulem.t_projekt=p.kood
set @sql='insert into #tulem (t_objekt,rn'+@fields+') SELECT t_objekt,3'+@fields_sum+' FROM #tulem where rn=1 group by t_objekt'
exec(@sql)
set @sql='insert into #tulem (t_objekt,rn'+@fields+') SELECT ''ZZZZZZ'',4'+@fields_sum+' FROM #tulem where rn=1'
print @sql
exec(@sql)
set @sql='select case rn when 0 then ''<b>''+t_Objekt when 3 then ''<b>Total'' when 4 then ''<b>All total'' end as Object,case when rn=1 then t_Projekt end as Project, case when rn=1 and len(nimi)>31 then ''<div title="''+replace(nimi,''"'','''')+''">''+left(nimi,29)+''...</div>'' else nimi end [Name                                                ]'+@fields+' from #tulem '+@fields_null+' order by t_objekt,rn, t_projekt'
print @sql
exec(@sql)
drop table #tulem




GO


