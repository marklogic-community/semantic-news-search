(: Once search:remove-constraint() is fixed so that it can
   work with custom constraints that include
   cts:triple-range-queries, you can delete this module.

   In addition, edit /lib/render.xsl wherever it says CHANGEME
:)
xquery version "1.0-ml";

module namespace workaround = "http://marklogic.com/sem-app/workaround";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function workaround:parse(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  let $facet-name := substring-before($constraint-qtext,':'),
      $prop-value := string($right),
      $delim := if (contains($prop-value,' ')) then '"' else ''
  return
    <cts:properties-query qtextconst="{$facet-name}:{$delim}{$prop-value}{$delim}">
    {
      cts:word-query("whatever")
    }
    </cts:properties-query>
};
