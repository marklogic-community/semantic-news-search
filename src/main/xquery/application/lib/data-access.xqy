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

    <!-- Both of the constraints below use a combination query to find
         documents in a category represented by OpenCalais-supplied triples.

         They use field (path) range indexes to facet on the RDF values.
    -->
    {
      ("cat","org") !
      <constraint name="{.}">
        <custom facet="true">
          <fragment-scope>properties</fragment-scope>
          <parse        apply="parse"  ns="http://marklogic.com/sem-app/facet-lib" at="/lib/facet-lib.xqy"/>
          <start-facet  apply="start"  ns="http://marklogic.com/sem-app/facet-lib" at="/lib/facet-lib.xqy"/>
          <finish-facet apply="finish" ns="http://marklogic.com/sem-app/facet-lib" at="/lib/facet-lib.xqy"/>
        </custom>
      </constraint>
    }

    <!-- Expand the result highlighting by expanding the query via SPARQL -->
    <transform-results apply="expanded-snippet"
                       ns="http://marklogic.com/sem-app/snippet"
                       at="/lib/snippet.xqy"/>

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
