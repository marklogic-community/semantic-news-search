Semantic News Search
====================

This sample application illustrates some uses of MarkLogic 7's
new semantic search capabilities. For installation instructions,
see "Installation steps" at the end of this document.


Project overview
----------------

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
MarkLogic's triple store. (For details on how this data was prepared,
see https://github.com/marklogic/semantic-news-search/blob/master/docs/documentation.txt)


Installation steps
------------------

1. Configure database & servers using the packaging config:
   enhanced-search/config/enhanced-search-package.zip

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

Steps to load the infobox data:

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
