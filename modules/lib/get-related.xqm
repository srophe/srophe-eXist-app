xquery version "3.0";
(: Build relationships. :)
module namespace rel="http://syriaca.org/related";
import module namespace page="http://syriaca.org/page" at "paging.xqm";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace data="http://syriaca.org/data" at "data.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "tei2html.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


(:~ 
 : Get names/titles for each uri
 : @param $uris passed as string, can contain multiple uris
 : @param $idno for parent record, can be blank. Used to filter current record from results list. 
 :)
declare function rel:get-uris($uris as xs:string*, $idno) as xs:string*{
    for $uri in distinct-values(tokenize($uris,' '))
    where ($uri != $idno and not(starts-with($uri,'#')))  
    return $uri
};

(:~
 : Use XSLT to build short record view to display related records
 : @param $uri uri of record to display.  
:)
declare function rel:display($uri as xs:string*) as element(a)*{
    let $rec :=  data:get-rec($uri)  
    return tei2html:summary-view($rec, '', $uri)
};

(:~
 : @depreciated use SPARQL instead
 : Get related record names
:)
declare function rel:get-names($uris as xs:string?) {
    let $count := count(tokenize($uris,' '))
    for $uri at $i in tokenize($uris,' ')
    let $rec :=  data:get-rec($uri)
    let $name := 
                if(not(exists(data:get-rec($uri)))) then $uri
                else if(contains($uris,'/spear/')) then
                    let $string := normalize-space(string-join($rec/child::*/child::*[not(self::tei:bibl)]/descendant::text(),' '))
                    let $last-words := tokenize($string, '\W+')[position() = 5]
                    return $string (:concat(substring-before($string, $last-words),'...'):)
                else substring-before($rec[1]/descendant::tei:titleStmt[1]/tei:title[1]/text()[1],' — ')
    return
        (
        if($i gt 1 and $count gt 2) then  
            ', '
        else if($i = $count and $count gt 1) then  
            ' and '
        else (),
        normalize-space($name)
        )
};

(:~ 
 : Get names/titles for each uri, for json output
 : @param $uris passed as string, can contain multiple uris
 :)
declare function rel:get-names-json($uris as xs:string?) as node()*{
    for $uri in tokenize($uris,' ')
    let $rec :=  data:get-rec($uri)
    let $name := 
                if(contains($uris,'/spear/')) then
                    let $string := normalize-space(string-join($rec/descendant::text(),' '))
                    let $last-words := tokenize($string, '\W+')[position() = 5]
                    return concat(substring-before($string, $last-words),'...')
                else substring-before($rec/descendant::tei:titleStmt[1]/tei:title[1]/text()[1],'—')
    return <name>{normalize-space($name)}</name>     
};

(:~ 
 : Describe relationship using tei:description or @name
 : @param $related relationship element 
 :)
declare function rel:decode-relationship($related as node()*){ 
    let $name := $related/@name | $related/@ref
    for $name in $name[1]
    let $subject-type := rel:get-subject-type($related/@passive)
    let $label := global:odd2text(name($related[1]),string($name))
    return 
            if($label != '') then 
                $label
            else 
                if($name = 'dcterms:subject') then 
                    concat($subject-type, ' highlighted: ')
                else if($name = 'syriaca:commemorated') then
                    concat($subject-type,' commemorated:  ')    
                else  
                string-join(
                    for $w in tokenize($name,' ')
                    return functx:capitalize-first(substring-after(functx:camel-case-to-words($w,' '),':')),' ')
};

(:~ 
 : Subject type, based on uri of @passive uris
 : @param 'passive' $relationship attribute
:)
declare function rel:get-subject-type($rel as xs:string*) as xs:string*{
    if(contains($rel, ' ')) then
        if(count(distinct-values(for $r in tokenize(string($rel),'/')[4] return $r)) gt 1) then 
            'records'
        else if(contains($rel,'subject')) then 
            'keywords'
        else concat(tokenize(string($rel[1]),'/')[4],'s')
    else
        if(contains($rel,'subject')) then 
            'keywords'
        else tokenize(string($rel[1]),'/')[4]
};

