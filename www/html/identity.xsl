<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Dispatcher Information</h2>
	<a href="/">Return</a>
    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">Peer ID</th>
      <th align="left">PID</th>
      <th align="left">Node ID</th>
    </tr>
    <xsl:for-each select="identity">
    <tr>
	  <td><xsl:value-of select="peer_id_"/></td>
	  <td><xsl:value-of select="pid_"/></td>
	  <td><xsl:value-of select="node_id_"/></td>
    </tr>
    </xsl:for-each>
    </table>
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
