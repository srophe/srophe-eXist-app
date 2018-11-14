(:~           
 : Builds persons page and persons page functions  
 :)
xquery version "3.0";

module namespace person="http://syriaca.org/srophe/person";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "lib/global.xqm";
import module namespace app="http://syriaca.org/srophe/templates" at "app.xql";
import module namespace maps="http://syriaca.org/srophe/maps" at "lib/maps.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "lib/data.xqm";
import module namespace rel="http://syriaca.org/srophe/related" at "lib/get-related.xqm";
import module namespace timeline="http://syriaca.org/srophe/timeline" at "lib/timeline.xqm";
import module namespace tei2html="http://syriaca.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";

declare namespace http="http://expath.org/ns/http-client";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace schema = "http://schema.org/";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
(:~ 
 : Parameters passed from the url  
 :)
declare variable $person:id {request:get-parameter('id', '')};
declare variable $person:works-view {request:get-parameter('works-view', '')};
declare variable $person:work-start {request:get-parameter('work-start', 1)};
declare variable $person:work-count {request:get-parameter('work-count', 20)};

(:
 : Pass necessary elements to h1 xslt template     
:)      
declare %templates:wrap function person:h1($node as node(), $model as map(*)){
    let $title-nodes := 
            <srophe-title xmlns="http://www.tei-c.org/ns/1.0">
                {(
                    $model("hits")//tei:persName[@syriaca-tags],
                    $model("hits")//tei:seriesStmt,
                    $model("hits")//tei:person/descendant::tei:birth,
                    $model("hits")//tei:person/descendant::tei:death,
                    $model("hits")//tei:person/descendant::tei:floruit,
                    $model("hits")/descendant::tei:teiHeader
                )}
            </srophe-title>
    return global:tei2html($title-nodes)
};

declare %templates:wrap function person:names($node as node(), $model as map(*)){
try {
    let $names := $model("hits")//tei:person/tei:persName
    let $abstract := $model("hits")//tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')] | $model("hits")//tei:note[@type='abstract']
    let $sex := $model("hits")//tei:sex
    let $martyr := $model("hits")//tei:state
    let $nodes := 
        (<person xmlns="http://www.tei-c.org/ns/1.0">
            {(
                $names,
                $abstract,
                $martyr,
                $sex
            )}
        </person>)
    return global:tei2html($nodes)
   } catch * { <error>No Data {$err:code}: {$err:description}</error>}
   
};

declare %templates:wrap function person:desc($node as node(), $model as map(*)){
try {    
    let $desc := $model("hits")//tei:note[@type="description"]
    let $nodes := 
        (<person xmlns="http://www.tei-c.org/ns/1.0">
            {$desc}
        </person>)
    return global:tei2html($nodes)
   } catch * { <error>No Data {$err:code}: {$err:description}</error>}
   
};

declare %templates:wrap function person:data($node as node(), $model as map(*)){
    try {
     let $rec := $model("hits")//tei:person
     let $nodes := 
         <person xmlns="http://www.tei-c.org/ns/1.0" ana="{$rec/@ana/text()}">
                 {
                     for $data in $rec/child::*[not(self::tei:persName)][not(self::tei:bibl)]
                     [not(self::*[@type='abstract' or starts-with(@xml:id, 'abstract-en')])]
                     [not(self::tei:state)][not(self::tei:sex)][not(self::tei:note[@type="description"])]
                     return $data
                 }
         </person>
     return global:tei2html($nodes)        
    } catch * { <error>No Data {$err:code}: {$err:description}</error>}
};
    
