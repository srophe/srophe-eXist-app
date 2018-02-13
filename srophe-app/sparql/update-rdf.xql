xquery version "3.1";
(:~
 : XQuery RDF generation
 : Checks for updates since last modified version using:
     eXistdb's xmldb:find-last-modified-since($node-set as node()*, $since as xs:dateTime) as node()*
 : Converts TEI records to RDF using $global:public-view-base/modules/lib/rei2rdf.xqm 
 : Adds new RDF records to RDF store.
 :
:)

import module namespace http="http://expath.org/ns/http-client";
import module namespace global="http://syriaca.org/global" at "../modules/lib/global.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "../modules/lib/tei2rdf.xqm ";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: Can I store the last modified date in the script? :)
declare variable $rdf-config := if(doc('config.xml')) then doc('zotero-config.xml') else ();
declare variable $last-modified-version := $rdf-config//rdf/last-modified/text();

(: Update RDF :)
declare function local:update-rdf(){
let $action := request:get-parameter('action', '')
let $collection := request:get-parameter('collection', '')
return 
    if($action = 'initiate') then
        local:get-records($action,$collection,())
    else if(request:get-parameter('action', '') = 'update') then
        <response status="200" xmlns="http://www.w3.org/1999/xhtml">
            <message>Update!</message>
        </response>
    else 
        <response status="400" xmlns="http://www.w3.org/1999/xhtml">
            <message>You did not give me any directions.</message>
        </response>
};

declare function local:get-records($action as xs:string?, $collection as xs:string?, $date as xs:dateTime?){
    if($action = 'initiate') then
        let $records := 
            if($collection != '') then 
                (: Special handling for SPEAR, to process every div[@uri] as a record. :)
                if($collection = 'spear') then
                    for $r in collection($global:data-root || '/' || $collection)//tei:div[@uri][ancestor::tei:TEI/descendant::tei:title[. = 'Chronicle of Edessa']]
                    let $teiHeader := root($r)//tei:teiHeader
                    return 
                        <tei:TEI xmlns="http://www.tei-c.org/ns/1.0">{($teiHeader,$r)}</tei:TEI> 
                else collection($global:data-root || '/' || $collection)/tei:TEI 
            else collection($global:data-root)/tei:TEI
        let $total := count($records)
        let $perpage := 50
        let $pages := xs:integer($total div $perpage)
        let $start := 0
        return 
            <response status="200" xmlns="http://www.w3.org/1999/xhtml">
                <message style="margin:1em;padding:1em; border: 1px solid #eee; display:block;">
                    <strong>Total: </strong>{$total}<br/>
                    <strong>Per page: </strong>{$perpage}<br/>
                    <strong>Pages: </strong>{$pages}<br/>
                    <strong>Collection: </strong>{$collection}<br/>
                </message>
                <output>{local:process-results($records, $total, $start, $perpage, $collection)}</output>
            </response>
    else if($action = 'update') then 
        let $records := 
            if($collection != '') then 
                collection($global:data-root || '/' || $collection)/tei:TEI[xmldb:find-last-modified-since(., xs:dateTime($date))] 
            else collection($global:data-root)/tei:TEI[xmldb:find-last-modified-since(., xs:dateTime($date))]
        let $total := count($records)
        let $perpage := 50
        let $pages := xs:integer($total div $perpage)
        let $start := 0
        return 
            <response status="200" xmlns="http://www.w3.org/1999/xhtml">
                <message style="margin:1em;padding:1em; border: 1px solid #eee; display:block;">
                    <strong>Total: </strong>{$total}<br/>
                    <strong>Per page: </strong>{$perpage}<br/>
                    <strong>Pages: </strong>{$pages}<br/>
                    <strong>Collection: </strong>{$collection}<br/>
                </message>
                <output>{local:process-results($records, $total, $start, $perpage, $collection)}</output>
            </response>            
    else 
        <response status="200" xmlns="http://www.w3.org/1999/xhtml">
            <message>There is no other hand.</message>
        </response>
};

