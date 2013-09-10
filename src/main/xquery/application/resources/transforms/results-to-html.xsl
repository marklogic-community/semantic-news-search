<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:search="http://marklogic.com/appservices/search"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="search xs xd"
    version="2.0">
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jul 4, 2013</xd:p>
      <xd:p><xd:b>Author:</xd:b> pfennell</xd:p>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output encoding="UTF-8" indent="yes" media-type="application/xhtml+xml" method="xhtml"/>
  
  <!--<xsl:strip-space elements="*"/>-->
  
  
  <xd:doc></xd:doc>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>News: Search Results</title>
      </head>
      <body>
        <xsl:apply-templates select="search:response" mode="search"/>
      </body>
    </html>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="search:response" mode="search">
    <div>
      <h1>Results</h1>
      <ul>
        <xsl:apply-templates select="search:result" mode="#current"/>
      </ul>
    </div>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="search:result" mode="search">
    <li>
      <xsl:apply-templates select="search:snippet" mode="snippet"/>
    </li>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="search:match[1]" mode="snippet">
    <p><a href="news-item" title="Go to News Item..."><xsl:apply-templates select="* | text()" mode="#current"/></a></p>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="search:match" mode="snippet">
    <p><xsl:apply-templates select="* | text()" mode="#current"/></p>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="search:highlight" mode="snippet">
    <em><xsl:value-of select="text()"/></em>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="text()" mode="snippet">
    <xsl:copy-of select="."/>
  </xsl:template>
  
</xsl:stylesheet>