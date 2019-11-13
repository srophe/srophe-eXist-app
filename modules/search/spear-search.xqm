xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace spears="http://syriaca.org/srophe/spears";
import module namespace functx="http://www.functx.com";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";
import module namespace rel="http://syriaca.org/srophe/related" at "lib/get-related.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $spears:name {request:get-parameter('name', '')};
declare variable $spears:place {request:get-parameter('place', '')};
declare variable $spears:event {request:get-parameter('event', '')};
declare variable $spears:ref {request:get-parameter('ref', '')};
declare variable $spears:keyword {request:get-parameter('controlledkeyword', '')};
declare variable $spears:relation {request:get-parameter('relation', '')};
declare variable $spears:type {request:get-parameter('type', '')};
declare variable $spears:title {request:get-parameter('title', '')};

(:~
 : Search Name
 : @param $name search persName
 want to be able to return all given/family ect without a search term?
 given / family / title
:)
declare function spears:name() as xs:string? {
    if($spears:name != '') then
        concat("[ft:query(descendant::tei:persName,'",data:clean-string($spears:name),"',data:search-options())]")   
    else ()
};

(:~
 : Search Place
 : @param $name search placeName
:)
declare function spears:place() as xs:string? {
    if($spears:place != '') then
        concat("[ft:query(descendant::tei:placeName,'",data:clean-string($spears:place),"',data:search-options())]")   
    else ()
};

(:~
 : Search Event
 : @param $name search placeName
:)
declare function spears:event() as xs:string? {
    if($spears:event != '') then
        concat("[ft:query(descendant::tei:event,'",data:clean-string($spears:event),"',data:search-options())]")   
    else ()
};

(:~
 : Search keyword
 : @param keyword
:)
declare function spears:controlled-keyword-search(){
    if($spears:keyword !='') then 
        concat("[descendant::*[matches(@ref,'(^|\W)",$spears:keyword,"(\W|$)')] | descendant::*[matches(@target,'(^|\W)",$spears:keyword,"(\W|$)')]]")
    else ()
};

(:~
 : Search keyword
 : @param keyword
:)
declare function spears:title-search(){
    if($spears:title != '') then 
        concat("[ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[. = ",$spears:title,"]]")
    else ()    
};

(:~
 : Search keyword
 : @param keyword
:)
declare function spears:type-search(){
    if($spears:type != '') then 
        if($spears:type = 'pers') then 
            "[tei:listPerson]"
        else if($spears:type = 'rel') then
            "[tei:listRelation]"
        else if($spears:type = 'event') then 
            "[tei:listEvent]"
        else ()
    else ()    
};

declare function spears:relation(){
    if($spears:relation != '') then
            concat("[descendant::tei:relation[matches(@passive,'",$spears:relation,"(\W|$)')]
            |descendant::tei:relation[matches(@active,'",$spears:relation,"(\W|$)')]
            |descendant::tei:relation[matches(@mutual,'",$spears:relation,"(\W|$)')]]")
    else ()
};

(:~
 : Search by date
 : NOTE: still thinking about this one
:)

(:~
 : Build query string to pass to search.xqm 
:)
declare function spears:query-string() as xs:string? {
 concat("collection('",$config:data-root,"/spear/tei')//tei:div[@type='factoid']",
    spears:type-search(),
    spears:keyword-search(),
    spears:name(),
    spears:place(),
    spears:event(),
    spears:title-search(),
    spears:relation(),
    spears:controlled-keyword-search()
    )
};

(:
 : General keyword anywhere search function 
:)
declare function spears:keyword-search(){
    if(request:get-parameter('keyword', '') != '') then 
        for $query in request:get-parameter('keyword', '') 
        return concat("[ft:query(descendant-or-self::tei:div,'",data:clean-string($query),"',data:search-options()) or ft:query(ancestor-or-self::tei:TEI/descendant::tei:teiHeader,'",data:clean-string($query),"',data:search-options())]")
    else if(request:get-parameter('q', '') != '') then 
        for $query in request:get-parameter('q', '') 
        return concat("[ft:query(descendant-or-self::tei:div,'",data:clean-string($query),"',data:search-options()) or ft:query(ancestor-or-self::tei:TEI/descendant::tei:teiHeader,'",data:clean-string($query),"',data:search-options())]")
    else ()
};


(:~
 : Format search results
 : Need a better uri for factoids, 
:)
declare function spears:results-node($hit){
    let $id := string($hit/tei:idno[@type='URI'])
    let $alt-view :=
        if($spears:type = 'pers' or $spears:name != '') then 
            string($hit/tei:listPerson/tei:person/tei:persName/@ref)
        else if ($spears:place != '') then string($hit/tei:listPerson/tei:person/tei:persName/@ref)
        else ()
    let $alt-view-type :=
        if($spears:type = 'pers' or $spears:name != '') then 'Person'
        else if ($spears:place != '') then 'Place'
        else ()
    let $title := 
        if($hit/tei:listRelation) then rel:relationship-sentence($hit//descendant::tei:relation)
        else string-join(tei2html:tei2html($hit/child::*[2]),' ')
    return 
        <p style="font-weight:bold padding:.5em;">
            {$title} <a href="factoid.html?id={$id}">View Factoid</a>
            {
                if($alt-view != '') then 
                    (' | ', <a href="factoid.html?id={$alt-view}">View {$alt-view-type}</a>)
                else ()
            }
        </p>
};

(:~
 : Build drop down menu for controlled keywords
:)
declare function spears:keyword-menu(){
for $keywordURI in 
distinct-values(
    (
    for $keyword in collection($config:data-root || '/spear/')//@target[contains(.,'/keyword/')]
    return tokenize($keyword,' '),
    for $keyword in collection($config:data-root || '/spear/')//@ref[contains(.,'/keyword/')]
    return tokenize($keyword,' ')
    )
    )
let $key := lower-case(functx:camel-case-to-words(substring-after($keywordURI,'/keyword/'),' '))    
order by $key     
return
    <option value="{$keywordURI}">{$key}</option>
};

declare function spears:source-menu(){
for $title in collection($config:data-root || '/spear/')//tei:titleStmt/tei:title[1]
let $id := $title/ancestor::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="URI"]
order by $title  
return
    <option value="{$title}">{$title}</option>
};

