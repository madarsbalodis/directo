SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER      PROCEDURE [dbo].[xml_core_SISSE_eshop] AS
DECLARE @klient_kood bigint, @kood bigint, @nimitmp nvarchar(255),@addrtmp nvarchar(255),@konttmp nvarchar(255), @koodid varchar(1000)
declare @ladu nvarchar(32), @seeria nvarchar(32), @objekt nvarchar(32), @s1 int, @s2 int, @webid nvarchar(32), @webtype nvarchar(32)
declare @number int, @maa int, @kmk nvarchar(32), @x int, @kinnitatud int
DECLARE @myyja nvarchar(32), @aeg datetime
declare @key nvarchar(32), @appkey nvarchar(64), @appkey_setting nvarchar(64)
declare @result1 xml, @result2 nvarchar(max)
declare @artikkel nvarchar(32), @id_exist int
declare @kl_kood nvarchar(32), @nimi nvarchar(255), @kustuta int, @valem nvarchar(32)

set @key = CONVERT(nvarchar,getdate())

update in_tell_tellimused set x=@key where x is null
update in_artiklid set x=@key where x is null

set @koodid=''

select @appkey_setting=setting from settings where ID='xmlcore_key'

create table #results
(number nvarchar(32), tyyp nvarchar(32), result int, descr nvarchar(255), submittype nvarchar(32))

--vastuvotmine, artiklid
declare tellimused cursor for select kood, appkey from in_artiklid where x=@key
open tellimused

FETCH NEXT FROM tellimused INTO @webid, @appkey
WHILE @@FETCH_STATUS = 0
BEGIN
	if @appkey=@appkey_setting
	begin
		if ISNULL(@webid,'')=''
		begin
			insert into #results values (@webid, 'ITEM', 3, 'Missing key values','Items')
		end
		else
		begin
			if exists (select kood from artiklid WITH (nolock) where kood=@webid)
			begin

				--saadetud lisavaljad uuesti
				delete from yld_data where klass='ARTIKKEL' and kaart=@webid and kood in
				(select kood from in_artiklid_lisa where kaart=@webid)
				
				insert into yld_data
				(kood, klass, kaart, sisu, param)
				select kood, 'ARTIKKEL',kaart,sisu,param 
				from in_artiklid_lisa
				where kaart=@webid

				insert into #results values (@webid, 'ITEM', 0, 'Update','Items')
			end
			else
			begin
				insert into #results values (@webid, 'ITEM', 1, 'Not found','Items')
			end
		END
	end
	else
	begin
			insert into #results values (@webid, 'ITEM', 2, 'Incorrect AppKey','Items')
	end

	set @x=@x+1
	FETCH NEXT FROM tellimused INTO @webid, @appkey
END
CLOSE tellimused
DEALLOCATE tellimused

delete from in_artiklid_lisa where kaart in (select kood from in_artiklid where x=@key)
delete from in_artiklid where x=@key

