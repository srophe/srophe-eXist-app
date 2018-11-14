xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace nhsls="http://syriaca.org/srophe/nhsls";
import module namespace functx="http://www.functx.com";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $nhsls:q {request:get-parameter('q', '')};
declare variable $nhsls:title {request:get-parameter('title', '')};
declare variable $nhsls:author {request:get-parameter('author', '')};
declare variable $nhsls:prologue {request:get-parameter('prologue', '')};
declare variable $nhsls:incipit {request:get-parameter('incipit', '')};
declare variable $nhsls:explicit {request:get-parameter('explicit', '')};
declare variable $nhsls:editions {request:get-parameter('editions', '')};
declare variable $nhsls:modern {request:get-parameter('modern', '')};
declare variable $nhsls:ancient {request:get-parameter('ancient', '')};
declare variable $nhsls:mss {request:get-parameter('mss', '')};
declare variable $nhsls:refs {request:get-parameter('refs', '')};
declare variable $nhsls:related-pers {request:get-parameter('related-pers', '')};
declare variable $nhsls:idno {request:get-parameter('idno', '')};
declare variable $nhsls:id-type {request:get-parameter('id-type', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
:)
declare function nhsls:keyword() as xs:string? {
    if($nhsls:q != '') then concat("[ft:query(.,'",data:clean-string($nhsls:q),"',data:search-options()) or ft:query(descendant::tei:persName,'",data:clean-string($nhsls:q),"',data:search-options()) or ft:query(descendant::tei:placeName,'",data:clean-string($nhsls:q),"',data:search-options()) or ft:query(ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:title,'",data:clean-string($nhsls:q),"',data:search-options()) or ft:query(descendant::tei:desc,'",data:clean-string($nhsls:q),"',data:search-options())]")
    else ()    
};

declare function nhsls:title() as xs:string? {
    if($nhsls:title != '') then concat("[ft:query(tei:bibl/tei:title,'",data:clean-string($nhsls:title),"',data:search-options())]")
    else ()    
};

declare function nhsls:author() as xs:string? {
    if($nhsls:author != '') then
        if(starts-with($nhsls:author,$config:base-uri)) then 
            concat("[tei:bibl/tei:author[@ref='",$nhsls:author,"']]")
        else
            concat("[ft:query(tei:bibl/tei:author,'",data:clean-string($nhsls:author),"',data:search-options())]")
    else ()    
};

declare function nhsls:prologue() as xs:string? {
    if($nhsls:prologue != '') then concat("[ft:query(tei:bibl/tei:note[@type='prologue'],'",data:clean-string($nhsls:prologue),"',data:search-options())]")
    else ()    
};

declare function nhsls:incipit() as xs:string? {
    if($nhsls:incipit != '') then concat("[ft:query(tei:bibl/tei:note[@type='incipit'],'",data:clean-string($nhsls:incipit),"',data:search-options())]")
    else ()    
};

declare function nhsls:explicit() as xs:string? {
    if($nhsls:explicit != '') then concat("[ft:query(tei:bibl/tei:note[@type='explicit'],'",data:clean-string($nhsls:explicit),"',data:search-options())]")
    else ()    
};

declare function nhsls:editions() as xs:string? {
    if($nhsls:editions != '') then concat("[ft:query(tei:bibl/tei:note[@type='editions'],'",data:clean-string($nhsls:editions),"',data:search-options())]")
    else ()    
};

declare function nhsls:modern() as xs:string? {
    if($nhsls:modern != '') then concat("[ft:query(tei:bibl/tei:note[@type='modernTranslation'],'",data:clean-string($nhsls:modern),"',data:search-options())]")
    else ()    
};

declare function nhsls:ancient() as xs:string? {
    if($nhsls:ancient != '') then concat("[ft:query(tei:bibl/tei:note[@type='ancientVersion'],'",data:clean-string($nhsls:ancient),"',data:search-options())]")
    else ()    
};

declare function nhsls:mss() as xs:string? {
    if($nhsls:mss != '') then concat("[ft:query(tei:bibl/tei:note[@type='MSS'],'",data:clean-string($nhsls:mss),"',data:search-options())]")
    else ()    
};

declare function nhsls:refs() as xs:string? {
    if($nhsls:refs != '') then concat("[ft:query(tei:bibl/tei:bibl,'",data:clean-string($nhsls:refs),"',data:search-options())]")
    else ()    
};

(:
 : NOTE: Forsee issues here if users want to seach multiple ids at one time. 
 : Thinking of how this should be enabled. 
:)
declare function nhsls:idno() as xs:string? {
    if($nhsls:idno != '') then 
        let $id := replace($nhsls:idno,'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/work/',$id)
        return 
            if($nhsls:id-type != '') then concat("[descendant::tei:idno[@type='",$nhsls:id-type,"'][normalize-space(.) = '",$id,"']]")
            else concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    else ()    
};

declare function nhsls:related-persons() as xs:string?{
    if($nhsls:related-pers != '') then 
        if(matches($nhsls:related-pers,'^http://syriaca.org/')) then 
            let $id := normalize-space($nhsls:related-pers)
            return concat("[descendant::tei:relation[@passive[matches(.,'",$id,"')] or @active[matches(.,'",$id,"')]]]")
        else 
            let $ids := 
                string-join(distinct-values(
                    for $name in collection('/db/apps/srophe-data/data/persons')//tei:person[ft:query(tei:persName,$nhsls:related-pers)]
                    let $id := $name/parent::*/descendant::tei:idno[starts-with(.,'http://syriaca.org')]
                    return concat($id/text(),'(\s|$)')),'|')
            return concat("[descendant::tei:relation[@passive[matches(@passive,'",$ids,"')] or @active[matches(@passive,'",$ids,"')]]]")
    else ()  
};
(:~
 : Build query string to pass to search.xqm 
:)
declare function nhsls:query-string() as xs:string? {
 concat("collection('",$config:data-root,"/works/tei')//tei:body",
    data:keyword-search(),nhsls:title(),nhsls:author(),nhsls:prologue(),
    nhsls:incipit(),nhsls:explicit(),nhsls:editions(),
    nhsls:modern(),nhsls:ancient(),nhsls:mss(),
    nhsls:refs(),nhsls:related-persons(),
    nhsls:idno()
    )
};

(:~
 : Builds advanced search form for persons
 :)
declare function nhsls:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
        {let $search-config := 
                if(doc-available(concat($config:app-root, '/nhsl/search-config.xml'))) then concat($config:app-root, '/nhsl/search-config.xml')
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
                <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="q" name="q" class="form-control" placeholder="English, French, Syriac"/>
                </div>
            </div> 
            <hr/>         
            <div class="form-group">            
                <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="title" name="title" class="form-control"  placeholder="English, French, Syriac"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="author" class="col-sm-2 col-md-3  control-label">Author: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="author" name="author" class="form-control" placeholder="English, French, Syriac"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="related-pers" class="col-sm-2 col-md-3  control-label">Related Persons: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="related-pers" name="related-pers" class="form-control" placeholder="English, French, Syriac Keyword or Syriaca.org URI"/>
                </div>
            </div>              
            <hr/>         
            <div class="form-group">            
                <label for="prologue" class="col-sm-2 col-md-3  control-label">Prologue: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="prologue" name="prologue" class="form-control" placeholder="French, Syriac"/>
                </div>
            </div> 
            <div class="form-group">            
                <label for="incipit" class="col-sm-2 col-md-3  control-label">Incipit: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="incipit" name="incipit" class="form-control" placeholder="French, Syriac"/>
                </div>
            </div> 
            <div class="form-group">            
                <label for="explicit" class="col-sm-2 col-md-3  control-label">Explicit: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="explicit" name="explicit" class="form-control" placeholder="French, Syriac"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="editions" class="col-sm-2 col-md-3  control-label">Editions: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="editions" name="editions" class="form-control" placeholder="Keyword"/>
                </div>
            </div> 
            <div class="form-group">            
                <label for="modern" class="col-sm-2 col-md-3  control-label">Modern Translations: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="modern" name="modern" class="form-control" placeholder="Keyword"/>
                </div>
            </div> 
            <div class="form-group">            
                <label for="ancient" class="col-sm-2 col-md-3  control-label">Ancient Versions: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="ancient" name="ancient" class="form-control" placeholder="Keyword"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="mss" class="col-sm-2 col-md-3  control-label">Manuscripts: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="mss" name="mss" class="form-control" placeholder="Keyword"/>
                </div>
            </div>
            <div class="form-group">            
                <label for="sources" class="col-sm-2 col-md-3  control-label">References: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="refs" name="refs" class="form-control" placeholder="Keyword"/>
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