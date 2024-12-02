<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Acceptors</h2>
	<a href="/">Return</a>

    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">sim entity id</th>
      <th align="left">listen address</th>
      <th align="left">listen port</th>
      <th align="left">connection address</th>
      <th align="left">connection port</th>
      <th align="left">proxy_role</th>
      <th align="left">num ch</th>
      <th align="left">bound 2 handler</th>
    </tr>
    <xsl:for-each select="acceptor">
    <tr>
	  <td><xsl:value-of select="sim_entity_id"/></td>
	  <td><xsl:value-of select="listen_addr"/></td>
	  <td><xsl:value-of select="listen_port"/></td>
	  <td><xsl:value-of select="connection_addr"/></td>
	  <td><xsl:value-of select="connection_port"/></td>
	  <td><xsl:value-of select="proxy_role"/></td>
	  <td><xsl:value-of select="num_ch"/></td>
	  <td><xsl:value-of select="bound_2_handler"/></td>
    </tr>
    </xsl:for-each>
    </table>
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
