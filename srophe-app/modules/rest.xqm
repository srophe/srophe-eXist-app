xquery version "3.0";

module namespace api="http://syriaca.org/api";
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace app="http://syriaca.org/templates" at "app.xql";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace tei2ttl="http://syriaca.org/tei2ttl" at "lib/tei2ttl.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm";
import module namespace geojson="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace geokml="http://syriaca.org/geokml" at "lib/geokml.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace req="http://exquery.org/ns/request";

(: Namespaces :)
declare namespace json="http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace http="http://expath.org/ns/http-client";

(:----------------------------------------------------------------------------------------------:)
(: Main html pages :)
declare
    %rest:GET
    %rest:path("/tcadrt/home")
    %output:media-type("text/html")
    %output:method("html5")
function api:root() {
    let $content := '../index.html'
    return api:render-html($content,'')
};

declare
    %rest:GET
    %rest:path("/tcadrt/{$resource}")
    %output:media-type("text/html")
    %output:method("html5")
function api:resolve-resource($resource) {
    let $content := concat('../',$resource,'.html')
    return api:render-html($content,'')
};

declare
    %rest:GET
    %rest:path("/tcadrt/{$page}.html")
    %output:media-type("text/html")
    %output:method("html5")
function api:get-page($page) {
    let $content := concat('../',$page,'.html')
    return api:render-html($content,'')
};


(: Add plain vanilla json, maybe. :)
declare
    %rest:GET
    %rest:path("/tcadrt/{$folder}/{$page}")
    %output:media-type("text/html")
    %output:method("html5")
function api:get-page($folder as xs:string?, $page as xs:string?) {
    let $content := concat('../',$folder,'/',$page)
    let $work-uris := 
        distinct-values(for $collection in $global:get-config//repo:collection
        let $short-path := replace($collection/@record-URI-pattern,$global:base-uri,'')
        return replace($short-path,'/',''))
    return 
        if($folder = $work-uris) then 
            let $extension := substring-after($page,".")
            let $response-media-type := api:determine-media-type($extension)
            let $flag := api:determine-type-flag($extension)
            let $id :=  if(contains($page,'.')) then
                            concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,substring-before($page,"."))
                        else concat($global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@record-URI-pattern,$page)
            return
                if($flag = ('tei','xml')) then 
                    (<rest:response> 
                        <http:response status="200"> 
                          <http:header name="Content-Type" value="application/xml; charset=utf-8"/> 
                        </http:response> 
                      </rest:response>,
                      api:get-tei($id))
                else if($flag = 'atom') then <message>atom</message>
                else if($flag = 'rdf') then 
                     (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="application/rdf+xml; charset=utf-8"/>  
                        </http:response> 
                      </rest:response>, 
                      tei2rdf:rdf-output(api:get-tei($id)))
                else if($flag = 'turtle') then 
                     (<rest:response> 
                            <http:response status="200"> 
                              <http:header name="Content-Type" value="text/turtle; charset=utf-8"/> 
                            </http:response> 
                          </rest:response>, 
                          tei2ttl:ttl-output(api:get-tei($id)))
                else if($flag = 'geojson') then 
                     (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="application/json; charset=utf-8"/>
                            <http:header name="Access-Control-Allow-Origin" value="application/json; charset=utf-8"/> 
                        </http:response> 
                      </rest:response>, 
                      geojson:geojson(api:get-tei($id)))
                else if($flag = 'kml') then 
                     (<rest:response> 
                        <http:response status="200"> 
                            <http:header name="Content-Type" value="application/xml; charset=utf-8"/>  
                        </http:response> 
                      </rest:response>, 
                      geokml:kml(api:get-tei($id)))
                else if($flag = 'json') then <message>atom</message>
                else 
                    let $collection := $global:get-config//repo:collection[contains(@record-URI-pattern,concat('/',$folder))]/@app-root
                    let $html-path := concat('../',$global:get-config//repo:collection[contains(@record-URI-pattern, $folder)][1]/@app-root,'/record.html') 
                    return api:render-html($html-path,$id)
                    (:    <message>{$content} collection path: {string($collection)} html path {$html-path} id {$id}</message>:)                                     
        else api:render-html($content,'')
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
declare function api:render-html($content, $id as xs:string?){
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
        else api:not-found()        
};

(: Function to generate a 404 Not found response :)
declare function api:not-found(){
  <rest:response>
    <http:response status="404" message="Not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};

(:----------------------------------------------------------------------------------------------:)
(: Utility functions to set media type-dependent values :)

(: Functions used to set media type-specific values :)
declare function api:determine-extension($header){
    if (contains(string-join($header),"application/rdf+xml")) then "rdf"
    else if (contains(string-join($header),"text/turtle")) then "ttl"
    else if (contains(string-join($header),"application/ld+json") or contains(string-join($header),"application/json")) then "json"
    else if (contains(string-join($header),"application/tei+xml")) then "tei"
    else if (contains(string-join($header),"text/xml")) then "tei"
    else if (contains(string-join($header),"application/atom+xml")) then "atom"
    else if (contains(string-join($header),"application/vnd.google-earth.kmz")) then "kml"
    else if (contains(string-join($header),"application/geo+json")) then "geojson"
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
    default return "html"
};
