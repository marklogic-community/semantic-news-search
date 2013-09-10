xquery version "1.0-ml" encoding "utf-8";

(:~
 : Simple URL re-writer.
 : @author	Philip A. R. Fennell
 :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";


let $debug := xdmp:log(concat('[XQuery][News] path = ', xdmp:get-request-path()))
return
  if (matches(xdmp:get-request-path(), '^/$')) then
    xdmp:get-request-url()
  else
    concat(xdmp:get-request-path(), '.xqy', substring-after(xdmp:get-request-url(), xdmp:get-request-path()))