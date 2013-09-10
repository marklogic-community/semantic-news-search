<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
    xmlns:c="http://www.w3.org/ns/xproc-step" 
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:es="http://www.marklogic.com/enhanced-search#"
    xmlns:oc="http://s.opencalais.com/1/pred/"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    name="enrich-news-pages" 
    version="1.0">
  
  <!--<p:input port="source" sequence="true"/>-->
  <!--<p:output port="result"/>
  
  <p:serialization port="result" encoding="utf-8" method="xml" 
      omit-xml-declaration="false" indent="true"/>-->
  
  <p:variable name="FEED_PATH" select="'../../../../data/feeds/'"/>
  
  <p:variable name="BASE_URI" select="'http://www.bbc.co.uk'"/>
  <p:variable name="SERVICE_URI" select="'http://api.opencalais.com/enlighten/rest/'"/>
  <p:variable name="SERVICE_KEY" select="'whvrukc7wah3t2up4v9afwft'"></p:variable>
  
  
  <p:directory-list include-filter=".*\.xml$">
    <p:with-option name="path" select="$FEED_PATH"/>
  </p:directory-list>
  
  <p:make-absolute-uris match="/c:directory/c:file/@name"/>
  
  <p:for-each>
    <p:iteration-source select="/c:directory/c:file"/>
    
    <p:load>
      <p:with-option name="href" select="/c:file/@name"/>
    </p:load>
    
    <p:for-each>
      <p:iteration-source select="/rss/channel/item"/>
      
      <p:variable name="url" select="/item/guid/string()"/>
      
      <p:try>
        <p:group>
          <p:identity>
            <p:input port="source">
              <p:inline>
                <c:request method="GET"/>
              </p:inline>
            </p:input>
          </p:identity>
      
          <p:add-attribute name="feed-request" match="/c:request" attribute-name="href">
            <p:with-option name="attribute-value" select="$url"/>
          </p:add-attribute>
      
          <p:http-request name="feed-response">
            <p:documentation>Retrieve the story referenced by the feed item/entry.</p:documentation>
          </p:http-request>
      
          <p:exec command="tidy" source-is-xml="false" result-is-xml="false" 
              wrap-result-lines="false" method="xml">
            <p:documentation>Apply HTML Tidy to the response HTML.</p:documentation>
            <p:with-option name="args" 
                select="'--quiet yes --show-warnings no --doctype omit --numeric-entities yes --output-xml yes'"/>
          </p:exec>
          <p:unescape-markup name="html"/>
          <p:unwrap name="web-page" match="c:result"/>
      
          <p:xslt name="cleaned-page">
            <p:documentation>Throw away the unnecessary website content/structure.</p:documentation>
            <p:input port="stylesheet">
              <p:document href="../transforms/clean-story.xsl"/>
            </p:input>
            <p:input port="parameters">
              <p:empty/>
            </p:input>
            <p:with-param name="URL" select="$url"/>
            <p:with-param name="BASE_URI" select="$BASE_URI"/>
          </p:xslt>
      
          <p:filter select="/xhtml:html/xhtml:body/xhtml:div[@class = 'story-body']"/>
          <p:wrap-sequence wrapper="c:data"/>
          <p:escape-markup name="story" indent="false"/>
          
          <p:sink/>
          
          <p:escape-markup name="service-params">
            <p:documentation>Convert the OpenCalais XML parameter fragment into a string.</p:documentation>
            <p:input port="source">
<p:inline exclude-inline-prefixes="#all"><c:data><oc:params xmlns:oc="http://s.opencalais.com/1/pred/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <oc:processingDirectives oc:contentType="TEXT/HTML" oc:outputFormat="xml/rdf" oc:docRDFaccesible="false" oc:allowDistribution="false"/> 
  <oc:userDirectives oc:allowDistribution="true" oc:allowSearch="false" oc:externalID="mluces" oc:submitter="ml"/> 
  <oc:externalMetadata/> 