(:~ 
 : Get 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:get-cited($idno){
let $data := 
    for $r in collection($global:data-root)//tei:body[.//@target[. = replace($idno[1],'/tei','')]]
    let $headword := replace($r/ancestor::tei:TEI/descendant::tei:title[1]/text()[1],' — ','')
    let $id := $r/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][1]
    let $sort := global:build-sort-string($headword,'')
    where $sort != ''
    order by $sort
    return concat($id, 'headword:=', $headword)
return  map { "cited" := $data}    
};

(:~ 
 : HTML display of 'cited by' relationships. Used in bibl module. 
 : @param $idno bibl idno
:)
declare function rel:cited($idno, $start, $perpage){
    let $perpage := if($perpage) then $perpage else 5
    let $current-id := replace($idno[1]/text(),'/tei','')
    let $hits := rel:get-cited($current-id)?cited
    let $count := count($hits)
    return
        if(exists($hits)) then 
            <div class="well relation">
                <h4>Cited in:</h4>
                <span class="caveat">{$count} record(s) cite this work.</span> 
                {
                    if($count gt 5) then
                        for $rec in subsequence($hits,$start,$perpage)
                        let $id := substring-before($rec,'headword:=')
                        return 
                            tei2html:summary-view(collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI, '', $id)                        
                    else 
                        for $rec in $hits
                        let $id := substring-before($rec,'headword:=')
                        return 
                            tei2html:summary-view(collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI, '', $id)
                }
                { 
                     if($count gt 5) then
                        <div>
                            <a href="#" class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="modal" data-target="#moreInfo" 
                            data-ref="../search.html?bibl={$current-id}&amp;perpage={$count}&amp;sort=alpha" 
                            data-label="See all {$count} results" id="moreInfoBtn">
                              See all {$count} results
                             </a>
                        </div>
                     else ()
                 }
            </div>
        else ()
        
};

(:
 : HTML display of 'subject headings' using 'cited by' relationships
 : @param $idno bibl idno
:)
declare function rel:subject-headings($idno){
    let $hits := rel:get-cited(replace($idno[1]/text(),'/tei',''))?cited
    let $total := count($hits)
    return 
        if(exists($hits)) then
            <div class="well relation">
                <h4>Subject Headings:</h4>
                {
                    (
                    for $recs in subsequence($hits,1,20)
                    let $headword := substring-after($recs,'headword:=')
                    let $id := replace(substring-before($recs,'headword:='),'/tei','')
                    return 
                            <span class="sh pers-label badge">{replace($headword,' — ','')} 
                            <a href="search.html?subject={$id}" class="sh-search">
                            <span class="glyphicon glyphicon-search" aria-hidden="true"></span>
                            </a></span>
                            ,
                       if($total gt 20) then
                        (<div class="collapse" id="showAllSH">
                            {
                            for $recs in subsequence($hits,20,$total)
                            let $headword := substring-after($recs,'headword:=')
                            let $id := replace(substring-before($recs,'headword:='),'/tei','')
                            return 
                               <span class="sh pers-label badge">{replace($headword,' — ',' ')} 
                               <a href="search.html?subject={$id}" class="sh-search"> 
                               <span class="glyphicon glyphicon-search" aria-hidden="true">
                               </span></a></span>
                            }
                        </div>,
                        <a class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showAllSH" data-text-swap="Hide"> <span class="glyphicon glyphicon-plus" aria-hidden="true"></span> Show All </a>
                        )
                    else ()
                    )
                }
            </div>
        else ()
};

