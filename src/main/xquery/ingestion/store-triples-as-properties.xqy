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
  PREFIX c:   <http://s.opencalais.com/1/pred/>
  PREFIX e:   <http://s.opencalais.com/1/type/em/e/>
  PREFIX owl: <http://www.w3.org/2002/07/owl#>
";

(: Use SPARQL to find the specific triples we're interested in. :)
declare function local:category-triples($doc-id) {
  sem:sparql($sparql-prefixes||"

    CONSTRUCT {
      ?DocCat c:categoryName ?cat .
    }
    FROM <http://www.bbc.co.uk/news/graph>
    WHERE {
     ?DocInfo owl:sameAs <"||$doc-id||"> .
     ?DocCat c:docId ?DocInfo ;
             c:categoryName ?cat .
    }

  ")
};

declare function local:orgtype-triples($doc-id) {
  sem:sparql($sparql-prefixes||"

    CONSTRUCT {
      ?org c:organizationtype ?orgtype .
    }
    FROM <http://www.bbc.co.uk/news/graph>
    WHERE {
      ?DocInfo owl:sameAs <"||$doc-id||"> .

      ?RelevanceInfo c:docId ?DocInfo ;
                     c:subject ?org .

      ?org a e:Organization ;
           c:organizationtype ?orgtype .
    }

  ")
};

(: For each document in the collection... :)
collection("http://www.bbc.co.uk/news/content")[3] !
(
  let $uri     := document-uri(.),
      $doc-id  := /*:html/*:head/@resource/string(),
      $triples := (local:category-triples($doc-id),
                   local:orgtype-triples($doc-id)),
      $xml     := sem:rdf-serialize($triples,"triplexml")
  return
    (: Load the triples into the properties fragment :)
    ( xdmp:log("Setting properties for ("||position()||" of "||last()||") "||$uri),
      xdmp:document-set-properties($uri, $xml)
    )
)
