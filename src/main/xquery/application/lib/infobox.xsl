<!-- This stylesheet controls the display of the infobox,
     using $infobox:data (defined in infobox.xqy) as the input -->
<!DOCTYPE xsl:stylesheet [
<!ENTITY foaf "http://xmlns.com/foaf/0.1/">
<!ENTITY prop "http://dbpedia.org/property/">
<!ENTITY dbpo "http://dbpedia.org/ontology/">
<!ENTITY dbpdt "http://dbpedia.org/datatype/">
<!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
<!ENTITY rdf  "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<!ENTITY xs   "http://www.w3.org/2001/XMLSchema#">
]>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:mt="http://marklogic.com/sem-app/templates"
  xmlns:data="http://marklogic.com/sem-app/data"
  xmlns:infobox="http://marklogic.com/sem-app/infobox"
  xmlns:sem="http://marklogic.com/semantics"
  exclude-result-prefixes="xs sem mt data xdmp infobox">

  <xdmp:import-module href="/lib/infobox.xqy" namespace="http://marklogic.com/sem-app/infobox"/>

  <!-- For each supported resource type (Company or Country),
       configure what properties we want to display in the infobox. -->
  <xsl:variable name="infobox-configs" as="element()+">
    <config type="&dbpo;Company">
      <image iri="&foaf;depiction"/>
      <list>
        <prop iri="&prop;companyName"      >Name</prop>
        <prop iri="&foaf;homepage" link="yes">Home page</prop>
        <prop iri="&prop;locationCountry"  >Country</prop>
        <prop iri="&dbpo;numberOfEmployees"># employees</prop>
        <prop iri="&dbpo;foundingYear"     >Founding year</prop>

        <prop iri="&prop;equity"           >Equity</prop>
        <prop iri="&prop;assets"           >Assets</prop>
        <prop iri="&prop;revenue"          >Revenue</prop>
        <prop iri="&prop;netIncome"        >Net Income</prop>

        <prop iri="&rdfs;comment" lang="en">Summary</prop>
      </list>
    </config>
    <config type="&dbpo;Country">
      <image iri="&foaf;depiction"/>
      <list>
        <prop iri="&prop;commonName"       >Country</prop>
        <prop iri="&prop;currency"         >Currency</prop>
        <prop iri="&prop;officialLanguages">Language</prop>
        <prop iri="&prop;governmentType"   >Government</prop>
        <prop iri="&prop;populationCensus" >Population</prop>
      </list>
    </config>
  </xsl:variable>

  <xsl:template match="mt:infobox">
    <!-- Which type of resource is this? -->
    <xsl:variable name="infobox-type"
                  select="$infobox-configs/@type[. = $infobox:data/sem:triple
                                                                   [sem:predicate eq '&rdf;type']
                                                                  /sem:object
                                                ]"/>

    <!-- Process the corresponding config children -->
    <xsl:apply-templates mode="infobox" select="$infobox-configs[@type is $infobox-type]/*"/>

    <xsl:if test="$infobox:data/*">
      <p><a href="/search/infobox.xqy?q={$data:q}&amp;format=xml">View RDF triples</a></p>
    </xsl:if>
  </xsl:template>

          <!-- Render property lists as definition lists -->
          <xsl:template mode="infobox" match="list">
            <dl>
              <xsl:apply-templates mode="#current"/>
            </dl>
          </xsl:template>

          <!-- Render an individual image or property -->
          <xsl:template mode="infobox" match="image | prop">
            <xsl:variable name="prop-config" select="."/>
            <!-- Find and render the relevant triple elements for this property -->
            <xsl:for-each select="$infobox:data/sem:triple[sem:predicate        eq $prop-config/@iri]
                                                      [not(sem:object/@xml:lang != $prop-config/@lang)]">
              <xsl:apply-templates mode="render-object" select="$prop-config">
                <xsl:with-param name="object" select="sem:object"/>
              </xsl:apply-templates>
            </xsl:for-each>
          </xsl:template>

                  <xsl:template mode="render-object" match="prop">
                    <xsl:param name="object"/>
                    <dt>
                      <xsl:value-of select="."/>
                    </dt>
                    <dd>
                      <xsl:apply-templates mode="#current" select="$object">
                        <xsl:with-param name="prop-config" select="."/>
                      </xsl:apply-templates>
                    </dd>
                  </xsl:template>

                          <!-- Render just the last part of IRIs that appear as objects -->
                          <xsl:template mode="render-object" match="sem:object[not(@*)]">
                            <xsl:value-of select="translate(tokenize(.,'/')[last()],'_',' ')"/>
                          </xsl:template>

                          <!-- The "year" format doesn't always appear as advertised (might include a full dateTime) -->
                          <xsl:template mode="render-object" match="sem:object[@datatype eq '&xs;gYear']">
                            <xsl:value-of select="substring(.,1,4)"/> 
                          </xsl:template>

                          <!-- Format numbers and monetary amounts -->

                          <xsl:template mode="render-object" match="sem:object[@datatype eq '&dbpdt;usDollar']">
                            <xsl:value-of select="format-number(xs:float(.), '$#,###', 'grouped')"/>
                          </xsl:template>

                          <xsl:template mode="render-object" match="sem:object[@datatype eq '&dbpdt;euro']">
                            <xsl:value-of select="format-number(xs:float(.), '&#8364;#,###', 'grouped')"/> <!-- Euro symbol -->
                          </xsl:template>

                          <xsl:template mode="render-object" match="sem:object[@datatype = ('&xs;int','&xs;integer')]">
                            <xsl:value-of select="format-number(xs:float(.), '#,###', 'grouped')"/>
                          </xsl:template>

                                  <xsl:decimal-format name="grouped"
                                    decimal-separator="."
                                    grouping-separator=","/>


                          <!-- Render URLs as clickable links -->
                          <xsl:template mode="render-object" match="sem:object">
                            <xsl:param name="prop-config"/>
                            <xsl:choose>
                              <xsl:when test="$prop-config/@link">
                                <a href="{.}">
                                  <xsl:value-of select="."/>
                                </a>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="."/>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:template>

                  <xsl:template mode="render-object" match="image">
                    <xsl:param name="object"/>
                    <img src="{$object}"/>
                  </xsl:template>

</xsl:stylesheet>
