xquery version "3.0";

(:~
 : Passes content to content negotiation module, if not using restxq
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2018-04-12
:)

import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";

(: Content serialization modules. :)
import module namespace cntneg="http://srophe.org/srophe/cntneg" at "content-negotiation.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "tei2html.xqm";

(: Data processing module. :)
import module namespace data="http://srophe.org/srophe/data" at "../lib/data.xqm";

(: Import KWIC module:)
import module namespace kwic="http://exist-db.org/xquery/kwic";

(: Namespaces :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http="http://expath.org/ns/http-client";

declare variable $start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $perpage {request:get-parameter('perpage', 20) cast as xs:integer};
declare variable $sort {request:get-parameter('sort-element', '') cast as xs:string};


let $path := if(request:get-parameter('id', '')  != '') then 
                request:get-parameter('id', '')
             else if(request:get-parameter('doc', '') != '') then
                request:get-parameter('doc', '')
             else ()   
let $format := if(request:get-parameter('format', '') != '') then request:get-parameter('format', '') else 'xml'
return
    if(request:get-parameter('id', '') != '' or request:get-parameter('doc', '') != '') then
        cntneg:content-negotiation(data:get-document(), $format, $path)
    else if(request:get-parameter-names() != '') then
        let $hits := data:search('','',$sort)
        return 
        if($format=('json','JSON')) then
            (response:set-header("Content-Type", "application/json; charset=utf-8"),
            response:set-header("Access-Control-Allow-Origin", "application/json; charset=utf-8"),
            serialize(
                <root>
                    <action>{request:get-query-string()}</action>
                    <info>hits: {count($hits)}</info>
                    <start>{$start}</start>
                    <results>{
                            for $h in subsequence($hits,$start,$perpage)
                            let $id := replace($h/descendant::tei:idno[starts-with(.,$config:base-uri)][1],'/tei','')
                            let $title := $h/descendant::tei:titleStmt/tei:title
                            let $expanded := kwic:expand($h)
                            return 
                                <json:value json:array="true">
                                    <id>{$id}</id>
                                    {$title}
                                    <hits>{normalize-space(string-join((tei2html:output-kwic($expanded, $id)),' '))}</hits>
                                </json:value>
                            }</results>
                    </root>, 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                </output:serialization-parameters>)) 
        else 
            <results total="{count($hits)}" search-string="{request:get-query-string()}" next="{$start + $perpage}" id="result">{
                for $h at $i in subsequence($hits,($start + 1),$perpage) 
                return 
                <div class="dynamicSearchResult">
                    <span class="num">{($start + $i) - 1}. </span>
                    {cntneg:content-negotiation($h, 'html-summary', $path)}
                </div>
            }</results> 
    else ()                    
    