(:~
 : Builds persons page and persons page functions
 :)
xquery version "3.0";

module namespace ev="http://syriaca.org/events";

import module namespace templates="http://exist-db.org/xquery/templates" ;

import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "timeline.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $ev:id {request:get-parameter('id', '')}; 
declare variable $ev:view {request:get-parameter('view', 'place')};
declare variable $ev:date {request:get-parameter('date', '')};
declare variable $ev:fq {request:get-parameter('fq', '')};
declare variable $ev:sort {request:get-parameter('sort', 'all') cast as xs:string};
declare variable $ev:item-type {request:get-parameter('item-type', 'all') cast as xs:string};

declare function ev:display-recs-short-view($node,$lang){
  transform:transform($node, doc($global:app-root || '/resources/xsl/rec-short-view.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
        <param name="lang" value="en"/>
        <param name="spear" value="true"/>
    </parameters>
    )
};

(:~ 
 : Include timeline and events list view in xql to adjust for event/person/place view
:)
declare function ev:build-timeline($nodes as node()*, $dates){
let $data := $nodes
return
     if($dates = 'personal') then 
         if($data//tei:birth[@when or @notBefore or @notAfter] or $data//death[@when or @notBefore or @notAfter] or $data//tei:state[@when or @notBefore or @notAfter or @to or @from]) then
                 <div class="row">
                         <div class="col-md-9">
                             <div class="timeline">
                                 <div>{timeline:timeline($data, 'Events Timeline')}</div>
                             </div>
                         </div>
                         <div class="col-md-3">
                             <h4>Dates</h4>
                             <ul class="list-unstyled">
                                 {
                                  for $date in $data//tei:birth[@when] | $data//tei:birth[@notBefore] | $data//tei:birth[@notAfter] 
                                  | $data//tei:death[@when] |$data//tei:death[@notBefore] |$data//tei:death[@notAfter]| 
                                  $data//tei:floruit[@when] | $data//tei:floruit[@notBefore]| $data//tei:floruit[@notAfter] 
                                  | $data//tei:state[@when] | $data//tei:state[@notBefore] | $data//tei:state[@notAfter] | $data//tei:state[@from] | $data//tei:state[@to]
                                  return 
                                     <li>{ev:display-recs-short-view($date,'')}</li>
                                 }
                             </ul>
                         </div>
                     </div>
         else ()
      else if($dates = 'events') then
         <div class="timeline">
             <div>{timeline:timeline($data, 'Events Timeline')}</div>
         </div>
      else ()  
};

declare function ev:build-events-panel($nodes as node()*){
<div class="panel panel-default">
    <div class="panel-heading clearfix">
        <h4 class="panel-title pull-left" style="padding-top: 7.5px;">
        {if($ev:view='event') then 'Events' else if($ev:id !='') then 'Events' else 'All Factoids'}
        </h4>
        <!-- Sort options for events list -->
        <div class="btn-group pull-right">
            <div class="dropdown"><button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">Sort<span class="caret"/></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                    <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="manuscript">Textual</a></li>
                    <li role="presentation"><a role="menuitem" tabindex="-1" href="#" id="date">Chronological</a></li>
                </ul>
            </div>
        </div>
    </div>
    <div class="panel-body">
        {ev:events($nodes)}
    </div>
</div>
};

declare function ev:events($nodes as node()*){
<div id="events-list">
    {
    let $data := $nodes
    return
    if($ev:sort = 'manuscript') then
       <ul>
        {
            for $e in $data
            return <li class="md-line-height">{global:tei2html($e)} {<a href="factoid.html?id={string($e/@uri)}">See factoid page  <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"></span></a>}</li>
         }
        </ul>
    else
        <ul>
        {
            for $event in $data
            let $date := substring($event/descendant-or-self::tei:date[1]/@syriaca-computed-start,1,2)
            group by $date
            order by $date ascending
            return
            <li>
                <h4>
                {
                    if(starts-with($date,'-')) then 'BC Dates'
                    else if($date != '') then concat(substring-after($date,'0'),'00') 
                    else 'Date Unknown'
                }
                </h4>
                <ul>
                    {
                        for $e in $event
                        return 
                            <li class="md-line-height">
                                {global:tei2html($e/tei:listEvent/descendant::tei:event)}&#160; 
                                {<a href="factoid.html?id={string($e/@uri)}">See factoid page  <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"></span></a>   }
                            </li>
                    }
                </ul>
            </li>
         }
         </ul>

    }
</div>
};

