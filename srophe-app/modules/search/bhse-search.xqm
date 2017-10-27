xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bhses="http://syriaca.org/bhses";
import module namespace functx="http://www.functx.com";
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bhses:title {request:get-parameter('title', '')};
declare variable $bhses:author {request:get-parameter('author', '')};
declare variable $bhses:prologue {request:get-parameter('prologue', '')};
declare variable $bhses:incipit {request:get-parameter('incipit', '')};
declare variable $bhses:explicit {request:get-parameter('explicit', '')};
declare variable $bhses:editions {request:get-parameter('editions', '')};
declare variable $bhses:modern {request:get-parameter('modern', '')};
declare variable $bhses:ancient {request:get-parameter('ancient', '')};
declare variable $bhses:mss {request:get-parameter('mss', '')};
declare variable $bhses:refs {request:get-parameter('refs', '')};
declare variable $bhses:related-pers {request:get-parameter('related-pers', '')};
declare variable $bhses:idno {request:get-parameter('idno', '')};
declare variable $bhses:id-type {request:get-parameter('id-type', '')};
declare variable $bhses:coll {request:get-parameter('coll', '')};

declare function bhses:title() as xs:string? {
    if($bhses:title != '') then concat("[ft:query(tei:bibl/tei:title,'",data:clean-string($bhses:title),"',data:search-options())]")
    else ()    
};

declare function bhses:author() as xs:string? {
    if($bhses:author != '') then
        if(starts-with($bhses:author,$global:base-uri)) then 
            concat("[tei:bibl/tei:author[@ref='",$bhses:author,"']]")
        else
            concat("[ft:query(tei:bibl/tei:author,'",data:clean-string($bhses:author),"',data:search-options())]")
    else ()    
};

declare function bhses:prologue() as xs:string? {
    if($bhses:prologue != '') then concat("[ft:query(tei:bibl/tei:note[@type='prologue'],'",data:clean-string($bhses:prologue),"',data:search-options())]")
    else ()    
};

declare function bhses:incipit() as xs:string? {
    if($bhses:incipit != '') then concat("[ft:query(tei:bibl/tei:note[@type='incipit'],'",data:clean-string($bhses:incipit),"',data:search-options())]")
    else ()    
};

declare function bhses:explicit() as xs:string? {
    if($bhses:explicit != '') then concat("[ft:query(tei:bibl/tei:note[@type='explicit'],'",data:clean-string($bhses:explicit),"',data:search-options())]")
    else ()    
};

declare function bhses:editions() as xs:string? {
    if($bhses:editions != '') then concat("[ft:query(tei:bibl/tei:bibl[@type='lawd:Edition'],'",data:clean-string($bhses:editions),"',data:search-options())]")
    else ()    
};

declare function bhses:modern() as xs:string? {
    if($bhses:modern != '') then concat("[ft:query(tei:bibl/tei:bibl[@type='syriaca:ModernTranslation'],'",data:clean-string($bhses:modern),"',data:search-options())]")
    else ()    
};

declare function bhses:ancient() as xs:string? {
    if($bhses:ancient != '') then concat("[ft:query(tei:bibl/tei:bibl[@type='syriaca:AncientVersion'],'",data:clean-string($bhses:ancient),"',data:search-options())]")
    else ()    
};

declare function bhses:mss() as xs:string? {
    if($bhses:mss != '') then concat("[ft:query(tei:bibl/tei:bibl[@type='syriaca:Manuscript'],'",data:clean-string($bhses:mss),"',data:search-options())]")
    else ()    
};

declare function bhses:refs() as xs:string? {
    if($bhses:refs != '') then concat("[ft:query(tei:bibl/tei:bibl,'",data:clean-string($bhses:refs),"',data:search-options())]")
    else ()    
};

(:
 : NOTE: Forsee issues here if users want to seach multiple ids at one time. 
 : Thinking of how this should be enabled. 
:)
declare function bhses:idno() as xs:string? {
    if($bhses:idno != '') then 
        let $id := replace($bhses:idno,'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/work/',$id)
        return 
            if($bhses:id-type != '') then concat("[descendant::tei:idno[@type='",$bhses:id-type,"'][normalize-space(.) = '",$id,"']]")
            else concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    else ()    
};