(:~ 
 : Main div for HTML display 
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-relationships($node,$idno){ 
<div class="panel panel-default">
    <div class="panel-heading"><h3 class="panel-title">Relationships </h3></div>
    <div class="panel-body">
    {       
        for $related in $node/descendant-or-self::tei:relation
        let $rel-id := index-of($node, $related[1])
        let $rel-type := if($related/@ref) then $related/@ref else $related/@name
        group by $relationship := $rel-type
        return
            let $names := rel:get-uris(string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' '),$idno)
            let $count := count($names)
            return 
                (<p class="rel-label"> 
                    {
                     if(contains($idno,'/subject/') and $relationship = 'skos:broadMatch') then
                        concat('This keyword has broader match with', $count,' keyword',if($count gt 1) then 's' else())
                     else if($related/@mutual) then 
                        concat('This ', rel:get-subject-type($related[1]/@mutual), ' ', rel:decode-relationship($related[1]), ' ', $count, ' other ', rel:get-subject-type($related[1]/@mutual),'.')
                      else if($related/@active) then 
                        concat('This ', rel:get-subject-type($related[1]/@active), ' ',
                        rel:decode-relationship($related[1]), ' ',$count, ' ',rel:get-subject-type($related[1]/@passive),'.')
                      else rel:decode-relationship($related[1])
                    }
                </p>,
                <div class="rel-list">{
                    for $r in subsequence($names,1,2)
                    return rel:display($r),
                    if($count gt 2) then
                        <span>
                            <span class="collapse" id="showRel-{$rel-id}">{
                                for $r in subsequence($names,3,$count)
                                return rel:display($r)
                            }</span>
                            <a class="togglelink btn btn-info" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showRel-{$rel-id}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                        </span>
                    else ()
                    (:for $r in $names
                    return 
                    <div class="short-rec rel indent">{rel:display($r)}</div>
                    :)
                }</div>)
        }
    </div>
</div>
};

