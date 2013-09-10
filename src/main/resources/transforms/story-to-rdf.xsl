<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:es="http://www.marklogic.com/enhanced-search#"
    xmlns:og="http://opengraphprotocol.org/schema/"
    xmlns:rnews="http://iptc.org/std/rNews/2011-10-07#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:sem="http://marklogic.com/semantics"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
    version="2.0"
    xpath-default-namespace="http://www.w3.org/1999/xhtml">
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 24, 2013</xd:p>
      <xd:p><xd:b>Author:</xd:b> pfennell</xd:p>
      <xd:p>Transform news story into an RDF graph data as RDF/XML</xd:p>
    </xd:desc>
  </xd:doc>
  
  
  <xsl:output encoding="UTF-8" indent="yes" media-type="application/xml" method="xml"/>
  
  <xsl:strip-space elements="*"/>
  
  
  <xd:doc>Root</xd:doc>
  <xsl:template match="/">
    <xsl:apply-templates select="*" mode="sem:triples"/>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="html" mode="sem:triples">
    <xsl:variable name="sem:subject" as="xs:anyURI" select="head/@resource"/>
    
    <rdf:RDF xmlns:es="http://www.marklogic.com/enhanced-search#">
      <xsl:for-each select="namespace::* except (namespace::xml, namespace::c, namespace::*[name() eq ''])">
        <xsl:namespace name="{name()}"><xsl:value-of select="."/></xsl:namespace>
      </xsl:for-each>
      <xsl:apply-templates select="*" mode="#current">
        <xsl:with-param name="sem:subject" as="xs:anyURI" select="$sem:subject" tunnel="yes"/>
      </xsl:apply-templates>
    </rdf:RDF>
  </xsl:template>
  
  
  <xd:doc>Set the type of thing as an rnews:Article.</xd:doc>
  <xsl:template match="head" mode="sem:triples">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    
    <rdf:Description rdf:about="{$sem:subject}">
      <xsl:copy-of select="rdf:make-triple('rdf:type', sem:curie-expand(@typeof/string()), (), ())"/>
      <xsl:copy-of select="rdf:make-triple('rnews:identifier', @resource, (), ())"/>
      <xsl:copy-of select="rdf:make-triple('rnews:usageTerms', link[@rel = 'copyright']/@href/string(), (), ())"/>
      <xsl:apply-templates select="meta" mode="sem:triples"/>
    </rdf:Description>
  </xsl:template>
  
  
  <xd:doc></xd:doc>
  <xsl:template match="body" mode="sem:triples">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    
    <xsl:apply-templates select="div[@class = 'story-body']//*" mode="associatedMedia"/>
  </xsl:template>
  
  
  <xd:doc>Description.</xd:doc>
  <xsl:template match="meta[@property eq 'rnews:description']" mode="sem:triples" priority="1">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    
    <xsl:copy-of select="rdf:make-triple(@property, @content, /html/@xml:lang, ())"/>
  </xsl:template>
  
  
  <xd:doc>Section.</xd:doc>
  <xsl:template match="meta[@name eq 'CPS_SECTION_PATH']" mode="sem:triples" priority="1">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    <xsl:variable name="section" as="xs:string" select="if (starts-with(@content/string(), 'World/')) then 'World' else @content"/>
    
    <xsl:copy-of select="rdf:make-triple('rnews:articleSection', $section, (), 'http://www.w3.org/2001/XMLSchema#string')"/>
  </xsl:template>
  
  
  <xd:doc>Headline.</xd:doc>
  <xsl:template match="meta[@property eq 'rnews:headline']" mode="sem:triples" priority="1">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    
    <xsl:copy-of select="rdf:make-triple(@property, @content, /html/@xml:lang, ())"/>
  </xsl:template>
  
  
  <xd:doc>Date Published.</xd:doc>
  <xsl:template match="meta[@property eq 'rnews:datePublished']" mode="sem:triples" priority="1">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    
    <xsl:copy-of select="rdf:make-triple(@property, @content, (), 'http://www.w3.org/2001/XMLSchema#dateTime')"/>
  </xsl:template>
  
  
  <xd:doc>Fallback.</xd:doc>
  <xsl:template match="meta[starts-with(@property, 'rnews')]" mode="sem:triples">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    
    <xsl:copy-of select="rdf:make-triple(@property, @content, (), ())"/>
  </xsl:template>
  
  
  <xd:doc>Story images.</xd:doc>
  <xsl:template match="img" mode="associatedMedia">
    <xsl:param name="sem:subject" as="xs:anyURI" tunnel="yes"/>
    <xsl:variable name="associatedMediaURI" as="xs:string" select="@src"/>
    
    <rdf:Description rdf:about="{@src}">
      <xsl:copy-of select="rdf:make-triple('rdf:type', 'http://iptc.org/std/rNews/2011-10-07#ImageObject', (), ())"/>
      <xsl:copy-of select="rdf:make-triple('rnews:associatedArticle', $sem:subject, (), ())"/>
      <xsl:if test="@width">
        <xsl:copy-of select="rdf:make-triple('rnews:width', @width, (), 'http://www.w3.org/2001/XMLSchema#integer')"/>
      </xsl:if>
      <xsl:if test="@height">
        <xsl:copy-of select="rdf:make-triple('rnews:height', @height, (), 'http://www.w3.org/2001/XMLSchema#integer')"/>
      </xsl:if>
      <xsl:copy-of select="rdf:make-triple('rnews:description', @alt, /html/@xml:lang, ())"/>
      <xsl:copy-of select="rdf:make-triple('rnews:encodingFormat', 'http://cv.iptc.org/newscodes/format/JPEG_Baseline', (), ())"/>
    </rdf:Description>
  </xsl:template>
  
  
  <xd:doc>Ignore everything else.</xd:doc>
  <xsl:template match="*" mode="sem:triples associatedMedia"/>
  
  
  <xd:doc>Create an m-triple.</xd:doc>
  <xsl:function name="rdf:make-triple" as="element()">
    <xsl:param name="predicate" as="xs:string"/>
    <xsl:param name="object" as="item()"/>
    <xsl:param name="lang" as="xs:string?" />
    <xsl:param name="type" as="xs:string?"/>
    
    <xsl:element name="{$predicate}">
      <xsl:choose>
        <xsl:when test="string-length($lang) gt 0">
          <xsl:attribute name="xml:lang" select="$lang"/>
          <xsl:value-of select="string($object)"/>
        </xsl:when>
        <xsl:when test="string-length($type) gt 0">
          <xsl:attribute name="rdf:datatype" select="$type"/>
          <xsl:value-of select="string($object)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="rdf:resource" select="$object"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:function>
  
  
  <xd:doc>Expands a curie into a fully qualified QName.</xd:doc>
  <xsl:function name="sem:curie-expand" as="xs:string">
    <xsl:param name="curie" as="xs:string"/>
    <xsl:variable name="prefix" as="xs:string" select="substring-before($curie, ':')"/>
    <xsl:variable name="element" as="element()">
      <xsl:element name="{$curie}"/>
    </xsl:variable>
    
    <xsl:value-of select="replace($curie, concat($prefix, ':'), namespace-uri-for-prefix($prefix, $element))"/>
  </xsl:function>
  
</xsl:transform>