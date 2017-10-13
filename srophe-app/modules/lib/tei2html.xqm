xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2html="http://syriaca.org/tei2html";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";

declare namespace html="http://purl.org/dc/elements/1.1/";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

(:~
 : Simple TEI to HTML transformation
 : @param $node   
:)
declare function tei2html:tei2html($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(tei:persName) return 
                <span class="persName">{
                    if($node/child::*) then 
                        for $part in $node/child::*
                        order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
                        return tei2html:tei2html($part/node())
                    else tei2html:tei2html($node/node())
                }</span>
            case element(tei:category) return element ul {tei2html:tei2html($node/node())}
            case element(tei:catDesc) return element li {tei2html:tei2html($node/node())}
            case element(tei:label) return element span {tei2html:tei2html($node/node())}
            default return tei2html:tei2html($node/node())
};

(:
 : Used for short views of records, browse, search or related items display. 
:)
declare function tei2html:summary-view($nodes as node()*, $lang as xs:string?, $id as xs:string?) as item()* {
  if(contains($id,'/person/')) then tei2html:summary-view-persons($nodes,$id)
  else if(contains($id,'/place/')) then tei2html:summary-view-places($nodes,$id)
  else if(contains($id,'/keyword/')) then tei2html:summary-view-keyword($nodes, $id)
  else if(contains($id,'/bibl/')) then tei2html:summary-view-bibl($nodes, $id)
  else tei2html:summary-view-generic($nodes,$id)   
};

(: Special short view template for Persons :)
declare function tei2html:summary-view-persons($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                    $nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $syr-title := 
                if($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                     <span xml:lang="syr" lang="syr" dir="rtl">{string-join($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                else if($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword')]) then 
                    '[Syriac Not Available]'
                else () 
    let $ana := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                return tei2html:translate-series($a)
    let $birth := if($ana != '') then $nodes/descendant::tei:birth/text() else ()            
    let $death := if($ana != '') then $nodes/descendant::tei:death/text() else ()
    let $floruit := string-join($nodes/descendant-or-self::tei:floruit/text(),' ')
    let $dates := 
        (
        if($birth != '') then $birth else (),
        if($birth != '' and $death != '') then  ' - ' else(),
        if($death != '') then if($birth = '' or empty($birth)) then ('d. ',$death) else  $death else (),
        if($floruit != '') then if($birth != '' or $death != '') then (', ',$floruit) else $floruit else ()
        )                    
    return 
        <div class="short-rec-view">
            <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">{(tei2html:tei2html($title),if($syr-title != '') then (' - ', $syr-title) else())}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {if($ana != '') then <span class="results-list-desc type" dir="ltr" lang="en">{('(', $ana, if($dates != '') then (', ', $dates) else (),')')}</span>  else()}
            {if(
            $nodes/descendant::tei:person/tei:persName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]) then 
                <span class="results-list-desc names" dir="ltr" lang="en">
                    Names: {
                        for $n in $nodes/descendant::tei:person/tei:persName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] 
                        where $n/position() lt 8
                        return <span class="pers-label badge">{tei2html:tei2html($n)}</span>
                    } 
                </span>
            else ()}
            {if($nodes/descendant-or-self::*[starts-with(@xml:id,'abstract')]) then 
                for $abstract in $nodes/descendant::*[starts-with(@xml:id,'abstract')]
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                        concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                        return $w,' '),'...')
                     else $string 
                return 
                    <span class="results-list-desc desc" dir="ltr" lang="en">{
                        if($abstract/descendant-or-self::tei:quote) then concat('"',normalize-space($blurb),'"')
                        else $blurb
                    }</span>
            else()}
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>   
};

(: Special short view template for Places :)
declare function tei2html:summary-view-places($nodes as node()*, $id as xs:string?) as item()* {
    let $title := $nodes/descendant-or-self::tei:title[1]/text()
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)                
    return 
        <div class="short-rec-view">
                        <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">
                        {(tei2html:tei2html($title),
                        if($nodes/descendant::tei:place/@type) then 
                        concat(' (',string($nodes/descendant::tei:place/@type),') ') else ())}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>   
};

(: Special short view template for Keywords/Taxonomy :)
declare function tei2html:summary-view-keyword($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::tei:term[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                    $nodes/descendant-or-self::tei:term[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/text()
                  else $nodes/descendant-or-self::tei:term[1]/text()                  
    return 
        <div class="short-rec-view">
            <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">{$title}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title)} - {normalize-space($id)}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {if($nodes/descendant::*[starts-with(@xml:id,'abstract')]) then 
                for $abstract in $nodes/descendant::*[starts-with(@xml:id,'abstract')]
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                            concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                            return $w,' '),'...')  
                     else $string 
                return 
                    if($abstract/descendant-or-self::tei:quote) then 
                        concat('"',$blurb,'"')
                    else $blurb
            else()}
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>   
};

