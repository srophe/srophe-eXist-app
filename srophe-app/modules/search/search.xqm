xquery version "3.0";

module namespace search="http://syriaca.org/search";
import module namespace facets="http://syriaca.org/facets" at "../lib/facets.xqm";
import module namespace places="http://syriaca.org/places" at "places-search.xqm";
import module namespace common="http://syriaca.org/common" at "common.xqm";
import module namespace geo="http://syriaca.org/geojson" at "../lib/geojson.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;


declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Shared global parameters for building search paging function
:)
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:sort {request:get-parameter('sort', '') cast as xs:string};
declare variable $search:perpage {request:get-parameter('perpage', 1) cast as xs:integer};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};


(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string := 
                        if($coll = 'places') then places:query-string()
                        else search:query-string($collection)
    return                         
    map {"hits" := 
                if($search:sort = 'alpha') then 
                    for $hit in util:eval($eval-string)
                    let $en-title := 
                                 if($hit/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/child::*) then 
                                     string-join($hit/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/child::*/text(),' ')
                                 else if(string-join($hit/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/text())) then 
                                    string-join($hit/descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/text(),' ')   
                                 else $hit/ancestor::tei:TEI/descendant::tei:title[1]/text()
                    order by common:build-sort-string($en-title) ascending
                    return $hit                                                     
                else if($search:sort = 'date') then 
                    for $hit in util:eval($eval-string)
                    let $date := 
                            if($hit/descendant::tei:birth) then $hit/descendant::tei:birth/@syriaca-computed-start
                            else if($hit/descendant::tei:death) then $hit/descendant::tei:death/@syriaca-computed-start
                            else ()
                    order by xs:date($date) ascending
                    return $hit 
                else 
                    for $hit in util:eval($eval-string)
                    order by ft:score($hit) + count($hit/descendant::tei:bibl) descending
                    return $hit
         }
};

(:~
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
concat("collection('",$global:data-root,$collection,"')//tei:body",
    places:keyword(),
    places:place-name()
    )
};

declare function search:search-api($q,$place,$person){
let $keyword-string := 
    if(exists($q) and $q != '') then concat("[ft:query(.,'",common:clean-string($q),"',common:options())]")
    else ()    
let $place-name := 
    if(exists($place) and $place != '') then concat("[ft:query(descendant::tei:placeName,'",common:clean-string($place),"',common:options())]")
    else ()
let $pers-name := 
    if(exists($person) and $person != '') then concat("[ft:query(descendant::tei:persName,'",common:clean-string($person),"',common:options())]")
    else ()
let $query-string := 
    concat("collection('",$global:data-root,"')//tei:body",
    $keyword-string,$pers-name,$place-name)
return $query-string
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
    places:search-string()
};

declare %templates:wrap function search:spear-facets($node as node(), $model as map(*)){
if(exists(request:get-parameter-names())) then 
    <div>
     <h4>Browse by</h4>
     {
        let $facet-nodes := $model('hits')
        let $facets := $facet-nodes//tei:persName | $facet-nodes//tei:placeName | $facet-nodes//tei:event 
        | $facet-nodes/ancestor::tei:TEI/descendant::tei:titleStmt[1]/tei:title[1]
        return facets:facets($facets)
     }
    </div>
else ()    
};

(:~ 
 : Count total hits
:)
declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

