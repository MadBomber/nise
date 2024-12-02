<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Command Channel Entries</h2>
	<a href="/">Return</a>

    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">id</th>
	  <th align="left">read_buff</th>
    </tr>
    <xsl:for-each select="dispatcher">
    <tr>
	  <td><xsl:value-of select="chid"/></td>
	  <td><xsl:value-of select="ch"/></td>
    </tr>
    </xsl:for-each>
    </table>

  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
