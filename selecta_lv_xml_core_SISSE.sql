SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[xml_core_SISSE] @callid nvarchar(255)=null AS
set nocount on;

DECLARE @step NVARCHAR(255)

DECLARE @number int, @appkey nvarchar(64)
DECLARE @x int, @summa money
DECLARE @kaibemaiks money, @kokku money
DECLARE @aeg date, @kmkood int
DECLARE @tasumisviisi nvarchar(32),@tasumisviisist nvarchar(32)
DECLARE @kasutaja nvarchar(32), @kommentaar nvarchar(255)
DECLARE @kinnitatud int, @objekt nvarchar(32)
DECLARE @projektist nvarchar(32), @projekti nvarchar(32)
DECLARE @valuuta nvarchar(32), @baasv1 money
DECLARE @ts date, @cu nvarchar(32)
DECLARE @keel nvarchar(32), @dokument int
DECLARE @src_number int, @src_unit nvarchar(32)
DECLARE @kurss_e money, @kurss money
DECLARE @arvuti nvarchar(32), @arvutisse nvarchar(32)
DECLARE @cashmove_ok int, @cashmove_duplicate int, @koodid varchar(1000)
declare @key nvarchar(32), @xmlcore_key nvarchar(64), @seeria nvarchar(32), @webid nvarchar(64), @incwebid nvarchar(32), @inctype int, @incctype nvarchar(max)
declare @projekt nvarchar(max)
declare @sequence nvarchar(32), @stock nvarchar(255)
declare @ag datetime, @err nvarchar(32), @x2 nvarchar(max)
declare @result1 xml, @result2 nvarchar(max)
declare @series nvarchar(32)
declare @webCustomerRegNo nvarchar(25)
DECLARE @new_objekt NVARCHAR(255), @old_objekt NVARCHAR(255), @old_objekt2 NVARCHAR(255), @new_objekt2 NVARCHAR(255), @manager NVARCHAR(255), @project NVARCHAR(255)
DEClare @ebCustomerFactoringCount int
declare @mapId int, @orderIndex int, @updDate datetime, @prodGroup nvarchar(255), @mapId2 int, @region nvarchar(32),@hankija nvarchar(max), @aegDoc nvarchar(max),@aegDoc2 datetime, @maa int
declare @maxrn int
declare @sorderFromStock nvarchar(32), @sorderToStock nvarchar(32)
select @sorderFromStock = isnull(param1,''), @sorderToStock = isnull(param2,'') from tr_params where kood='def_stocks_sorder_mappost' and tyyp='xml'
declare @bodytxt nvarchar(max)
declare @mail_to nvarchar(max)
set @mail_to = (select top 1 sisu from uuringud_read where field='receiver')

set @key=CONVERT(nvarchar,getdate(),121)
select @x2 = convert(nvarchar(max),getdate(),121)

update in_kassa_liikumised set x=@key where x is null
UPDATE in_liikumised SET x=@key where x is null
UPDATE in_customer_changes SET x=@key where x is null
UPDATE in_webshop_orders SET x=@key where x is null
--update in_nayax_transaction set x=@x2 where x is null
update in_nayax_transaction_header set x=@x2 where x is null
update in_nayax_transaction_line set x=@x2 where x is null
update in_nayax_transaction_payments set x=@x2 where x is null

UPDATE in_mappost_stock_order_merch SET x=@key where x is null
update in_mappost_stock_order set x=@x2 where x is null
update in_mappost_stock_order_lines set x=@x2 where x is null
update in_mappost_stock_order set UpdatedDateConv=convert(datetime,UpdatedDate) where x=@x2
--update in_mappost_stock_order_lines set DirectoItem=isnull((select top 1 kaart from yld_data where klass='artikkel' and kood='HTYPE1' and sisu=NayaxProductId),'') where x=@x2

update in_mappost_stock_order_lines set DirectoItem=isnull((select top 1 kaart from yld_data where klass='artikkel' and kood='HTYPE1' and sisu=NayaxProductId),'') where x=@x2 and isnull(ProductId,'')=''
update in_mappost_stock_order_lines set DirectoItem=ProductId where x=@x2 and isnull(ProductId,'')!=''


UPDATE in_mappost_liikumised set x=@key where x is null
UPDATE in_mappost_liikumised_stock_movement SET x=@key where x is null
--UPDATE in_mappost_bad_stock_movement SET x=@key where x is null
UPDATE in_mappost_takings SET x=@key where x is null

update in_otell_tellimused set x=@x2 where x is null
update in_otell_tellimused_read set x=@x2 where x is null
update in_otell_tellimused set dateCov=convert(datetime,date) where x=@x2
update in_otell_tellimused_read set artikkel=isnull((select kaart from yld_data where klass='artikkel' and kood='HTYPE1' and sisu=artikkel),artikkel) where x=@x2

--SELECT * FROM in_liikumised

--EXEC [dbo].[xml_core_SISSE]

set @cashmove_ok=0
set @cashmove_duplicate=0

set @koodid=''
create table #output
(response NVARCHAR(MAX))
create table #results
(number nvarchar(64), tyyp nvarchar(32), result int, descr nvarchar(max), submittype nvarchar(255))

create table #proc_results
(sisu nvarchar(max))

-- create schema for project history
SELECT TOP 0 * INTO #projektid FROM projektid WITH(nolock)

select @xmlcore_key=setting from Settings where id='xmlcore_key'
select @seeria=field19 from kasutajad where kood='EC'
-----------------------------------------
DECLARE @leftover INT, @id_exist INT, @webid2 INT

	UPDATE in_liikumised_read
    SET    x = @key 
    WHERE  x IS NULL AND number IN (SELECT number FROM in_liikumised WHERE x = @key)

	DELETE FROM in_liikumised WHERE number IN (SELECT number FROM in_liikumised WHERE x = @key) AND x != @key
	DELETE FROM in_liikumised_read WHERE number IN (SELECT number FROM in_liikumised WHERE x = @key) AND x != @key

    DECLARE tellimused CURSOR FOR 
      SELECT number, 
             leftover,
             number, 
			 projektist,
			 laost
      FROM   in_liikumised 
      WHERE  x = @key 

    OPEN tellimused 

    FETCH next FROM tellimused INTO @webid, @leftover, @webid2,@projektist,@stock 

    WHILE @@FETCH_STATUS = 0 
      BEGIN 
        if((select count(number) from ladu_liikumised where sisekommentaar=convert(nvarchar(255),@webid) and projekti=@projektist and laost=@stock)=0)
            begin

          EXEC dbo.get_dok_number @moodul='liikumine', @seeria='DOC', @NUMBER = NULL, @cu='xmlcore', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT 

                /*INSERT INTO ladu_liikumised 
                            (number, 
                             aeg, 
                             laost, 
                             lattu, 
                             projekt, 
                             projekti, 
                             ts, 
                             cu) 
                SELECT @number, 
                       aeg, 
                       laost, 
                       lattu, 
                       projektist, 
                       projekti, 
                       Getdate(), 
                       'XML' 
                FROM   in_liikumised 
                WHERE  number = @number */
				

				update ladu_liikumised
					set
						aeg=z.aeg, 
						laost=z.laost, 
						lattu=z.lattu, 
						projekt=z.projektist,
						projekti=z.projekti,
						ts=getdate(), 
						cu='XML',
						sisekommentaar=@webid
					from (select * from in_liikumised where number=@webid)z
				where ladu_liikumised.number=@number 



                IF Isnull(@leftover, 0) = 1 
                  BEGIN 
                      UPDATE in_liikumised_read 
                      SET    sent_kogus = isnull(kogus,0),
							kogus = Isnull((SELECT Sum(kogus) FROM 
                                     int_artikli_ajalugu 
                                     WHERE 
                                     kood 
                                     =artikkel 
                                            AND ladu 
                                     = 'VENDINGO' AND aeg<(SELECT aeg FROM 
                                     in_liikumised 
                                     WHERE 
                                     number 
                                     = 
                                            @webid and x=@key) AND 
                                     ( SELECT top 1 projekt FROM int_laoid_hinnad t2 
                                     WHERE 
                                     t2.laoid=int_artikli_ajalugu.laoid)=(SELECT 
                                     projektist 
                                     FROM 
                                            in_liikumised WHERE number=@webid and x=@key)) 
                                     , 0) 
             + Isnull((SELECT Sum(kogus_saadud) FROM 
                          ladu_liikumised_read 
                                     INNER JOIN 
                                     ladu_liikumised ON 
      ladu_liikumised.number=ladu_liikumised_read.number 
             WHERE 
      Isnull(kinnitatud, 0)=0 AND 
      ladu_liikumised.aeg<(SELECT 
      aeg 
      FROM 
             in_liikumised 
      WHERE number= @webid and x=@key) AND lattu='VENDINGO' AND artikkel=in_liikumised_read.artikkel AND ladu_liikumised.projekti = (SELECT projektist FROM in_liikumised WHERE number=@webid and x=@key)), 0) - 
      Isnull(kogus, 0) 
	  where number=@webid
      END 


      INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv) 
      SELECT @number, 
			  artikkel, 
			  kogus, 
			  kogus, 
			  CONVERT(NVARCHAR(510),sent_kogus),
			  (SELECT top 1 nimi 
			  FROM   artiklid 
			  WHERE  kood = ilr.artikkel), 
			  row_number() OVER (ORDER BY artikkel),
			  row_number() OVER (ORDER BY artikkel) 
      FROM  in_liikumised_read as ilr where number=@webid and x=@key and kogus>=0

	  INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv) 
      SELECT @number, 
			  artikkel, 
			  0,
			  0,
			  CONCAT(sent_kogus, ' (', kogus, ')'),
			  (SELECT top 1 nimi 
			  FROM   artiklid 
			  WHERE  kood = ilr.artikkel), 
			  row_number() OVER (ORDER BY artikkel),
			  row_number() OVER (ORDER BY artikkel) 
      FROM  in_liikumised_read as ilr where number=@webid and x=@key and kogus<0


		  EXEC [dbo].[ladu_liik_komplekteeri] @number

		  EXEC Hooldus_vaba 'liikumine', @number 
		  --EXEC dbo.liikumine_sn_split @number
		  EXEC dbo.liikumine_laoid_split @number
		  
		  --EXEC dbo.after_save @moodul = 'liikumine', @number = @number
            exec dbo.after_save_klient 'liikumine', @NUMBER, NULL, NULL, NULL

		  INSERT #output 
		  	EXEC Kinnita_liik @number 
		  DELETE FROM #output

		 




            IF Isnull(@leftover, 0) = 1 
            BEGIN 
                if ((select count(kogus) from in_liikumised_read where number=@webid2 and kogus<0)>0)
                                    BEGIN
                                        EXEC dbo.get_dok_number @moodul='sissetulek', @seeria='DOC', @NUMBER = NULL, @cu='xmlcore', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT

                                        update ladu_sissetulekud
                                            set
                                                hankija_kood='VIRT',
                                                ladu='VENDINGO',
                                                projekt=z.projektist,
                                                aeg=((select dateadd(ss,-1,z.aeg))),
                                                ts=Getdate(),
                                                cu='XML',
                                                konto='7110101'
                                            from (select * from in_liikumised where number=@webid)z
                                        where ladu_sissetulekud.number=@number 

                                                        --select @maa = isnull(maa,0) from kliendid where kood=(select klient_kood from mr_arved where number=@number)

                                        insert ladu_sissetulekud_read
                                                (
                                                    number
                                                    ,artikkel
                                                    ,kogus
                                                    ,yhikuhind
                                                    ,rn
                                                    ,rv
                                                )
                                            select 
                                                    @number
                                                    ,ilr.artikkel
                                                    ,ABS(ilr.kogus)
                                                    ,(select top 1 viimane_ost from artiklid where kood=ilr.artikkel)
                                                    ,row_number() OVER (ORDER BY artikkel)
                                                    ,row_number() OVER (ORDER BY artikkel) 
                                            from in_liikumised_read as ilr where number=@webid and kogus<0

                                          INSERT #output 
                                        EXEC kinnita_LS @number 
										--Removed because confirmation now happens at 06:00 AM due to this causing calculation errors
                                        DELETE FROM #output 

                                            --update tell_tellimused set saldo=(select sum(tkkm) from tell_tellimused_read where number=@number) where number=@number
                                       -- insert into #results values (@webid, 'Stock Receipt', 1, 'OK',convert(nvarchar(255),@number))

                                        
                                    end 



                END

            
		  INSERT INTO #results 
		  VALUES (@webid, 'MOVEMENT', 0, 'OK', convert(nvarchar(255),@number)) 

				end
                
            else
        							begin
				insert into #results values (@webid, 'Stock movement', 2, 'DUPLICATE','1')

					
							end
          --SET @x=@x + 1 

          FETCH next FROM tellimused INTO @webid, @leftover, @webid2, @projektist, @stock
      END 

    CLOSE tellimused 

    DEALLOCATE tellimused 

    --cleanup 
    DELETE FROM in_liikumised_read 
    WHERE  number IN (SELECT number 
                      FROM   in_liikumised 
                      WHERE  x = @key) 

    DELETE FROM in_liikumised 
    WHERE  x = @key 
--------------------------


------ MOVEMENT2 -------
UPDATE in_liikumised2 
SET    x = @key 
WHERE  x IS NULL 

UPDATE in_liikumised_read2
SET    x = @key 
WHERE  x IS NULL AND lisa_field1 IN (SELECT lisa_field1 FROM in_liikumised2 WHERE x = @key)

DELETE FROM in_liikumised2 WHERE lisa_field1 IN (SELECT lisa_field1 FROM in_liikumised2 WHERE x = @key) AND x != @key
DELETE FROM in_liikumised_read2 WHERE lisa_field1 IN (SELECT lisa_field1 FROM in_liikumised2 WHERE x = @key) AND x != @key

DECLARE liikumised2 CURSOR LOCAL FAST_FORWARD FOR 
    SELECT lisa_field1, 
            leftover 
    FROM   in_liikumised2 
    WHERE  x = @key 

OPEN liikumised2  

FETCH next FROM liikumised2 INTO @webid, @leftover 

