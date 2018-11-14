(:~   
 : Builds place page and place page functions
 :)
xquery version "3.0";

module namespace place="http://syriaca.org/srophe/place";
import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "lib/global.xqm";
import module namespace app="http://syriaca.org/srophe/templates" at "app.xql";
import module namespace maps="http://syriaca.org/srophe/maps" at "lib/maps.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;

declare namespace http="http://expath.org/ns/http-client";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace transform="http://exist-db.org/xquery/transform";

(:~   
 : Parameters passed from the url 
 :)
declare variable $place:id {request:get-parameter('id', '')};
declare variable $place:status {request:get-parameter('status', '')};

(:
 : Pass necessary elements to h1 xslt template
:)
declare %templates:wrap function place:h1($node as node(), $model as map(*)){
    let $title := $model("hits")//tei:place
    let $title-nodes := 
            <srophe-title xmlns="http://www.tei-c.org/ns/1.0">
                {($title//tei:placeName[@syriaca-tags='#syriaca-headword'],$title/descendant::tei:idno, $title/descendant::tei:location)}
            </srophe-title>
    return global:tei2html($title-nodes)
};

declare %templates:wrap function place:abstract($node as node(), $model as map(*)){
    let $abstract := $model("hits")//tei:place/tei:desc[starts-with(@xml:id,'abstract')]
    let $abstract-nodes := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {$abstract}
    </place>
    return global:tei2html($abstract)
};

declare function place:type-details($data, $type){
<div class="clearfix" xmlns="http://www.w3.org/1999/xhtml">
    <div id="type">
        <p><strong>Place Type: </strong>
            <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a>
        </p>
    </div>
    {
    if($data//tei:location) then
        <div id="location" xmlns="http://www.w3.org/1999/xhtml">
            <h4>Location</h4>
            <ul>
            {
                for $location in $data//tei:location
                return global:tei2html($location)
            }
            </ul>
        </div>
    else ()
    }
</div>
};

(:~
 : Add map and location information
:)
declare %templates:wrap function place:location-details($node as node(), $model as map(*)){
let $data := $model("hits")
let $type := string($model("hits")//tei:place/@type)
let $geo := $data//tei:geo[1]
return 
    if($data//tei:geo) then 
        <div class="row" xmlns="http://www.w3.org/1999/xhtml">
            <div class="col-md-7">
                {maps:build-map($data,0)}
            </div>
            <div class="col-md-5">
                {place:type-details($data, $type)}
            </div>    
        </div>
    else place:type-details($data, $type)
};

(:~
 : Add descriptions information 
:)
declare %templates:wrap function place:body($node as node(), $model as map(*)){
    let $ref-id := concat($config:base-uri,'/place/',$place:id)
    let $desc-nodes := $model("hits")/descendant::tei:place/tei:desc[not(starts-with(@xml:id,'abstract'))]
    let $notes-nodes := $model("hits")/descendant::tei:place/tei:note
    let $events-nodes := $model("hits")/descendant::tei:place/tei:event
    let $nested-loc := 
            for $nested-loc in collection($config:data-root || "/places/tei")/descendant::tei:location[@type="nested"]/tei:*[@ref=$ref-id]
            let $parent-name := $nested-loc/descendant::tei:placeName[1]
            let $place-id := substring-after($nested-loc/ancestor::*/tei:place[1]/@xml:id,'place-')
            let $place-type := $nested-loc/ancestor::*/tei:place[1]/@type
            return 
                <nested-place id="{$place-id}" type="{$place-type}">
                    {$nested-loc/ancestor::*/tei:placeName[1]}
                </nested-place>
    let $confessions := 
            if($model("hits")/descendant::tei:state[@type='confession']) then 
                let $confessions := doc($config:app-root || "/documentation/confessions.xml")//tei:list
                return 
                <confessions xmlns="http://www.tei-c.org/ns/1.0">
                   {(
                    $confessions,
                    for $event in $model("hits")/descendant::tei:event
                    return $event,
                    for $state in $model("hits")/descendant::tei:state[@type='confession']
                    return $state)}
                </confessions>
            else () 
    return 
        global:tei2html(<place xmlns="http://www.tei-c.org/ns/1.0">
            {($desc-nodes, $nested-loc, $events-nodes, $confessions, $notes-nodes)}
        </place>)
};

(:~
 : Get related place names      
 : ex: <relation name="contained" active="http://syriaca.org/place/145 http://syriaca.org/place/166" passive="#place-78" source="#bib78-1" to="0363"/>
:)
declare function place:related-places($node as node(), $model as map(*)){
 let $rec := $model("hits")
 return 
    global:tei2html(
    <place xmlns="http://www.tei-c.org/ns/1.0">
        <div id="heading">{$model("hits")//tei:place/tei:placeName[1]}</div>
        <tei:related-places>
                {
                    for $related in $rec//tei:relation
                    let $active := 
                        for $rel-item in tokenize($related/@active,' ')
                        let $item-id := tokenize($rel-item, '/')[last()]
                        let $item-uri := $rel-item
                        let $place-id := concat('place-',$item-id)
                        return
                            if(starts-with($item-id,'#')) then ()
                            else
                                <relation id="{$item-id}" uri="{$item-uri}" varient="active">
                                {
                                    (for $att in $related/@*
                                        return
                                             attribute {name($att)} {$att},                      
                                    for $get-related in collection($config:data-root || "/places/tei")/id($place-id)
                                    return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                                }
                                </relation>
                            
                    let $passive := 
                        for $rel-item in tokenize($related/@passive,' ')
                        let $item-id := tokenize($rel-item, '/')[last()]
                        let $item-uri := $rel-item
                        let $place-id := concat('place-',$item-id)
                        return
                            if(starts-with($item-id,'#')) then ()
                            else
                            <relation id="{$item-id}" uri="{$item-uri}" varient="passive">
                            {
                                (for $att in $related/@*
                                    return
                                         attribute {name($att)} {$att},                      
                                for $get-related in collection($config:data-root || "/places/tei")/id($place-id)
                                return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                            }
                            </relation>
                    let $mutual := 
                            if($related/@mutual) then
                            let $mutual-string := normalize-space($related/@mutual)
                            return
                                <relation varient="mutual">
                                    {
                                        for $rel-item in tokenize($mutual-string,' ')
                                        let $item-id := tokenize($rel-item, '/')[last()]
                                        let $item-uri := $rel-item
                                        let $place-id := concat('place-',$item-id)
                                        return
                                            <mutual id="{$item-id}">{
                                            (for $att in $related/@*
                                            return
                                                 attribute {name($att)} {$att},                      
                                            for $get-related in collection($config:data-root || "/places/tei")/id($place-id)
                                            let $type := string($get-related/@type)
                                            return 
                                                (attribute type {$type}, $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']))
                                            }
                                            </mutual>
                                    }
                                </relation>
                              else ''  
        
                    return ($active,$passive,$mutual)
                }
        </tei:related-places>
    </place>)
};

(:
 : Return bibls for use in sources 
:)
declare %templates:wrap function place:sources($node as node(), $model as map(*)){
    let $rec := $model("hits")
    let $sources := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
        {$rec//tei:place/tei:bibl}
    </place>
    return global:tei2html($sources)
};

(:
 : Return place names
:)
declare %templates:wrap function place:place-name($node as node(), $model as map(*)){
    let $names := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
            {$model("hits")//tei:place/tei:placeName}
    </place>
    return global:tei2html($names)
};

(:
 : Return tieHeader info to be used in citation
:)
declare %templates:wrap function place:citation($node as node(), $model as map(*)){
    let $rec := $model("hits")
    let $header := 
    <place xmlns="http://www.tei-c.org/ns/1.0">
        <citation xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader | $rec//tei:bibl}
        </citation> 
    </place>
    return global:tei2html($header)
};

(:~
 : Prints link icons on left
:)
declare %templates:wrap function place:link-icons-list($node as node(), $model as map(*)){
let $data := $model("hits")
let $links:=
    <place xmlns="http://www.tei-c.org/ns/1.0">
        <see-also title="{substring-before($data//tei:teiHeader/descendant::tei:titleStmt/tei:title[1],'-')}" xmlns="http://www.tei-c.org/ns/1.0">
            {$data/descendant::tei:place/descendant::tei:idno, $data/descendant::tei:place/descendant::tei:location}
        </see-also>
    </place>
return global:tei2html($links)
};
