<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template match="/boost_serialization">
  <html>
  <body>
    <h2>Dispatcher Options</h2>
	<a href="/">Return</a>

    <table border="1">
    <xsl:for-each select="dispatcher">
    <tr><td bgcolor="#9acd32">Option Flag</td><td><xsl:value-of select="options"/></td> </tr>
	<tr><td bgcolor="#9acd32">Command Port</td><td><xsl:value-of select="command_port"/></td> </tr>
	<tr><td bgcolor="#9acd32">Dispatcher-to-Dispatcher Port</td><td><xsl:value-of select="d2d_port"/></td> </tr>
	<tr><td bgcolor="#9acd32">Dispatcher-to-Model Port</td><td><xsl:value-of select="d2m_port"/></td> </tr>
	<tr><td bgcolor="#9acd32">Number of Reactor Threads</td><td><xsl:value-of select="num_threads"/></td> </tr>
	<tr><td bgcolor="#9acd32">Cache Routing Queries</td><td><xsl:value-of select="no_cache"/></td> </tr>
	<tr><td bgcolor="#9acd32">Max Timeout</td><td><xsl:value-of select="max_timeout"/></td> </tr>
	<tr><td bgcolor="#9acd32">Max Queue Size</td><td><xsl:value-of select="max_queue_size"/></td> </tr>
	<tr><td bgcolor="#9acd32">Max (No Header) Read Buffer Size</td><td><xsl:value-of select="max_buffer_size"/></td> </tr>
    </xsl:for-each>
    </table>
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
