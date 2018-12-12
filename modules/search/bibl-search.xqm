xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bibls="http://syriaca.org/srophe/bibls";
import module namespace functx="http://www.functx.com";

import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bibls:title {request:get-parameter('title', '')};
declare variable $bibls:author {request:get-parameter('author', '')};
declare variable $bibls:idno {request:get-parameter('idno', '')};
declare variable $bibls:subject {request:get-parameter('subject', '')};
declare variable $bibls:id-type {request:get-parameter('id-type', '')};
declare variable $bibls:pub-place {request:get-parameter('pub-place', '')};
declare variable $bibls:publisher {request:get-parameter('publisher', '')};
declare variable $bibls:date {request:get-parameter('date', '')};

declare function bibls:title() as xs:string? {
    if($bibls:title != '') then concat("[ft:query(descendant::tei:title,'",data:clean-string($bibls:title),"',data:search-options())]")
    else ()    
};

declare function bibls:author() as xs:string? {
    if($bibls:author != '') then concat("[ft:query(descendant::tei:author,'",data:clean-string($bibls:author),"',data:search-options()) or ft:query(descendant::tei:editor,'",data:clean-string($bibls:author),"',data:search-options())]")
    else ()    
};

(:
 : NOTE: Forsee issues here if users want to seach multiple ids at one time. 
 : Thinking of how this should be enabled. 
:)
declare function bibls:idno() as xs:string? {
    if($bibls:idno != '') then  
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][matches(.,'",$bibls:idno,"$')]]")
            else concat("[descendant::tei:idno[matches(.,'",$bibls:idno,"$')]]")

    (:
        let $id := replace($bibls:idno,'[^\d\s]','')
        let $syr-id := concat('http://syriaca.org/bibl/',$id)
        return 
            if($bibls:id-type != '') then concat("[descendant::tei:idno[@type='",$bibls:id-type,"'][normalize-space(.) = '",$id,"']]")
            else concat("[descendant::tei:idno[normalize-space(.) = '",$id,"' or .= '",$syr-id,"']]")
    :)            
    else ()    
};

declare function bibls:pub-place() as xs:string? {
    if($bibls:pub-place != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:pubPlace,'",data:clean-string($bibls:pub-place),"',data:search-options())]")
    else ()  
};

declare function bibls:publisher() as xs:string? {
    if($bibls:publisher != '') then 
        concat("[ft:query(descendant::tei:imprint/tei:publisher,'",data:clean-string($bibls:publisher),"',data:search-options())]")
    else ()  
};

declare function bibls:date() as xs:string? {
    if($bibls:date != '') then 
        concat("[matches(descendant::tei:imprint/tei:date,'",$bibls:date,"')]")
    else ()  
};

declare function bibls:subject() as xs:string?{
    if($bibls:subject != '') then 
        concat("collection('",$config:data-root,"')//tei:idno[.='",$bibls:subject,"']/ancestor::tei:body/descendant::tei:bibl[child::tei:ptr]")
    else ()  
};

declare function bibls:bibl() as xs:string?{
    if(request:get-parameter('bibl', '') != '') then
        concat("collection('",$config:data-root,"')//tei:body[.//@target[. = '", request:get-parameter('bibl', '') ,"']]/ancestor::tei:TEI")
    else ()  
};

(:~     
 : Build query string to pass to search.xqm 
:)
declare function bibls:query-string() as xs:string? { 
if($bibls:subject != '') then bibls:subject()
else if(request:get-parameter('bibl', '')) then bibls:bibl()
else
 concat("collection('",$config:data-root,"/bibl/tei')//tei:body",
    data:keyword-search(),
    bibls:title(),
    bibls:author(),
    bibls:pub-place(),
    bibls:publisher(),
    bibls:date(),
    bibls:idno()
    )
};

(:~
 : Builds advanced search form for persons
 :)
declare function bibls:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
        {let $search-config := 
                if(doc-available(concat($config:app-root, '/bibl/search-config.xml'))) then concat($config:app-root, '/bibl/search-config.xml')
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
                    <div class="input-group">
                        <input type="text" id="qs" name="q" class="form-control keyboard" placeholder="Any word in citation"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('qs')}</div>
                    </div>                 
                </div>
            </div> 
            <hr/>         
            <div class="form-group">            
                <label for="title" class="col-sm-2 col-md-3  control-label">Title: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="title" name="title" class="form-control keyboard"  placeholder="Title of article, journal, book, or series"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('title')}</div>
                    </div>                 
                </div>
            </div>
            <div class="form-group">            
                <label for="author" class="col-sm-2 col-md-3  control-label">Author/Editor: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="author" name="author" class="form-control keyboard" placeholder="First Last or Last, First"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('author')}</div>
                    </div>                
                </div>
            </div>  
            <div class="form-group">            
                <label for="pub-place" class="col-sm-2 col-md-3  control-label">Publication Place: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                        <input type="text" id="pubPlace" name="pub-place" class="form-control keyboard" placeholder="First Last or Last, First"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('pubPlace')}</div>
                    </div>                
                </div>
            </div>
            <div class="form-group">            
                <label for="publisher" class="col-sm-2 col-md-3  control-label">Publisher: </label>
                <div class="col-sm-10 col-md-6 ">
                    <div class="input-group">
                    <input type="text" id="publisher" name="publisher" class="form-control keyboard" placeholder="Publisher Name"/>
                            <div class="input-group-btn">{global:keyboard-select-menu('publisher')}</div>
                    </div>                 
                </div>
            </div>   
            <div class="form-group">            
                <label for="date" class="col-sm-2 col-md-3  control-label">Date: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="date" name="date" class="form-control" placeholder="Year as YYYY"/>
                </div>
            </div>   
            <hr/>
            <div class="form-group">            
                <label for="idno" class="col-sm-2 col-md-3  control-label">Id Number: </label>
                <div class="col-sm-10 col-md-2 ">
                    <input type="text" id="idno" name="idno" class="form-control"  placeholder="Ex: 3490"/>
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