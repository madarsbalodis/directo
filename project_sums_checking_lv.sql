SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



















ALTER function [dbo].[project_sums_checking_lv](@docType as nvarchar(15), @docNumber int, @checkingType nvarchar(25)) returns nvarchar(max)
begin
-- need to create supplier checking
declare @returntxt nvarchar(max)
declare @contractDfValue nvarchar(255)
declare @main_document_project_data_table table (project nvarchar(max), countInContract decimal(15,0), sumInContract decimal(15,4), usedSumInInInvoiceWoOrder decimal(15,4),usedSumInInInvoiceWithOrder decimal(15,4),reservedSumWithOrder decimal(15,4), CurrentDoc decimal(15,4), total decimal(15,4), usedPerc decimal(15,4))

declare @contractSum decimal(15,4), @usedSum decimal(15,4)

declare @projectValidationStatus nvarchar(10)
set @projectValidationStatus = NULL
if @docType='otellimus'
	begin
	if @checkingType in ('Contract','contractVsDocSumsPerc','contractVsDocSums','contractVsDocSumsPercSave')
		begin
		select @contractDfValue = isnull((select lisa_field2 from otell_tellimused where number=@docNumber),'')
		if isnull(@contractDfValue,'')!=''
			begin
				
				if isnumeric(@contractDfValue)=1
					begin
						if (select count(*) from lepingud where number=@contractDfValue) = 1
							begin
								if isnull((select hankija_kood from otell_tellimused where number=@docNumber),'')=isnull((select hankija_kood from lepingud where number=@contractDfValue),'')
									begin
										if (select count(*) from otell_tellimused_read where number=@docNumber) >=1
											begin
												insert @main_document_project_data_table (project)
												select isnull(otr.r_projekt,ot.projekt) from otell_tellimused_read otr left join otell_tellimused ot on otr.number=ot.number where otr.number=@docNumber group by otr.r_projekt,ot.projekt

												update @main_document_project_data_table set countInContract=(select count(*) from lepingud_read inner join lepingud on lepingud.number=lepingud_read.number where lepingud_read.number=@contractDfValue and iif(isnull(lepingud_read.projekt,'')!='',isnull(lepingud_read.projekt,''),isnull(lepingud.projekt,''))=isnull(project,''))

												if (select count(*) from @main_document_project_data_table where countInContract = 0 ) >= 1
													begin
													select @returntxt = convert(nvarchar(max),(select 'Projekts '+convert(nvarchar(max),project)+N' nav atrodams		līgumā:'+convert(nvarchar(max),@contractDfValue) from @main_document_project_data_table where countInContract = 0 for xml path (''),type,elements))
									end
									else
										begin
											set @projectValidationStatus = 'OK'
										end
									end
								else
									begin
										select @returntxt = N'Dokumentam ir 0 rindas'
									end
									end
								else
									begin
										select @returntxt = N'Līgumā '+convert(nvarchar(max),@contractDfValue)+N' norādītais piegādātājs neatbilst dokumentā norādītajam piegādātājam'
									end
							end
						else
							begin
								select @returntxt = N'Norādītais līguma Nr. nav atrodams'
							end
					end
				else
					begin
						select @returntxt = N'Norādītais līguma nr neatbilst līguma dokumenta formātam'
					end
			end
		else
			begin
				select @returntxt = N'Nav aizpildīts Līguma Nr.'
			end
		end
