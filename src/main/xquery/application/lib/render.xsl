<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:mt="http://marklogic.com/sem-app/templates"
  xmlns:data="http://marklogic.com/sem-app/data"
  xmlns:search="http://marklogic.com/appservices/search"
  xmlns:replace="http://marklogic.com/sem-app/replace-att"
  xmlns:my="http://localhost"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs xdmp mt data search my replace">

  <!-- See http://www.w3.org/TR/html5/syntax.html#the-doctype and http://www.w3.org/html/wg/tracker/issues/54 -->
  <xsl:output doctype-system="about:legacy-compat"
              omit-xml-declaration="yes"/>

  <xdmp:import-module href="/lib/data-access.xqy" namespace="http://marklogic.com/sem-app/data"/>
  <xdmp:import-module href="/MarkLogic/appservices/search/search.xqy" namespace="http://marklogic.com/appservices/search"/>

  <!-- Apparently, MarkLogic is only happy if we import this here (it's insufficient to import it in the included stylesheet) -->
  <xdmp:import-module href="/lib/infobox.xqy" namespace="http://marklogic.com/sem-app/infobox"/>

  <xsl:include href="infobox.xsl"/>

  <xsl:variable name="q" select="xdmp:get-request-field('q','')"/>

  <!-- These are lazily evaluated -->
  <xsl:variable name="results" select="data:get('results')"/>

  <xsl:variable name="facet-names" select="('cat','org')"/>

  <!-- Show the query used to find these results -->
  <xsl:template match="mt:query-used">
    <!-- show the query as XML
    <xsl:variable name="query-doc">
      <xsl:copy-of select="$data:ctsQuery"/>
    </xsl:variable>
    <xsl:value-of select="xdmp:quote($query-doc/*)"/>
    -->
    <!-- Show the query constructors -->
    <xsl:value-of select="$data:ctsQuery"/>
  </xsl:template>

  <!-- Total result count -->
  <xsl:template match="mt:result-count">
    <xsl:value-of select="$results/@total"/>
  </xsl:template>

  <!-- Pre-select the relevant sort option -->
<!--
  <xsl:template match="select[@mt:sortbox eq 'yes']/option/@mt:selected">
    <xsl:if test="../@value eq $data:current-sort-order">
      <xsl:attribute name="selected" select="'selected'"/>
    </xsl:if>
  </xsl:template>
-->


  <!-- Let the next rule copy @class when @mt:selected-class is also present -->
  <xsl:template mode="#default repeating" match="@class[../@mt:selected-class]"/>

  <xsl:template mode="#default repeating" match="@mt:selected-class">
    <xsl:param name="selected" tunnel="yes"/>
    <xsl:param name="keep-annotation" tunnel="yes"/>
    <xsl:if test="$selected or ../@class">
      <xsl:attribute name="class" select="concat(../@class,' ',
                                                 if ($selected) then string(.) else '')"/>
    </xsl:if>
    <!-- If needed during further post-processing -->
    <xsl:if test="$keep-annotation">
      <xsl:copy/>
    </xsl:if>
  </xsl:template>


  <!-- Populate the search box -->
  <xsl:template match="input[@name eq 'q']/@mt:value">
    <xsl:attribute name="value">
      <xsl:value-of select="$data:q"/> 
    </xsl:attribute>
  </xsl:template>

  <!-- Post-process the facet lists to auto-expand when a descendant value is selected -->
  <xsl:template match="*[@mt:expanded-class]">
    <xsl:variable name="intermediate-result">
      <xsl:next-match>
        <xsl:with-param name="keep-annotation" select="true()" tunnel="yes"/>
      </xsl:next-match>
    </xsl:variable>
    <xsl:apply-templates mode="expand-menus" select="$intermediate-result"/>
  </xsl:template>

          <!-- Keep these annotations around until the post-processing stage -->
          <xsl:template match="@mt:expanded-class">
            <xsl:copy/>
          </xsl:template>

          <!-- Let the next rule copy @class when @mt:expanded-class is also present -->
          <xsl:template mode="expand-menus" match="@class[../@mt:expanded-class]"/>

          <!-- Add class="{expanded}" when a descendant facet value is selected -->
          <xsl:template mode="expand-menus" match="@mt:expanded-class">
            <xsl:variable name="contains-selected" select="..//li[my:is-facet-value-selected(.)]"/>
            <xsl:if test="$contains-selected or ../@class">
              <xsl:attribute name="class" select="concat(../@class,' ',
                                                         if ($contains-selected) then string(.) else '')"/>
            </xsl:if>
          </xsl:template>

          <!-- Sort the selected facets first, if there are any -->
          <xsl:template mode="expand-menus-content" match="ul">
            <xsl:apply-templates mode="expand-menus" select="li">
              <xsl:sort select="my:is-facet-value-selected(.)" order="descending"/> <!-- true first -->
            </xsl:apply-templates>
          </xsl:template>

                  <!-- If, for example, the <li> has class="on" -->
                  <xsl:function name="my:is-facet-value-selected" as="xs:boolean">
                    <xsl:param name="li" as="element(li)"/>
                    <xsl:sequence select="$li/@mt:selected-class = tokenize(normalize-space($li/@class),' ')"/>
                  </xsl:function>


          <!-- Strip out namespace nodes -->
          <xsl:template mode="expand-menus" match="*">
            <xsl:element name="{name()}" namespace="{namespace-uri()}">
              <xsl:apply-templates mode="#current" select="@*"/>
              <xsl:apply-templates mode="expand-menus-content" select="."/>
            </xsl:element>
          </xsl:template>

                  <xsl:template mode="expand-menus-content" match="*">
                    <xsl:apply-templates mode="expand-menus"/>
                  </xsl:template>

          <!-- Copy everything else as is -->
          <xsl:template mode="expand-menus" match="@* | text() | comment() | processing-instruction()">
            <xsl:copy/>
          </xsl:template>

          <!-- Strip out the template flags -->
          <xsl:template mode="expand-menus" match="@mt:*"/>


                  <!-- For year and month -->
                  <xsl:function name="my:facet-values">
                    <xsl:param name="results"/>
                    <xsl:param name="facet-name"/>
                    <xsl:sequence select="$results/search:facet[@name eq $facet-name]/search:facet-value"/>
                  </xsl:function>


  <!-- Render repeating items -->
  <xsl:template match="*[@mt:repeating]" priority="1">
    <xsl:variable name="html-prototype" select="."/>
    <xsl:for-each select="my:data-elements(@mt:repeating)">
      <xsl:apply-templates mode="repeating" select="$html-prototype">
        <xsl:with-param name="data" select="." tunnel="yes"/>
        <xsl:with-param name="pos"  select="position()" tunnel="yes"/>
        <xsl:with-param name="selected" tunnel="yes" as="xs:boolean">
          <xsl:apply-templates mode="is-selected" select="."/>
        </xsl:with-param>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

          <xsl:function name="my:data-elements">
            <xsl:param name="item-name" as="xs:string"/>
            <xsl:sequence select="if ($item-name eq 'result')         then $results/search:result
                             else if ($item-name = $facet-names)      then my:facet-values($results, $item-name)
                             else ()"/>
          </xsl:function>

          <!-- Whether this facet value is part of the current search -->
          <xsl:template mode="is-selected" match="search:facet-value">
            <xsl:sequence select="my:is-constraint-selected(.)"/>
          </xsl:template>

          <!-- By default, don't select -->
          <xsl:template mode="is-selected" match="*">
            <xsl:sequence select="false()"/>
          </xsl:template>


  <!-- Render facet fields -->
  <xsl:template mode="content" match="*[@mt:repeating = $facet-names]
                                       //*[@mt:field]">
    <xsl:apply-templates mode="facet-field" select="@mt:field"/>
  </xsl:template>

          <xsl:template mode="facet-field" match="@*[. eq 'count']">
            <xsl:param name="data" tunnel="yes"/>
            <xsl:value-of select="$data/@count"/>
          </xsl:template>

          <xsl:template mode="facet-field" match="@*[. eq 'name']">
            <xsl:param name="data" tunnel="yes"/>
            <xsl:value-of select="$data"/>
          </xsl:template>



  <!-- Render result fields -->
  <xsl:template mode="content" match="*[@mt:repeating eq 'result']//*[@mt:field]">
    <xsl:apply-templates mode="result-field" select="@mt:field"/>
  </xsl:template>

          <xsl:template mode="result-field" match="@*[. eq 'title']">
            <xsl:param name="data" tunnel="yes"/>
            <xsl:copy-of select="data:highlight(doc($data/@uri)//xhtml:title)/node()"/>
          </xsl:template>

          <xsl:template mode="result-field" match="@*[. eq 'excerpt']">
            <xsl:param name="data" tunnel="yes"/>
            <xsl:apply-templates mode="snippet" select="$data/search:snippet"/>
          </xsl:template>

                  <xsl:template mode="snippet" match="search:match">
                    <xsl:if test="preceding-sibling::search:match and not(starts-with(.,'...'))">...</xsl:if>
                    <span>
                      <xsl:apply-templates mode="#current"/>
                    </span>
                  </xsl:template>

                  <xsl:template mode="snippet #default" match="search:highlight">
                    <strong>
                      <xsl:apply-templates mode="#current"/>
                    </strong>
                  </xsl:template>



  <!-- Replace attribute templates of the form {mt:var} -->
  <xsl:template mode="repeating #default" match="@replace:*">
    <!-- Strip off the "replace" namespace -->
    <xsl:attribute name="{local-name()}">
      <xsl:variable name="repeating-element" select="ancestor::*[@mt:repeating][1]"/>
      <xsl:analyze-string select="." regex="\{{mt: ([^}}]*) \}}" flags="x">
        <xsl:matching-substring>
          <xsl:apply-templates mode="var-value" select="$repeating-element">
            <xsl:with-param name="var-name" select="regex-group(1)"/>
          </xsl:apply-templates>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:attribute>
  </xsl:template>

          <!-- Replace {mt:q} with the $q link value of the modified search -->
          <xsl:template mode="var-value" match="*"> <!--[@mt:repeating = $facet-names]">-->
            <xsl:param name="var-name"/>
            <xsl:param name="data" tunnel="yes"/>
            <xsl:choose>
              <xsl:when test="$var-name eq 'q'">
                <xsl:apply-templates mode="search-q" select="$data"/>
              </xsl:when>
              <!-- Article link -->
              <xsl:when test="$var-name eq 'articleLink'">
                <xsl:value-of select="doc($data/@uri)/*:html/*:head/@resource"/>
              </xsl:when>
            </xsl:choose>
          </xsl:template>



          <xsl:template mode="search-q" match="search:facet-value">
            <xsl:variable name="selected" select="my:is-constraint-selected(.)"/>
            <xsl:variable name="this-constraint" select="my:this-constraint(.)"/>

            <!-- CHANGEME delete this element -->
            <xsl:variable name="new-q" select="if ($selected) then search:remove-constraint($data:q, $this-constraint, $workaround-options)
                                                              else concat($data:q,' ', $this-constraint)"/>
            <!-- CHANGEME un-comment this element
            <xsl:variable name="new-q" select="if ($selected) then search:remove-constraint($data:q, $this-constraint, $data:options)
                                                              else concat($data:q,' ', $this-constraint)"/>
            -->
            <xsl:value-of select="encode-for-uri($new-q)"/>
          </xsl:template>


                  <!-- CHANGEME delete this cluster of elements -->
                  <xsl:variable name="workaround-options" as="element()">
                    <xsl:apply-templates mode="workaround-options" select="$data:options"/>
                  </xsl:variable>
                          <xsl:template mode="workaround-options" match="search:custom/@facet | search:start-facet | search:finish-facet"/>
                          <xsl:template mode="workaround-options" match="search:parse/@ns">
                            <xsl:attribute name="ns" select="'http://marklogic.com/sem-app/workaround'"/>
                          </xsl:template>
                          <xsl:template mode="workaround-options" match="search:parse/@at">
                            <xsl:attribute name="at" select="'/lib/workaround-lib.xqy'"/>
                          </xsl:template>
                          <xsl:template mode="workaround-options" match="@* | node()">
                            <xsl:copy>
                              <xsl:apply-templates mode="#current" select="@* | node()"/>
                            </xsl:copy>
                          </xsl:template>



                  <xsl:function name="my:this-constraint" as="xs:string">
                    <xsl:param name="fv" as="element(search:facet-value)"/>
                    <xsl:sequence select="concat($fv/../@name,':',if (contains($fv/@name,' '))
                                                                  then concat('&quot;',$fv/@name,'&quot;')
                                                                  else                 $fv/@name)"/>
                  </xsl:function>

                  <xsl:function name="my:is-constraint-selected" as="xs:boolean">
                    <xsl:param name="fv" as="element(search:facet-value)"/>
                    <xsl:variable name="this-constraint" select="my:this-constraint($fv)"/>
                    <xsl:variable name="current-constraints" select="my:current-constraints($results)"/>
                    <xsl:sequence select="$this-constraint = $current-constraints"/>
                  </xsl:function>

                  <xsl:function name="my:current-constraints" as="xs:string*">
                    <xsl:param name="response" as="element(search:response)"/>
                    <xsl:variable name="constraints"
                                  select="$response/search:query//@qtextconst/string(),

                                          for $c in $response/search:query//@qtextpre[contains(.,':')]/..
                                          return string-join(($c//@qtextpre,
                                                              $c/*:value,
                                                              $c//@qtextpost),'')"/>
                    <xsl:sequence select="$constraints"/>
                  </xsl:function>

                  <!-- Remove constraints recursively, in case someone tries to enter two constraints -->
                  <xsl:function name="my:remove-constraints" as="xs:string">
                    <xsl:param name="q" as="xs:string"/>
                    <xsl:param name="constraints" as="xs:string*"/>
                    <xsl:param name="options" as="element(search:options)"/>
<xsl:value-of select="xdmp:log(concat('removing: ',$constraints))"/>
                    <xsl:choose>
                      <xsl:when test="not($constraints)">
                        <xsl:sequence select="$q"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:variable name="new-q" select="search:remove-constraint($q, $constraints[1], $options)"/>
                        <xsl:sequence select="if (count($constraints) gt 1) then my:remove-constraints($new-q,$constraints[position() gt 1],$options)
                                                                            else $new-q"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:function>



  <!-- Boilerplate, default copy behavior -->
  <!-- For elements, strip out the unnecessary xmlns declarations -->
  <xsl:template mode="#default repeating" match="*">
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:apply-templates mode="content" select="."/>
    </xsl:element>
  </xsl:template>

          <!-- By default, process children -->
          <xsl:template mode="content" match="*">
            <xsl:apply-templates/>
          </xsl:template>

  <!-- Copy everything else as is -->
  <xsl:template mode="#default repeating" match="@* | text() | comment() | processing-instruction()">
    <xsl:copy/>
  </xsl:template>


  <!-- Strip out the template flags -->
  <xsl:template mode="#default repeating" match="@mt:*"/>

</xsl:stylesheet>
