xquery version "3.0";
(:~
 : Shared functions for search modules 
 :)
module namespace rec="http://syriaca.org/short-rec-view";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";


(:
 : Function to truncate description text after first 12 words
 : @param $string
:)
declare function rec:truncate-string($str as xs:string*) as xs:string? {
let $string := string-join($str, ' ')
return 
    if(count(tokenize($string, '\W+')[. != '']) gt 12) then 
        let $last-words := tokenize($string, '\W+')[position() = 14]
        return concat(substring-before($string, $last-words),'...')
    else $string
};

(: 
 : Formats search and browse results 
 : Uses English and Syriac headwords if available, tei:teiHeader/tei:title if no headwords.
 : Should handle all data types, and eliminate the need for 
 : data type specific display functions eg: persons:saints-results-node()
 : @param $node search/browse hits should be either tei:person, tei:place, or tei:body
 : Used by search.xqm, browse.xqm and get-related.xqm
:)
declare function rec:display-recs-short-view($node, $lang) as node()*{
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