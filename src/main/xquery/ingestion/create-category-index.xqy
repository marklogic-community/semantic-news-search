(: This script configures the "category" range field index
   which the app needs to perform triples-based faceting.
      
   Be sure to run this against the app's database, probably
   called "EnhancedSearch".
:)
xquery version "1.0-ml";

import module namespace admin = "http://marklogic.com/xdmp/admin" 
       at "/MarkLogic/admin.xqy";

(: Create a path namespace :)
let $path-ns :=
  admin:database-path-namespace(
    "sem",
    "http://marklogic.com/semantics"
),

(: Create the field :)
(: Using the XML format directly to work around
   an apparent bug in the Admin API's new
   database-add-field-paths function :)
$field :=
<field xmlns="http://marklogic.com/xdmp/database">
  <field-name>category</field-name>
  <field-path>
    <path>sem:triple[sem:predicate eq 'http://s.opencalais.com/1/pred/categoryName']/sem:object</path>
    <weight>1.0</weight>
  </field-path>
  <word-lexicons/>
  <included-elements/>
  <excluded-elements/>
  <tokenizer-overrides/>
</field>,

(: Create the field range index :)
$rangespec :=
  admin:database-range-field-index(
    "string",
    "category",
    "http://marklogic.com/collation/",
    false()
),

(: Get and update the configuration :)
$config := admin:get-configuration(),
$config := admin:database-add-path-namespace($config, xdmp:database(), $path-ns),
$config := admin:database-add-field         ($config, xdmp:database(), $field),
(:
$config := admin:database-add-field-paths   ($config, xdmp:database(), "category", $field-path),
:)
$config := admin:database-add-range-field-index($config, xdmp:database(), $rangespec)

(: Save the configuration :)
return admin:save-configuration($config)
