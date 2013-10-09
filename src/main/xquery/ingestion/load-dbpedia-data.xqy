(: This query:

   1. finds all the DBpedia sameAs links we just loaded,
   2. loads the corresponding RDF data from dbpedia.org.
:)
xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" 
      at "/MarkLogic/semantics.xqy";

(: If it doesn't finish in 30 minutes, something else is wrong :)
xdmp:set-request-time-limit(1800),

(: STEP 1: find all the DBpedia sameAs links :)
sem:sparql("

  PREFIX owl: <http://www.w3.org/2002/07/owl#>
  SELECT DISTINCT ?thing
  FROM <http://marklogic.com/sem-app/sameAsLinks>
  WHERE
  {
    ?entity owl:sameAs ?thing FILTER STRSTARTS(?thing,'http://dbpedia.org/') .
  }

")

! map:get(.,"thing")

(: STEP 2: grab the corresponding RDF data from dbpedia.org :)
! replace(.,"/resource/","/data/")
! concat(.,".rdf")
! (try { (xdmp:log(concat("Loading ",.)),
          sem:rdf-load(., ("rdfxml","graph=http://marklogic.com/sem-app/dbpedia"))) }
   catch($e) {xdmp:log($e)})
