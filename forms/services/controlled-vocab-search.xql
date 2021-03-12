xquery version "3.0";

(:~
 : NOTE: Handle all lookups for controlled vocab. change name
 : Build dropdown list of available resources for citation
:)
import module namespace config="http://srophe.org/srophe/config" at "../../modules/config.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";


(:forms:build-instance($id):)
declare variable $id {request:get-parameter('id', '')};
declare variable $q {request:get-parameter('q', '')};
declare variable $idno {request:get-parameter('idno', '')};
declare variable $element {request:get-parameter('element', 'person')};
declare variable $action {request:get-parameter('action', '')};
declare variable $type {request:get-parameter('type', '')};

declare function local:search(){
<results xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en">
{
let $hits := 
        if($type = 'bibl') then
            if($idno != '') then
                collection($config:data-root || '/bibl/')//tei:idno[. = $idno]
            else if($q != '') then
                collection($config:data-root || '/bibl/')//tei:TEI[descendant::tei:title[ft:query(., $q,local:options())] or descendant::tei:author[ft:query(., $q,local:options())]] 
            else  <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en">No Match</TEI>
        else collection($config:data-root)//tei:title[ft:query(., $q,local:options())]
for $hit in $hits
let $id := replace($hit/ancestor-or-self::tei:TEI/descendant::tei:publicationStmt/descendant::tei:idno[starts-with(.,$config:base-uri)],'/tei','')
let $string := if($hit/child::*) then string-join($hit//text(),' ') else $hit/text() 
let $title := if($hit/descendant::tei:biblStruct) then $hit/descendant::tei:biblStruct/child::*[1]/tei:title else $hit/ancestor-or-self::tei:TEI/descendant::tei:title
let $author := 
            if($hit/descendant::tei:biblStruct/descendant::tei:author[1]) then $hit/descendant::tei:biblStruct/descendant::tei:author[1]
            else if($hit/descendant::tei:biblStruct/descendant::tei:editor[1]) then $hit/descendant::tei:biblStruct/descendant::tei:editor[1]
            else if($hit/ancestor-or-self::tei:TEI/descendant::tei:author[1]) then $hit/ancestor-or-self::tei:TEI/descendant::tei:author[1] else if($hit/ancestor-or-self::tei:TEI/descendant::tei:editor[1]) then $hit/ancestor-or-self::tei:TEI/descendant::tei:editor[1] else ()
let $recType := 
    if($hit/ancestor-or-self::tei:TEI/descendant::tei:entryFree) then
        $hit/ancestor-or-self::tei:TEI/descendant::tei:entryFree/@type
    else if($hit/ancestor-or-self::tei:TEI/descendant::tei:listPlace) then
        $hit/ancestor-or-self::tei:TEI/descendant::tei:place/@type
    else()
return 
        <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="en">
            {
            if($type='bibl') then
                <bibl>
                    {attribute ref { $id }}
                    <title level='citation'>Title: {normalize-space(string-join(($title[matches(.,'^[a-zA-Z]','i')][1]//text(),$title[not(matches(.,'^[a-zA-Z]','i'))][1]//text()),' '))} Author: {normalize-space(string-join($author[1]//text(),' '))}</title>
                    {$author}
                    {$title}
                    <ptr target="{ $id }"/>
                    <citedRange unit="pp"/>
                </bibl>
            else
                element { local-name($hit) } { 
                    attribute ref { $id }, attribute type { $recType }, 
                    $string
                    }
             
            }
        </TEI>
        }
</results>        
};

(:~
 : Search options passed to ft:query functions
:)
declare function local:options(){
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>1</phrase-slop>
        <leading-wildcard>no</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
};

(:
if($q != '') then local:search-name()
else ()
:)
if($q != '' or $idno != '') then local:search()
else ()