declare function local:process-results($records as item()*, $total, $start, $perpage, $collection){
    let $end := $start + $perpage
    return
        (    
         (: Process collection records :)
         for $r in subsequence($records,$start,$perpage)
         let $id := 
                if($r/descendant-or-self::tei:div[@uri]) then 
                    string($r/descendant-or-self::tei:div[@uri][1]/@uri) 
                else replace($r/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei','')
         let $uri := document-uri(root($r))
         let $rdf := tei2rdf:rdf-output($r)
         let $file-name := substring-before(tokenize($uri,'/')[last()],'.xml')
         let $collection := replace(substring-before($uri, $file-name),'/tei/','')
         let $repository := replace($global:app-root,'/db/apps/','')
         let $rdf-collection := if($collection = 'spear' or $r/descendant-or-self::tei:div[@uri]) then 'spear' else replace(replace(substring(substring-after($collection, $global:data-root),2),'tei',''),'/','-')
         let $rdf-filename := concat(replace(substring-after($id,'http://'),'/|\.','-'),'.rdf')
         let $rdf-path := concat($repository,'/',$rdf-collection) 
         return  
             try {
                 <response status="200" xmlns="http://www.w3.org/1999/xhtml">
                     <message>{(
                             (: Check for local collection :)
                            if(xmldb:collection-available('/db/rdftest/' || $rdf-path)) then ()
                            else local:mkcol("/db/rdftest", $rdf-path),
                            xmldb:store('/db/rdftest/' || $rdf-path, xmldb:encode-uri($rdf-filename), $rdf)
                     )}</message>
                 </response>
                 } catch *{
                 <response status="fail" xmlns="http://www.w3.org/1999/xhtml">
                     <message>Failed to add resource {$rdf-filename}: {concat($err:code, ": ", $err:description)}</message>
                 </response>
                 },
         (: Go to next :)        
         if($total gt $end) then 
             local:process-results($records, $total, $end, $perpage, $collection)
         else ()
         )            
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

(: Create rdf collection if it does not exist. :)
declare function local:build-collection-rdf(){
    let $rdf-coll := xmldb:create-collection("/db", "rdftest")
    let $rdf-conf-coll := xmldb:create-collection("/db/system/config/db", "rdftest")
    let $rdf-conf :=
        <collection xmlns="http://exist-db.org/collection-config/1.0">
           <index xmlns:xs="http://www.w3.org/2001/XMLSchema">
              <rdf />
           </index>
        </collection>
    return xmldb:store($rdf-conf-coll, "collection.xconf", $rdf-conf)
};

(:~
 : Check action parameter, if empty, return contents of config.xml
 : If $action is not empty, check for specified collection, create if it does not exist. 
 : Run Zotero request. 
:)
if(request:get-parameter('action', '') != '') then
    if(xmldb:collection-available('/db/rdftest')) then
        <response xmlns="http://www.w3.org/1999/xhtml">{ local:update-rdf() }</response>
    else <response xmlns="http://www.w3.org/1999/xhtml">{ (local:build-collection-rdf(),local:update-rdf()) }</response>
else if(request:get-parameter('id', '') != '') then
     let $rec := collection($global:data-root)/tei:TEI[descendant::tei:idno[. = request:get-parameter('id', '')]]
     return 
        if(xmldb:collection-available('/db/rdftest')) then         
            <response xmlns="http://www.w3.org/1999/xhtml">{ local:process-results($rec, 1,1,1,()) }</response>
        else <response xmlns="http://www.w3.org/1999/xhtml">{(: (local:build-collection-rdf(),local:update-rdf()) :) 'Error'}</response>

else 
    <div xmlns="http://www.w3.org/1999/xhtml">
        <p><label>Last Updated: </label> {$last-modified-version}</p>
    </div>