(: Generic short view template :)
declare function tei2html:summary-view-generic($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::tei:title[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                    $nodes/descendant-or-self::tei:title[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/text()
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)
    return 
        <div class="short-rec-view">
            <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">{$title}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title)} - {normalize-space($id)}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {if($series != '') then <span class="results-list-desc type" dir="ltr" lang="en">{(' (',$series,') ')}</span> else ()}
            {if($nodes/descendant-or-self::*[starts-with(@xml:id,'abstract')]) then 
                for $abstract in $nodes/descendant::*[starts-with(@xml:id,'abstract')]
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                        concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                        return $w,' '),'...')
                     else $string 
                return 
                    <span class="results-list-desc desc" dir="ltr" lang="en">{
                        if($abstract/descendant-or-self::tei:quote) then concat('"',normalize-space($blurb),'"')
                        else $blurb
                    }</span>
            else()}
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>   
};

declare function tei2html:summary-view-bibl($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::tei:title[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                    $nodes/descendant-or-self::tei:title[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]/text()
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)
    return 
        <div class="short-rec-view">
            <a href="{replace($id,$global:base-uri,$global:nav-base)}" dir="ltr">{$title}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title)} - {normalize-space($id)}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            <span class="results-list-desc desc" dir="ltr" lang="en">{global:tei2html(<citation xmlns="http://www.tei-c.org/ns/1.0">{$nodes/descendant::tei:biblStruct}</citation>)}</span>
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
            else()
            }
        </div>
};

declare function tei2html:summary-view-spear($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en']) then 
                    $nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][@xml:lang='en'][1]
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $syr-title := 
                if($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                     <span xml:lang="syr" lang="syr" dir="rtl">{string-join($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                else if($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword')]) then 
                    '[Syriac Not Available]'
                else () 
    let $ana := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                    return tei2html:translate-series($a)
    let $birth := if($ana != '') then $nodes/descendant::tei:birth/text() else ()            
    let $death := if($ana != '') then $nodes/descendant::tei:death/text() else ()
    let $floruit := string-join($nodes/descendant-or-self::tei:floruit/text(),' ')
    let $dates := 
            (
            if($birth != '') then $birth else (),
            if($birth != '' and $death != '') then  ' - ' else(),
            if($death != '') then if($birth = '' or empty($birth)) then ('d. ',$death) else  $death else (),
            if($floruit != '') then if($birth != '' or $death != '') then (', ',$floruit) else $floruit else ()
            )                    
    return                    
    <div class="short-rec-view">
        <a href="aggregate.html?id={$id}" dir="ltr">{(tei2html:tei2html($title),if($nodes/descendant::tei:place/@type) then concat(' (',string($nodes/descendant::tei:place/@type),') ') else (),if($syr-title != '') then (' - ', $syr-title) else())}</a>
        {if($ana != '') then <span class="results-list-desc type" dir="ltr" lang="en">{('(', $ana, if($dates != '') then (', ', $dates) else (),')')}</span>  else()}
            {if(
            $nodes/descendant::tei:person/tei:persName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]) then 
                <span class="results-list-desc names" dir="ltr" lang="en">
                    Names: {
                        for $n in $nodes/descendant::tei:person/tei:persName[not(contains(@syriaca-tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] 
                        where $n/position() lt 8
                        return <span class="pers-label badge">{tei2html:tei2html($n)}</span>
                    } 
                </span>
            else ()}
            {if($nodes/descendant-or-self::*[starts-with(@xml:id,'abstract')]) then 
                for $abstract in $nodes/descendant::*[starts-with(@xml:id,'abstract')]
                let $string := string-join($abstract/descendant-or-self::*/text(),' ')
                let $blurb := 
                    if(count(tokenize($string, '\W+')[. != '']) gt 25) then  
                        concat(string-join(for $w in tokenize($string, '\W+')[position() lt 25]
                        return $w,' '),'...')
                     else $string 
                return 
                    <span class="results-list-desc desc" dir="ltr" lang="en">{
                        if($abstract/descendant-or-self::tei:quote) then concat('"',normalize-space($blurb),'"')
                        else $blurb
                    }</span>
            else()}
        <span class="results-list-desc uri"><span class="srp-label">For additional information, see: </span><a href="{replace($id,$global:base-uri,$global:nav-base)}">{$id}</a></span>
    </div>        
};


declare function tei2html:translate-series($series as xs:string?){
    if($series = 'The Syriac Biographical Dictionary') then ()
    else if($series = 'A Guide to Syriac Authors') then 
        <a href="{$global:nav-base}/authors/index.html"><img src="{$global:nav-base}/resources/img/icons-authors-sm.png" alt="A Guide to Syriac Authors"/>author</a>
    else if($series = 'Qadishe: A Guide to the Syriac Saints') then 
        <a href="{$global:nav-base}/q/index.html"><img src="{$global:nav-base}/resources/img/icons-q-sm.png" alt="Qadishe: A Guide to the Syriac Saints"/>saint</a>        
    else $series
};