<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:es="http://www.marklogic.com/enhanced-search#"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="c xd xs"
    version="2.0"
    xpath-default-namespace="http://www.w3.org/1999/xhtml">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 24, 2013</xd:p>
      <xd:p><xd:b>Author:</xd:b> pfennell</xd:p>
      <xd:p>Cleans a BBC News story.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:param name="URL" as="xs:string?" select="/html/head/@resource"/>
  <xsl:param name="BASE_URI" as="xs:string?" select="'http://www.bbc.co.uk'"/>
  
  <xsl:output encoding="UTF-8" indent="yes" media-type="application/xml" method="xml"/>
  
  <xsl:strip-space elements="*"/>
  
  
  <xd:doc>Root.</xd:doc>
  <xsl:template match="/">
    <xsl:apply-templates select="*" mode="clean-story"/>
  </xsl:template>
  
  
  <xd:doc>Maintain the XHTML wrapper.</xd:doc>
  <xsl:template match="html" mode="clean-story">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:base" select="$BASE_URI"/>
      <xsl:apply-templates select="head" mode="metadata"/>
      <xsl:apply-templates select="body" mode="clean-story"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Keep rNews metadata.</xd:doc>
  <xsl:template match="head" mode="metadata">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="meta" mode="#current"/>
      <xsl:copy-of select="link[@rel = 'copyright']"/>
      <link rel="http://purl.org/dc/terms/source" href="{$URL}"/>
      <xsl:copy-of select="title"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Reformat datePublished.</xd:doc>
  <xsl:template match="meta[contains(@property, 'rnews:datePublished')]" mode="metadata" priority="1">
    <xsl:copy>
      <xsl:copy-of select="@* except (@content)"/>
      <xsl:attribute name="content">
        <xsl:variable name="date" select="substring-before(@content, ' ')"/>
        <xsl:variable name="time" select="substring-after(@content, ' ')"/>
        <xsl:value-of select="concat(translate($date, '/', '-'), 'T', $time)"/>
      </xsl:attribute>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Select only rNews metadata.</xd:doc>
  <xsl:template match="meta[contains(@property, 'rnews:')]" mode="metadata">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  
  <xd:doc>Select news section.</xd:doc>
  <xsl:template match="meta[@name eq 'CPS_SECTION_PATH'] " mode="metadata">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  
  <xd:doc>Keep the body container.</xd:doc>
  <xsl:template match="body" mode="clean-story">
    <xsl:copy>
      <xsl:apply-templates select="descendant::div[@class = 'story-body']" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Select only the story content.</xd:doc>
  <xsl:template match="div[@class = 'story-body']" mode="clean-story">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*" mode="#current"/>
    </xsl:copy>
    <xsl:apply-templates select="*" mode="move-feature"/>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <!--<xsl:template match="div[contains(@class, 'layout-block-a')]" mode="clean-story">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <a rel="http://purl.org/dc/terms/source" href="{$URL}">Source</a>
      <xsl:apply-templates select="*" mode="#current"/>
    </xsl:copy>
  </xsl:template>-->
  
  
  <xd:doc>Remove script elements.</xd:doc>
  <xsl:template match="script" mode="clean-story"/>
  
  
  <xd:doc>Remove social media links.</xd:doc>
  <xsl:template match="div[@id eq 'page-bookmark-links-head']" mode="clean-story"/>
  
  
  <xd:doc>Remove feature inserts (will be inserted at the end.</xd:doc>
  <xsl:template match="div[starts-with(@class/string(), 'story-feature')]" mode="clean-story"/>
  
  
  <xd:doc>Remove related links (will be inserted at the end.</xd:doc>
  <xsl:template match="div[starts-with(@class/string(), 'embedded-hyper')]" mode="clean-story"/>
  
  
  <xd:doc>Remove related in-line video clips but extract place-holder image.</xd:doc>
  <xsl:template match="div[starts-with(@class/string(), 'videoInStory')]" mode="clean-story">
    <xsl:copy>
      <xsl:copy-of select="descendant::img"/>
        <xsl:copy-of select="descendant::p[@class = 'caption']"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Remove cross headings (minor sub headings).</xd:doc>
  <xsl:template match="span[@class eq 'cross-head']" mode="clean-story"/>
  
  
  <xd:doc>Remove hidden links.</xd:doc>
  <xsl:template match="a[@class eq 'hidden']" mode="clean-story"/>
  
  
  <xd:doc>Remove empty elements (with nbsp white space).</xd:doc>
  <!--<xsl:template match="*[string-length(string()) eq 1][text() = '&#160;']" mode="clean-story"/>-->
  
  
  <xd:doc>Remove unwanted id attributes in paragraphs.</xd:doc>
  <xsl:template match="p" mode="clean-story">
    <xsl:copy>
      <xsl:copy-of select="@* except (@id)"/>
      <xsl:apply-templates select="* | text()" mode="clean-story"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Move feature inserts.</xd:doc>
  <xsl:template match="div[starts-with(@class/string(), 'story-feature')]" mode="move-feature" priority="1">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="clean-story"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Move related links.</xd:doc>
  <xsl:template match="div[starts-with(@class/string(), 'embedded-hyper')]" mode="move-feature" priority="1">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="clean-story"/>
    </xsl:copy>
  </xsl:template>
  
    
  
  <xd:doc>Ignore other nodes in this mode.</xd:doc>
  <xsl:template match="*" mode="move-feature"/>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="*" mode="clean-story">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
</xsl:transform>