<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:es="http://www.marklogic.com/enhanced-search#"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="es xd xs"
    version="2.0"
    xpath-default-namespace="http://www.w3.org/1999/xhtml">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 28, 2013</xd:p>
      <xd:p><xd:b>Author:</xd:b> pfennell</xd:p>
      <xd:p>Extract XHTML Content from the job-bag.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output encoding="UTF-8" indent="yes" media-type="application/xml" method="xml"/>
  
  <xsl:strip-space elements="*"/>
  
  <xd:doc></xd:doc>
  <xsl:template match="/">
    <xsl:copy-of select="es:job-bag/html"/>
  </xsl:template>
  
</xsl:transform>