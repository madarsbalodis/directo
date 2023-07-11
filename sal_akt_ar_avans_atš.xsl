<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:js="urn:formulas"
    exclude-result-prefixes="msxsl js fo">
    <xsl:output method="html" />

    <xsl:decimal-format name="ocra" decimal-separator='.' grouping-separator=' ' />
    <xsl:key name="unique_currency" match="/documents/document/kliendi_arved/kliendi_arve" use="valuuta" />

    <!-- Define the key for grouping -->
    <xsl:key name="konto" match="kliendi_ettemaks2" use="konto" />
       
    <xsl:key name="customer" match="/documents/document" use="klient_kood" />

    <xsl:template match="/">

        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <html>

        <head>
            <title>Akts par savstarpējo norēķinu salīdzināšanu</title>
            <style type="text/css">
                body {
                    text-align: center;
                }

                .container {
                    display: table;
                    text-align: left;
                    width: 700px;
                    margin: auto;
                    font-family: calibri;
                }

                .headTable {
                    width: 700px;
                    border-collapse: collapse;
                    text-align: left;
                    padding: 10px 0px 10px 0px;
                }

                .headcell1 {
                    width: 250px;
                    height: 15px;
                    border-collapse: collapse;
                    text-align: left;
                    padding: 0px 0px 0px 5px;
                }

                .headcell2 {
                    width: 200px;
                    height: 15px;
                    border-collapse: collapse;
                    text-align: center;
                    padding: 0px 0px 0px 5px;
                }

                .finIntroTable {
                    border-collapse: collapse;
                    width: 700px;
                }

                .finIntrocell1 {
                    width: 165px;
                    height: 15px;
                    text-align: left;
                    padding: 0px 0px 0px 5px;
                }

                .finIntrocell2 {
                    width: 40px;
                }

                .finIntrocell1bord {
                    width: 165px;
                    height: 15px;
                    border-top: 1px solid #000000;
                    border-bottom: 1px solid #000000;
                    border-left: 1px solid #000000;
                    border-right: 1px solid #000000;
                    text-align: center;
                    padding: 0px 0px 0px 5px;
                }

                .signTable {
                    border-collapse: collapse;
                    width: 700px;
                }

                .signcell1 {
                    width: 330px;
                    height: 15px;
                    text-align: left;
                    padding: 0px 0px 0px 5px;
                }

                .signcell2 {
                    width: 40px;
                }

                .signcell3 {
                    width: 330px;
                    height: 15px;
                    border-bottom: 1px solid #000000;
                }

                .spacer {
                    height: 10px;
                }

                .spacer_big {
                    height: 20px;
                }

                .spacer_large {
                    height: 40px;
                }

                .pbreak {
                    page-break-after: always;
                }

                .divider {
                    clear: both;
                }

                <!-- Text styles -->
                <!-- Header 1 -->
                .h1 {
                    font-size: 14px;
                    font-family: arial;
                    font-weight: bold;
                }

                <!-- Header 2 -->
                .h2 {
                    font-size: 12px;
                    font-family: arial;
                    font-weight: bold;
                }

                <!-- Text 1 -->
                .t1 {
                    font-size: 13px;
                    font-family: arial;
                    font-weight: bold;
                }

                <!-- Text 2 -->
                .t2 {
                    font-family: arial;
                    font-size: 11px;
                }

                .t3 {
                    font-family: arial;
                    font-size: 11px;
                    font-weight: bold;
                }

                .t4 {
                    font-family: arial;
                    font-size: 10px;
                    font-style: italic;
                }
            </style>
        </head>

        <body>
    <xsl:variable name="DistinctAccount">
    <accounts>
    <xsl:for-each select="/documents/document/kliendi_ettemaksud2/kliendi_ettemaks2[count(. | key('konto',konto)[1])=1 and tyyp='Laekumine']">
            <account>
                <code><xsl:value-of select="konto"/></code>
                <name><xsl:value-of select="konto_nimi"/></name>
            </account>
  </xsl:for-each>
      </accounts>
    </xsl:variable>
<xsl:variable name="customerPrep">
    <prepayments>
        <xsl:for-each select="/documents/document/kliendi_ettemaksud2/kliendi_ettemaks2[tyyp='Laekumine']">
            <xsl:variable name="rate">
                <xsl:choose>
                        <xsl:when test="kurss=''">1</xsl:when>
                        <xsl:when test="kurss!=''"><xsl:value-of select="kurss"/></xsl:when>
                </xsl:choose>
            </xsl:variable>
            <prepayment>
                <summa><xsl:value-of select="format-number(((laek * (-1))) * $rate,'0.00')"/></summa>
                <rate><xsl:value-of select="format-number(kurss,'0.00')"/></rate>
                <preid><xsl:value-of select="etteid"/></preid>
                <custCode><xsl:value-of select="klient_kood"/></custCode>
                <account><xsl:value-of select="konto"/></account>
                <accountName><xsl:value-of select="konto_nimi"/></accountName>
            </prepayment>
        </xsl:for-each>
    </prepayments>
