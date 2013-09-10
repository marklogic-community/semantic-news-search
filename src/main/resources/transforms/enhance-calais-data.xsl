<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform 
    xmlns:c="http://s.opencalais.com/1/pred/"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:es="http://www.marklogic.com/enhanced-search#"
    xmlns:oc="http://s.opencalais.com/1/pred/"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
    version="2.0"
    xpath-default-namespace="http://www.w3.org/1999/xhtml">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 28, 2013</xd:p>
      <xd:p><xd:b>Author:</xd:b> pfennell</xd:p>
      <xd:p>Enhance RDF extracted by OpenCalais.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:param name="URI" as="xs:string"/>
  
  <xsl:output encoding="UTF-8" indent="yes" media-type="application/xml" method="xml"/>
  
  <xsl:strip-space elements="*"/>
  
  
  <xd:doc>Root.</xd:doc>
  <xsl:template match="/">
    <xsl:apply-templates select="*" mode="enhance"/>
  </xsl:template>
  
  
  <xd:doc>Descriptions of things.</xd:doc>
  <xsl:template match="rdf:Description" mode="enhance">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="properties"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Known to be dates.</xd:doc>
  <xsl:template match="oc:date | oc:docDate" mode="properties" priority="2">
    <xsl:copy>
      <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#date</xsl:attribute>
      <xsl:apply-templates select="* | text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Known to be numeric values.</xd:doc>
  <xsl:template match="oc:latitude | oc:longitude | oc:score | oc:relevance" mode="properties" priority="2">
    <xsl:copy>
      <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#double</xsl:attribute>
      <xsl:apply-templates select="* | text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Copy as-is.</xd:doc>
  <xsl:template match="*[@rdf:resource] | *[@rdf:datatype] | *[@xml:lang]" mode="properties" priority="1">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Fallback - duplicate.</xd:doc>
  <xsl:template match="*" mode="properties">
    <xsl:copy>
      <!--<xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#string</xsl:attribute>-->
      <xsl:apply-templates select="* | text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Add a sameAs assertion to link OpenCalais to source BBC NewsItem.</xd:doc>
  <xsl:template match="rdf:Description[rdf:type/@rdf:resource eq 'http://s.opencalais.com/1/type/sys/DocInfo']" mode="enhance">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="properties"/>
      <owl:sameAs rdf:resource="{$URI}"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xd:doc>Ignore</xd:doc>
  <xsl:template match="*[not(exists(@*))][not(exists(* | text()))]" mode="properties" priority="3"/>
  
  <!--
  <xd:doc>Remove.</xd:doc>
  <xsl:template match="rdf:Description[rdf:type/@rdf:resource eq 'http://s.opencalais.com/1/type/sys/RelevanceInfo']" mode="enhance" priority="1"/>
  -->
  
  <xd:doc>Remove.</xd:doc>
  <xsl:template match="rdf:Description[rdf:type/@rdf:resource eq 'http://s.opencalais.com/1/type/sys/InstanceInfo']" mode="enhance" priority="1"/>
  
  <xd:doc>Remove.</xd:doc>
  <xsl:template match="rdf:Description[rdf:type/@rdf:resource eq 'http://s.opencalais.com/1/type/em/r/Quotation']" mode="enhance" priority="1"/>
  
  <xd:doc>Remove.</xd:doc>
  <xsl:template match="rdf:Description/oc:document" mode="properties" priority="1"/> 
  
  
  <xd:doc>Fallback, replicate node, attributes and its children.</xd:doc>
  <xsl:template match="*" mode="enhance">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="* | text()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:transform>