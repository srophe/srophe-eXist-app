(:~              
 : Builds SPEAR pages  
 :)
xquery version "3.0";
module namespace spear="http://syriaca.org/srophe/spear";

(: eXistdb modules :)
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace functx="http://www.functx.com";

(:Syriaca.org modules. :)
import module namespace data="http://syriaca.org/srophe/data" at "lib/data.xql";
import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace cts="http://syriaca.org/cts" at "../CTS/cts-resolver.xqm";
import module namespace ev="http://syriaca.org/srophe/events" at "lib/events.xqm";
import module namespace facet="http://expath.org/ns/facet" at "lib/facet.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "lib/global.xqm";
import module namespace maps="http://syriaca.org/srophe/maps" at "lib/maps.xqm";
import module namespace page="http://syriaca.org/srophe/page" at "lib/paging.xqm";
import module namespace rel="http://syriaca.org/srophe/related" at "lib/get-related.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace timeline="http://syriaca.org/srophe/timeline" at "lib/timeline.xqm";

declare namespace http="http://expath.org/ns/http-client";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: NEW SPEAR :)
declare variable $spear:id {request:get-parameter('id', '')}; 
declare variable $spear:view {request:get-parameter('view', '')};
declare variable $spear:date {request:get-parameter('date', '')};
declare variable $spear:fq {request:get-parameter('fq', '')};
declare variable $spear:sort {request:get-parameter('sort', 'all') cast as xs:string};
declare variable $spear:alpha-filter {request:get-parameter('alpha-filter', '')};
declare variable $spear:lang {request:get-parameter('lang', '')};
declare variable $spear:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $spear:perpage {request:get-parameter('perpage', 15) cast as xs:integer};

(: Type of factoid :)
declare variable $spear:item-type {
    if($spear:id != '') then 
        if(contains($spear:id, '/place')) then 'place-factoid'
        else if(contains($spear:id, '/person')) then 'person-factoid'
        else if(contains($spear:id, '/keyword')) then 'keyword-factoid'
        else if(contains($spear:id, '/spear') and contains($spear:id, '-')) then 'factoid'
        else if(contains($spear:id, '/spear')) then 'source-factoid'
        else 'event-factoid'
    else 'all-events'
};    

(: Facets for different browse types :)
declare function spear:get-facets(){
    let $facet-config-file := if(request:get-parameter('view', '') = 'persons' or request:get-parameter('view', '') = '') then 
                                'persons-facets.xml'
                              else if(request:get-parameter('view', '') = 'places') then
                                'places-facets.xml'                                
                              else if(request:get-parameter('view', '') = 'events') then
                                'events-facets.xml'
                              else if(request:get-parameter('view', '') = 'relations') then
                                'relations-facets.xml'
                              else ()
    let $facet-config := 
            concat($config:app-root, '/spear/',$facet-config-file) 
    return 
        if(doc-available($facet-config)) then doc($facet-config)
        else ()
};

