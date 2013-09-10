= Semantic Search =

<https://wiki.marklogic.com/pages/viewpage.action?pageId=27659194>

== Things to do ==

# XQuery module to collect news stories from BBC News web site.
# Transform to extract body and related news content from web page
# Configure Open Calais Enrichment Pipeline.
# Load Content.
# Harvest images.


<http://feeds.bbci.co.uk/news/world/rss.xml?edition=uk>

<ul class="links-list">
	<li><a href="http://feeds.bbci.co.uk/news/rss.xml" >Top Stories</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/world/rss.xml" >World</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/uk/rss.xml" >UK</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/business/rss.xml" >Business</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/politics/rss.xml" >Politics</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/health/rss.xml" >Health</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/education/rss.xml" >Education &amp; Family</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/science_and_environment/rss.xml" >Science &amp; Environment</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/technology/rss.xml" >Technology</a></li>
	<li><a href="http://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml" >Entertainment &amp; Arts</a></li>
</ul>


== News Search Application ==

Search text for phrase (should title have extra weighting for relevance?).

Show search results:
* Headline.
* Highlighted matches in text.
* Total result count.
* Relevance?
* NewsItem Date.
* Categories.
* Available as Atom Feed.

Display result item:
* Render HTML news item.
* Highlighted text.
* Categories (+links).
* People (+links).
* Organisations (+links).
* Cities/Countries (+links).
* Map locations (not sure what the primary location would be).

Navigate (filter) by: 
* Categories.
* People in the news.
* Places in the news.

DBpedia Look-up Service?
* Link OpenCalais concepts to DBpedia.
* 


== REST APIs ==

REST API isn't 'classic' RESTful!

List all APIs:
<http://localhost:8002/v1/rest-apis/>

Info. for Database:
<http://localhost:8002/v1/rest-apis?database=EnhancedSearch>

Info. for Named Service:
<http://localhost:8002/v1/rest-apis/enhanced-search>

Configuration of Endpoint:
<http://localhost:8020/v1/config/properties>

Retrieve Document:
<http://localhost:8020/v1/documents?uri=%2Fcontent%2Fnews%2Fworld-asia-22965046.xml>

Search:
<http://localhost:8020/v1/search?q=&collection=http%3A%2F%2Fwww.bbc.co.uk%2Fnews%2Fcontent>