declare %templates:wrap function person:timeline($node as node(), $model as map(*), $dates){
let $data := $model("hits")
return
    if($dates = 'personal') then 
        if($data//tei:birth[@when or @notBefore or @notAfter] or 
        $data//tei:death[@when or @notBefore or @notAfter] or 
        $data//tei:state[@when or @notBefore or @notAfter or @to or @from] or 
        $data//tei:floruit[@when or @notBefore or @notAfter or @to or @from] or $data//tei:date[@when or @notBefore or @notAfter or @to or @from]) then
                <div>                
                    <div>{timeline:timeline($data, 'Events Timeline')}</div>
                    <div class="indent">
                            <h4>Dates</h4>
                            <ul class="list-unstyled">
                                {
                                 for $date in $data//tei:birth[@when or @notBefore or @notAfter] | $data//tei:birth[tei:date[@when or @notBefore or @notAfter]] |
                                 $data//tei:death[@when or @notBefore or @notAfter] | $data//tei:death[tei:date[@when or @notBefore or @notAfter]] |
                                 $data//tei:state[@when or @notBefore or @notAfter or @to or @from] | $data//tei:state[tei:date[@when or @notBefore or @notAfter]] |
                                 $data//tei:floruit[@when or @notBefore or @notAfter or @to or @from] | $data//tei:floruit[tei:date[@when or @notBefore or @notAfter]] 
                                 return 
                                    <li>{global:tei2html($date)}</li>
                                }
                            </ul> 
                       </div>     
                    </div>
        else ()
     else if($dates = 'events') then
        <div class="timeline">
            <h3>Events</h3>
            <div>{timeline:timeline($data//tei:event, 'Events Timeline')}</div>
        </div>
     else ()
};

declare %templates:wrap function person:related-places($node as node(), $model as map(*)){
let $data := $model("hits")
let $geo-hits := person:get-related($data)
let $places-count := count(tokenize(string-join(($data//tei:relation/@passive),' '),' ')[contains(.,'/place/')])
return 
    if($geo-hits//tei:geo) then
        <div><hr/>
            <h2>Related Places in the Syriac Gazetteer</h2>
            {maps:build-map($geo-hits,$places-count)}
            {global:tei2html(
                <person xmlns="http://www.tei-c.org/ns/1.0">
                    <related-items xmlns="http://www.tei-c.org/ns/1.0">
                        {
                            for $r in $data//tei:relation
                            let $uris := $r/@passive
                            let $desc := $r/tei:desc
                            for $rel-rec in tokenize($uris,' ')
                            return
                                <relation uri="{$rel-rec}" xmlns="http://www.tei-c.org/ns/1.0">
                                    {(for $att in $r/@*
                                      return attribute {name($att)} {$att},
                                      let $rec := collection($config:data-root)//tei:idno[. = $rel-rec] 
                                      let $title := 
                                        if($rec/ancestor::tei:place) then 
                                            <place xml:id="{$rec/ancestor::tei:place/@xml:id}" type="{$rec/ancestor::tei:place/@type}" xmlns="http://www.tei-c.org/ns/1.0">
                                                {($rec/ancestor::tei:place/tei:placeName[@syriaca-tags="#syriaca-headword"][1])}
                                            </place>
                                        else $rec/ancestor::tei:TEI/descendant::*[@syriaca-tags="#syriaca-headword"][1]
                                      return 
                                        <item uri="{$rel-rec}" xmlns="http://www.tei-c.org/ns/1.0">
                                            {$title}
                                        </item> 
                                       ,
                                       $desc
                                   )}
                                </relation>   
                        }
                    </related-items>
                </person>)
            }  
        </div>
    else ()
    
};

(:~
 : Get related items 
 : NOTE should be able to pass related items in as string?
:)  
declare function person:get-related($rec as node()*){
for $related in $rec//tei:relation
let $uris := string($related/@passive)
for $item-uri in tokenize($uris,' ')
let $rec := collection($config:data-root)//tei:idno[. = $item-uri]
let $geo := if($rec/ancestor::tei:TEI//tei:geo) then $rec/ancestor::tei:TEI//tei:geo
                else ()
let $title := string(root($rec)/descendant::*[@syriaca-tags="#syriaca-headword"][1])
let $type := if(root($rec)/descendant::tei:place/@type) then concat(' - ', string($rec/ancestor::tei:TEI/descendant::tei:place/@type)) else ()
let $desc := string($related/tei:desc)
return 
      <place xmlns="http://www.tei-c.org/ns/1.0">
        <idno>{$item-uri}</idno>
        <title>{concat($title,$type)}</title>
        <relationType>{if(string($related/@name) != '') then string($related/@name) else string($related/@ref)}</relationType>
        <desc>{$desc}</desc>
        <location>{$geo}</location>  
      </place>
                  
};

(:
 : Use OCLC API to return VIAF records 
 : limit to first 5 results
 : @param $rec
 : NOTE param should just be tei:idno as string
:)
declare %templates:wrap function person:worldcat($node as node(), $model as map(*)){
let $rec := $model("hits")
return 
    try {
        if($rec/descendant::tei:idno[starts-with(.,'http://worldcat.org/identities/lccn-n')] or $rec/descendant::tei:idno[starts-with(.,'http://viaf.org/viaf')][not(contains(.,'sourceID'))]) then
            let $viaf-ref := if($rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')]) then 
                                        $rec/descendant::tei:idno[@type='URI'][contains(.,'http://worldcat.org/identities/lccn-n')][1]/text()
                                     else $rec/descendant::tei:idno[@type='URI'][not(contains(.,'sourceID/SRP')) and starts-with(.,'http://viaf.org/viaf')][1]
            let $uri := if(starts-with($viaf-ref,'http://viaf.org/viaf')) then 
                                    let $rdf := http:send-request(<http:request href="{concat($viaf-ref,'/rdf.xml')}" method="get"/>)[2]//schema:sameAs/child::*/@rdf:about[starts-with(.,'http://id.loc.gov/')]
                                    let $lcc := tokenize($rdf,'/')[last()]
                                    return concat('http://worldcat.org/identities/lccn-',$lcc)
                                else $viaf-ref
            let $build-request :=  <http:request href="{$uri}" method="get"/>
            return 
                if($uri != '') then 
                    try {
                        let $results :=  http:send-request($build-request)//by 
                        let $total-works := string($results/ancestor::Identity//nameInfo/workCount)
                        return 
                            if(not(empty($results)) and  $total-works != '0') then 
                                    <div id="worldcat-refs" class="well">
                                        <h3>{$total-works} Catalog Search Results from WorldCat</h3>
                                        <p class="hint">Based on VIAF ID. May contain inaccuracies. Not curated by Syriaca.org.</p>
                                        <div>
                                             <ul id="{$viaf-ref}" count="{$total-works}">
                                                {
                                                    for $citation in $results/citation[position() lt 5]
                                                    return
                                                        <li><a href="{concat('http://www.worldcat.org/oclc/',substring-after($citation/oclcnum/text(),'ocn'))}">{$citation/title/text()}</a></li>
                                                 }
                                             </ul>
                                             <span class="pull-right"><a href="{$uri}">See all {$total-works} titles from WorldCat</a></span>,<br/>
                                        </div>
                                    </div>    
                                             
                            else ()
                    } catch * {
                        <error>Caught error {$err:code}: {$err:description}</error>
                    } 
                 else ()   
        else ()
    } catch * {
        <error>Caught error {$err:code}: {$err:description}</error>
    } 
};

(: 
 : Get relations for right side menu 
 : Use get-related module.
 : NOTE need to untangle get-related and get-related places. 
:)
declare %templates:wrap function person:relations($node as node(), $model as map(*)){
if($model("hits")/descendant::tei:relation) then 
    let $idno := replace($model("hits")/descendant::tei:idno[@type='URI'][starts-with(.,$config:base-uri)][1]/text(),'/tei','')
    return rel:build-relationships($model("hits")//tei:relation, $idno,(),'list-description', ())
else ()
};

declare %templates:wrap function person:authored-by($node as node(), $model as map(*)){
let $rec := $model("hits")
let $recid := replace($rec/descendant::tei:idno[@type='URI'][starts-with(.,$config:base-uri)][1]/text(),'/tei','')
let $works := collection($config:data-root || '/works/tei')//tei:author[@ref =  $recid]  
let $count := count($works)
return 
    if($count gt 0) then 
        <div xmlns="http://www.w3.org/1999/xhtml">
            <h3>Works by {substring-before($rec/descendant::tei:title[1],' — ')} in the New Handbook of Syriac Literature</h3>
            {(
                if($rec/descendant::tei:note[@type='authorship']) then
                    global:tei2html($rec/descendant::tei:note[@type='authorship'])
                else (),
                if($count gt 3) then
                        <div>
                         {
                             for $r in subsequence($works, 1, 3)
                             let $workid := replace($r/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][starts-with(.,$config:base-uri)][1],'/tei','')
                             let $rec :=  data:get-document($workid)
                             return tei2html:summary-view($rec, (), $workid[1])
                         }
                            <div>
                            <a href="{$config:nav-base}/bhse/search.html?author={$recid}&amp;sort-element=title" class="btn btn-info" style="width:100%; margin-bottom:1em;" >
                              See all {count($works)} works
                             </a>
                            </div>
                         </div>    
                else 
                    for $r in $works
                    let $workid := replace($r/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][starts-with(.,$config:base-uri)][1],'/tei','')
                    let $rec :=  data:get-document($workid)
                    return tei2html:summary-view($rec, (), $workid[1])
            )}
            <hr/>
        </div>
    else ()     
};

(:
 : Return bibls for use in sources
:)
declare %templates:wrap function person:sources($node as node(), $model as map(*)){
    let $rec := $model("hits")
    let $sources := 
    <person xmlns="http://www.tei-c.org/ns/1.0">
        {$rec//tei:person/tei:bibl}
    </person>
    return global:tei2html($sources)
};

(: 
 : Return tieHeader info to be used in citation
:)
declare %templates:wrap function person:citation($node as node(), $model as map(*)){
    let $rec := $model("hits")
    let $header := 
    <person xmlns="http://www.tei-c.org/ns/1.0">
        <citation xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader | $rec//tei:bibl}
        </citation> 
    </person>
    return global:tei2html($header)
};

(:~
 : Build links
:)
declare %templates:wrap function person:link-icons-list($node as node(), $model as map(*)){
let $data := $model("hits")
let $links:=
    <person xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data//tei:person/descendant::tei:idno, $data//tei:person/descendant::tei:location}
        </see-also>
    </person>
return global:tei2html($links)
};

(:
 : Map for persons index page. 
 : All persons with relationships to places.
:)
declare %templates:wrap function person:display-persons-map($node as node(), $model as map(*)){
    let $persons := 
    for $p in collection($config:data-root || '/persons/tei')//tei:relation[contains(@passive,'/place/') or contains(@active,'/place/') or contains(@mutual,'/place/')]
    let $name := string($p/ancestor::tei:TEI/descendant::tei:title[1])
    let $pers-id := string($p/ancestor::tei:TEI/descendant::tei:idno[1])
    let $relation := string($p/@name)
    let $places := for $p in tokenize(string-join(($p/@passive,$p/@active,$p/@mutual),' '),' ')[contains(.,'/place/')] return <placeName xmlns="http://www.tei-c.org/ns/1.0">{$p}</placeName>
                    return 
                        <person xmlns="http://www.tei-c.org/ns/1.0">
                            <persName xmlns="http://www.tei-c.org/ns/1.0" name="{$relation}" id="{replace($pers-id,'/tei','')}">{$name}</persName>
                            {$places}
                        </person>
    let $places := distinct-values($persons/descendant::tei:placeName/text()) 
    let $locations := 
        for $id in $places
        for $geo in collection($config:data-root || '/places/tei')//tei:idno[. = $id][ancestor::tei:TEI[descendant::tei:geo]]
        let $title := $geo/ancestor::tei:TEI/descendant::*[@syriaca-tags="#syriaca-headword"][1]
        let $type := string($geo/ancestor::tei:TEI/descendant::tei:place/@type)
        let $geo := $geo/ancestor::tei:TEI/descendant::tei:geo
        return 
            <place xmlns="http://www.tei-c.org/ns/1.0">
                <idno>{$id}</idno>
                <title>{concat(normalize-space($title), ' - ', $type)}</title>
                <desc>Related Persons:
                {
                    for $p in $persons[child::tei:placeName[. = $id]]/tei:persName
                    return concat('<br/><a href="',string($p/@id),'">',normalize-space($p),'</a>')
                }
                </desc>
                <location>{$geo}</location>  
            </place>
    return  maps:build-map($locations,count($places))
};