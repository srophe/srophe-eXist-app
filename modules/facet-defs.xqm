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
    else if($collection = ('persons','sbd','authors','q')) then
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Type">
            <group-by function="facet:group-by-sub-module">
                <sub-path>descendant::tei:seriesStmt/tei:biblScope/tei:idno</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="descending">count</order-by>
        </facet-definition>
        <facet-definition name="Century">
            <range type="xs:year">
                <bucket lt="0001" name="BC dates" order='22'/>
                <bucket gt="0001-01-01" lt="0100-01-01" name="1-100" order='21'/>
                <bucket gt="0100-01-01" lt="0200-01-01" name="100-200" order='20'/>
                <bucket gt="0200-01-01" lt="0300-01-01" name="200-300" order='19'/>
                <bucket gt="0300-01-01" lt="0400-01-01" name="300-400" order='18'/>
                <bucket gt="0400-01-01" lt="0500-01-01" name="400-500" order='17'/>
                <bucket gt="0500-01-01" lt="0600-01-01" name="500-600" order='16'/>
                <bucket gt="0600-01-01" lt="0700-01-01" name="600-700" order='15'/>
                <bucket gt="0700-01-01" lt="0800-01-01" name="700-800" order='14'/>
                <bucket gt="0800-01-01" lt="0900-01-01" name="800-900" order='13'/>
                <bucket gt="0900-01-01" lt="1000-01-01" name="900-1000" order='12'/>
                <bucket gt="1000-01-01" lt="1100-01-01" name="1000-1100" order='11'/>
                <bucket gt="1100-01-01" lt="1200-01-01" name="1100-1200" order='10'/>
                <bucket gt="1200-01-01" lt="1300-01-01" name="1200-1300" order='9'/>
                <bucket gt="1300-01-01" lt="1400-01-01" name="1300-1400" order='8'/>
                <bucket gt="1400-01-01" lt="1500-01-01" name="1400-1500" order='7'/>
                <bucket gt="1500-01-01" lt="1600-01-01" name="1500-1600" order='6'/>
                <bucket gt="1600-01-01" lt="1700-01-01" name="1600-1700" order='5'/>
                <bucket gt="1700-01-01" lt="1800-01-01" name="1700-1800" order='4'/>
                <bucket gt="1800-01-01" lt="1900-01-01" name="1800-1900" order='3'/>
                <bucket gt="1900-01-01" lt="2000-01-01" name="1900-2000" order='2'/>
                <bucket gt="2000-01-01" name="2000 +" order="1"/>
            </range>
            <group-by type="xs:date">
                <sub-path>/@syriaca-computed-start</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="descending">order</order-by>
        </facet-definition>
        <facet-definition name="Sex or Gender">
            <group-by>
                <sub-path>descendant::tei:sex/text()</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Has name in">
            <group-by function="facet:controlled-labels">
                <sub-path>descendant::tei:person/tei:persName/@xml:lang</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Born">
            <group-by>
                <sub-path>descendant::tei:relation[@name="born-at"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Died">
            <group-by>
                <sub-path>descendant::tei:relation[@name="died-at"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Literary Connection">
            <group-by function="facet:group-by-array">
                <sub-path>descendant::tei:relation[@name="has-literary-connection-to-place"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>        
        <facet-definition name="Unspecified Connection">
            <group-by function="facet:group-by-array">
                <sub-path>descendant::tei:relation[@name="has-relation-to-place"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>            
        <facet-definition name="Office">
            <group-by>
                <sub-path>descendant::tei:state[@type="office"]/@role</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Saint type">
            <group-by>
                <sub-path>descendant::tei:state[@type="saint"]/@role</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Occupation">
            <group-by>
                <sub-path>descendant::tei:state[@type="occupation"]/@role</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
    </facets> 
    else if($collection = 'bhse') then
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Type">
            <group-by function="facet:group-by-sub-module">
                <sub-path>descendant::tei:seriesStmt/tei:biblScope/tei:idno</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="descending">count</order-by>
        </facet-definition>
        <facet-definition name="Commemorated">
            <group-by function="facet:group-by-array">
                <sub-path>descendant::tei:relation[@name="syriaca:commemorated"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>        
        <facet-definition name="Sources">
            <group-by>
                <sub-path>descendant::tei:body/tei:bibl/tei:bibl/tei:ptr/@target</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
    </facets> 
    else if($collection = 'spear') then
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Place">
            <group-by>
                <sub-path>descendant::tei:placeName/@ref</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="descending">count</order-by>
        </facet-definition>
        <facet-definition name="Person">
        <!--function="facet:group-name" -->
            <group-by>
                <sub-path>descendant::tei:persName/@ref</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition> 
        <facet-definition name="Sex or Gender">
            <group-by>
                <sub-path>descendant::tei:sex/@value</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Born">
            <group-by>
                <sub-path>descendant::tei:relation[@name="born-at"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Died">
            <group-by>
                <sub-path>descendant::tei:relation[@name="died-at"]/@passive</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Keyword">
            <group-by function="facet:group-by-array">
                <sub-path>descendant::*/@*[contains(.,'/keyword/')]</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
            <facet-definition name="Type">
            <group-by function="facet:spear-type">
                <sub-path>child::*[1]/name(.)</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Source Text">
            <group-by function="facet:spear-source-text">
                <sub-path>ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
    </facets>
    else if($collection = 'spear-sources') then 
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Source Text">
            <group-by function="facet:spear-source-text">
                <sub-path>ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
        <facet-definition name="Type">
            <group-by function="facet:spear-type">
                <sub-path>child::*[1]/name(.)</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
    </facets> 
    else if($collection = 'spear-events') then 
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Source Text">
            <group-by function="facet:spear-source-text">
                <sub-path>ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
            <facet-definition name="Keyword">
            <group-by function="facet:group-by-array">
                <sub-path>descendant::*/@*[contains(.,'/keyword/')]</sub-path>
            </group-by>
            <max-values show="5">40</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
    </facets> 
    else if($collection = 'spear-keywords') then 
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Keyword">
            <group-by function="facet:group-by-array">
                <sub-path>descendant::*/@*[contains(.,'/keyword/')]</sub-path>
            </group-by>
            <max-values show="5">100</max-values>
            <order-by direction="ascending">count</order-by>
        </facet-definition>
    </facets> 
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
    else if($collection = 'manuscripts') then 
    <facets xmlns="http://expath.org/ns/facet">
        <facet-definition name="Repository">
            <group-by>
                <sub-path>descendant::tei:repository</sub-path>
            </group-by>
            <max-values show="5">50</max-values>
            <order-by direction="descending">count</order-by>
        </facet-definition>
        <facet-definition name="Country">
            <group-by>
                <sub-path>descendant::tei:country</sub-path>
            </group-by>
            <max-values show="5">50</max-values>
            <order-by direction="descending">count</order-by>
        </facet-definition>
    </facets> 
    else ()
};