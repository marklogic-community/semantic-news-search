<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
		xmlns:c="http://www.w3.org/ns/xproc-step"
		xmlns:p="http://www.w3.org/ns/xproc"
		xmlns:xhtml="http://www.w3.org/1999/xhtml"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		name="news-pages"
    version="1.0">
	
	<p:input port="source"/>
	<!--<p:output port="result"/>
	
	<p:serialization port="result" encoding="utf-8" method="xml"
			omit-xml-declaration="false" indent="true"/>-->
	
  <p:variable name="BASE_URI" select="'http://www.bbc.co.uk'"/>
  
	
	<p:for-each>
	  <p:iteration-source select="/rss/channel/item"/>
	  
	  <p:variable name="url" select="/item/guid/string()"/>
	  
	  <p:identity>
	    <p:input port="source">
	      <p:inline><c:request method="GET"/></p:inline>
	    </p:input>
	  </p:identity>
	  
	  <p:add-attribute match="/c:request" attribute-name="href">
	    <p:with-option name="attribute-value" select="$url"/>
	  </p:add-attribute>
	  
	  <p:http-request/>
	
  	<p:exec command="tidy"
  			source-is-xml="false"
  			result-is-xml="false"
  			wrap-result-lines="false"
  			method="xml">
  		<p:with-option name="args" select="'--quiet yes --show-warnings no --doctype omit --numeric-entities yes --output-xml yes'"/>
  	</p:exec>
  	
	  <p:unescape-markup name="html"/>
	  
	  <p:unwrap name="web-page" match="c:result"/>
	  
	  <p:try>
      <p:group>
        <!--
	      <p:xslt>
	        <p:input port="stylesheet">
	          <p:document href="../transforms/clean-story.xsl"/>
	        </p:input>
	        <p:input port="parameters">
	          <p:empty/>
	        </p:input>
	        <p:with-param name="URL" select="$url"/>
	        <p:with-param name="BASE_URI" select="$BASE_URI"/>
	      </p:xslt>
	      -->
	      <p:store encoding="UTF-8" indent="true" media-type="application/xhtml+xml" 
	         method="xml" omit-xml-declaration="false">
	        <p:with-option name="href" select="concat('../../../../data', substring-after($url, $BASE_URI), '.xml')"/>
	      </p:store>
	      
	    </p:group>
	    <p:catch>
	      <p:sink/>
	    </p:catch>
	  </p:try>
	  
	</p:for-each>
	
	<!--<p:wrap-sequence wrapper="c:results"/>-->
</p:declare-step>
