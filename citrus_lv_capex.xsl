<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:js="urn:formulas"
    exclude-result-prefixes="msxsl js fo">
    <xsl:output method="html"/>
    <xsl:template match="/">
        <html>
            <head>
                <title>CAPEX</title>
            </head>
            <body>
            <style>
                .master {background-color:#66B2FF;}
                .lightgrey {background-color:#F0F0F0;}
            </style>

                <p>Periods</p>
                <table cellpadding="0" cellspacing="0">
                    <tr>
                        <th>#</th>
                        <th>Projekta #</th>
                        <th>Projekta Nosaukums</th>
                        <th>Stratēģiskais budžets</th>
                        <th>Aktuālais budžets</th>
                        <th>Atvērtāis</th>
                        <th>Neatvērtais</th>
                        <th>Ieguldītais</th>
                        <th>Atlikums</th>
                    </tr>
                    <!-- Process parent projects -->
                    <xsl:for-each select="/documents/document/capex_master_projects/capex_master_project">
                        <xsl:variable name="capexMasterProject" select="kood"/>
                        <xsl:variable name="capexMasterProjectPosition" select="position()"/>

                        <!-- Calculate Atvērtāis, Ieguldītais for parent by summing children -->
                        <xsl:variable name="childAtvertaisSum" select="sum(/documents/document/capex_projects/capex_project[master=$capexMasterProject]/contr_summa)"/>
                        <xsl:variable name="childIegulditaisSum" select="sum(/documents/document/capex_projects/capex_project[master=$capexMasterProject]/invoicesum)"/>

                        <!-- Calculate Neatvērtais and Atlikums for parent -->
                        <xsl:variable name="parentAktualais" select="sum(/documents/document/capex_master_projects/capex_master_project[kood=$capexMasterProject]/rowsact/row/baas1deebet)"/>
                        <xsl:variable name="parentNeatvertais" select="$parentAktualais - $childAtvertaisSum"/>
                        <xsl:variable name="parentAtlikums" select="$childAtvertaisSum - $childIegulditaisSum"/>

                        <tr>
                            <td class="master">7.4.<xsl:value-of select="$capexMasterProjectPosition"/></td>
                            <td class="master"><xsl:value-of select="kood"/></td>
                            <td class="master"><xsl:value-of select="nimi"/></td>
                            <td class="master"><xsl:value-of select="format-number(sum(/documents/document/capex_master_projects/capex_master_project[kood=$capexMasterProject]/rows/row/baas1deebet), '0.00')"/></td>
                            <td class="master"><xsl:value-of select="format-number($parentAktualais, '0.00')"/></td>
                            <td class="master"><xsl:if test="$childAtvertaisSum != 0.00"><xsl:value-of select="format-number($childAtvertaisSum, '0.00')"/></xsl:if></td>
                            <td class="master"><xsl:value-of select="format-number($parentNeatvertais, '0.00')"/></td>
                            <td class="master"><xsl:if test="$childIegulditaisSum != 0.00"><xsl:value-of select="format-number($childIegulditaisSum, '0.00')"/></xsl:if></td>
                            <td class="master"><xsl:if test="$parentAtlikums != 0.00"><xsl:value-of select="format-number($parentAtlikums, '0.00')"/></xsl:if></td>
                        </tr>

                        <!-- Process child projects and ensure correct Atlikums calculation -->
                        <xsl:for-each select="/documents/document/capex_projects/capex_project[master=$capexMasterProject]">
                            <xsl:variable name="capexProject" select="kood"/>
                            <xsl:variable name="capexProjectPosition" select="position()"/>

                            <!-- Calculate values for child projects -->
                            <xsl:variable name="childStrategic" select="sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rows/row/baas1deebet)"/>
                            <xsl:variable name="childActual" select="sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rowsact/row/baas1deebet)"/>
                            <xsl:variable name="childAtvertais" select="contr_summa"/>
                            <xsl:variable name="childIegulditais" select="invoicesum"/>
                            <xsl:variable name="childAtlikums" select="$childAtvertais - $childIegulditais"/>

                            <tr>
                                <td class="lightgrey">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/></td>
                                <td class="lightgrey"><xsl:value-of select="kood"/></td>
                                <td class="lightgrey"><xsl:value-of select="nimi"/></td>
                                <td class="lightgrey"><xsl:if test="$childStrategic != 0.00"><xsl:value-of select="format-number($childStrategic, '0.00')"/></xsl:if></td>
                                <td class="lightgrey"><xsl:if test="$childActual != 0.00"><xsl:value-of select="format-number($childActual, '0.00')"/></xsl:if></td>
                                <td class="lightgrey"><xsl:if test="$childAtvertais != 0.00"><xsl:value-of select="format-number($childAtvertais, '0.00')"/></xsl:if></td>
                                <td class="lightgrey">&#160;</td> <!-- Neatvērtais is not needed for child projects -->
                                <td class="lightgrey"><xsl:if test="$childIegulditais != 0.00"><xsl:value-of select="format-number($childIegulditais, '0.00')"/></xsl:if></td>
                                <td class="lightgrey">
                                    <xsl:choose>
                                        <xsl:when test="$childAtlikums != 0.00 and $childAtlikums != -$childIegulditais">
                                            <xsl:value-of select="format-number($childAtlikums, '0.00')"/>
                                        </xsl:when>
                                        <xsl:otherwise>&#160;</xsl:otherwise>
                                    </xsl:choose>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
