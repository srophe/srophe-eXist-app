xquery version "3.0";
(: Global app variables and functions. :)
module namespace global="http://syriaca.org/global";
declare namespace http="http://expath.org/ns/http-client";
declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

(: Global variables used by Srophe app :)
(: Find app root for building absolute paths :)
declare variable $global:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
    ;
(: Get repo.xml to parse global varaibles :)
declare variable $global:get-config := doc($global:app-root || '/repo-config.xml');

(: Establish data root defined in repo.xml 'data-root' name of eXist app :)
declare variable $global:data-root := 
    let $app-root := $global:get-config//repo:app-root/text()  
    let $data-root := concat($global:get-config//repo:data-root/text(),'/data') 
    return
       replace($global:app-root, $app-root, $data-root)
    ;

(: Establish main navigation for app, used in templates for absolute links. Syriaca.org uses a development and production server which each have different root directories.  :)
declare variable $global:nav-base := 
    if($global:get-config//repo:nav-base/text() != '') then $global:get-config//repo:nav-base/text()
    (: For app set to root '/' see syriaca.org production site. :)
    else if($global:get-config//repo:nav-base/text() = '/') then ''
    else '';

(: Base URI used in record tei:idno :)
declare variable $global:base-uri := $global:get-config//repo:base_uri/text();

declare variable $global:app-title := $global:get-config//repo:title/text();

declare variable $global:app-url := $global:get-config//repo:url/text();

declare variable $global:id-path := $global:get-config//repo:id-path/text();

(: Map rendering, google or leaflet :)
declare variable $global:app-map-option := $global:get-config//repo:maps/repo:option[@selected='true']/text();

(: Map rendering, google or leaflet :)
declare variable $global:map-api-key := $global:get-config//repo:maps/repo:option[@selected='true']/@api-key;

(: Recaptcha Key, Store as environemnt variable. :)
declare variable $global:recaptcha := '6Lc8sQ4TAAAAAEDR5b52CLAsLnqZSQ1wzVPdl0rO';

(: Global functions used throughout Srophe app :)
(:~
 : Sub in relative paths based on base-url variable
 : @para @uri as xs:string 
 :)
declare function global:internal-links($uri as xs:string?){
    try {
        replace($uri,$global:base-uri,$global:nav-base)
    } catch * {
        <error>Caught error {$err:code}: {$err:description}</error>
        }
};

(:
 : Addapted from https://github.com/eXistSolutions/hsg-shell
 : Recurse through menu output absolute urls based on config.xml values. 
 : @param $nodes html elements containing links with '$app-root'
:)
declare function global:fix-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(html:a) return
                let $href := replace($node/@href, "\$app-root", $global:nav-base)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element(html:form) return
                let $action := replace($node/@action, "\$app-root", $global:nav-base)
                return
                    <form action="{$action}">
                        {$node/@* except $node/@action, global:fix-links($node/node())}
                    </form>      
            case element() return
                element { node-name($node) } {
                    $node/@*, global:fix-links($node/node())
                }
            default return
                $node
};

(:~
 : Transform tei to html via xslt
 : @param $node data passed to transform
:)
declare function global:tei2html($nodes as node()*) {
  transform:transform($nodes, doc($global:app-root || '/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
    </parameters>
    )
};

(: 
 : Formats search and browse results 
 : Uses English and Syriac headwords if available, tei:teiHeader/tei:title if no headwords.
 : @param $node search/browse hits should be either tei:person, tei:place, or tei:body
 : @param $lang defaults to 'en'
 : @param $recid 
 : Used by search.xqm, browse.xqm and get-related.xqm and spear.xqm
:)
declare function global:display-recs-short-view($node as node()*, $lang as xs:string?, $recid as xs:string?) as node()*{
  transform:transform($node, doc($global:app-root || '/resources/xsl/rec-short-view.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
        <param name="lang" value="{$lang}"/>
        <param name="recid" value="{$recid}"/>
    </parameters>
    )   
};

(: 
 : Formats search and browse results 
 : Uses English and Syriac headwords if available, tei:teiHeader/tei:title if no headwords.
 : @param $node search/browse hits should be either tei:person, tei:place, or tei:body
 : @param $lang defaults to 'en'
 : Used by search.xqm, browse.xqm and get-related.xqm
:)
declare function global:display-recs-short-view($node as node()*, $lang as xs:string?) as node()*{
  transform:transform($node, doc($global:app-root || '/resources/xsl/rec-short-view.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
        <param name="lang" value="{$lang}"/>
    </parameters>
    )
};

(:~
 : Build uri from short id
 : Uses request:get-parameter('id', '') return string. 
:)
declare function global:resolve-id() as xs:string?{
let $id := request:get-parameter('id', '')
let $parse-id :=
    if(contains($id,$global:base-uri) or starts-with($id,'http://')) then $id
    else if(starts-with(request:get-uri(),$global:base-uri)) then string(request:get-uri())
    else if(contains(request:get-uri(),$global:nav-base) and $global:nav-base != '') then 
        replace(request:get-uri(),$global:nav-base, $global:base-uri)
    else if(starts-with(request:get-uri(),'/exist/apps')) then 
        replace(request:get-uri(),concat('/exist/apps/',replace($global:app-root,'/db/apps/','')), $global:base-uri)   
    else $id
let $final-id := if(ends-with($parse-id,'.html')) then substring-before($parse-id,'.html') else $parse-id
return $final-id
};

(:~
 : Get collection data
 : @param $collection match collection name in repo.xml 
:)
declare function global:collection-vars($collection as xs:string?) as node()?{
let $collection-config := $global:get-config//repo:collections
for $collection in $collection-config/repo:collection[@name = $collection]
return $collection
};


(:~
 : Build uri from short id
 : Uses request:get-parameter('id', '') return string. 
:)
declare function global:collection-data-root($collection as xs:string?) as xs:string?{
let $collection-config := $global:get-config//repo:collections
for $collection in $collection-config/repo:collection[@name = $collection]
return string($collection/@data-root)
};

(:~
 : Build uri from short id
 : Uses request:get-parameter('id', '') return string. 
:)
declare function global:collection-series($collection as xs:string?) as xs:string?{
let $collection-config := $global:get-config//repo:collections
for $collection in $collection-config/repo:collection[@name = $collection]
return string($collection/@series)
};

(:~ 
 : Parse persNames to take advantage of sort attribute in display. 
 : Returns a sorted string
 : @param $name persName element 
 :)
declare function global:parse-name($name as node()*) as xs:string* {
if($name/child::*) then 
    string-join(for $part in $name/child::*
    order by $part/@sort ascending, string-join($part/descendant-or-self::text(),' ') descending
    return $part/text(),' ')
else $name/text()
};

(:~ 
 : Parse persNames to take advantage of sort attribute in display. 
 : Returns a sorted string
 : @param $name persName element 
 :)
declare function global:make-iso-date($date as xs:string?) as xs:date* {
xs:date(
    if($date = '0-100') then '0001-01-01'
    else if($date = '2000-') then '2100-01-01'
    else if(matches($date,'\d{4}')) then concat($date,'-01-01')
    else if(matches($date,'\d{3}')) then concat('0',$date,'-01-01')
    else if(matches($date,'\d{2}')) then concat('00',$date,'-01-01')
    else if(matches($date,'\d{1}')) then concat('000',$date,'-01-01')
    else '0100-01-01')
};

(:
 : Function to truncate description text after first 12 words
 : @param $string
:)
declare function global:truncate-string($str as xs:string*) as xs:string? {
let $string := string-join($str, ' ')
return 
    if(count(tokenize($string, '\W+')[. != '']) gt 12) then 
        let $last-words := tokenize($string, '\W+')[position() = 14]
        return concat(substring-before($string, $last-words),'...')
    else $string
};
(:~
 : Strips English titles of non-sort characters as established by Syriaca.org
 : Used for alphabetizing
 : @param $titlestring 
 :)
declare function global:build-sort-string($titlestring as xs:string?, $lang as xs:string?) as xs:string* {
    if($lang = 'ar') then global:ar-sort-string($titlestring)
    else replace($titlestring,'^[^\p{L}]+|^[aA]\s+|^[aA]l-|^[aA]n\s|^[oO]n\s+[aA]\s+|^[oO]n\s+|^[tT]he\s+[^\p{L}]+|^[tT]he\s+|^A\s+|^''De','')
};

(:~
 : Strips Arabic titles of non-sort characters as established by Syriaca.org
 : @note: This code normalizes for alphabetization the most common cases, data uses rare Arabic glyphs such as those in the range U0674-U06FF, further normalization may be needed
 : Used for alphabetizing
 : @param $titlestring 
 :)
declare function global:ar-sort-string($titlestring as xs:string?) as xs:string* {
replace(
    replace(
      replace(
        replace(
          replace($titlestring,'^\s+',''), (:remove leading spaces. :)
            '[ً-ٖ]',''), (:remove vowels and diacritics :)
                '(^|\s)(ال|أل|ٱل)',''), (: remove all definite articles :)
                    'آ|إ|أ|ٱ','ا'), (: normalize letter alif :)
                        '^(ابن|إبن|بن)','') (:remove all forms of (ابن) with leading space :)
};

(:
 : Uses Srophe ODD file to establish labels for various ouputs. Returns blank if there is no matching definition in the ODD file.
 : Pass in ODD file from repo.xml 
 : example: global:odd2text($rec/descendant::tei:bibl[1],string($rec/descendant::tei:bibl[1]/@type))
:)
declare function global:odd2text($element as xs:string?, $label as xs:string?) as xs:string* {
    let $odd-path := $global:get-config//repo:odd/text()
    let $odd-file := 
                    if(starts-with($odd-path,'http')) then 
                            http:send-request(<http:request href="{xs:anyURI($odd-path)}" method="get"/>)[2]
                    else doc($global:app-root || $odd-path)
    return 
        if($odd-path != '') then
            let $odd := $odd-file
            (:let $e := if(contains($element,'/@')) then substring-before($element,'/@') else $element
            let $a := if(contains($element,'@')) then substring-after($element,'/@') else ()
            :)
            return 
                try {
                    if($odd/descendant::*[@ident = $element][1]/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()) then 
                        $odd/descendant::*[@ident = $element][1]/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()
                    else if($odd/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()) then 
                        $odd/descendant::tei:valItem[@ident=$label][1]/tei:gloss[1]/text()
                    else $label    
                } catch * {
                    $label (:<error>Caught error {$err:code}: {$err:description}</error>:)
                }  
         else $label
};

(:~
 : Configure dropdown menu for keyboard layouts for input boxes
 : Options are defined in repo.xml
 : @param $input-id input id used by javascript to select correct keyboard layout.  
 :)
declare function global:keyboard-select-menu($input-id as xs:string){
    (: Could have lange options set in config :)
    if($global:get-config//repo:keyboard-options/child::*) then 
        <ul xmlns="http://www.w3.org/1999/xhtml" class="dropdown-menu" test="TEST">
            {
            for $layout in $global:get-config//repo:keyboard-options/repo:option
            return  
                <li xmlns="http://www.w3.org/1999/xhtml"><a href="#" class="keyboard-select" id="{$layout/@id}" data-keyboard-id="{$input-id}">{$layout/text()}</a></li>
            }
        </ul>
    else ()       
};
