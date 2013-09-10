xquery version "1.0-ml";

(: Copyright 2002-2013 MarkLogic Corporation.  All Rights Reserved. :)

(:
:: Custom action.  It must be a CPF action module.
:: Replace this text completely, or use it as a template and 
:: add imports, declarations,
:: and code between START and END comment tags.
:: Uses the external variables:
::    $cpf:document-uri: The document being processed
::    $cpf:transition: The transition being executed
:)

import module namespace cpf = "http://marklogic.com/cpf"
   at "/MarkLogic/cpf/cpf.xqy";

(: START custom imports and declarations; imports must be in Modules/ on filesystem :)

import module namespace sem = "http://marklogic.com/semantics" at
  "MarkLogic/semantics.xqy";

declare namespace es = "http://www.marklogic.com/enhanced-search#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(: END custom imports and declarations :)

declare option xdmp:mapping "false";

declare variable $cpf:document-uri as xs:string external;
declare variable $cpf:transition as node() external;

if ( cpf:check-transition($cpf:document-uri,$cpf:transition))
then
    try {
       (: START your custom XQuery here :)
       
       let $rdfXML as element()? := fn:doc($cpf:document-uri)/es:job-bag/rdf:RDF
       let $insertQuery as xs:string :=
"xquery version '1.0-ml';

import module namespace sem = 'http://marklogic.com/semantics' at
  'MarkLogic/semantics.xqy';

declare variable $RDF_XML as element() external;

sem:rdf-insert(sem:rdf-parse($RDF_XML), (), (), ('http://www.bbc.co.uk/news/graph'))"
       return
         xdmp:eval($insertQuery, 
           (xs:QName('RDF_XML'), $rdfXML),
           <options xmlns="xdmp:eval">
             <database>{xdmp:database('EnhancedSearch')}</database>
           </options>)
       
       (: END your custom XQuery here :)
       ,
       cpf:success( $cpf:document-uri, $cpf:transition, () )
    }
    catch ($e) {
       cpf:failure( $cpf:document-uri, $cpf:transition, $e, () )
    }
else ()

            