(:~
 : Build initial browse results based view parameter
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
 : @param $element element used to filter browse results, passed from html
 : @param $facets facet xml file name, relative to collection directory
:)  
declare function spear:get-all($node as node(), $model as map(*), $collection as xs:string*, $element as xs:string?, $facets as xs:string?){
   let $collection-path := 
            if(config:collection-vars($collection)/@data-root != '') then concat('/',config:collection-vars($collection)/@data-root)
            else if($collection != '') then concat('/',$collection)
            else '/spear'
    let $facets := facet:facet-filter(global:facet-definition-file($collection))
    return 
        if(request:get-parameter('view', '') = 'places') then 
                    (:
                    let $browse-path := concat("collection($config:data-root || $collection-path)//tei:div[descendant::tei:placeName]",facet:facet-filter(spear:get-facets()))
                    let $spear := util:eval($browse-path)
                    :)
                    let $spear := collection($config:data-root || $collection-path)//tei:div[descendant::tei:placeName]
                    return 
                        map{"spear" := $spear,
                            "hits" := 
                                        let $uris := distinct-values($spear//@ref[contains(.,concat($config:base-uri,'/place/'))])
                                        let $facets := concat("collection($config:data-root || '/places')//tei:TEI",facet:facet-filter(spear:get-facets()))
                                        let $places := util:eval($facets)[.//tei:idno[@type='URI'][. = ($uris)]]
                                        for $place in $places
                                        order by global:build-sort-string($place/descendant::tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1],'') ascending
                                        return $place
                            }
        else if(request:get-parameter('view', '') = 'events') then 
                    map{"hits" :=
                                let $browse-path := concat("collection($config:data-root || $collection-path)//tei:div[tei:listEvent]",facet:facet-filter(spear:get-facets()))
                                for $event in util:eval($browse-path)
                                let $date := $event/descendant::tei:event/descendant::tei:date[1]
                                let $sort := 
                                            if($date/@notBefore) then $date/@notBefore
                                            else if($date/@from) then $date/@from
                                            else if($date/@when) then $date/@when 
                                            else if($date/@to) then $date/@to 
                                            else if($date/@from) then $date/@from 
                                            else if($date/@notAfter) then $date/@notAfter                                                 
                                            else ()
                                order by $sort descending
                                return $event
                                }
        else if(request:get-parameter('view', '') = 'relations') then 
                    map{"hits" :=
                                let $browse-path := concat("collection($config:data-root || $collection-path)//tei:div[tei:listRelation]",facet:facet-filter(spear:get-facets()))
                                for $relation in util:eval($browse-path)
                                return  $relation
                                }                          
        else                    
                    (:
                    facet:html-list-facets-as-buttons(facet:count($hits, $facet-config/descendant::facet:facet-definition[@name="Century"]))
                    :)
                    let $browse-path := 
                      (:  string-join(
                            let $facet-config := spear:get-facets()
                            for $facet in $facet-config/descendant::facet:facet-definition
                            return 
                            concat("collection($config:data-root || $collection-path)//tei:div[tei:listPerson]",
                                    facet:facet-filter($facet)
                                ),' | ')
                       :)         
                    concat("collection($config:data-root || $collection-path)//tei:div[tei:listPerson]",facet:facet-filter(spear:get-facets()))
                    let $spear := util:eval($browse-path)
                    return 
                        map{"spear" := $spear,
                            "path"  := $browse-path,
                            "hits" := 
                                        let $uris := distinct-values($spear//@ref[contains(.,concat($config:base-uri,'/person/'))])
                                        let $persons := collection($config:data-root || '/persons')//tei:TEI[.//tei:idno[@type='URI'][. = ($uris)]]
                                        return 
                                            if($spear:alpha-filter != '' and $spear:alpha-filter != 'ALL') then 
                                                for $person in $persons
                                                let $sort := global:build-sort-string($person/descendant::tei:persName[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1],'')
                                                order by $sort ascending
                                                where matches($sort,global:get-alpha-filter()) 
                                                return $person
                                            else 
                                                for $person in $persons
                                                let $sort := global:build-sort-string($person/descendant::tei:persName[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1],'')
                                                order by $sort ascending 
                                                return $person
                            }
};

(: Browse menu for persons and places :)
declare function spear:browse-abc-menu(){
    <div class="browse-alpha tabbable" xmlns="http://www.w3.org/1999/xhtml">
        <ul class="list-inline">
        {            
            for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ALL', ' ')
            return
                    <li>{if($spear:alpha-filter = $letter) then attribute class {"selected badge"} else()}
                    <a href="?alpha-filter={$letter}{if($spear:view != '') then concat('&amp;view=',$spear:view) else()}{
                    if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">
                    {$letter}</a></li>
        }
        </ul>
    </div>
};

(:
 : Main HTML display of browse results
 : @param $collection passed from html 
:)
declare function spear:show-hits($node as node(), $model as map(*), $collection, $sort-options as xs:string*, $facets as xs:string?){
(<div>
    <div class="float-container">
        <div class="pull-right paging">      
            {page:pages($model("hits"), $collection, $spear:start, $spear:perpage,'', $sort-options)}
        </div>
            {if(request:get-parameter('view', '') = 'persons' or request:get-parameter('view', '') = '' or request:get-parameter('view', '') = 'places') then spear:browse-abc-menu() else ()}
    </div>
</div>,
<div class="row">
    {
        if(spear:get-facets() != '') then
            <div class="col-md-4">
                {
                    if(request:get-parameter('view', '') = 'persons' or request:get-parameter('view', '') = '') then
                        facet:html-list-facets-as-buttons(facet:count($model("spear"), spear:get-facets()//facet:facet-definition))
                    else facet:html-list-facets-as-buttons(facet:count($model("hits"), spear:get-facets()//facet:facet-definition))
                }
            </div>
        else ()
    }
    <div class="{if(spear:get-facets() != '') then 'col-md-8' else 'col-md-12'}">
        {if(request:get-parameter('view', '') = 'places' and count($model("hits")//tei:geo) gt 0) then
                maps:build-map($model("hits"), count($model("hits")))
         else if(request:get-parameter('view', '') = 'events') then
                (timeline:timeline(subsequence($model("hits"), $spear:start,$spear:perpage),'Timeline'),
                <hr/>)                
         else ()
        }
        <div class="results">
            {
                for $hit in subsequence($model("hits"), $spear:start,$spear:perpage)
                let $link := 
                    if($hit/tei:listRelation) then
                        let $id := $hit/tei:idno[@type="URI"]
                        return <span>{spear:factoid-title($hit)} <a href="factoid.html?id={$id}"> See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/> </a></span>
                    else if($hit/tei:listEvent) then
                        let $id := $hit/tei:idno[@type="URI"]
                        return <span>{spear:factoid-title($hit)} <a href="factoid.html?id={$id}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a></span>
                    else if($hit/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')]) then 
                        let $id := replace($hit/descendant::tei:idno[@type='URI'][1],'/tei','')
                        return <a href="aggregate.html?id={$id}" dir="ltr">{spear:factoid-title($hit)}</a>
                    else $hit
                    return 
                    <div xmlns="http://www.w3.org/1999/xhtml" class="result">{$link}</div>
            }
        </div> 
    </div>
</div>)
};

(: Build factoid title, uses Syriaca.org canonical names for persons and places. :)
declare function spear:factoid-title($hit){
    if($hit/tei:listRelation) then rel:relationship-sentence($hit//descendant::tei:relation)
    else if($hit/tei:listEvent) then string-join(tei2html:tei2html($hit/tei:listEvent/tei:event),' ')
    else if($hit/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')]) then 
        let $en-title := if($hit/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')]) then 
                            $hit/descendant-or-self::*[contains(@syriaca-tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][1]//text()
                         else $hit/descendant-or-self::tei:title[1]/text()
        let $syr-title := if($hit/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                            <span xml:lang="syr" lang="syr" dir="rtl">{string-join($hit/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                          else if($hit/descendant::*[contains(@syriaca-tags,'#syriaca-headword')]) then '[Syriac Not Available]'
                          else () 
        return (tei2html:tei2html($en-title),if($syr-title != '') then (' - ', $syr-title) else())
    else()
};

(:~  
 : Build spear view
 : @param $id spear URI
 :)       
declare %templates:wrap function spear:get-rec($node as node(), $model as map(*), $view as xs:string?){ 
let $id :=
        if(contains($spear:id,$config:base-uri) or starts-with($spear:id,'http://')) then $spear:id
        else if(contains(request:get-uri(),$config:nav-base)) then replace(request:get-uri(),$config:nav-base, $config:base-uri)
        else if(contains(request:get-uri(),$config:base-uri)) then request:get-uri()
        else $spear:id
let $id := if(ends-with($id,'.html')) then substring-before($id,'.html') else $id  
return 
    if($view = 'aggregate') then
        map {"data" :=  
        <aggregate xmlns="http://www.tei-c.org/ns/1.0" id="{$id}">
            {
                if($spear:item-type = 'source-factoid') then 
                    data:get-document($id)        
                else
                    for $rec in
                        data:get-document($id) | 
                        collection($config:data-root || "/spear/tei")//tei:div[descendant::*[@ref=$spear:id or @target=$spear:id]] |
                        collection($config:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@active, concat($spear:id,"(\W|$)"))]] |
                        collection($config:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@passive, concat($spear:id,"(\W|$)"))]] |
                        collection($config:data-root || '/spear/tei')//tei:div[descendant::tei:relation[matches(@mutual, concat($spear:id,"(\W|$)"))]] |
                        collection($config:data-root || '/spear/tei')//tei:div[descendant::*[matches(@ana, concat($spear:id,"(\W|$)"))]]                        
                    return $rec  
            }
        </aggregate>}
    else  map {"data" :=  data:get-document($id) }  
};

(:~   
 : Checks for canonical record in Syriaca.org 
 : @param $spear:id 
:)
declare function spear:canonical-rec($id){
  collection($config:data-root)//tei:TEI[.//tei:idno = $id]
};

declare function spear:resolve-id() as xs:string?{
let $id := request:get-parameter('id', '')
let $parse-id :=
    if(contains($id,$config:base-uri) or starts-with($id,'http://')) then $id
    else if(starts-with(request:get-uri(),$config:base-uri)) then string(request:get-uri())
    else if(contains(request:get-uri(),$config:nav-base) and $config:nav-base != '') then 
        replace(request:get-uri(),$config:nav-base, $config:base-uri)
    else if(starts-with(request:get-uri(),'/exist/apps')) then 
        replace(request:get-uri(),concat('/exist/apps/',replace($config:app-root,'/db/apps/','')), $config:base-uri)   
    else $id
let $final-id := if(ends-with($parse-id,'.html')) then substring-before($parse-id,'.html') else $parse-id
return $final-id
};

(:~        
 : Build page title
 : Uses connical record from syriaca.org as title, otherwise uses spear data
:)
declare %templates:wrap function spear:h1($node as node(), $model as map(*)){
let $data := $model("data")
let $pid := spear:resolve-id()
let $id := <idno type='URI' xmlns="http://www.tei-c.org/ns/1.0">{$pid}</idno>
return 
    if(spear:factoid-title($data) != '') then 
        (<h1>SPEAR Factoids about {spear:factoid-title($data)}</h1>,
         <div style="margin:0 1em 1em; color: #999999;">
           <small><a href="../documentation/terms.html#place-uri" title="Click to read more about URIs" class="no-print-link"><span class="helper circle noprint"><p>i</p></span></a>
                <p><span class="srp-label">URI</span>: <span id="syriaca-id">{$id/text()}</span></p></small></div>
           )
    else if($spear:item-type = 'keyword-factoid') then 
        (<h1>SPEAR Keyword</h1>,
           <div style="margin:0 1em 1em; color: #999999;">
           <small><a href="../documentation/terms.html#place-uri" title="Click to read more about URIs" class="no-print-link"><span class="helper circle noprint"><p>i</p></span></a>
                <p><span class="srp-label">URI</span>: <span id="syriaca-id">{$id/text()}</span></p></small></div>
           )
    else  (<h1>SPEAR Factoid</h1>,
           <div style="margin:0 1em 1em; color: #999999;">
           <small><a href="../documentation/terms.html#place-uri" title="Click to read more about URIs" class="no-print-link"><span class="helper circle noprint"><p>i</p></span></a>
                <p><span class="srp-label">URI</span>: <span id="syriaca-id">{$id/text()}</span></p></small></div>
           )         
};
     
declare function spear:data($node as node(), $model as map(*), $view as xs:string?){
if($spear:item-type = 'place-factoid') then 
    (spear:relationships-aggregate($node,$model),
    spear:events($node,$model),
    spear:person-data($model("data")))
else if($spear:item-type = 'person-factoid') then
    ( 
    spear:person-data($model("data")),
    spear:relationships-aggregate($node,$model),
    spear:events($node,$model)
    ) 
else if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
    spear:source-data($model("data"))
else if($spear:item-type = 'keyword-factoid') then
    (
    spear:person-data($model("data")),
    spear:relationships-aggregate($node,$model),
    spear:events($node,$model)     
    )    
else if($model("data")//tei:div/tei:listRelation) then
    <div class="factoid">
       <h4>Relationship</h4>
       {
       for $r in $model("data")//tei:div/tei:listRelation/descendant::tei:relation
        return <p>{rel:relationship-sentence($r)}</p>
       }
    </div>  
else 
    (:
    Need to pass relationship data to XSLT or move SPEAR display into XQuery. 
    <spear-as-is xmlns="http://www.tei-c.org/ns/1.0">
                             {for $r in $model("data")//tei:div/descendant::tei:relation
                              return <p><strong>Relationship:</strong> {rel:relationship-sentence($r)}</p>
                              }
                         </spear-as-is>
    :)
    global:tei2html(<factoid xmlns="http://www.tei-c.org/ns/1.0">
                        {$model("data")//tei:div}
                        </factoid>)
};

declare function spear:cts($node as node(), $model as map(*)){
    if($model("data")//tei:bibl[@type='urn']) then
        let $refs := $model("data")/tei:bibl[@type='urn']/tei:ptr/@target
        return
            if($refs != '') then 
                <div class="panel panel-default" id="cts">
                    <div class="panel-heading clearfix">
                        <h4 class="panel-title">Text from The Syriac Corpus</h4>
                    </div>
                    <div class="panel-body">
                        {
                        for $r in $refs 
                        return 
                        (cts:run($r, 'html'),
                        <span>Go to text <a href="{$config:nav-base}/CTS/cts-resolver.xql?urn={$r}"><span class="glyphicon glyphicon-circle-arrow-right"> </span></a></span>)
                        }
                    </div>
                </div> 
            else()    
    else ()

};
(:~          
    How to list all the factoids?
    should have the options of by type, in order and using 'advance browse options?'   
:)
declare function spear:source-data($data){
let $refs := distinct-values(tokenize(string-join($data//@active | $data//@passive | $data//@mutual | $data//@ref | $data//@target,' '),' '))
let $factoids := $data/descendant::tei:div[@uri]
let $count-factoids := count($factoids)
let $biographical := $factoids[tei:listPerson]
let $count-biographical := count($biographical)
let $relationship := $factoids[tei:listRelation]
let $count-relationship := count($relationship)
let $event := $factoids[tei:listEvent]
let $count-event := count($event)
let $unique-persons := count($refs[contains(.,'/person/')])
let $unique-places := count($refs[contains(.,'/place/')])
let $unique-keywords := count($refs[contains(.,'/keyword/')])
return 
<div class="panel panel-default">
    <div class="panel-heading clearfix">
        <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Publication Information</h4>
    </div>
    <div class="panel-body"> 
        {global:tei2html(<spear-teiHeader xmlns="http://www.tei-c.org/ns/1.0">{$data/descendant::tei:teiHeader, $data/descendant::tei:back}</spear-teiHeader>)}
        <div><span class="srp-label">Data Set:</span>
        <ul>
            <li>This prosopography contains  {$count-factoids} 
            factoids about {$unique-persons} persons, 
            {$unique-places} places, and {$unique-keywords} subjects.</li>
            <li>
                The data is composed of {$count-biographical} biographical factoids, {$count-relationship} relationship factoids, 
                and {$count-event} event factoids.
            </li>
        </ul>
        </div>
        <hr/>
        <h4><a href="browse.html?fq=;fq-Source%20Text:{$data/descendant::tei:teiHeader/descendant::tei:title[1]}&amp;view=advanced">See all factoids for this work <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a></h4>
    </div>
</div>
};
     
declare function spear:person-data($data){
let $personInfo := $data/descendant::tei:div[tei:listPerson]
return 
    if(not(empty($personInfo))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Person Factoids {if($spear:item-type = 'person-factoid') then ' about ' else ' referencing '} &#160; {spear:factoid-title($data)}</h4>
             </div>
             <div class="panel-body"> 
                {global:tei2html(
                    <aggregate xmlns="http://www.tei-c.org/ns/1.0">
                        {$personInfo}
                    </aggregate>)}
             </div>
        </div>
    else 
        <div class="well text-center">
        <h2>No SPEAR data.</h2>
        </div>
};

declare %templates:wrap function spear:relationships-aggregate($node as node(), $model as map(*)){
let $relations := $model("data")//tei:div[descendant::tei:listRelation]                
let $count := count($relations)   
let $relation := subsequence($relations,1,20)
return 
    if(not(empty($relation))) then 
        <div class="panel panel-default">
             <div class="panel-heading clearfix">
                 <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Relationship Factoids about {spear:factoid-title($model("data"))}</h4>
             </div>
             <div class="panel-body">
                <div class="indent">
                    {
                       for $r in $relation
                       return 
                       <p>{rel:relationship-sentence($r/descendant::tei:relation)} &#160;<a href="factoid.html?id={string($r/tei:idno)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a></p>
                       (:
                       if($count gt 20) then 
                           <a href="#" class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="modal" data-target="#moreInfo" 
                            data-ref="{$config:nav-base}/spear/search.html?relation={$spear:id}&amp;perpage={$count}&amp;sort=alpha" 
                            data-label="See all {$count} &#160; Relationships" id="related-names">See all {$count} relationships <i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                       else ()
                    :)}
                </div>
            </div>
        </div>            
    else () 
};

declare %templates:wrap function spear:relationships($node as node(), $model as map(*)){
    let $relation := $model("data")//tei:listRelation
    let $uri := if($model("data")/@uri) then $model("data")/@uri else ()
    for $r in $relation/descendant::tei:relation
    return (:rel:build-short-relationships($r, $uri):)
    rel:build-relationships($r//tei:relation,$uri, '', 'sentence', '')
};

(: NOTE: add footnotes to events panel :)
declare %templates:wrap function spear:events($node as node(), $model as map(*)){
  if($model("data")//tei:listEvent) then
    let $events := $model("data")//tei:div[tei:listEvent/descendant::tei:event]
    return
        (ev:build-timeline($events,'events'),
        ev:build-events-panel($events))
  else ()  
};

(:~
 : NOTE: this is really the cononical, not the related... should have two, on for factoids, one for 
 aggrigate?  
 Checks link to related record
:)
declare function spear:srophe-related($node as node(), $model as map(*), $view as xs:string?){
if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
    <div class="panel panel-default">
        <div class="panel-heading clearfix">
            <h4 class="panel-title">NHSL Record information</h4>
        </div>
        <div class="panel-body">
         </div>
    </div>      
else
    let $data := $model("data")
    let $rec-exists := $data//tei:TEI  
    let $type := string($rec-exists/descendant::tei:place/@type)
    let $geo := $rec-exists/descendant::tei:body[descendant-or-self::tei:geo]
    let $abstract := $rec-exists/descendant::tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] 
                     | $rec-exists/descendant::tei:note[@type='abstract'] | $rec-exists/descendant::tei:entryFree/tei:gloss[@xml:lang = 'en']
    return 
        if($rec-exists) then 
            <div class="panel panel-default">
                 <div class="panel-heading clearfix">
                     <h4 class="panel-title">About {spear:factoid-title($data)}</h4>
                 </div>
                 <div class="panel-body">
                    {if($geo) then 
                    <div>
                        <div>{maps:build-map($geo,0)}</div>
                        <div>
                            <p><strong>Place Type: </strong><a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a></p>
                             {if($data//tei:location) then
                                    <div id="location">
                                        <h4>Location</h4>
                                        <ul>
                                        {
                                            for $location in $data//tei:location
                                            return global:tei2html($location)
                                        }
                                        </ul>
                                    </div>
                                else ()}
                        </div>    
                    </div>
                    else ()}
                   {if($abstract != '') then 
                        <div>
                            {global:tei2html($abstract)}
                        </div>    
                    else ()}
                    <br/>
                    <hr/>
                    <p>View entry in <a href="{replace($spear:id,$config:base-uri,$config:nav-base)}">{if(contains($spear:id,'person')) then 'Syriac Biographical Dictionary' else if(contains($spear:id,'keyword')) then 'A Taxonomy of Syriac Studies' else 'The Syriac Gazetteer' }</a></p>
                 </div>
            </div>
        else ()
};

(:~          
 : Find related factoids
 : Side bar used by aggrigate pages. Not to be confussed with spear:relationships-aggregate, which is used for center page display in aggrigate pages, and decodes relationships. 
:)
declare function spear:related-factiods($node as node(), $model as map(*), $view as xs:string?){
let $data := $model("data")  
let $title := $data/descendant::tei:titleStmt/tei:title[1]/text()
return
    if($data/ancestor::tei:body//tei:ref[@type='additional-attestation'][@target=$spear:id] 
    or $data/descendant::tei:div/descendant::tei:persName 
    or $data/descendant::tei:div/descendant::tei:placeName 
    or $data/descendant::tei:div/descendant::tei:relation) then 
        <div class="panel panel-default">
            <div class="panel-heading clearfix">
                {
                    if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                        <h4 class="panel-title">Browse Persons, Places and Keywords in {$title}</h4>
                    else
                        <h4 class="panel-title">Related Persons, Places and Keywords</h4>
                }

            </div>
            <div class="panel-body">
            {
                let $relations := distinct-values(tokenize(string-join(($data/descendant::*/@ref,
                                    $data/descendant::tei:div/descendant::*/@target,
                                    $data/descendant::tei:div/descendant::tei:relation/@mutual,
                                    $data/descendant::tei:div/descendant::tei:relation/@active,
                                    $data/descendant::tei:div/descendant::tei:relation/@passive),' '),' '))
                let $persNames := $relations[contains(.,'/person/')]
                let $placeNames := $relations[contains(.,'/place/')]
                let $keywords := $relations[contains(.,'/keyword/')]
                let $count-persons := count($persNames)
                let $count-places := count($placeNames)
                let $count-keywords := count($keywords)
                return 
                    (
                    if($count-persons gt 0) then 
                        <div>
                            <h4>Person(s) <span class="badge">{$count-persons}</span></h4>
                            <div class="facet-list show">
                                <ul>
                                    {
                                        for $r in subsequence($persNames,1,5)
                                        return 
                                            if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Person:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                            else     
                                                <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                                    }
                                </ul>
                             </div>
                              {
                                    if($count-persons gt 5) then
                                        (<div class="facet-list collapse" id="show-person">
                                            <ul>
                                            {
                                            for $r in subsequence($persNames,6,$count-persons + 1)
                                            return 
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Person:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                                else     
                                                    <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                                            }
                                            </ul>
                                        </div>,
                                        <a class="facet-label togglelink btn btn-info" 
                                        data-toggle="collapse" data-target="#show-person" href="#show-person" 
                                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                                    else ()
                                }
                        </div>
                    else(),     
                    if($count-places gt 0) then                        
                        <div>
                            <h4>Places(s) <span class="badge">{$count-places}</span></h4>
                                <div class="facet-list show">
                                     <ul>
                                        {
                                            for $r in subsequence($placeNames,1,5)
                                            return 
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Place:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                                else 
                                                    <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>
                                        }
                                    </ul>
                                </div>
                                {
                                    if($count-places gt 5) then
                                        (<div class="facet-list collapse" id="show-places">
                                            <ul>
                                            {
                                            for $r in subsequence($placeNames,6,$count-places + 1)
                                            return 
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Place:{$r}&amp;view=advanced">{spear:get-title($r)}</a></li>
                                                else 
                                                    <li><a href="aggregate.html?id={$r}">{spear:get-title($r)}</a></li>                                            }
                                            </ul>
                                        </div>,
                                        <a class="facet-label togglelink btn btn-info" 
                                        data-toggle="collapse" data-target="#show-places" href="#show-places" 
                                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                                    else ()
                                }
                        </div>
                    else (),
                    if($count-keywords gt 0) then                        
                        <div>
                            <h4>Keyword(s) <span class="badge">{$count-keywords}</span></h4>
                                <div class="facet-list show">
                                     <ul>
                                        {
                                            for $r in subsequence($keywords,1,5)
                                            return 
                                                if($spear:item-type = 'source-factoid' and $view = 'aggregate') then
                                                    <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Keyword:{$r}&amp;view=advanced">{lower-case(functx:camel-case-to-words(substring-after($r,'/keyword/'),' '))}</a></li>
                                                else
                                                    <li><a href="aggregate.html?id={$r}">{lower-case(functx:camel-case-to-words(substring-after($r,'/keyword/'),' '))}</a></li>                                                    
                                        }
                                    </ul>
                                </div>
                                {
                                    if($count-keywords gt 5) then
                                        (<div class="facet-list collapse" id="show-keywords">
                                            <ul>
                                            {
                                            for $r in subsequence($keywords,6,$count-keywords + 1)
                                            return 
                                                  <li><a href="browse.html?fq=;fq-Source Text:{$title};fq-Keyword:{$r}&amp;view=advanced">{lower-case(functx:camel-case-to-words(substring-after($r,'/keyword/'),' '))}</a></li>
                                            }
                                            </ul>
                                        </div>,
                                        <a class="facet-label togglelink btn btn-info" 
                                        data-toggle="collapse" data-target="#show-keywords" href="#show-keywords" 
                                        data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>)
                                    else ()
                                }
                        </div>
                    else ())     
            }
            </div>
        </div>
    else ()
};
 
declare function spear:sparql-relationships($node as node(), $model as map(*)){
     <div id="sparqlFacetsBox" class="panel panel-default" xmlns="http://www.w3.org/1999/xhtml">
        <div class="panel-heading clearfix"><h4 class="panel-title">
        Related Persons, Places and Keywords
        <small>
        <span class="input-append facetLists pull-right ">
            <span class="form-group facetLists">
                <label for="type">View:  </label>
                <select id="type" name="type">
                    <option id="List">List</option>
                    <option id="Tabel">Table</option>
                    <option id="Force">Force</option>
                    <option id="Sankey">Sankey</option>
                </select>  
                <span class="glyphicon glyphicon-resize-full pull-right expand"></span>
            </span>
        </span></small>
        </h4></div>
        <div class="panel-body">
            <div id="result"/>
        </div>
       <script>
        <![CDATA[
        var facetParams = [];
        var enlarged = false;
        var uri = ']]>{$spear:id}<![CDATA[';
        var baseURL = 'http://wwwb.library.vanderbilt.edu/exist/apps/srophe/api/sparql';
        var mainQueryURL = baseURL + '?buildSPARQL=true&facet-name=uri&uri=' + uri;
        
        $(document).ready(function () {

            mainQuery(mainQueryURL);
            //Submit results on format change
            $('.facetLists').on('change', '#type', function() {
                mainQuery(mainQueryURL);
            })
            
        });
        
        $('.expand').on('click', function() {
            $('#sparqlFacetsBox').toggleClass('clicked');
            $(this).toggleClass('glyphicon glyphicon-resize-full').toggleClass('glyphicon glyphicon-resize-small');
            mainQuery(mainQueryURL);
        })
           
        //Submit main SPARQL query based on facet parameters
        function mainQuery(url){
            type = $("#type option:selected").val();
              if($( "#sparqlFacetsBox" ).hasClass( "clicked" )){
                var config = {
                  "width":  750,
                  "height": 500,
                  "margin":  0,
                  "selector": "#result"
                }
            } else {
                var config = {
                  "width":  350,
                  "height": 300,
                  "margin":  0,
                  "selector": "#result"
                }
            }  
            // Otherwise send to d3 visualization, set format to json.  
            $.get(url + '&type=' + type + '&format=json', function(data) {
                d3sparql.graphType(data, type, config);
            }).fail( function(jqXHR, textStatus, errorThrown) {
                console.log("JavaScript error: " + textStatus);
            });
        }
        ]]>
    </script>
    </div>            
                        
};

(: Replace with factoid-title if possible:)
declare function spear:get-title($uri){
let $doc := spear:canonical-rec($uri)
return 
      if (exists($doc)) then
        replace(string-join($doc/descendant::tei:fileDesc/tei:titleStmt[1]/tei:title[1]/text()[1],' '),' — ',' ')
      else $uri
};

(:~           
 : Build footnotes   
 : Better handling of footnotes, should only return 1 tei:back (currently returns on for each factoid)
:)
declare %templates:wrap function spear:bibl($node as node(), $model as map(*)){
    let $data := $model("data")
    let $bibl := $data/tei:div[tei:idno]/descendant::tei:bibl[starts-with(descendant::tei:ptr/@target,'http://syriaca.org/bibl/')]
    return global:tei2html(<spear-citation xmlns="http://www.tei-c.org/ns/1.0">{($bibl)}</spear-citation>)
};

(:
 : Home page timeline
:)
declare %templates:wrap function spear:get-event-data($node as node(), $model as map(*)){
let $events :=  collection($config:data-root || "/spear/tei")//tei:event[parent::tei:listEvent]
return 
     map {"data" := $events}
};
   
declare %templates:wrap function spear:build-event-timeline($node as node(), $model as map(*)){
let $events := $model("data")
return
    ev:build-timeline($events,'events')
};