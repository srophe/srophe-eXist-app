xquery version "3.0";        
 
module namespace search="http://syriaca.org/search";
import module namespace data="http://syriaca.org/data" at "../lib/data.xqm";
import module namespace page="http://syriaca.org/page" at "../lib/paging.xqm";
import module namespace rel="http://syriaca.org/related" at "../lib/get-related.xqm";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "../facet-defs.xqm";
import module namespace slider = "http://localhost/ns/slider" at "../lib/date-slider.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "lib/tei2html.xqm";
import module namespace maps="http://syriaca.org/maps" at "../lib/maps.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

import module namespace functx="http://www.functx.com";
import module namespace templates="http://exist-db.org/xquery/templates" ;

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ 
 : Shared global parameters for building search paging function
:)
declare variable $search:q {request:get-parameter('q', '') cast as xs:string};
declare variable $search:persName {request:get-parameter('persName', '') cast as xs:string};
declare variable $search:placeName {request:get-parameter('placeName', '') cast as xs:string};
declare variable $search:title {request:get-parameter('title', '') cast as xs:string};
declare variable $search:bibl {request:get-parameter('bibl', '') cast as xs:string};
declare variable $search:idno {request:get-parameter('uri', '') cast as xs:string};
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:sort-element {request:get-parameter('sort-element', '') cast as xs:string};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?, $view as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string := search:query-string($collection)
    let $hits := util:eval($eval-string)
    return 
        if(exists(request:get-parameter-names()) or ($view = 'all')) then 
            if($collection = 'places') then  
                map {"hits" := 
                            for $r in $hits
                            let $id := $r/descendant::tei:idno[1]
                            order by global:build-sort-string(page:add-sort-options($r,request:get-parameter('sort-element', '')),'') ascending
                            return 
                                if($r/descendant::tei:entryFree) then 
                                    let $related := util:eval(concat("collection('",$global:data-root,"')//tei:body[descendant::tei:relation[@passive ='", $id,"']]",facet:facet-filter(facet-defs:facet-definition($collection)),slider:date-filter(())))
                                    return $related
                                else util:eval(concat("root($id)",facet:facet-filter(facet-defs:facet-definition($collection)),slider:date-filter(())))
                    }
            else if($collection = 'keywords') then  map {"hits" := util:eval(concat("$hits",facet:facet-filter(facet-defs:facet-definition($collection)),slider:date-filter(())))[descendant::tei:entryFree[@type='architectural-feature']] }
            else map {"hits" := util:eval(concat("$hits",facet:facet-filter(facet-defs:facet-definition($collection)),slider:date-filter(()))) }
        (: Combine search and browse features for TCADRT Research Tool :)
        else map {"hits" := 
                if($collection = 'keywords') then 
                    data:get-browse-data($collection, 'tei:titleStmt/tei:title')[descendant::tei:entryFree[@type='architectural-feature']]
                else data:get-browse-data($collection, 'tei:titleStmt/tei:title') 
            }
            
};

