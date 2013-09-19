(: This query:

   1. finds all the sameAs links we just loaded,
   2. filters out all except those referencing dbpedia.org, and
   3. loads the corresponding RDF data from dbpedia.org.
:)
xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" 
      at "/MarkLogic/semantics.xqy";

(: STEP 1: find all the sameAs links :)
sem:sparql("
  PREFIX owl: <http://www.w3.org/2002/07/owl#>
  SELECT ?o
  FROM <http://marklogic.com/sem-app/sameAsLinks>
  WHERE { ?s owl:sameAs ?o . # FILTER STRSTARTS(STR(?o),'http://dbpedia.org/') # I get 'Undefined function fn:starts-with()'
        }
")

! map:get(.,"o")

(: STEP 2: retain only the dbpedia.org references (because it didn't work in SPARQL, see above) :)
! (if (starts-with(.,"http://dbpedia.org")) then . else ())

(: STEP 3: grab the corresponding RDF data from dbpedia.org :)
! replace(.,"/resource/","/data/")
! concat(.,".rdf")
! (try { (xdmp:log(concat("Loading ",.)),
          sem:rdf-load(., ("rdfxml","graph=http://marklogic.com/sem-app/dbpedia"))) }
   catch($e) {xdmp:log($e)})
