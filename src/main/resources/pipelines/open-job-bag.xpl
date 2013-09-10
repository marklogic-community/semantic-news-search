<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
    xmlns:c="http://www.w3.org/ns/xproc-step" 
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:es="http://www.marklogic.com/enhanced-search#"
    xmlns:oc="http://s.opencalais.com/1/pred/"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rnews="http://iptc.org/std/rNews/2011-10-07#"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xml:base="../../../../data/"
    name="open-job-bag"
    version="1.0">
  
  <p:variable name="FEED_PATH" select="'archive/news/'"/>
  <p:variable name="BASE_URI" select="'http://www.bbc.co.uk'"/>
  
  
  <p:directory-list include-filter=".*\.xml$">
    <p:with-option name="path" select="$FEED_PATH"/>
  </p:directory-list>
  
  <p:for-each>
    <p:iteration-source select="/c:directory/c:file"/>
    
    <p:variable name="name" select="substring-before(/c:file/@name, '.xml')"/>
    
    <p:make-absolute-uris match="/c:file/@name"/>
    
    <p:load name="job-bag">
      <p:with-option name="href" select="/c:file/@name"/>
    </p:load>
    
    <p:store encoding="UTF-8" indent="true" media-type="application/xhtml+xml" 
        method="xml" omit-xml-declaration="false">
      <p:with-option name="href" select="concat('ingest/content/', $name, '.xml')"/>
      <p:input port="source" select="/es:job-bag/xhtml:html">
        <p:pipe port="result" step="job-bag"/>
      </p:input>
    </p:store>
    
    <p:store encoding="UTF-8" indent="true" media-type="application/rdf+xml" 
        method="xml" omit-xml-declaration="false">
      <p:with-option name="href" select="concat('ingest/graph/', $name, '.rdf')"/>
      <p:input port="source" select="/es:job-bag/rdf:RDF">
        <p:pipe port="result" step="job-bag"/>
      </p:input>
    </p:store>
    
  </p:for-each>
</p:declare-step>