(:~
 : Main search functions.
 : Build a search XPath based on search parameters. 
 : Add sort options. 
:)
declare function spears:search($collection as xs:string*, $queryString as xs:string?, $sort-element as xs:string?) {                      
    let $eval-string := if($queryString != '') then $queryString 
                        else concat(data:build-collection-path($collection), data:create-query($collection),facet:facet-filter(global:facet-definition-file($collection)))
    let $hits := util:eval($eval-string)
    return 
        if(request:get-parameter('sort-element', '') != '' and request:get-parameter('sort-element', '') != 'relevance' or request:get-parameter('view', '') = 'all') then 
            for $hit in $hits
            let $sort := global:build-sort-string(data:add-sort-options($hit, request:get-parameter('sort-element', '')),'')
            order by $sort collation 'http://www.w3.org/2013/collation/UCA'
            return $hit
        else if($sort-element != '' and $sort-element != 'relevance') then  
            for $hit in util:eval($eval-string)
            order by global:build-sort-string(data:add-sort-options($hit, $sort-element),'')
            return root($hit)            
        else if(request:get-parameter('relId', '') != '' and (request:get-parameter('sort-element', '') = '' or not(exists(request:get-parameter('sort-element', ''))))) then
            for $h in $hits
                let $part := 
                      if ($h/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n castable as  xs:integer)
                      then xs:integer($h/child::*/tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n)
                      else 0
            order by $part
            return $h 
        else 
            for $hit in $hits
            order by ft:score($hit) + (count($hit/descendant::tei:bibl) div 100) descending
            return $hit 
};
(:~
 : Builds advanced search form for persons
 :)
declare function spears:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
    {let $search-config := 
                if(doc-available(concat($config:app-root, '/spear/search-config.xml'))) then concat($config:app-root, '/spear/search-config.xml')
                else concat($config:app-root, '/search-config.xml')
            let $config := 
                if(doc-available($search-config)) then doc($search-config)
                else ()                            
            return 
                if($config != '') then 
                    (<button type="button" class="btn btn-info pull-right clearfix search-button" data-toggle="collapse" data-target="#searchTips">
                        Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span></button>,                       
                    if($config//search-tips != '') then
                    <div class="panel panel-default collapse" id="searchTips">
                        <div class="panel-body">
                        <h3 class="panel-title">Search Tips</h3>
                        {$config//search-tips}
                        </div>
                    </div>
                    else if(doc-available($config:app-root || '/searchTips.html')) then doc($config:app-root || '/searchTips.html')
                    else ())
                else ()}
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
            <div class="form-group">
                <label for="qs" class="col-sm-2 col-md-3  control-label">Full-text: </label>
                <div class="col-sm-10 col-md-6">
                        <input type="text" id="qs" name="q" class="form-control keyboard"/>
                </div>
            </div>
            <!-- Person Name -->
            <div class="form-group">
                <label for="name" class="col-sm-2 col-md-3  control-label">Person Name: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="name" name="name" class="form-control keyboard"/>
                </div>
            </div>            
            <div class="form-group">
                <label for="place" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="place" name="place" class="form-control keyboard"/>
                </div>
            </div> 
            <div class="form-group">
                <label for="event" class="col-sm-2 col-md-3  control-label">Event: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="event" name="event" class="form-control keyboard"/>
                </div>
            </div>               
            <hr/>
            <h4>Limit by</h4>
            <div class="form-group">            
                <label for="type" class="col-sm-2 col-md-3  control-label">Type</label>
                <div class="col-sm-10 col-md-6">
                    <select name="type" id="type" class="form-control">
                        <option value="">- Select -</option>
                        <option value="rel">Relation</option>
                        <option value="pers">Person</option>
                        <option value="event">Event</option>
                    </select>
                </div>    
            </div>                 
            <div class="form-group">            
                <label for="keyword" class="col-sm-2 col-md-3  control-label">Keyword</label>
                <div class="col-sm-10 col-md-6">
                    <select name="keyword" id="keyword" class="form-control">
                        <option value="">- Select -</option>
                        {spears:keyword-menu()}
                    </select>
                </div>    
            </div>  
            <div class="form-group">            
                <label for="primary-src" class="col-sm-2 col-md-3  control-label">Primary Source</label>
                <div class="col-sm-10 col-md-6">
                    <select name="primary-src" id="primary-src" class="form-control">
                        <option value="">- Select -</option>
                        {spears:source-menu()}
                    </select>
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