xquery version "3.1";
(:~  
 : Build GeoJSON file for all placeNames/@key  
 : NOTE: Save file to DB, rerun occasionally? When new data is added? 
 : Run on webhook activation, add new names, check for dups. 
:)

import module namespace config="http://srophe.org/srophe/config" at "config.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "content-negotiation/tei2html.xqm";
import module namespace http="http://expath.org/ns/http-client";

import module namespace functx="http://www.functx.com";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";

declare function local:persons($nodes as node()*){
    <listPerson xmlns="http://www.tei-c.org/ns/1.0">
        {
           for $n in $nodes
           return 
                <person ref="{replace($n/descendant::tei:publicationStmt[1]/tei:idno[@type="URI"][1],'/tei','')}"></person>
        }
    </listPerson>
};

declare function local:places($nodes as node()*){
    <listPlace xmlns="http://www.tei-c.org/ns/1.0">
        {
           for $n in $nodes
           return 
                <place ref="{replace($n/descendant::tei:publicationStmt[1]/tei:idno[@type="URI"][1],'/tei','')}"></place>
        }
    </listPlace>
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

if(request:get-parameter('action', '') = 'create') then
    try {    
        if(request:get-parameter('content', '') = 'persons') then
            let $records := collection($config:data-root || '/persons')
            let $f := local:persons($records)
            return 
                if(xmldb:collection-available(concat($config:app-root,'/documentation/indexes'))) then
                    xmldb:store(concat($config:app-root,'/documentation/indexes'), xmldb:encode-uri('persons.xml'), $f)
                else (local:mkcol(concat($config:app-root,'/documentation'),'indexes'), xmldb:store(concat($config:app-root,'/documentation/indexes'), xmldb:encode-uri('persons.xml'), $f)) 
        else if(request:get-parameter('content', '') = 'places') then
            let $records := collection($config:data-root || '/places')
            let $f := local:places($records)
            return 
                if(xmldb:collection-available(concat($config:app-root,'/documentation/indexes'))) then
                    xmldb:store(concat($config:app-root,'/documentation/indexes'), xmldb:encode-uri('places.xml'), $f)
                else (local:mkcol(concat($config:app-root,'/documentation'),'indexes'), xmldb:store(concat($config:app-root,'/documentation/indexes'), xmldb:encode-uri('places.xml'), $f))
        else if(request:get-parameter('content', '') = 'subjects') then
            <div>In progress</div>
        else ()
    } catch *{
        <response status="fail">
            <message>{concat($err:code, ": ", $err:description)}</message>
        </response>
    } 
else <div>In process</div>