--vastuvotmine, kogused
declare tellimused cursor for select number, appkey from in_tell_tellimused where x=@key
open tellimused
FETCH NEXT FROM tellimused INTO @webid, @appkey
WHILE @@FETCH_STATUS = 0
BEGIN

	if @appkey=@appkey_setting
	begin
		select @id_exist=count(*) from tell_tellimused where number=@webid
		if @id_exist=0
		BEGIN
			set @number=@webid
		
			select @maa = ISNULL( maa, 0 ) from kliendid WITH(nolock) where kood=(select klient_kood from in_tell_tellimused where number=@number)

			insert into tell_tellimused (number, myyja, aeg,  klient_kood, arvetasub,  tingimus, ladu, klient_nimi, lahetusviis
				,  kommentaar, valuuta, kurssbv1 
				 ,esindaja, telefon, aadress1, aadress2, aadress3
				 ,lahetusaadress1, lahetusaadress2, lahetusaadress3
				 ,klient_nimi_lahetusel
				 , ts, cu, field57, objekt, lahetusaeg
				 ,lisa_field1, lisa_field2, lisa_field3
				 , kliendi_tellimus
				 , maa
				 , asumaa
				 , hinnakiri
				 , staatus
				 , kmregnumber
				 , haldur
				 )
				SELECT @number
				, CASE WHEN ISNULL( lahetusviis, '' ) = 'B2B' THEN ( SELECT kliendid.myyja FROM kliendid WITH(nolock) WHERE kood = klient_kood )
						ELSE CASE WHEN EXISTS ( SELECT kood FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ) THEN 'WEB_FIN' ELSE 'WEB' END END
				--, CASE WHEN EXISTS ( SELECT kood FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ) THEN 'WEB_FIN' ELSE 'WEB' END
				, aeg, klient_kood
				, ISNULL( ( SELECT TOP 1 arvetasub FROM kliendid WITH(nolock) WHERE kood = klient_kood ), arvetasub ) arvetasub
			--, ISNULL( ( SELECT TOP 1 arvetasub FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ), arvetasub ) arvetasub
				, isnull(tingimus,(select tingimus from kliendid where kood=klient_kood))
				, isnull(ladu,'CN')
			--, CASE WHEN ISNULL( lahetusviis, '' ) = 'B2B' THEN NULL ELSE isnull(ladu,'CN') END
				, isnull(klient_nimi,(select nimi from kliendid where kood=klient_kood))
				, lahetusviis
				,kommentaar, 'EUR', 1
				, isnull(esindaja,(select kontakt from kliendid where kood=klient_kood))
				, isnull(telefon,(select telefon from kliendid where kood=klient_kood))

				, aadress1, aadress2, aadress3
				, lahaadress1, lahaadress2, lahaadress3
				,klientnimi_lahetusel
				, GETDATE(), 'XML', email
				/*
				, ( SELECT kasutajad.objekt + CASE WHEN fo1.hierarhia IS NOT NULL THEN ',' + fo1.hierarhia ELSE NULL END + CASE WHEN fo2.hierarhia IS NOT NULL THEN ',' + fo2.hierarhia ELSE NULL END FROM 
				fin_objektid fo1 WITH(nolock), fin_objektid fo2 WITH(nolock), kasutajad WITH(nolock) WHERE fo2.kood = fo1.hierarhia AND fo1.kood = kasutajad.objekt AND kasutajad.kood = 'WEB' )
					+ ( SELECT CASE WHEN objekt IS NOT NULL THEN ',' + objekt ELSE NULL END FROM kliendid WITH(nolock) WHERE kood = klient_kood )
					objekt
				*/
				/*, ( SELECT kasutajad.objekt 
					+ CASE WHEN fo1.hierarhiad IS NOT NULL THEN ',' + fo1.hierarhiad ELSE NULL END
					 FROM 
					fin_objektid fo1 WITH(nolock), kasutajad WITH(nolock) WHERE fo1.kood = kasutajad.objekt AND kasutajad.kood = 
						( CASE WHEN EXISTS ( SELECT kood FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ) THEN 'WEB_FIN' ELSE 'WEB' END )
					)
					+ ( SELECT objekt FROM kliendid WITH(nolock) WHERE kood = klient_kood )
					objekt*/
				, CASE WHEN ISNULL( lahetusviis, '' ) = 'B2B' THEN ( SELECT kasutajad.objekt_hr FROM kliendid WITH(nolock) INNER JOIN kasutajad WITH(nolock) ON kasutajad.kood = kliendid.myyja WHERE kliendid.kood = klient_kood )
						ELSE
							(select objekt from kasutajad where kood=( CASE WHEN EXISTS ( SELECT kood FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ) THEN 'WEB_FIN' ELSE 'WEB' END ))
					+iif(isnull((SELECT objekt FROM kliendid WITH(nolock) WHERE kood = klient_kood),'')!='',','+(SELECT objekt FROM kliendid WITH(nolock) WHERE kood = klient_kood),'')
						END objekt

				--,(select objekt from kasutajad where kood=( CASE WHEN EXISTS ( SELECT kood FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ) THEN 'WEB_FIN' ELSE 'WEB' END ))
				--	+iif(isnull((SELECT objekt FROM kliendid WITH(nolock) WHERE kood = klient_kood),'')!='',','+(SELECT objekt FROM kliendid WITH(nolock) WHERE kood = klient_kood),'') objekt
				, lahetusaeg
				, lisa_field1, lisa_field2, lisa_field3
				, kliendi_tellimus
				, @maa
				, ( SELECT ISNULL( asumaa, 'EE' ) from kliendid where kood = klient_kood )	asumaa
				, ( SELECT hinnakiri FROM kliendid WITH(nolock) WHERE kood = klient_kood AND klass = 'WEB_FIN' ) hinnakiri
				, CASE WHEN lahetusviis = 'B2B' THEN 'Manual' ELSE NULL END staatus
				 , ISNULL( ( SELECT TOP 1 kmregnr FROM kliendid WITH(nolock) WHERE kood = klient_kood ), kmregnumber ) kmregnumber
				 , ( SELECT TOP 1 kliendihaldur FROM kliendid WITH(nolock) WHERE kood = klient_kood ) haldus
				FROM in_tell_tellimused where number=@number

			insert into tell_tellimused_read (number, artikkel, kogus, Field8, rsum, yhikuhind, tkkm, summa, ostuhind, nimetus, kmkood, r_kommentaar, rn, rv
			,lahetusaeg, variant, r_ladu
			,tekst1, tekst2, tekst3, tekst4
			, yhik
			)
			SELECT @number, artikkel, kogus
				, ale
				, rsum
				, hind
				, hind tkkm
				, kogus * hind -- kogus*isnull(hind,(select hind from artiklid where kood=artikkel))*(100-ISNULL(ale,0))/100
				, dbo.kesk_hind(artikkel,getdate())
				, isnull(nimetus,(select nimi from artiklid where kood=artikkel))
				, ISNULL( kmkood, dbo.get_art_kmkood( artikkel, @maa ) )
				,kommentaar, rn, rv, lahetusaeg, variant
				-- LADU vastavalt ladude prioriteetsusele, kus on kogus olemas
				, CASE WHEN EXISTS ( SELECT number FROM tell_tellimused WITH(nolock) WHERE number = @number AND ISNULL( lahetusviis, '' ) = 'B2B' ) THEN NULL ELSE
					(	SELECT TOP 1 yld_data.kaart
							--, yld_data.sisu, dbo.get_laoseis_vaba( 1, in_tell_tellimused_read.artikkel, yld_data.kaart, 0,0, 'laos,tellitud,liikout', GETDATE(), null ) seis
						FROM yld_data WITH(nolock)
						WHERE yld_data.klass = 'LADU' AND yld_data.kood = 'LADU_PRW'
							AND dbo.get_laoseis_vaba2( 1, in_tell_tellimused_read.artikkel, yld_data.kaart, 0, 0, 'laos,tellitud,liikout', GETDATE(), null, in_tell_tellimused_read.variant )
								>= ( SELECT sum( tr2.kogus ) FROM in_tell_tellimused_read tr2 WITH(nolock) WHERE tr2.number = @number AND ISNULL( tr2.variant, '' ) = ISNULL( in_tell_tellimused_read.variant, '' ) AND tr2.artikkel = in_tell_tellimused_read.artikkel )
						ORDER BY sisu ASC ) END r_ladu
				,tekst1, tekst2, tekst3, tekst4
				, 'GAB'
				FROM in_tell_tellimused_read where number=@number