WHILE @@FETCH_STATUS = 0 
    BEGIN 
        SELECT @id_exist = Count(*) 
        FROM   ladu_liikumised WITH(nolock)
        WHERE  lisa_field1 = @webid 

        IF @id_exist = 0 
		BEGIN 
		set @ag = GETDATE()
		set @series = (select top 1 param1 from tr_params with(nolock) where tyyp = 'xml' and kood = 'series' and param2 = 'movement2')
				
		EXEC dbo.get_dok_number @moodul='liikumine', @seeria=@series, @number = NULL, @cu='XML', @aeg=@ag, @keel = 'ENG', @num = @number OUTPUT, @err = @err OUTPUT

		IF @number is not null 
		BEGIN
            --SET @number=@webid 

			------------Project card object field update ------------------
			SET @project = NULL

			SELECT @project = projekti, @new_objekt = objekt4 
			FROM   in_liikumised2 
            WHERE  lisa_field1 = @webid AND x = @key 

			SELECT @old_objekt = (SELECT TOP 1 kood FROM fin_objektid WITH(nolock) WHERE tase = 5 AND ','+projektid.objekt+',' LIKE '%,'+kood+',%') 
			FROM projektid WITH(nolock) 
			WHERE kood = @project 

			IF (ISNULL(@old_objekt,'') != ISNULL(@new_objekt,'') AND ISNULL(@new_objekt,'') != '') 
			BEGIN 
				UPDATE lepingud
				SET ts = GETDATE()
				WHERE number IN (SELECT number FROM lepingud_read WITH(nolock) WHERE ISNULL(projekt,'') = @project AND ISNULL(r_aeg2,'') = '')
				
				--preserve state 
				INSERT INTO #projektid SELECT * FROM projektid WITH(nolock) WHERE kood = @project

				IF (@old_objekt IS NULL)
				BEGIN 

					UPDATE projektid 
					SET objekt = isnull(objekt, '') + ',' + @new_objekt 
					WHERE kood = @project

				END 
				ELSE 
				BEGIN 

					UPDATE projektid 
					SET objekt = TRIM(REPLACE(','+objekt+',',','+@old_objekt+',',','+@new_objekt+','))
					WHERE kood = @project

					UPDATE projektid 
					SET objekt = REPLACE(objekt,',,',',')
					WHERE kood = @project
				
					UPDATE projektid 
					SET objekt = LEFT(objekt,LEN(objekt)-1)
					WHERE kood = @project

					UPDATE projektid 
					SET objekt = RIGHT(objekt,LEN(objekt)-1)
					WHERE kood = @project
				
				END

				EXEC sys.sp_set_session_context @KEY = N'sec_user', @VALUE = 'XML'
				EXEC dbo.create_history @before_save='#projektid', @after_save='projektid', @history='projektid_history', @kood=@project;
				TRUNCATE TABLE #projektid

			END

			------------END Project card object field update ------------------
            UPDATE ladu_liikumised 
			SET
                aeg=in_liikumised2.aeg, 
                laost=in_liikumised2.laost, 
                lattu=in_liikumised2.lattu, 
                projekt=in_liikumised2.projektist, 
                projekti=in_liikumised2.projekti, 
				hinnamuutus=0,
				lisa_field1=@webid
            FROM   in_liikumised2 
            WHERE  ladu_liikumised.number = @number AND in_liikumised2.lisa_field1 = @webid AND x=@key

            IF Isnull(@leftover, 0) = 1 
                BEGIN 
                    UPDATE in_liikumised_read2 
                    SET    sent_kogus = kogus,
						kogus = Isnull((SELECT Sum(kogus) FROM 
										int_artikli_ajalugu WITH(nolock)
										WHERE 
										kood=artikkel AND ladu = 'VENDINGO' AND aeg<(SELECT aeg FROM 
											in_liikumised2 
											WHERE lisa_field1 = @webid AND x=@key
										) AND 
										( SELECT projekt FROM int_laoid_hinnad t2 WITH(nolock)
										WHERE 
										t2.laoid=int_artikli_ajalugu.laoid)=(SELECT 
										projektist 
										FROM in_liikumised2 WHERE lisa_field1 = @webid AND x=@key)) 
                                    , 0) 
						+ Isnull((SELECT Sum(kogus_saadud) FROM 
									ladu_liikumised_read 
												INNER JOIN 
												ladu_liikumised ON 
				ladu_liikumised.number=ladu_liikumised_read.number 
						WHERE 
				Isnull(kinnitatud, 0)=0 AND 
				ladu_liikumised.aeg<(SELECT 
				aeg 
				FROM in_liikumised2 
				WHERE lisa_field1 = @webid AND x=@key) AND lattu='VENDINGO' AND artikkel=in_liikumised_read2.artikkel AND ladu_liikumised.projekti = (SELECT projektist FROM in_liikumised2 WHERE lisa_field1 = @webid AND x=@key)), 0) - 
				Isnull(kogus, 0) 
				END 

				INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv) 
				SELECT @number, 
						artikkel, 
						kogus, 
						kogus, 
						CONVERT(NVARCHAR,sent_kogus),
						(SELECT nimi 
						FROM   artiklid 
						WHERE  kood = artikkel), 
						Row_number() 
						OVER( 
						ORDER BY artikkel) rn, 
						Row_number() 
						OVER( 
						ORDER BY artikkel) rv
				FROM   in_liikumised_read2 
				WHERE  in_liikumised_read2.lisa_field1 = @webid AND x=@key
	  
				UPDATE ladu_liikumised_read
				SET kogus_saadud = 0
				WHERE  number = @number 
				AND ISNULL(kogus_saadud,0) < 0

				EXEC [dbo].[ladu_liik_komplekteeri] @number

				EXEC Hooldus_vaba 'liikumine', @number 

				EXEC Liikumine_laoid_split @number 

				DELETE FROM #output 

				INSERT #output 
				EXEC Kinnita_liik @number 

				if exists(select * from #output where response != 'Kinnitatud') begin 
					insert into buglist (aeg, norija, viga, seletus, tegi, valmis)
					select getdate(), 'in_likkumine2', convert(nvarchar,@number), response, 'XML', 1
					from #output
				end

				IF EXISTS(SELECT 1 FROM ladu_liikumised WITH(nolock) WHERE number = @number AND ISNULL(kinnitatud,0)=0)
				BEGIN

				EXEC Liikumine_laoid_split @number 

				DELETE FROM #output 

				INSERT #output 
				EXEC Kinnita_liik @number 

				if exists(select * from #output where response != 'Kinnitatud') begin 
					insert into buglist (aeg, norija, viga, seletus, tegi, valmis)
					select getdate(), 'in_likkumine2', convert(nvarchar,@number), response, 'XML', 1
					from #output

				end

				END

				INSERT INTO #results 
				VALUES (@webid, 'MOVEMENT2', 0, 'OK', 'Movements') 
			END 

		ELSE BEGIN 
			INSERT INTO #results VALUES (@webid, 'MOVEMENT2', 1, 'Failed to create document: ' + @err, 'Movements' )
		END

		END
		ELSE BEGIN 
			INSERT INTO #results VALUES (@webid, 'MOVEMENT2', 1, 'Duplicate', 'Movements') 
		END 

        --SET @x=@x + 1 

        FETCH next FROM liikumised2 INTO @webid, @leftover 
    END 

CLOSE liikumised2 
DEALLOCATE liikumised2

--cleanup 
DELETE FROM in_liikumised_read2 
WHERE lisa_field1 IN (SELECT lisa_field1 
                    FROM   in_liikumised2 
                    WHERE  x = @key) 

DELETE FROM in_liikumised2 
WHERE  x = @key 
----------------------------


-----MAPPOST INVENTORY TEST -----------------
--DECLARE @leftover INT, @id_exist INT, @webid2 INT

	UPDATE in_mappost_liikumised_read 
    SET    x = @key 
    WHERE  x IS NULL AND number IN (SELECT number FROM in_mappost_liikumised WHERE x = @key)

	DELETE FROM in_mappost_liikumised WHERE number IN (SELECT number FROM in_mappost_liikumised WHERE x = @key) AND x != @key
	DELETE FROM in_mappost_liikumised_read  WHERE number IN (SELECT number FROM in_mappost_liikumised WHERE x = @key) AND x != @key

	--changed where clause @13.06.2023 added isnull(lattu,'')!='' and isnull(laost,'')!='' and isnull(projektist,'')!='' and isnull(projekti,'')!='' [Martinsb]


    DECLARE tellimused CURSOR FOR 
      SELECT number, 
             leftover,
             number 
      FROM   in_mappost_liikumised 
      WHERE  x = @key and isnull(lattu,'')!='' and isnull(laost,'')!='' and isnull(projektist,'')!='' and isnull(projekti,'')!=''

    OPEN tellimused 

    FETCH next FROM tellimused INTO @webid, @leftover, @webid2

    WHILE @@FETCH_STATUS = 0 
      BEGIN 
        if((select count(number) from ladu_liikumised where sisekommentaar=convert(nvarchar(255),@webid))=0)
            begin

          EXEC dbo.get_dok_number @moodul='liikumine', @seeria='DOC', @NUMBER = NULL, @cu='xmlcore', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT 

                /*INSERT INTO ladu_liikumised 
                            (number, 
                             aeg, 
                             laost, 
                             lattu, 
                             projekt, 
                             projekti, 
                             ts, 
                             cu) 
                SELECT @number, 
                       aeg, 
                       laost, 
                       lattu, 
                       projektist, 
                       projekti, 
                       Getdate(), 
                       'XML' 
                FROM   in_liikumised 
                WHERE  number = @number */

				update ladu_liikumised
					set
						aeg=dateadd(ss,1,Z.AEG),
						--(select dateadd(mi,-5,dateadd(dd,1,cast(z.aeg as date)))),
						laost=z.laost, 
						lattu=z.lattu, 
						projekt=z.projektist,
						projekti=z.projekti,
						ts=getdate(), 
						cu='XML',
						sisekommentaar=@webid
						,lisa_field5='MAPPOST_INVENTORY'
						,lisa_field6=CONVERT(NVARCHAR(255),ISNULL(@LEFTOVER,0))
					from (select * from in_mappost_liikumised where number=@webid and x=@key)z
				where ladu_liikumised.number=@number 


/*
                IF Isnull(@leftover, 0) = 1 
                  BEGIN 
                      UPDATE in_mappost_liikumised_read  
                      SET    sent_kogus = isnull(kogus,0),
							kogus = Isnull((SELECT Sum(kogus) FROM 
                                     int_artikli_ajalugu 
                                     WHERE 
                                     kood 
                                     =artikkel 
                                            AND ladu 
                                     = 'VENDINGO' AND aeg<(SELECT dateadd(mi,-5,dateadd(dd,1,cast(aeg as date)))  FROM 
                                     in_mappost_liikumised 
                                     WHERE 
                                     number 
                                     = 
                                            @webid) AND 
                                     ( SELECT top 1 projekt FROM int_laoid_hinnad t2 
                                     WHERE 
                                     t2.laoid=int_artikli_ajalugu.laoid)=(SELECT 
                                     projektist 
                                     FROM 
                                            in_mappost_liikumised WHERE number=@webid)) 
                                     , 0) 
             + Isnull((SELECT Sum(kogus_saadud) FROM 
                          ladu_liikumised_read 
                                     INNER JOIN 
                                     ladu_liikumised ON 
      ladu_liikumised.number=ladu_liikumised_read.number 
             WHERE 
      Isnull(kinnitatud, 0)=0 AND 
      ladu_liikumised.aeg<(SELECT 
      aeg 
      FROM 
             in_mappost_liikumised 
      WHERE number= @webid) AND lattu='VENDINGO' AND artikkel=in_mappost_liikumised_read .artikkel AND ladu_liikumised.projekti = (SELECT projektist FROM in_mappost_liikumised WHERE number=@webid)), 0) - 
      Isnull(kogus, 0)
	  where number=@webid 
      END */


      INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv) 
      SELECT @number, 
			  artikkel, 
			  kogus, 
			  kogus, 
			  CONVERT(NVARCHAR(510),sent_kogus),
			  (SELECT top 1 nimi 
			  FROM   artiklid 
			  WHERE  kood = ilr.artikkel), 
			  row_number() OVER (ORDER BY artikkel),
			  row_number() OVER (ORDER BY artikkel) 
      FROM  in_mappost_liikumised_read  as ilr where number=@webid and x=@key and kogus>=0

	  INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv) 
      SELECT @number, 
			  artikkel, 
			  0,
			  0,
			  CONCAT(sent_kogus, ' (', kogus, ')'),
			  (SELECT top 1 nimi 
			  FROM   artiklid 
			  WHERE  kood = ilr.artikkel), 
			  row_number() OVER (ORDER BY artikkel),
			  row_number() OVER (ORDER BY artikkel) 
      FROM  in_mappost_liikumised_read  as ilr where number=@webid and  x=@key  and kogus<0


		  EXEC [dbo].[ladu_liik_komplekteeri] @number
		  update ladu_liikumised_read set kogus_saadud=kogus where number=@number and kogus_saadud is null



		  if (select count(*) from ladu_liikumised_read where artikkel='DEPOSIT' and number=@number)>=1
	begin
		select @maxrn = max(rn)+1 from ladu_liikumised_read where number=@number
		insert ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv)
		select @number,'DEPOSIT',sum(kogus),sum(kogus_saadud),CONVERT(NVARCHAR(510),sum(kogus_saadud)),(select nimi from artiklid where kood='DEPOSIT'),@maxrn,@maxrn from ladu_liikumised_read where number=@number and artikkel='DEPOSIT' group by number,artikkel

		update ladu_liikumised_read set kogus=0, kogus_saadud=0  where number=@number and artikkel='DEPOSIT' and rn!=@maxrn
	end

		  EXEC Hooldus_vaba 'liikumine', @number 
		  --EXEC dbo.liikumine_sn_split @number
		--  EXEC dbo.liikumine_laoid_split @number
		  
		  --EXEC dbo.after_save @moodul = 'liikumine', @number = @number
            exec dbo.after_save_klient 'liikumine', @NUMBER, NULL, NULL, NULL

		 -- INSERT #output 
		 -- 	EXEC Kinnita_liik @number 
		--  DELETE FROM #output

		 


/*

            IF Isnull(@leftover, 0) = 1 
            BEGIN 
                if (isnull((select count(artikkel) from in_mappost_liikumised_read  where number=@webid2 and kogus<0),0)>0)
                                    BEGIN
                                        EXEC dbo.get_dok_number @moodul='sissetulek', @seeria='DOC', @NUMBER = NULL, @cu='xmlcore', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT

                                        update ladu_sissetulekud
                                            set
                                                hankija_kood='VIRT',
                                                ladu='VENDINGO',
                                                projekt=z.projektist,
                                                aeg=(select dateadd(ss,-1,dateadd(mi,-1,dateadd(dd,1,cast(z.aeg as date))))),
                                                ts=Getdate(),
                                                cu='XML',
                                                konto='7110101'
                                            from (select * from in_mappost_liikumised where number=@webid)z
                                        where ladu_sissetulekud.number=@number 

                                                        --select @maa = isnull(maa,0) from kliendid where kood=(select klient_kood from mr_arved where number=@number)

                                        insert ladu_sissetulekud_read
                                                (
                                                    number
                                                    ,artikkel
                                                    ,kogus
                                                    ,yhikuhind
                                                    ,rn
                                                    ,rv
                                                )
                                            select 
                                                    @number
                                                    ,ilr.artikkel
                                                    ,ABS(ilr.kogus)
                                                    ,(select top 1 viimane_ost from artiklid where kood=ilr.artikkel)
                                                    ,row_number() OVER (ORDER BY artikkel)
                                                    ,row_number() OVER (ORDER BY artikkel) 
                                            from in_mappost_liikumised_read  as ilr where number=@webid and kogus<0

                                          INSERT #output 
                                        EXEC kinnita_LS @number 
										--Removed because confirmation now happens at 06:00 AM due to this causing calculation errors
                                        DELETE FROM #output 

                                            --update tell_tellimused set saldo=(select sum(tkkm) from tell_tellimused_read where number=@number) where number=@number
                                       -- insert into #results values (@webid, 'Stock Receipt', 1, 'OK',convert(nvarchar(255),@number))

                                        
                                    end 



                END

            */
		  INSERT INTO #results 
		  VALUES (@webid, 'MOVEMENT', 0, 'OK', convert(nvarchar(255),@number)) 

				end
                
            else
        							begin
				insert into #results values (@webid, 'Stock movement', 2, 'DUPLICATE','1')

					
							end
          --SET @x=@x + 1 

          FETCH next FROM tellimused INTO @webid, @leftover, @webid2
      END 

    CLOSE tellimused 

    DEALLOCATE tellimused 

    --cleanup 
      DELETE FROM in_mappost_liikumised_read  
    WHERE  number IN (SELECT number 
                      FROM   in_mappost_liikumised 
                      WHERE  x = @key and isnull(laost,'')!='' and isnull(lattu,'')!='' and isnull(projektist,'')!='' and isnull(projekti,'')!='') 

    DELETE FROM in_mappost_liikumised 
    WHERE  x = @key and isnull(laost,'')!='' and isnull(lattu,'')!='' and isnull(projektist,'')!='' and isnull(projekti,'')!=''

-----------------------------------------	
declare tellimused insensitive cursor for select number,kommentaar from in_kassa_liikumised
open tellimused
FETCH NEXT FROM tellimused INTO @webid, @kommentaar
WHILE @@FETCH_STATUS = 0
BEGIN
set @number=(select max(number) + 1 from kassa_liikumised)
		if exists (select kommentaar from kassa_liikumised where kommentaar=@kommentaar)
		begin
		set @cashmove_duplicate=@cashmove_duplicate+1
			insert into #results values (@number, 'KLIIK', 1, 'Duplicate',NULL)
		END
		ELSE
		BEGIN
		insert into kassa_liikumised 
    (
        number
      , summa
      , kokku
      , aeg
      , tasumisviisist
      , tasumisviisi
      , kasutaja
      , kommentaar
      , projektist
      , projekti
      , valuuta
      , baasv1
      , ts
      , cu
      , kurss
      , kinnitatud
      , arvuti
      , arvutisse
      , dokument
      , kaibemaks
      , kurss_e
    )
		select top 1 
        @number
		  , summa
		  , kokku
		  , aeg
		  , (select top 1 tviis from arvutid where kood='POS')
		  , (select top 1 piirang from arvutid where  kood='POS')
		  , 'EC'
		  , kommentaar
		  , projektist
		  , projekti
		  , valuuta
		  , kokku
		  , getdate()
		  , 'EC'
		  , kurss
		  , 'False'
		  , 'POS'
	    	, 'POS'
	    , @webid
      , 0
      , 0
		from in_kassa_liikumised
    where
    number=@webid

		if((select count(number) from in_kassa_liikumised where number=@webid)=1)
		begin
insert into #results values (@number, 'KLIIK', 0, 'OK',NULL)
		set @cashmove_ok=@cashmove_ok+1
		end

DECLARE @tmp TABLE (response NVARCHAR(MAX))
INSERT INTO @tmp 
exec kinnita_KLIIK @number

		
		END
		

		FETCH NEXT FROM tellimused INTO @webid, @kommentaar
END
CLOSE tellimused
DEALLOCATE tellimused


--cleanup
delete from in_kassa_liikumised where x=@key

----- CONTRACTS IN START -----
DECLARE @konto NVARCHAR(255)=''
DECLARE @proj NVARCHAR(32),
		@action INT,
		@dt DATETIME,
		@contract_no INT,
		@m_nr INT,
		@BRANDING nvarchar(2000)
	
