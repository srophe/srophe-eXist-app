xquery version "3.0";
(:~
 : Paging module for reuse by search and browse pages
 : Adds page numbers and sort options to HTML output.  
 :) 
module namespace page="http://syriaca.org/srophe/page";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";

import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~
 : Build paging menu for search results, includes search string
 : $param @hits hits as nodes
 : $param @start start number passed from url
 : $param @perpage number of hits to show 
 : $param @sort include search options 
:)
declare function page:pages(
    $hits as node()*, 
    $collection as xs:string?,
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
            if($search-string = ('yes','Yes')) then  
                if(page:display-search-params($collection) != '') then 
                <div class="col-sm-5 search-string">
                    <h3 class="hit-count paging">Search results: </h3>
                    <p class="col-md-offset-1 hit-count">{$total-result-count} matches for {page:display-search-params($collection)} </p>
                    <p class="col-md-offset-1 hit-count note small">
                    You may wish to expand your search by using our 
                    <a href="search.html">advanced search functions</a> or by using wildcard characters to increase results. 
                    See <a href="#" data-toggle="collapse" data-target="#searchTips">search tips</a> for more details.
                    </p> 
                 </div>
                else ()
             else ()
             }
            <div>
                {if($search-string = ('yes','Yes')) then attribute class { "col-md-7" } else attribute class { "col-md-12" } }
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
                    if($search-string = ('yes','Yes')) then   
                        <li class="pull-right"><a href="search.html" class="clear-search"><span class="glyphicon glyphicon-search"/> New</a></li>
                    else() 
                    )}
                </ul>
                }
            </div>
    </div>
    )    
return 
    ($pagination-links,
    let $search-config := 
        if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
            else concat($config:app-root, '/search-config.xml')
    let $config := 
        if(doc-available($search-config)) then doc($search-config)
        else ()                            
    return 
        if($config//search-tips != '') then
            <div class="panel panel-default collapse" id="searchTips">
                <div class="panel-body">
                <h3 class="panel-title">Search Tips</h3>
                {$config//search-tips}
                </div>
            </div>
        else if(doc-available($config:app-root || '/searchTips.html')) then doc($config:app-root || '/searchTips.html')
        else ()
    )
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

(:~
 : User friendly display of search parameters for HTML pages
 : Filters out $start, $sort-element and $perpage parameters. 
:)
declare function page:display-search-params($collection as xs:string?){
    if($collection = ('sbd','q','authors','saints','persons')) then page:person-search-string()
    else if($collection ='spear') then page:spear-search-string()
    else if($collection = 'places') then page:place-search-string()
    else if($collection = ('bhse','nhsl','bible')) then page:bhse-search-string()
    else if($collection = 'bibl') then page:bibl-search-string()
    else 
    <span xmlns="http://www.w3.org/1999/xhtml">
    {(
        let $parameters :=  request:get-parameter-names()
        let $search-config := 
            if($collection != '') then concat($config:app-root, '/', string(config:collection-vars($collection)/@app-root),'/','search-config.xml')
            else concat($config:app-root, '/','search-config.xml')
        let $search-config :=  
            if(doc-available($search-config)) then 
                doc($search-config) 
            else ()
        for  $parameter in $parameters
        return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = ('start','sort-element','perpage','sort')) then ()
                else if($parameter = $search-config//input/@name) then
                   (<span class="param">{string($search-config//input[@name = $parameter]/@name)}: </span>,<span class="param-string">{request:get-parameter($parameter, '')}</span>) 
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="param-string">{request:get-parameter($parameter, '')}</span>)
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="param-string">{request:get-parameter($parameter, '')}</span>)    
            else ())
            }
    </span>
};

(: Syriaca.org collection speccific search params :)
(: Places :)
declare function page:place-search-string(){
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = ('start','sort-element','perpage','sort')) then ()
            else if($parameter = ('q','keyword')) then 
                (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'p') then 
                (<span class="param">Place Name: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'type') then 
                (<span class="param">Type: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'loc') then 
                (<span class="param">Location: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'e') then 
                (<span class="param">Event: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'eds') then 
                (<span class="param">Event Start Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'ede') then 
                (<span class="param">Event End Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'a') then 
                (<span class="param">Attestations: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'ads') then 
                (<span class="param">Attestations Start Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'ade') then 
                (<span class="param">Attestations End Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'c') then 
                (<span class="param">Religious Communities: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'cds') then 
                (<span class="param">Religious Communities Start Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'cde') then 
                (<span class="param">Religious Communities End Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)            
            else if($parameter = 'existds') then 
                (<span class="param">Existence Start Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'existde') then 
                (<span class="param">Existence End Date: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)        
            else if($parameter = 'en' and request:get-parameter($parameter, '') != '') then 
                (<span class="param">English </span>)  
            else if($parameter = 'syr' and request:get-parameter($parameter, '') != '') then 
                (<span class="param">Syriac </span>)
            else if($parameter = 'ar' and request:get-parameter($parameter, '') != '') then 
                (<span class="param">Arabic </span>)    
            else (<span class="param"> {replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>                                            
};

(: Spear :)
declare function page:spear-search-string() as xs:string*{
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = ('start','sort-element','perpage','sort')) then ()
            else if($parameter = 'fq') then ()
            else if($parameter = ('q','keyword')) then 
                (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160;</span>)
            else if($parameter = 'keyword') then 
                (<span class="param">Controlled Keyword: </span>,<span class="match">{lower-case(functx:camel-case-to-words(substring-after(request:get-parameter($parameter, ''),'/keyword/'),' '))}&#160; </span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>
};

declare function page:bhse-search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = ('start','sort-element','perpage','sort')) then ()
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'coll') then 
                    (<span class="param">Collection: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'related-pers') then 
                    (<span class="param">Related Persons: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'modern') then 
                    (<span class="param">Modern Translations: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'ancient') then 
                    (<span class="param">Ancient Versions: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'mss') then 
                    (<span class="param">Manuscript: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)            
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160;  </span>)    
            else ()               
};

declare function page:bibl-search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
        return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = ('start','sort-element','perpage','sort')) then ()
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if ($parameter = 'author') then 
                    (<span class="param">Author/Editor: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
            else ()               
};

declare function page:nhsl-search-string(){
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
        return 
            if(request:get-parameter($parameter, '') != '') then
                if($parameter = ('start','sort-element','perpage','sort')) then ()
                else if($parameter = 'q') then 
                    (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'related-pers') then 
                    (<span class="param">Related Persons: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'modern') then 
                    (<span class="param">Modern Translations: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'ancient') then 
                    (<span class="param">Ancient Versions: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
                else if($parameter = 'mss') then 
                    (<span class="param">Manuscript: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)            
                else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
            else ()               
};

declare function page:person-search-string() as node()*{
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = ('start','sort-element','perpage','sort')) then ()
            else if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
           (: else if($parameter = 'coll') then 
                (<span class="param">Resource: </span>,<span class="match">{
                    if($persons:coll = 'sbd' ) then '"The Syriac Biographical Dictionary"'
                    else if($persons:coll = 'q' ) then '"Qadishe: A Guide to the Syriac Saints"'
                    else if($persons:coll = 'authors' ) then '"A Guide to Syriac Authors"'
                    else $persons:coll
                }&#160; </span>):)
            else if($parameter = 'coll') then 
                (<span class="param">Collection: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else if($parameter = 'persName') then 
                (<span class="param">Person Name: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)                
            else if($parameter = 'gender') then 
                (<span class="param">Sex or Gender: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)
            else (<span class="param"> {replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
      </span>
};
