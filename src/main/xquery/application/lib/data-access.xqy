xquery version "1.0-ml";
module namespace data="http://marklogic.com/sem-app/data";

import module namespace search = "http://marklogic.com/appservices/search"
    at "/MarkLogic/appservices/search/search.xqy";

import module namespace infobox = "http://marklogic.com/sem-app/infobox"
    at "/lib/infobox.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(: The string query :)
declare variable $q := xdmp:get-request-field("q","");

(: The desired page number :)
declare private variable $p := xs:integer(xdmp:get-request-field("p","1"));

(: Options node for the Search API :)
declare variable $options :=
  <options xmlns="http://marklogic.com/appservices/search">
    <additional-query>{cts:collection-query("http://www.bbc.co.uk/news/content")}</additional-query>

    <!-- This custom constraint uses SPARQL to expand the given query terms -->
    <constraint name="org">
      <custom facet="false">
        <parse apply="parse" ns="http://marklogic.com/sem-app/org-constraint"
                             at="/lib/org-constraint.xqy" />
      </custom>
    </constraint>

    <!-- This constraint uses a combination query to find documents
         in a category represented by OpenCalais-supplied triples.

         And it uses a field (path) range index to facet on the RDF values. -->
    <constraint name="cat">
      <custom facet="true">
        <fragment-scope>properties</fragment-scope>
        <parse        apply="parse"  ns="http://marklogic.com/sem-app/cat-constraint" at="/lib/cat-constraint.xqy"/>
        <start-facet  apply="start"  ns="http://marklogic.com/sem-app/cat-constraint" at="/lib/cat-constraint.xqy"/>
        <finish-facet apply="finish" ns="http://marklogic.com/sem-app/cat-constraint" at="/lib/cat-constraint.xqy"/>
      </custom>
    </constraint>

    <transform-results apply="snippet"/>
    <extract-metadata>
      <qname elem-ns="http://www.w3.org/1999/xhtml" elem-name="title"/>
    </extract-metadata>
    <return-query>true</return-query>
  </options>;

declare variable $ctsQuery as cts:query := cts:query(search:parse($q, $options));

(: Used for highlighting search results;
   returns the "OR", rather than the "AND", of the given sub-queries :)
declare function data:matchesAnyQuery($baseQuery as cts:query) as cts:query {
    let $ctsQueryXML := <_>{$baseQuery}</_>/node(),
        $queriesXML  := if ($ctsQueryXML/self::cts:and-query) then $ctsQueryXML/*
                                                              else $ctsQueryXML,
        $queries := for $query in $queriesXML return cts:query($query)
    return cts:or-query($queries)
};

declare private variable $page-length := 10;

declare function data:get($region) {
       if ($region eq 'results') then data:results($q, $p)
  else if ($region eq 'infobox') then $infobox:data
  else ()
};

declare function data:results($q,$p) {
  search:search($q,
                $options,
                data:start-index($page-length,$p),
                $page-length)
};

(: Compute the start index from the page number and page length :)
declare private function data:start-index($page-length as xs:integer,
                                          $page-number as xs:integer) {
  ($page-length * $page-number) - ($page-length - 1)
};

declare function data:highlight($node) {
  cts:highlight($node, data:matchesAnyQuery($ctsQuery), <strong>{$cts:text}</strong>)
};

