SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER     procedure [dbo].[int_hooldus_klient_capex] @aeg1 datetime, @aeg2 datetime as 

if(not(exists(select 1 from int_hooldus_klient where rn='_capex')))
	begin
		insert int_hooldus_klient (rn, nimi,formaat)
		select '_capex','CAPEX','xml'
	end

--select * from projektid where master in (select kood from projektid where kood like 'CAPEX%') --and year(aeg1)=year(@aeg1))
--select * from projektid where master in (select kood from projektid where master in (select kood from projektid where kood like 'CAPEX%')) for xml path ('capex_project'),type,elements -- and year(aeg1)=year(@aeg1)))
create table #projects (first_stproj nvarchar(32), proj_from_bugget nvarchar(32),budget_proj_master nvarchar(32),projectMasterCount decimal(15,0), first_master nvarchar(32), pname nvarchar(255), contr_summa decimal(15,4), responsible nvarchar(255), sdate nvarchar(max), edate nvarchar(max))

--select distinct(Projekt) from fin_eelarved_read where Projekt in (select kood from projektid)
declare @dproject nvarchar(max),@project nvarchar(max)
declare capex_project cursor for select kood from projektid where master like 'CAPEX%' and kood in (select kood from projektid)
open capex_project
FETCH NEXT FROM capex_project INTO @project
WHILE @@FETCH_STATUS = 0
BEGIN
declare tellimused2 cursor for select distinct(projekt) from fin_eelarved_read where number in (2000001) and isnull(projekt,'')!=''
open tellimused2
FETCH NEXT FROM tellimused2 INTO @dproject
WHILE @@FETCH_STATUS = 0
BEGIN
/*
	insert #paymentsPurchaseOrderSums (porder,number,paymentDate,calculatedSum,project,contractext,dtype,month_code,coef,psum)
	select @otellimus, @tasumine, @date,@psum * coef, isnull(projekt,''),
	lisa_field1,'otellimus',convert(nvarchar(max),month(@date))+'_'+convert(nvarchar(max),year(@date)),coef, @psum from #t3 where number=@otellimus 
	*/
	insert #projects
	select @dproject first_stproj, @project proj_from_bugget, (select dbo.get_master_project_lv_ver(@dproject,@project)) budget_proj_master,NULL,NULL,NULL,NULL,NULL,NULL,NULL

	FETCH NEXT FROM tellimused2 INTO @dproject
END
CLOSE tellimused2
DEALLOCATE tellimused2
declare tellimused2 cursor for select kood from projektid where  isnull(master,'')!=''
open tellimused2
FETCH NEXT FROM tellimused2 INTO @dproject
WHILE @@FETCH_STATUS = 0
BEGIN
/*
	insert #paymentsPurchaseOrderSums (porder,number,paymentDate,calculatedSum,project,contractext,dtype,month_code,coef,psum)
	select @otellimus, @tasumine, @date,@psum * coef, isnull(projekt,''),
	lisa_field1,'otellimus',convert(nvarchar(max),month(@date))+'_'+convert(nvarchar(max),year(@date)),coef, @psum from #t3 where number=@otellimus 
	*/
	insert #projects
	select @dproject first_stproj, @project proj_from_bugget, (select dbo.get_master_project_lv_ver(@dproject,@project)) budget_proj_master,NULL,(select master from projektid where kood=@dproject),NULL,NULL,NULL,NULL,NULL

	FETCH NEXT FROM tellimused2 INTO @dproject
END
CLOSE tellimused2
DEALLOCATE tellimused2
FETCH NEXT FROM capex_project INTO @project
END
CLOSE capex_project
DEALLOCATE capex_project
update #projects set projectMasterCount=(select count(*) from projektid where master=first_stproj)
update #projects set pname=(select nimi from projektid where kood=first_stproj)
update #projects set contr_summa = isnull((select sum(summa) from lepingud_read where projekt=first_stproj),0)
update #projects set responsible=(select nimi from kasutajad where kood=(select juht from projektid where kood=first_stproj))
update #projects set edate=(select convert(nvarchar(max),aeg2,104) from projektid where kood=first_stproj),sdate=(select convert(nvarchar(max),aeg1,104) from projektid where kood=first_stproj)
select substring(convert(nvarchar(max),year(@aeg1)),3,2) a,
(select * ,
			isnull((select sum(summa) from lepingud_read where projekt=projektid.kood),0) contr_summa, 
			(select * from fin_eelarved_read where projekt=projektid.kood and tyyp like 'prog_%' and tyyp like '%'+substring(convert(nvarchar(max),year(@aeg1)),3,2)+'%' for xml path('row'),type,elements) as rows,
			(select * from fin_eelarved_read where projekt=projektid.kood and tyyp like '%PB%' and tyyp like '%'+convert(nvarchar(max),year(@aeg1))+'%' for xml path('row'),type,elements) as rowsact,
			(select isnull(sum(or_arved_read.summa),0) summa from or_arved_read left join or_arved on or_arved.number=or_arved_read.number where isnull(Or_arved_read.projekt,Or_arved.projekt)=projektid.kood) as invoicesum from projektid where master in (select kood from projektid where kood like 'CAPEX%') for xml path ('capex_master_project'),type,elements) as capex_master_projects,
(select *,
			isnull((select sum(summa) from lepingud_read where projekt=projektid.kood),0) contr_summa, 
			(select * from fin_eelarved_read where projekt=projektid.kood and tyyp like 'prog_%' and tyyp like '%'+substring(convert(nvarchar(max),year(@aeg1)),3,2)+'%' for xml path('row'),type,elements) as rows,
			(select * from fin_eelarved_read where projekt=projektid.kood and tyyp like '%PB%' and tyyp like '%'+convert(nvarchar(max),year(@aeg1))+'%' for xml path('row'),type,elements) as rowsact,
			(select isnull(sum(or_arved_read.summa),0) summa from or_arved_read left join or_arved on or_arved.number=or_arved_read.number where isnull(Or_arved_read.projekt,Or_arved.projekt)=projektid.kood) as invoicesum
	from projektid where master in (select kood from projektid where master in (select kood from projektid where kood like 'CAPEX%')) for xml path ('capex_project'),type,elements) as capex_projects,
(select *,(select isnull(sum(or_arved_read.summa),0) summa from or_arved_read left join or_arved on or_arved.number=or_arved_read.number where isnull(Or_arved_read.projekt,Or_arved.projekt)=#projects.first_stproj) as invoicesum from #projects where budget_proj_master is not null for xml path ('project'), type,elements) as projects
for xml path ('document'),type,elements

GO
