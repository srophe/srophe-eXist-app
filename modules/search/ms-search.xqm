xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace ms="http://syriaca.org/srophe/ms";
import module namespace functx="http://www.functx.com";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Build query string to pass to search.xqm 
:)
declare function ms:query-string() as xs:string? {
 concat("collection('",$config:data-root,"/manuscripts/tei')//tei:teiHeader",
    data:keyword-search()
    )
};

(:~
 : Format search results
 : Need a better uri for factoids, 
:)
declare function ms:results-node($hit){
    let $root := $hit 
    let $title := $root/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title/text()
    let $id := $root/ancestor::tei:TEI/descendant::tei:idno[starts-with(.,$config:base-uri)][1]/text()
    return 
        <p style="font-weight:bold padding:.5em;">
            <a href="manuscript.html?id={$id}">{$title}</a>
        </p>
};

(:~
 : Builds advanced search form for persons
 :)
declare function ms:search-form() {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
        {let $search-config := 
                if(doc-available(concat($config:app-root, '/ms/search-config.xml'))) then concat($config:app-root, '/ms/search-config.xml')
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
            <label for="q" class="col-sm-2 col-md-3  control-label">Full-text: </label>
            <div class="col-sm-10 col-md-9 ">
                <div class="input-group">
                    <input type="text" id="qs" name="q" class="form-control keyboard"/>
                    <div class="input-group-btn">{global:keyboard-select-menu('qs')}</div>
                </div> 
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