(: This module implements a custom snippeting function.

   The only customization is that we expand the original query
   in order to highlight examples of the requested class.

   For example, if the original query contains 'org:"central bank"',
   then the expanded query will contain OR'd word-queries for
   "US Federal Reserve", "China's National Audit Office", etc.
   causing such phrases to be highlighted in the results, even
   though they weren't a part of the original query.

   It does this by looking for an expandable triple-range-query in
   the original query and then adding a bunch of word queries enumerated
   from the result of a deeper dig into the RDF store via SPARQL.
:) 
xquery version "1.0-ml";

module namespace snip = "http://marklogic.com/sem-app/snippet";

import module namespace sem = "http://marklogic.com/semantics"
       at "/MarkLogic/semantics.xqy";

import module namespace search = "http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";


(: The properties that will trigger a query expansion. So far we just have one. :)
declare private variable $props-to-expand := ("http://s.opencalais.com/1/pred/organizationtype");

(: The property that signifies the name of each instance :)
declare private variable $instance-name-prop := "http://s.opencalais.com/1/pred/name";


(: This is the function that the Search API calls to retrieve
   the custom snippet. The only thing we do is expand the query
   and then pass it back to the built-in snippeting function.
:)
declare function snip:expanded-snippet(
   $result as node(),
   $ctsquery as schema-element(cts:query),
   $options as element(search:transform-results)?
) as element(search:snippet)
{
  let $expanded-query := snip:expand($ctsquery) return
  search:snippet($result, $expanded-query, $options)
};


(: This function expands the query, according to whether
   expandable predicates appear in the original.
:)
declare function snip:expand($query) {
  let $triple-constraints := $query//cts:triple-range-query
                                     [cts:predicate = $props-to-expand],

      $word-queries := $triple-constraints
                     ! snip:instances(cts:predicate, cts:object)
                     ! cts:word-query(.)
  return
    <cts:or-query>
      {$query, $word-queries}
    </cts:or-query>
};


(: This function calls out to SPARQL to get the actual
   instance names (e.g. "Free Syrian Army") for the given
   facet value (e.g. org:"governmental military").
:)
declare function snip:instances($facet, $value) {
  sem:sparql("

    SELECT DISTINCT ?instanceName
    WHERE {
      ?instance <"||$facet||"> '"||$value||"' ;
                <"||$instance-name-prop||"> ?instanceName .
    }

  ")
  ! map:get(., "instanceName")
};
