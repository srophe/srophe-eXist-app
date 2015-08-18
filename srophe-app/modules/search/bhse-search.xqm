xquery version "3.0";
(:~
 : Builds search information for spear sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace bhses="http://syriaca.org//bhses";
import module namespace functx="http://www.functx.com";
import module namespace facets="http://syriaca.org//facets" at "../facets.xqm";
import module namespace app="http://syriaca.org//templates" at "../app.xql";
import module namespace common="http://syriaca.org//common" at "common.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "../config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $bhses:q {request:get-parameter('q', '')};

(:~
 : Build full-text keyword search over all tei:place data
 : @param $q query string
:)
declare function bhses:keyword() as xs:string? {
    if($bhses:q != '') then concat("[ft:query(.,'",common:clean-string($bhses:q),"',common:options()) or ft:query(descendant::tei:persName,'",common:clean-string($bhses:q),"',common:options()) or ft:query(descendant::tei:placeName,'",common:clean-string($bhses:q),"',common:options()) or ft:query(ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:title,'",common:clean-string($bhses:q),"',common:options()) or ft:query(descendant::tei:desc,'",common:clean-string($bhses:q),"',common:options())]")
    else ()    
};


(:~
 : Build query string to pass to search.xqm 
:)
declare function bhses:query-string() as xs:string? {
 concat("collection('",$config:data-root,"/works/tei')//tei:body",
    bhses:keyword()
    )
};

(:~
 : Build a search string for search results page from search parameters
:)
declare function bhses:search-string() as xs:string*{
    let $keyword-string := if($bhses:q != '') then 
                                (<span class="param">Keyword: </span>,<span class="match">{common:clean-string($bhses:q)}&#160;</span>)
                           else ''                          
    return $keyword-string                  
};

(:~
 : Format search results
 : Need a better uri for factoids, 
:)
declare function bhses:results-node($hit){
    let $root := $hit 
    let $title := $root/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title/text()
    let $id := $root/ancestor::tei:TEI/descendant::tei:idno[starts-with(.,'http://syriaca.org')][1]/text()
    return 
        <p style="font-weight:bold padding:.5em;">
            <a href="manuscript.html?id={$id}">{$title}</a>
        </p>
};


(:~
 : Builds advanced search form for persons
 :)
declare function bhses:search-form() {   
<form method="get" action="search.html" class="form-horizontal" role="form">
    <h1>Advanced Search</h1>
    <div class="well well-small">
        <div><p><em>Wild cards * and ? may be used to optimize search results.
        Wild cards may not be used at the beginning of a word, as it hinders search speed.</em></p></div>
        <div class="well well-small search-inner well-white">
        <!-- Keyword -->
            <div class="form-group">            
                <label for="q" class="col-sm-2 col-md-3  control-label">Full-text: </label>
                <div class="col-sm-10 col-md-6 ">
                    <input type="text" id="q" name="q" class="form-control"/>
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