declare function search:group-results($node as node(), $model as map(*), $collection as xs:string?){
    let $hits := $model("hits")
    let $groups := distinct-values($hits//tei:relation[@ref="schema:containedInPlace"]/@passive)
    return 
        map {"group-by-sites" :=            
            for $place in $hits 
            let $site := $place/descendant::tei:relation[@ref="schema:containedInPlace"]/@passive
            group by $facet-grp-p := $site[1]
            let $label := facet:get-label($site[1])
            order by $label
            return  
                if($site != '') then 
                    <div class="indent" xmlns="http://www.w3.org/1999/xhtml" style="margin-bottom:1em;">
                            <a class="togglelink text-info" 
                            data-toggle="collapse" data-target="#show{replace($label,' ','')}" 
                            href="#show{replace($label,' ','')}" data-text-swap=" + "> - </a>&#160; 
                            <a href="{replace($facet-grp-p,$global:base-uri,$global:nav-base)}">{$label}</a> (contains {count($place)} buildings)
                            <div class="indent collapse in" style="background-color:#F7F7F9;" id="show{replace($label,' ','')}">{
                                for $p in $place
                                let $id := replace($p/descendant::tei:idno[1],'/tei','')
                                return 
                                    <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">{tei2html:summary-view(root($p), '', $id)}</div>
                            }</div>
                    </div>
                else if($site = '' or not($site)) then
                    for $p in $place
                    let $id := replace($p/descendant::tei:idno[1],'/tei','')
                    return
                        if($groups[. = $id]) then () 
                        else 
                            <div class="col-md-11" style="margin-right:-1em; padding-top:.5em;">
                                 {tei2html:summary-view(root($p), '', $id)}
                            </div>
                        
                (:
                    for $p in $place
                    let $label := string-join($p/descendant::tei:titleStmt/tei:title[1]//text())
                    let $id := replace($p/descendant::tei:idno[1],'/tei','')
                    return 
                        if($hits/descendant::tei:relation[@ref="schema:containedInPlace"][@passive = $id]) then ()
                        else 
                           <div class="col-md-11" style="margin-right:-1em; padding-top:.5em;">
                                 {tei2html:summary-view(root($p), '', $id)}
                            </div>
                :)                            
                else ()
               
        } 
};

(: for debugging :)
declare function search:search-xpath($collection as xs:string?){
   let $coll := if($search:collection != '') then $search:collection else $collection
   return search:query-string($collection)                    
};

(:~   
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
let $search-config := concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/','search-config.xml')
return
if($collection != '') then 
    if(doc-available($search-config)) then 
       concat("collection('",$global:data-root,"/",$collection,"')//tei:body",facet:facet-filter(facet-defs:facet-definition($collection)),slider:date-filter(()),search:dynamic-paths($search-config))
    else if($collection = 'places') then  
        concat("collection('",$global:data-root,"')//tei:TEI",
        data:keyword(),
        search:persName(),
        search:placeName(), 
        search:title(),
        search:bibl(),
        data:uri(),
        search:terms(),
        search:features()
      )
    else
        concat("collection('",$global:data-root,"/",$collection,"')//tei:TEI",
        facet:facet-filter(facet-defs:facet-definition($collection)),
        slider:date-filter(()),
        data:keyword(),
        search:persName(),
        search:placeName(), 
        search:title(),
        search:bibl(),
        data:uri(),
        search:terms(),
        search:features()
      )
else 
concat("collection('",$global:data-root,"')//tei:TEI",
    facet:facet-filter(facet-defs:facet-definition($collection)),
    slider:date-filter(()),
    data:keyword(),
    search:persName(),
    search:placeName(), 
    search:title(),
    search:bibl(),
    data:uri(),
    search:features()
    )
};

declare function search:dynamic-paths($search-config as xs:string?){
    let $config := if(doc-available($search-config)) then doc($search-config) else ()
    let $params := request:get-parameter-names()
    return string-join(
    for $p in $params
    return 
        if($p = 'q') then
            concat("[ft:query(.,'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
        else 
           for $field in $config//input[@name = $p]
           return 
                if(request:get-parameter($p, '') != '') then
                       if(string($field/@element) = '.') then
                            concat("[ft:query(",string($field/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                        else concat("[ft:query(.//",string($field/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")    
                    else (),'')
};

declare function search:persName(){
    if($search:persName != '') then 
        data:element-search('persName',$search:persName) 
    else '' 
};

declare function search:placeName(){
    if($search:placeName != '') then 
        data:element-search('placeName',$search:placeName) 
    else '' 
};

declare function search:title(){
    if($search:title != '') then 
        data:element-search('title',$search:title) 
    else '' 
};

declare function search:bibl(){
    if($search:bibl != '') then  
        let $terms := data:clean-string($search:bibl)
        let $ids := 
            if(matches($search:bibl,'^http://syriaca.org/')) then
                normalize-space($search:bibl)
            else 
                string-join(distinct-values(
                for $r in collection($global:data-root || '/bibl')//tei:body[ft:query(.,$terms, data:search-options())]/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org')][1]
                return concat(substring-before($r,'/tei'),'(\s|$)')),'|')
        return concat("[descendant::tei:bibl/tei:ptr[@target[matches(.,'",$ids,"')]]]")
    else ()
       (: data:element-search('bibl',$search:bibl):)  
};

(: NOTE add additional idno locations, ptr/@target @ref, others? :)
declare function search:idno(){
    if($search:idno != '') then 
         (:concat("[ft:query(descendant::tei:idno, '&quot;",$search:idno,"&quot;')]"):)
         concat("[.//tei:idno = '",$search:idno,"']")
    else () 
};

(: TCADRT terms:)
declare function search:terms(){
    if(request:get-parameter('term', '')) then 
        data:element-search('term',request:get-parameter('term', '')) 
    else '' 
};

(: TCADRT architectural feature search functions :)
declare function search:features(){
    string-join(for $feature in request:get-parameter-names()[starts-with(., 'feature:' )]
    let $name := substring-after($feature,'feature:')
    let $number := 
        for $feature-number in request:get-parameter-names()[starts-with(., 'feature-num:' )][substring-after(.,'feature-num:') = $name]
        let $num-value := request:get-parameter($feature-number, '')
        return
            if($num-value != '' and $num-value != '0') then 
               concat("[descendant::tei:num[. = '",$num-value,"']]")
           else ()
    return 
        if(request:get-parameter($feature, '') = 'true') then 
            concat("[descendant::tei:relation[@ana='architectural-feature'][@passive = '",$name,"']",$number,"]")
        else ())          
};

declare function search:search-string(){
<span xmlns="http://www.w3.org/1999/xhtml">: 
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'start' or $parameter = 'sort-element' or $parameter = 'fq') then ()
            else if(starts-with($parameter,'feature-num:')) then request:get-parameter($parameter, '')
            else if(starts-with($parameter,'feature:')) then facet:get-label(substring-after($parameter,'feature:'))
            else if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{$search:q}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
    search:search-string()
};

(:~ 
 : Count total hits
:)
declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

(:~
 : Build paging for search results pages
 : If 0 results show search form
:)
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?, $sort-options as xs:string*){
  page:pages($model("hits"), $search:start, $search:perpage, search:search-string($collection), $sort-options)
};

(:~
 : Build Map view of search results with coordinates
 : @param $node search resuls with coords
:)
declare function search:build-geojson($node as node()*, $model as map(*)){
let $data := $model("hits")
let $geo-hits := $data//tei:geo
return
    if(count($geo-hits) gt 0) then
         (
         maps:build-map($data[descendant::tei:geo], count($data)),
         <div xmlns="http://www.w3.org/1999/xhtml">
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>,
         <script type="text/javascript" xmlns="http://www.w3.org/1999/xhtml">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>)
    else ()         
};

declare function search:display-slider($node as node(), $model as map(*), $collection as xs:string*){
    slider:browse-date-slider($model("hits"),())
};

(:~
 : Calls advanced search forms from sub-collection search modules
 : @param $collection
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*), $collection as xs:string?) {   
    if(exists(request:get-parameter-names())) then ()
    else <div xmlns="http://www.w3.org/1999/xhtml">{search:search-form($collection)}</div>
};

declare function search:display-map($node as node()*, $model as map(*), $collection as xs:string?) {
    <div xmlns="http://www.w3.org/1999/xhtml">{search:build-geojson($node,$model)}</div>
};

declare function search:display-facets($node as node()*, $model as map(*), $collection as xs:string?) {
    <div xmlns="http://www.w3.org/1999/xhtml">{facet:html-list-facets-as-buttons(facet:count($model("hits"), facet-defs:facet-definition($collection)/descendant::facet:facet-definition[not(@xml:lang)]))}</div>
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
    {
        if($collection = 'places') then 
            let $hits := $model("group-by-sites")
            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
            return $hit
        else 
            let $hits := $model("hits")
            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
            let $id := replace($hit/descendant::tei:idno[1],'/tei','')
            return 
             <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                 <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                     <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                 </div>
                 <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                     {tei2html:summary-view(root($hit), '', $id)}
                 </div>
             </div>   
   } 
</div>
};

(:~          
 : Checks to see if there are any parameters in the URL, if yes, runs search, if no displays search form. 
 : NOTE: could add view param to show all for faceted browsing? 
:)
declare %templates:wrap function search:build-page($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?) {
    search:show-hits($node, $model, $collection)
    (:
    if(exists(request:get-parameter-names()) or ($view = 'all')) then search:show-hits($node, $model, $collection)
    else ()
    :)
};

(:
 : TCADRT - display architectural features select lists
:)
declare %templates:wrap function search:architectural-features($node as node()*, $model as map(*)){ 
    <div class="row">{
        let $features := collection($global:data-root || '/keywords')/tei:TEI[descendant::tei:entryFree/@type='architectural-feature']
        for $feature in $features
        let $type := string($feature/descendant::tei:relation[@ref = 'skos:broadMatch']/@passive)
        group by $group-type := $type
        return  
            <div class="col-md-6">
                <h4 class="indent">{string($group-type)}</h4>
                {
                    for $f in $feature
                    let $title := string-join($f/descendant::tei:titleStmt/tei:title[1]//text(),' ')
                    let $id := replace($f/descendant::tei:idno[1],'/tei','')
                    return 
                        <div class="form-group row">
                            <div class="col-sm-4 col-md-3" style="text-align:right;">
                                  { if($f/descendant::tei:entryFree/@sub-type='numeric') then
                                    <select name="{concat('feature-num:',$id)}" class="inline">
                                      <option value="">No.</option>
                                      <option value="1">1</option>
                                      <option value="2">2</option>
                                      <option value="3">3</option>
                                      <option value="4">4</option>
                                      <option value="5">5</option>
                                      <option value="6">6</option>
                                      <option value="7">7</option>
                                      <option value="8">8</option>
                                      <option value="9">9</option>
                                      <option value="10">10</option>
                                    </select>
                                    else ()}
                            </div>    
                            <div class="checkbox col-sm-8 col-md-9" style="text-align:left;margin:0;padding:0">
                                <label><input type="checkbox" value="true" name="{concat('feature:',$id)}"/>{$title}</label>
                            </div>
                        </div>
                    }
                </div>                    
    }</div>
};

(:~
 : Builds advanced search form
 :)
declare function search:search-form($collection) {  
let $search-config := concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/','search-config.xml')
return 
    if(doc-available($search-config)) then 
        search:build-form($search-config) 
    else search:default-form()
};

declare function search:keyboard-select-button($node as node()*, $model as map(*), $input-name){
<div class="input-group-btn" xmlns="http://www.w3.org/1999/xhtml">
    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
    </button>
    {global:keyboard-select-menu($input-name)}
</div>
};

declare function search:build-form($search-config){
let $config := if(doc-available($search-config)) then doc($search-config) else ()
return 
    <form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal indent" role="form">
        <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
        {if($config//desc != '') then 
            <p class="indent">{$config//desc}</p>
        else() 
        }
        <div class="well well-small">
            <div class="well well-small" style="background-color:white; margin-top:2em;">
                <div class="row">
                    <div class="col-md-10">
                        {
                            for $input in $config//input
                            let $label := string($input/@label)
                            let $name := string($input/@name)
                            let $id := concat('s',$name)
                            (:<input type="text" label="Headword" name="headword" element="tei:term[@type='headword']" keyboard="yes"/>:)
                            return 
                                <div class="form-group">
                                    <label for="{$name}" class="col-sm-2 col-md-3  control-label">{$label}: </label>
                                    <div class="col-sm-10 col-md-9 ">
                                        <div class="input-group">
                                            <input type="text" id="{$id}" name="{$name}" class="form-control keyboard"/>
                                            {
                                                if($input/@keyboard='yes') then 
                                                    <div class="input-group-btn">
                                                        <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                                            &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                                        </button>{global:keyboard-select-menu($id)}
                                                    </div>
                                                else ()
                                            }
                                        </div> 
                                    </div>
                                </div>     
                        }
                </div>
             </div> 
             </div>
             <div class="pull-right">
                <button type="submit" class="btn btn-info">Search</button>&#160;
                <button type="reset" class="btn">Clear</button>
             </div>
            <br class="clearfix"/><br/>
        </div>
    </form>
};

declare function search:default-form(){
                <div id="search-form">
                    <form method="get" action="search.html" class="form-horizontal indent" role="form">
                        <h1 class="search-header">Search Architectura Sinica</h1>
                        <div class="well well-small">
                            <button type="button" class="btn btn-info pull-right" data-toggle="collapse" data-target="#searchTips">
                                Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"/>
                            </button> 
                            <div class="well well-small" style="background-color:white; margin-top:2em;">
                                <div class="row">
                                    <div class="col-md-7">
                                        <!-- Keyword -->
                                        <div class="form-group">
                                            <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                                            <div class="col-sm-10 col-md-9 ">
                                                <div class="input-group">
                                                    <input type="text" id="qs" name="q" class="form-control keyboard"/>
                                                </div> 
                                            </div>
                                        </div>
                                        <!-- Place Name-->
                                        <div class="form-group">
                                            <label for="placeName" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                                            <div class="col-sm-10 col-md-9 ">
                                                <div class="input-group">
                                                    <input type="text" id="placeName" name="placeName" class="form-control keyboard"/>
                                                </div>   
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label for="uri" class="col-sm-2 col-md-3  control-label">URI: </label>
                                            <div class="col-sm-10 col-md-9 ">
                                                <input type="text" id="uri" name="uri" class="form-control"/>
                                            </div>
                                        </div>
                                        <i id="searchSpinner" class="fa fa-spinner fa-spin fa-lg"/>           
                                    </div>
                                </div>    
                            </div>
                            <div class="pull-right">
                                <button type="submit" class="btn btn-info">Search</button> 
                                <button type="reset" class="btn">Clear</button>
                            </div>
                            <br class="clearfix"/>
                            <br/>
                        </div>    
                    </form>
                </div>
};