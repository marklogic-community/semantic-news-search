(: This script configures the server with all the fields and
   range field indexes that the application needs to perform
   triples-based faceting as configured in application/config/facets.xml.
      
   Run this script in an app server whose root is set to the
   parent "xquery" directory.
:)
xquery version "1.0-ml";

import module namespace admin = "http://marklogic.com/xdmp/admin" 
       at "/MarkLogic/admin.xqy";

declare namespace db = "http://marklogic.com/xdmp/database";

(: ASSUMPTION: the current database is the application database. :)
declare variable $dbid := xdmp:database();

(: Get all the facet info from our application config :)
declare variable $facet-configs :=
  xdmp:document-get(xdmp:modules-root()||"application/config/facets.xml")
  /facets/facet;

(: Recursively add fields and indexes as driven by the facet configs :)
declare function local:add-facets($config, $facets) {
  if (not($facets)) then $config
  else
    $facets[1] !
    (
      let $field :=
        (: We're using the XML format directly to work around
           an apparent bug in the Admin API's new
           database-add-field-paths function :)
        <field xmlns="http://marklogic.com/xdmp/database">
          <field-name>{text{@index-name}}</field-name>
          <field-path>
            <path>sem:triple[sem:predicate eq '{text{@rdf-property}}']/sem:object</path>
            <weight>1.0</weight>
          </field-path>
          <word-lexicons/>
          <included-elements/>
          <excluded-elements/>
          <tokenizer-overrides/>
        </field>,

      $existing := admin:database-get-fields($config, $dbid),

      $config :=
        if ($field/db:field-name = $existing/db:field-name)
        then $config
        else admin:database-add-field($config, $dbid, $field),

      $index :=
        admin:database-range-field-index(
          string(@type),
          string(@index-name),
          string(@collation),
          false()
        ),

      $existing := admin:database-get-range-field-indexes($config, $dbid),

      $config :=
        if ($index/db:field-name = $existing/db:field-name)
        then $config
        else admin:database-add-range-field-index($config, $dbid, $index)

      return
        local:add-facets($config, tail($facets))
    ) 
};


(: Get the empty config :)
let $config := admin:get-configuration(),


(: Add the path namespace for triples :)
$config :=
  let $path-ns :=
    admin:database-path-namespace(
      "sem",
      "http://marklogic.com/semantics"
    ),
  $existing := admin:database-get-path-namespaces($config, $dbid)
  return
    if ($existing/db:prefix = 'sem')
    then $config
    else admin:database-add-path-namespace($config, $dbid, $path-ns),


(: Add the field and index configurations :)
$config := local:add-facets($config, $facet-configs)

 
(: Save the configuration :)
return admin:save-configuration($config)