declare function bhses:related-persons() as xs:string?{
    if($bhses:related-pers != '') then 
        if(matches($bhses:related-pers,'^http://syriaca.org/')) then 
            let $id := normalize-space($bhses:related-pers)
            return concat("[descendant::tei:relation[@passive[matches(.,'",$id,"(\W.*)?$')] or @active[matches(.,'",$id,"(\W.*)?$')]]]")
        else 
            let $ids := 
                string-join(distinct-values(
                    for $name in collection('/db/apps/srophe-data/data/persons')//tei:person[ft:query(tei:persName,$bhses:related-pers)]
                    let $id := $name/parent::*/descendant::tei:idno[starts-with(.,'http://syriaca.org')]
                    return concat($id/text(),'(\s|$)')),'|')
            return concat("[descendant::tei:relation[@passive[matches(@passive,'",$ids,"(\W.*)?$')] or @active[matches(@passive,'",$ids,"(\W.*)?$')]]]")
    else ()  
};

declare function bhses:child() as xs:string? {
    if(request:get-parameter('child-rec', '') != '') then
        if(starts-with(request:get-parameter('child-rec', ''),$global:base-uri)) then  
            concat("[tei:bibl/tei:listRelation/tei:relation[@passive[matches(.,'",request:get-parameter('child-rec', ''),"(\W.*)?$')]]]")
        else ()
    else ()    
};

(:~
 : Search limit by submodule. 
:)
declare function bhses:coll($collection) as xs:string?{
let $collection :=
    if($collection = 'bhse' ) then 'http://syriaca.org/bhse'
    else if($collection = 'nhsl' ) then 'http://syriaca.org/nhsl'
    else if($collection = 'bible' ) then 'http://syriaca.org/bible'
    else ()
return             
    if($collection != '') then concat("[ancestor::tei:TEI/descendant::tei:seriesStmt/descendant::tei:idno = '",$collection,"']")
    else ()
};

