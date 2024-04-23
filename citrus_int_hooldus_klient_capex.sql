SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   procedure [dbo].[int_hooldus_klient_capex] @aeg1 datetime, @aeg2 datetime as 

select * from projektid where master in (select kood from projektid where kood like 'CAPEX%' and year(aeg1)=year(@aeg1))
select * from projektid where master in (select kood from projektid where master in (select kood from projektid where kood like 'CAPEX%' and year(aeg1)=year(@aeg1)))


--select distinct(Projekt) from fin_eelarved_read where Projekt in (select kood from projektid)
declare @dproject nvarchar(max),@project nvarchar(max)
declare capex_project cursor for select kood from projektid where master like 'CAPEX%' and kood in (select kood from projektid)
open capex_project
FETCH NEXT FROM capex_project INTO @project
WHILE @@FETCH_STATUS = 0
BEGIN
select @project
declare tellimused2 cursor for select distinct(Projekt) from fin_eelarved_read where Projekt in (select kood from projektid)
open tellimused2
FETCH NEXT FROM tellimused2 INTO @dproject
WHILE @@FETCH_STATUS = 0
BEGIN
/*
	insert #paymentsPurchaseOrderSums (porder,number,paymentDate,calculatedSum,project,contractext,dtype,month_code,coef,psum)
	select @otellimus, @tasumine, @date,@psum * coef, isnull(projekt,''),
	lisa_field1,'otellimus',convert(nvarchar(max),month(@date))+'_'+convert(nvarchar(max),year(@date)),coef, @psum from #t3 where number=@otellimus 
	*/
	select @dproject first_stproj, @project proj_from_bugget, (select dbo.get_master_project_lv_ver(@dproject,@project)) budget_proj_master

	FETCH NEXT FROM tellimused2 INTO @dproject
END
CLOSE tellimused2
DEALLOCATE tellimused2
FETCH NEXT FROM capex_project INTO @project
END
CLOSE capex_project
DEALLOCATE capex_project
GO