(:~
 : Build paging for search results pages
 : If 0 results show search form
:)
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*), $collection as xs:string?){
let $perpage := 20
let $start := if($search:start) then $search:start else 1
let $total-result-count := search:hit-count($node, $model)
let $end := 
    if ($total-result-count lt $perpage) then 
        $total-result-count
    else 
        $start + $perpage
let $number-of-pages :=  xs:integer(ceiling($total-result-count div $perpage))
let $current-page := xs:integer(($start + $perpage) div $perpage)
(: get all parameters to pass to paging function:)
let $url-params := replace(request:get-query-string(), '&amp;start=\d+', '')
let $parameters :=  request:get-parameter-names()
let $sort-options :=
                <li class="pull-right">
                    <div class="btn-group">
                        <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort <span class="caret"/></button>
                            <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                                <li role="presentation"><a role="menuitem" tabindex="-1" href="{concat('?', replace($url-params,'&amp;sort=(\w+)', ''), '&amp;start=', $start,'&amp;sort=rel')}" id="rel">Relevance</a></li>
                                <li role="presentation"><a role="menuitem" tabindex="-1" href="{concat('?', replace($url-params,'&amp;sort=(\w+)', ''), '&amp;start=', $start,'&amp;sort=alpha')}" id="alpha">Alphabetical (Title)</a></li>
                                {if($collection != 'places') then
                                    <li role="presentation"><a role="menuitem" tabindex="-1" href="{concat('?', replace($url-params,'&amp;sort=(\w+)', ''), '&amp;start=', $start,'&amp;sort=date')}" id="date">Date</a></li>
                                else()}
                            </ul>
                        </div>
                    </div>
                </li>
let $pagination-links := 
        <div class="row" xmlns="http://www.w3.org/1999/xhtml">
            <div class="col-sm-5">
            <h4 class="hit-count">Search results:</h4>
                <p class="col-md-offset-1 hit-count">{$total-result-count} matches for {search:search-string($collection)}.</p>
            </div>
            {if(search:hit-count($node, $model) gt $perpage) then 
              <div class="col-md-7">
                       <ul class="pagination  pull-right">
                          {
                          (: Show 'Previous' for all but the 1st page of results :)
                              if ($current-page = 1) then ()
                              else
                                  <li><a href="{concat('?', $url-params, '&amp;start=', $perpage * ($current-page - 2)) }">Prev</a></li>
                          }
                          {
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
                                  (
                                  if ($newstart eq $start) then 
                                      (<li class="active"><a href="#" >{$page}</a></li>)
                                  else
                                      <li><a href="{concat('?', $url-params, '&amp;start=', $newstart)}">{$page}</a></li>
                                  )
                          }
           
                          {
                          (: Shows 'Next' for all but the last page of results :)
                              if ($start + $perpage ge $total-result-count) then ()
                              else
                                  <li><a href="{concat('?', $url-params, '&amp;start=', $start + $perpage)}">Next</a></li>
                          }
                          {$sort-options}
                      </ul>
              </div>
             else 
             <div class="col-md-7">
                <ul class="pagination  pull-right">
                   {$sort-options}
                </ul>
             </div>
             }
        </div>    
return 
   if(exists(request:get-parameter-names())) then $pagination-links
   else ()
};

(:~
 : Build Map view of search results with coordinates
 : @param $node search resuls with coords
:)
declare function search:build-geojson($node as node()*, $model as map(*)){
let $geo-hits := $model("hits")//tei:geo
return
    if(count($geo-hits) gt 1) then
         (
         geo:build-map($geo-hits, '', ''),
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>,
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>)
    else ()         
};

(:~
 : Calls advanced search forms from sub-collection search modules
 : @param $collection
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*), $collection as xs:string?) {   
    if(exists(request:get-parameter-names())) then ''
    else <div>{places:search-form()}</div>
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="well" style="background-color:white;">
<div>{search:build-geojson($node,$model)}</div>
{
    for $hit at $p in subsequence($model("hits"), $search:start, 20)
    return
        <div class="row" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="col-md-10 col-md-offset-1">
                <div class="result">
                  <div class="col-md-1" style="margin-right:-1em;">
                    <span class="label label-default">{$search:start + $p - 1}</span>
                  </div>
                  <div class="col-md-9" xml:lang="en"> 
                    {common:display-recs-short-view($hit,'')} 
                  </div>
                </div>
            </div>
        </div>
   }
</div>
};

(:~
 : Checks to see if there are any parameters in the URL, if yes, runs search, if no displays search form. 
:)
declare %templates:wrap function search:build-page($node as node()*, $model as map(*), $collection as xs:string?) {
    if(exists(request:get-parameter-names())) then search:show-hits($node, $model, $collection)
    else ()
};