(:~ 
 : Build a single relationship type relation/@ref or @name
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-relationship($node,$idno, $relType){ 
for $related in $node/descendant-or-self::tei:relation[@name = $relType or @ref = $relType]
let $rel-id := index-of($node, $related[1])
let $names := rel:get-uris(string-join(($related/@active/string(),$related/@passive/string(),$related/@mutual/string()),' '),$idno)
let $count := count($names)
return 
    (<p class="rel-label">
        {
            if($related/@mutual) then 
                ('This ', rel:get-subject-type($related[1]/@mutual), ' ', rel:decode-relationship($related[1]), ' ', $count, ' other ', rel:get-subject-type($related[1]/@mutual),'.')
            else if($related/@active) then 
                ('This ', rel:get-subject-type($related[1]/@active), ' ',rel:decode-relationship($related[1]), ' ', $count, ' ', rel:get-subject-type($related[1]/@passive),'.')
            else rel:decode-relationship($related[1])
         }
      </p>,
      <div class="rel-list">{
        for $r in subsequence($names,1,2)
        return rel:display($r),
            if($count gt 2) then
                <span>
                    <span class="collapse" id="showRel-{$rel-id}">{
                        for $r in subsequence($names,3,$count)
                        return rel:display($r)
                    }</span>
                    <a class="togglelink btn btn-info" style="width:100%; margin-bottom:1em;" data-toggle="collapse" data-target="#showRel-{$rel-id}" data-text-swap="Hide"> See all {$count} &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
                </span>
            else ()
     }</div>)
};

(: Assumes active/passive SPEAR:)
declare function rel:decode-spear-relationship($relationship as xs:string?){
let $relationship-name := 
    if(contains($relationship,':')) then 
        substring-after($relationship,':')
    else $relationship
return 
    switch ($relationship-name)
        (: @ana = 'clerical':)
        case "Baptism" return " was baptized by "
        case "BishopOver" return " was under the authority of bishop "
        case "BishopOverBishop" return " was a bishop under the authority of bishop "
        case "BishopOverClergy" return " was a clergyperson under the authority of the bishop "
        case "BishopOverMonk" return " was a monk under the authority of the bishop "
        case "Ordination" return " was ordained by "
        case "ClergyFor" return " as a clergyperson " (: Full @passive had @active as a clergyperson.:)
        case "CarrierOfLetterBetween" return " exchanged a letter carried by "
        case "EpistolaryReferenceTo" return " was referenced in a letter between "
        case "LetterFrom" return " received a letter from "
        case "SenderOfLetterTo" return " received a letter from "
        (: @ana = 'family':)
        case "GreatGrandparentOf" return " had a great grandparent "
        case "AncestorOf" return " was the descendant of "
        case "ChildOf" return " was the parent of "
        case "SiblingOf" return " were siblings"
        case "ChildOfSiblingOf" return " was the sibling of a parent of "
        case "descendantOf" return " was the ancestor of "
        case "GrandchildOf" return " was the grandparent of "
        case "GrandparentOf" return " was the grandchild of "
        case "ParentOf" return " was the child of "
        case "SiblingOfParentOf" return " was a child of a sibling of "
        (: @ana = 'general' :)
        case "EnmityFor" return " was the object of the enmity of "
        case "MemberOfGroup" return " contained "
        case "Citation" return " was cited by "
        case "FollowerOf" return " had as a follower "
        case "StudentOf" return " had as a teacher "
        case "Judged" return " was judged by "
        case "LegalChargesAgainst" return " was the subject of a legal action brought by "
        case "Petitioned" return " received a petition or a request for legal action from "
        case "CommandOver" return " was under the command of "
        case "MonasticHeadOver" return " was under the monastic authority of "
        case "Commemoration" return " was commemorated by "  
        case "FreedSlaveOf" return " was released from slavery to "
        case "HouseSlaveOf" return " was held as a house slave "   
        case "SlaveOf" return " held as a slave "      
        (: @ana 'event' :)
        case "SameAs" return " refer to the same event. "
        case "CloseConnection" return " deal with closely related events."
        default return concat(' ', functx:camel-case-to-words($relationship-name,' '),' ') 
};

declare function rel:link($uris as xs:string*){
    let $count := count(tokenize($uris,' '))
    for $uri at $i in tokenize($uris,' ')
    return
        (
        if($i gt 1 and $count gt 2) then  ', '
        else if($i = $count and $count gt 1) then  ' and '
        else (), <a href="{$uri}">{$uri}</a>
        )
};

declare function rel:build-relationship-sentence($relationship,$uri){
(: Will have to add in some advanced prcessing that tests the current id (for aggrigate pages) and subs vocab for active/passive:)
if($relationship/@mutual) then
    (rel:link($relationship/@mutual), rel:decode-spear-relationship($relationship/@ref),'.')
else if($relationship/@active) then 
    (rel:link($relationship/@active), rel:decode-spear-relationship($relationship/@ref), rel:link($relationship/@passive),'.') 
else ()
};

(:~ 
 : Main div for HTML display for SPEAR relationships
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-short-relationships-list($node,$idno){ 
    let $count := count($node/descendant-or-self::tei:relation)
    return 
        for $related in $node/descendant-or-self::tei:relation
        let $uri := string($related/ancestor::tei:div[@uri][1]/@uri)
        return
            <span class="short-relationships">
               {(:rel:build-short-relationships($related,$uri):)rel:build-relationship-sentence($related,$uri)} 
                &#160;<a href="factoid.html?id={$uri}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/></a>
            </span>
};

(:~ 
 : Main div for HTML display SPEAR relationships
 : @param $node all relationship elements
 : @param $idno record idno
:)
declare function rel:build-short-relationships($node,$uri){ 
    <p>{rel:build-relationship-sentence($node,$uri)}</p>
};

(:~
 : Build external relationships, i.e, aggrigate all records which reference the current record, 
 : as opposed to rel:build-relationships which displays record information for records referenced in the current record.
 : @param $recID current record id 
 : @param $title current record title 
 : @param $relType relationship type
 : @param $collection current record collection
 : @param $sort sort on title or part number default to title
 : @param $count number of records to return, if empty defaults to 5 with a popup for more. 
:)
declare function rel:external-relationships($recid as xs:string, $title as xs:string?, $relType as xs:string*, $collection as xs:string?, $sort as xs:string?, $count as xs:string?){
let $related := 
    for $h in data:search(concat(data:build-collection-path($collection),data:relation-search($recid,$relType)))
    let $part := 
        if ($h/descendant::tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n castable as  xs:integer)
            then xs:integer($h/descendant::tei:listRelation/tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]]/tei:desc[1]/tei:label[@type='order'][1]/@n)
        else 0
    order by $part
    return $h      
let $total := count($related)
let $recType := 
    if($collection = ('sbd','authors','q')) then 'person'
    else if($collection = ('geo','place')) then 'place'
    else if($collection = ('nhsl','bhse','bible')) then 'work'
    else if($collection = ('subjects','keywords')) then 'keyword'
    else 'record'
let $title-string :=     
    if($relType = 'dct:isPartOf') then 
        concat($title,' contains ',$total,' works.')
    else if ($relType = 'skos:broadMatch') then
        if($recType = 'keyword') then 
           concat($title,' encompasses ',$total,concat(' ',$recType),if($total gt 1) then 's' else '','.')
        else if($recType = 'work') then 
            concat('This tradition comprises at least ',$total,' branches',if($total gt 1) then 's' else(),'.')
        else concat($title,' refers to ',$total,concat(' ',$recType),if($total gt 1) then 's' else(),'.')
    else concat($title,' ',global:odd2text('relation', $relType),' ',$total,' ',$recType, if($total gt 1) then 's' else(),'.')
let $collection-root := string(global:collection-vars($collection)/@app-root)    
return 
    if($total gt 0) then 
        <div xmlns="http://www.w3.org/1999/xhtml">
            {(
            <h3>{$title-string}</h3>,
             if($relType = 'syriaca:sometimesCirculatesWith') then
                <p class="note indent">* Manuscripts of the larger work only sometimes contain the work indicated.</p>
            else ())}
            {(
               if($count='all') then 
                    for $r in $related
                    return 
                             <div class="indent row">
                                <div class="col-md-1"><span class="badge results">{$r/descendant::tei:relation[@passive[matches(.,$recid)]][1]/descendant::tei:label[@type='order'][1]/text()}</span></div>
                                <div class="col-md-11">{tei2html:summary-view($r, '', $recid)}</div>
                             </div>
                else if($total gt 5) then
                        <div>
                         {
                             for $r in subsequence($related, 1, 3)
                             let $part := 
                                   if ($r/descendant::tei:relation[@passive[matches(.,$recid)]]/tei:desc[1]/tei:label[@type='order'][1]/@n castable as  xs:integer)
                                   then xs:integer($r/child::*/tei:listRelation/tei:relation[@passive[matches(.,$recid)]]/tei:desc[1]/tei:label[@type='order'][1]/@n)
                                   else ''
                             return 
                             <div class="indent row">
                                <div class="col-md-1"><span class="badge results">{$r/descendant::tei:relation[@passive[matches(.,$recid)]][1]/descendant::tei:label[@type='order'][1]/text()}</span></div>
                                <div class="col-md-11">{tei2html:summary-view($r, '', $recid)}</div>
                             </div>
                         }
                           <div>
                            <a href="#" class="btn btn-info getData" style="width:100%; margin-bottom:1em;" data-toggle="modal" data-target="#moreInfo" 
                            data-ref="{$global:nav-base}/{$collection-root}/search.html?relId={$recid}&amp;relType={$relType}&amp;perpage={$total}&amp;showPart=true" 
                            data-label="{$title-string}" id="works">
                              See all {$total} records
                             </a>
                           </div>
                         </div>
                else 
                    for $r in $related
                    return 
                             <div class="indent row">
                                <div class="col-md-1"><span class="badge results">{$r/descendant::tei:relation[@passive[matches(.,$recid)]][1]/descendant::tei:label[@type='order'][1]/text()}</span></div>
                                <div class="col-md-11">{tei2html:summary-view($r, '', $recid)}</div>
                             </div>
            )}
        </div>
    else ()  
};



