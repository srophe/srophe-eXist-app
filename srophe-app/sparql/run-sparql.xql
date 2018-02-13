xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace global="http://syriaca.org/global" at "../modules/lib/global.xqm";
import module namespace sprql-queries="http://syriaca.org/sprql-queries" at "sparql.xqm";
declare namespace sparql="http://www.w3.org/2005/sparql-results#";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $qname {request:get-parameter('qname', '')};
declare variable $id {request:get-parameter('id', '')};

declare function local:sparql-JSON($results){
    for $node in $results
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(sparql:variable) return element vars {string($node/@*:name)}
            case element(sparql:result) return element bindings {local:sparql-JSON($node/node())}
            case element(sparql:binding) return element {$node/@*:name} {
                for $n in $node/node()
                return 
                    (element type {local-name($n)},
                     element value {normalize-space($n/text())},
                     if($n/@xml:lang) then 
                        element {xs:QName('xml:lang')} {string($n/@xml:lang)}
                     else()
                    )
            }
            case element() return local:passthru($node)
            default return local:sparql-JSON($node/node())
};

(:~
 : Output d3js relationship graph
:)
declare function local:sparql-relationship-graph($results){
    for $node in $results
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(sparql:variable) return element vars {string($node/@*:name)}
            case element(sparql:result) return element bindings {local:sparql-JSON($node/node())}
            case element(sparql:binding) return element {$node/@*:name} {
                for $n in $node/node()
                return 
                    (element type {local-name($n)},
                     element value {normalize-space($n/text())},
                     if($n/@xml:lang) then 
                        element {xs:QName('xml:lang')} {string($n/@xml:lang)}
                     else()
                    )
            }
            case element() return local:passthru($node)
            default return local:sparql-JSON($node/node())
};


declare function local:passthru($node as node()*) as item()* { 
    element {name($node)} {($node/@*, local:sparql-JSON($node/node()))}
};

if($qname != '') then
    if($qname = 'related-subjects-count') then
        sprql-queries:related-subjects-count($id)
    else if($qname = 'related-subjects') then 
        sprql-queries:related-subjects($id)    
    else if($qname = 'related-citations-count') then
        sprql-queries:related-citations-count($id) 
    else if($qname = 'label') then
        sprql-queries:label($id) 
    else if($qname = 'test') then
        sprql-queries:test-q()      
    else <message>Submitted query is not a valid Syriaca.org named query. Please use the qname paramater to submit a custom SPARQL query. {$qname}</message>
else if(request:get-parameter('sparql', '')) then
    let $results := sprql-queries:run-query(request:get-parameter('sparql', ''))
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then              
            (serialize(local:sparql-JSON($results), 
                    <output:serialization-parameters>
                        <output:method>json</output:method>
                    </output:serialization-parameters>),
                    response:set-header("Content-Type", "application/json"))
        else $results          
else if(not(empty(request:get-data()))) then
    let $results := sprql-queries:run-query(request:get-data())
    return 
        if(request:get-parameter('format', '') = ('json','JSON')) then             
            (serialize(local:sparql-JSON($results), 
                    <output:serialization-parameters>
                        <output:method>json</output:method>
                    </output:serialization-parameters>),
                    response:set-header("Content-Type", "application/json"))
        else
            serialize($results, 
                    <output:serialization-parameters>
                        <output:method>xml</output:method>
                    </output:serialization-parameters>)                   
else <message>No query data submitted</message>
