xquery version "3.1";


import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
(:
declare option output:method "json";
declare option output:media-type "application/json";
:)

declare variable $id {request:get-parameter('id', '')};
declare variable $relationship {request:get-parameter('relationship', '')};
declare variable $type {request:get-parameter('type', '')};
declare variable $all-relationships {
    if(contains($relationship,'Select relationship') or contains($relationship,'All') or $relationship = '') then true() 
    else false()};

(: collection to query :)
declare variable $collection {
    if(request:get-parameter('collection', '') != '') then string(request:get-parameter('collection', ''))
    else '/db/apps/tcadrt-data/data'
    };

declare function local:get-relationship($relationship, $id){
    let $id := concat($id,'(\W.*)?$')
    return 
        if($all-relationships = false()) then
            if($id != '') then
                collection($collection)//tei:relation[@ref=$relationship][@passive[matches(.,$id)] or 
                    @active[matches(.,$id)] or
                    @mutual[matches(.,$id)]]
            else collection($collection)//tei:relation[@ref=$relationship]
        else if($id != '') then
                collection($collection)//tei:relation[@passive[matches(.,$id)] or 
                    @active[matches(.,$id)] or
                    @mutual[matches(.,$id)]]
        else collection($collection)//tei:relation
};

(: Output based on d3js requirements for producing an HTML table:)
declare function local:format-table($relationships){        
        <root>{
                (
                <head>{
                for $attr in $relationships[1]/@* 
                return <vars>{name($attr)}</vars>
                }</head>,
                <results>{
                for $r in $relationships 
                return $r
                }</results>)
            }
        </root>
};

(: Output based on d3js requirements for producing a d3js tree format, single nested level, gives collection overview :)
declare function local:format-tree-types($relationships){
    <root>
        <data>
            <children>
                {
                    for $r in $relationships
                    let $group := if($r/@ref) then $r/@ref else $r/@name
                    group by $type := $group
                    order by count($r) descending
                    return 
                        <json:value>
                            <name>{string($type)}</name>
                            <size>{count($r)}</size>
                         </json:value>
                 }
            </children>
        </data>
    </root>
};

(: output based on d3js requirements :)
declare function local:format-relationship-graph($relationships){
    let $uris := distinct-values((
                    for $r in $relationships return tokenize($r/@active,' '), 
                    for $r in $relationships return tokenize($r/@passive,' '), 
                    for $r in $relationships return tokenize($r/@mutual,' ')
                    )) 
    return 
        <root>
            <nodes>
                {
                for $uri in $uris
                return
                    <json:value>
                        <id>{$uri}</id>
                        <label>{$uri}</label>
                   </json:value>
                }
            </nodes>
            <links>
                {
                    for $r in $relationships
                    return 
                        if($r/@mutual) then 
                             for $m in tokenize($r/@mutual,' ')
                             return 
                                 let $node := 
                                     for $p in tokenize($r/@mutual,' ')
                                     where $p != $m
                                     return 
                                         <json:value>
                                             <source>{$m}</source>
                                             <target>{$p}</target>
                                             <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                             <value>0</value>
                                         </json:value>
                                 return $node
                        else if(contains($r/@active,' ')) then 
                                (: Check passive for spaces/multiple values :)
                                if(contains($r/@passive,' ')) then 
                                    for $a in tokenize($r/@active,' ')
                                    return 
                                        for $p in tokenize($r/@passive,' ')
                                        return 
                                           <json:value>
                                                <source>{string($p)}</source>
                                                <target>{string($a)}</target>
                                                <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value> 
                                (: multiple active, one passive :)
                                else 
                                    let $passive := string($r/@passive)
                                    for $a in tokenize($r/@active,' ')
                                    return 
                                            <json:value>
                                                <source>{string($passive)}</source>
                                                <target>{string($a)}</target>
                                                <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value>
                            (: One active multiple passive :)
                            else if(contains($r/@passive,' ')) then 
                                    let $active := string($r/@active)
                                    for $p in tokenize($r/@passive,' ')
                                    return 
                                            <json:value>
                                            {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                                                <source>{string($p)}</source>
                                                <target>{string($active)}</target>
                                                <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value>
                                (: One active one passive :)            
                            else 
                                    <json:value>
                                    {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                                        <source>{string($r/@passive)}</source>
                                        <target>{string($r/@active)}</target>
                                        <relationship>{replace($r/@ref,'^(.*?):','')}</relationship>
                                        <value>0</value>
                                    </json:value>
                }
            </links>
        </root>
};

let $data := 
    if($type = ('Force','Sankey')) then 
        local:format-relationship-graph(local:get-relationship($relationship, $id))
    else if($type = ('Table','table','Bundle')) then 
        local:format-table(local:get-relationship($relationship, $id))
    else if($type = ('Tree','Round Tree','Circle Pack','Bubble')) then 
        local:format-tree-types(local:get-relationship($relationship, $id))
    else if($type = ('Bar Chart','Pie Chart')) then
        local:format-tree-types(local:get-relationship($relationship, $id))   
    else local:format-table(local:get-relationship($relationship, $id)) 
return 
    if(request:get-parameter('format', '') = ('json','JSON')) then
        (serialize($data, 
                    <output:serialization-parameters>
                        <output:method>json</output:method>
                    </output:serialization-parameters>),
                    response:set-header("Content-Type", "application/json"))        
    else $data  