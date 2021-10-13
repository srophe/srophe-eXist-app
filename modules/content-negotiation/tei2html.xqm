xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2html="http://srophe.org/srophe/tei2html";
import module namespace bibl2html="http://srophe.org/srophe/bibl2html" at "bibl2html.xqm";
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

declare namespace srophe="https://srophe.app";
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
            case element(tei:biblScope) return element span {
                let $unit := if($node/@unit = 'vol') then concat($node/@unit,'.') 
                             else if($node[@unit != '']) then string($node/@unit) 
                             else if($node[@type != '']) then string($node/@type)
                             else () 
                return 
                    if(matches($node/text(),'^\d')) then concat($unit,' ',$node/text())
                    else if(not($node/text()) and ($node/@to or $node/@from)) then  concat($unit,' ',$node/@from,' - ',$node/@to)
                    else $node/text()
            }
            case element(tei:category) return element ul {tei2html:tei2html($node/node())}
            case element(tei:catDesc) return element li {tei2html:tei2html($node/node())}
            case element(tei:foreign) return element span 
                {(
                if($node/@xml:lang) then attribute lang { $node/@xml:lang } else (),
                if($node/@xml:lang = ('syr','ar','he')) then attribute dir { 'rtl' } else (),
                tei2html:tei2html($node/node())
                )}
            case element(tei:imprint) return element span {
                    if($node/tei:pubPlace/text()) then $node/tei:pubPlace[1]/text() else (),
                    if($node/tei:pubPlace/text() and $node/tei:publisher/text()) then ': ' else (),
                    if($node/tei:publisher/text()) then $node/tei:publisher[1]/text() else (),
                    if(not($node/tei:pubPlace) and not($node/tei:publisher) and $node/tei:title[@level='m']) then <abbr title="no publisher">n.p.</abbr> else (),
                    if($node/tei:date/preceding-sibling::*) then ', ' else (),
                    if($node/tei:date) then $node/tei:date else <abbr title="no date of publication">n.d.</abbr>,
                    if($node/following-sibling::tei:biblScope[@unit='series']) then ', ' else ()
            }
            case element(tei:label) return element span {tei2html:tei2html($node/node())}
            case element(tei:orig) return 
                <span class="tei-orig">{
                if($node/tei:date) then 
                    <span class="tei-date">{(' (',tei2html:tei2html($node/tei:date),')')}</span>
                else tei2html:tei2html($node/node())
                }</span>
            case element(tei:place) return
                if($node/parent::tei:listPlace/parent::tei:body) then
                    (:tei2html:placeUI($node):) tei2html:tei2html($node)
                else tei2html:tei2html($node)
            case element(tei:placeName) return 
                <span class="tei-placeName">{
                    let $name := tei2html:tei2html($node/node())
                    return
                        if($node/@ref) then
                            element a { attribute href { $node/@ref }, $name }
                        else $name                                 
                        }</span>
            case element(tei:persName) return 
                <span class="tei-persName">{
                    let $name := if($node/child::*) then 
                                    string-join(for $part in $node/child::*
                                    order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
                                    return tei2html:tei2html($part/node()),' ')
                                 else tei2html:tei2html($node/node())
                    return
                        if($node/@ref) then
                            element a { attribute href { $node/@ref }, $name }
                        else $name                                 
                        }</span>
            case element(tei:title) return 
                let $titleType := 
                        if($node/@level='a') then 
                            'title-analytic'
                        else if($node/@level='m') then 
                            'title-monographic'
                        else if($node/@level='j') then 
                            'title-journal'
                        else if($node/@level='s') then 
                            'title-series'
                        else if($node/@level='u') then 
                            'title-unpublished'
                        else if($node/parent::tei:persName) then 
                            'title-person'                             
                        else ()
                return  
                    <span class="tei-title {$titleType}"> {
                        (if($node/@xml:lang) then attribute lang { $node/@xml:lang } else (),
                        tei2html:tei2html($node/node()))                 
                    }</span>
            case element() return
                <span class="tei-{local-name($node)}">
                    {tei2html:attributes($node)}
                    {if($node/@n) then  <span class="tei-attr-n">{string($node/@n)}</span> else ()} 
                    {tei2html:tei2html($node/node()) }
                </span>                    
            default return tei2html:tei2html($node/node())
};

