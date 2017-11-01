xquery version "3.0";
(: Main module for interacting with eXist-db templates :)
module namespace app="http://syriaca.org/templates";
(: eXist modules :)
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace functx="http://www.functx.com";
(: Srophe modules :)
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";
import module namespace teiDocs="http://syriaca.org/teiDocs" at "teiDocs/teiDocs.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "lib/tei2html.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace maps="http://syriaca.org/maps" at "lib/maps.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";
(: Namespaces :)
declare namespace http="http://expath.org/ns/http-client";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
  
(:~            
 : Simple get record function, get tei record based on tei:idno
 : Builds URL from the following URL patterns defined in the controller.xql or uses the id paramter
 : Retuns 404 page if record is not found, or has been @depreciated
 : Retuns 404 page and redirects if the record has been @depreciated see https://github.com/srophe/srophe-app-data/wiki/Deprecated-Records   
:)                 
declare function app:get-rec($node as node(), $model as map(*), $collection as xs:string?, $id as xs:string?) { 
    map {"data" := 
         if($id and $id != 'page') then    
             root(collection($global:data-root)//tei:idno[. = $id])
         else <div>'Page data'</div>    
        }    
};

(:~
 : Dynamically build html title based on TEI record and/or sub-module. 
 : If this is a 'work' page representing a TEI record, use the tei:titleStmt/tei:titl
 : Otherwise try to find a matching collection title in the repo.xml
 : Use application title as default
:)
declare %templates:wrap function app:page-title($node as node(), $model as map(*), $collection as xs:string?){
    if($model("data")/tei:TEI) then 
        if(contains($model("data")/descendant::tei:titleStmt[1]/tei:title[1]/text(),' — ')) then
             substring-before($model("data")/descendant::tei:titleStmt[1]/tei:title[1],' — ')
        else $model("data")/descendant::tei:titleStmt[1]/tei:title[1]/text()
    else if($global:get-config//repo:collection[@name = $collection]) then
            string(doc($config:app-root || '/repo.xml')/repo:collection[@name = $collection]/@title)
    else $global:app-title
}; 

(:~ 
 : Add header links for alternative formats. 
 : And descriptive page metadata. 
 : ADD when rdf enabled: 
    <link type="application/rdf+xml" href="id.rdf" rel="alternate"/>
    <link type="text/turtle" href="id.ttl" rel="alternate"/>
    <link type="text/plain" href="id.nt" rel="alternate"/>
    <link type="application/json+ld" href="id.jsonld" rel="alternate"/>
:)
declare function app:metadata($node as node(), $model as map(*)) {
    if($model("data")/tei:TEI) then 
    (
    <meta name="DC.title " property="dc.title " content="{$model("data")/ancestor::tei:TEI/descendant::tei:title[1]/text()}"/>,
    if($model("data")/ancestor::tei:TEI/descendant::tei:desc or $model("data")/ancestor::tei:TEI/descendant::tei:note[@type="abstract"]) then 
        <meta name="DC.description " property="dc.description " content="{$model("data")/ancestor::tei:TEI/descendant::tei:desc[1]/text() | $model("data")/ancestor::tei:TEI/descendant::tei:note[@type="abstract"]}"/>
    else (),
    <link xmlns="http://www.w3.org/1999/xhtml" type="text/html" href="{replace($model("data")/ancestor::tei:TEI/descendant::tei:idno[1]/text(),'/tei','')}.html" rel="alternate"/>,
    <link xmlns="http://www.w3.org/1999/xhtml" type="text/xml" href="{replace($model("data")/ancestor::tei:TEI/descendant::tei:idno[1]/text(),'/tei','')}/tei" rel="alternate"/>,
    <link xmlns="http://www.w3.org/1999/xhtml" type="application/atom+xml" href="{replace($model("data")/ancestor::tei:TEI/descendant::tei:idno[1]/text(),'/tei','')}/atom" rel="alternate"/>
    )
    else ()
};

(:~ 
 : Enables shared content with template expansion.  
 : Used for shared menus in navbar where relative links can be problematic 
 : @param $node
 : @param $model
 : @param $path path to html content file, relative to app root. 
:)
declare function app:shared-content($node as node(), $model as map(*), $path as xs:string){
    let $links := doc($global:app-root || $path)
    return templates:process(global:fix-links($links/node()), $model)
};

(:~                   
 : Traverse main nav and "fix" links based on values in config.xml
 : Replaces $app-root with vaule defined in config.xml. 
 : This allows for more flexible deployment for dev and production environments.   
:)
declare
    %templates:wrap
function app:fix-links($node as node(), $model as map(*)) {
    templates:process(app:fix-links-typeswitch($node/node()), $model)
};

(:
 : Addapted from https://github.com/eXistSolutions/hsg-shell
 : Recurse through menu output absolute urls based on config.xml values. 
 : @param $nodes html elements containing links with '$app-root'
:)
declare function app:fix-links-typeswitch($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(html:a) return
                let $href := replace($node/@href, "\$app-root", $global:nav-base)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element(html:form) return
                let $action := replace($node/@action, "\$app-root", $global:nav-base)
                return
                    <form action="{$action}">
                        {$node/@* except $node/@action, app:fix-links-typeswitch($node/node())}
                    </form>  
            case element(html:link) return
                let $href := replace($node/@href, "\$app-root", $global:nav-base)
                return
                    <link href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </link>
            case element(html:script) return
                let $href := replace($node/@src, "\$app-root", $global:nav-base)
                return
                    <script src="{$href}">
                        {$node/@* except $node/@src, $node/node()}
                    </script>                     
            case element() return
                element { node-name($node) } {
                    $node/@*,  app:fix-links-typeswitch($node/node())
                }
            default return
                $node
};

(:~
 : Display keyboard menu 
:)
declare function app:keyboard-select-menu($node, $model, $input-id){
    global:keyboard-select-menu($input-id)
};

(:~ 
 : Adds google analytics from config.xml
 : @param $node
 : @param $model 
:)
declare  
    %templates:wrap 
function app:google-analytics($node as node(), $model as map(*)){
   $global:get-config//google_analytics/text() 
};

(:~  
 : Default title display, used if no sub-module title function.
 : Used by templating module, not needed if full record is being displayed 
:)
declare function app:h1($node as node(), $model as map(*)){
 global:tei2html(
 <srophe-title xmlns="http://www.tei-c.org/ns/1.0">{(
    if($model("data")/descendant::*[@syriaca-tags='#syriaca-headword']) then
        $model("data")/descendant::*[@syriaca-tags='#syriaca-headword']
    else $model("data")/descendant::tei:titleStmt[1]/tei:title[1], $model("data")/descendant::tei:idno[1]
    )}
 </srophe-title>)
}; 


(:~ 
 : Data formats and sharing
 : to replace app-link
 :)
declare %templates:wrap function app:other-data-formats($node as node(), $model as map(*), $formats as xs:string?){
let $id := replace($model("data")/descendant::tei:idno[contains(., $global:base-uri)][1],'/tei','')
return 
    if($formats) then
        <div class="container" style="width:100%;clear:both;margin-bottom:1em; text-align:right;">
            {
                for $f in tokenize($formats,',')
                return 
                    if($f = 'tei') then
                        (<a href="{concat(replace($id,$global:base-uri,$global:nav-base),'.tei')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the TEI XML data for this record." >
                             <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> TEI/XML
                        </a>, '&#160;')
                    else if($f = 'print') then                        
                        (<a href="javascript:window.print();" type="button" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to send this page to the printer." >
                             <span class="glyphicon glyphicon-print" aria-hidden="true"></span>
                        </a>, '&#160;')  
                   else if($f = 'rdf') then
                        (<a href="{concat(replace($id,$global:base-uri,$global:nav-base),'.rdf')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the RDF-XML data for this record." >
                             <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> RDF/XML
                        </a>, '&#160;')
                  else if($f = 'ttl') then
                        (<a href="{concat(replace($id,$global:base-uri,$global:nav-base),'.ttl')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the RDF-Turtle data for this record." >
                             <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> RDF/TTL
                        </a>, '&#160;')
                  else if($f = 'geojson') then
                        if($model("data")/descendant::tei:location/tei:geo) then 
                        (<a href="{concat(replace($id,$global:base-uri,$global:nav-base),'.geojson')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the GeoJSON data for this record." >
                             <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> GeoJSON
                        </a>, '&#160;')
                        else()
                  else if($f = 'kml') then
                        if($model("data")/descendant::tei:location/tei:geo) then
                            (<a href="{concat(replace($id,$global:base-uri,$global:nav-base),'.kml')}" class="btn btn-default btn-xs" id="teiBtn" data-toggle="tooltip" title="Click to view the KML data for this record." >
                             <span class="glyphicon glyphicon-download-alt" aria-hidden="true"></span> KML
                            </a>, '&#160;')
                         else()                           
                   else () 
                
            }
            <br/>
        </div>
    else ()
};


(:~  
 : Display any TEI nodes passed to the function via the paths parameter
 : Used by templating module, defaults to tei:body if no nodes are passed. 
 : @param $paths comma separated list of xpaths for display. Passed from html page  
:)
declare function app:display-nodes($node as node(), $model as map(*), $paths as xs:string?, $wrap as xs:string?){
    let $data := $model("data")
    return 
        if($paths != '') then
            if($wrap != '') then 
                global:tei2html(element{xs:QName($wrap)} {
                    for $p in $paths
                    return util:eval(concat('$data',$p))
                    })
            else global:tei2html(
                    for $p in $paths
                    return util:eval(concat('$data',$p)))
        else global:tei2html($model("data")/descendant::tei:body)       
}; 

(:
 : Return tei:body/descendant/tei:bibls for use in sources
:)
declare %templates:wrap function app:display-sources($node as node(), $model as map(*)){
    let $sources := $model("data")/descendant::tei:body/descendant::tei:bibl
    return global:tei2html(<sources xmlns="http://www.tei-c.org/ns/1.0">{$sources}</sources>)
};

(:~
 : Passes any tei:geo coordinates in record to map function. 
 : Suppress map if no coords are found. 
:)                   
declare function app:display-map($node as node(), $model as map(*)){
    let $related := app:external-relationships($node,$model,'dct:isPartOf')
    return 
        if($model("data")//tei:geo) then
            if($related//tei:geo) then
                maps:build-map(($model("data"),$related),0)
            else maps:build-map($model("data"),0)
        else if($related//tei:geo) then 
            maps:build-map($related,0)
        else ()
};

(:~
 : Process relationships uses lib/timeline.xqm module
:)                   
declare function app:display-timeline($node as node(), $model as map(*)){
    if($model("data")/descendant::tei:body/descendant::*[@when or @notBefore or @notAfter]) then
        <div>                
            <div>{timeline:timeline($model("data")/descendant::tei:body/descendant::*[@when or @notBefore or @notAfter], 'Timeline')}</div>
            <div class="indent">
                <h4>Dates</h4>
                <ul class="list-unstyled">
                    {
                        for $date in $model("data")/descendant::tei:body/descendant::*[@when or @notBefore or @notAfter] 
                        return <li>{global:tei2html($date)}</li>
                    }
                </ul> 
            </div>     
        </div>
     else ()
};

(:
 : Return tei:body/descendant/tei:bibls for use in sources
:)
declare %templates:wrap function app:display-citation($node as node(), $model as map(*)){
    global:tei2html(<citation xmlns="http://www.tei-c.org/ns/1.0">{$model("data")//tei:teiHeader | $model("data")//tei:bibl}</citation>) 

};

(:~
 : Process relationships uses lib/rel.xqm module
:)                   
declare function app:display-related($node as node(), $model as map(*), $type as xs:string?){
    if($type != '') then
        rel:build-relationship($model("data")//tei:body/child::*/tei:listRelation, replace($model("data")//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei',''),$type)
    else if($model("data")//tei:body/child::*/tei:listRelation) then 
        rel:build-relationships($model("data")//tei:body/child::*/tei:listRelation, replace($model("data")//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei',''))
    else ()
};

(:~            
 : TCADRT Get records that reference current record.
:)       
declare function app:external-relationships($node as node(), $model as map(*), $relType as xs:string?){
    let $rec := $model("data") 
    let $recid := replace($rec/descendant::tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei','')
    let $title := $rec/descendant::tei:titleStmt/tei:title[1]/text()
    let $relationshipPath := 
        if($relType != '') then
                concat("[descendant::tei:relation[@passive[matches(.,'",$recid,"(\W.*)?$')] or @mutual[matches(.,'",$recid,"(\W.*)?$')]][@ref = '",$relType,"']]")
        else concat("[descendant::tei:relation[@passive[matches(.,'",$recid,"(\W.*)?$')] or @mutual[matches(.,'",$recid,"(\W.*)?$')]]]")
    let $relationships := util:eval(concat("collection($global:data-root)/tei:TEI",$relationshipPath))
    return $relationships    
};

(:~      
 : TCADRT Get relations to display in body of HTML page
 : Used by tcadrt for displaying related buildings
 : @param $data TEI record
 : @param $relType name/ref of relation to be displayed in HTML page
:)
declare %templates:wrap function app:display-external-relationships($node as node(), $model as map(*), $relType as xs:string?, $collection as xs:string?, $sort as xs:string?, $count as xs:string?){
    let $related := app:external-relationships($node,$model,$relType)
    return 
        if($related) then 
            <div class="panel panel-default">
                <div class="panel-heading"><h3 class="panel-title">This site contains {count($related)} building(s) </h3></div>
                <div class="panel-body">
                    { 
                        for $r in $related
                        let $uri := replace($r/descendant::tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei','')
                        return 
                        <div class="indent">{tei2html:summary-view($r, (), $uri)}</div> 
                    }
                </div>
            </div>
        else ()
};

(:~
 : For tcadrt display related images. 
:)                   
declare function app:display-related-images($node as node(), $model as map(*)){
    if($model("data")//tei:relation[@ref='foaf:depicts']) then 
        <div class="record-images">
        {
            for $image in $model("data")//tei:relation[@ref='foaf:depicts']
            return 
                <span class="thumb-images">
                     <a href="{concat('https://',$image/@active,'b.jpg')}" target="_blank">
                         <span class="helper"></span>
                         <img src="{concat('https://',$image/@active,'t.jpg')}" />
                         {if($image/tei:desc) then <span class="caption">{$image/tei:desc}</span> else ()}
                     </a>
                </span>
        }    
        </div>            
    else ()        
};


(:~
 : bibl modulerelationships
:)                   
declare function app:cited($node as node(), $model as map(*)){
    rel:cited($model("data")//tei:idno[@type='URI'][ends-with(.,'/tei')], request:get-parameter('start', 1),request:get-parameter('perpage', 5))
};

(:~  
 : Record status to be displayed in HTML sidebar 
 : Data from tei:teiHeader/tei:revisionDesc/@status
:)
declare %templates:wrap  function app:rec-status($node as node(), $model as map(*), $collection as xs:string?){
let $status := string($model("data")/descendant::tei:revisionDesc/@status)
return
    if($status = 'published' or $status = '') then ()
    else
    <span class="rec-status {$status} btn btn-info">Status: {$status}</span>
};


(:~ 
 : Used by teiDocs
:)
declare %templates:wrap function app:set-data($node as node(), $model as map(*), $doc as xs:string){
    teiDocs:generate-docs($global:data-root || '/places/tei/78.xml')
};

(:~
 : Generic output documentation from xml
 : @param $doc as string
:)
declare %templates:wrap function app:build-documentation($node as node(), $model as map(*), $doc as xs:string?){
    let $doc := doc($global:app-root || '/documentation/' || $doc)//tei:encodingDesc
    return tei2html:tei2html($doc)
};

(:~
 : Pulls github wiki data into Syriaca.org documentation pages. 
 : @param $wiki-uri pulls content from specified wiki or wiki page. 
:)
declare function app:get-wiki($wiki-uri as xs:string?){
    http:send-request(
            <http:request href="{xs:anyURI($wiki-uri)}" method="get">
                <http:header name="Connection" value="close"/>
            </http:request>)[2]//html:div[@class = 'repository-content']            
};

(:~
 : Pulls github wiki data H1.  
:)
declare function app:wiki-page-title($node, $model){
    let $wiki-uri := 
        if(request:get-parameter('wiki-uri', '')) then 
            request:get-parameter('wiki-uri', '')
        else 'https://github.com/srophe/srophe-eXist-app/wiki' 
    let $uri := 
        if(request:get-parameter('wiki-page', '')) then 
            concat($wiki-uri, request:get-parameter('wiki-page', ''))
        else $wiki-uri
    let $wiki-data := app:get-wiki($uri)
    let $content := $wiki-data//html:div[@id='wiki-body']
    return $wiki-data/descendant::html:h1[1]
};

(:~
 : Pulls github wiki content.  
:)
declare function app:wiki-page-content($node, $model){
    let $wiki-uri := 
        if(request:get-parameter('wiki-uri', '')) then 
            request:get-parameter('wiki-uri', '')
        else 'https://github.com/srophe/srophe-eXist-app/wiki' 
    let $uri := 
        if(request:get-parameter('wiki-page', '')) then 
            concat($wiki-uri, request:get-parameter('wiki-page', ''))
        else $wiki-uri
    let $wiki-data := app:get-wiki($uri)
    return $wiki-data//html:div[@id='wiki-body'] 
};

(:~
 : Pull github wiki data into Syriaca.org documentation pages. 
 : Grabs wiki menus to add to Syraica.org pages
 : @param $wiki pulls content from specified wiki or wiki page. 
:)
declare function app:wiki-menu($node, $model, $wiki){
    let $wiki-data := app:get-wiki($wiki)
    let $menu := app:wiki-links($wiki-data//html:div[@id='wiki-rightbar']/descendant::*:ul[@class='wiki-pages'], $wiki)
    return $menu
};

(:~
 : Typeswitch to processes wiki menu links for use with Syriaca.org documentation pages. 
 : @param $wiki pulls content from specified wiki or wiki page. 
:)
declare function app:wiki-links($nodes as node()*, $wiki) {
    for $node in $nodes
    return 
        typeswitch($node)
            case element(html:a) return
                let $wiki-path := substring-after($wiki,'https://github.com')
                let $href := concat($global:nav-base, replace($node/@href, $wiki-path, "/documentation/wiki.html?wiki-page="),'&amp;wiki-uri=', $wiki)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element() return
                element { node-name($node) } {
                    $node/@*, app:wiki-links($node/node(), $wiki)
                }
            default return
                $node               
};
