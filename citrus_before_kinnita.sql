SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER PROCEDURE [dbo].[before_kinnita] @tyyp nvarchar(32), @number nvarchar(32), @p_olek varchar(100) OUTPUT 
AS
declare @msg nvarchar(max)



--solution for contract sum checking
if @tyyp in ('otellimus', 'oarve')
	begin
		if 1=2
			begin

				declare @contractCheckingMsg nvarchar(max)
				select @contractCheckingMsg = convert(nvarchar(max),
				(select dbo.project_sums_checking_lv(@tyyp,@number,'Contract')))
				
				if isnull(@contractCheckingMsg,'')!=''
					begin
						set @msg = @contractCheckingMsg
					end
				if isnull(@contractCheckingMsg,'')=''
					begin
						select @contractCheckingMsg = convert(nvarchar(max),
						
						(select dbo.project_sums_checking_lv(@tyyp,@number,'contractVsDocSums')))
						
	
						if isnull(@contractCheckingMsg,'')!=''
							begin
								set @msg = @contractCheckingMsg

							end
						else
							begin
								select @contractCheckingMsg = convert(nvarchar(max),
								
								(select dbo.project_sums_checking_lv(@tyyp,@number,'contractVsDocSumsPerc'))
								)
								
									if isnull(@contractCheckingMsg,'')!=''

									insert int_asp_alerts (unit,number,tekst,cu)
									select @tyyp,@number,@contractCheckingMsg,'(DIRECTO)'


							end
					end
				

			end
	end


if ISNULL(@msg,'')!=''
begin

		if object_id('tempdb..#teated') is NOT null BEGIN --FOR NEW DESING SUPPORTED CONFIRMERS
			insert into #teated select @msg
		END ELSE BEGIN
			set @p_olek = 'halb'
			select @msg
		END
	
end
	
GO