/*
SELECT yld_data.kaart, yld_data.sisu
							--, yld_data.sisu, dbo.get_laoseis_vaba( 1, in_tell_tellimused_read.artikkel, yld_data.kaart, 0,0, 'laos,tellitud,liikout', GETDATE(), null ) seis
						FROM yld_data WITH(nolock)
						WHERE yld_data.klass = 'LADU' AND yld_data.kood = 'LADU_PRW'
							AND dbo.get_laoseis_vaba2( 1, '28472', yld_data.kaart, 0, 0, 'laos,tellitud,liikout', GETDATE(), null, NULL )
								>= ( SELECT sum( tr2.kogus ) FROM in_tell_tellimused_read tr2 WITH(nolock) WHERE tr2.number = 30000011 AND ISNULL( tr2.variant, '' ) = ISNULL( NULL, '' ) AND tr2.artikkel = '28472' )
						ORDER BY sisu ASC

select * from in_tell_tellimused_read
delete from in_tell_tellimused_read

select * from tell_tellimused where number = 30000011


			update tell_tellimused_read
			set kmkood=ISNULL((select kmkood from artiklid where kood=tell_tellimused_read.artikkel),(select kmk_eesti from artikliklassid where kood=(select klass from artiklid where kood=tell_tellimused_read.artikkel)))
			where number=@number and kmkood is null
			UPDATE tell_tellimused_read set tkkm = dbo.summaKM (yhikuhind,kmkood), rsum = dbo.summaKM(summa,kmkood)	where number=@number

			update tell_tellimused_read
			set konto=ISNULL((select konto_myyk from artiklid where kood=tell_tellimused_read.artikkel),(select myyk_eestis from artikliklassid where kood=(select klass from artiklid where kood=tell_tellimused_read.artikkel)))
			where number=@number and konto is null
*/

			if @maa = 0
			begin
				update tell_tellimused_read set
				konto=ISNULL((select konto_myyk from artiklid where kood=artikkel),(select myyk_eestis from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				and konto is null

				update tell_tellimused_read set
				kmkood = ISNULL((select KMkood from artiklid where kood=artikkel),(select kmk_eesti from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number 
				-- kmkood IS NULL 
			end
			if @maa = 2
			begin
				update tell_tellimused_read set
				konto=ISNULL((select konto_myyk_eksport from artiklid where kood=artikkel),(select myyk_eksport from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				and konto is null


				update tell_tellimused_read set
				kmkood = ISNULL((select KMkood_eksport from artiklid where kood=artikkel),(select kmk_eksport from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				-- and kmkood IS NULL 
			end
			if @maa = 1
			begin
				update tell_tellimused_read set
				konto=ISNULL((select konto_myyk_EU from artiklid where kood=artikkel),(select myyk_eu from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				and konto is null

				update tell_tellimused_read set
				kmkood = ISNULL((select KMkood_EU from artiklid where kood=artikkel),(select kmk_eu from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				-- and kmkood IS NULL 
			end
			if @maa = 3
			begin
				update tell_tellimused_read set
				konto=ISNULL((select konto_myyk_EU2 from artiklid where kood=artikkel),(select myyk_eu2 from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				and konto is null

				update tell_tellimused_read set
				kmkood = ISNULL((select KMkood_EU2 from artiklid where kood=artikkel),(select kmk_eu2 from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number 
				--and kmkood IS NULL 
			end
			if @maa = 4
			begin
				update tell_tellimused_read set
				konto=ISNULL((select konto_myyk_EU3 from artiklid where kood=artikkel),(select myyk_eu3 from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number
				and konto is null

				update tell_tellimused_read set
				kmkood = ISNULL((select KMkood_EU3 from artiklid where kood=artikkel),(select kmk_eu3 from artikliklassid where kood=(select klass from artiklid where kood=artikkel)))
				where number=@number 
				--and kmkood IS NULL 
			end

			SELECT @valem = NULLIF( hinnakiri, '' ) FROM kliendid WITH(nolock) WHERE kood = ( SELECT klient_kood FROM in_tell_tellimused WHERE number=@number ) AND klass = 'WEB_FIN'

			IF EXISTS ( SELECT lahetusviis FROM tell_tellimused WITH(nolock) WHERE lahetusviis = 'B2B' AND number = @number ) AND @maa = 0
			BEGIN
				-- arvutame käibeta rea summast käibega hinnad/summad
				UPDATE tell_tellimused_read SET
					yhikuhind = ROUND( ( rsum / NULLIF( kogus, 0 ) ), 4 )
					, summa = rsum
					, tkkm = ROUND( ( 
							ROUND( ( ( rsum ) * ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 4 )
						/ NULLIF( kogus, 0 ) ), 4 )
					, rsum = ROUND( ( 
								ROUND( ( ( rsum ) * ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 4 ) ), 4 )
				WHERE number = @number
			END
			ELSE
			BEGIN
				IF @valem IS NULL
				BEGIN
					-- arvutame käibega rea summast käibeta hinnad/summad
					UPDATE tell_tellimused_read SET tkkm = ROUND( ( rsum / NULLIF( kogus, 0 ) ), 4 )
						, summa = ROUND( ( ( rsum ) / ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 2 )
						, yhikuhind = ROUND( ( 
								ROUND( ( ( rsum ) / ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 4 )
							/ NULLIF( kogus, 0 ) ), 4 )
					WHERE number = @number
				END
				ELSE
				BEGIN
					UPDATE tell_tellimused_read SET yhikuhind = dbo.get_hind2( artikkel, @valem ), summa = dbo.get_hind2( artikkel, @valem ) * NULLIF( kogus, 0 )
					WHERE number = @number
				END
			END
			/*
			IF @valem IS NULL
			BEGIN
				-- arvutame käibega rea summast käibeta hinnad/summad
				UPDATE tell_tellimused_read SET tkkm = ROUND( ( rsum / NULLIF( kogus, 0 ) ), 4 )
					, summa = ROUND( ( ( rsum ) / ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 2 )
					, yhikuhind = ROUND( ( 
							ROUND( ( ( rsum ) / ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 4 )
						/ NULLIF( kogus, 0 ) ), 4 )
				WHERE number = @number
			END
			ELSE
			BEGIN
				UPDATE tell_tellimused_read SET yhikuhind = dbo.get_hind2( artikkel, @valem ), summa = dbo.get_hind2( artikkel, @valem ) * NULLIF( kogus, 0 )
				WHERE number = @number
			END
			*/

			/*
			--UPDATE tell_tellimused_read SET tkkm = ROUND( ( rsum / kogus ), 4 ), yhikuhind = ROUND( ( ( rsum / kogus ) / ( 1 + isnull( ( select TOP 1 ilmakm from fin_KMkoodid WITH (nolock) where kood = kmkood ), 0 ) / 100 ) ), 4 )	WHERE number=@number
			UPDATE tell_tellimused_read SET yhikuhind =
				ROUND( yhikuhind / ( 1 + ( isnull( ( SELECT TOP 1 ilmakm FROM fin_KMkoodid WITH(nolock) WHERE kood = kmkood ), 0 ) / 100 ) ), 4 )
				WHERE number = @number
			UPDATE tell_tellimused_read SET summa = yhikuhind * kogus
				WHERE number = @number
			*/
			declare @customer_c_header nvarchar(32)
			select @customer_c_header = klient_kood from tell_tellimused where number=@number
			/* Updating account in rows  */
			if  @customer_c_header in ('CHICCOLV', 'TOYSLV')
				begin
					if @customer_c_header = 'CHICCOLV'
						begin
							update tell_tellimused_read set konto='6121' where number=@number
						end
					if @customer_c_header = 'TOYSLV'
						begin
							update tell_tellimused_read set konto='6120' where number=@number
						end
				end
			--EXEC dbo.tell_tellimused_renum @number
			EXEC dbo.arvuta_tellimus @number
			exec hooldus_vaba 'tellimus',@number
			update tell_tellimused_read set rv=rn where number=@number
			update tell_tellimused set saldo=summakokku where number=@number
		
			insert into kliendid (kood, nimi, aadress1, aadress2, aadress3, email, kontakt, telefon)
			select klient_kood, klient_nimi, aadress1, aadress2, aadress3, field57, esindaja, telefon
			from tell_tellimused where number=@number and klient_kood not in (select kood from kliendid)
			and ISNULL(klient_kood,'')!=''
		
			set @koodid=@koodid+convert(nvarchar,@number)
		
		
			insert into #results values (@webid, 'ORDER', 0, 'OK','Orders')
		end
			ELSE
		BEGIN
			insert into #results values (@webid, 'ORDER', 1, 'Duplicate','Orders')
		END
	end
	else
	begin
			insert into #results values (@webid, 'ORDER', 2, 'Incorrect AppKey','Orders')
	end

	set @x=@x+1
	FETCH NEXT FROM tellimused INTO @webid, @appkey
	if @@FETCH_STATUS = 0 set @koodid=@koodid+';'
END
CLOSE tellimused
DEALLOCATE tellimused


--cleanup
--delete from in_tell_tellimused_klient where number in (select number from in_tell_tellimused where x=@key)
delete from in_tell_tellimused_read where number in (select number from in_tell_tellimused where x=@key)
delete from in_tell_tellimused where x=@key

-- select * from in_tell_tellimused

if (select COUNT(*) from #results)=0
		insert into #results values (NULL, 'GENERAL', 100, 'No processable data found',NULL)


--tulemused valja

select @result1=
(select result as "@Type", descr as "@Desc", number as "@docid", tyyp as "@doctype", submittype as "@submit"
 from #results for xml path ('Result'))

set @result2='<?xml version="1.0" encoding="UTF-8"?><results>'+CONVERT(nvarchar(max),@result1)+'</results>'

--select * from tell_tellimused where number = 2 order by number
--select * from in_tell_tellimused order by number

select @result2
drop table #results




GO