</xsl:variable>
<xsl:variable name="customerPrep2">
    <prepayments>
        <xsl:for-each select="/documents/document/kliendi_ettemaksud2/kliendi_ettemaks2[tyyp='Arve']">
            <xsl:variable name="rate">
                <xsl:choose>
                        <xsl:when test="kurss=''">1</xsl:when>
                        <xsl:when test="kurss!=''"><xsl:value-of select="kurss"/></xsl:when>
                </xsl:choose>
            </xsl:variable>
            <prepayment>
                <summa><xsl:value-of select="format-number(laek * $rate,'0.00')"/></summa>
                <rate><xsl:value-of select="format-number(kurss,'0.00')"/></rate>
                <preid><xsl:value-of select="etteid"/></preid>
                <custCode><xsl:value-of select="klient_kood"/></custCode>
                <account><xsl:value-of select="konto"/></account>
                <accountName><xsl:value-of select="konto_nimi"/></accountName>
            </prepayment>
        </xsl:for-each>
    </prepayments>
</xsl:variable>
<xsl:variable name="customerPrepTotals">
    <prepayments>
        <xsl:for-each select="msxsl:node-set($customerPrep)/prepayments/prepayment">
        <xsl:variable name="preid" select="preid"/>
        <xsl:variable name="custCode2" select="custCode"/>
        <xsl:variable name="totalFromInvoice" select="sum(msxsl:node-set($customerPrep2)/prepayments/prepayment[custCode=$custCode2 and preid=$preid]/summa)"/>
        <xsl:variable name="totaEdited">
                <xsl:choose>
                        <xsl:when test="$totalFromInvoice = ''">0</xsl:when>
                        <xsl:when test="$totalFromInvoice != ''"><xsl:value-of select="$totalFromInvoice"/></xsl:when>
                </xsl:choose>
        </xsl:variable>   
            <prepayment>
                <preid><xsl:value-of select="preid"/></preid>
                <custCode><xsl:value-of select="custCode"/></custCode>
                <account><xsl:value-of select="account"/></account>
                <accountName><xsl:value-of select="accountName"/></accountName>
                <total><xsl:value-of select="format-number(summa - $totaEdited,'0.00')"/></total>
            </prepayment>
        </xsl:for-each>
    </prepayments>