if @checkingType in ('contractVsDocSumsPerc','contractVsDocSums','contractVsDocSumsPercSave')
	begin
		if @projectValidationStatus = 'OK'
			begin
				-- contract sum checking for project
				update @main_document_project_data_table set sumInContract=isnull((select sum(lepingud_read.summa) from lepingud_read inner join lepingud on lepingud.number=lepingud_read.number where lepingud.number=@contractDfValue and isnull(isnull(lepingud_read.projekt,lepingud.projekt),'')=isnull(project,'')),0)

				-- purchase invoice sum checking for current project without added purchase order
				update @main_document_project_data_table set usedSumInInInvoiceWoOrder=isnull((select sum(oar.summa) from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(isnull(oar.projekt,oa.projekt),'')=isnull(project,'') and isnull(oa.ostutellimus,'')='' and isnull(oa.kinnitatud,0)=1  and oa.lisa_field2=@contractDfValue),0)
				
				-- purchase invoice sum checking for current project with added purchase order
				update @main_document_project_data_table set usedSumInInInvoiceWithOrder=isnull((select sum(oar.summa) from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(isnull(oar.projekt,oa.projekt),'')=isnull(project,'') and isnull(oa.ostutellimus,'')!='' and isnull(oa.kinnitatud,0)=1  and oa.lisa_field2=@contractDfValue),0) 

				-- purchase prder sum checking for current project
				update @main_document_project_data_table set reservedSumWithOrder=isnull((select sum(otr.summa) from otell_tellimused_read otr left join otell_tellimused ot on otr.number=ot.number where isnull(isnull(otr.r_projekt,ot.projekt),'')=isnull(project,'') and ot.number not in (select oa.ostutellimus from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(isnull(oar.projekt,oa.projekt),'')=isnull(project,'') and isnull(oa.ostutellimus,'')!='' and isnull(oa.kinnitatud,0)=1) and ot.number!=@docNumber  and ot.lisa_field2=@contractDfValue and isnull(ot.kinnitatud,0)=1),0)

				update @main_document_project_data_table set CurrentDoc=isnull((select sum(otr.summa) from otell_tellimused_read otr left join otell_tellimused ot on otr.number=ot.number where isnull(isnull(otr.r_projekt,ot.projekt),'')=isnull(project,'') and ot.number=@docNumber  and ot.lisa_field2=@contractDfValue),0)

				update @main_document_project_data_table set total=(isnull(usedSumInInInvoiceWoOrder,0)+isnull(usedSumInInInvoiceWithOrder,0)+isnull(reservedSumWithOrder,0)+isnull(CurrentDoc,0))

				update @main_document_project_data_table set usedPerc=(iif(total=0,1,total) / sumInContract)*100
			if @checkingType = 'contractVsDocSums'
				begin
				--checking for project sums ws previous calculated sum's
				if (select count(*) from @main_document_project_data_table where sumInContract <= total
				) > =1
					begin

					--preparing altert text if calculated sums tottaly for project are greater than contract sum for project
						select @returntxt = 
						
						convert(nvarchar(max),(
							-- select N'Projekta '+convert(nvarchar(max),isnull(project,'')) + N' paredzēta līgumā ' + convert(nvarchar(max),@contractDfValue)+ ' = ' +  convert(nvarchar(max),sumInContract) + N' bet izmantota [b]'+'[a href="yld_print.asp?1=1&param0='+convert(nvarchar(max),@contractDfValue)+'&param1='+convert(nvarchar(max),isnull(project,''))+'&row=5410&moodul=int_hooldus_klient_contract_sums_detail&print=no&mida=xsl&aeg1=01.02.2024&aeg2=26.02.2024&1=1">'+convert(nvarchar(max),(isnull(total,0)))+N'[/a][/b]','[br/]' 
						select N'Projekta '+convert(nvarchar(max),isnull(project,'')) + N' paredzēta līgumā ' + convert(nvarchar(max),@contractDfValue)+ ' = ' +  convert(nvarchar(max),sumInContract) + N' bet izmantota '+convert(nvarchar(max),(isnull(total,0)))
						
						from @main_document_project_data_table where sumInContract <= total 
						for xml path (''),type,elements))
					end
				end
			if @checkingType in ('contractVsDocSumsPerc','contractVsDocSumsPercSave')
				begin
				--checking for project sums ws previous calculated sum's
				if (select count(*) from @main_document_project_data_table where usedperc > 80) > =1
					begin

					--preparing altert text if calculated sums tottaly for project are greater than contract sum for project
						select @returntxt = 
						
						convert(nvarchar(max),(
							select N'Projekta '+convert(nvarchar(max),project) + N' paredzēta līgumā ' + convert(nvarchar(max),@contractDfValue)+ ' = ' +  convert(nvarchar(max),sumInContract) + N' summma izmantota '+convert(nvarchar(max),(isnull(usedperc,0)))+'%' 
						
						from @main_document_project_data_table where usedPerc >= 80 for xml path (''),type,elements))
					end
				end
			end
		end
	end

