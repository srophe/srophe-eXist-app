xquery version "3.0";

module namespace api="http://syriaca.org/api";
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace req="http://exquery.org/ns/request";

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
(: Used for content negotiation :)
import module namespace tei2ttl="http://syriaca.org/tei2ttl" at "lib/tei2ttl.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm";
import module namespace geojson="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace geokml="http://syriaca.org/geokml" at "lib/geokml.xqm";

(: Namespaces :)
declare namespace json="http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace http="http://expath.org/ns/http-client";


(:~ 
 : Get all data, specify serialization in request headers or using the $format parameter 
 : @param $format acceptable formats tei/ttl/rdf/geojson
 : @param $start start of results set
 : @param $limit number of results to return 
:)
declare
    %rest:GET
    %rest:path("/tcadrt/api/data")
    %rest:query-param("format", "{$format}", "")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("limit", "{$limit}", 50)
    %rest:header-param("Content-Type", "{$content-type}")
function api:bulk-by-headers($content-type, $format as xs:string*, $start as xs:integer*, $limit as xs:integer*) {
    let $data := subsequence(collection($global:data-root)/tei:TEI, $start, $limit)
    let $request-format := if($format != '') then $format else $content-type
    return api:content-negotiation($data, $request-format, ())
};

(:~ 
 : Serialization for internal pages, mostly place and features
 : Pass in path to page. 
 : Pass in content type via header or page extension 
 :)
declare
    %rest:GET
    %rest:path("/tcadrt/{$folder}/{$page}")
    %rest:header-param("Content-Type", "{$content-type}")
function api:get-page($folder as xs:string?, $page as xs:string?, $content-type) {
    let $content := concat('../',$folder,'/',$page)
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
            return api:content-negotiation($data, $content-type, $content) 
        else api:content-negotiation((), $content-type, $content)
};


(:----------------------------------------------------------------------------------------------:)
(: API helper functions :)

