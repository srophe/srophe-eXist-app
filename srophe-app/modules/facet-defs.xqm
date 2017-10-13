(:~    
 : Builds Facet definitions for each submodule. 
 :)
xquery version "3.0";

module namespace facet-defs="http://syriaca.org/facet-defs";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace facet = "http://expath.org/ns/facet";


declare function facet-defs:facet-definition($collection as xs:string?, $facets as xs:string?){
if($facets != '') then 
        doc(concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/',$facets))/facet:facets
else facet-defs:facet-definition($collection)
};

declare function facet-defs:facet-definition($collection as xs:string?){
    if(doc(concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/facet-def.xml'))) then 
        doc(concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/facet-def.xml'))//facet:facets
    else if($collection = ('places','bethqatraye')) then 
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Type">
            <group-by function="facet:group-place-type">
                <sub-path>descendant::tei:place/@type</sub-path>
            </group-by>
            <max-values show="100">100</max-values>
            <order-by direction="descending">count</order-by>
        </facet-definition>
    </facets>    
    else ()
};