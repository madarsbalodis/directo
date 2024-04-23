SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[get_master_project_lv_ver] (@inputedproj VARCHAR(250),@inputedproj2 VARCHAR(250))
RETURNS VARCHAR(250)
AS BEGIN
select @inputedproj2 = iif(@inputedproj2='',NULL,@inputedproj2)
DECLARE @mproj VARCHAR(250)
DECLARE @project nvarchar(max), @project2 nvarchar(max), @master nvarchar(max)
set @project=@inputedproj
declare @temp table
(
project nvarchar(255),
master nvarchar(255)
)
insert @temp
select kood, master from projektid where kood=@project
if (isnull((select master from projektid where kood=@project),'')!='')
begin
DECLARE project CURSOR FOR
select project, master from @temp
OPEN project
FETCH NEXT FROM project INTO @project2, @master
WHILE @@FETCH_STATUS = 0
BEGIN
if isnull(@master,'')!=''
begin
while @master is not null
begin
if @master is not null
begin
set @project2 = @master
set @master = (select master from projektid where kood=@project2)
insert @temp
select @project2, @master
end
end
end
FETCH NEXT FROM project INTO @project2, @master
END
CLOSE project;
DEALLOCATE project;
if @inputedproj2 is null
	begin
		select @mproj = project from @temp where master is null
	end
if @inputedproj2 is not null
	begin
		select @mproj = project from @temp where project = @inputedproj2
	end
END
else
set @mproj=@project

delete from @temp;
RETURN @mproj;
END
GO