</xsl:variable>
            <xsl:for-each select="/documents/document">
                <xsl:variable name="custCode" select="kood" />
             <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyzāčēģīķļņšūž'" />
        <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZĀČĒĢĪĶĻŅŠŪŽ'" />

        <xsl:variable name="language">
            <xsl:choose>
                <xsl:when
                    test="substring(translate(keel, $lowercase, $uppercase), 1, 2)='LV' or substring(translate(keel, $lowercase, $uppercase), 1, 2)='LA' or keel=''">LV</xsl:when>
                <xsl:otherwise>EN</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="currency_struct">
            <xsl:for-each
                select="kliendi_arved/kliendi_arve[count(. | key('unique_currency',valuuta)[1])=1]">
                <currency><xsl:value-of select="valuuta" /></currency>
            </xsl:for-each>
        </xsl:variable>

        <!-- Text variables -->
        <!--Header block text variables-->
        <xsl:variable name="str_headvar_1">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Akts par savstarpējo norēķinu salīdzināšanu'" />
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="'Balance reconciliation and confirmation'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_2">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'DEBITORAM'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'STATEMENT OF DEBT'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_3">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'AKTS'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="''" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_4">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Par savstarpējo norēķinu salīdzināšanu'" />
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="'Balance reconciliation and confirmation'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_5">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Pārbaudot savstarpējos norēķinus uz '" />
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="'We kindly ask you to confirm following balance as on'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_6">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="', konstatējām sekojošo atlikumu: '" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="': '" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_7">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Tel. '" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Phone '" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_headvar_8">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'/ Fakss '" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'/ Fax '" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--Fin block text variables-->
        <xsl:variable name="str_finvar_1">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Debets'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Debit'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_finvar_2">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Kredīts'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Credit'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_finvar_3">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Numurs'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Invoice No.'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_finvar_4">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Datums'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Date'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_finvar_5">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Apmaksas datums'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Payment due date'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_finvar_6">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Rēķina summa'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Invoice Amount'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_finvar_7">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Summa apmaksai'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Payment Amount'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!--Singature block text variables-->
        <xsl:variable name="str_signvar_1"><xsl:value-of
                select="'Lūdzam 10 dienu laikā apstiprināt atlikumu, parakstot un atsūtot šo aktu uz e-pastu: '" />
        </xsl:variable>
        <xsl:variable name="str_signvar_2"><xsl:value-of select="' vai pa pastu: '" /></xsl:variable>
        <xsl:variable name="str_signvar_3"><xsl:value-of
                select="'. Pretējā gadījumā par pareiziem uzskatīsim mūsu datus.'" /></xsl:variable>
        <xsl:variable name="str_signvar_4"><xsl:value-of
                select="'Please send us one signed copy of this statement (by using fax, e-mail or mail) within 10 days of receiving it. If statement will not be sent back within 30 days of the date of issuing it – we will consider our balance statement to be correct and confirmed.'" />
        </xsl:variable>
        <xsl:variable name="str_signvar_5"><xsl:value-of
                select="'Please send us account statement if there appears to be differences between our and your records. Please contact us by phone '" />
        </xsl:variable>
        <xsl:variable name="str_signvar_6"><xsl:value-of
                select="'. The documents can be sent to the following e-mail '" /></xsl:variable>
        <xsl:variable name="str_signvar_7"><xsl:value-of select="' or postal address '" /></xsl:variable>
        <xsl:variable name="str_signvar_8">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Galvenā grāmatvede'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Head of bookkeeping'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="str_signvar_16">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of
                        select="'Dokuments sagatavots elektroniski un ir derīgs bez paraksta.'" /></xsl:when>
                <xsl:otherwise><xsl:value-of
                        select="'Document is produced electronically and valid without signature.'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_signvar_17">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'Dokumentu sagatavoja grāmatvede '" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'Prepared by '" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="str_signvar_18">
            <xsl:choose>
                <xsl:when test="$language='LV'"><xsl:value-of select="'/paraksts, atšifrējums, datums/'" /></xsl:when>
                <xsl:otherwise><xsl:value-of select="'/signature, name, surname, date/'" /></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

                <xsl:variable name="rekinu_skaits" select="count(kliendi_arved/kliendi_arve/saldo)" />
                <xsl:variable name="rekini">
                    <xsl:for-each select="kliendi_arved/kliendi_arve">
                        <rekins>
                            <valuta>
                                <xsl:choose>
                                    <xsl:when test="valuuta=''">
                                        LVL
                                    </xsl:when>
                                    <xsl:when test="valuuta='LVL'">
                                        LVL
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="valuuta" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </valuta>
                            <summa>
                                <xsl:choose>
                                    <xsl:when test="saldo='0'">
                                        0.00
                                    </xsl:when>
                                    <xsl:when test="saldo!='0'">
                                        <xsl:choose>
                                            <xsl:when test="valuuta=''">
                                                <xsl:value-of select="format-number(saldo div 0.702804, '0.00')" />
                                            </xsl:when>
                                            <xsl:when test="valuuta='LVL'">
                                                <xsl:value-of select="format-number(saldo div 0.702804, '0.00')" />
                                            </xsl:when>
                                            <xsl:when test="valuuta!='LVL' and valuuta!=''">
                                                <xsl:value-of select="saldo" />
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:when>
                                </xsl:choose>
                            </summa>
                        </rekins>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="rekini_lvl">
                    <xsl:for-each select="msxsl:node-set($rekini)/rekins[valuta='LVL']">
                        <rekins1>
                            <summa1>
                                <xsl:value-of select="summa" />
                            </summa1>
                        </rekins1>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="rekini_eur">
                    <xsl:for-each select="msxsl:node-set($rekini)/rekins[valuta='EUR']">
                        <rekins2>
                            <summa2>
                                <xsl:value-of select="summa" />
                            </summa2>
                        </rekins2>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="rekini_cita_val">
                    <xsl:for-each
                        select="msxsl:node-set($rekini)/rekins [valuta!='LVL' and valuta!='EUR' and  valuta!='']">
                        <xsl:variable name="val" select="valuta" />
                        <rekins3>
                            <summa3>
                                <xsl:value-of select="summa" />
                            </summa3>
                            <valuta3>
                                <xsl:value-of select="valuta" />
                            </valuta3>
                        </rekins3>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="sumlvl" select="sum(msxsl:node-set($rekini_lvl)/rekins1/summa1)" />
                <xsl:variable name="sumeur" select="sum(msxsl:node-set($rekini_eur)/rekins2/summa2)" />
                <xsl:variable name="sumother" select="sum(msxsl:node-set($rekini_cita_val)/rekins3/summa3)" />
                <xsl:variable name="prieksapm">
                    <xsl:choose>
                        <xsl:when test="ettemaks=''">
                            0.00
                        </xsl:when>
                        <xsl:when test="ettemaks!=''">
                            <xsl:value-of select="format-number(ettemaks, '0.00')" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="sumlvluneur">
                    <xsl:value-of select="format-number(($sumeur + $sumlvl) + $prieksapm, '0.00')" />
                </xsl:variable>
                <xsl:variable name="rekinu_valuta">
                    <xsl:for-each select="kliendi_arved/kliendi_arve[valuuta!='']">
                        <xsl:value-of select="valuuta" />
                    </xsl:for-each>
                </xsl:variable>

                <xsl:if test="saldo!=''">
                    <xsl:if test="position()!=1">
                        <h5 style="page-break-after:always;">&#160;</h5>
                    </xsl:if>
                    <div class="container">
                        <xsl:variable name="prieksapm2">
                            <xsl:choose>
                                <xsl:when test="ettemaks=''">
                                    0.00
                                </xsl:when>
                                <xsl:when test="ettemaks!=''">
                                    <xsl:value-of select="format-number(ettemaks, '0.00')" />
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="temp1"><xsl:value-of select="substring-after(print_date,'.')" />
                        </xsl:variable>
                        <xsl:variable name="month1"><xsl:value-of select="substring-before($temp1,'.')" />
                        </xsl:variable>
                        <xsl:variable name="day1"><xsl:value-of select="substring-before(print_date,'.')" />
                        </xsl:variable>
                        <xsl:variable name="year1"><xsl:value-of select="substring-after($temp1,'.')" /></xsl:variable>
                        <xsl:variable name="menesisEng">
                            <xsl:if test="$month1='01' or $month1='1'">&#160; January,&#160; </xsl:if>
                            <xsl:if test="$month1='02' or $month1='2'">&#160; February,&#160; </xsl:if>
                            <xsl:if test="$month1='03' or $month1='3'">&#160; March,&#160; </xsl:if>
                            <xsl:if test="$month1='04' or $month1='4'">&#160; April,&#160; </xsl:if>
                            <xsl:if test="$month1='05' or $month1='5'">&#160; May,&#160; </xsl:if>
                            <xsl:if test="$month1='06' or $month1='6'">&#160; June,&#160; </xsl:if>
                            <xsl:if test="$month1='07' or $month1='7'">&#160; July,&#160; </xsl:if>
                            <xsl:if test="$month1='08' or $month1='8'">&#160; August,&#160; </xsl:if>
                            <xsl:if test="$month1='09' or $month1='9'">&#160; September,&#160; </xsl:if>
                            <xsl:if test="$month1='10'">&#160; October,&#160; </xsl:if>
                            <xsl:if test="$month1='11'">&#160; November,&#160; </xsl:if>
                            <xsl:if test="$month1='12'">&#160; December,&#160; </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="temp"><xsl:value-of select="substring-after(aeg,'.')" /> </xsl:variable>
                        <xsl:variable name="month"><xsl:value-of select="substring-before($temp,'.')" /></xsl:variable>
                        <xsl:variable name="day"><xsl:value-of select="substring-before(aeg,'.')" /></xsl:variable>
                        <xsl:variable name="year"><xsl:value-of select="substring-after($temp,'.')" /></xsl:variable>
                        <xsl:variable name="menesis2Eng">
                            <xsl:if test="$month='01' or $month='1'">&#160; January,&#160; </xsl:if>
                            <xsl:if test="$month='02' or $month='2'">&#160; February,&#160; </xsl:if>
                            <xsl:if test="$month='03' or $month='3'">&#160; March,&#160; </xsl:if>
                            <xsl:if test="$month='04' or $month='4'">&#160; April,&#160; </xsl:if>
                            <xsl:if test="$month='05' or $month='5'">&#160; May,&#160; </xsl:if>
                            <xsl:if test="$month='06' or $month='6'">&#160; June,&#160; </xsl:if>
                            <xsl:if test="$month='07' or $month='7'">&#160; July,&#160; </xsl:if>
                            <xsl:if test="$month='08' or $month='8'">&#160; August,&#160; </xsl:if>
                            <xsl:if test="$month='09' or $month='9'">&#160; September,&#160; </xsl:if>
                            <xsl:if test="$month='10'">&#160; October,&#160; </xsl:if>
                            <xsl:if test="$month='11'">&#160; November,&#160; </xsl:if>
                            <xsl:if test="$month='12'">&#160; December,&#160; </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="menesis3Eng">
                            <xsl:if test="$month='01' or $month='1'">&#160; January,&#160; </xsl:if>
                            <xsl:if test="$month='02' or $month='2'">&#160; February,&#160; </xsl:if>
                            <xsl:if test="$month='03' or $month='3'">&#160; March,&#160; </xsl:if>
                            <xsl:if test="$month='04' or $month='4'">&#160; April,&#160; </xsl:if>
                            <xsl:if test="$month='05' or $month='5'">&#160; May,&#160; </xsl:if>
                            <xsl:if test="$month='06' or $month='6'">&#160; June,&#160; </xsl:if>
                            <xsl:if test="$month='07' or $month='7'">&#160; July,&#160; </xsl:if>
                            <xsl:if test="$month='08' or $month='8'">&#160; August,&#160; </xsl:if>
                            <xsl:if test="$month='09' or $month='9'">&#160; September,&#160; </xsl:if>
                            <xsl:if test="$month='10'">&#160; October,&#160; </xsl:if>
                            <xsl:if test="$month='11'">&#160; November,&#160; </xsl:if>
                            <xsl:if test="$month='12'">&#160; December,&#160; </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="menesis">
                            <xsl:if test="$month='01' or $month='1'">janvārī</xsl:if>
                            <xsl:if test="$month='02' or $month='2'">februārī</xsl:if>
                            <xsl:if test="$month='03' or $month='3'">martā</xsl:if>
                            <xsl:if test="$month='04' or $month='4'">aprīlī</xsl:if>
                            <xsl:if test="$month='05' or $month='5'">maijā</xsl:if>
                            <xsl:if test="$month='06' or $month='6'">jūnijā</xsl:if>
                            <xsl:if test="$month='07' or $month='7'">jūlijā</xsl:if>
                            <xsl:if test="$month='08' or $month='8'">augustā</xsl:if>
                            <xsl:if test="$month='09' or $month='9'">septembrī</xsl:if>
                            <xsl:if test="$month='10'">oktobrī</xsl:if>
                            <xsl:if test="$month='11'">novembrī</xsl:if>
                            <xsl:if test="$month='12'">decembrī</xsl:if>
                        </xsl:variable>
                        <xsl:variable name="menesis2">
                            <xsl:if test="$month='01' or $month='1'">janvāri</xsl:if>
                            <xsl:if test="$month='02' or $month='2'">februāri</xsl:if>
                            <xsl:if test="$month='03' or $month='3'">martu</xsl:if>
                            <xsl:if test="$month='04' or $month='4'">aprīli</xsl:if>
                            <xsl:if test="$month='05' or $month='5'">maiju</xsl:if>
                            <xsl:if test="$month='06' or $month='6'">jūniju</xsl:if>
                            <xsl:if test="$month='07' or $month='7'">jūliju</xsl:if>
                            <xsl:if test="$month='08' or $month='8'">augustu</xsl:if>
                            <xsl:if test="$month='09' or $month='9'">septembri</xsl:if>
                            <xsl:if test="$month='10'">oktobri</xsl:if>
                            <xsl:if test="$month='11'">novembri</xsl:if>
                            <xsl:if test="$month='12'">decembri</xsl:if>
                        </xsl:variable>
                        <xsl:variable name="menesis3">
                            <xsl:if test="$month='01' or $month='1'">janvārim</xsl:if>
                            <xsl:if test="$month='02' or $month='2'">februārim</xsl:if>
                            <xsl:if test="$month='03' or $month='3'">martam</xsl:if>
                            <xsl:if test="$month='04' or $month='4'">aprīlim</xsl:if>
                            <xsl:if test="$month='05' or $month='5'">maijam</xsl:if>
                            <xsl:if test="$month='06' or $month='6'">jūnijam</xsl:if>
                            <xsl:if test="$month='07' or $month='7'">jūlijam</xsl:if>
                            <xsl:if test="$month='08' or $month='8'">augustam</xsl:if>
                            <xsl:if test="$month='09' or $month='9'">septembrim</xsl:if>
                            <xsl:if test="$month='10'">oktobrim</xsl:if>
                            <xsl:if test="$month='11'">novembrim</xsl:if>
                            <xsl:if test="$month='12'">decembrim</xsl:if>
                        </xsl:variable>

                        <div class="spacer_big"></div><!-- Space from top of the page -->
                        <table class="headTable">
                            <tr>
                                <td class="headcell1">
                                    <div class="t1">
                                        <xsl:value-of select="/documents/footer/firma_nimi" />
                                    </div>
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                    <text class="t2">
                                        <xsl:value-of select="/documents/footer/firma_kmnr" />
                                    </text>
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                    <text class="t2">
                                        <xsl:if test="/documents/footer/firma_tegevusaadress!=''"><xsl:value-of
                                                select="/documents/footer/firma_tegevusaadress" />&#160;</xsl:if>
                                        <xsl:if test="/documents/footer/firma_tegevusaadress2!=''"><xsl:value-of
                                                select="/documents/footer/firma_tegevusaadress2" />&#160;</xsl:if>
                                        <xsl:if test="/documents/footer/firma_tegevusaadress3!=''"><xsl:value-of
                                                select="/documents/footer/firma_tegevusaadress3" />&#160;</xsl:if>
                                    </text>
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                    <text class="t2">
                                        <xsl:value-of select="$str_headvar_7" /><xsl:value-of
                                            select="/documents/footer/firma_telefon" />
                                        <xsl:if test="/documents/footer/firma_faks!=''"><xsl:value-of
                                                select="$str_headvar_8" /><xsl:value-of
                                                select="/documents/footer/firma_faks" /></xsl:if>
                                    </text>
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                </td>
                                <td class="headcell2">
                                    <div class="t1">
                                        <xsl:value-of select="$str_headvar_2" />
                                    </div>
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                    <div class="t1">
                                        <xsl:value-of select="nimi" />
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                    <text class="t2">
                                        <xsl:value-of select="regnr" />
                                    </text>
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                    <text class="t2">
                                        <xsl:if test="aadress1!=''"><xsl:value-of select="aadress1" />&#160;</xsl:if>
                                        <xsl:if test="aadress2!=''"><xsl:value-of select="aadress2" />&#160;</xsl:if>
                                        <xsl:if test="aadress3!=''"><xsl:value-of select="aadress3" />&#160;</xsl:if>
                                    </text>
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <xsl:choose>
                                <xsl:when test="$language='LV'">
                                    <tr>
                                        <td class="headcell1">
                                        </td>
                                        <td class="headcell2">
                                            <div class="t1">
                                                <xsl:value-of select="$str_headvar_3" />
                                            </div>
                                        </td>
                                        <td class="headcell1">
                                        </td>
                                    </tr>
                                </xsl:when>
                            </xsl:choose>
                            <tr>
                                <td class="headcell1">
                                </td>
                                <td class="headcell2">
                                    <text class="t2">
                                        <xsl:value-of select="$str_headvar_4" />
                                    </text>
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <tr>
                                <td class="headcell1">
                                    <text class="t2">
                                        <xsl:choose>
                                            <xsl:when test="$language='LV'">
                                                <xsl:value-of select="concat($year,'. gada',' ',$day,'. ',$menesis)" />
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="concat($day1 ,$menesisEng, $year1)" />
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </text>
                                </td>
                                <td class="headcell2">
                                </td>
                                <td class="headcell1">
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <xsl:value-of select="$str_headvar_5" />
                                    <xsl:choose>
                                        <xsl:when test="$language='LV'">
                                            <xsl:value-of select="concat($year,'.gada',' ',$day,'.',$menesis2)" />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat($day ,$menesis2Eng, $year)" />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="$str_headvar_6" />
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer_big"></div>
                                </td>
                            </tr>
                        </table>

                        <table class="finIntroTable">
                            <tr>
                                <td class="finIntrocell1" colspan="2">
                                    <div class="t1">
                                        <xsl:value-of select="/documents/footer/firma_nimi" />
                                    </div>
                                </td>
                                <td class="finIntrocell2">
                                </td>
                                <td class="finIntrocell1" colspan="2">
                                    <div class="t1">
                                        <xsl:value-of select="nimi" />
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td class="finIntrocell1" colspan="2">
                                    <text class="t2">
                                        <xsl:value-of select="/documents/footer/firma_kmnr" />
                                    </text>
                                </td>
                                <td class="finIntrocell2">
                                </td>
                                <td class="finIntrocell1" colspan="2">
                                    <text class="t2">
                                        <xsl:value-of select="regnr" />
                                    </text>
                                </td>
                            </tr>
                            <tr>
                                <td class="finIntrocell1" colspan="2">
                                    <text class="t2">
                                        <xsl:if test="/documents/footer/firma_tegevusaadress!=''"><xsl:value-of
                                                select="/documents/footer/firma_tegevusaadress" />&#160;</xsl:if>
                                        <xsl:if test="/documents/footer/firma_tegevusaadress2!=''"><xsl:value-of
                                                select="/documents/footer/firma_tegevusaadress2" />&#160;</xsl:if>
                                        <xsl:if test="/documents/footer/firma_tegevusaadress3!=''"><xsl:value-of
                                                select="/documents/footer/firma_tegevusaadress3" />&#160;</xsl:if>
                                    </text>
                                </td>
                                <td class="finIntrocell2">
                                </td>
                                <td class="finIntrocell1" colspan="2">
                                    <text class="t2">
                                        <xsl:if test="aadress1!=''"><xsl:value-of select="aadress1" />&#160;</xsl:if>
                                        <xsl:if test="aadress2!=''"><xsl:value-of select="aadress2" />&#160;</xsl:if>
                                        <xsl:if test="aadress3!=''"><xsl:value-of select="aadress3" />&#160;</xsl:if>
                                    </text>
                                </td>
                            </tr>
                            <!--tr>
						<td class="finIntrocell1" colspan="2">
							<text class="t2">
								<xsl:value-of select="/documents/footer/firma_telefon" /><xsl:if test="/documents/footer/firma_faks!=''"> /  <xsl:value-of select="/documents/footer/firma_faks" /></xsl:if>
							</text>
						</td>
						<td class="finIntrocell2">
						</td>
						<td class="finIntrocell1" colspan="2">				
						</td>						
					</tr-->
                            <tr>
                                <td class="finIntrocell1">
                                    <div class="spacer"></div>
                                </td>
                                <td class="finIntrocell1">
                                </td>
                                <td class="finIntrocell2">
                                </td>
                                <td class="finIntrocell1">
                                </td>
                                <td class="finIntrocell1">
                                </td>
                            </tr>
                            <tr>
                                <td class="finIntrocell1bord">
                                    <text class="t2">
                                        <xsl:value-of select="$str_finvar_1" />
                                    </text>
                                </td>
                                <td class="finIntrocell1bord">
                                    <text class="t2">
                                        <xsl:value-of select="$str_finvar_2" />
                                    </text>
                                </td>
                                <td class="finIntrocell2">
                                </td>
                                <td class="finIntrocell1bord">
                                    <text class="t2">
                                        <xsl:value-of select="$str_finvar_1" />
                                    </text>
                                </td>
                                <td class="finIntrocell1bord">
                                    <text class="t2">
                                        <xsl:value-of select="$str_finvar_2" />
                                    </text>
                                </td>
                            </tr>
                            <tr>
                                <td class="finIntrocell1bord">
                                    <text class="t2">
                                        <xsl:choose>
                                            <xsl:when test="$rekinu_skaits &gt; 0">
                                                <xsl:choose>
                                                    <xsl:when test="$year &gt; 2013">
                                                        <xsl:choose>
                                                            <xsl:when test="$sumlvluneur &gt; '0.00000001'">
                                                                <xsl:value-of
                                                                    select="format-number($sumlvluneur, '0.00')" />&#160;EUR
                                                            </xsl:when>
                                                        </xsl:choose>
                                                    </xsl:when>
                                                    <xsl:when test="$year &lt; 2014">
                                                        <xsl:choose>
                                                            <xsl:when test="$sumlvluneur &gt; '0.00000001'">
                                                                <xsl:value-of
                                                                    select="format-number($sumlvluneur * 0.702804, '0.00')" />&#160;LVL
                                                            </xsl:when>
                                                        </xsl:choose>
                                                    </xsl:when>
                                                </xsl:choose>
                                                <xsl:if
                                                    test="sum(msxsl:node-set($rekini_cita_val)/rekins3/summa3)!='0.00'">
                                                    <xsl:choose>
                                                        <xsl:when test="$sumother &gt; '0.00000001'">
                                                            <xsl:value-of
                                                                select="format-number($sumother, '0.00')" />&#160;<xsl:value-of
                                                                select="msxsl:node-set($rekini_cita_val)/rekins3/valuta3" />
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </xsl:if>
                                                <xsl:if
                                                    test="sum(msxsl:node-set($rekini_cita_val)/rekins3/summa3)='0.00' and $sumlvluneur='0.00'">
                                                    0.00&#160;<xsl:value-of
                                                        select="msxsl:node-set($rekini_cita_val)/rekins3/valuta3" />
                                                </xsl:if>
                                            </xsl:when>
                                        </xsl:choose>
                                    </text>
                                </td>
                                <td class="finIntrocell1bord">
                                    <text class="t2">
                                        <xsl:choose>
                                            <xsl:when test="$rekinu_skaits &gt; 0">
                                                <xsl:choose>
                                                    <xsl:when test="$year &gt; 2013">
                                                        <xsl:choose>
                                                            <xsl:when test="$sumlvluneur &lt; '-0.00000001'">
                                                                <xsl:value-of
                                                                    select="format-number($sumlvluneur, '0.00')" />&#160;EUR
                                                            </xsl:when>
                                                        </xsl:choose>
                                                    </xsl:when>
                                                    <xsl:when test="$year &lt; 2014">
                                                        <xsl:choose>
                                                            <xsl:when test="$sumlvluneur &lt; '-0.00000001'">
                                                                <xsl:value-of
                                                                    select="format-number($sumlvluneur * 0.702804, '0.00')" />&#160;LVL
                                                            </xsl:when>
                                                        </xsl:choose>
                                                    </xsl:when>
                                                </xsl:choose>
                                                <xsl:if
                                                    test="sum(msxsl:node-set($rekini_cita_val)/rekins3/summa3)!='0.00'">
                                                    <xsl:choose>
                                                        <xsl:when test="$sumother &lt; '-0.00000001'">
                                                            <xsl:value-of
                                                                select="format-number($sumother, '0.00')" />&#160;<xsl:value-of
                                                                select="msxsl:node-set($rekini_cita_val)/rekins3/valuta3" />
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </xsl:if>
                                                <xsl:if
                                                    test="sum(msxsl:node-set($rekini_cita_val)/rekins3/summa3)='0.00' and $sumlvluneur='0.00'">
                                                    0.00&#160;<xsl:value-of
                                                        select="msxsl:node-set($rekini_cita_val)/rekins3/valuta3" />
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="$rekinu_skaits='0'">
                                                <xsl:if test="$prieksapm2 &lt; '-0.00000000001'">
                                                    <xsl:value-of
                                                        select="format-number(0.00 + $prieksapm2 * (-1), '0.00')" />&#160;
                                                    <xsl:choose>
                                                        <xsl:when test="$year &gt; 2013">
                                                            EUR
                                                        </xsl:when>
                                                        <xsl:when test="$year &lt; 2014">
                                                            LVL
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </xsl:if>
                                            </xsl:when>
                                        </xsl:choose>
                                    </text>
                                </td>
                                <td class="finIntrocell2">
                                </td>
                                <td class="finIntrocell1bord">
                                </td>
                                <td class="finIntrocell1bord">
                                </td>
                            </tr>
                        </table>

                        <div class="spacer_big"></div>

                        <table class="main_table1" width="100%" border="0" cellpadding="2" cellspacing="0"
                            style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                            bordercolor="#111111">
                            <tr>
                                <td align="center" valign="top" height="10"
                                    style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                    text-align="center" bordercolor="#111111"><xsl:value-of select="$str_finvar_3" />
                                </td>
                                <td align="center" valign="top" height="10"
                                    style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000   text-align:center;"
                                    bordercolor="#111111"><xsl:value-of select="$str_finvar_4" /></td>
                                <td valign="top" align="center" height="10"
                                    style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000   text-align:center;"
                                    bordercolor="#111111"><xsl:value-of select="$str_finvar_5" /></td>
                                <td align="center" valign="top" height="10"
                                    style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                    bordercolor="#111111"><xsl:value-of select="$str_finvar_6" /></td>
                                <td align="center" valign="top" height="10"
                                    style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                    bordercolor="#111111"><xsl:value-of select="$str_finvar_7" /></td>
                            </tr>
                            <xsl:for-each select="kliendi_arved/kliendi_arve">
                                <tr>
                                    <td align="center" height="10"
                                        style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                        bordercolor="#111111">

                                        <xsl:value-of select="number" />
                                    </td>
                                    <td align="center" height="10"
                                        style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                        bordercolor="#111111"> <xsl:value-of
                                            select="substring-before(concat(aeg,' '),' ')" /></td>
                                    <td height="10" align="center"
                                        style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                        bordercolor="#111111"><xsl:value-of
                                            select="substring-before(concat(aeg2,' '),' ')" /> </td>
                                    <td align="center" height="10"
                                        style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                        bordercolor="#111111"><xsl:value-of
                                            select="format-number(translate(tasuda,',','.'),'### ##0.00', 'ocra')" />&#160;
                                        <xsl:choose>
                                            <xsl:when test="valuuta!=''">
                                                <xsl:value-of select="valuuta" />
                                            </xsl:when>
                                            <xsl:otherwise>LVL</xsl:otherwise>
                                        </xsl:choose>
                                    </td>
                                    <td align="center" height="10"
                                        style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                        bordercolor="#111111"><xsl:value-of
                                            select="format-number(translate(saldo,',','.'),'### ##0.00', 'ocra')" />&#160;
                                        <xsl:choose>
                                            <xsl:when test="valuuta!=''">
                                                <xsl:value-of select="valuuta" />
                                            </xsl:when>
                                            <xsl:otherwise>LVL</xsl:otherwise>
                                        </xsl:choose>
                                    </td>

                                </tr>
                            </xsl:for-each>
                            <xsl:choose>
                                <xsl:when test="keel!=''">
                                    <tr>
                                        <td align="left" height="10" colspan="5"
                                            style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                            bordercolor="#111111"><b>Prepayment:&#160;
                                                <xsl:choose>
                                                    <xsl:when test="ettemaks=''">
                                                        0.00
                                                    </xsl:when>
                                                    <xsl:when test="ettemaks!=''">
                                                        <xsl:value-of select="format-number(ettemaks, '0.00')" />
                                                    </xsl:when>
                                                </xsl:choose>
                                            </b>
                                        </td>
                                    </tr>
                                </xsl:when>
                                <xsl:when test="keel=''">
                                    <tr>
                                        <td align="left" height="10" colspan="5"
                                            style="border-collapse: collapse; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000"
                                            bordercolor="#111111">

                                            <xsl:for-each select="msxsl:node-set($DistinctAccount)/accounts/account">
                                                <xsl:variable name="konto_nimi" select="name" />
                                                <xsl:variable name="konto" select="code" />
                                                
                                                <xsl:variable name="laek" select="format-number(sum(msxsl:node-set($customerPrepTotals)/prepayments/prepayment[custCode=$custCode and account=$konto]/total), '0.000000')" />
                                                

                                                <xsl:if test="$laek != 0">
                                                    <b>
                                                        <xsl:value-of select="concat($konto_nimi, ': ', format-number($laek, '0.00'))" />
                                                    </b>
                                                    <br />
                                                </xsl:if>

                                               
                                            </xsl:for-each>
                                            
                                        </td>
                                    </tr>
                                </xsl:when>
                            </xsl:choose>
                        </table>

                        <table class="signTable">
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>

                            <xsl:choose>
                                <xsl:when test="$language='LV'">
                                    <tr>
                                        <td colspan="3">
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_1" />
                                            </text>
                                            <text class="t3">
                                                <xsl:value-of select="/documents/document/sec_user_andmed/email" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_2" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="//footer/fin_aadress" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_3" />
                                            </text>
                                        </td>
                                    </tr>
                                </xsl:when>
                                <xsl:otherwise>
                                    <tr>
                                        <td colspan="3">
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_4" />
                                            </text>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="3">
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_5" />
                                            </text>
                                            <text class="t3">
                                                <xsl:value-of select="//footer/fin_telefon" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_6" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="/documents/document/sec_user_andmed/email" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="$str_signvar_7" />
                                            </text>
                                            <text class="t2">
                                                <xsl:value-of select="//footer/firma_nimi" />&#160;<xsl:value-of
                                                    select="//footer/fin_aadress" />
                                            </text>
                                        </td>
                                    </tr>
                                </xsl:otherwise>
                            </xsl:choose>

                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <tr>
                                <td class="signcell1">
                                    <div class="t1">
                                        <xsl:value-of select="/documents/footer/firma_nimi" />
                                    </div>
                                </td>
                                <td class="signcell2">
                                </td>
                                <td class="signcell1">
                                    <div class="t1">
                                        <xsl:value-of select="nimi" />
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td colspan="3">
                                    <div class="spacer"></div>
                                </td>
                            </tr>
                            <tr>
                                <td class="signcell3">
                                </td>
                                <td class="signcell2">
                                </td>
                                <td class="signcell3">
                                </td>
                            </tr>
                            <tr>
                                <td class="signcell1">
                                </td>
                                <td class="signcell2">
                                    <div class="spacer"></div>
                                </td>
                                <td class="signcell1">
                                </td>
                            </tr>
                            <tr>
                                <td class="signcell1">
                                    <text class="t2">
                                        <xsl:value-of select="$str_signvar_8" />
                                    </text>
                                </td>
                                <td class="signcell2">
                                </td>
                                <td class="signcell1">
                                </td>
                            </tr>
                            <tr>
                                <td class="signcell1">
                                    <text class="t2">
                                        <xsl:value-of select="//document/sec_nimi" />
                                    </text>
                                </td>
                                <td class="signcell2">
                                </td>
                                <td class="signcell1">
                                </td>
                            </tr>
                        </table>
                        <div class="divider"></div>
                    </div> <!-- Konteinera beigas -->
                </xsl:if>
            </xsl:for-each>
        </body>

        </html>
    </xsl:template>

    <xsl:template name="getVal">
        <xsl:param name="value" />
        <xsl:variable name="res" select="format-number($value,'0.00')" />
        <xsl:choose>
            <xsl:when test="$res='NaN' or $res=''">0.00</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$res" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