if @docType='oarve'
	begin
		select @contractDfValue = isnull((select lisa_field2 from or_arved where number=@docNumber),'')
	if @checkingType in ('Contract','contractVsDocSumsPerc','contractVsDocSums','contractVsDocSumsPercSave')
		begin
		if isnull(@contractDfValue,'')!=''
			begin
				
				if isnumeric(@contractDfValue)=1
					begin
						if (select count(*) from lepingud where number=@contractDfValue) = 1
							begin
								if isnull((select hankija_kood from Or_arved where number=@docNumber),'')=isnull((select hankija_kood from lepingud where number=@contractDfValue),'')
									begin
											if (select count(*) from or_arved_read where number=@docNumber) >=1
									begin
										insert @main_document_project_data_table (project)
										select isnull(otr.projekt,ot.projekt) from or_arved_read otr left join or_arved ot on otr.number=ot.number where otr.number=@docNumber group by otr.projekt,ot.projekt

										update @main_document_project_data_table set countInContract=(select count(*) from lepingud_read inner join lepingud on lepingud.number=lepingud_read.number where lepingud_read.number=@contractDfValue and iif(isnull(lepingud_read.projekt,'')!='',lepingud_read.projekt,isnull(lepingud.projekt,''))=isnull(project,''))

										

										if (select count(*) from @main_document_project_data_table where countInContract = 0 ) >= 1
											begin
											select @returntxt = convert(nvarchar(max),(select 'Projekts '+convert(nvarchar(max),project)+N' nav atrodams		līgumā:'+convert(nvarchar(max),@contractDfValue) from @main_document_project_data_table where countInContract = 0 for xml path (''),type,elements))
											end
										else
											begin
												set @projectValidationStatus = 'OK'
											end
									end
								else
									begin
										select @returntxt = N'Dokumentam ir 0 rindas'
									end
									end
								else
																		begin
										select @returntxt = N'Līgumā '+convert(nvarchar(max),@contractDfValue)+N' norādītais piegādātājs neatbilst dokumentā norādītajam piegādātājam'
									end

							end
						else
							begin
								select @returntxt = N'Norādītais līguma Nr. nav atrodams'
							end
					end
				else
					begin
						select @returntxt = N'Norādītais līguma nr neatbilst līguma dokumenta formātam'
					end
			end
		else
			begin
				select @returntxt = N'Nav aizpildīts Līguma Nr.'
			end
