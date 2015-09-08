xquery version "3.0";
(:
 : Build atom feed for all syrica.org modules
 : Module is used by atom.xql and rest.xqm 
 : @param $collection selects data collection for feed 
 : @param $id return single entry matching xml:id
 : @param $start start paged results
 : @param $perpage default set to 25 can be changed via perpage param
:)
module namespace rdfq="http://syriaca.org//rdfq";

import module namespace config="http://syriaca.org//config" at "../config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cito = "http://purl.org/spar/cito";
declare namespace cnt = "http://www.w3.org/2011/content";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace geo = "http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace gn = "http://www.geonames.org/ontology#";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace collex="http://www.collex.org/schema#";
declare namespace ra="http://www.rossettiarchive.org/schema#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace role="http://www.loc.gov/loc.terms/relators/";
declare namespace syriaca="http://syriaca.org/schema#";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

declare function rdfq:which-rdf($node as node(), $which as xs:string?){
   <p>'test'</p>
};

declare function rdfq:build-pelagios($node){
   <p>'test'</p>
};

(: Use xslt? or Typeswitch ? :)
declare function rdfq:build-collex($node){
<rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:dcterms="http://purl.org/dc/terms/"
      xmlns:collex="http://www.collex.org/schema#"
      xmlns:ra="http://www.rossettiarchive.org/schema#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
      xmlns:role="http://www.loc.gov/loc.terms/relators/"
      xmlns:syriaca="http://syriaca.org/schema#">
      {for $resource in $node/tei:TEI
       return rdfq:collex-resources($resource)
      }
</rdf:RDF>
};

declare function rdfq:collex-resources($node){
let $id := replace($node/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][1],'tei','')
return 
   <syriaca:syriaca rdf:about="ID">
      <collex:federation>MESA</collex:federation>
      <collex:archive>syriac_gazetteer</collex:archive>
      {(rdfq:collex-title($node/descendant::tei:titleStmt),
        rdfq:collex-editors($node/descendant::tei:titleStmt),
        if($node/descendant::tei:titleStmt/tei:sponsor) then 
            <role:PBL>{$node/descendant::tei:titleStmt/tei:sponsor/text()}</role:PBL>
        else ()
        )}
      <dc:type>Interactive Resource</dc:type>
      <collex:discipline>Anthropology</collex:discipline>
      <collex:discipline>Archaeology</collex:discipline>
      <collex:discipline>Architecture</collex:discipline>
      <collex:discipline>Art History</collex:discipline>
      <collex:discipline>Book History</collex:discipline>
      <collex:discipline>Classics and Ancient History</collex:discipline>
      <collex:discipline>Ethnic Studies</collex:discipline>
      <collex:discipline>Geography</collex:discipline>      
      <collex:discipline>History</collex:discipline>
      <collex:discipline>Manuscript Studies</collex:discipline>
      <collex:discipline>Philosophy</collex:discipline>               
      <collex:discipline>Religious Studies</collex:discipline>      
      <collex:genre>Reference Works</collex:genre>
      <collex:genre>Bibliography</collex:genre>
      <collex:freeculture>true</collex:freeculture>
      <collex:ocr>false</collex:ocr>
      <dc:language>en</dc:language>
      <collex:source_xml rdf:resource="{concat($id,'/tei')}"/>
      <collex:source_html rdf:resource="{concat($id,'.html')}"/>
      <rdfs:seeAlso rdf:resource="{concat($id,'.html')}"/>
      <collex:text>{string-join($node/descendant::tei:desc/descendant::text(),' ')}</collex:text>
   </syriaca:syriaca>
};

declare function rdfq:collex-title($node){
for $title in $node/descendant::tei:title
return 
    if($title[@level='m']) then 
        <dc:source>{normalize-space($title)}</dc:source>
    else
        <dc:title>{normalize-space($title)}</dc:title>
};

declare function rdfq:collex-editors($node){
for $editor in $node/descendant::tei:editor
return 
    if($editor[@role='creator']) then 
        <role:AUT>{$editor/text()}</role:AUT>
    else if($editor[@role='general']) then 
        <role:EDT>{$editor/text()}</role:EDT>
    else ()
};

(:
<dc:date>4-DIGIT-DATE</dc:date>
<dcterms:hasPart rdf:resource="ANOTHER_OBJECT_CONTAINED_BY_THIS_OBJECT"/>
      <dcterms:isPartOf rdf:resource="AN_OBJECT_THAT_CONTAINS_THIS_OBJECT"/>
      <dc:relation rdf:resource="AN_ASSOCIATED_OBJECT"/>
:)