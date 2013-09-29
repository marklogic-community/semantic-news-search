(: This script copies all the facet-related triples
   associated with each document to that document's
   properties fragment.

   This effectively enables us to facet on RDF data.

   NOTE: it will overwrite the document's properties,
   so the assumption is that no other properties
   are being used.
:)
xquery version "1.0-ml";

import module namespace sem="http://marklogic.com/semantics"
       at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

(: Get all the facet info from our application config :)
declare variable $facet-configs :=
  xdmp:document-get(xdmp:modules-root()||"application/config/facets.xml")
  /facets/facet;

(: For the given document id, run the SPARQL query
   associated with each configured facet, binding
   the $facetProperty and $docId variables (effectively,
   via regex-replacement, which performs much better).
:)
declare function local:triples($doc-id) {
  $facet-configs !
  (
    let $sparql-src :=
      if (sparql)
      then sparql
      else let $id := @sparql-idref
           return //sparql[@id eq $id]

    let $sparql := ../sparql-prefixes||$sparql-src
    let $sparql := replace($sparql,"\$facetProperty","<"||@rdf-property||">")
    let $sparql := replace($sparql,"\$docId",        "<"||$doc-id||">")

    return
      sem:sparql($sparql)
  )
};


(: For each document in the collection... :)
collection("http://www.bbc.co.uk/news/content") !
(
  let $uri     := document-uri(.),
      $doc-id  := /*:html/*:head/@resource/string(),
      $triples := local:triples($doc-id),
      $xml     := sem:rdf-serialize($triples,"triplexml")
  return
    (: Load the triples into the properties fragment :)
    ( xdmp:log("Setting properties for ("||position()||" of "||last()||") "||$uri),
      (:xdmp:log(xdmp:quote($xml)),:)
      xdmp:document-set-properties($uri, $xml)
    )
)