end
if @checkingType in ('contractVsDocSumsPerc','contractVsDocSums','contractVsDocSumsPercSave')
	begin
		if @projectValidationStatus = 'OK'
			begin
			
				update @main_document_project_data_table set sumInContract=isnull((select sum(lepingud_read.summa) from lepingud_read inner join lepingud on lepingud.number=lepingud_read.number where lepingud.number=@contractDfValue and isnull(isnull(lepingud_read.projekt,lepingud.projekt),'')=isnull(project,'')),0)
				update @main_document_project_data_table set usedSumInInInvoiceWoOrder=isnull((select sum(oar.summa) from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(oar.projekt,oa.projekt)=project and isnull(oa.ostutellimus,'')='' and isnull(oa.kinnitatud,0)=1 and oa.number!=@docNumber and oa.lisa_field2=@contractDfValue),0)
				update @main_document_project_data_table set usedSumInInInvoiceWithOrder=isnull((select sum(oar.summa) from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(oar.projekt,oa.projekt)=project and isnull(oa.ostutellimus,'')!='' and isnull(oa.kinnitatud,0)=1 and oa.number!=@docNumber and oa.lisa_field2=@contractDfValue),0) 
				update @main_document_project_data_table set reservedSumWithOrder=isnull((select sum(otr.summa) from otell_tellimused_read otr left join otell_tellimused ot on otr.number=ot.number where isnull(otr.r_projekt,ot.projekt)=project and isnull(ot.kinnitatud,0)=1 and ot.number not in (select oa.ostutellimus from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(oar.projekt,oa.projekt)=project and isnull(oa.ostutellimus,'')!='' and isnull(oa.kinnitatud,0)=1 and oa.lisa_field2=@contractDfValue)),0)
				update @main_document_project_data_table set CurrentDoc=isnull((select sum(oar.summa) from or_arved_read oar left join or_arved oa on oar.number=oa.number where isnull(oar.projekt,oa.projekt)=project and oa.number=@docNumber and oa.lisa_field2=@contractDfValue),0)
				
					update @main_document_project_data_table set total=(isnull(usedSumInInInvoiceWoOrder,0)+isnull(usedSumInInInvoiceWithOrder,0)+isnull(reservedSumWithOrder,0)+isnull(CurrentDoc,0))
					
				update @main_document_project_data_table set usedPerc=(iif(total=0,1,total) / sumInContract)*100
			if @checkingType = 'contractVsDocSums'
				begin
				--checking for project sums ws previous calculated sum's
				if (select count(*) from @main_document_project_data_table where sumInContract <= total) > =1
					begin

					--preparing altert text if calculated sums tottaly for project are greater than contract sum for project
						select @returntxt = 
						
						convert(nvarchar(max),(
							select N'Projekta '+convert(nvarchar(max),project) + N' paredzēta līgumā ' + convert(nvarchar(max),@contractDfValue)+ ' = ' +  convert(nvarchar(max),sumInContract) + N' bet izmantota '+convert(nvarchar(max),(isnull(total,0)))
						
						from @main_document_project_data_table-- where --sumInContract <= total 
						for xml path (''),type,elements))
					end
				end
			if @checkingType in ('contractVsDocSumsPerc','contractVsDocSumsPercSave')
				begin
				--checking for project sums ws previous calculated sum's
				if (select count(*) from @main_document_project_data_table where usedperc > 80) > =1
					begin

					--preparing altert text if calculated sums tottaly for project are greater than contract sum for project
						select @returntxt = 
						
						convert(nvarchar(max),(
							select N'Projekta '+convert(nvarchar(max),project) + N' paredzēta līgumā ' + convert(nvarchar(max),@contractDfValue)+ ' = ' +  convert(nvarchar(max),sumInContract) + N' summma izmantota '+convert(nvarchar(max),(isnull(cast(usedperc as decimal(15,4)),0)))+'%' 
						
						from @main_document_project_data_table where usedPerc >= 80 for xml path (''),type,elements))
					end
				end

			--select @returntxt = 
						
			--			convert(nvarchar(max),(
			--				select N'Projekta '+convert(nvarchar(max),project) + N' paredzēta līgumā ' + convert(nvarchar(max),@contractDfValue)+ ' = ' +  convert(nvarchar(max),sumInContract) + N' bet izmantota .b.'+convert(nvarchar(max),(isnull(usedSumInInInvoiceWoOrder,0)+isnull(usedSumInInInvoiceWithOrder,0)+isnull(reservedSumWithOrder,0)))+N'./b.','.br.' 

						--select @returntxt = convert(nvarchar(max),(select isnull(project,'')+convert(nvarchar(max),sum(sumInContract))+convert(nvarchar(max),(sum(isnull(usedSumInInInvoiceWoOrder,0))+sum(isnull(usedSumInInInvoiceWithOrder,0))+sum(isnull(reservedSumWithOrder,0))+sum(isnull(CurrentDoc,0))))+'%'+convert(nvarchar(max),((sum(isnull(usedSumInInInvoiceWoOrder,0))+sum(isnull(usedSumInInInvoiceWithOrder,0))+sum(isnull(reservedSumWithOrder,0))+sum(isnull(CurrentDoc,0))) / sum(isnull(sumInContract,0))) * 100)+'.br.' from @main_document_project_data_table group by project for xml path (''),type,elements))

				

			end
		end
	end

--return alert text if exsists
return @returntxt
end
GO
