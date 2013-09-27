(: This module implements the "cat" custom constraint.

   If you type "cat:Sports" for example, it will use a
   triple-range-query to find all documents in the "Sports"
   category, as represented by OpenCalais-supplied RDF triples.

   NOTE: the assumption is that the relevant triples are
   stored with the document itself: in this case, in the 
   document's properties fragment.

   We also facet on these values through the use of
   a path range index, named via the "category" field definition.
:)
xquery version "1.0-ml";

module namespace cat = "http://marklogic.com/sem-app/cat-constraint";

import module namespace search = "http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

(: This function constructs a triple range query
   against properties, which the Search API will
   then combine with the rest of the user's query.
:)
declare function cat:parse(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  cts:properties-query(
    cts:triple-range-query((), sem:iri("http://s.opencalais.com/1/pred/categoryName"), string($right))
  )
  ! <_>{.}</_>/* (: return as XML :)
};


(: This function tells the Search API the source of the
   constraint's facet values: the "category" field range index.
:)
declare function cat:start(
  $constraint as element(search:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  for $cat in cts:field-values("category", (), ($facet-options, "concurrent"), $query, $quality-weight, $forests)
  return
    <category name="{$cat}" count="{cts:frequency($cat)}"/>
};


(: In order to support concurrency, we return the final
   facet values in a separate function call.
:)
declare function cat:finish(
  $start as item()*,
  $constraint as element(search:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as element(search:facet)
{
  <search:facet name="{$constraint/@name}">
  {
    for $cat in $start
    return
      <search:facet-value name="{$cat/@name}" count="{$cat/@count}">
        { cat:displayCategory($cat/@name) }
      </search:facet-value>
  }
  </search:facet>
};


(: Display slashes instead of underscores in category names :)
declare private function cat:displayCategory($cat) {
  translate($cat,'_','/') 
};
