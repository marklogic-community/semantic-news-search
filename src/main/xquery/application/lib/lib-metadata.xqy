xquery version "1.0-ml" encoding "utf-8";

module namespace es = "http://marklogic.com/use-cases/enhanced-search";

import module namespace sem = "http://marklogic.com/semantics" at
    "/MarkLogic/semantics.xqy";

declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $PREFIXES as element() := 
<query><![CDATA[
prefix fn:    <http://www.w3.org/2005/xpath-functions#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX xs:    <http://www.w3.org/2001/XMLSchema#>

PREFIX bbc:   <http://www.bbc.co.uk/news/>
PREFIX cat:   <http://s.opencalais.com/1/type/cat/>
PREFIX dct:    <http://purl.org/dc/terms/>
PREFIX e:     <http://s.opencalais.com/1/type/em/e/>
PREFIX geo:   <http://s.opencalais.com/1/type/er/Geo/>
PREFIX oc:    <http://s.opencalais.com/1/pred/>
PREFIX owl:   <http://www.w3.org/2002/07/owl#>
PREFIX rnews: <http://iptc.org/std/rNews/2011-10-07#>
]]></query>;


(:~
 : Returns the NewsItem metadata for the context story.
 : @param $id the NewsItem's identifier URI.
 : @return RDF.XML representation of the NewsItem's metadata.
 :)
declare function es:describeNewsItem($id as xs:string) 
    as element(rdf:RDF)
{
  let $result as item()* := sem:sparql(es:query-add-prolog($PREFIXES, 
<query><![CDATA[
DESCRIBE $id
]]></query>),
(map:entry('id', sem:iri($id))),
())
return
  sem:rdf-serialize($result, 'rdfxml')
};


(:~
 : Returns the NewsItem's enriched metadata.
 : @param $id the NewsItem's identifier URI.
 : @return RDF.XML representation of the NewsItem's metadata.
 :)
declare function es:newsItemCategories($id as xs:string) 
    as element(rdf:RDF)
{
  let $result as item()* := sem:sparql(es:query-add-prolog($PREFIXES, 
<query><![CDATA[
CONSTRUCT {
  ?DocInfo oc:country $countryName ; 
           oc:category $category .
}
FROM <http://www.bbc.co.uk/news/graph>
WHERE {
  $DocInfo owl:sameAs $id .
  $DocCat oc:docId $DocInfo ;
          oc:category $category .
}
]]></query>),
(map:entry('id', sem:iri($id))),
())
return
  sem:rdf-serialize($result, 'rdfxml')
};


(:~
 : Returns the NewsItem's enriched metadata.
 : @param $id the NewsItem's identifier URI.
 : @param $threshold the relevance threshold.
 : @return RDF.XML representation of the NewsItem's metadata.
 :)
declare function es:newsItemSubjects($id as xs:string, $threshold as xs:double) 
    as element(rdf:RDF)
{
  let $bindings := map:map()
  let $_put := map:put($bindings, 'id', sem:iri($id))
  let $_put := map:put($bindings, 'threshold', $threshold)
  let $result as item()* := sem:sparql(es:query-add-prolog($PREFIXES, 
<query><![CDATA[
CONSTRUCT {
  $subject oc:name $name ;
           a $type .
}
FROM <http://www.bbc.co.uk/news/graph>
WHERE {
  SELECT DISTINCT $subject $name $type $rel
  WHERE {
    $DocInfo owl:sameAs <http://www.bbc.co.uk/news/world-asia-22965046> .
    $thing1 oc:docId $DocInfo ;
            oc:relevance $relevance ;
            oc:subject $subject .
    $subject oc:name $name ;
             rdf:type $type .
    FILTER ($relevance >= $threshold)
  }  ORDER BY DESC($relevance)
}
]]></query>),
($bindings),
())
return
  sem:rdf-serialize($result, 'rdfxml')
};


(:~
 : Add the namespace prefix bindings to the query.
 : @param $query the query.
 : @return a SPARQL query with any predefined prefixes pre-pended to the query.
 :)
declare function es:query-add-prolog($prefixes as element(), $query as element())
    as xs:string
{
  $PREFIXES || $query
};

