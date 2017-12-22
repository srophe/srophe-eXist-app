xquery version "3.0";
(:~
 : Paging module for reuse by search and browse pages 
 :)
 
module namespace page="http://syriaca.org/page";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~ 
 : Adds sort filter based on sort prameter
:)
declare function page:add-sort-options($hit, $sort-element as xs:string*){
    if($sort-element != '') then
        if($sort-element = 'title') then 
            global:build-sort-string($hit/ancestor::tei:TEI/descendant::tei:title[1],'')
        else if($sort-element = 'author') then 
            if($hit/ancestor::tei:TEI/descendant::tei:author[1]) then 
                if($hit/ancestor::tei:TEI/descendant::tei:author[1]/descendant-or-self::tei:surname) then 
                    $hit/ancestor::tei:TEI/descendant::tei:author[1]/descendant-or-self::tei:surname[1]
                else $hit/ancestor::tei:TEI/descendant::tei:author[1]
            else 
                if($hit/ancestor::tei:TEI/descendant::tei:editor[1]/descendant-or-self::tei:surname) then 
                    $hit/ancestor::tei:TEI/descendant::tei:editor[1]/descendant-or-self::tei:surname[1]
                else $hit/ancestor::tei:TEI/descendant::tei:editor[1]
        else if($sort-element = 'pubDate') then 
            $hit/ancestor::tei:TEI/descendant::tei:imprint[1]/descendant-or-self::tei:date[1]
        else if($sort-element = 'pubPlace') then 
            $hit/ancestor::tei:TEI/descendant::tei:imprint[1]/descendant-or-self::tei:pubPlace[1]
        else if($sort-element = 'persDate') then
            if($hit/ancestor::tei:TEI/descendant::tei:birth) then $hit/ancestor::tei:TEI/descendant::tei:birth/@syriaca-computed-start
            else if($hit/ancestor::tei:TEI/descendant::tei:death) then $hit/ancestor::tei:TEI/descendant::tei:death/@syriaca-computed-start
            else ()
        else $hit
    else $hit
};

(:~
 : Build paging menu for search results, includes search string
 : $param @hits hits as nodes
 : $param @start start number passed from url
 : $param @perpage number of hits to show 
 : $param @sort include search options 
:)
declare function page:pages(
    $hits as node()*, 
    $start as xs:integer?, 
    $perpage as xs:integer?, 
    $search-string as xs:string*,
    $sort-options as xs:string*){
let $perpage := if($perpage) then xs:integer($perpage) else 20
let $start := if($start) then $start else 1
let $total-result-count := count($hits)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function, strip start parameter :)
let $url-params := replace(replace(request:get-query-string(), '&amp;start=\d+', ''),'start=\d+','')
let $param-string := if($url-params != '') then concat('?',$url-params,'&amp;start=') else '?start='        
let $pagination-links := 
    (<div class="row alpha-pages" xmlns="http://www.w3.org/1999/xhtml">
            {
            if($search-string != '') then             
                <div class="col-sm-5 search-string">
                    <h3 class="hit-count paging">Search results:</h3>
                    <p class="col-md-offset-1 hit-count">{$total-result-count} matches for {$search-string}.</p>
                    <p class="col-md-offset-1 hit-count note">
                        You may wish to expand your search by using our advanced <a href="search.html">search functions</a> or by 
                        using wildcard characters to increase results. See  
                        <a href="#" data-toggle="collapse" data-target="#searchTips">search tips</a> for more details.
                    </p>        
                 </div>
             else ()
             }
            <div>
                {if($search-string != '') then attribute class { "col-md-7" } else attribute class { "col-md-12" } }
                {
                if($total-result-count gt $perpage) then 
                <ul class="pagination pull-right">
                    {((: Show 'Previous' for all but the 1st page of results :)
                        if ($current-page = 1) then ()
                        else <li><a href="{concat($param-string, $perpage * ($current-page - 2)) }">Prev</a></li>,
                        (: Show links to each page of results :)
                        let $max-pages-to-show := 8
                        let $padding := xs:integer(round($max-pages-to-show div 2))
                        let $start-page := 
                                      if ($current-page le ($padding + 1)) then
                                          1
                                      else $current-page - $padding
                        let $end-page := 
                                      if ($number-of-pages le ($current-page + $padding)) then
                                          $number-of-pages
                                      else $current-page + $padding - 1
                        for $page in ($start-page to $end-page)
                        let $newstart := 
                                      if($page = 1) then 1 
                                      else $perpage * ($page - 1)
                        return 
                            if ($newstart eq $start) then <li class="active"><a href="#" >{$page}</a></li>
                             else <li><a href="{concat($param-string, $newstart)}">{$page}</a></li>,
                        (: Shows 'Next' for all but the last page of results :)
                        if ($start + $perpage ge $total-result-count) then ()
                        else <li><a href="{concat($param-string, $start + $perpage)}">Next</a></li>,
                        if($sort-options != '') then page:sort($param-string, $start, $sort-options)
                        else(),
                        <li><a href="{concat($param-string,'1&amp;perpage=',$total-result-count)}">All</a></li>,
                        if($search-string != '') then
                            <li class="pull-right search-new"><a href="search.html"><span class="glyphicon glyphicon-search"/> New</a></li>
                        else ()    
                        )}
                </ul>
                else 
                <ul class="pagination pull-right">
                {(
                    if($sort-options != '') then page:sort($param-string, $start, $sort-options)
                    else(),
                    if($search-string != '') then   
                        <li class="pull-right"><a href="search.html"><span class="glyphicon glyphicon-search"/> New</a></li>
                    else() 
                    )}
                </ul>
                }
            </div>
    </div>,
    if($search-string != '') then 
        <xi:include href="{$global:app-root}/searchTips.html"/>
    else ()
    )    
return $pagination-links
   
};

(:~
 : Build sort options menu for search/browse results
 : $param @param-string search parameters passed from URL, empty for browse
 : $param @start start number passed from url 
 : $param @options include search options a comma separated list
:)
declare function page:sort($param-string as xs:string?, $start as xs:integer?, $options as xs:string*){
<li xmlns="http://www.w3.org/1999/xhtml">
    <div class="btn-group">
        <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort <span class="caret"/></button>
            <ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dropdownMenu1">
                {
                    for $option in tokenize($options,',')
                    return 
                    <li role="presentation">
                        <a role="menuitem" tabindex="-1" href="{concat(replace($param-string,'&amp;sort-element=(\w+)', ''),$start,'&amp;sort-element=',$option)}" id="rel">
                            {
                                if($option = 'pubDate' or $option = 'persDate') then 'Date'
                                else if($option = 'pubPlace') then 'Place of publication'
                                else functx:capitalize-first($option)
                            }
                        </a>
                    </li>
                }
            </ul>
        </div>
    </div>
</li>
};