(: This module is concerned with taking the user's search
   and finding the most relevant resource to display in
   an infobox, if available.

   See infobox.xsl for the rendering of the infobox.
:)
xquery version "1.0-ml";

module namespace infobox = "http://marklogic.com/sem-app/infobox";

import module namespace sem = "http://marklogic.com/semantics"
    at "/MarkLogic/semantics.xqy";

import module namespace search = "http://marklogic.com/appservices/search"
    at "/MarkLogic/appservices/search/search.xqy";

import module namespace data = "http://marklogic.com/sem-app/data"
    at "/lib/data-access.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";


(: Don't require the infobox resource to match *everything* the user types.
   Instead, allow it to match anything the user types. :)
declare private variable $infobox:query := data:matchesAnyQuery(cts:query(search:parse($data:q)));

(: Use SPARQL to find all the resources among the object types we support
   for infoboxes, i.e. companies and countries, whose name matches one of the
   user's query terms. :)
declare private variable $infobox:matching-infobox-iris as sem:iri* :=
  let $sparql := "

    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX cts: <http://marklogic.com/cts#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dbp: <http://dbpedia.org/property/>
    PREFIX dbo: <http://dbpedia.org/ontology/>

    SELECT DISTINCT ?s
    FROM <http://marklogic.com/sem-app/dbpedia>
    WHERE
    {
      { ?s a dbo:Country }
      UNION
      { ?s a dbo:Company } .

      { ?s dbp:commonName  ?name FILTER cts:contains(?name,"||$infobox:query||") }
      UNION
      { ?s dbp:companyName ?name FILTER cts:contains(?name,"||$infobox:query||") }
      UNION
      { ?s rdfs:label      ?name FILTER cts:contains(?name,"||$infobox:query||") } .
    }

  "
  return
    sem:sparql($sparql)
  ! map:get(.,"s")
  ! sem:iri(.)
;

(: Since we're currently only displaying one infobox at a time, just pick the first matching one. :)
declare private variable $infobox:iri := $infobox:matching-infobox-iris[1];

(: Get back all the relevant triples pertaining to the chosen resource :)
declare private variable $infobox:triples as sem:triple* := sem:describe($infobox:iri);

(: Return the triples in XML format, for rendering purposes :)
declare variable $infobox:data as element() :=
  <infobox>
    {$infobox:triples}
  </infobox>
;