UPDATE in_lepingud
SET x = @key
WHERE x is NULL

DELETE FROM in_lepingud WHERE project + CONVERT(NVARCHAR, ISNULL(action, 0)) IN (SELECT project + CONVERT(NVARCHAR, ISNULL(action, 0)) FROM in_lepingud WHERE x=@key) AND x!=@key
	
DECLARE leping_cur CURSOR FOR 
SELECT action, project, dt, contract_number, BRANDING
FROM in_lepingud
WHERE x = @key
	
OPEN leping_cur 
FETCH next FROM leping_cur INTO @action, @proj, @dt, @contract_no, @BRANDING
WHILE @@FETCH_STATUS = 0 
BEGIN
	if (@action = 0) -- removing
	BEGIN
		DECLARE @subj1 NVARCHAR(255),
					@letter1 NVARCHAR(512),
					@mails1 NVARCHAR(max)
					
		SET @subj1 = N'Iekārta noņemta no klienta ['+ ISNULL((SELECT ISNULL(nimi,'') FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM projektid WITH(nolock) WHERE kood = @proj)),'')+']: ['+ISNULL((SELECT ISNULL(nimi,'') FROM artiklid WITH(nolock) WHERE kood = (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)),'')+'] [' + @proj + ']'
		
		UPDATE lepingud
		SET ts = GETDATE()
		WHERE number IN (SELECT number FROM lepingud_read WHERE ISNULL(projekt,'') = @proj AND ISNULL(r_aeg2,'') = '')
	
		-- set end date
		UPDATE lepingud_read
		SET r_aeg2 = @dt
		WHERE ISNULL(projekt,'') = @proj
		AND ISNULL(r_aeg2,'') = ''
			
		-- set project attribute end date
		UPDATE yld_data
		SET param = REPLACE(CONVERT(NVARCHAR,@dt,102), '.', ' ')
		WHERE klass = 'PROJEKT'
		AND kood IN ('BASE','NRI','NAYAX','COOLER','SYRUP','VENDON')
		AND kaart = @proj
		AND ISNULL(sisu,'') != ''
		AND ISNULL(param,'') = ''

		DELETE yld_data WHERE klass = 'PROJEKT' AND kood = 'water_filter' AND kaart = @proj
		
		--preserve state 
		INSERT INTO #projektid SELECT * FROM projektid WITH(nolock) WHERE kood = @proj
			
		UPDATE projektid
		SET klient_kood = null,
			klient_nimi = null,
			kl_kontakt = null,
			kl_kontakt_telefon = null,
			kl_kontakt_email = null
		WHERE kood = @proj

		EXEC sys.sp_set_session_context @KEY = N'sec_user', @VALUE = 'XML'
		EXEC dbo.create_history @before_save='#projektid', @after_save='projektid', @history='projektid_history', @kood=@proj;
		TRUNCATE TABLE #projektid
			
		-- move from KLIENTU_IRANGA to XXX_NAUDOTA_IRANGA
		SET @m_nr = (SELECT MAX(number)+1 FROM ladu_liikumised WITH(nolock) WHERE number < 2300000)
			
		INSERT INTO ladu_liikumised (number, laost, lattu, kinnitatud, aeg, ts, cu, hinnamuutus, kasutaja/*, kl_kood, kl_nimi*/)
		SELECT @m_nr, 'IEK_KLIENTI', (SELECT TOP 1 stock FROM in_lepingud WITH(nolock) WHERE project = @proj), 0, GETDATE(), GETDATE(), 'XML', 0, 'XML'
			
		INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, seerianumber, nimetus)
		SELECT @m_nr, (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC),
				1, 1, @proj
				,(SELECT nimi FROM artiklid WITH(nolock) WHERE kood = (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC))
			
		DECLARE @rn INT
		SET	@rn = 0
			
		UPDATE ladu_liikumised_read
		SET @rn = rn = @rn +1
		WHERE number = @m_nr
			
		EXEC Hooldus_vaba 'liikumine', @m_nr 

		EXEC Liikumine_laoid_split @m_nr 

		DELETE FROM #output 
		IF EXISTS(SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC) 
		BEGIN
			INSERT #output 
			EXEC Kinnita_liik @m_nr
		END
		
		-- removing customer from inventory
		UPDATE inventar
		SET klient_kood = null,
			klient_nimi = null
		WHERE ISNULL(seerianumber,'') = @proj
		
		UPDATE yld_data
		SET sisu = null, param = null
		WHERE kood = '3020'
		AND klass = 'INVENTAR'
		AND kaart IN (SELECT kood FROM inventar WITH(nolock) WHERE ISNULL(seerianumber,'') = @proj)

		

		--SET @subj1 = N'Created movement: ' + CONVERT(NVARCHAR,@m_nr)
		
		SET @letter1 = '<br/>Created movement: <a target="blank_" href="https://login.directo.ee/ocra_selecta_lv/ladu_liigu.asp?number=' + CONVERT(NVARCHAR,@m_nr) + '">' + CONVERT(NVARCHAR,@m_nr) + '</a>.'

		SET @letter1 = @letter1 + N'<br/>Realted project: <a target="blank_" href="https://login.directo.ee/ocra_selecta_lv/yld_projekt.asp?KOOD=' + @proj + '">' + @proj + '</a>.'

		SET @mails1 = REPLACE(ISNULL((SELECT TOP 1 sisu 
											FROM uuringud_read WITH(nolock) 
											JOIN uuringud ON uuringud_read.kood = uuringud.kood
											WHERE field = 'EMAIL_INVENTORY'
											AND uuringud.tyyp = 'VENDING'),'Inara.Kuma@coffeeaddress.lv;Oskars.Rumpe@coffeeaddress.lv'), ',', ';')
			
		EXEC msdb.dbo.Sp_send_dbmail
			@recipients=@mails1,
			@body_format='HTML',
			@body = @letter1,
			@subject= @subj1;				

		INSERT INTO #results 
		VALUES (@proj, 'CONTRACT', 0, 'Removed', 'Contracts') 
	END
	ELSE BEGIN
		SET @m_nr = ISNULL((SELECT TOP 1 number FROM lepingud WHERE number = @contract_no),0)
			
		IF (@m_nr = 0)
		BEGIN
			INSERT INTO #results 
			VALUES (@contract_no, 'CONTRACT', 10, 'Contract not found!', 'Contracts') 
		END
		ELSE BEGIN

		IF EXISTS(SELECT 1 FROM lepingud_read WITH(nolock) WHERE number = @m_nr AND projekt = @proj AND r_aeg1 = @dt) 
		BEGIN
			INSERT INTO #results 
			VALUES (@contract_no, 'CONTRACT', 10, 'Contract import canceled!', 'Contracts') 
		END 
		ELSE 
		BEGIN 
			-- 2.1 add to contract
			DECLARE @it NVARCHAR(32),
					@itt NVARCHAR(32),
					@row_no INT,
					@contract INT
						
						
			SET @it = (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)
			SET @itt = (SELECT TOP 1 sisu FROM yld_data WITH(nolock) WHERE ISNULL(sisu,'') != '' AND klass = 'artikkel' AND kood = 'SUT_ITEM' AND kaart = @it)
			SET @row_no = ISNULL((SELECT MAX(rn)+1 FROM lepingud_read WITH(nolock) WHERE number = @m_nr),1)
			SET @contract = @m_nr
			
			UPDATE lepingud
			SET ts = GETDATE()
			WHERE number = @contract

			IF NOT EXISTS(SELECT 1 FROM lepingud_read WITH(nolock) WHERE number = @contract AND projekt = @proj AND r_aeg1 = @dt) 
			BEGIN
				
				INSERT INTO lepingud_read (number, tyyp, rn, rv, kood, nimi, kogus, objekt, projekt, kmk, r_aeg1, konto, hind, summa )
				SELECT @contract, 0
						,@row_no
						,@row_no
						,@itt
						,(SELECT nimi FROM artiklid WITH(nolock) WHERE kood = @itt)
						,1
						,(SELECT objekt FROM artiklid WITH(nolock) WHERE kood = @itt)
						,@proj
						,(SELECT TOP 1 kmk FROM lepingud_read WITH(nolock) WHERE number = @m_nr AND ISNULL(kmk,'') != '')
						,@dt 
						,(SELECT param1 FROM tr_params WITH(nolock) WHERE tyyp = 'XMLCORE' AND kood = 'ContractRowAccount') 
						,(SELECT TOP 1 price FROM in_lepingud WITH(nolock) WHERE project = @proj) 
						,(SELECT TOP 1 price FROM in_lepingud WITH(nolock) WHERE project = @proj) 
			
			END			
			-- 2.2. create project
				IF NOT(EXISTS(SELECT * FROM projektid WITH(nolock) WHERE kood = @proj))
				BEGIN
					INSERT INTO projektid (kood, nimi, cu, ts, valuuta, klient_kood, klient_nimi, suletud, aeg_loodud, looja, objekt, proj_tyyp, juht)
					SELECT @proj
							,(SELECT nimi FROM artiklid WITH(nolock) WHERE kood = @it) 
							,'XML', GETDATE(), 'EUR' 
							,(SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)
							,(SELECT nimi FROM kliendid WITH(nolock) WHERE kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj))
							,0 , GETDATE(), 'XML' 
							,(SELECT TOP 1 business_type FROM in_lepingud WITH(nolock) WHERE project = @proj)
							,(SELECT TOP 1 projekt_tyyp FROM in_lepingud WITH(nolock) WHERE project = @proj)
							,(SELECT TOP 1 technician FROM in_lepingud WITH(nolock) WHERE project = @proj)
					
					declare @itemCodeForDF nvarchar(64) = (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)
					;with src (project, df_code, df_val) as
					(select @proj, 'HOLDING_TYPE' df_code
							, (select top 1 sisu from yld_data with(nolock) where klass = 'artikkel' and kood = 'HOLD_TYPE' and kaart = @itemCodeForDF and sisu>'') df_val
					union select @proj, 'HOLDING_NAME' df_code
							, (select top 1 sisu from yld_data with(nolock) where klass = 'artikkel' and kood = 'HOLD_NAME' and kaart = @itemCodeForDF and sisu>'') df_val)
					merge yld_data as trgt
					using src on trgt.klass = 'PROJEKT' and trgt.kood = src.df_code and trgt.kaart = src.project
					when NOT MATCHED by target then
					insert (kood, klass, kaart, sisu)
					values (src.df_code, 'PROJEKT', src.project, src.df_val)
					when MATCHED then
					update set trgt.sisu = src.df_val;
				END
				ELSE BEGIN -- update project
					-- 2.4. update project
					--preserve state 
					INSERT INTO #projektid SELECT * FROM projektid WITH(nolock) WHERE kood = @proj

					UPDATE projektid
					SET klient_kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj),
						klient_nimi = (SELECT nimi FROM kliendid WITH(nolock) WHERE kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)),
						ts = GETDATE(),
						--objekt=(SELECT TOP 1 objekt FROM in_lepingud WITH(nolock) WHERE project = @proj)
						proj_tyyp=ISNULL((SELECT TOP 1 nullif(projekt_tyyp,'') FROM in_lepingud WITH(nolock) WHERE project = @proj),(SELECT proj_tyyp FROM projektid WITH(nolock) WHERE kood = @proj))
						,cu = 'XML'
					WHERE kood = @proj

					EXEC sys.sp_set_session_context @KEY = N'sec_user', @VALUE = 'XML'
					EXEC dbo.create_history @before_save='#projektid', @after_save='projektid', @history='projektid_history', @kood=@proj;
					TRUNCATE TABLE #projektid
				END

				-- event 694748
				UPDATE a SET
					objekt = dbo.get_objekt_hr(a.objekt, b.kood)
				FROM projektid a
				CROSS APPLY (
					SELECT TOP 1 o.kood FROM fin_objektid o WITH(nolock) 
					INNER JOIN yld_data y WITH(nolock) ON o.kood = y.kaart
					WHERE o.tase = 8 AND y.klass = N'OBJEKT' AND y.kood = N'BRANDING_MAPPING_CONTRACTS' AND y.sisu = @BRANDING
				) b
				WHERE a.kood = @proj AND @BRANDING != ''

				INSERT INTO [dbo].[in_projektid] (kood, objekt, juht, business_type, x) SELECT TOP 1 project, objekt, technician, business_type, x FROM in_lepingud WITH(nolock) WHERE project = @proj

			-- 2.5. update/create datafields
			;with src (project, df_code, df_val) as 
			(select project, df_code, df_val from in_lepingud 
			unpivot (df_val for df_code in (BRANDING, ABC, ARMOR)) unpiv
			where x = @key and project = @proj)
			merge yld_data as trgt
			using src on trgt.klass = 'PROJEKT' and trgt.kood = src.df_code and trgt.kaart = src.project
			when NOT MATCHED by target then
			insert (kood, klass, kaart, sisu)
			values (src.df_code, 'PROJEKT', src.project, src.df_val)
			when MATCHED then
			update set trgt.sisu = src.df_val;

			UPDATE yld_data
			SET param = REPLACE(CONVERT(NVARCHAR,@dt,102), '.', ' ')
			WHERE klass = 'PROJEKT'
			AND kood IN ('BASE','NRI','NAYAX','COOLER','SYRUP','VENDON')
			AND kaart = @proj
			AND ISNULL(sisu,'') != ''
			AND ISNULL(param,'') = ''
				
			IF (EXISTS(SELECT TOP 1 ISNULL(nayax,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(nayax,'') != ''))
			BEGIN
				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'NAYAX', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(nayax,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(nayax,'') != '')
			END
				
			IF (EXISTS(SELECT TOP 1 ISNULL(nri,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(nri,'') != ''))
			BEGIN
				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'NRI', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(nri,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(nri,'') != '')
			END
				
			IF (EXISTS(SELECT TOP 1 ISNULL(base,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(base,'') != ''))
			BEGIN
				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'BASE', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(base,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(base,'') != '')
			END
			---------------------------------------------------------------------------
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(COOLER,'') != ''))
			BEGIN
				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'COOLER', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(COOLER,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(COOLER,'') != '')
			END
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(SYRUP,'') != ''))
			BEGIN
				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'SYRUP', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(SYRUP,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(SYRUP,'') != '')
			END
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(VENDON,'') != ''))
			BEGIN
				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'VENDON', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(VENDON,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(VENDON,'') != '')
			END
			--only update
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(TASKER_CONTACT_PERSON,'') != ''))
			BEGIN
				DELETE yld_data WHERE kood = 'TASKER_CONTACT_PERSON' AND klass = 'KLIENT' AND kaart = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)

				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'TASKER_CONTACT_PERSON', 'KLIENT', (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj), (SELECT TOP 1 ISNULL(TASKER_CONTACT_PERSON,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(TASKER_CONTACT_PERSON,'') != '')
			END
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(TASKER_MAIL,'') != ''))
			BEGIN
				DELETE yld_data WHERE kood = 'TASKER_MAIL' AND klass = 'KLIENT' AND kaart = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)

				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'TASKER_MAIL', 'KLIENT', (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj), (SELECT TOP 1 ISNULL(TASKER_MAIL,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(TASKER_MAIL,'') != '')
			END
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(TASKER_PHONE,'') != ''))
			BEGIN
				DELETE yld_data WHERE kood = 'TASKER_PHONE' AND klass = 'KLIENT' AND kaart = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)

				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'TASKER_PHONE', 'KLIENT', (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj), (SELECT TOP 1 ISNULL(TASKER_PHONE,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(TASKER_PHONE,'') != '')
			END
			IF (EXISTS(SELECT 1 FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(water_filter,'') != ''))
			BEGIN
				DELETE yld_data WHERE kood = 'water_filter' AND klass = 'KLIENT' AND kaart = (SELECT TOP 1 water_filter FROM in_lepingud WITH(nolock) WHERE project = @proj)

				INSERT INTO yld_data (kood, klass, kaart, sisu)
				SELECT 'water_filter', 'PROJEKT', @proj, (SELECT TOP 1 ISNULL(water_filter,'') FROM in_lepingud WITH(nolock) WHERE project = @proj AND ISNULL(water_filter,'') != '')
			END
			----------------------------------------------------------------------------
				
			DECLARE @subj NVARCHAR(255),
					@letter NVARCHAR(512) = '',
					@inv_card NVARCHAR(32),
					@inv_class NVARCHAR(32),
					@supp NVARCHAR(32)
				
			DECLARE @new_inventory INT=0
			-- 2.6. creating inventory card
			IF ((SELECT TOP 1 stock FROM in_lepingud WITH(nolock) WHERE project = @proj) IN ('JAUN_RIGA','JAUN_DAUGAVP ','JAUN_LIEP','JAUN_RIGA_VENDING '))
					AND NOT EXISTS ( SELECT klass FROM lepingud WITH(nolock) WHERE number = @contract AND klass = 'SOLDMACHINE' )
			BEGIN
				SET @new_inventory = 1

				SELECT @inv_card = CONVERT(NVARCHAR,MAX(kood)+1)
				FROM inventar
				WHERE isnumeric(kood) = 1
				
				SET @inv_class = (SELECT TOP 1 sisu FROM yld_data WITH(nolock) WHERE klass = 'ARTIKKEL' AND kood = 'ILG_TURT' AND kaart = @it)
				SET @supp = (SELECT hankija FROM int_laoid_hinnad WHERE laoid = (SELECT TOP 1 I.laoid FROM int_artikli_ajalugu I WITH(nolock) WHERE ISNULL(I.sn,'') = @proj ORDER BY aeg DESC))
				
				INSERT INTO inventar (kood, nimetus, suletud, mis, s_maksumus, amort, hankija_kood, hankija_nimi, ostuarve, aeg, klass, vastutaja, objekt, k_maksumus, h_maksumus, kulum, aeg2, ts, cu, k_amort, k_kulum, k_maha, k_vara, myygi_kasum, myygi_kahjum, seerianumber, projekt, tyyp, jaakvaartus, aeg_ostetud, reg_jaak)
				
				SELECT @inv_card -- kood				
						,(SELECT nimi FROM artiklid WITH(nolock) WHERE kood = @it) -- nimetus						
						,0 -- suletud						
						,1 -- mis
						,(SELECT TOP 1 I.hind / ISNULL(I.kurss_e,1) FROM int_artikli_ajalugu I WITH(nolock) WHERE ISNULL(I.sn,'') = @proj ORDER BY aeg DESC) --s_maksumus						
						,(SELECT ISNULL(protsent,0) FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class) -- amort						
						,@supp -- hankija						
						,(SELECT nimi FROM hankijad WHERE kood = @supp) -- hankija_nimi						
						,(SELECT TOP 1 O.number FROM or_arved O WITH(nolock) WHERE ISNULL(O.sissetulek,0) = (SELECT TOP 1 U.number FROM int_artikli_ajalugu U WITH(nolock) WHERE ISNULL(U.sn,'') = @proj AND tyyp = 'SIS' ORDER BY aeg ASC)) --ostuarve						
						,DATEADD(m, DATEDIFF(m, -1, current_timestamp), 0) --@dt, -- aeg
						,@inv_class --klass						
						,'SVIKEA' -- vastutaja
						,null --objekt
						,0 -- k_maksumus
						,(SELECT TOP 1 I.hind / ISNULL(I.kurss_e,1) FROM int_artikli_ajalugu I WITH(nolock) WHERE ISNULL(I.sn,'') = @proj ORDER BY aeg ASC) -- h_maksumus
						,0 --kulum (sukauptas nusid)
						,null  --aeg2
						,GETDATE() --ts
						,'Int_hooldus_klient_sut' --cu
						,(SELECT ISNULL(amort,'') FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class)
						,(SELECT ISNULL(kulum,'') FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class)
						,(SELECT ISNULL(maha,'') FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class)
						,(SELECT ISNULL(vara,'') FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class)
						,(SELECT ISNULL(myygi_kasum,'') FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class)
						,(SELECT ISNULL(myygi_kahjum,'') FROM inventari_klassid WITH(nolock) WHERE kood = @inv_class)
						,@proj 
						,@proj
						,0 -- tyyp
						,0 -- jaakvaartus
						,(SELECT TOP 1 O.aeg FROM or_arved O WITH(nolock) WHERE ISNULL(O.sissetulek,0) = (SELECT TOP 1 U.number FROM int_artikli_ajalugu U WITH(nolock) WHERE ISNULL(U.sn,'') = @proj AND tyyp = 'SIS' ORDER BY aeg ASC))
						,(SELECT TOP 1 I.hind / ISNULL(I.kurss_e,1) FROM int_artikli_ajalugu I WITH(nolock) WHERE ISNULL(I.sn,'') = @proj ORDER BY aeg DESC)
						
					
				
			END

			IF NOT EXISTS ( SELECT klass FROM lepingud WITH(nolock) WHERE number = @contract AND klass = 'SOLDMACHINE' )
				EXEC [dbo].[Int_hooldus_klientLEPINGUD_AUTO_PROCEDURE] '1/1/2018', '1/1/2018', @proj
			
			UPDATE inventar
			SET klient_kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj),
				klient_nimi = (SELECT nimi FROM kliendid WITH(nolock) WHERE kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)) 
			WHERE ISNULL(seerianumber,'') = @proj
			
			
			IF NOT EXISTS ( SELECT klass FROM lepingud WITH(nolock) WHERE number = @contract AND klass = 'SOLDMACHINE' )
			BEGIN
				-- insert where missing 
				INSERT INTO yld_data (kood, klass, kaart)
				SELECT '3020', 'INVENTAR', kood
				FROM inventar WITH(nolock)
				WHERE kood IN (SELECT kood FROM inventar WITH(nolock) WHERE ISNULL(seerianumber,'') = @proj)
				AND NOT(EXISTS(SELECT * FROM yld_data WITH(nolock) WHERE kood = '3020' AND klass = 'INVENTAR' AND kaart IN (SELECT kood FROM inventar WITH(nolock) WHERE ISNULL(seerianumber,'') = @proj)))
			
				-- update all
				UPDATE yld_data
				SET sisu = (SELECT arvetasub FROM kliendid WITH(nolock) WHERE kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)),
					param = (SELECT CONVERT(NVARCHAR(32),nimi) FROM kliendid WHERE kood = (SELECT arvetasub FROM kliendid WITH(nolock) WHERE kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)))
				WHERE kood = '3020'
				AND klass = 'INVENTAR'
				AND kaart IN (SELECT kood FROM inventar WITH(nolock) WHERE ISNULL(seerianumber,'') = @proj)
				
				-- 2.6. moving from NEW stock to CUSTOMER stock
				SET @m_nr = (SELECT MAX(number)+1 FROM ladu_liikumised WITH(nolock) WHERE number < 2300000)
			
				INSERT INTO ladu_liikumised (number, laost, lattu, kinnitatud, aeg, ts, cu, hinnamuutus, kasutaja, kl_kood, kl_nimi, konto)
				SELECT @m_nr
						,(SELECT TOP 1 stock FROM in_lepingud WITH(nolock) WHERE project = @proj)
						,'IEK_KLIENTI'
						, 0, GETDATE(), GETDATE(), 'XML', 1, 'XML'
						,(SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj)
						,(SELECT nimi FROM kliendid WITH(nolock) WHERE kood = (SELECT TOP 1 customer FROM in_lepingud WITH(nolock) WHERE project = @proj))
						,(SELECT param1 FROM tr_params WITH(nolock) WHERE tyyp = 'XMLCORE' AND kood = 'MovementAccount') 
				
				INSERT INTO ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, seerianumber, nimetus, uushind, laoid, fifo, rn, rv , trn)
				SELECT @m_nr
						,(SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)
						,1, 1
						,@proj
						,(SELECT nimi FROM artiklid WITH(nolock) WHERE kood = (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC))
						,0
						,(SELECT TOP 1 laoid FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)
						,(SELECT TOP 1 hind FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)
						,1,1,1
						
				SELECT @konto = vara FROM inventari_klassid WITH(nolock) WHERE kood IN (SELECT sisu FROM yld_data WITH(nolock) WHERE klass = 'ARTIKKEL' AND kood = 'ILG_TURT' AND kaart IN (SELECT artikkel FROM ladu_liikumised_read WITH(nolock) WHERE number = @m_nr))

				IF (ISNULL(@konto,'')!='') 
				BEGIN 
					UPDATE ladu_liikumised SET konto = @konto WHERE number = @m_nr 
				END

				EXEC Hooldus_vaba 'liikumine', @m_nr 

				EXEC Liikumine_laoid_split @m_nr
	
				DELETE FROM #output 

				IF EXISTS(SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC) 
				BEGIN
					INSERT #output  
					EXEC Kinnita_liik @m_nr
				END
			END
				
			-- 2.7. sending emial
			SET @subj = N'Iekārta uzstādīta pie klienta  ['+ ISNULL((SELECT ISNULL(nimi,'') FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM projektid WITH(nolock) WHERE kood = @proj)),'')+']: ['+ISNULL((SELECT ISNULL(nimi,'') FROM artiklid WITH(nolock) WHERE kood = (SELECT TOP 1 kood FROM int_artikli_ajalugu WITH(nolock) WHERE ISNULL(sn,'') = @proj ORDER BY aeg DESC)),'')+'] [' + @proj + ']' 
			
			IF ((SELECT TOP 1 stock FROM in_lepingud WITH(nolock) WHERE project = @proj) IN ('JAUN_RIGA','JAUN_DAUGAVP ','JAUN_LIEP','JAUN_RIGA_VENDING '))
				AND NOT EXISTS ( SELECT klass FROM lepingud WITH(nolock) WHERE number = @contract AND klass = 'SOLDMACHINE' )
			BEGIN
				SET @letter = (CASE WHEN @new_inventory = 1 THEN N'Created' ELSE N'Updated' END) + N' inventory card: <a target="blank_" href="https://login.directo.ee/ocra_selecta_lv/yld_inventar.asp?KOOD=' + @inv_card + '">' + @inv_card + '</a>.'
			END
			
			SET @letter = @letter + N'<br/>Contract: <a target="blank_" href="https://login.directo.ee/ocra_selecta_lv/leping.asp?number=' + CONVERT(NVARCHAR,@contract) + '">' + CONVERT(NVARCHAR,@contract) + '</a>.'			
			
			IF NOT EXISTS ( SELECT klass FROM lepingud WITH(nolock) WHERE number = @contract AND klass = 'SOLDMACHINE' )
				SET @letter = @letter + N'<br/>Created movement: <a target="blank_" href="https://login.directo.ee/ocra_selecta_lv/ladu_liigu.asp?number=' + CONVERT(NVARCHAR,@m_nr) + '">' + CONVERT(NVARCHAR,@m_nr) + '</a>.'

			SET @letter = @letter + N'<br/>Related project: <a target="blank_" href="https://login.directo.ee/ocra_selecta_lv/yld_projekt.asp?KOOD=' + @proj + '">' + @proj + '</a>.'
				
			DECLARE @mails NVARCHAR(max)
			SET @mails = REPLACE(ISNULL((SELECT TOP 1 sisu 
											FROM uuringud_read WITH(nolock) 
											JOIN uuringud ON uuringud_read.kood = uuringud.kood
											WHERE field = 'EMAIL_INVENTORY'
											AND uuringud.tyyp = 'VENDING'),'Inara.Kuma@coffeeaddress.lv;Oskars.Rumpe@coffeeaddress.lv'), ',', ';')
			
			EXEC msdb.dbo.Sp_send_dbmail
			@recipients=@mails,
			@body_format='HTML',
			@body = @letter,
			@subject= @subj;

			INSERT INTO #results 
			VALUES (@proj, 'CONTRACT', 0, CONVERT(NVARCHAR,@contract)+CONVERT(NVARCHAR,@row_no), 'Contracts') 
		END

		END
	END



	FETCH next FROM leping_cur INTO @action, @proj, @dt, @contract_no, @BRANDING