(:~
 : Get TEI record based on $id and $collection
 : Builds full uri based on repo.xml
:)
declare function api:get-tei($id){
    root(collection($global:data-root)//tei:idno[. = $id])
};

(:~
 : Process HTML templating from within a RestXQ function.
:)
declare function api:render-html($content as xs:string, $id as xs:string?){
    let $content := doc($content)
    return 
        if($content) then 
             let $config := map {
                 $templates:CONFIG_APP_ROOT := $config:app-root,
                 $templates:CONFIG_STOP_ON_ERROR := true(),
                 $templates:CONFIG_PARAM_RESOLVER := function($param as xs:string) as xs:string* {
                     (:req:parameter($param):)
                     switch ($param)
                        case "id" return
                            $id
                        default return req:parameter($param)
                 }
             }
             
             let $lookup := function($functionName as xs:string, $arity as xs:int) {
                 try {
                     function-lookup(xs:QName($functionName), $arity)
                 } catch * {
                     ()
                 }
             }
             return
                 templates:apply($content, $lookup, (), $config)
        else $content (:api:not-found():)        
};

(: Function to generate a 404 Not found response :)
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

(:----------------------------------------------------------------------------------------------:)

(: Content negotiation, pass in data :)
declare function api:content-negotiation($data as item()*, $content-type as xs:string?, $path as xs:string?){
    let $page := if(contains($path,'/')) then tokenize($path,'/')[last()] else $path
    let $type := if(substring-after($page,".") != '') then 
                    substring-after($page,".")
                 else if($content-type) then 
                    api:determine-extension($content-type)
                 else 'html'
    let $flag := api:determine-type-flag($type)
    return 
        if($flag = ('tei','xml')) then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='xml'/>
                    <output:media-type value='text/xml'/>
                </output:serialization-parameters>
             </rest:response>,$data)
        else if($flag = 'atom') then <message>Not an available data format.</message>
        else if($flag = 'rdf') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                    <http:header name="media-type" value="application/xml"/>
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='xml'/>
                    <output:media-type value='application/xml'/>
                </output:serialization-parameters>
             </rest:response>, tei2rdf:rdf-output($data))
        else if($flag = ('turtle','ttl')) then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
                    <http:header name="method" value="text"/>
                    <http:header name="media-type" value="text/plain"/>
                </http:response>
                <output:serialization-parameters>
                    <output:method value='text'/>
                    <output:media-type value='text/plain'/>
                </output:serialization-parameters>
            </rest:response>, tei2ttl:ttl-output($data))
        else if($flag = 'geojson') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/json; charset=utf-8"/>
                    <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/> 
                </http:response> 
             </rest:response>, geojson:geojson($data))
        else if($flag = 'kml') then 
            (<rest:response> 
                <http:response status="200"> 
                    <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                </http:response> 
                <output:serialization-parameters>
                    <output:method value='xml'/>
                    <output:media-type value='application/xml'/>
                    </output:serialization-parameters>                        
             </rest:response>, geokml:kml($data))
        else if($flag = 'json') then <message>Not an available data format.</message>
        (: Output as html, either using eXist templating, or just dumping data as html :)
        else 
            let $work-uris := 
                distinct-values(for $collection in $global:get-config//repo:collection
                    let $short-path := replace($collection/@record-URI-pattern,$global:base-uri,'')
                    return replace($short-path,'/',''))
            let $folder := tokenize(substring-before($path,concat('/',$page)),'/')[last()]                    
            return  
                if($folder = $work-uris) then         
                    let $id :=  if(contains($page,'.')) then
                                    concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,substring-before($page,"."))
                                else concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,$page)
                    let $collection := $global:get-config//repo:collection[contains(@record-URI-pattern,concat('/',$folder))]/@app-root
                    let $html-path := concat('../',$global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@app-root,'/record.html') 
                    return  
                        (<rest:response> 
                            <http:response status="200"> 
                                <http:header name="Content-Type" value="text/html; charset=utf-8"/>  
                            </http:response> 
                            <output:serialization-parameters>
                                <output:method value='html5'/>
                                <output:media-type value='text/html'/>
                            </output:serialization-parameters>                        
                        </rest:response>, api:render-html($html-path,$id))  
                else if($page != '') then
                    (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="text/html; charset=utf-8"/>  
                        </http:response> 
                        <output:serialization-parameters>
                            <output:method value='html5'/>
                            <output:media-type value='text/html'/>
                        </output:serialization-parameters>                        
                     </rest:response>,api:render-html($page,''))                    
                else (<rest:response> 
                            <http:response status="200"> 
                                <http:header name="Content-Type" value="text/html; charset=utf-8"/>  
                            </http:response> 
                            <output:serialization-parameters>
                                <output:method value='html5'/>
                                <output:media-type value='text/html'/>
                            </output:serialization-parameters>                        
                          </rest:response>,$data)
};

(: Utility functions to set media type-dependent values :)

(: Functions used to set media type-specific values :)
declare function api:determine-extension($header){
    if (contains(string-join($header),"application/rdf+xml") or $header = 'rdf') then "rdf"
    else if (contains(string-join($header),"text/turtle") or $header = ('ttl','turtle')) then "ttl"
    else if (contains(string-join($header),"application/ld+json") or contains(string-join($header),"application/json") or $header = ('json','ld+json')) then "json"
    else if (contains(string-join($header),"application/tei+xml") or contains(string-join($header),"text/xml") or $header = ('tei','xml')) then "tei"
    else if (contains(string-join($header),"application/atom+xml") or $header = 'atom') then "atom"
    else if (contains(string-join($header),"application/vnd.google-earth.kmz") or $header = 'kml') then "kml"
    else if (contains(string-join($header),"application/geo+json") or $header = 'geojson') then "geojson"
    else "html"
};

declare function api:determine-media-type($extension){
  switch($extension)
    case "rdf" return "application/rdf+xml"
    case "tei" return "application/tei+xml"
    case "tei" return "text/xml"
    case "atom" return "application/atom+xml"
    case "ttl" return "text/turtle"
    case "json" return "application/ld+json"
    case "kml" return "application/vnd.google-earth.kmz"
    case "geojson" return "application/geo+json"
    default return "text/html"
};

(: NOTE: not sure this is needed:)
declare function api:determine-type-flag($extension){
  switch($extension)
    case "rdf" return "rdf"
    case "atom" return "atom"
    case "tei" return "xml"
    case "xml" return "xml"
    case "ttl" return "turtle"
    case "json" return "json"
    case "kml" return "kml"
    case "geojson" return "geojson"
    case "html" return "html"
    case "htm" return "html"
    default return "html"
};
