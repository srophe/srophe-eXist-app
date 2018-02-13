xquery version "3.0";


import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

declare variable $collection {
    if(request:get-parameter('collection', '') != '') then string(request:get-parameter('collection', ''))
    else '/db/apps/tcadrt-data/data'
    };

<list>{
    for $r in distinct-values(for $r in collection($collection)//tei:relation return $r/@ref)
    return 
        <option label="{if(contains($r,':')) then substring-after($r,':') else $r}" value="{$r}"/>
        }
</list>