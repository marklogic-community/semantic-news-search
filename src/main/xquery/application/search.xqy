xquery version "1.0-ml" encoding "utf-8";

(:~
 : Search Results.
 : @author	Philip A. R. Fennell
 :)

import module namespace search = "http://marklogic.com/appservices/search" at 
    "/MarkLogic/appservices/search/search.xqy";
    
import module namespace es = "http://marklogic.com/use-cases/enhanced-search" at
    "lib/lib-metadata.xqy";

declare namespace atom  = "http://www.w3.org/2005/Atom";
declare namespace cat   = "http://s.opencalais.com/1/type/cat/"; 
declare namespace html  = "http://www.w3.org/1999/xhtml";
declare namespace oc    = "http://s.opencalais.com/1/pred/"; 
declare namespace rdf   = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rnews = "http://iptc.org/std/rNews/2011-10-07#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "indent = yes";
declare option xdmp:output "media-type = application/xml";
declare option xdmp:output "method = xml";
declare option xdmp:output "omit-xml-declaration = no";

declare variable $DEFAULT_START  as xs:string := '1';
declare variable $DEFAULT_LENGTH as xs:string := '10';


let $qtext as xs:string := xdmp:get-request-field('q', '')
let $query := search:parse($qtext)
let $start as xs:unsignedLong := xs:unsignedLong(xdmp:get-request-field('start', $DEFAULT_START))
let $length as xs:unsignedLong := xs:unsignedLong(xdmp:get-request-field('length', $DEFAULT_LENGTH))
let $results as item()* := cts:search(collection('http://www.bbc.co.uk/news/content'), cts:query($query))
return
  <feed xmlns="http://www.w3.org/2005/Atom">
    <id>/search</id>
    <title>News Search: Results</title>
    <updated>{text {current-dateTime()}}</updated>
    <generator uri="http://www.marklogic.com" version="7.0">MarkLogic Server</generator>
    {
    for $result in $results
    let $id as xs:string := $result/html:html/html:head/@resource/string()
    let $newsItemMetadata as element(rnews:NewsItem) := es:describeNewsItem($id)/rnews:NewsItem
    let $newsItemCategories as element(oc:category)* := es:newsItemCategories($id)//oc:category
    return
      <entry>
        <id>{text {$id}}</id>
        <title>{text {$newsItemMetadata/rnews:headline/string()}}</title>
        <updated>{text {$newsItemMetadata/rnews:datePublished/string()}}</updated>
        <category scheme="http://www.bbc.co.uk/news/" term="{$newsItemMetadata/rnews:articleSection/string()}" label="{$newsItemMetadata/rnews:articleSection/string()}"/>
        { for $category in $newsItemCategories
          let $categoryTerm as xs:string := substring-after($category/@rdf:resource/string(), 'http://d.opencalais.com/cat/Calais/')
          return
            <category scheme="http://s.opencalais.com/1/type/cat/DocCat" term="{$categoryTerm}" label="{if (contains($categoryTerm, '_')) then translate($categoryTerm, '_', '/') else string-join(analyze-string($categoryTerm, '[A-Z][a-z]+')/node()[local-name() eq 'match'], ' ')}"/>
        }
        <!-- <score>{cts:score($result)}</score> -->
        <content type="xhtml">{
          cts:highlight($result/html:html/html:body/html:div[@class eq 'story-body'], cts:query($query), <em xmlns="http://www.w3.org/1999/xhtml" class="highlight">{$cts:text}</em>)
        }</content>
      </entry>
    }
  </feed>