END
	
CLOSE leping_cur 
DEALLOCATE leping_cur
	
DELETE FROM in_lepingud
WHERE x = @key
-- CONTRACTS IN END -----

	SET @step = 'PROJECT IN'
	--PROJECT IN 
	--SELECT * FROM [dbo].[in_projektid] 



    UPDATE [dbo].[in_projektid] 
    SET    x = @key 
    WHERE  x IS NULL

    DECLARE tellimused CURSOR FOR 
    SELECT kood, objekt, business_type, juht   
    FROM   [dbo].[in_projektid] 
    WHERE  x = @key 

    OPEN tellimused 

	FETCH next FROM tellimused INTO @webid, @objekt, @new_objekt2, @manager 

	WHILE @@FETCH_STATUS = 0 
    BEGIN 

		IF EXISTS(SELECT 1 FROM projektid WITH(nolock) WHERE kood = @webid)
		BEGIN 

			SELECT @old_objekt = (SELECT TOP 1 kood FROM fin_objektid WITH(nolock) WHERE tase = 5 AND ','+projektid.objekt+',' LIKE '%,'+kood+',%') 
			FROM projektid WITH(nolock) 
			WHERE kood = @webid 

			SELECT @old_objekt2 = (SELECT TOP 1 kood FROM fin_objektid WITH(nolock) WHERE tase = 2 AND ','+projektid.objekt+',' LIKE '%,'+kood+',%') 
			FROM projektid WITH(nolock) 
			WHERE kood = @webid 

			SET @new_objekt = @objekt 

			--SELECT @old_objekt, @new_objekt
			--SELECT objekt, TRIM(REPLACE(','+objekt+',',',ZILFRE,',',AruKru,')) FROM projektid WHERE kood = 'Z01151'

			IF EXISTS ( SELECT RENOVATED FROM in_projektid WHERE kood = @webid AND RENOVATED IS NOT NULL )
			BEGIN
				DELETE FROM yld_data WHERE klass = 'PROJEKT' AND kood = 'RENOVATED' AND kaart = @webid
					AND EXISTS ( SELECT RENOVATED FROM in_projektid WHERE kood = @webid AND RENOVATED IS NOT NULL )
				INSERT INTO yld_data ( klass, kood, kaart, sisu )
					SELECT 'PROJEKT', 'RENOVATED', @webid, RENOVATED FROM in_projektid WHERE kood = @webid AND RENOVATED IS NOT NULL
					AND NOT EXISTS ( SELECT kaart FROM yld_data WITH(nolock) WHERE klass = 'PROJEKT' AND kood = 'RENOVATED' AND kaart = @webid )
				SET @step = 'PROJECT IN:1:'+ISNULL(@old_objekt,'')+'='+ISNULL(@new_objekt,'')

				INSERT INTO #results 
				VALUES (@webid, 'PROJECT', 0, 'OK', 'RENOVATED changed in project '+CONVERT(NVARCHAR,@webid)) 
			END

			--preserve state 
			INSERT INTO #projektid SELECT * FROM projektid WITH(nolock) WHERE kood = @webid

			IF (ISNULL(@old_objekt,'') != ISNULL(@new_objekt,'') AND ISNULL(@new_objekt,'') != '') 
			BEGIN
				UPDATE lepingud
				SET ts = GETDATE()
				WHERE number IN (SELECT number FROM lepingud_read WHERE ISNULL(projekt,'') = @webid AND ISNULL(r_aeg2,'') = '')

				IF (@old_objekt IS NULL)
				BEGIN 
			
					UPDATE projektid 
					SET objekt = LEFT(isnull(objekt, '') + ',' + @new_objekt,255) 
					WHERE kood = @webid

				END 
				ELSE 
				BEGIN 

					UPDATE projektid 
					SET objekt = TRIM(REPLACE(','+objekt+',',','+@old_objekt+',',','+@new_objekt+','))
					WHERE kood = @webid

					UPDATE projektid 
					SET objekt = REPLACE(objekt,',,',',')
					WHERE kood = @webid
				
					UPDATE projektid 
					SET objekt = LEFT(objekt,LEN(objekt)-1)
					WHERE kood = @webid

					UPDATE projektid 
					SET objekt = RIGHT(objekt,LEN(objekt)-1)
					WHERE kood = @webid
				
				END

				INSERT INTO #results 
				VALUES (@webid, 'PROJECT', 0, 'OK', 'changed from object '+ISNULL(@old_objekt,'')+' to object '+ISNULL(@new_objekt,'')) 

			END
			ELSE 
			BEGIN 
				IF (ISNULL(@new_objekt,'') != '') AND NOT EXISTS ( SELECT number FROM #results WHERE number = @webid )
				BEGIN 

					INSERT INTO #results 
					VALUES (@webid, 'PROJECT', 0, 'ERR', 'there is no object changes in project '+CONVERT(NVARCHAR,@webid)) 

				END

			END

			SET @step = 'PROJECT IN:2:'+ISNULL(@old_objekt2,'')+'='+ISNULL(@new_objekt2,'')

			IF (ISNULL(@old_objekt2,'') != ISNULL(@new_objekt2,'') AND ISNULL(@new_objekt2,'') != '') 
			BEGIN 
				UPDATE lepingud
				SET ts = GETDATE()
				WHERE number IN (SELECT number FROM lepingud_read WHERE ISNULL(projekt,'') = @webid AND ISNULL(r_aeg2,'') = '')

				IF (@old_objekt2 IS NULL)
				BEGIN 

					UPDATE projektid 
					SET objekt = isnull(objekt, '') + ',' + @new_objekt2 
					WHERE kood = @webid

				END 
				ELSE 
				BEGIN 

					UPDATE projektid 
					SET objekt = TRIM(REPLACE(','+objekt+',',','+@old_objekt2+',',','+@new_objekt2+','))
					WHERE kood = @webid

					UPDATE projektid 
					SET objekt = REPLACE(objekt,',,',',')
					WHERE kood = @webid
				
					UPDATE projektid 
					SET objekt = LEFT(objekt,LEN(objekt)-1)
					WHERE kood = @webid

					UPDATE projektid 
					SET objekt = RIGHT(objekt,LEN(objekt)-1)
					WHERE kood = @webid
				
				END

				INSERT INTO #results 
				VALUES (@webid, 'PROJECT', 0, 'OK', 'changed from object '+ISNULL(@old_objekt2,'')+' to object '+ISNULL(@new_objekt2,'')) 

			END
			ELSE 
			BEGIN 
				IF (ISNULL(@new_objekt2,'') != '') AND NOT EXISTS ( SELECT number FROM #results WHERE number = @webid )
				BEGIN 

					INSERT INTO #results 
					VALUES (@webid, 'PROJECT', 0, 'ERR', 'there is no object changes in project '+CONVERT(NVARCHAR,@webid)) 

				END

			END

			IF (@manager IS NOT NULL) 
			BEGIN 

				UPDATE projektid SET juht = ISNULL(@manager,juht) WHERE kood = @webid

				INSERT INTO #results 
				VALUES (@webid, 'PROJECT', 0, 'OK', 'manager changed in project '+CONVERT(NVARCHAR,@webid)) 

			END

			EXEC sys.sp_set_session_context @KEY = N'sec_user', @VALUE = 'XML'
			EXEC dbo.create_history @before_save='#projektid', @after_save='projektid', @history='projektid_history', @kood=@webid;
			TRUNCATE TABLE #projektid

		END

		/*IF (ISNULL(@old_objekt2,'') = ISNULL(@new_objekt2,'') AND (ISNULL(@old_objekt,'') = ISNULL(@new_objekt,'') ) )
		BEGIN
			INSERT INTO #results 
			VALUES (@webid, 'PROJECT', 1, 'There is nothing to change from object '+ISNULL(@old_objekt,'')+' to object '+ISNULL(@new_objekt,''), 'Projects') 
		END*/

		FETCH next FROM tellimused INTO @webid, @objekt, @new_objekt2, @manager 
    END 

    CLOSE tellimused 

    DEALLOCATE tellimused 

    DELETE FROM [dbo].[in_projektid] 
    WHERE  x = @key 


	-- event 510157
	SET @step = 'EVENT IN:in_events2'

	--here?
	UPDATE in_events2 
    SET    xkey = @key 
    WHERE  xkey IS NULL

	--EVENT IN 2
	DECLARE tellimused CURSOR FOR 
	SELECT k_kood   
	FROM   in_events2 
	WHERE  xkey = @key 
	AND ISNULL(k_kood,'') != ''


    OPEN tellimused 

    FETCH next FROM tellimused INTO @webid 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        SELECT @id_exist = kood  
        FROM   events WITH(nolock) 
        WHERE  ISNULL(k_kood,'') = @webid 

        IF ISNULL(@id_exist,0) = 0 
		BEGIN
			
			INSERT INTO events ( k_kood, k_tyyp, k_nimi, k_aadress, k_telefon, k_email, k_kontakt, artikkel, tyyp, projekt, objekt, aeg1, aeg2, status, kasutaja, tegija, sisu, markus, feedback, cu, aeg_loodud, sn, teade_jah, teade_aeg, teade_jah_k, teade_aeg_k )
			SELECT TOP 1 k_kood, k_tyyp, k_nimi, k_aadress, k_telefon, k_email, k_kontakt, artikkel, ISNULL(tyyp,'MONEY_CALCULATION'), ISNULL(projekt,(SELECT TOP 1 projekt FROM events E WITH(nolock) WHERE E.tyyp IN ('NRI', 'J2000', 'COFEMAR', 'CF7000', 'CASH_COLLECTION') AND E.sn = in_events2.sn ORDER BY E.aeg1 DESC))
			, objekt, ISNULL(aeg1,GETDATE()), aeg2, status, ISNULL(kasutaja,'XML'), tegija,null, null, null,/* sisu, markus, feedback,*/ 'XML', GETDATE(), sn, null, null, null, null 
			FROM in_events2 WITH(nolock) 
			WHERE xkey = @key 
			AND k_kood = @webid
			
			SELECT @id_exist = kood  
			FROM   events WITH(nolock) 
			WHERE  k_kood = @webid

			IF ((SELECT ISNULL(projekt,'') FROM events WITH(nolock) WHERE kood = @id_exist) = '')
			BEGIN
				UPDATE events
				SET status = 'DEMESIO'
				WHERE kood = @id_exist
			END
			
			INSERT INTO yld_data (kood, klass, kaart, sisu)
			SELECT 'CALC_SUM', 'EVENT', CONVERT(NVARCHAR,@id_exist), (SELECT TOP 1 sisu FROM in_events2 WITH(nolock) WHERE xkey = @key AND k_kood = @webid)
			
			INSERT INTO yld_data (kood, klass, kaart, sisu)
			SELECT 'CALC_NOTES', 'EVENT', CONVERT(NVARCHAR,@id_exist), (SELECT TOP 1 markus FROM in_events2 WITH(nolock) WHERE xkey = @key AND k_kood = @webid)
			
			INSERT INTO yld_data (kood, klass, kaart, sisu)
			SELECT 'CALC_TOKEN', 'EVENT', CONVERT(NVARCHAR,@id_exist), (SELECT TOP 1 feedback FROM in_events2 WITH(nolock) WHERE xkey = @key AND k_kood = @webid)

			INSERT INTO #results 
			VALUES (@webid, 'EVENT', 0, CONVERT(NVARCHAR,@id_exist), 'Events')


			--EXEC Int_hooldus_klient_chash '1/1/2019', '1/1/2019', @id_exist, '0', 'NE'
			DELETE FROM #output
			INSERT INTO #output
			exec after_save_klient 'event', @id_exist

		END 
		ELSE 
		BEGIN 

			INSERT INTO #results 
			VALUES (@webid, 'EVENT', 1, 'Duplicate', 'Events') 

		END
		
		FETCH next FROM tellimused INTO @webid 
	END

    CLOSE tellimused 
    DEALLOCATE tellimused 

	DELETE FROM in_events2 WHERE xkey = @key 


	SET @step = 'EVENT IN:in_events3'
	--EVENT IN
	--SELECT * FROM in_events3
	--SELECT * FROM in_events2
	UPDATE in_events3 
    SET    xkey = @key 
    WHERE  xkey IS NULL 

	DECLARE tellimused CURSOR FOR 
	SELECT k_kood   
	FROM   in_events3 
	WHERE  xkey = @key 
	AND ISNULL(k_kood,'') != ''

    OPEN tellimused 

    FETCH next FROM tellimused INTO @webid 
    WHILE @@FETCH_STATUS = 0 
    BEGIN 
        SELECT @id_exist = kood  
        FROM   events WITH(nolock) 
        WHERE  ISNULL(k_kood,'') = @webid 

        IF ISNULL(@id_exist,0) = 0 
		BEGIN
			
			INSERT INTO events ( k_kood, k_tyyp, k_nimi, k_aadress, k_telefon, k_email, k_kontakt, artikkel, tyyp, projekt, objekt, aeg1, aeg2, status, kasutaja, tegija, sisu, markus, feedback, cu, aeg_loodud, sn, teade_jah, teade_aeg, teade_jah_k, teade_aeg_k )
			SELECT TOP 1 k_kood, k_tyyp, k_nimi, k_aadress, k_telefon, k_email, k_kontakt, artikkel, ISNULL(tyyp,'CASH_COLLECTION'), projekt, objekt, ISNULL(aeg1,GETDATE()), aeg2, ISNULL(status,'NAUJAS'), ISNULL(kasutaja,'XML')
				, ISNULL( tegija, ( SELECT TOP 1 kasutajad.kood FROM kasutajad WITH(nolock) WHERE kasutajad.objekt = in_events3.objekt ) ) , sisu, markus, feedback, 'XML', GETDATE(), sn, null, null, null, null
			FROM in_events3 WITH(nolock) 
			WHERE xkey = @key 
			AND k_kood = @webid

			SELECT @id_exist = kood  
			FROM   events WITH(nolock) 
			WHERE  k_kood = @webid 
			
			EXEC Int_hooldus_klient_chash '1/1/2019', '1/1/2019', @id_exist, '0', 'NE'

			INSERT INTO #results 
			VALUES (@webid, 'EVENT', 0, CONVERT(NVARCHAR,@id_exist), 'Events')

		END 
		ELSE 
		BEGIN 

			INSERT INTO #results 
			VALUES (@webid, 'EVENT', 1, 'Duplicate', 'Events') 

		END
		
		FETCH next FROM tellimused INTO @webid 
	END

    CLOSE tellimused 
    DEALLOCATE tellimused 

	DELETE FROM in_events3 WHERE xkey = @key



--Change customer contact data start
declare tellimused insensitive cursor for select kood, tyyp, kontakt_kood from in_customer_changes where x=@key
open tellimused
FETCH NEXT FROM tellimused INTO @incwebid, @inctype, @incctype
WHILE @@FETCH_STATUS = 0
BEGIN
set @number=(select count(kood) from kliendid where kood=@incwebid)
		if @number=0
			begin
				insert into #results values (@incwebid, 'Kliendid', 0, 'CUSTOMER_NOT_EXIST',NULL)
			END
		ELSE
			BEGIN
				if @inctype = '1'
					begin
						insert kliendid_ajalugu (kood, aeg, field, enne, nyyd, cu)
						select @incwebid, getdate(), 'kontakt', (select kontakt from kliendid where kood=@incwebid), nimi,'WEB' from in_customer_changes where kood=@incwebid and tyyp=@inctype
						union
						select @incwebid, getdate(), 'email', (select email from kliendid where kood=@incwebid),email, 'WEB' from in_customer_changes where kood=@incwebid and tyyp=@inctype
						union 
						select @incwebid, getdate(), 'telefon', (select telefon from kliendid where kood=@incwebid) ,telefon,'WEB' from in_customer_changes where kood=@incwebid and tyyp=@inctype
				
						update kliendid 
								set 
									kliendid.kontakt=z.nimi,
									kliendid.email=z.email,
									kliendid.telefon=z.telefon
						from (select * from in_customer_changes where kood=@incwebid and tyyp=@inctype)z
						where kliendid.kood=z.kood
						insert into #results values (@incwebid, 'CHANGED_CUSTOMER_CONTACT', 1, 'OK',NULL)
					end
				if @inctype = '2'
					begin
						insert kliendid_ajalugu (kood, aeg, field, enne, nyyd, cu)
						select @incwebid, getdate(), 'lahaadress1', (select lahaadress1 from kliendid where kood=@incwebid), lahetusaadress1,'WEB' from in_customer_changes where kood=@incwebid and tyyp=@inctype
						union
						select @incwebid, getdate(), 'lahaadress2', (select lahaadress2 from kliendid where kood=@incwebid), lahetusaadress2,'WEB' from in_customer_changes where kood=@incwebid and tyyp=@inctype
						union
						select @incwebid, getdate(), 'lahaadress3', (select lahaadress3 from kliendid where kood=@incwebid), lahetusaadress3,'WEB' from in_customer_changes where kood=@incwebid and tyyp=@inctype
				
						update kliendid 
								set 
									kliendid.lahaadress1=z.lahetusaadress1,
									kliendid.lahaadress2=z.lahetusaadress2,
									kliendid.lahaadress3=z.lahetusaadress3
						from (select * from in_customer_changes where kood=@incwebid)z
						where kliendid.kood=z.kood
						insert into #results values (@incwebid, 'CHANGED_DEL_ADDRESS', 1, 'OK',NULL)
					end
				if @inctype = '3'
					begin
						insert kontaktisikud (kood, kl_kood, kl_nimi, nimi, telefon, email, cu, ts)
						select (select max(kood)+1 from kontaktisikud with(nolock)),@incwebid, (select nimi from kliendid where kood=@incwebid), nimi, telefon, email, 'WEB', getdate() from in_customer_changes  where kood=@incwebid and tyyp=@inctype
						insert into #results values (convert(nvarchar(max),(select max(kood) from kontaktisikud where kl_kood=@incwebid)), 'Add '+(select nimi from kontaktisikud where kood=(select max(kood) from kontaktisikud where kl_kood=@incwebid))+' contact', 1, 'OK',NULL)
					end
				if @inctype = '4'
					begin
						insert kontaktisikud_ajalugu (rn, aeg, kood, enne, nyyd)
						select @incctype, getdate(), 'kontakt', (select nimi from kontaktisikud where kood=@incctype), nimi from in_customer_changes where kood=@incwebid and tyyp=@inctype
						union
						select @incctype, getdate(), 'email', (select email from kontaktisikud where kood=@incctype), email from in_customer_changes where kood=@incwebid and tyyp=@inctype
						union
						select @incctype, getdate(), 'telefon', (select telefon from kontaktisikud where kood=@incctype), telefon from in_customer_changes where kood=@incwebid and tyyp=@inctype

						update kontaktisikud
							set 
								kontaktisikud.nimi=z.nimi,
								kontaktisikud.email=z.email,
								kontaktisikud.telefon=z.telefon
						from (select * from in_customer_changes where kood=@incwebid and tyyp=@inctype and kontakt_kood=@incctype)z
						where kontaktisikud.kood=@incctype
						insert into #results values (@incctype, 'CHANGED_CONTACT', 1, 'OK',NULL)
					end
				if @inctype = '5'
					begin
						insert kontaktisikud_ajalugu (rn, aeg, kood, enne, nyyd)
						select @incctype, getdate(), 'closed', (select suletud from kontaktisikud where kood=@incctype), nimi from in_customer_changes where kood=@incwebid and tyyp=@inctype

						update kontaktisikud
							set 
								suletud='1'
						where kontaktisikud.kood=@incctype
						insert into #results values (@incctype, 'UNACTIVED', 1, 'OK',NULL)
					end
			end	
		FETCH NEXT FROM tellimused INTO @incwebid, @inctype, @incctype
END
CLOSE tellimused
DEALLOCATE tellimused
--select * from kontaktisikud_ajalugu where kood=86
DELETE FROM in_customer_changes
WHERE x = @key
--Change customer contact data end
--Change customer contact data start
declare tellimused insensitive cursor for select webshop_order from in_webshop_orders where x=@key
open tellimused
FETCH NEXT FROM tellimused INTO @webid
WHILE @@FETCH_STATUS = 0
BEGIN
set @number=(select count(number) from tell_tellimused where kliendi_tellimus=@webid)
/*
		if @number >= 1
			begin
				insert into #results values (@webid, 'Sales Orders', 0, 'Order already exist',NULL)
			END
		ELSE
			BEGIN
			if(select count(kood) from kliendid where kood=(select klient from in_webshop_orders where webshop_order=@webid and x=@key))=0
				begin
					insert kliendid (kood, nimi
					, objekt, lahaadress1, asumaa, arvetasub, myyja, regnr, kmregnr, kmkood
					, telefon,email, ts,loodud_cu,cu,loodud_ts)
					select klient,klient_nimi
					, 'RIGA,OTHER,PRIVATE,IRREGULAR', 'ND', 'LV', klient, 'NOREPLY', 'ND', 'ND', 1 
					,telefon, email, getdate(), 'XML','XML',getdate() from in_webshop_orders where webshop_order=@webid and x=@key
				end

*/
set @webCustomerRegNo = ''
	select @webCustomerRegNo = reg_no from in_webshop_orders where webshop_order=@webid and x=@key
		if (select count(number) from tell_tellimused where kliendi_tellimus=@webid) >= 1
			begin
				insert into #results values (@webid, 'Sales Orders', 0, 'Order already exist',NULL)
			END
		ELSE
			BEGIN
		if isnull(@webCustomerRegNo,'')=''
		begin
		/*
			if(select count(kood) from kliendid where kood=(select klient from in_webshop_orders where webshop_order=@webid and x=@key))=0
				begin
					insert kliendid (kood, nimi
					, objekt, lahaadress1, asumaa, arvetasub, myyja, regnr, kmregnr, kmkood
					, telefon,email, ts,loodud_cu,cu,loodud_ts)
					select klient,klient_nimi
					, 'RIGA,OTHER,PRIVATE,IRREGULAR', 'ND', 'LV', klient, 'NOREPLY', 'ND', 'ND', 1 
					,telefon, email, getdate(), 'XML','XML',getdate() from in_webshop_orders where webshop_order=@webid and x=@key
				end
		*/
		if(select count(kood) from kliendid where kood=(select klient from in_webshop_orders where webshop_order=@webid and x=@key))=0
				begin
				declare @custCountWiththisEmail  int
				select  @custCountWiththisEmail = count(kood) from kliendid where kood=arvetasub and email=(select email from in_webshop_orders where webshop_order=@webid and x=@key)
				--select @custCountWiththisEmail
				if @custCountWiththisEmail = 0
				begin
					--select '1'
					insert kliendid (kood, nimi
					, objekt, lahaadress1, asumaa, arvetasub, myyja, regnr, kmregnr, telefon,email, ts,loodud_cu,cu,loodud_ts)
					select klient,klient_nimi
					, 'RIGA,OTHER,PRIVATE,IRREGULAR', 'ND', 'LV', klient, email, 'ND', 'ND',telefon, email, getdate(), 'XML','XML',getdate() from in_webshop_orders where webshop_order=@webid and x=@key
					end
				end
				if @custCountWiththisEmail >= 1
				begin
					--select '2'
					declare @custEmail nvarchar(max)
					select @custemail = email from in_webshop_orders where webshop_order=@webid and x=@key
					--select @custEmail
					update in_webshop_orders set klient=(select top 1 kood from kliendid where kood=arvetasub and email=@custemail), klient_tellija=(select top 1 kood from kliendid where kood=arvetasub and email=@custEmail) where x=@key and webshop_order=@webid
					update in_webshop_orders set klient_nimi=(select top 1 nimi from kliendid where kood=klient), klient_tellija_nimi=(select top 1 nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid
				end
				--select * from in_webshop_orders
		END

		if isnull(@webCustomerRegNo,'')!=''
		BEGIN
			declare @FactoringCustomerCount int
			select @FactoringCustomerCount =  count(kood) from kliendid where regnr=@webCustomerRegNo and isnull(arvetasub,kood)=kood
			Declare @CompRegisterRecordCount int
			select  @CompRegisterRecordCount = count(kood) from okr_master.dbo.master_firms where maa='lv'and kood=@webCustomerRegNo
			if(@FactoringCustomerCount = 0)
				BEGIN
				
					if(@CompRegisterRecordCount=1)
					begin
						insert kliendid (
											kood,
											nimi,
											objekt,
											lahaadress1,
											asumaa,
											arvetasub,
											myyja,
											regnr,
											kmregnr,
											kmkood,
											telefon,
											email,
											ts,
											loodud_cu,
											cu,
											loodud_ts
										)
							select 
										'EBLV_'+convert(nvarchar(max),kood),
										replace(nimi,'"',''),
										'RIGA,OTHER,PRIVATE,IRREGULAR',
										'',
										maa,
										'EBLV_'+convert(nvarchar(max),kood),
										'',
										kood,
										(select vat from in_webshop_orders where x=@key and webshop_order=@webid),
										'',
										'',
										(select email from in_webshop_orders where x=@key and webshop_order=@webid),
										getdate(),
										'XML',
										'XML',
										getdate()
							from okr_master.dbo.master_firms where maa='lv' and kood=@webCustomerRegNo

							select @bodytxt = N'Directo ir izveidots jauns klients, balstoties uz Uzņēmumu reģistra datiem<br/><br/>
							<b>Uzņēmuma nosaukums:</b>'+(select nimi from kliendid where regnr=@webCustomerRegNo)+'<br />'+
							N'<b>Reģistrācijas numurs:</b>'+convert(nvarchar(max),@webCustomerRegNo)+'<br />'+
							N'<b>E-pasts:</b>'+isnull((select email from in_webshop_orders where x=@key and webshop_order=@webid),'')+'<br /><br />'+
							N'<b>Directo kods:</b>'+'EBLV_'+convert(nvarchar(max),@webCustomerRegNo)

							update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo) where x=@key and webshop_order=@webid
							update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid

					end
					if(@CompRegisterRecordCount=0)
					begin
				select  @ebCustomerFactoringCount = count(kood) from kliendid where substring(kood,1,4)='EBLV' and regnr=@webCustomerRegNo
				if @ebCustomerFactoringCount = 1
					begin
						update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV' and arvetasub=kood), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV'  and arvetasub=kood) where x=@key and webshop_order=@webid
						update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid
					end
					if @ebCustomerFactoringCount = 0
						begin
							insert kliendid (
												kood,
												nimi,
												objekt,
												lahaadress1,
												asumaa,
												arvetasub,
												myyja,
												regnr,
												kmregnr,
												kmkood,
												telefon,
												email,
												ts,
												loodud_cu,
												cu,
												loodud_ts
											)
							select 
											'EBLV_'+convert(nvarchar(max),reg_no),
											replace(klient_nimi,'"',''),
											'RIGA,OTHER,PRIVATE,IRREGULAR',
											'',
											'LV',
											'EBLV_'+convert(nvarchar(max),reg_no),
											'',
											reg_no,
											vat,
											'',
											'',
											email,
											getdate(),
											'XML',
											'XML',
											getdate()
								from in_webshop_orders where x=@key and webshop_order=@webid
									
								select @bodytxt = N'Directo ir izveidots jauns klients, balstoties uz klienta ievadītajiem datiem<br/><br/>
							<b>Uzņēmuma nosaukums:</b>'+(select nimi from kliendid where regnr=@webCustomerRegNo)+'<br />'+
							N'<b>Reģistrācijas numurs:</b>'+convert(nvarchar(max),@webCustomerRegNo)+'<br />'+
							N'<b>E-pasts:</b>'+isnull((select email from in_webshop_orders where x=@key and webshop_order=@webid),'')+'<br /><br />'+
							N'<b>Directo kods:</b>'+'EBLV_'+convert(nvarchar(max),@webCustomerRegNo)


								update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo) where x=@key and webshop_order=@webid
								update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid
						end
					end
				end
		if (@FactoringCustomerCount = 1)
			BEGIN
				update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo and isnull(arvetasub,kood)=kood), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo and isnull(arvetasub,kood)=kood) where x=@key and webshop_order=@webid
				update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid
			END
		if (@FactoringCustomerCount >= 2)
			BEGIN

				select  @ebCustomerFactoringCount = count(kood) from kliendid where substring(kood,1,4)='EBLV' and regnr=@webCustomerRegNo
				if @ebCustomerFactoringCount = 1
					begin
						update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV' and arvetasub=kood), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV'  and arvetasub=kood) where x=@key and webshop_order=@webid
						update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid
					end
			
			if @ebCustomerFactoringCount = 0
			begin
						if(@CompRegisterRecordCount=1)
					begin
						insert kliendid (
											kood,
											nimi,
											objekt,
											lahaadress1,
											asumaa,
											arvetasub,
											myyja,
											regnr,
											kmregnr,
											kmkood,
											telefon,
											email,
											ts,
											loodud_cu,
											cu,
											loodud_ts
										)
							select 
										'EBLV_'+convert(nvarchar(max),kood),
										replace(nimi,'"',''),
										'RIGA,OTHER,PRIVATE,IRREGULAR',
										'',
										maa,
										'EBLV_'+convert(nvarchar(max),kood),
										'',
										kood,
										(select vat from in_webshop_orders where x=@key and webshop_order=@webid),
										'',
										'',
										(select email from in_webshop_orders where x=@key and webshop_order=@webid),
										getdate(),
										'XML',
										'XML',
										getdate()
							from okr_master.dbo.master_firms where maa='lv' and kood=@webCustomerRegNo

							select @bodytxt = N'Directo ir izveidots jauns klients, balstoties uz Uzņēmumu reģistra datiem<br/><br/>
							<b>Uzņēmuma nosaukums:</b>'+(select nimi from kliendid where regnr=@webCustomerRegNo)+'<br />'+
							N'<b>Reģistrācijas numurs:</b>'+convert(nvarchar(max),@webCustomerRegNo)+'<br />'+
							N'<b>E-pasts:</b>'+isnull((select email from in_webshop_orders where x=@key and webshop_order=@webid),'')+'<br /><br />'+
							N'<b>Directo kods:</b>'+'EBLV_'+convert(nvarchar(max),@webCustomerRegNo)

						update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV' and arvetasub=kood), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV' and arvetasub=kood) where x=@key and webshop_order=@webid
						update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid

					end
					if(@CompRegisterRecordCount=0)
					begin
							insert kliendid (
												kood,
												nimi,
												objekt,
												lahaadress1,
												asumaa,
												arvetasub,
												myyja,
												regnr,
												kmregnr,
												kmkood,
												telefon,
												email,
												ts,
												loodud_cu,
												cu,
												loodud_ts
											)
							select 
											'EBLV_'+convert(nvarchar(max),reg_no),
											replace(klient_nimi,'"',''),
											'RIGA,OTHER,PRIVATE,IRREGULAR',
											'',
											'LV',
											'EBLV_'+convert(nvarchar(max),reg_no),
											'',
											reg_no,
											vat,
											'',
											telefon,
											email,
											getdate(),
											'XML',
											'XML',
											getdate()
								from in_webshop_orders where x=@key and webshop_order=@webid
						
						select @bodytxt = N'Directo ir izveidots jauns klients, balstoties uz klienta ievadītajiem datiem<br/><br/>
							<b>Uzņēmuma nosaukums:</b>'+(select nimi from kliendid where regnr=@webCustomerRegNo)+'<br />'+
							N'<b>Reģistrācijas numurs:</b>'+convert(nvarchar(max),@webCustomerRegNo)+'<br />'+
							N'<b>E-pasts:</b>'+isnull((select email from in_webshop_orders where x=@key and webshop_order=@webid),'')+'<br /><br />'+
							N'<b>Directo kods:</b>'+'EBLV_'+convert(nvarchar(max),@webCustomerRegNo)



						update in_webshop_orders set klient=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV' and arvetasub=kood), klient_tellija=(select kood from kliendid where regnr=@webCustomerRegNo and substring(kood,1,4)='EBLV' and arvetasub=kood) where x=@key and webshop_order=@webid
						update in_webshop_orders set klient_nimi=(select nimi from kliendid where kood=klient), klient_tellija_nimi=(select nimi from kliendid where kood=klient_tellija) where x=@key and webshop_order=@webid
						
					end
			end	
		
		end
		end
		


			set @ag=getdate()
			set @series = (select top 1 param1 from tr_params with(nolock) where tyyp = 'xml' and kood = 'series' and param2 = 'sales_order')

				 EXEC dbo.get_dok_number @moodul='tellimus', @seeria=@series, @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
				 update tell_tellimused 
				 set
												kliendi_tellimus=@webid
											,	aeg=z.aeg1
											,	tingimus=z.pay_term
											,	objekt=z.objekt
											,	klient_nimi_lahetusel=z.nimi_lahetusel
											,	lahetusaadress1=z.lahaadress1
											,	lahetusaadress2=z.lahaadress2
											,	lahetusaadress3=z.lahaadress3
											,	klient_kood=z.klient
											,	klient_nimi=z.nimi
											,	arvetasub=z.arvetasub
											,	aadress1=z.aadress1
											,	aadress2=z.aadress2
											,	aadress3=z.aadress3
											,	lahetustingimus=z.del_method
											,	kommentaar=z.kommentaar
											,	lahetusaeg=z.del_aeg
											,	esindaja=isnull((select kontakt from kliendid with(nolock) where kood = z.klient), z.kontakt)
											,	telefon=isnull((select nullif(telefon,'') from kliendid with(nolock) where kood = z.klient), z.telefon)
											,	ladu=z.ladu
											,	kurssbv1=z.kurssbv1
											,	valuuta=z.valuuta
											,	hinnakiri=z.hinnakiri
											,	myyja = ( SELECT TOP 1 myyja FROM kliendid WITH(nolock) WHERE kood = z.klient )
											,	field57 = ( SELECT TOP 1 email FROM kliendid WITH(nolock) WHERE kood = z.klient )
										from 
										( select 
							@number as number
						,	@webid as webid
						,	aeg1
						,	isnull(isnull(pay_term,(select tingimus from kliendid where kood=klient_tellija)),(select tingimus from kliendid where kood=klient)) pay_term
						,	isnull(isnull(objekt,(select objekt from kliendid where kood=klient_tellija)),(select objekt from kliendid where kood=klient)) objekt
						,	isnull((select nimi_lahetusel from kliendid where kood=klient_tellija),(select nimi_lahetusel from kliendid where kood=klient)) nimi_lahetusel
						,	isnull((select lahaadress1 from kliendid where kood=klient_tellija),(select lahaadress1 from kliendid where kood=klient)) lahaadress1
						,	isnull((select lahaadress2 from kliendid where kood=klient_tellija),(select lahaadress2 from kliendid where kood=klient)) lahaadress2
						,	isnull((select lahaadress3 from kliendid where kood=klient_tellija),(select lahaadress3 from kliendid where kood=klient)) lahaadress3
						,	klient_tellija as klient
						,	(select nimi from kliendid where kood=klient_tellija) nimi
						,	klient as arvetasub
						,	isnull((select aadress1 from kliendid where kood=klient_tellija),(select aadress1 from kliendid where kood=klient)) aadress1
						,	isnull((select aadress2 from kliendid where kood=klient_tellija),(select aadress2 from kliendid where kood=klient)) aadress2
						,	isnull((select aadress3 from kliendid where kood=klient_tellija),(select aadress3 from kliendid where kood=klient)) aadress3
						,	del_method
						,	kommentaar
						,	del_aeg
						,	kontakt
						,	telefon
						,	ladu
						,	1 as kurssbv1
						,	'EUR' as valuuta
						,	iif(isnull((select hinnakiri from kliendid where kood=klient_tellija),'')!='',(select hinnakiri from kliendid where kood=klient_tellija),(select hinnakiri from kliendid where kood=klient)) as hinnakiri
				from in_webshop_orders with(nolock) where webshop_order=@webid) z
				where tell_tellimused.number=@number
				

