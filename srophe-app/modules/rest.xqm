xquery version "3.0";

(: Syriaca.org restxq file. :)
module namespace api="http://syriaca.org/api";
(: Syriaca.org modules :)
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "lib/tei2html.xqm";
import module namespace cntneg="http://syriaca.org/cntneg" at "lib/content-negotiation.xqm";

(:eXist modules:)
import module namespace req="http://exquery.org/ns/request";

(: eXist SPARQL module for SPARQL endpoint, comment out if not using SPARQL module :)
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

(: For output annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Establish root directory for restxq :)
declare variable $api:repo {replace($global:app-root, '/db/apps/','')};

(: Establish API endpoints :)

(:
 : Get records with coordinates
 : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html
 : @param $collection filter on collection - not implmented yet
 : Serialized as geoJSON
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/json")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("collection", "{$collection}", "")
function api:coordinates($type as xs:string*, $collection as xs:string*) {
    cntneg:content-negotiation(api:get-records-with-coordinates($type, $collection), 'geojson',())
};

(:
 : Get records with coordinates
 : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html
 : @param $collection filter on collection - not implmented yet
 : Serialized as KML
:)
declare
    %rest:GET
    %rest:path("/srophe/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("collection", "{$collection}", "")
function api:coordinates($type as xs:string*, $collection as xs:string*) {
    cntneg:content-negotiation(api:get-records-with-coordinates($type, $collection), 'kml',())
};

(:~
 Search API, returns JSON
 @param $element element to be searched. Accepts:
    persName
    placeName
    title
    author
    note
    event
    desc
    location
    idno
 @param $collection accepts:
    Gateway to the Syriac Saints
    The Syriac Biographical Dictionary
    The Gorgias Encyclopedic Dictionary of the Syriac Heritage
    The Syriac Gazetteer
    Bibliotheca Hagiographica Syriaca Electronica
    SPEAR: Syriac Persons, Events, and Relations
    Qadishe: A Guide to the Syriac Saints
    A Guide to Syriac Authors
    A Guide to the Syriac Saints
  @param $lang accepts:
    en, syr, ar, syr-Syrj, grc, la, 
    fr, en-x-gedsh, de, fr-x-bhs, it, syr-Syrn, 
    el, ar-Syrc, eng, ara-syrc, lat, fr-x-zanetti,
    fr-x-fiey, fr-x-bhsyre, syr-Syrc, cop, es, 
    nl, hy, ka, cu, gez, ru, ru-Latn-iso9r95, syr-pal, 
    pt, sog, pl, el-Latn-iso843
  @param $author accepts string value. May only be used when $element = 'title'    
:)
(: 
    @note: This function is important! Used by eKtobe
    add disabmiguation information (dates for persNames)
    Add addtional format options? OAI,ATOM,TEI?
    Add general search option for all tei (body)
    NOTE make lang and collection accept multiple values. (rework xpath fo accept multiple values.) 
    May need to add distinct values
:)
declare
    %rest:GET
    %rest:path("/srophe/api/search/{$element}")
    %rest:query-param("q", "{$q}", "")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("lang", "{$lang}", "")
    %rest:query-param("author", "{$author}", "")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
function api:search-element($element as xs:string?, $q as xs:string*, $collection as xs:string*, $lang as xs:string*, $author as xs:string*){
    let $collection := if($collection != '') then
                            if($collection = ('Gateway to the Syriac Saints',
                            'The Syriac Biographical Dictionary',
                            'The Gorgias Encyclopedic Dictionary of the Syriac Heritage',
                            'The Syriac Gazetteer',
                            'Bibliotheca Hagiographica Syriaca Electronica',
                            'SPEAR: Syriac Persons, Events, and Relations',
                            'Qadishe: A Guide to the Syriac Saints',
                            'A Guide to Syriac Authors',
                            'A Guide to the Syriac Saints')) then 
                                concat("[.//tei:title = '",$collection,"']")
                            else ()
                        else ()
    let $options :=                  
        "<options>
            <default-operator>and</default-operator>
            <phrase-slop>1</phrase-slop>
            <leading-wildcard>yes</leading-wildcard>
            <filter-rewrite>yes</filter-rewrite>
        </options>"                          
    let $lang := if($lang != '') then concat("[@xml:lang = '",$lang,"']") 
                 else ()
    let $author := if($author != '') then 
                     concat("[ft:query(.//tei:author,'",$author,"',",$options,")]")
                 else () 
               
    let $eval-string := concat("collection('",$global:data-root,"')//tei:TEI[ft:query(.//tei:",$element,",'",$q,"*',",$options,")]",$lang,$collection,$author)
    let $hits := util:eval($eval-string)
    return 
        if(count($hits) gt 0) then 
            <json:value>
                (
                    <id>0</id>,
                    <action>{$q}</action>,
                    <info>hits: {count($hits)}</info>,
                    <start>1</start>
               <results>
               {
                for $hit in $hits
                let $id := replace($hit/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei','')
                let $dates := 
                    if($element = 'persName') then 
                        string-join($hit/descendant::tei:body/descendant::tei:birth/descendant-or-self::text() 
                        | $hit/descendant::tei:body/descendant::tei:death/descendant-or-self::text() | 
                        $hit/descendant::tei:body/descendant::tei:floruit/descendant-or-self::text(),' ')
                    else ()
                let $element-text := util:eval(concat("$hit//tei:",$element,"[ft:query(.,'",$q,"*',",$options,")]"))                   
                return
                        <json:value json:array="true">
                            <id>{$id}</id>
                            {for $e in $element-text 
                             return 
                                element {xs:QName($element)} { normalize-space(string-join($e//text(),' ')) }}
                            {if($dates != '') then <dates>{normalize-space($dates)}</dates> else ()}
                        </json:value>
                }
                </results>)
            </json:value>
        else   
            <json:value>
                <json:value json:array="true">
                    <id>0</id>
                    <action>1</action>
                    <info>No results</info>
                    <start>1</start>
                </json:value>
            </json:value>
};
(:
 : SPARQL endpoint GET
 : @param $query SPARQL query
 : @param $format Format for results, json or xml
:)
declare
    %rest:GET
    %rest:path("/srophe/api/sparql")
    %rest:query-param("query", "{$query}", "")
    %rest:query-param("format", "{$format}", "")
    %rest:header-param("Content-Type", "{$content-type}")
function api:coordinates($query as xs:string*, $format as xs:string*, $content-type as item()*) {
   let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'xml'
   return
   (<rest:response> 
        <http:response status="200"> 
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Access-Control-Allow-Methods" value="POST"/>
        </http:response> 
      </rest:response>,sparql:query($query))
     (:cntneg:content-negotiation(sparql:query($query), $request-format,())):)
};

(:
 : SPARQL endpoint POST 
:)
declare
    %rest:POST('{$data}')
    %rest:path("/srophe/api/sparql")
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-serialize($data as item()*, $content-type as item()*) {
   (<rest:response> 
        <http:response status="200"> 
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Access-Control-Allow-Methods" value="GET"/>
        </http:response> 
      </rest:response>,sparql:query($data))
};

(:
 : Data dump for all records
 : @param $collection filter on collection - see repo-config.xml for collection names
 : @param $format -supported formats rdf/ttl/xml/html/json
 : @param $start
 : @param $limit
 : @param $content-type - serializtion based on format or Content-Type header. 
:)
declare
    %rest:GET
    %rest:path("/srophe/api/data")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("format", "{$format}", "")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("limit", "{$limit}", 50)
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-dump(
    $type as xs:string*, 
    $collection as xs:string*, 
    $format as xs:string*, 
    $start as xs:integer*,
    $limit as xs:integer*,
    $content-type as item()*) {
    let $data := if($collection != '') then
                    collection($global:data-root || '/' || $collection)
                 else collection($global:data-root)
    let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'xml'
    return cntneg:content-negotiation(subsequence($data, $start, $limit), $request-format,())
};

(:
 : Data dump for any results set may be posted to this endpoint for serialization
 : @param $content-type - serializtion based on format or Content-Type header. 
:)
declare
    %rest:POST('{$data}')
    %rest:path('/srophe/api/data/serialize')
    %rest:header-param("Content-Type", "{$content-type}")
function api:data-serialize($data as item()*, $content-type as item()*) {
   cntneg:content-negotiation($data, $content-type,())
};

(:~
  : Use resxq to for content negotiation
  : @param $folder syriaca.org subcollection 
  : @param $page record id
  : @note extension is passed in with $page parameter, parsed out after .
  :)
declare
    %rest:GET
    %rest:path("/srophe/{$folder}/{$page}")
    %rest:header-param("Content-Type", "{$content-type}")
function api:get-page($folder as xs:string?, $page as xs:string?, $content-type as item()*) {
    let $path := concat($folder,'/',$page)
    let $work-uris := 
        distinct-values(for $collection in $global:get-config//repo:collection
        let $short-path := replace($collection/@record-URI-pattern,$global:base-uri,'')
        return replace($short-path,'/',''))        
    return 
        if($folder = $work-uris) then 
            let $id :=  if(contains($page,'.')) then
                            concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,substring-before($page,"."))
                        else concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,$page)
            let $data := if(api:get-tei($id) != '') then api:get-tei($id) else api:not-found()
            return cntneg:content-negotiation($data, $content-type, $path) 
        else api:not-found()
};

(:~
  : Use resxq to for content negotiation
  : @param $folder syriaca.org subcollection 
  : @param $page record id
  : @param $extension record extension
  :)
declare
    %rest:GET
    %rest:path("/srophe/{$folder}/{$page}/{$extension}")
    %rest:header-param("Content-Type", "{$content-type}")
function api:get-page($folder as xs:string?, $page as xs:string?, $extension as xs:string, $content-type as item()*) {
    let $path := concat($folder,'/',$page,'.',$extension)
    let $work-uris := 
        distinct-values(for $collection in $global:get-config//repo:collection
        let $short-path := replace($collection/@record-URI-pattern,$global:base-uri,'')
        return replace($short-path,'/',''))
    return 
        if($folder = $work-uris) then 
            let $id :=  if(contains($page,'.')) then
                            concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,substring-before($page,"."))
                        else concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,$page)
            let $data := if(api:get-tei($id) != '') then api:get-tei($id) else api:not-found()
            return cntneg:content-negotiation($data, $extension, ()) 
        else api:not-found()
}; 

(: Helper functions :)

(: Function to generate a 404 Not found response 
response:redirect-to()
:)
declare function api:not-found(){
  (<rest:response>
    <http:response status="404" message="Not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <rest:forward>{ xs:anyURI(concat($global:nav-base, '/404.html')) }</rest:forward>
  )
};

(:~
 : Get TEI record based on $id
 : Builds full uri based on repo.xml
:)
declare function api:get-tei($id){
    root(collection($global:data-root)//tei:idno[@type='URI'][. = $id])
};

(:~
 : Get all records with coordinates
 : @param $type 
 : @param $collection
 :)
declare function api:get-records-with-coordinates($type as xs:string*, $collection as xs:string*){
    if($type) then
        if(contains($type,',')) then 
            let $types := 
                if(contains($type,',')) then  string-join(for $type-string in tokenize($type,',') return concat('"',$type-string,'"'),',')
                else $type
            let $path := concat("collection('",$global:data-root,"/places/tei')//tei:place[@type = (",$types,")]//tei:geo") 
            for $recs in util:eval($path) 
            return $recs 
        else collection($global:data-root || "/places/tei")//tei:place[@type=$type]
    else collection($global:data-root || "/places/tei")//tei:geo/ancestor::tei:TEI
};