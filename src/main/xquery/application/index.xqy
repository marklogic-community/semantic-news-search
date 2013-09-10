xquery version "1.0-ml" encoding "utf-8";

(:~
 : Home page.
 : @author	Philip A. R. Fennell
 :)

declare namespace html = "http://www.w3.org/1999/xhtml";

(: <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
                      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "indent = yes";
declare option xdmp:output "media-type = text/html";
declare option xdmp:output "method = xhtml";
declare option xdmp:output "omit-xml-declaration = no";


<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>News: Search</title>
  </head>
  <body>
    <div id="search">
      <h1>News Search</h1>
      <form action="search" method="get">
        <fieldset>
          <label for="q">Search for:</label>
          <input id ="q" name="q" type="text"/>
          <input type="submit"/>
        </fieldset>
      </form>
    </div>
  </body>
</html>
