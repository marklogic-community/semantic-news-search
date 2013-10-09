(: This query:
 
   1. finds all the OpenCalais-disambiguated companies and countries
   2. loads the relevant RDF from d.opencalais.com, which may include
      sameAs links pointing to corresponding DBpedia resources.
:)
xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" 
      at "/MarkLogic/semantics.xqy";

(: STEP 1: find all the entity instances of the desired types :)
  sem:sparql("

    PREFIX r:   <http://s.opencalais.com/1/type/er/>
    PREFIX geo: <http://s.opencalais.com/1/type/er/Geo/>

    SELECT DISTINCT ?entity
    FROM <http://www.bbc.co.uk/news/graph>
    WHERE {
      { ?entity a r:Company }
      UNION
      { ?entity a geo:Country }
    }

  ")
! map:get(., "entity")

(: STEP 2: fetch and load the RDF from opencalais.com :)
! concat(., ".rdf")
! (try { (xdmp:log(concat("Loading ",.))),
          sem:rdf-load(., ("rdfxml","graph=http://marklogic.com/sem-app/sameAsLinks")) }
   catch($e) {xdmp:log($e)})
