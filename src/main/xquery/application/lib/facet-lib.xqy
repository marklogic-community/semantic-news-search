(: This module implements the triples-based custom constraints.

   If you type "cat:Sports" for example, it will use a
   triple-range-query to find all documents in the "Sports"
   category, as represented by OpenCalais-supplied RDF triples.

   NOTE: the assumption is that the relevant triples are
   stored with the document itself: in this case, in the 
   document's properties fragment.

   We also facet on these values through the use of
   path range indexes.

   All facets are configured in application/config/facets.xml
:)
xquery version "1.0-ml";

module namespace facet = "http://marklogic.com/sem-app/facet-lib";

import module namespace search = "http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace data = "http://marklogic.com/sem-app/data"
       at "/lib/data-access.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

(: This function constructs a triple range query
   against properties, which the Search API will
   then combine with the rest of the user's query.
:)
declare function facet:parse(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  let $facet-name   := substring-before($constraint-qtext,':'),
      $rdf-property := $data:facet-configs[@name eq $facet-name]/@rdf-property/string(),
      $prop-value   := string($right),
      $delim        := if (contains($prop-value,' ')) then '"' else ''
  return

    <cts:properties-query qtextconst="{$facet-name}:{$delim}{$prop-value}{$delim}">
    {
      cts:triple-range-query((), sem:iri($rdf-property), $prop-value)
    }
    </cts:properties-query>
};


(: This function tells the Search API the source of the
   constraint's facet values, e.g. the "category" field range index.
:)
declare function facet:start(
  $constraint as element(search:constraint),
  $query as cts:query?,
  $facet-options as xs:string*,
  $quality-weight as xs:double?,
  $forests as xs:unsignedLong*)
as item()*
{
  let $facet-name := $constraint/@name,
      $index-name := $data:facet-configs[@name eq $facet-name]/@index-name/string()

  for $val in cts:field-values($index-name, (), ($facet-options, "concurrent"), $query, $quality-weight, $forests)
  return
    <value name="{$val}" count="{cts:frequency($val)}"/>
};


(: In order to support concurrency, we return the final
   facet values in a separate function call.
:)
declare function facet:finish(
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
    for $val in $start
    return
      <search:facet-value name="{$val/@name}" count="{$val/@count}">
        { facet:displayValue($val/@name) }
      </search:facet-value>
  }
  </search:facet>
};


(: Display slashes instead of underscores in facet values :)
declare private function facet:displayValue($val) {
  translate($val,'_','/') 
};