(:~
 : Build query string to pass to search.xqm 
:)
declare function bhses:query-string($collection) as xs:string? {
 concat("collection('",$global:data-root,"/works/tei')//tei:body",bhses:coll($collection),
    data:keyword(),bhses:title(),bhses:author(),bhses:prologue(),
    bhses:incipit(),bhses:explicit(),bhses:editions(),
    bhses:modern(),bhses:ancient(),bhses:mss(),
    bhses:refs(),bhses:related-persons(),bhses:child(),
    data:relation-search(),
    bhses:idno()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function bhses:search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = 'start' or $parameter = 'sort-element') then ()
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'related-pers') then 
                    (<span class="param">Related Persons: </span>,<span class="match">{$bhses:related-pers}&#160; </span>)
                else if($parameter = 'modern') then 
                    (<span class="param">Modern Translations: </span>,<span class="match">{$bhses:modern}&#160; </span>)
                else if($parameter = 'ancient') then 
                    (<span class="param">Ancient Versions: </span>,<span class="match">{$bhses:ancient}&#160; </span>)
                else if($parameter = 'mss') then 
                    (<span class="param">Manuscript: </span>,<span class="match">{$bhses:mss}&#160; </span>)            
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160;  </span>)    
            else ()               
};


(:~
 : Builds advanced search form for persons
 :)
declare function bhses:search-form($collection) {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
             <button type="button" class="btn btn-info pull-right" data-toggle="collapse" data-target="#searchTips">
                Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span>
            </button>&#160;
            <xi:include href="{$global:app-root}/searchTips.html"/>
        <div class="well well-small search-inner well-white">
              <div class="form-group">            
                <label for="coll" class="col-sm-2 col-md-3  control-label">Search in Resource: </label>
                <div class="col-sm-10 col-md-6">
                    <label class="checkbox-inline">
                        <input type="radio" name="coll" value="nhsl" aria-label="NHSL"/>
                        {
                            if($collection = 'nhsl') then attribute checked { "checked" }
                            else ()
                         }
                            NHSL
                    </label>
                    <label class="checkbox-inline">
                        <input type="radio" name="coll" value="q" aria-label="BHSE"/>
                        {
                            if($collection = 'bhse') then attribute checked { "checked" }
                            else ()
                        }
                        BHSE
                    </label>
                </div>
            </div>
        <!-- Keyword -->
            <div class="form-group">
                <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="qs" name="q" class="form-control keyboard" placeholder="English, French, Syriac"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('qs')}
                        </div>
                    </div> 
                </div>
            </div>
            <hr/>
            <div class="form-group">
                <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="title" name="title" class="form-control keyboard" placeholder="English, French, Syriac"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('title')}
                        </div>
                    </div> 
                </div>
            </div>
            <div class="form-group">
                <label for="title" class="col-sm-2 col-md-3  control-label">Author: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="author" name="author" class="form-control keyboard" placeholder="English, French, Syriac"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('author')}
                        </div>
                    </div> 
                </div>
            </div>
            <div class="form-group">
                <label for="relatedPers" class="col-sm-2 col-md-3  control-label">Related Persons: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="relatedPers" name="related-pers" class="form-control keyboard" placeholder="English, French, Syriac Keyword or Syriaca.org URI"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('relatedPers')}
                        </div>
                    </div> 
                </div>
            </div>          
            <hr/>  
            <div class="form-group">
                <label for="prologue" class="col-sm-2 col-md-3  control-label">Prologue: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="prologue" name="prologue" class="form-control keyboard" placeholder="French, Syriac"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('prologue')}
                        </div>
                    </div> 
                </div>
            </div> 
            <div class="form-group">
                <label for="incipit" class="col-sm-2 col-md-3  control-label">Incipit: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="incipit" name="incipit" class="form-control keyboard" placeholder="French, Syriac"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('incipit')}
                        </div>
                    </div> 
                </div>
            </div>       
            <div class="form-group">
                <label for="explicit" class="col-sm-2 col-md-3  control-label">Explicit: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                    <input type="text" id="explicit" name="explicit" class="form-control keyboard" placeholder="French, Syriac"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('explicit')}
                        </div>
                    </div> 
                </div>
            </div>  
            <div class="form-group">
                <label for="editions" class="col-sm-2 col-md-3  control-label">Editions: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                    <input type="text" id="editions" name="editions" class="form-control keyboard" placeholder="Keyword"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('editions')}
                        </div>
                    </div> 
                </div>
            </div> 
            <div class="form-group">
                <label for="modern" class="col-sm-2 col-md-3  control-label">Modern Translations: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                    <input type="text" id="modern" name="modern" class="form-control keyboard" placeholder="Keyword"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('modern')}
                        </div>
                    </div> 
                </div>
            </div>                            
            <div class="form-group">
                <label for="ancient" class="col-sm-2 col-md-3  control-label">Ancient Versions: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                    <input type="text" id="ancient" name="ancient" class="form-control keyboard" placeholder="Keyword"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('ancient')}
                        </div>
                    </div> 
                </div>
            </div>  
            <div class="form-group">
                <label for="mss" class="col-sm-2 col-md-3  control-label">Manuscripts: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                    <input type="text" id="mss" name="mss" class="form-control keyboard" placeholder="Keyword"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('mss')}
                        </div>
                    </div> 
                </div>
            </div> 
            <div class="form-group">
                <label for="sources" class="col-sm-2 col-md-3  control-label">References: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                    <input type="text" id="refs" name="refs" class="form-control keyboard" placeholder="Keyword"/>
                        <div class="input-group-btn">
                                <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                    &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                </button>
                                    {global:keyboard-select-menu('refs')}
                        </div>
                    </div> 
                </div>
            </div>             
            <hr/>
            <div class="form-group">            
                <label for="idno" class="col-sm-2 col-md-3  control-label">Text Id Number: </label>
                <div class="col-sm-4 col-md-2 ">
                    <input type="text" id="idno" name="idno" class="form-control"  placeholder="Ex: 3490"/>
                </div>
                <div class="col-sm-6 col-md-5 ">                
                <label class="checkbox-inline">
                    <input type="radio" name="id-type" value="BHO" aria-label="BHO"/> BHO
                </label>
                <label class="checkbox-inline">
                    <input type="radio" name="id-type" value="BHS" aria-label="BHS"/> BHS
                </label>
                <label class="checkbox-inline">
                    <input type="radio" name="id-type" value="CPG" aria-label="CPG"/> CPG
                </label>    
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