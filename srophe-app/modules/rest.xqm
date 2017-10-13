xquery version "3.0";

module namespace api="http://syriaca.org/api";

import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";
import module namespace geojson="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace geokml="http://syriaca.org/geokml" at "lib/geokml.xqm";
import module namespace tei2ttl="http://syriaca.org/tei2ttl" at "lib/tei2ttl.xqm";
import module namespace feed="http://syriaca.org/atom" at "lib/atom.xqm";
import module namespace sprql-queries="http://syriaca.org/sprql-queries" at "lib/sparql.xqm";
declare namespace json="http://www.json.org";
(: For output annotations  :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: For REST annotations :)
declare namespace rest = "http://exquery.org/ns/restxq";

(: For interacting with the TEI document :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace http="http://expath.org/ns/http-client";

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as JSON
:)
declare
    %rest:GET
    %rest:path("/tcadrt/api/geo/json")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "json")
    %output:media-type("application/json")
    (:%output:method("json"):)
function api:get-geo-json($type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/json; charset=utf-8"/>
    <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/>
  </http:response> 
</rest:response>, 
     api:get-geojson-node($type,$output)
) 

};

(:~
  : Use resxq to format urls for geographic API
  : @param $type string passed from uri see: http://syriaca.org/documentation/place-types.html 
  : for acceptable types 
  : @param $output passed to geojson.xqm to correctly serialize results
  : Serialized as KML
:)
declare
    %rest:GET
    %rest:path("/tcadrt/api/geo/kml")
    %rest:query-param("type", "{$type}", "")
    %rest:query-param("output", "{$output}", "kml")
    %output:media-type("application/vnd.google-earth.kmz")
    %output:method("xml")
function api:get-geo-kml($type as xs:string*, $output as xs:string*) {
(<rest:response> 
  <http:response status="200"> 
    <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
  </http:response> 
</rest:response>, 
     api:get-geojson-node($type,$output) 
) 
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
    Still to do: 
    add disabmiguation information (dates for persNames)
    Add addtional format options? OAI,ATOM,TEI?
    Add general search option for all tei (body)
    NOTE make lang and collection accept multiple values. (rework xpath fo accept multiple values.) 
    May need to add distinct values
:)
declare
    %rest:GET
    %rest:path("/tcadrt/api/search/{$element}")
    %rest:query-param("q", "{$q}", "")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("lang", "{$lang}", "")
    %rest:query-param("author", "{$author}", "")
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

(:~
  : Use resxq to format urls for tei
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/tcadrt/{$collection}/{$id}/ttl")
    %output:media-type("text/turtle")
    %output:method("text")
function api:get-ttl($collection as xs:string, $id as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="text/turtle; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
    tei2ttl:ttl-output(api:get-tei-rec($collection, $id))
     )
}; 


(:~
  : SPARQL endpoint 
  : Serialized as XML
:)
declare
    %rest:GET
    %rest:path("/tcadrt/api/sparql")
    %rest:query-param("qname", "{$qname}", "")
    %rest:query-param("id", "{$id}", "")
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:sparql-endpoint($qname as xs:string*, $id as item()*){
  if(not(empty($qname))) then
    if($qname = 'related-subjects-count') then
        sprql-queries:related-subjects-count($id)
    else if($qname = 'related-citations-count') then
        sprql-queries:related-citations-count($id) 
    else if($qname = 'label') then
        sprql-queries:label($id) 
    else <message>Submitted query is not a valid Syriaca.org named query. Please use the q paramater to submit a custom SPARQL query</message>
  else <message>No query data submitted</message>
};

(:~
  : Use resxq to format urls for tei
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML

declare 
    %rest:GET
    %rest:path("/tcadrt/ttl")
    %rest:query-param("collection", "{$collection}", "")
    %rest:query-param("start", "{$start}", "")
    %rest:query-param("perpage", "{$perpage}", "")
    %output:media-type("text/turtle")
    %output:method("text")
function api:get-ttl-collection($collection as xs:string, $start as xs:string,$perpage as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="text/turtle; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
        tei2ttl:get-ttl('',$collection,$start,$perpage)
     )
};
:)
(:~
  : Use resxq to format urls for tei
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/tcadrt/{$collection}/{$id}/tei")
    %output:media-type("text/xml")
    %output:method("xml")
function api:get-tei($collection as xs:string, $id as xs:string){
    let $rec := api:get-tei-rec($collection, $id)
    return 
        if(not(empty($rec))) then 
            (<rest:response> 
                <http:response status="200">
                  <http:header name="Content-Type" value="application/xml; charset=utf-8"/>
                  <http:header name="Access-Control-Allow-Origin" value="*"/> 
                </http:response> 
              </rest:response>, 
              api:get-tei-rec($collection, $id))
        else 
            (<rest:response> 
                <http:response status="400">
                  <http:header name="Content-Type" value="application/xml; charset=utf-8"/>
                  <http:header name="Access-Control-Allow-Origin" value="*"/> 
                </http:response> 
              </rest:response>,
              <response status="error">
                    <message>This record can not be found, please check URI and try again</message>
              </response>)
}; 

(:~
  : Return atom feed for single record
  : @param $collection syriaca.org subcollection 
  : @param $id record id
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/tcadrt/{$collection}/{$id}/atom")
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-record($collection as xs:string, $id as xs:string){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
     feed:get-entry(api:get-tei-rec($collection, $id))
    )
}; 

(:~
  : Return atom feed for syrica.org subcollection
  : @param $collection syriaca.org subcollection 
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/tcadrt/api/{$collection}/atom")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-feed($collection as xs:string, $start as xs:integer*, $perpage as xs:integer*){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
    let $feed := collection(xs:anyURI($global:data-root || $collection ))//tei:TEI
    let $total := count($feed)
    return
     feed:build-atom-feed($feed, $start, $perpage,'',$total)
     )
}; 

(:~
  : Return atom feed for syriaca.org  
  : Serialized as XML
:)
declare 
    %rest:GET
    %rest:path("/tcadrt/api/atom")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-feed($start as xs:integer*, $perpage as xs:integer*){
   (<rest:response> 
      <http:response status="200"> 
        <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
      </http:response> 
    </rest:response>, 
    let $feed := collection(xs:anyURI($global:data-root))//tei:TEI
    let $total := count($feed)
    return 
     feed:build-atom-feed($feed, $start, $perpage,'',$total)
     )
};

(:~
 : Returns tei record for syriaca.org subcollections
:)
declare function api:get-tei-rec($collection as xs:string, $id as xs:string) as node()*{
    let $uri := concat($global:base-uri,'/',$collection, '/', $id)
    return 
        if($collection='spear') then 
            let $spear-id := concat('http://syriaca.org/spear/',$id)
            return data:get-rec($spear-id)
        else data:get-rec($uri)
};

(:~
 : Build selects coordinates
:)
declare function api:get-geojson-node($type,$output){
let $geo-map :=
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
return
    if($output = 'json') then geojson:geojson($geo-map)
    else geokml:kml($geo-map)
};