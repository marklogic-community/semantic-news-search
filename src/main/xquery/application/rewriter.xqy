xquery version "1.0-ml";

let $path     := xdmp:get-request-path(),
    $orig-url := xdmp:get-request-url()
return
  (: Hide files we don't want to serve up :)
  if (starts-with($path,'/lib') or
      starts-with($path,'/config') or
      starts-with($path,'README.txt')) then
    "/notfound.xqy"
  else
    xdmp:get-request-url()
