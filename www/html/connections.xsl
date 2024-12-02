<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Connections</h2>
	<a href="/">Return</a>

    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">connection id</th>
      <th align="left">handle</th>
      <th align="left">local</th>
      <th align="left">remote</th>
      <th align="left">connection type</th>
      <th align="left">proxy_role</th>
      <th align="left">state</th>
    </tr>
    <xsl:for-each select="connection">
    <tr>
	  <td><xsl:value-of select="connection_id"/></td>
	  <td><xsl:value-of select="handle"/></td>
	  <td><xsl:value-of select="local_address"/>:<xsl:value-of select="local_port"/></td>
	  <td><a href="http://{remote_address}:8010/"><xsl:value-of select="remote_address"/>:<xsl:value-of select="remote_port"/></a></td>
	  <td><xsl:value-of select="connection_type"/></td>
	  <td><xsl:value-of select="proxy_role"/></td>
	  <td><xsl:value-of select="state"/></td>
    </tr>
    </xsl:for-each>
    </table>
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
