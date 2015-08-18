xquery version "3.0";
(:
 :
:)
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace georss="http://www.georss.org/georss";
declare namespace xslfo="http://exist-db.org/xquery/xslfo";

declare variable $collection {request:get-parameter('collection', '')};
declare variable $id {request:get-parameter('id', '')};
declare variable $perpage {request:get-parameter('perpage', 25) cast as xs:integer};
declare variable $start {request:get-parameter('start', 1) cast as xs:integer};

let $tei := doc('/db/apps/srophe-data/data/persons/tei/13.xml')
let $fop-config :=
<fop version="1.0">
   <renderers>
       <renderer mime="application/pdf">
         <fonts>
          <directory>http://wwwb.library.vanderbilt.edu/resources/fonts</directory>
          <auto-detect/>
        </fonts>
       </renderer>
   </renderers>
</fop> 

let $fo-doc := transform:transform($tei, doc('../resources/xsl/tei2PDF.xsl'),())
let $pdf := xslfo:render($fo-doc, 'application/pdf', (), $fop-config)
return response:stream-binary($pdf, "application/pdf", "output.pdf")
   