</oc:params></c:data></p:inline>
            </p:input>
          </p:escape-markup>
          
          <p:xslt name="calais-request">
            <p:documentation>Build the OpenCalais REST API request.</p:documentation>
            <p:input port="source">
              <p:inline exclude-inline-prefixes="#all"><c:request method="POST">
                <c:body content-type="application/x-www-form-urlencoded">licenseID=&amp;content=&amp;paramsXML=</c:body>
              </c:request></p:inline>
            </p:input>
            <p:input port="stylesheet">
              <p:inline>
                <xsl:transform 
                    xmlns:c="http://www.w3.org/ns/xproc-step" 
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                    version="2.0">
                  <xsl:output encoding="UTF-8" indent="no" media-type="application/xml" method="xml"/>
                  <xsl:param name="SERVICE_URI" as="xs:string"/>
                  <xsl:param name="SERVICE_KEY" as="xs:string"/>
                  <xsl:param name="SERVICE_PARAMS" as="xs:string"/>
                  <xsl:param name="CONTENT" as="xs:string"/>
                  
                  <xsl:template match="/c:request">
                    <xsl:copy>
                      <xsl:copy-of select="@*"/>
                      <xsl:attribute name="href" select="$SERVICE_URI"/>
                      <xsl:apply-templates select="*"/>
                    </xsl:copy>
                  </xsl:template>
                  
                  <xsl:template match="c:body">
                    <xsl:copy>
                      <xsl:copy-of select="@*"/>
                      <xsl:text>licenseID=</xsl:text><xsl:value-of select="$SERVICE_KEY"/>
                      <xsl:text>&amp;content=</xsl:text><xsl:value-of select="$CONTENT"/>
                      <xsl:text>&amp;paramsXML=</xsl:text><xsl:value-of select="$SERVICE_PARAMS"/>
                    </xsl:copy>
                  </xsl:template>
                </xsl:transform>
              </p:inline>
            </p:input>
            <p:input port="parameters"><p:empty/></p:input>
            <p:with-param name="SERVICE_URI" select="$SERVICE_URI"/>
            <p:with-param name="SERVICE_KEY" select="$SERVICE_KEY"/>
            <p:with-param name="SERVICE_PARAMS" select="encode-for-uri(/c:data/string())">
              <p:pipe port="result" step="service-params"/>
            </p:with-param>
            <p:with-param name="CONTENT" select="encode-for-uri(/c:data/string())">
              <p:pipe port="result" step="story"/>
            </p:with-param>
          </p:xslt>
          
          <p:http-request name="calais-response"/>
          
          <p:xslt name="extracted-terms">
            <p:input port="stylesheet">
              <p:document href="../transforms/enhance-calais-data.xsl"/>
            </p:input>
            <p:input port="parameters">
              <p:empty/>
            </p:input>
            <p:with-param name="URI" select="$url"/>
          </p:xslt>
          
          <p:sink/>
          
          <p:xslt name="metadata">
            <p:documentation>Extract RDF metadata embedded in the web page.</p:documentation>
            <p:input port="source">
              <p:pipe port="result" step="cleaned-page"/>
            </p:input>
            <p:input port="stylesheet">
              <p:document href="../transforms/story-to-rdf.xsl"/>
            </p:input>
            <p:input port="parameters">
              <p:empty/>
            </p:input>
          </p:xslt>
          
          <p:insert name="graph" match="/rdf:RDF" position="last-child">
            <p:documentation>Merge OpenCalais and Web Page RDF statements.</p:documentation>
            <p:input port="source">
              <p:pipe port="result" step="metadata"/>
            </p:input>
            <p:input port="insertion" select="/rdf:RDF/*">
              <p:pipe port="result" step="extracted-terms"/>
            </p:input>
          </p:insert>
          
          <p:wrap-sequence wrapper="es:job-bag">
            <p:documentation>Create a container for the graph and content.</p:documentation>
            <p:input port="source">
              <p:pipe port="result" step="cleaned-page"/>
              <p:pipe port="result" step="graph"/>
            </p:input>
          </p:wrap-sequence>
          
          <p:choose>
            <p:documentation>Only save those jobs that have content.</p:documentation>
            <p:when test="exists(/es:job-bag/xhtml:html/xhtml:body/*)">
              <p:store encoding="UTF-8" indent="true" media-type="application/xhtml+xml" 
                  method="xml" omit-xml-declaration="false">
                <p:with-option name="href" select="concat('../../../../data/enriched', substring-after($url, $BASE_URI), '.xml')"/>
              </p:store>
            </p:when>
            <p:otherwise>
              <p:sink/>
            </p:otherwise>
          </p:choose>
        </p:group>
        <p:catch>
          <p:sink/>
        </p:catch>
      </p:try>
      
    </p:for-each>
    
  </p:for-each>
  
  <!--<p:wrap-sequence wrapper="c:results"/>-->
</p:declare-step>
