xquery version "3.0";

module namespace geojson="http://syriaca.org/geojson";
(:~
 : Module returns coordinates as geoJSON
 : Formats include geoJSON 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)

import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:~
 : Serialize XML as JSON
:)
declare function geojson:geojson($nodes as node()*){
    xqjson:serialize-json(geojson:json-wrapper($nodes))
};

(:~
 : Build root element for geojson output
:)
declare function geojson:json-wrapper($nodes as node()*) as element()*{
<json type="object">
    <pair name="type" type="string">FeatureCollection</pair>
    <pair name="features"  type="array">
        {
             for $n in $nodes[descendant-or-self::tei:geo]
             return geojson:geojson-object($n)
        }
    </pair>
</json>
};

(:~
 : Build geoJSON object for each node with coords
 : Sample data passed to geojson-object
  <place xmlns="http://www.tei-c.org/ns/1.0">
    <idno></idno>
    <title></title>
    <desc></desc>
    <location></location>  
  </place>
:)
declare function geojson:geojson-object($node as node()*) as element()*{
let $id := if($node//tei:idno[@type='URI']) then $node//tei:idno[@type='URI'][1]
           else $node//tei:idno[1]
let $title := if($node/descendant::*[@syriaca-tags="#syriaca-headword"]) then $node/descendant::*[@syriaca-tags="#syriaca-headword"][1] 
              else $node//tei:title[1]
let $desc := if($node/descendant::tei:desc[1]/tei:quote) then 
                concat('"',$node/descendant::tei:desc[1]/tei:quote,'"')
             else $node//tei:desc[1]
let $type := if($node//tei:relationType != '') then 
                string($node//tei:relationType)
              else if($node//tei:place/@type) then 
                string($node//tei:place/@type)
              else ()   
let $coords := $node//tei:geo[1]
return 
<item type="object">
    <pair name="type" type="string">Feature</pair>
    <pair name="geometry" type="object">
        <pair name="type" type="string">Point</pair>
        <pair name="coordinates"  type="array">
            <item type="number">{substring-after($coords,' ')}</item>
            <item type="number">{substring-before($coords,' ')}</item>
        </pair>
    </pair>
    <pair name="properties"  type="object">
        <pair name="uri" type="string">{replace($id,'/tei','')}</pair>
        <pair name="name" type="string">{string-join($title,' ')}</pair>
        {if($desc != '') then
            <pair name="desc" type="string">{string-join($desc,' ')}</pair> 
        else(),
        if($type != '') then
            <pair name="type" type="string">{$type}</pair> 
        else ()
        }
        
    </pair>
</item>
};