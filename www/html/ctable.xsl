<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Connection Table Entries</h2>
	<a href="/">Return</a>

    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">id</th>
      <th align="left">name</th>
	  <th align="left">host</th>
	  <th align="left">port</th>
	  <th align="left">header</th>
	  <th align="left">proxy_role</th>
	  <th align="left">connection_type</th>
	  <th align="left">max_retry_timeout</th>
	  <th align="left">priority</th>
	  <th align="left">tcp_nodelay</th>
	  <th align="left">send_buff</th>
	  <th align="left">recv_buff</th>
	  <th align="left">read_buff</th>
    </tr>
    <xsl:for-each select="entity">
    <tr>
	  <td><xsl:value-of select="id_"/></td>
	  <td><xsl:value-of select="name_"/></td>
	  <td><xsl:value-of select="host_"/></td>
	  <td><xsl:value-of select="port_"/></td>
	  <td><xsl:value-of select="header_"/></td>
	  <td><xsl:value-of select="proxy_role_"/></td>
	  <td><xsl:value-of select="connection_type_"/></td>
	  <td><xsl:value-of select="max_retry_timeout_"/></td>
	  <td><xsl:value-of select="priority_"/></td>
	  <td><xsl:value-of select="tcp_nodelay"/></td>
	  <td><xsl:value-of select="send_buff"/></td>
	  <td><xsl:value-of select="recv_buff"/></td>
	  <td><xsl:value-of select="read_buff"/></td>
    </tr>
    </xsl:for-each>
    </table>

  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
