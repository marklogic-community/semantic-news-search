# Semantic News Search

This sample application illustrates some uses of MarkLogic 7's
new semantic search capabilities, including support for the SPARQL
RDF query language.

For installation instructions, see "Installation steps" at the
end of this document.


## Project overview

The project consists of a MarkLogic search application enhanced
with some RDF-based features:

  * RDF-based infobox generation for countries and companies
  * RDF-based search term expansion
  * Display of RDF metadata associated with each search result

The data set consists of articles from BBC World News. We used
the OpenCalais web service to automatically identify article
categories, as well as entities mentioned inside each article
(such as countries, companies, people, cities, etc.). All such
RDF metadata returned from the web service was then loaded into
MarkLogic's triple store. For infobox data, we used RDF from
DBpedia.org, identified via OpenCalais-supplied sameAs links.


## How the infobox works
When the user types "ireland", for example, not only will all
articles mentioning "ireland" be returned in the results, but an
infobox containing some facts about the country of Ireland will
be displayed on the right-hand side of the page.

### Getting the data

Once the pre-archived data has been loaded ([steps 1-3](#installation-steps)
in the installation steps), we additionally need to associate the 
OpenCalais-identified entities with corresponding DBpedia resources.
Since our infobox will support both countries and companies, we use
SPARQL to find all the currently (non-DBpedia) resources of those types,
and then go to opencalais.com to retrieve further information about them.

Once we have those sameAs links loaded, we can now pull in the necessary
data from DBpedia.org.

Each step in this two-step process uses the [sem:sparql()](http://docs.marklogic.com/sem:sparql)
function, as well as the [sem:rdf-load()](http://docs.marklogic.com/sem:rdf-load) function:

  1. [load-opencalais-sameAs-links.xqy](src/main/xquery/ingestion/load-opencalais-sameAs-links.xqy)
  2. [load-dbpedia-data.xqy](src/main/xquery/ingestion/load-dbpedia-data.xqy)


### Generating the infobox

Once the data has been loaded, we use SPARQL to find the relevant
infobox resource based on what the user typed into the search box.
The SPARQL used in this module is an example of how you can use
the [cts:contains()](http://docs.marklogic.com/cts:contains) function
in a SPARQL FILTER expression, as well as the use of
[sem:describe()](http://docs.marklogic.com/sem:describe) to return
the triples relevant to the resource's infobox:

  * [infobox.xqy](src/main/xquery/application/lib/infobox.xqy)

Once the triples are returned (in XML format), their display
is configured, depending on which type of resource is being
rendered (a company or a country), and implemented, in this XSLT module:

  * [infobox.xsl](src/main/xquery/application/lib/infobox.xsl)


## Installation steps

1. Configure database & servers using the packaging config.

   Go to MarkLogic Server's [Configuration Manager page](http://localhost:8002),
   click the "Import" tab, and browse to the packaging config
   [zip file](config/enhanced-search-package.zip) provided in this project.
   Then review and apply the imported server configuration changes.

2. Load the pre-processed BBC documents using mlcp:

   Here's the command I used, ran inside the "data/ingest" directory
   (be sure to first change the output_uri_replace value):

        mlcp.bat import -host localhost -port 8022 -username admin -password admin -input_file_path content -mode local -input_file_type documents -output_collections "http://www.bbc.co.uk/news/content" -output_uri_replace "C:/cygwin/home/evanlenz/semantic-search/data/ingest/content,'content/news'"
   
3. Load the OpenCalais-supplied RDF triples using mlcp.

   Here's the command, ran inside the "data/ingest" directory

        mlcp.bat import -host localhost -port 8022 -username admin -password admin -input_file_path graph -mode local -input_file_type RDF -output_collections "http://www.bbc.co.uk/news/graph" -output_uri_prefix "/graph/news/"

4. Create an app server, e.g. "EnhancedSearchMaintenance",
   with a server root pointing to the "src/main/xquery"
   directory. This will be for running the following data
   preparation scripts. The next steps assume it's at port 8023.

5. Copy the triples needed for faceting into document
   properties by running the following script:
   http://localhost:8023/ingestion/store-triples-as-properties.xqy 

   See the error log file to track its progress.
 
6. Create the necessary indexes to support faceting
   by running the following script:
   http://localhost:8023/ingestion/create-field-indexes.xqy

7. Test the app at http://localhost:8021/search. Faceting
   should now work.

### Loading the infobox data

1. Fetch sameAs links from opencalais.com, by invoking this script:
   http://localhost:8023/ingestion/load-opencalais-sameAs-links.xqy

   See the error log file to track its progress.

   NOTE: d.opencalais.com seems to be intermittently unavailable;
   try again later if necessary.

   Also, maddeningly, not all the sameAs links, particularly
   the dbpedia.org ones, appear in every request. This too
   is intermittent. You might want to run the script when
   it appears that opencalais.com is actually returning
   dbpedia.org sameAs links. Refresh this page as a test:
   http://d.opencalais.com/er/company/ralg-tr1r/9bb26018-f501-329e-b57d-5e1ec16f1bd0.html

   The upshot is that you may get only a portion of the available
   sameAs links, and possibly different ones on different invocations.
   This determines which entities will have corresponding infoboxes.


2. Fetch the infobox data from DBPedia by invoking this script:
   http://localhost:8023/ingestion/load-dbpedia-data.xqy

   See the error log file to track its progress.
