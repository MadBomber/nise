<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Models</h2>
	<a href="/">Return</a>

    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">chid</th>
      <th align="left">jid</th>
      <th align="left">mid</th>
      <th align="left">nodeid</th>
      <th align="left">unitid</th>
      <th align="left">statsid</th>
      <th align="left">pid</th>
      <th align="left">mid_name</th>
      <th align="left">ch</th>
    </tr>
    <xsl:for-each select="model">
    <tr>
	  <td><xsl:value-of select="chid"/></td>
	  <td><xsl:value-of select="jid"/></td>
	  <td><xsl:value-of select="mid"/></td>
	  <td><xsl:value-of select="nodeid"/></td>
	  <td><xsl:value-of select="unitid"/></td>
	  <td><xsl:value-of select="statsid"/></td>
	  <td><xsl:value-of select="pid"/></td>
	  <td><xsl:value-of select="mid_name"/></td>
	  <td><xsl:value-of select="ch"/></td>
    </tr>
    </xsl:for-each>
    </table>
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