select @maa = isnull(maa,0) from kliendid where kood=(select klient_kood from tell_tellimused where number=@number)
				insert tell_tellimused_read (
													number
												,	rn
												,	rv
												,	artikkel
												,	kogus
												,	nimetus
												,	yhikuhind
												,	summa
												,	Field8
												,	konto
												,	rv_summa
												,	yhik
												,	rsum
												,	tkkm
												,	myygikate
												,	kmkood
											)
				select
							@number
						,	rn
						,	rn
						,	artikkel
						,	kogus
						,	isnull(artikkel_nimi,(select nimi from artiklid where kood=artikkel))
						,	hind
						,	cast(cast(hind * kogus as decimal(15,4)) - (cast(hind * kogus as decimal(15,4)) * isnull(pross / 100,0)) as decimal(15,4))
						,	isnull(pross,0)
						,	case
									when (@maa = 0)
										then 
											isnull((select konto_myyk from artiklid where kood=artikkel),(select myyk_eestis from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
									when (@maa = 1)
										then 
											isnull((select konto_myyk_EU from artiklid where kood=artikkel),(select myyk_eu from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
							end
						,	cast(cast(hind * kogus as decimal(15,4)) - (cast(hind * kogus as decimal(15,4)) * isnull(pross / 100,0)) as decimal(15,4))
						,	isnull((select yhik from artiklid where kood=artikkel),'gab')
						,	0
						,	0
						,	cast(cast(hind * kogus as decimal(15,4)) - (cast(hind * kogus as decimal(15,4)) * isnull(pross / 100,0)) as decimal(15,4))
						,		case
									when (@maa = 0)
										then 
											isnull((select KMkood from artiklid where kood=artikkel),(select kmk_eesti from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
									when (@maa = 1)
										then 
											isnull((select KMkood_EU from artiklid where kood=artikkel),(select kmk_eu from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
							end
			from in_webshop_orders_read where webshop_order=@webid and artikkel!='DEPOSIT'

			update tell_tellimused_read 
				set 
						rsum=z.rsum
				from (select number, rn, cast(myygikate + (myygikate * ((select case when (ilmakm=0) then 100 else ilmakm end from fin_kmkoodid where kood=kmkood) /100)) as decimal(15,4)) as rsum from tell_tellimused_read where number=@number) z
				where tell_tellimused_read.number=z.number and  tell_tellimused_read.rn=z.rn
				exec after_save_klient 'tellimus', @number, NULL, NULL, NULL
				insert into #results values (@webid, 'Sales Orders', 1, 'Order create',convert(nvarchar(max),@number))
		update tell_tellimused_read 
			set tkkm = z.tkkm
			from (select number, rn, cast(rsum - myygikate as decimal(15,4)) as tkkm from tell_tellimused_read where number=@number) z
			where tell_tellimused_read.number=z.number and tell_tellimused_read.rn=z.rn


			exec dbo.tellimus_komplekteeri @number

			update tell_tellimused
				set 
						summa = (select sum(summa) from tell_tellimused_read where number=@number)
					,	kmkokku = (select sum(tkkm) from tell_tellimused_read where number=@number)
					,	summakokku = (select sum(rsum) from tell_tellimused_read where number=@number)
					,	ettemaks = iif(tingimus='PREPAYMENT',(select sum(rsum) from tell_tellimused_read where number=@number),0)
				where number=@number
			end	


		/* Created (payment for webcard or webbank orders) by Renārs Abeļūns 18.09.2020 */
			
			DECLARE @laek_summa DECIMAL(19,2)
			DECLARE @payterm nvarchar(32)
			SELECT @laek_summa = summakokku, @payterm = tingimus from tell_tellimused with(nolock) where number = @number
			IF
				(@payterm = 'WEBBANK' or @payterm = 'WEBCARD')
					AND
				@laek_summa > 0 
					AND 
				NOT EXISTS ( SELECT number FROM mr_laekumised WITH(nolock) WHERE number = @number) 
			BEGIN
				INSERT INTO mr_laekumised ( number, aeg, tasumisviis, cu, ts, seletus, objekt, arvuti )
				SELECT @number, aeg, tingimus, 'XML' , @ts, 'Ettemaks ' + CONVERT( nvarchar, @number ), NULL, NULL
				FROM tell_tellimused WITH(nolock) WHERE number = @number
				INSERT INTO mr_laekumised_read
					( number, ettemaks, klient_kood, klient_nimi, valuuta_p, kurss_p, summa_p, tasuti, objektid, kmk )
				SELECT 
					number, number, klient_kood, klient_nimi, 'EUR',1, @laek_summa, @laek_summa, NULL
					, ( SELECT TOP 1 param1 FROM tr_params WITH(nolock) WHERE tyyp = 'XML' AND kood = 'ORDER_paymentvatcode' ) kmk
				FROM tell_tellimused WITH(nolock) WHERE number = @number
				INSERT INTO #results VALUES (@webid, 'Receipts', 1, 'Receipt Created', convert(nvarchar(max),@number) )
				/* confirm document */
				IF EXISTS ( SELECT TOP 1 param1 FROM tr_params WHERE tyyp = 'XML' AND kood = 'ORDER_confirmpayment' AND param1 = '1' )
				BEGIN
					DELETE FROM #output
					INSERT INTO #output
						EXEC kinnita_LAEK @number,1  -- The '1' at the end is for payment confirmation as it is a bit field 
					IF EXISTS ( SELECT response FROM #output WHERE response = 'Kinnitatud' )
						--INSERT INTO #results VALUES ( @@identity, 'PAYMENT', 30, 'Confirmed', 'Orders',  @webid )
						INSERT INTO #results VALUES (@webid, 'Receipts', 1, 'Receipt Confirmed', convert(nvarchar(max),@number) )
					ELSE 	
						--INSERT INTO #results VALUES ( @@identity, 'PAYMENT', 39, 'Payment not confirmed: ' + ( SELECT TOP 1 msg FROM #output ), 'Orders',@webid )
						INSERT INTO #results VALUES (@webid, 'Receipts', 1, 'Receipt Not Confirmed', convert(nvarchar(max),@number) )
				END
			END

			/* end (payment for webcard or webbank orders)  */
			if (isnull(@bodytxt,'')!='')
				begin
					EXEC msdb.dbo.sp_send_dbmail
						@body_format='HTML',
							@recipients = @mail_to,
							@body = @bodytxt,
							@subject = 'Klienta izveide no EB pasutijuma'
				end

		FETCH NEXT FROM tellimused INTO @webid
END
CLOSE tellimused
DEALLOCATE tellimused
delete from in_webshop_orders_read where webshop_order in (select webshop_order from in_webshop_orders WHERE x = @key)
DELETE FROM in_webshop_orders
WHERE x = @key

--Change customer contact data end




SET @step = 'CUSTOMER IN'
UPDATE in_kliendid SET x=@key where x is null

declare tellimused insensitive cursor for select kood from in_kliendid where x=@key
open tellimused
FETCH NEXT FROM tellimused INTO @webid
WHILE @@FETCH_STATUS = 0
BEGIN
	if exists(SELECT * FROM kliendid WITH(nolock) where kood = @webid)
	BEGIN
		insert into #results values (@webid, 'Customer IN', 1, 'Customer already exists',NULL)
	END
	ELSE 
	BEGIN
		INSERT INTO kliendid (kood, nimi, email, telefon, objekt, lahaadress1, asumaa, arvetasub, myyja, regnr
							,kmregnr)
		SELECT TOP 1 
			kood, nimi, email, telefon
			, 'RIGA,OTHER,PRIVATE,IRREGULAR'
			, 'ND'
			, 'LV'
			, @webid
			, 'NOREPLY'
			, 'ND'
			, 'ND'
		FROM in_kliendid WHERE kood = @webid and x=@key

		insert into #results values (@webid, 'Customer IN', 0, 'Customer created',NULL)
	END
	FETCH NEXT FROM tellimused INTO @webid
END
CLOSE tellimused
DEALLOCATE tellimused
DELETE from in_kliendid where x=@key







--nayax xml in start

declare nayax_in cursor for select projekt, aeg, sequence from in_nayax_transaction_header where x=@x2
	open nayax_in
	FETCH NEXT FROM nayax_in INTO @projekt, @aeg, @sequence
	WHILE @@FETCH_STATUS = 0
		BEGIN
			if(select count(number) from mr_arved where projekt=@projekt and cast(aeg as date) = cast(@aeg as date) and lisa_field1='test_nayax' and lisa_field2=isnull(@sequence,'2'))>=1
				begin
					insert into #results values (@projekt, 'Nayax', 0, 'DUPLICATE',NULL)
				end
			if(select count(number) from mr_arved where projekt=@projekt and cast(aeg as date) = cast(@aeg as date) and lisa_field1='test_nayax' and lisa_field2=isnull(@sequence,'2'))=0
				begin
					EXEC dbo.get_dok_number @moodul='arve', @seeria='NAYAX', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
					update mr_arved
					set 
						projekt=@projekt,
						lisa_field1='test_nayax',
						lisa_field2=isnull(@sequence,'2'),
						klient_kood=iif(isnull((select klient_kood from projektid where kood=@projekt),'')='','24749',(select klient_kood from projektid where kood=@projekt)),
						klient_nimi=(select nimi from kliendid where kood=iif(isnull((select klient_kood from projektid where kood=@projekt),'')='','24749',(select klient_kood from projektid where kood=@projekt))),
						aeg=(case when ((isnull(@sequence,'2'))='1') then ((select dateadd(mi,-10,(dateadd(ss,-1,dateadd(dd,1,convert(datetime,@aeg))))))) else (select dateadd(ss,-1,dateadd(dd,1,convert(datetime,@aeg)))) end),
						field5=1,
						kinnitatud=0,
						kommentaar='AUT',
						MUUDALADU='1',
						ladu='vendingo',
						myyja = isnull(( SELECT TOP 1 myyja FROM kliendid WITH(nolock) WHERE kood = iif(isnull((select klient_kood from projektid where kood=@projekt),'')='','24749',(select klient_kood from projektid where kood=@projekt))),'1057')
					where number=@number

					update mr_arved
					set maa = (select maa from kliendid with(nolock) where kood = mr_arved.klient_kood)
					where number = @number
	
				insert mr_arved_read (
											number,
											artikkel,
											summa,
											kogus,
											hind,
											KMK,
											projekt,
											konto,
											rn,
											rv
										)
					select
							@number,
							iif(isnull((select kood from artiklid where kood=productId),'')='','999999',productId) artikkel,
							cast(isnull(lsum,0) AS DECIMAL(15,4)) summa,
							isnull(qty,0) as kogus,
							cast(isnull(price,0) AS DECIMAL(15,4)) summa,
							ISNULL((SELECT kmkood FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM mr_arved WITH(nolock) WHERE number = @number)), dbo.get_art_kmkood(iif(isnull(productId,'')='','999999',productId), (SELECT maa FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM mr_arved WITH(nolock) WHERE number = @number)))),
							@projekt projekt,
							dbo.get_art_konto(iif(isnull(productId,'')='','999999',productId), (SELECT maa FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM mr_arved WITH(nolock) WHERE number = @number))),
							rn,
							rn
					from in_nayax_transaction_line a where projekt=@projekt and sequence=@sequence and x=@x2

					update mr_arved_read set seletus=(select nimi from artiklid where kood=mr_arved_read.artikkel) where number=@number

					EXEC [dbo].[mr_arve_komplekteeri] @number

					update mr_arved_read set 
							kmk = ISNULL((SELECT kmkood FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM mr_arved WITH(nolock) WHERE number = @number)), dbo.get_art_kmkood(iif(isnull(artikkel,'')='','999999',artikkel), (SELECT maa FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM mr_arved WITH(nolock) WHERE number = @number)))),
							konto = dbo.get_art_konto(iif(isnull(artikkel,'')='','999999',artikkel), (SELECT maa FROM kliendid WITH(nolock) WHERE kood = (SELECT klient_kood FROM mr_arved WITH(nolock) WHERE number = @number)))
					where number=@number

					update mr_arved_read set
					summa = iif(summa <> 0,CAST((summa - (kogus * ISNULL((SELECT 0.1 FROM artiklid WITH(nolock) WHERE kood = artikkel AND retsept LIKE 'DEPOSIT%'), 0))) / (1 + (SELECT ilmakm / 100 FROM fin_KMkoodid WHERE kood = kmk)) AS DECIMAL(15,4)),0)
					,hind = iif(hind <> 0,CAST((hind - ISNULL((SELECT 0.1 FROM artiklid WITH(nolock) WHERE kood = artikkel AND retsept LIKE 'DEPOSIT%'), 0)) / (1 + (SELECT ilmakm / 100 FROM fin_KMkoodid WHERE kood = kmk)) AS DECIMAL(15,4)),0)
					where number=@number

					--exec dbo.arvuta_arve 2603775
declare @kinnit2 table
					(resp nvarchar(max))

select 
			@number as number,
			CASE 
					WHEN (payment='EcommerceCreditCard') THEN (N'CARD')
					WHEN (payment='CASH') THEN (N'S')
					WHEN (payment='Monyx App') THEN (N'CARD')
					WHEN (payment='Credit Card') THEN (N'CARD')
					WHEN (payment='Prepaid Credit') THEN (N'PREPAID')
					WHEN (payment='Pay Pal') THEN (N'CARD')
					WHEN (payment='Monyx Balance') THEN (N'CARD')
			END AS payment,
			psum
into #posPay from in_nayax_transaction_payments where projekt=@projekt and sequence=@sequence and x=@x2

insert mr_arved_raha (arvenr, tingimus,raha)
select @number, payment, sum(psum) from #posPay where number=@number group by payment

drop table #posPay
insert into #results values (@projekt, 'Nayax', 1, 'OK',convert(nvarchar(max),@number))				
				end
			FETCH NEXT FROM nayax_in INTO @projekt, @aeg, @sequence
		END --fetch end
CLOSE nayax_in
DEALLOCATE nayax_in
--drop table #output

declare mappost_in cursor for select appkey, mappostId, orderIndex, MachineNumber, operator, Region  from in_mappost_stock_order where x=@x2
	open mappost_in
	FETCH NEXT FROM mappost_in INTO @appkey, @mapId, @orderIndex, @projekt, @kasutaja, @region
	WHILE @@FETCH_STATUS = 0
		BEGIN
if(select count(number) from ladu_tellimused where lisa_field1=convert(nvarchar(max),@mapId))>=1
begin
insert into #results values (convert(nvarchar(max),@mapId), 'SOrder', 0, 'DUPLICATE',NULL)
end
else
begin
			declare mappost_in2 cursor for select distinct ProductGroup, mappostId  from in_mappost_stock_order_lines where x=@x2 and mappostId=@mapId group by  ProductGroup, mappostId
	open mappost_in2
	FETCH NEXT FROM mappost_in2 INTO @prodGroup, @mapId2
	WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC dbo.get_dok_number @moodul='ladu_tellimus', @seeria='DOC', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
			update ladu_tellimused set
							projekti =@projekt,
							laost = (case when (@projekt = (select top 1 kaart from yld_data where @projekt = kaart and kood = '1CKODSS'and klass = 'PROJEKT')) then (@sorderFromStock) else ('CAVENDING')end), -- iif(isnull(@region,'Riga')='Riga','Gal',iif(@region='Liep',' LIEPAJA','Daugav')),
							lattu = @sorderToStock,
							aeg = (select top 1 UpdatedDate from in_mappost_stock_order where x=@x2 and appkey=@appkey and MachineNumber=@projekt and mappostId=@mapId),
							kasutaja=isnull((select sisu from yld_data where klass='objekt' and kaart=@kasutaja),@kasutaja),
							cu='XML',
							ts=getdate(),
							kl_kood=(select klient_kood from projektid where kood=@projekt),
							kl_nimi=(select nimi from kliendid where kood=(select klient_kood from projektid where kood=@projekt)),
							lisa_field1=@mapId2,
							lisa_field2=@orderIndex,
							lisa_field5=@prodGroup+iif((select count(ProductGroup) from in_mappost_stock_order_lines  where x=@x2 and mappostId=@mapId and ProductGroup='Meal')>=1,'+W','+'),
							sisekommentaar=@prodGroup+iif((select count(ProductGroup) from in_mappost_stock_order_lines  where x=@x2 and mappostId=@mapId and ProductGroup='Meal')>=1,'+W','+')
		where number=@number
	--	SELECT TOP 10 * FROM ladu_tellimused_read
	/*
	select @number NUMBER, DirectoItem ITEM, PAR PAR, (select nimi from artiklid where kood=(select top 1 kaart from yld_data where klass='artikkel' and kood='htype1' and sisu=NayaxProductId)) ITEMC, CAST(SelectionID AS DECIMAL(15,4))SelectionID INTO #T10000001 from in_mappost_stock_order_lines where x=@x2 and mappostId=@mapId2 and ProductGroup=@prodGroup ORDER BY CONVERT(INT,SelectionID)
		insert ladu_tellimused_read (number, artikkel, kogus, nimetus, KOMMENTAAR, rn, rv)
		SELECT *,row_number() OVER(ORDER BY selectionID, NUMBER, ITEM, PAR, ITEMC ASC),row_number() OVER(ORDER BY selectionID, NUMBER, ITEM, PAR, ITEMC ASC) FROM #T10000001 GROUP BY SelectionID, NUMBER, ITEM, PAR, ITEMC
	*/

/*
	select @number NUMBER, DirectoItem ITEM, PAR PAR, (select nimi from artiklid where kood=DirectoItem) ITEMC, CAST(SelectionID AS DECIMAL(15,4))SelectionID INTO #T10000001 from in_mappost_stock_order_lines where x=@x2 and mappostId=@mapId2 and ProductGroup=@prodGroup ORDER BY CONVERT(INT,SelectionID)
		insert ladu_tellimused_read (number, artikkel, kogus, nimetus, KOMMENTAAR)
		SELECT * FROM #T10000001 GROUP BY SelectionID, NUMBER, ITEM, PAR, ITEMC
	*/

	-- Create a temporary table with specific data from in_mappost_stock_order_lines
select @number NUMBER, row_number() OVER (ORDER BY DirectoItem,PAR,SelectionID) rn, DirectoItem ITEM, PAR PAR, (select nimi
	from artiklid
	where kood=DirectoItem) ITEMC, CAST(SelectionID AS DECIMAL(15,4))SelectionID INTO #T10000001 from in_mappost_stock_order_lines where x=@x2 and mappostId=@mapId2 and ProductGroup=@prodGroup ORDER BY CONVERT(INT,SelectionID)
--added rn,rv
insert ladu_tellimused_read
	(number,rn,rv, artikkel, kogus, nimetus, KOMMENTAAR)
SELECT number, rn, rn, ITEM, par, ITEMC, SelectionID
FROM #T10000001
GROUP BY SelectionID, NUMBER, ITEM, PAR, ITEMC,rn

		DROP TABLE #T10000001

		exec dbo.ladu_tellimus_komplekteeri @number
		
		insert into #results values (convert(nvarchar(max),@number), 'SOrder', 1, 'OK',convert(nvarchar(max),@mapid2))
		FETCH NEXT FROM mappost_in2 INTO   @prodGroup, @mapId2
		END --fetch end
		CLOSE mappost_in2
		DEALLOCATE mappost_in2
		
		--select * from ladu_tellimused
		end
			FETCH NEXT FROM mappost_in INTO @appkey, @mapId, @orderIndex, @projekt, @kasutaja,@region

		END --fetch end
CLOSE mappost_in
DEALLOCATE mappost_in

delete from in_mappost_stock_order where x=@x2
delete from in_mappost_stock_order_lines where x=@x2

declare mappost_in cursor for select appkey, date,datecov from in_otell_tellimused where x=@x2 group by date,appkey, datecov
	open mappost_in
	FETCH NEXT FROM mappost_in INTO @appkey, @aegDoc, @aegDoc2
	WHILE @@FETCH_STATUS = 0
		BEGIN
		
			if(select count(number) from otell_tellimused where kommentaar='Mappost Purchase ORDER' and aeg=@aegDoc2)>=1
				begin
					insert into #results values (convert(nvarchar(max),''), 'POrder', 0, 'DUPLICATE',NULL)
				end
			else
				begin
					declare mappost_in2 cursor for select hankija from in_otell_tellimused_read where x=@x2 group by hankija
						open mappost_in2
						FETCH NEXT FROM mappost_in2 INTO @hankija
						WHILE @@FETCH_STATUS = 0
							begin
								EXEC dbo.get_dok_number @moodul='otellimus', @seeria='DOC', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
								update otell_tellimused
										set 
											hankija_kood=@hankija
											,ladu = (case when (@hankija = '1190') then (@sorderFromStock) else ('GAL') end)
											,hankija_nimi=(select nimi from hankijad where kood=@hankija)
											,tingimus=(select tingimus from hankijad where kood=@hankija)
											,pangakonto=(select pangakonto from hankijad where kood=@hankija)
											,aeg=@aegDoc2
											,kommentaar='Mappost Purchase ORDER'
								where number=@number
								

								select ROW_NUMBER() OVER(ORDER BY hankija, artikkel ASC) AS RowNr, artikkel, sum(kogus) kogus into #t1 from in_otell_tellimused_read where x=@x2 and hankija=@hankija group by hankija, artikkel

								
								--select @maa = maa from hankijad where kood=@hankija
								insert otell_tellimused_read (number, rn, kood, kogus, nimi, yhikuhind,soetushind, summa,kmkood,yhik)
								select @number, RowNr, artikkel, kogus, (select nimi from artiklid where kood=artikkel), (select ostuhind from artiklid where kood=artikkel),(select ostuhind from artiklid where kood=artikkel), (select ostuhind from artiklid where kood=artikkel)* kogus,(select kmkood from hankijad where kood=@hankija),(select yhik from artiklid where kood=artikkel) from #t1
								
								drop table #t1
								insert into #results values (convert(nvarchar(max),@hankija), 'POrder', 0, 'OK',@number)
								FETCH NEXT FROM mappost_in2 INTO @hankija

							end
						--select * from hankijad where kood='50480'
						--select top 10 * from otell_tellimused_read where number=1000360
						CLOSE mappost_in2
DEALLOCATE mappost_in2
					--EXEC dbo.get_dok_number @moodul='otellimus', @seeria='DOC', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
						
					--update otell_tellimused
						--set hankija
						--declare
	--					insert into #results values (convert(nvarchar(max),@number), 'POrder', 0, 'OK',NULL)
				end
FETCH NEXT FROM mappost_in INTO @appkey, @aegDoc,@aegDoc2
		END

CLOSE mappost_in
DEALLOCATE mappost_in



--delete from in_nayax_transaction where x=@x2
delete from in_nayax_transaction_header where x=@x2
delete from in_nayax_transaction_line where x=@x2
delete from in_nayax_transaction_payments where x=@x2
--update ladu_sissetulekud set tekst=sisekommentaar where sisekommentaar like N'%trūkstošie%'
--nayax xml in end

----------- MAPPOST STOCK MOVEMENTS ---------------
declare stock_movement CURSOR for select number,appkey from in_mappost_liikumised_stock_movement where x=@key
	open stock_movement
		FETCH NEXT FROM stock_movement INTO @mapId,@appkey
			WHILE @@FETCH_STATUS = 0
			BEGIN
			if(@appkey=@xmlcore_key)
				begin
					if((select count(number) from ladu_liikumised where lisa_field5=convert(nvarchar(255),@mapId))=0)
                
						begin
							EXEC dbo.get_dok_number @moodul='liikumine', @seeria='DOC', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
							
							update ladu_liikumised
								set 
									lisa_field5=convert(nvarchar(max),@mapId),
									aeg=z.aeg,
									laost=z.laost,
									lattu=z.lattu,
									projekt=z.projekti,
									projekti=z.projektist,
									ts=getdate(),
									sisekommentaar=convert(nvarchar(255),z.number)+','+ isnull(z.additional,''),
									kl_kood=(select top 1 klient_kood from projektid where kood = z.projektist or kood = z.projekti  ),
									kl_nimi=(select top 1 klient_nimi from projektid where kood = z.projektist  or kood = z.projekti  )
								from
									(select * from in_mappost_liikumised_stock_movement where number=@mapid)z
								where ladu_liikumised.number=@number

								insert into ladu_liikumised_read (number,artikkel,kogus,kogus_saadud,nimetus,rn, rv)
								select 
								@number,
								artikkel,
								kogus,
								kogus,
								(SELECT top 1 nimi FROM artiklid WHERE kood = in_mappost_liikumised_read_stock_movement.artikkel),
								row_number() OVER (ORDER BY artikkel),
			 					row_number() OVER (ORDER BY artikkel) 
								
								from in_mappost_liikumised_read_stock_movement  where number=@mapId

								EXEC [dbo].[ladu_liik_komplekteeri] @number
									
		select @maxrn = max(rn)+1 from ladu_liikumised_read where number=@number
		insert ladu_liikumised_read (number, artikkel, kogus, kogus_saadud, kommentaar, nimetus, rn, rv)
		select @number,'DEPOSIT',sum(kogus),sum(kogus_saadud),CONVERT(NVARCHAR(510),sum(kogus_saadud)),(select nimi from artiklid where kood='DEPOSIT'),@maxrn,@maxrn from ladu_liikumised_read where number=@number and artikkel='DEPOSIT' group by number,artikkel

		update ladu_liikumised_read set kogus=0, kogus_saadud=0  where number=@number and artikkel='DEPOSIT' and rn!=@maxrn
	
								--EXEC Hooldus_vaba 'liikumine', @number 
								--EXEC dbo.liikumine_sn_split @number
					
					--select * from ladu_liikumised_read where number=1297039
								--select * from ladu_liikumised_read_laoid where number=1297039
								EXEC dbo.after_save @moodul = 'liikumine', @number = @number
								--EXEC dbo.renu

									INSERT #output 
									EXEC dbo.Kinnita_liik @number -- Confirms movement
									delete from #output
									
									-- insert confirm_ladu_liikumised (response)
									-- select * from #output

									-- update confirm_ladu_liikumised set number=@number where number is null
	
								insert into #results values (@mapid, 'Mappost Stock movement', 1, 'OK',convert(nvarchar(255),@number))

								if isnull((select kinnitatud from ladu_liikumised where number=@number),0)=0
								begin
									exec dbo.liikumine_laoid_split @number
									INSERT #output 
									EXEC dbo.Kinnita_liik @number -- Confirms movement
									delete from #output
								end
							end
					else
							begin
				insert into #results values (@mapid, 'Mappost Stock movement', 2, 'DUPLICATE','1')

					
							end
				end
					else
			begin

			  insert into #results values (@mapid, 'Mappost Stock movement', 0, 'INCORRECT APPKEY','1')

			end
					FETCH NEXT FROM stock_movement INTO  @mapId,@appkey
		END --fetch end
CLOSE stock_movement
DEALLOCATE stock_movement

delete in_mappost_liikumised_read_stock_movement where number in (select number from in_mappost_liikumised_stock_movement where x = @key)
delete in_mappost_liikumised_stock_movement where x = @key




-------------------------------------------

----------- MAPPOST STOCK TAKINGS ---------------
/*
declare stock_takings CURSOR for select number,appkey from in_mappost_takings where x=@key
	open stock_takings
		FETCH NEXT FROM stock_takings INTO @mapId,@appkey
			WHILE @@FETCH_STATUS = 0
			BEGIN
			if(@appkey=@xmlcore_key)
				begin
					if((select count(number) from ladu_inventuurid where number=convert(nvarchar(255),@mapid))=0)
						begin
							EXEC dbo.get_dok_number @moodul='inventuur', @seeria='DOC', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
							
							update ladu_inventuurid
								set 
									aeg=dateadd(ss,1,z.aeg),
									ladu=z.stock,
									projekt=z.projekt,
									ts=getdate()
								from
									(select * from in_mappost_takings where number=@mapid)z
								where ladu_inventuurid.number=@number

								insert ladu_inventuurid_read (number,artikkel,kogus,kirjeldus)
								select 
								@number,
								artikkel,
								kogus,
								(SELECT top 1 nimi FROM artiklid WHERE kood = in_mappost_takings_read.artikkel)
								
								from in_mappost_takings_read  where number=@mapId

								insert into #results values (@number, 'Mappost Takings', 1, 'OK',convert(nvarchar(255),@mapid))
						end
				else
						begin
			insert into #results values (@mapid, 'Mappost Takings', 2, 'DUPLICATE','1')

				
						end
			end
				else
			begin

			  insert into #results values (@mapid, 'Mappost Takings', 0, 'INCORRECT APPKEY','1')

			end
					FETCH NEXT FROM stock_takings INTO  @mapId,@appkey
		END --fetch end
CLOSE stock_takings
DEALLOCATE stock_takings

delete in_mappost_takings_read where number in (select number from in_mappost_takings where x = @key)
delete in_mappost_takings where x = @key
*/
---mappst stock takings new ------

declare @account nvarchar(32)
select @account = param1 from tr_params where tyyp='xml' and kood='mappost_inv_stake' and param2='account'
declare stock_takings CURSOR for  SELECT number, appkey
      FROM   in_mappost_liikumised 
      WHERE  x = @key and isnull(laost,'')!='' and isnull(lattu,'')='' and isnull(projektist,'')='' and isnull(projekti,'')=''
	open stock_takings
		FETCH NEXT FROM stock_takings INTO @mapId,@appkey
			WHILE @@FETCH_STATUS = 0
			BEGIN
			if(@appkey=@xmlcore_key)
				begin

					if((select count(number) from ladu_inventuurid where seletus='Mappost-'+convert(nvarchar(255),@mapid))=0)
						begin
							EXEC dbo.get_dok_number @moodul='inventuur', @seeria='NAYAX2', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
							
							update ladu_inventuurid
								set 
									aeg=z.aeg,
									ladu=z.laost,
									ts=getdate(),
									laoid_split=1,
									kett=@number,
									seletus='Mappost-'+convert(nvarchar(255),@mapid),
									konto=@account
								from
									(select * from in_mappost_liikumised where number=@mapid and x=@key)z
								where ladu_inventuurid.number=@number

								insert ladu_inventuurid_read (number,artikkel,kogus,kirjeldus)
								select 
								@number,
								artikkel,
								kogus,
								(SELECT top 1 nimi FROM artiklid WHERE kood = in_mappost_liikumised_read.artikkel)
								
							from in_mappost_liikumised_read  where number=@mapId and x=@key

						
								
								exec dbo.inv_laoid_split_kett @number
								

select @stock = isnull((select ladu from ladu_inventuurid where number=@number),'')
								if isnull((select sisu from yld_data where kood='AUTOCONFIRM' and klass='ladu' and kaart=@stock),'Yes')='Yes' and (select count(*) from ladu_liikumised where laost=@stock and isnull(kinnitatud,0)=0)=0 and (select count(*) from ladu_liikumised where lattu=@stock and isnull(kinnitatud,0)=0)=0
									begin
										insert #output
										exec dbo.kinnita_LINV @number
										delete from #output
									end
								--select * from information_schema.routines where routine_name like '%kinn%'
								declare @confirmed nvarchar(255)
								select @confirmed = iif(isnull(kinnitatud,0)=0,'Not Conformed','Confirmed') from ladu_inventuurid where number=@number
								insert into #results values (@mapid, 'Mappost Takings', 1, 'OK',convert(nvarchar(255),@confirmed))
						end
				else
						begin
			insert into #results values (@mapid, 'Mappost Takings', 2, 'DUPLICATE','1')

				
						end
			end
				else
			begin

			  insert into #results values (@mapid, 'Mappost Takings', 0, 'INCORRECT APPKEY','1')

			end
					FETCH NEXT FROM stock_takings INTO  @mapId,@appkey
		END --fetch end
CLOSE stock_takings
DEALLOCATE stock_takings


----------- MAPPOST STOCK ORDERS MERCH  ---------------
declare stock_movement CURSOR for select number,appkey from in_mappost_stock_order_merch where x=@key
	open stock_movement
		FETCH NEXT FROM stock_movement INTO @mapId,@appkey
			WHILE @@FETCH_STATUS = 0
			BEGIN
			if(@appkey=@xmlcore_key)
				begin
					if((select count(number) from ladu_tellimused where lisa_field1=convert(nvarchar(255),@mapId))=0)
                    
						begin
							EXEC dbo.get_dok_number @moodul='ladu_tellimus', @seeria='DOC', @NUMBER = NULL, @cu='XML', @aeg=@ag, @keel = 'default', @num =@number OUTPUT, @err = @err OUTPUT
							
							update ladu_tellimused
								set 
									aeg=z.aeg,
									laost=z.laost,
									lattu=z.lattu,
									ts=getdate(),
									sisekommentaar=convert(nvarchar(255),z.number)+','+ isnull(z.additional,''),
									lisa_field1=convert(nvarchar(255),z.number)

								from
									(select * from in_mappost_stock_order_merch where number=@mapid)z
								where ladu_tellimused.number=@number

								insert ladu_tellimused_read (number,artikkel,kogus,nimetus,r_laost)
								select 
								@number,
								artikkel,
								kogus,
								(SELECT top 1 nimi FROM artiklid WHERE kood = in_mappost_stock_order_merch_read.artikkel),
								ladu
								
								from in_mappost_stock_order_merch_read  where number=@mapId
								INSERT
									#output 

									EXEC Kinnita_liik @number -- Confirms movement
									
								DELETE FROM
									#output 

								insert into #results values (@mapid, 'Mappost Stock POrder Merch', 1, 'OK',convert(nvarchar(255),@number))
						end
				else
						begin
			insert into #results values (@mapid, 'Mappost Stock POrder Merch', 2, 'DUPLICATE','1')

				
						end
			end
				else
			begin

			  insert into #results values (@mapid, 'Mappost Stock POrder Merch', 0, 'INCORRECT APPKEY','1')

			end
					FETCH NEXT FROM stock_movement INTO  @mapId,@appkey
		END --fetch end
CLOSE stock_movement
DEALLOCATE stock_movement

--delete in_mappost_stock_order_merch_read where number in (select number from in_mappost_stock_order_merch where x = @key)
--delete in_mappost_stock_order_merch where x = @key


-------------------------------------------



--CPFORMULA (Customer Price Formula change)
--IF (@callid = 'cpformula') --@callid is not passed to procedure
--BEGIN
SET @step = 'Customer price formula change'

UPDATE in_customer_priceformula SET x=@key WHERE x IS NULL

declare cpformula insensitive cursor for select DISTINCT kood from in_customer_priceformula where x=@key
open cpformula
FETCH NEXT FROM cpformula INTO @webid
		
WHILE @@FETCH_STATUS = 0
BEGIN 
	IF NOT EXISTS(SELECT * FROM kliendid WITH(nolock) WHERE kood = @webid)
	BEGIN
		INSERT INTO #results VALUES (@webid, 'Cpformula', 1, 'Customer does not exist', NULL)
	END
	ELSE
	BEGIN
		UPDATE kliendid
		SET hinnakiri = (SELECT TOP 1 hinnakiri FROM in_customer_priceformula WHERE x=@key AND kood = @webid)
		WHERE kood = @webid

		INSERT INTO #results VALUES (@webid, 'Cpformula', 0, 'Updated', NULL)
	END

	FETCH NEXT FROM cpformula INTO @webid
END
CLOSE cpformula
DEALLOCATE cpformula	

--CLEANUP
DELETE FROM in_customer_priceformula WHERE kood IN (SELECT kood FROM in_customer_priceformula WHERE x=@key)
--END


-------------------------------------------



if (select COUNT(number) from #results)=0
begin
insert into #results values (NULL, 'GENERAL', 99, 'No processable data found','General error')
end
/*

	insert into xml_core_sisse_log_xml
select GETDATE()
,(select
(
(select result as "@Type", descr as "@Desc", number as "@docid", tyyp as "@doctype", submittype as "@submit"
 from #results for xml path ('Result'),type)
 ) for xml path ('Results'),type)
, @key
,@callid

select
(
(select result as "@Type", descr as "@Desc", number as "@docid", tyyp as "@doctype", submittype as "@submit"
 from #results for xml path ('Result'),type)
 ) for xml path ('Results'),type */



select @result1=
(select result as "@Type", descr as "@Desc", number as "@docid", tyyp as "@doctype", submittype as "@submit"
 from #results for xml path ('Result'))

select @result2='<?xml version="1.0" encoding="UTF-8"?><Results>'+CONVERT(nvarchar(max),@result1)+'</Results>'

select @result2


drop table #output
drop table #results
drop table #proc_results
DROP TABLE IF EXISTS #projektid

GO
