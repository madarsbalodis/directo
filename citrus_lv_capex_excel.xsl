<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:js="urn:formulas"
    exclude-result-prefixes="msxsl js fo">
    <!--output-file:capex.xls-->
    <!--charset=utf-8-->
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/">
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
            xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:x="urn:schemas-microsoft-com:office:excel"
            xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
            xmlns:html="http://www.w3.org/TR/REC-html40">
            <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">
                <AllowPNG/>
            </OfficeDocumentSettings>
            <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">
                <WindowHeight>8676</WindowHeight>
                <WindowWidth>23040</WindowWidth>
                <WindowTopX>32767</WindowTopX>
                <WindowTopY>32767</WindowTopY>
                <ProtectStructure>False</ProtectStructure>
                <ProtectWindows>False</ProtectWindows>
            </ExcelWorkbook>
            <Styles>
                <Style ss:ID="Default" ss:Name="Normal">
                    <Alignment ss:Vertical="Bottom"/>
                    <Borders/>
                    <Font ss:FontName="Aptos Narrow" x:CharSet="186" x:Family="Swiss" ss:Size="11"
                        ss:Color="#000000"/>
                    <Interior/>
                    <NumberFormat/>
                    <Protection/>
                </Style>
                <Style ss:ID="s71">
                    <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>
                    <Font ss:FontName="Calibri" x:CharSet="186" x:Family="Swiss" ss:Color="#FFFFFF"
                        ss:Bold="1"/>
                    <Interior ss:Color="#203764" ss:Pattern="Solid"/>
                    <Protection ss:Protected="0"/>
                </Style>
                <Style ss:ID="s77">
                    <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>
                    <Font ss:FontName="Calibri" x:CharSet="186" x:Family="Swiss" ss:Color="#FFFFFF"
                        ss:Bold="1"/>
                    <Interior ss:Color="#203764" ss:Pattern="Solid"/>
                </Style>
                <Style ss:ID="s78">
                    <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>
                    <Font ss:FontName="Calibri" x:CharSet="186" x:Family="Swiss" ss:Color="#FFFFFF"
                        ss:Bold="1"/>
                    <Interior ss:Color="#203764" ss:Pattern="Solid"/>
                    <NumberFormat ss:Format="Short Date"/>
                </Style>
                <Style ss:ID="s81">
                    <Font ss:FontName="Aptos Narrow" x:Family="Swiss" ss:Size="11"
                        ss:Color="#000000" ss:Bold="1"/>
                    <Interior ss:Color="#83CCEB" ss:Pattern="Solid"/>
                    <NumberFormat ss:Format="@"/>
                </Style>
                <Style ss:ID="s82">
                    <Font ss:FontName="Aptos Narrow" x:Family="Swiss" ss:Size="11"
                        ss:Color="#000000" ss:Bold="1"/>
                    <Interior ss:Color="#83CCEB" ss:Pattern="Solid"/>
                </Style>
                <Style ss:ID="s84">
                    <Interior ss:Color="#F2F2F2" ss:Pattern="Solid"/>
                </Style>
            </Styles>
            <Worksheet ss:Name="Sheet1">
                <Table ss:DefaultRowHeight="14.4">
                    <Column ss:Width="54.599999999999994"/>
                    <Column ss:AutoFitWidth="0" ss:Width="87.6"/>
                    <Column ss:AutoFitWidth="0" ss:Width="193.2"/>
                    <Column ss:AutoFitWidth="0" ss:Width="70.8"/>
                    <Column ss:AutoFitWidth="0" ss:Width="72"/>
                    <Column ss:AutoFitWidth="0" ss:Width="98.4"/>
                    <Column ss:AutoFitWidth="0" ss:Width="127.19999999999999"/>
                    <Column ss:AutoFitWidth="0" ss:Width="99"/>
                    <Column ss:AutoFitWidth="0" ss:Width="90" ss:Span="1"/>
                    <Column ss:Index="11" ss:Width="63"/>
                    <Column ss:AutoFitWidth="0" ss:Width="141"/>
                    <Row ss:Height="27.6">
                        <Cell ss:StyleID="s77"><Data ss:Type="String">#</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Projekta numurs</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Projekta nosaukums</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Stratēģiskais budžets</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Aktuālais budžets</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Atvērtāis</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Neatvērtais</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Ieguldītais</Data></Cell>
                        <Cell ss:StyleID="s77"><Data ss:Type="String">Atlikums</Data></Cell>
                    </Row>
                    <xsl:for-each select="/documents/document/capex_master_projects/capex_master_project">
                        <xsl:variable name="capexMasterProject" select="kood"/>
                        <xsl:variable name="capexMasterProjectPosition" select="position()"/>
                        <xsl:variable name="childAtvertaisSum" select="sum(/documents/document/capex_projects/capex_project[master=$capexMasterProject]/contr_summa)"/>
                        <xsl:variable name="childIegulditaisSum" select="sum(/documents/document/capex_projects/capex_project[master=$capexMasterProject]/invoicesum)"/>
                        <xsl:variable name="parentAktualais" select="sum(/documents/document/capex_master_projects/capex_master_project[kood=$capexMasterProject]/rowsact/row/baas1deebet)"/>
                        <xsl:variable name="parentNeatvertais" select="$parentAktualais - $childAtvertaisSum"/>
                        <xsl:variable name="parentAtlikums" select="$childAtvertaisSum - $childIegulditaisSum"/>

                        <Row>
                            <Cell ss:StyleID="s81"><Data ss:Type="String">7.4.<xsl:value-of select="$capexMasterProjectPosition"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="kood"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="nimi"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="format-number(sum(rows/row/baas1deebet), '0.00')"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="format-number($parentAktualais, '0.00')"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="format-number($childAtvertaisSum, '0.00')"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="format-number($parentNeatvertais, '0.00')"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="format-number($childIegulditaisSum, '0.00')"/></Data></Cell>
                            <Cell ss:StyleID="s82"><Data ss:Type="String"><xsl:value-of select="format-number($parentAtlikums, '0.00')"/></Data></Cell>
                        </Row>

                        <xsl:for-each select="/documents/document/capex_projects/capex_project[master=$capexMasterProject]">
                            <xsl:variable name="capexProject" select="kood"/>
                            <xsl:variable name="capexProjectPosition" select="position()"/>
                            <xsl:variable name="childStrategic" select="sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rows/row/baas1deebet)"/>
                            <xsl:variable name="childActual" select="sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rowsact/row/baas1deebet)"/>
                            <xsl:variable name="childAtvertais" select="contr_summa"/>
                            <xsl:variable name="childIegulditais" select="invoicesum"/>
                            <xsl:variable name="childAtlikums" select="$childAtvertais - $childIegulditais"/>

                            <Row ss:StyleID="s84">
                                <Cell><Data ss:Type="String">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String"><xsl:value-of select="kood"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String"><xsl:value-of select="nimi"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String"><xsl:value-of select="format-number($childStrategic, '0.00')"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String"><xsl:value-of select="format-number($childActual, '0.00')"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String"><xsl:value-of select="format-number($childAtvertais, '0.00')"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String">&#160;</Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String"><xsl:value-of select="format-number($childIegulditais, '0.00')"/></Data></Cell>
                                <Cell ss:StyleID="s84"><Data ss:Type="String">
                                    <xsl:choose>
                                        <xsl:when test="$childAtlikums != 0.00 and $childAtlikums != -$childIegulditais">
                                            <xsl:value-of select="format-number($childAtlikums, '0.00')"/>
                                        </xsl:when>
                                        <xsl:otherwise>&#160;</xsl:otherwise>
                                    </xsl:choose>
                                </Data></Cell>
                            </Row>

                            <xsl:for-each select="/documents/document/projects/project[first_master=$capexProject]">
                                <xsl:variable name="project0" select="first_stproj"/>
                                <xsl:variable name="ProjectPosition0" select="position()"/>
                                <xsl:variable name="project0MasterSum" select="format-number(/documents/document/projects/project[first_master=$project0]/contr_summa, '0.00')"/>

                                <Row>
                                    <Cell><Data ss:Type="String">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/></Data></Cell>
                                    <Cell><Data ss:Type="String"><xsl:value-of select="first_stproj"/></Data></Cell>
                                    <Cell><Data ss:Type="String"><xsl:value-of select="pname"/></Data></Cell>
                                    <Cell><Data ss:Type="String"><xsl:value-of select="responsible"/></Data></Cell>
                                    <Cell><Data ss:Type="String"><xsl:value-of select="sdate"/></Data></Cell>
                                    <Cell><Data ss:Type="String"><xsl:value-of select="edate"/></Data></Cell>
                                    <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                    <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                    <Cell><Data ss:Type="String"><xsl:value-of select="format-number(contr_summa, '0.00')"/></Data></Cell>
                                    <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                    <Cell><Data ss:Type="String">
                                        <xsl:choose>
                                            <xsl:when test="invoicesum &gt; 0">
                                                <xsl:value-of select="format-number(invoicesum, '0.00')"/>
                                            </xsl:when>    
                                            <xsl:otherwise>&#160;</xsl:otherwise>
                                        </xsl:choose>
                                    </Data></Cell>
                                </Row>

                                <xsl:for-each select="/documents/document/projects/project[first_master=$project0]">
                                    <xsl:variable name="project1" select="first_stproj"/>
                                    <xsl:variable name="ProjectPosition1" select="position()"/>
                                    <xsl:variable name="project1MasterSum" select="format-number(/documents/document/projects/project[first_master=$project1]/contr_summa, '0.00')"/>

                                    <Row>
                                        <Cell><Data ss:Type="String">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/></Data></Cell>
                                        <Cell><Data ss:Type="String"><xsl:value-of select="first_stproj"/></Data></Cell>
                                        <Cell><Data ss:Type="String"><xsl:value-of select="pname"/></Data></Cell>
                                        <Cell><Data ss:Type="String"><xsl:value-of select="responsible"/></Data></Cell>
                                        <Cell><Data ss:Type="String"><xsl:value-of select="sdate"/></Data></Cell>
                                        <Cell><Data ss:Type="String"><xsl:value-of select="edate"/></Data></Cell>
                                        <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                        <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                        <Cell><Data ss:Type="String"><xsl:value-of select="format-number(contr_summa, '0.00')"/></Data></Cell>
                                        <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                        <Cell><Data ss:Type="String">
                                            <xsl:choose>
                                                <xsl:when test="invoicesum &gt; 0">
                                                    <xsl:value-of select="format-number(invoicesum, '0.00')"/>
                                                </xsl:when>    
                                                <xsl:otherwise>&#160;</xsl:otherwise>
                                            </xsl:choose>
                                        </Data></Cell>
                                    </Row>

                                    <xsl:for-each select="/documents/document/projects/project[first_master=$project1]">
                                        <xsl:variable name="project2" select="first_stproj"/>
                                        <xsl:variable name="ProjectPosition2" select="position()"/>
                                        <xsl:variable name="project2MasterSum" select="format-number(/documents/document/projects/project[first_master=$project2]/contr_summa, '0.00')"/>

                                        <Row>
                                            <Cell><Data ss:Type="String">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/>.<xsl:value-of select="$ProjectPosition2"/></Data></Cell>
                                            <Cell><Data ss:Type="String"><xsl:value-of select="first_stproj"/></Data></Cell>
                                            <Cell><Data ss:Type="String"><xsl:value-of select="pname"/></Data></Cell>
                                            <Cell><Data ss:Type="String"><xsl:value-of select="responsible"/></Data></Cell>
                                            <Cell><Data ss:Type="String"><xsl:value-of select="sdate"/></Data></Cell>
                                            <Cell><Data ss:Type="String"><xsl:value-of select="edate"/></Data></Cell>
                                            <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                            <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                            <Cell><Data ss:Type="String"><xsl:value-of select="format-number(contr_summa, '0.00')"/></Data></Cell>
                                            <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                            <Cell><Data ss:Type="String">
                                                <xsl:choose>
                                                    <xsl:when test="invoicesum &gt; 0">
                                                        <xsl:value-of select="format-number(invoicesum, '0.00')"/>
                                                    </xsl:when>    
                                                    <xsl:otherwise>&#160;</xsl:otherwise>
                                                </xsl:choose>
                                            </Data></Cell>
                                        </Row>

                                        <xsl:for-each select="/documents/document/projects/project[first_master=$project2]">
                                            <xsl:variable name="project3" select="first_stproj"/>
                                            <xsl:variable name="ProjectPosition3" select="position()"/>
                                            <xsl:variable name="project3MasterSum" select="format-number(/documents/document/projects/project[first_master=$project3]/contr_summa, '0.00')"/>

                                            <Row>
                                                <Cell><Data ss:Type="String">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/>.<xsl:value-of select="$ProjectPosition2"/>.<xsl:value-of select="$ProjectPosition3"/></Data></Cell>
                                                <Cell><Data ss:Type="String"><xsl:value-of select="first_stproj"/></Data></Cell>
                                                <Cell><Data ss:Type="String"><xsl:value-of select="pname"/></Data></Cell>
                                                <Cell><Data ss:Type="String"><xsl:value-of select="responsible"/></Data></Cell>
                                                <Cell><Data ss:Type="String"><xsl:value-of select="sdate"/></Data></Cell>
                                                <Cell><Data ss:Type="String"><xsl:value-of select="edate"/></Data></Cell>
                                                <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                                <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                                <Cell><Data ss:Type="String"><xsl:value-of select="format-number(contr_summa, '0.00')"/></Data></Cell>
                                                <Cell><Data ss:Type="String">&#160;</Data></Cell>
                                                <Cell><Data ss:Type="String">
                                                    <xsl:choose>
                                                        <xsl:when test="invoicesum &gt; 0">
                                                            <xsl:value-of select="format-number(invoicesum, '0.00')"/>
                                                        </xsl:when>    
                                                        <xsl:otherwise>&#160;</xsl:otherwise>
                                                    </xsl:choose>
                                                </Data></Cell>
                                            </Row>
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:for-each>
                </Table>
                <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
                    <PageSetup>
                        <Header x:Margin="0.3"/>
                        <Footer x:Margin="0.3"/>
                        <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
                    </PageSetup>
                    <Print>
                        <ValidPrinterInfo/>
                        <HorizontalResolution>600</HorizontalResolution>
                        <VerticalResolution>600</VerticalResolution>
                    </Print>
                    <Selected/>
                    <Panes>
                        <Pane>
                            <Number>3</Number>
                            <ActiveRow>12</ActiveRow>
                            <ActiveCol>11</ActiveCol>
                        </Pane>
                    </Panes>
                    <ProtectObjects>False</ProtectObjects>
                    <ProtectScenarios>False</ProtectScenarios>
                </WorksheetOptions>
            </Worksheet>
        </Workbook>
    </xsl:template>

    <!-- helper functions -->

    <xsl:template name="getVal">
        <xsl:param name="value" />
        <xsl:variable name="res" select="format-number($value,'0.00')" />
        <xsl:choose>
            <xsl:when test="$res='NaN' or $res=''">0.00</xsl:when>
            <xsl:otherwise><xsl:value-of select="$res" /></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="replaceCharsInString">
        <xsl:param name="stringIn" />
        <xsl:param name="charsIn" />
        <xsl:param name="charsOut" />
        <xsl:choose>
            <xsl:when test="contains($stringIn,$charsIn)">
                <xsl:value-of select="concat(substring-before($stringIn,$charsIn),$charsOut)" />
                <xsl:call-template name="replaceCharsInString">
                    <xsl:with-param name="stringIn" select="substring-after($stringIn,$charsIn)" />
                    <xsl:with-param name="charsIn" select="$charsIn" />
                    <xsl:with-param name="charsOut" select="$charsOut" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$stringIn" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="cleanName">
        <xsl:param name="name" />
        <xsl:variable name="name_without_lt">
            <xsl:call-template name="replaceCharsInString">
                <xsl:with-param name="stringIn" select="string($name)" />
                <xsl:with-param name="charsIn" >
                    <xsl:text disable-output-escaping="yes">&lt;</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="charsOut" select="'&amp;lt;'" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="name_without_gt">
            <xsl:call-template name="replaceCharsInString">
                <xsl:with-param name="stringIn" select="string($name_without_lt)" />
                <xsl:with-param name="charsIn" >
                    <xsl:text disable-output-escaping="yes">&gt;</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="charsOut" select="'&amp;gt;'" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="name_without_amp">
            <xsl:call-template name="replaceCharsInString">
                <xsl:with-param name="stringIn" select="string($name_without_gt)" />
                <xsl:with-param name="charsIn" >
                    <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="charsOut" select="'&amp;amp;'" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="name_without_apos">
            <xsl:call-template name="replaceCharsInString">
                <xsl:with-param name="stringIn" select="string($name_without_amp)" />
                <xsl:with-param name="charsIn" >
                    <xsl:text disable-output-escaping="yes">&apos;</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="charsOut" select="'&amp;apos;'" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="name_without_quot">
            <xsl:call-template name="replaceCharsInString">
                <xsl:with-param name="stringIn" select="string($name_without_apos)" />
                <xsl:with-param name="charsIn" >
                    <xsl:text disable-output-escaping="yes">&quot;</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="charsOut" select="'&amp;quot;'" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$name_without_quot" />
    </xsl:template>
</xsl:stylesheet>
