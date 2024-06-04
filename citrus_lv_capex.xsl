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
			<table callpadding="0" cellspacing="0">
				<tr>
					<th>#</th>
					<th>Projekta #</th>
					<th>Projekta Nosaukums</th>
					<th>Stratēģiskais budžets</th>
					<th>Aktuālais budžets</th>
					<th>Atvērtais</th>
					<th>Neatvērtais</th>
					<th>Ieguldītais</th>
					<th>Atlikums</th>
				</tr>
				<xsl:for-each select="/documents/document/capex_master_projects/capex_master_project">
				<xsl:variable name="capexMasterProject" select="kood"/>
				<xsl:variable name="capexMasterProjectPosition" select="position()"/>
				<!--xsl:variable name="sums" select="$capexMasterProjectSum + $project0MasterSum"/-->
				<tr>
					<td class="master">7.4.<xsl:value-of select="$capexMasterProjectPosition"/></td>
					<td class="master"><xsl:value-of select="kood"/></td>
					<td class="master"><xsl:value-of select="nimi"/></td>
					<td class="master"><xsl:value-of select="format-number(sum(/documents/document/capex_master_projects/capex_master_project[kood=$capexMasterProject]/rows/row/baas1deebet),'0.00')"/></td>
					<td class="master"><xsl:value-of select="format-number(sum(/documents/document/capex_master_projects/capex_master_project[kood=$capexMasterProject]/rowsact/row/baas1deebet),'0.00')"/></td>
					<td class="master">&#160;</td>
					<td class="master"><xsl:value-of select="format-number(sum(/documents/document/capex_master_projects/capex_master_project[kood=$capexMasterProject]/rowsact/row/baas1deebet) - sum(/documents/document/projects/project[budget_proj_master=$capexMasterProject and budget_proj_master!=first_master]/contr_summa),'0.00')"/></td>
					<td class="master">&#160;</td>
					<td class="master">&#160;</td>
				</tr>
				<!--  -->
				<xsl:for-each select="/documents/document/capex_projects/capex_project[master=$capexMasterProject]">
				<xsl:variable name="capexProject" select="kood"/>
				<xsl:variable name="capexProjectPosition" select="position()"/>
				<xsl:variable name="capexMasterProjectSum" select="format-number(/documents/document/capex_projects/capex_project[master=$capexMasterProject]/contr_summa,'0.00')"/>
				<tr>
					<td class="lightgrey">7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/></td>
					<td class="lightgrey"><xsl:value-of select="kood"/></td>
					<td class="lightgrey"><xsl:value-of select="nimi"/></td>
					<td class="lightgrey"><xsl:value-of select="format-number(sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rows/row/baas1deebet),'0.00')"/></td>
					<td class="lightgrey"><xsl:value-of select="format-number(sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rowsact/row/baas1deebet),'0.00')"/></td>
					<td class="lightgrey"><xsl:value-of select="contr_summa"/></td>
					<td class="lightgrey">
						<xsl:choose>
							<xsl:when test="sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rowsact/row/baas1deebet) &gt; 0 and contr_summa &gt; 0"><xsl:value-of select="format-number(sum(/documents/document/capex_projects/capex_project[kood=$capexProject]/rowsact/row/baas1deebet) - contr_summa,'0.00')"/></xsl:when>
						</xsl:choose>
						
					</td>
					<td class="lightgrey"><xsl:choose>
							<xsl:when test="invoicesum &gt; 0"><xsl:value-of select="format-number(invoicesum,'0.00')"/></xsl:when>
							<xsl:otherwise>
										&#160;
									</xsl:otherwise>
						</xsl:choose>
						</td>
					<td class="lightgrey">
						<xsl:choose>
							<xsl:when test="contr_summa &gt; 0 and invoicesum &gt; 0">
								<xsl:value-of select="format-number(contr_summa - invoicesum,'0.00')"/>
							</xsl:when>
							<xsl:otherwise>
								&#160;
							</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
				<xsl:for-each select="/documents/document/projects/project[first_master=$capexProject]">
				<xsl:variable name="project0" select="first_stproj"/>
				<xsl:variable name="ProjectPosition0" select="position()"/>
				<xsl:variable name="project0MasterSum" select="format-number(/documents/document/projects/project[first_master=$project0]/contr_summa,'0.00')"/>
				<tr>
					<td>7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/></td>
					<td><xsl:value-of select="first_stproj"/></td>
					<td><xsl:value-of select="pname"/></td>
					<td>&#160;</td>
					<td>&#160;</td>
					<td><xsl:value-of select="contr_summa"/></td>
					<td>&#160;</td>
					<td>
						<xsl:choose>
							<xsl:when test="invoicesum &gt; 0">
								<xsl:value-of select="format-number(invoicesum,'0.00')"/>
							</xsl:when>	
							<xsl:otherwise>
								&#160;
							</xsl:otherwise>
						</xsl:choose>
					</td>
					<td>
						<xsl:choose>
							<xsl:when test="contr_summa &gt; 0 and invoicesum &gt; 0">
								<xsl:value-of select="format-number(contr_summa - invoicesum,'0.00')"/>
							</xsl:when>
							<xsl:otherwise>
								&#160;
							</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
					<xsl:for-each select="/documents/document/projects/project[first_master=$project0]">
					<xsl:variable name="project1" select="first_stproj"/>
					<xsl:variable name="ProjectPosition1" select="position()"/>
					<xsl:variable name="project1MasterSum" select="format-number(/documents/document/projects/project[first_master=$project1]/contr_summa,'0.00')"/>
					<tr>
						<td>7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/></td>
						<td><xsl:value-of select="first_stproj"/></td>
						<td><xsl:value-of select="pname"/></td>
						<td>&#160;</td>
						<td>&#160;</td>
						<td><xsl:value-of select="contr_summa"/></td>
						<td>&#160;</td>
						<td>
							<xsl:choose>
								<xsl:when test="invoicesum &gt; 0">
									<xsl:value-of select="format-number(invoicesum,'0.00')"/>
								</xsl:when>	
								<xsl:otherwise>
									&#160;
								</xsl:otherwise>
							</xsl:choose>
						</td>
						<td>
						<xsl:choose>
							<xsl:when test="contr_summa &gt; 0 and invoicesum &gt; 0">
								<xsl:value-of select="format-number(contr_summa - invoicesum,'0.00')"/>
							</xsl:when>
							<xsl:otherwise>
								&#160;
							</xsl:otherwise>
						</xsl:choose>
					</td>
					</tr>
						<xsl:for-each select="/documents/document/projects/project[first_master=$project1]">
						<xsl:variable name="project2" select="first_stproj"/>
						<xsl:variable name="ProjectPosition2" select="position()"/>
						<xsl:variable name="project2MasterSum" select="format-number(/documents/document/projects/project[first_master=$project2]/contr_summa,'0.00')"/>
						<tr>
							<td>7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/>.<xsl:value-of select="$ProjectPosition2"/></td>
							<td><xsl:value-of select="first_stproj"/></td>
							<td><xsl:value-of select="pname"/></td>
							<td>&#160;</td>
							<td>&#160;</td>
							<td><xsl:value-of select="contr_summa"/></td>
							<td>&#160;</td>
							<td>
								<xsl:choose>
									<xsl:when test="invoicesum &gt; 0">
										<xsl:value-of select="format-number(invoicesum,'0.00')"/>
									</xsl:when>
									<xsl:otherwise>
										&#160;
									</xsl:otherwise>
									</xsl:choose>
							</td>
							<td>
								<xsl:choose>
									<xsl:when test="contr_summa &gt; 0 and invoicesum &gt; 0">
										<xsl:value-of select="format-number(contr_summa - invoicesum,'0.00')"/>
									</xsl:when>
									<xsl:otherwise>
										&#160;
									</xsl:otherwise>
								</xsl:choose>
							</td>
						</tr>
							<xsl:for-each select="/documents/document/projects/project[first_master=$project2]">
							<xsl:variable name="project3" select="first_stproj"/>
							<xsl:variable name="ProjectPosition3" select="position()"/>
							<xsl:variable name="project3MasterSum" select="format-number(/documents/document/projects/project[first_master=$project3]/contr_summa,'0.00')"/>
							<tr>
								<td>7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/>.<xsl:value-of select="$ProjectPosition2"/>.<xsl:value-of select="$ProjectPosition3"/></td>
								<td><xsl:value-of select="first_stproj"/></td>
								<td><xsl:value-of select="pname"/></td>
								<td>&#160;</td>
								<td>&#160;</td>
								<td><xsl:value-of select="contr_summa"/></td>
								<td>&#160;</td>
								<td>
									<xsl:choose>
										<xsl:when test="invoicesum &gt; 0"><xsl:value-of select="format-number(invoicesum,'0.00')"/></xsl:when>
										<xsl:otherwise>
										&#160;
									</xsl:otherwise>
									</xsl:choose>
									
								</td>
								<td>
									<xsl:choose>
										<xsl:when test="contr_summa &gt; 0 and invoicesum &gt; 0">
											<xsl:value-of select="format-number(contr_summa - invoicesum,'0.00')"/>
										</xsl:when>
										<xsl:otherwise>
											&#160;
										</xsl:otherwise>
									</xsl:choose>
								</td>
								
							</tr>
								<xsl:for-each select="/documents/document/projects/project[first_master=$project3]">
								<xsl:variable name="project4" select="first_stproj"/>
								<xsl:variable name="ProjectPosition4" select="position()"/>
								<tr>
									<td>7.4.<xsl:value-of select="$capexMasterProjectPosition"/>.<xsl:value-of select="$capexProjectPosition"/>.<xsl:value-of select="$ProjectPosition0"/>.<xsl:value-of select="$ProjectPosition1"/>.<xsl:value-of select="$ProjectPosition2"/>.<xsl:value-of select="$ProjectPosition3"/>.<xsl:value-of select="$ProjectPosition4"/></td>
									<td><xsl:value-of select="first_stproj"/></td>
									<td><xsl:value-of select="pname"/></td>
									<td>&#160;</td>
									<td>&#160;</td>
									<td><xsl:value-of select="contr_summa"/></td>
									<td>&#160;</td>
									<td>
										<xsl:choose>
											<xsl:when test="invoicesum &gt; 0"><xsl:value-of select="format-number(invoicesum,'0.00')"/></xsl:when>
											<xsl:otherwise>
										&#160;
									</xsl:otherwise>
										</xsl:choose>
									</td>
									<td>
										<xsl:choose>
											<xsl:when test="contr_summa &gt; 0 and invoicesum &gt; 0">
												<xsl:value-of select="format-number(contr_summa - invoicesum,'0.00')"/>
											</xsl:when>
											<xsl:otherwise>
												&#160;
											</xsl:otherwise>
										</xsl:choose>
									</td>
								</tr>
								</xsl:for-each>
							</xsl:for-each>
						</xsl:for-each>
					</xsl:for-each>
				</xsl:for-each>
				</xsl:for-each>
				</xsl:for-each>
			</table>
		</body>
	</html>
</xsl:template>
</xsl:stylesheet>
