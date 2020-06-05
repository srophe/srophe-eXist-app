xquery version "3.1";        
(:~  
 : Builds HTML search forms and HTMl search results Srophe Collections and sub-collections   
 :) 
module namespace search="http://srophe.org/srophe/search";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/templates" ;

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Import Srophe application modules. :)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace bibls="http://srophe.org/srophe/bibls" at "bibl-search.xqm";
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://srophe.org/srophe/global" at "../lib/global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "../lib/facets.xql";
import module namespace page="http://srophe.org/srophe/page" at "../lib/paging.xqm";
import module namespace slider = "http://srophe.org/srophe/slider" at "../lib/date-slider.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Variables:)
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};

(:~
 : Builds search result, saves to model("hits") for use in HTML display
:)

(:~
 : Search results stored in map for use by other HTML display functions
 : Updated for Architectura Sinica to display full list if no search terms
:)
declare %templates:wrap function search:search-data($node as node(), $model as map(*), $collection as xs:string?, $sort-element as xs:string?){
    let $queryExpr := search:query-string($collection)     
    let $hits := if($queryExpr != '') then 
                     data:search($collection, $queryExpr,$sort-element)
                 else data:search($collection, '',$sort-element)
    let $all := 
                if($collection = 'bibl') then $hits  
                else if($collection = 'keywords') then
                  for $h in $hits
                  let $score := 
                    if(request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance') then
                        global:build-sort-string(data:add-sort-options($h, request:get-parameter('sort-element', '')),'')
                    else if(request:get-parameter-names() = '' or empty(request:get-parameter-names()) or request:get-parameter('sort-element', '') = 'title') then
                        if($h/descendant::tei:term[@xml:lang="zh-latn-pinyin"]) then 
                            global:build-sort-string($h/descendant::tei:term[@xml:lang="zh-latn-pinyin"][1],'')
                        else global:build-sort-string($h/descendant::tei:titleStmt/tei:title[1],'') 
                    else if($sort-element != '') then 
                        global:build-sort-string(data:add-sort-options($h[1],  $sort-element),'')
                    else ft:score($h) 
                    order by $score ascending
                    return $h  
                else if(request:get-parameter-names() = '' or empty(request:get-parameter-names())) then $hits
                else 
                    let $ids := 
                        for $id in $hits 
                        group by $idno := $id/descendant::tei:publicationStmt/tei:idno[@type='URI']
                        return replace($idno,'/tei','')
                    let $related := 
                            (collection($config:data-root)//tei:TEI[descendant::tei:relation[@passive = $ids]] |
                            collection($config:data-root)//tei:TEI[descendant::tei:relation[@active = $ids]] | 
                            collection($config:data-root)//tei:TEI[descendant::tei:relation[@mutual = $ids]])
                    for $h in ($hits | $related)
                    let $id := $h/descendant::tei:publicationStmt/tei:idno[@type='URI'][1]
                    group by $de-dup := $id
                    let $score :=
                            if(request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance') then
                                global:build-sort-string(data:add-sort-options($h, request:get-parameter('sort-element', '')),'')
                            else if(request:get-parameter-names() = '' or empty(request:get-parameter-names()) or request:get-parameter('sort-element', '') = 'title') then
                                global:build-sort-string($h/descendant::tei:titleStmt/tei:title[1],'') 
                            else if($sort-element != '') then 
                                global:build-sort-string(data:add-sort-options($h[1],  $sort-element),'')
                            else ft:score($h) 
                    order by $score ascending
                    return $h[1]                   
    return  
        map {
                "hits" : $all,
                "query" : $queryExpr
        } 
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?, $kwic as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
    <!--<div>{search:query-string($collection)}</div>-->
    {
            if($collection = 'places') then 
                let $hits := $model("group-by-sites") 
                for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                let $site := $hit/descendant::tei:relation[@ref="schema:containedInPlace"]/@passive
                group by $facet-grp-p := $site[1]
                let $label := global:get-label($site[1])
                order by $label
                return
                    if($site != '') then 
                        <div class="indent" xmlns="http://www.w3.org/1999/xhtml" style="margin-bottom:1em;">
                                <a class="togglelink text-info" 
                                data-toggle="collapse" data-target="#show{replace($label,' ','')}" 
                                href="#show{replace($label,' ','')}" data-text-swap=" + "> - </a>&#160; 
                                <a href="{replace($facet-grp-p,$config:base-uri,$config:nav-base)}">{$label}</a> (contains {count($hit)} buildings)
                                <div class="indent collapse in" style="background-color:#F7F7F9;" id="show{replace($label,' ','')}">{
                                    for $p in $hit
                                    let $id := replace($p/descendant::tei:idno[1],'/tei','')
                                    return 
                                        <div class="indent" style="border-bottom:1px dotted #eee; padding:1em">{tei2html:summary-view(root($p), '', $id)}</div>
                                }</div>
                        </div>
                    else if($site = '' or not($site)) then
                        for $p in $hit
                        let $id := replace($p/descendant::tei:idno[1],'/tei','')
                        return
                            (:if($groups[. = $id]) then () 
                            else:) 
                                <div class="col-md-11" style="margin-right:-1em; padding-top:.5em;">
                                     {tei2html:summary-view(root($p), '', $id)}
                                </div>                        
                    else ()
            else 
                let $hits := $model("hits")
                for $hit at $p in subsequence($hits, $search:start, $search:perpage)
                let $id := replace($hit/descendant::tei:idno[1],'/tei','')
                return 
                 <div class="row record" xmlns="http://www.w3.org/1999/xhtml">
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


(: Architectura Sinica functions :)
(:
 : TCADRT - display architectural features select lists for research-tool.html
 facet-architecturalFeature=
:)
declare %templates:wrap function search:architectural-features($node as node()*, $model as map(*)){ 
    <div class="row">{
        let $features := collection($config:data-root || '/keywords')/tei:TEI[descendant::tei:entryFree/@type='architectural-feature']
        for $feature in $features
        let $type := string($feature/descendant::tei:relation[@ref = 'skos:broadMatch'][1]/@passive)
        group by $group-type := $type
        return  
            <div class="col-md-6">
                <h4 class="indent">{string($group-type)}</h4>
                {
                    for $f in $feature
                    let $title := string-join($f/descendant::tei:titleStmt/tei:title[1]//text(),' ')
                    let $id := replace($f/descendant::tei:idno[1],'/tei','')
                    order by $title descending
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
                                <label><input type="checkbox" value="{$id}" name="facet-architecturalFeature"/>{$title}</label>
                            </div>
                        </div>
                    }
           </div>                    
    }</div>
};

(: TCADRT terms:)
declare function search:terms(){
    if(request:get-parameter('term', '')) then 
        data:element-search('term',request:get-parameter('term', '')) 
    else '' 
};

(: TCADRT architectural feature search functions :)
declare function search:features(){
    string-join(for $feature in request:get-parameter-names()[starts-with(., 'feature-num:' )]
    let $name := substring-after($feature,'feature-num:')
    let $num-value := 
        if(not(empty($feature)) and ($feature castable as xs:integer)) then 
            xs:integer($feature) 
        else 0
    let $number :=
        if($num-value != 0) then 
               concat("[descendant::tei:num[. lt;= '",$num-value,"']]")
        else ()
    return concat("[descendant::tei:relation[@ana='architectural-feature'][@passive = '",$name,"']",$number,"]"),'')          
};

(:~   
 : Builds general search string from main Architecture Sinica page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
let $search-config := concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
return
    if($collection != '') then 
        if($collection = 'places') then  
            concat(data:build-collection-path($collection),
            slider:date-filter(()),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri(),
            search:terms(),
            data:element-search('term',request:get-parameter('term', '')),
            search:features()
          )
        else if($collection = 'keywords') then 
            concat(data:build-collection-path($collection),
            slider:date-filter(()),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri(),
            search:terms(),
            data:element-search('term',request:get-parameter('term', '')),
            search:features())
        else if($collection = 'bibl') then bibls:query-string()            
        else 
            concat(data:build-collection-path($collection),
            slider:date-filter(()),
            data:element-search('placeName',request:get-parameter('placeName', '')),
            data:element-search('title',request:get-parameter('title', '')),
            data:element-search('bibl',request:get-parameter('bibl', '')),
            data:uri(),
            search:terms(),
            search:features()
          )
    else concat(data:build-collection-path($collection),
        slider:date-filter(()),
        data:element-search('placeName',request:get-parameter('placeName', '')),
        data:element-search('title',request:get-parameter('title', '')),
        data:element-search('bibl',request:get-parameter('bibl', '')),
        data:uri(),
        search:features()
        )
};

(: Group results by building site :)
declare function search:group-results($node as node(), $model as map(*), $collection as xs:string?){
    let $hits := $model("hits")
    return 
        map {"group-by-sites" :            
                for $place in $hits 
                let $site := $place/descendant::tei:relation[@ref="schema:containedInPlace"]/@passive
                group by $facet-grp-p := $site[1]
                let $label := global:get-label($site[1])
                order by $label
                return  $place } 
};
