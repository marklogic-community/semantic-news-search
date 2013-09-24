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

(: Use SPARQL to get a list of all candidate resources, based on the resource types we support :)
declare private variable $infobox:candidate-resource-iris as xs:string* :=
  sem:sparql("
 
    SELECT DISTINCT ?s
    FROM <http://marklogic.com/sem-app/dbpedia>
    WHERE
    {
      { ?s a <http://dbpedia.org/ontology/Country> }
      UNION
      { ?s a <http://dbpedia.org/ontology/Company> }
    }
  ")
  ! map:get(.,"s")
;

(: These are the fields we'll apply the user's search to :)
declare private variable $infobox:name-properties :=
  ("http://dbpedia.org/property/commonName",
   "http://dbpedia.org/property/companyName",
   sem:curie-expand("rdfs:label"))
;

(: Pick the first result returned from cts:search (relevance order) :)
declare private variable $infobox:iri := 
  (: Search only the DBPedia triples pertaining to the resource's names :)
  cts:search(collection("http://marklogic.com/sem-app/dbpedia")
                        //sem:triple[sem:subject    = $infobox:candidate-resource-iris]
                                    [sem:predicate  = $infobox:name-properties]
                        /sem:object,
             $infobox:query)
   [1] (: get the subject IRI for the first-matching triple :)
  /parent::sem:triple
  /sem:subject
  /string(.)
;

(: Use SPARQL DESCRIBE to get back all the triples pertaining to the chosen resource :)
declare private variable $infobox:triples as sem:triple* :=
  sem:sparql("

    DESCRIBE <"||$infobox:iri||">

  ")
;

(: Return the triples in XML format, for rendering purposes :)
declare variable $infobox:data as element() :=
  <infobox>
    {$infobox:triples}
  </infobox>
;
