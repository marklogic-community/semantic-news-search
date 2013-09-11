xquery version "1.0-ml";
module namespace render="http://marklogic.com/sem-app/render";

import module namespace data="http://marklogic.com/sem-app/data" at "/lib/data-access.xqy";

declare namespace mt="http://marklogic.com/sem-app/templates";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $format := xdmp:get-request-field("format","html");

(: The template is index.html in the same directory :)
declare private variable $template-path :=
  let $root-without-slash := replace(xdmp:modules-root(),    "(.*)/",       "$1"),
      $path-without-file  := replace(xdmp:get-request-path(),"(.*)/[^/]*$", "$1")
  return
    concat($root-without-slash, $path-without-file, '/index.html');

(: Load the template file as XML :)
declare private variable $template := xdmp:document-get($template-path,
                                                        <options xmlns="xdmp:document-get">
                                                          <format>xml</format>
                                                        </options>);

(: Render the whole page/template :)
declare function render:full-page() {
  xdmp:xslt-invoke("render.xsl", $template)
};

(: Render just part of the page :)
declare function render:page-region($page-region) {

       if ($format eq 'html') then xdmp:xslt-invoke("render.xsl", $template//*[@mt:page-region eq $page-region])
  else if ($format eq 'xml')  then             data:get($page-region)
  else if ($format eq 'json') then render:json(data:get($page-region))
  else ()
};

(: Not implemented: converts the XML data to JSON :)
declare function render:json($data) {
  (: stub :)
  $data
};
