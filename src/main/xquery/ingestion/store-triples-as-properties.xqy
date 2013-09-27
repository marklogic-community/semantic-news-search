(: This script copies all the article category triples
   associated with each document to that document's
   properties fragment.

   This effectively enables us to facet on RDF data.

   This script is idempotent (safe to run more than once).

   NOTE: it will overwrite the document's properties,
   so the assumption is that no other properties
   are being used.
:)
xquery version "1.0-ml";

import module namespace sem="http://marklogic.com/semantics"
       at "/MarkLogic/semantics.xqy";

declare option xdmp:mapping "false";

declare private variable $sparql-prefixes :=
"
  PREFIX oc:  <http://s.opencalais.com/1/pred/>
  PREFIX owl: <http://www.w3.org/2002/07/owl#>
";

(: Use SPARQL to find the specific triples we're interested in. :)
declare function local:category-triples($doc) {
  let $id := $doc/*:html/*:head/@resource/string()
  return
    sem:sparql($sparql-prefixes||"

      CONSTRUCT {
        ?DocCat oc:categoryName ?cat
      }
      FROM <http://www.bbc.co.uk/news/graph>
      WHERE {
       ?DocInfo owl:sameAs <"||$id||"> .
       ?DocCat oc:docId ?DocInfo ;
               oc:categoryName ?cat .
      }

    ")
};

(: For each document in the collection... :)
collection("http://www.bbc.co.uk/news/content") !
(
  let $uri     := document-uri(.),
      $triples := local:category-triples(.),
      $xml     := sem:rdf-serialize($triples,"triplexml")
  return
    (: Load the triples into the properties fragment :)
    ( xdmp:log("Setting properties for "||$uri),
      xdmp:document-set-properties($uri, $xml)
    )
)
