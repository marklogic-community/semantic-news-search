(: This module implements the "org" custom constraint.

   If you type "org:military" for example, it will expand
   the query to search for all the known military organizations.

   The available organization types we know about from the
   OpenCalais-supplied data are as follows:

    * political party
    * governmental civilian
    * governmental military
    * sports
    * central bank
:)
xquery version "1.0-ml";

module namespace org = "http://marklogic.com/sem-app/org-constraint";

import module namespace sem = "http://marklogic.com/semantics" 
      at "/MarkLogic/semantics.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare private variable $sparql-prefixes :=
"
   PREFIX c: <http://s.opencalais.com/1/pred/>
   PREFIX o: <http://s.opencalais.com/1/type/em/e/>
";

(: This function constructs an expanded query
   based on what we know about the various types
   of organizations.
:)
declare function org:parse(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  (: First, get a list of all known organization types :)
  let $all-orgtypes :=
    sem:sparql($sparql-prefixes || "

      SELECT DISTINCT ?type
      WHERE {
        ?s a o:Organization .
        ?s c:organizationtype ?type .
      }

    ")
    ! map:get(., "type")


  (: Second, find the org types that match the user's query :)
  let $matching-orgtypes := $all-orgtypes[org:contains(., string($right))]


  (: Third, retrieve the names of all organizations having the desired type(s) :)
  let $matching-organizations :=
    sem:sparql($sparql-prefixes || "

      SELECT DISTINCT ?orgName
      WHERE {
        ?org a o:Organization .
        ?org c:organizationtype ?type .
          FILTER ("||
            string-join(
              $matching-orgtypes ! ("?type = '"||.||"'"), " || "
            )||")
        ?org c:name ?orgName .
      }

    ")
    ! map:get(., "orgName") 


  (: Finally, construct a cts OR query that searches for those organizations :)
  return
    cts:or-query(
      $matching-organizations ! cts:word-query(.,"case-insensitive")
    )
    ! <_>{.}</_>/* (: convert to XML :)

};


(: An organization type matches via cts:contains
   OR with a regular substring match but only if the 
   search string is not trivially short.

   For example, if someone types "government", let it match "governmental"
   via substring match (since stemming doesn't apply here).
:)
declare private function org:contains(
  $str as xs:string,
  $search as xs:string)
as xs:boolean
{
  cts:contains($str,cts:word-query($search,"case-insensitive"))
    or
  (if (string-length($search) gt 5) then contains($str,$search) else false())
};