declare function tei2html:attributes($node as node()*) as item()* {
    for $a in $node/@*
    return 
        if(name($a) = "xml:lang") then 
            ($a, attribute lang { $a },
            if($a ='en') then 
                attribute dir { 'ltr' }
            else if($a = ('syr','ar','syc','syr-Syrj')) then 
                attribute dir { 'rtl' }    
            else ()
            )
        else if(name($a) = "@xml:id") then
            attribute id { $a } 
        else $a
};

declare function tei2html:add-footnote($node as node()*){
let $refs := $node/@source
return 
    if($refs != '') then 
        <span class="tei-footnote-refs" dir="ltr" lang="en">{
            for $r at $i in tokenize($refs,' ')
            return 
                (if($i gt 1) then ', ' else (),
                <span class="tei-footnote-ref">
                    <a href="{$r}">{substring-after($r,'-')}</a>
                </span>)
        }</span>
    else ()
};

(:~
 : Display title for each module. 
:)
declare function tei2html:h1($nodes as node()*){
let $id := $nodes/descendant::tei:body/descendant::tei:idno[contains(., $config:base-uri)][1]
return 
    <div class="row title">
        <h1 class="col-md-8"><span id="title">{
            if(ft:field($nodes, "title")) then 
                if(ft:field($nodes, "titleSyriac")) then 
                concat(ft:field($nodes, "title"), ' - ', ft:field($nodes, "titleSyriac"))
                else ft:field($nodes, "title")
            else if(contains($id,'/subject/')) then 
                ('Term', tei2html:tei2html($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][not(empty(node()))][1]))
            else if($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword') or contains(@srophe:tags,'#headword') or contains(@srophe:tags,'#syriaca-headword')]) then
                  (tei2html:tei2html($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword') or contains(@srophe:tags,'#headword') or contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][not(empty(node()))][1]),
                    ' - ',
                    if($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword') or contains(@srophe:tags,'#headword') or contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')]) then 
                       <span lang="syr" dir="rtl">{tei2html:tei2html($nodes/descendant::*[contains(@syriaca-tags,'#syriaca-headword') or contains(@srophe:tags,'#headword') or contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')])}</span>
                    else '[ Syriac Not Available ]')
            else tei2html:tei2html($nodes/descendant-or-self::tei:title[1])
        }</span>
        {
        if($nodes/descendant::tei:birth or $nodes/descendant::tei:death or $nodes/descendant::tei:floruit) then
            <span lang="en" class="type" style="padding-left:1em; font-size:.85em;">{
                ('(',
                    if($nodes/descendant::tei:birth or $nodes/descendant::tei:death) then 
                        if(not($nodes/descendant::tei:death)) then
                            concat('b.',
                                for $b at $i in $nodes/descendant::tei:birth
                                return concat(if($i gt 1) then ' or ' else(), $b/text())
                            ) 
                        else if($nodes/descendant::tei:death) then 
                            (if($nodes/descendant::tei:birth) then ' - '
                            else 'd.',
                            for $d at $i in $nodes/descendant::tei:death
                            return concat(if($i gt 1) then ' or ' else(), $d/text())
                            )
                            (:
                        else if($nodes/descendant::tei:floruit and not($nodes/descendant::tei:birth) and not($nodes/descendant::tei:death)) then  
                            if($nodes/descendant::tei:floruit/tei:date) then 
                                for $f at $i in $nodes/descendant::tei:floruit/tei:date
                                return concat(if($i gt 1) then ' or ' else(), $f/text())
                            else if($nodes/descendant::tei:floruit[@notBefore or @notAfter or @when or @from or @to]) then
                                if($nodes/descendant::tei:floruit/@to and $nodes/descendant::tei:floruit/@from) then 
                                    concat('between ', tei2html:trim-date(tei:floruit[1]/@from), ' - ',  tei2html:trim-date(tei:floruit[1]/@to))
                                else if($nodes/descendant::tei:floruit/@notBefore and $nodes/descendant::tei:floruit/@notAfter) then
                                    concat('between ', tei2html:trim-date(tei:floruit[1]/@notBefore), ' - ',  tei2html:trim-date(tei:floruit[1]/@notAfter))
                                else tei2html:do-dates(tei:floruit[1])
                            else concat('active ', $nodes/descendant::tei:floruit[1]/text()) :)
                        else ()
                    else (),
                ')')
            }</span>
        else ()
        }
        </h1>
    </div>
};

declare function tei2html:do-dates($element){
    if($element/@when or $element/@notBefore or $element/@notAfter or $element/@from or $element/@to) then 
        (if($element/@from) then
            if($element/@to) then
                concat(tei2html:trim-date($element/@from), '-', tei2html:trim-date($element/@to))
            else concat('from ', tei2html:trim-date($element/@from))
        else if($element/@to) then    
            concat('to ', tei2html:trim-date($element/@to)) 
        else (),
        if($element/@notBefore) then
            if($element/@to or $element/@from) then 
                concat(', not before ', tei2html:trim-date($element/@notBefore))
            else concat('not before ', tei2html:trim-date($element/@notBefore))
        else (),
        if($element/@notAfter) then
            if($element/@to or $element/@from or $element/@notBefore) then 
                concat(', not after ', tei2html:trim-date($element/@notAfter))
            else concat('not after ', tei2html:trim-date($element/@notAfter))
        else (),
        if($element/@when) then
            if($element/@to or $element/@from or $element/@notBefore or $element/@notAfter) then 
                concat(', ', tei2html:trim-date($element/@when))
            else tei2html:trim-date($element/@when)
        else ()
        )
    else ()
};

declare function tei2html:trim-date($date){
    if(starts-with($date,'-0')) then concat(substring($date,3),' BCE')
    else if(starts-with($date,'0')) then tei2html:trim-date(substring($date,2))
    else string($date)
};

(:~ 
 : Display idno with copy icon and paging (if relevant)
:)
declare function tei2html:idno-title-display($id){
    let $id-string := substring-after(tokenize($id,'/')[last()],'-')
    let $id-num := if($id-string castable as xs:integer) then $id-string cast as xs:integer else 0
    let $next := $id-num + 1
    let $prev := $id-num - 1
    let $next-url := concat(substring-before($id,'-'),'-',string($next))
    let $prev-url := concat(substring-before($id,'-'),'-',string($prev))
    return 
        <div style="margin:0 1em 1em; color: #999999;" xmlns="http://www.w3.org/1999/xhtml">
            <small>
                <span class="uri">
                    <a href="{replace($prev-url, $config:base-uri, $config:nav-base)}"><span class="glyphicon glyphicon-backward" aria-hidden="true"/></a>
                    &#160;<button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                        <span class="srp-label">URI</span>
                    </button>&#160;
                    <span id="syriaca-id">{$id}</span>
                    <script>
                        <![CDATA[
                            var clipboard = new Clipboard('#idnoBtn');
                            clipboard.on('success', function(e) {
                            console.log(e);
                            });
                            
                            clipboard.on('error', function(e) {
                            console.log(e);
                            });]]>
                    </script>
                    <a href="{replace($next-url,$config:base-uri, $config:nav-base)}"><span class="glyphicon glyphicon-forward" aria-hidden="true"/></a>
                </span>
            </small>
        </div>
};

(: template for gazetteer pages :)
(:
declare function tei2html:placeUI($node){
<div>
    {tei2html:tei2html($node/tei:desc[starts-with(@xml:id,'abstract')])}
    <div class="well">{
    let $type := string($node/@type)
    let $geo := $node/descendant::tei:geo[1]
    return 
        if($geo) then 
            <div class="row" xmlns="http://www.w3.org/1999/xhtml">
                <div class="col-md-7">
                    {maps:build-map($data,0)}
                </div>
                <div class="col-md-5">
                   <div class="clearfix" xmlns="http://www.w3.org/1999/xhtml">
                        <div id="type">
                            <p><strong>Place Type: </strong>
                                <a href="../documentation/place-types.html#{normalize-space($type)}" class="no-print-link">{$type}</a>
                            </p>
                        </div>
                        {
                        if($geo/descendant-or-self::tei:location) then
                            <div id="location" xmlns="http://www.w3.org/1999/xhtml">
                                <h4>Location</h4>
                                <ul>
                                {
                                    for $location in $geo/descendant-or-self::tei:location
                                    let $sort := if($location[@subtype = 'preferred']) then 0 else 1
                                    order by $sort
                                    return tei2html:tei2html($location)
                                }
                                </ul>
                            </div>
                        else ()
                        }
                    </div> 
                </div>    
            </div>
        else 
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
                            for $location in $geo/descendant-or-self::tei:location
                            let $sort := if($location[@subtype = 'preferred']) then 0 else 1
                            order by $sort
                            return tei2html:tei2html($location)
                        }
                        </ul>
                    </div>
                else ()
                }
            </div>
    }</div>
    
    
</div>

};
:)

(:
 : Used for short views of records, browse, search or related items display. 
:)
declare function tei2html:summary-view($nodes as node()*, $lang as xs:string?, $id as xs:string?) as item()* {
  let $id := if($id) then $id else replace($nodes/descendant-or-self::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
  return 
      if(contains($id,'/person/')) then tei2html:summary-view-persons($nodes,$id)
      else if(contains($id,'/place/')) then tei2html:summary-view-places($nodes,$id)
      else if(contains($id,'/keyword/')) then tei2html:summary-view-keyword($nodes, $id)
      else if(contains($id,'/bibl/')) then tei2html:summary-view-bibl($nodes, $id)
      else tei2html:summary-view-generic($nodes,$id)   
};

(: Special short view template for Persons :)
declare function tei2html:summary-view-persons($nodes as node()*, $id as xs:string?) as item()* {
    let $title := (:if(ft:field($nodes, "title")) then 
                    ft:field($nodes, "title")
                  else :)if($nodes/descendant-or-self::*[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::*[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]
                  else if($nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]                    
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $syr-title := 
               (: if(ft:field($nodes, "titleSyriac")) then 
                    ft:field($nodes, "titleSyriac")
                else :)if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                     <span xml:lang="syr" lang="syr" dir="rtl">{string-join($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                else if($nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')]) then 
                    $nodes/descendant-or-self::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')]                     
                else if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')]) then 
                    '[Syriac Not Available]'
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
            <a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}" dir="ltr">{(tei2html:tei2html($title),if($syr-title != '') then (' - ', $syr-title) else())}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {if($ana != '') then <span class="results-list-desc type" dir="ltr" lang="en">{('(', $ana, if($dates != '') then (', ', $dates) else (),')')}</span>  else()}
            {if(
            $nodes/descendant::tei:person/tei:persName[not(contains(@srophe:tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]) then 
                <span class="results-list-desc names" dir="ltr" lang="en">
                    Names: {
                        for $n in $nodes/descendant::tei:person/tei:persName[not(contains(@srophe:tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] 
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
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}">{replace($id,'/tei','')}</a></span>
            else()
            }
        </div>   
};

(: Special short view template for Places :)
declare function tei2html:summary-view-places($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::*[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::*[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $syr-title := 
                if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                     <span xml:lang="syr" lang="syr" dir="rtl">{string-join($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                else if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')]) then 
                    '[Syriac Not Available]'
                else () 
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)                
    return 
        <div class="short-rec-view">
                        <a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}" dir="ltr">{(tei2html:tei2html($title),if($nodes/descendant::tei:place/@type) then concat(' (',string($nodes/descendant::tei:place/@type),') ') else (),if($syr-title != '') then (' - ', $syr-title) else())}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            {if($nodes/descendant-or-self::tei:place/tei:placeName[not(contains(@srophe:tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]) then 
                <span class="results-list-desc names" dir="ltr" lang="en">
                    Names: {
                        for $n in $nodes/descendant::tei:place/tei:placeName[not(contains(@srophe:tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] 
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
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}">{replace($id,'/tei','')}</a></span>
            else()
            }
        </div>   
};

(: Special short view template for Keywords/Taxonomy :)
declare function tei2html:summary-view-keyword($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::tei:term[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::tei:term[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]/text()
                  else $nodes/descendant-or-self::tei:term[1]/text()                  
    return 
        <div class="short-rec-view">
            <a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}" dir="ltr">{$title}</a>
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
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}">{replace($id,'/tei','')}</a></span>
            else()
            }
        </div>   
};

(: Generic short view template :)
declare function tei2html:summary-view-generic($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::tei:title[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::tei:title[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]/text()
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $syr-title := 
                if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                     <span xml:lang="syr" lang="syr" dir="rtl">{string-join($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                else ()                   
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)
    return 
        <div class="short-rec-view">
            <a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}" dir="ltr">{(tei2html:tei2html($title),if($nodes/descendant::tei:place/@type) then concat(' (',string($nodes/descendant::tei:place/@type),') ') else (),if($syr-title != '') then (' - ', $syr-title) else())}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
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
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}">{replace($id,'/tei','')}</a></span>
            else()
            }
        </div>   
};

declare function tei2html:summary-view-bibl($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::tei:title[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::tei:title[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]/text()
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $series := for $a in distinct-values($nodes/descendant::tei:seriesStmt/tei:biblScope/tei:title)
                   return tei2html:translate-series($a)
    return 
        <div class="short-rec-view">
            <a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}" dir="ltr">{$title}</a>
            <button type="button" class="btn btn-sm btn-default copy-sm clipboard"  
                data-toggle="tooltip" title="Copies record title &amp; URI to clipboard." 
                data-clipboard-action="copy" data-clipboard-text="{normalize-space($title[1])} - {normalize-space($id[1])}">
                    <span class="glyphicon glyphicon-copy" aria-hidden="true"/>
            </button>
            <span class="results-list-desc desc" dir="ltr" lang="en">{
                bibl2html:citation($nodes/descendant::tei:biblStruct)
                (:global:tei2html(<citation xmlns="http://www.tei-c.org/ns/1.0">{$nodes/descendant::tei:biblStruct}</citation>):)
            }</span>
            {
            if($id != '') then 
            <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{replace(replace($id,$config:base-uri,$config:nav-base),'/tei','')}">{replace($id,'/tei','')}</a></span>
            else()
            }
        </div>
};

declare function tei2html:summary-view-spear($nodes as node()*, $id as xs:string?) as item()* {
    let $title := if($nodes/descendant-or-self::*[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != '']) then 
                    $nodes/descendant-or-self::*[@srophe:tags='#syriaca-headword'][contains(@xml:lang,'en')][descendant::text() != ''][1]
                  else $nodes/descendant-or-self::tei:title[1]/text()
    let $syr-title := 
                if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]) then
                     <span xml:lang="syr" lang="syr" dir="rtl">{string-join($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')}</span>
                else if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')]) then 
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
            $nodes/descendant::tei:person/tei:persName[not(contains(@srophe:tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))]) then 
                <span class="results-list-desc names" dir="ltr" lang="en">
                    Names: {
                        for $n in $nodes/descendant::tei:person/tei:persName[not(contains(@srophe:tags,'#syriaca-headword'))][not(matches(@xml:lang,('^syr|^ar|^en-xsrp1')))] 
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
        <span class="results-list-desc uri"><span class="srp-label">For additional information, see: </span><a href="{replace($id,$config:base-uri,$config:nav-base)}">{$id}</a></span>
    </div>        
};

declare function tei2html:title-display($nodes as node()*){
    <span id="title">
        {(
            if($nodes/descendant-or-self::tei:entryFree) then
                concat('Term: ', tei2html:tei2html($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][not(empty(node()))][1]))
            else if($nodes/descendant::*[contains(@srophe:tags,'#anonymous-description')]) then
                string-join($nodes/descendant::*[contains(@srophe:tags,'#anonymous-description')][1],' ')
            else if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')]) then
                (string(tei2html:tei2html($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'en')][not(empty(node()))][1])),
                ' - ',
                if($nodes/descendant::*[contains(@srophe:tags,'#anonymous-description')]) then 
                    string(tei2html:tei2html($nodes/descendant::*[contains(@srophe:tags,'#anonymous-description')][1]))
                else if($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')]) then 
                    <span lang="syr" dir="rtl">{string(tei2html:tei2html($nodes/descendant::*[contains(@srophe:tags,'#syriaca-headword')][starts-with(@xml:lang,'syr')][1]))}</span>
                else '[ Syriac Not Available ]'
                )
            else tei2html:tei2html($nodes/descendant-or-self::tei:title[1])
           (:NOTE: need to add dates for persons. see xslt :)
        )}
   </span>
};

declare function tei2html:translate-series($series as xs:string?){
    if($series = 'The Syriac Biographical Dictionary') then ()
    else if($series = 'A Guide to Syriac Authors') then 
        <a href="{$config:nav-base}/authors/index.html"><img src="{$config:nav-base}/resources/images/icons-authors-sm.png" alt="A Guide to Syriac Authors"/>author</a>
    else if($series = 'Qadishe: A Guide to the Syriac Saints') then 
        <a href="{$config:nav-base}/q/index.html"><img src="{$config:nav-base}/resources/images/icons-q-sm.png" alt="Qadishe: A Guide to the Syriac Saints"/>saint</a>        
    else $series
};

(:~ 
 : Reworked  KWIC to be more 'Google like' 
 : Passes content through  tei2html:kwic-format() to output only text and matches 
 : Note: could be made more robust to match proximity operator, it it is greater the 10 it may be an issue.
 : To do, pass search params to record, highlight hits in record 
   let $search-params := 
        string-join(
            for $param in request:get-parameter-names()
            return 
                if($param = ('fq','start')) then ()
                else if(request:get-parameter($param, '') = ' ') then ()
                else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
:)
declare function tei2html:output-kwic($nodes as node()*, $id as xs:string*){
    let $results := <results xmlns="http://www.w3.org/1999/xhtml">{tei2html:kwic-format($nodes)}</results>
    let $count := count($results//*:match)
    for $node at $p in subsequence($results//*:match,1,8)
    let $prev := $node/preceding-sibling::text()[1]
    let $next := $node/following-sibling::text()[1]
    let $prevString := 
        if(string-length($prev) gt 60) then 
            concat(' ...',substring($prev,string-length($prev) - 100, 100))
        else $prev
    let $nextString := 
        if(string-length($next) lt 100 ) then () 
        else concat(substring($next,1,100),'... ')
    let $link := concat($config:nav-base,'/',tokenize($id,'/')[last()],'#',$node/@n)
    return 
        <span>{$prevString}&#160;<span class="match" style="background-color:yellow;"><a href="{$link}">{$node/text()}</a></span>&#160;{$nextString}</span>
};

(:~
 : Strips results to just text and matches. 
 : Note, could pass though tei2html:tei2html() to hide hidden content (choice/orig)
:)
declare function tei2html:kwic-format($nodes as node()*){
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(exist:match) return 
                let $n := if($node/ancestor-or-self::*[@n]) then concat('Head-id.',$node/ancestor-or-self::*[@n][1]/@n) else ()
                return 
                <match xmlns="http://www.w3.org/1999/xhtml">
                    {(if($n != '') then attribute n {$n} else (), 
                    $node/node()
                    )}
                </match>
            default return tei2html:kwic-format($node/node())                
};