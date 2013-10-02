(: This query:
 
   1. finds all the OpenCalais disambiguated entity types,
      i.e. those whose IRIs include "/type/er",
   2. finds all the instances of those types, e.g., countries, companies, etc., and
   3. loads the relevant RDF from d.opencalais.com, which may include sameAs links.
:)
xquery version "1.0-ml";

import module namespace sem = "http://marklogic.com/semantics" 
      at "/MarkLogic/semantics.xqy";

let $rdf-type-pred := sem:curie-expand("rdf:type")

(: STEP 1: enumerate the types of entities we have in the database :)
let $entity-types :=
  (: This is inefficient; it loads the XML for all the triples. Is there an efficient way to do this? :)
  distinct-values(
    collection("http://www.bbc.co.uk/news/graph")
    //sem:triple[sem:predicate eq $rdf-type-pred]
                [starts-with(sem:object,"http://s.opencalais.com/1/type/er")]
     /sem:object
     /string()
  )

(: STEP 2: find all the entity instances of those types :)
let $entities :=
  for $t in $entity-types return 
  sem:sparql(concat("
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    SELECT DISTINCT ?s { ?s rdf:type <",$t,"> . }
  "))

(: STEP 3: fetch and load the RDF from opencalais.com :)
(: NOTE: d.opencalais.com seems to be intermittently unavailable;
         try again later if necessary.
         
         Also, maddeningly, not all the sameAs links, particularly
         the dbpedia.org ones, appear in every request. This too
         is intermittent. You might want to run the script when
         it appears that opencalais.com is actually returning
         dbpedia.org sameAs links. Refresh this page as a test:
         http://d.opencalais.com/er/company/ralg-tr1r/9bb26018-f501-329e-b57d-5e1ec16f1bd0.html
         :)
return
  $entities
! map:get(., "s")
! concat(., ".rdf")
! (try { (xdmp:log(concat("Loading ",.))),
          sem:rdf-load(., ("rdfxml","graph=http://marklogic.com/sem-app/sameAsLinks")) }
   catch($e) {xdmp:log($e)})
