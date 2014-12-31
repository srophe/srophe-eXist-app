(:~
 : Builds place page and place page functions
 :)
xquery version "3.0";

module namespace place="http://syriaca.org//place";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace transform="http://exist-db.org/xquery/transform";

(:~ 
 : Parameters passed from the url 
 :)
declare variable $place:id {request:get-parameter('id', '')};
declare variable $place:status {request:get-parameter('status', '')};

(:~
 : Retrieve place record
 : @param $id place id
 :)
declare function place:get-place-rec(){
    let $placeCollection := "/data/places/tei"
    let $placeid := concat('place-',$place:id)
    for $recs in collection($config:app-root || $placeCollection)/id($placeid)
    let $rec := $recs/ancestor::tei:TEI
    return $rec
};


(:~
 : Adds place data to map function
 :)
declare function place:get-place($node as node(), $model as map(*)){
    let $rec-data := place:get-place-rec()
    return
        map {"place-data" := $rec-data}
};

(:~
 : Retrieve place title for metadata function.
 : Function is called by metadata.xqm
 :)
declare function place:get-place-title(){
    let $title := string(place:get-place-rec()/child::*/tei:fileDesc/tei:titleStmt/tei:title[1])
    return concat('The Syriac Gazetteer: ',$title)
};

(:~
 : Builds Dublin Core metadata.
 : Function is called by metadata.xqm
 :)
declare function place:get-metadata() {
    for $rec in place:get-place-rec()
    let $description := if(exists($rec/descendant::tei:place/tei:desc[starts-with(@xml:id,'abstract')])) then
                            <meta name="description" content="{$rec/descendant::tei:place/tei:desc[starts-with(@xml:id,'abstract')]/text()}" />
                        else ''    
    let $title :=  <meta name="DC.title" property="dc.title" lang="en" content="{string($rec/child::*/tei:fileDesc/tei:titleStmt/tei:title[1])}"/>                       
    let $authors := let $author-name := distinct-values($rec/descendant::tei:titleStmt/tei:editor) 
                    for $author in $author-name
                    return <meta name="DC.creator" property="dc.creator" lang="en" content="{$author}" />
    let $contributors := let $contrib-name := distinct-values($rec/descendant::tei:titleStmt/tei:respStmt/tei:name) 
                         for $contributor in $contrib-name                        
                         return    <meta name="DC.contributor" property="dc.contributor" lang="en" content="{$contributor}" />              
                        
    let $identifier := <meta name="DC.identifier" property="dc.identifier" content="http://syriaca.org/place/{$place:id}" />
    let $rights := (<meta name="DC.rights" property="dc.rights" lang="en"  content="{normalize-space(string-join($rec/descendant::tei:publicationStmt/tei:availability/tei:licence/tei:p,' '))}"/>,
                    <meta name="DCTERMS.license" property="dcterms.license" content="http://creativecommons.org/licenses/by/3.0/" />)
    let $date :=     <meta name="DC.date" property="dc.date" lang="en" content="{$rec/descendant::tei:publicationStmt/tei:date}" />
    return ($description,$title,$contributors,$authors,$identifier,$rights,$date)
        
};

(:~
 : Get nested locations
 : Pull all places records with @type="nested" and also references current place id in @ref
 :            <location type="nested" source="#bib110-3">
 :              <region ref="http://syriaca.org/place/722">Mosul region</region>
 :           </location>       
:)
declare function place:get-nested-loc(){
    let $ref-id := concat('http://syriaca.org/place/',$place:id)
    for $nested-loc in collection($config:app-root || "/data/places/tei")//tei:location[@type="nested"]/tei:*[@ref=$ref-id]
    let $parent-name := $nested-loc//tei:placeName[1]
    let $place-id := substring-after($nested-loc/ancestor::*/tei:place[1]/@xml:id,'place-')
    let $place-type := $nested-loc/ancestor::*/tei:place[1]/@type
    return
    <nested-place id="{$place-id}" type="{$place-type}">
        {$nested-loc/ancestor::*/tei:placeName[1]}
    </nested-place>
};

declare function place:get-confessions(){
    let $confessions := doc($config:app-root || "/documentation/confessions.xml")//tei:list
    return
    <confessions xmlns="http://www.tei-c.org/ns/1.0">
        {$confessions}
    </confessions>
 };
 
(:~
 : Get related place names
 : <relation name="contained" active="http://syriaca.org/place/145 http://syriaca.org/place/166" passive="#place-78" source="#bib78-1" to="0363"/>
:)
declare function place:get-related-places($rec as node()*){
    <related-items>
        {
            for $related in $rec//tei:relation
            let $active := 
                for $rel-item in tokenize($related/@active,' ')
                let $item-id := tokenize($rel-item, '/')[last()]
                let $item-uri := $rel-item
                let $place-id := concat('place-',$item-id)
                return
                    <relation id="{$item-id}" uri="{$item-uri}" varient="active">
                    {
                        (for $att in $related/@*
                            return
                                 attribute {name($att)} {$att},                      
                        for $get-related in collection($config:app-root || "/data/places/tei")/id($place-id)
                        return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                    }
                    </relation>
            let $passive := 
                for $rel-item in tokenize($related/@passive,' ')
                let $item-id := tokenize($rel-item, '/')[last()]
                let $item-uri := $rel-item
                let $place-id := concat('place-',$item-id)
                return
                    <relation id="{$item-id}" uri="{$item-uri}" varient="passive">
                    {
                        (for $att in $related/@*
                            return
                                 attribute {name($att)} {$att},                      
                        for $get-related in collection($config:app-root || "/data/places/tei")/id($place-id)
                        return $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en'])
                    }
                    </relation>
            let $mutual := 
                    if($related/@mutual) then
                    let $mutual-string := normalize-space($related/@mutual)
                    return
                        <relation varient="mutual">
                            {
                                for $rel-item in tokenize($mutual-string,' ')
                                let $item-id := tokenize($rel-item, '/')[last()]
                                let $item-uri := $rel-item
                                let $place-id := concat('place-',$item-id)
                                return
                                    <mutual id="{$item-id}">{
                                    (for $att in $related/@*
                                    return
                                         attribute {name($att)} {$att},                      
                                    for $get-related in collection($config:app-root || "/data/places/tei")/id($place-id)
                                    let $type := string($get-related/@type)
                                    return 
                                        (attribute type {$type}, $get-related/tei:placeName[@syriaca-tags='#syriaca-headword'][@xml:lang='en']))
                                    }
                                    </mutual>
                            }
                        </relation>
                      else ''  

            return ($active,$passive,$mutual)
        }
    </related-items>
};

(:~ 
 : Pull together place page data   
 : Adds related places and nested locations to full TEI document
 : Passes xml to placepage.xsl for html transformation
:)
declare %templates:wrap function place:get-place-data($node as node(), $model as map(*)){
   for $rec in $model("place-data")
   let $buildRec :=
                <TEI
                    xml:lang="en"
                    xmlns:xi="http://www.w3.org/2001/XInclude"
                    xmlns:svg="http://www.w3.org/2000/svg"
                    xmlns:math="http://www.w3.org/1998/Math/MathML"
                    xmlns="http://www.tei-c.org/ns/1.0">
                    {
                        ($rec/child::*, place:get-related-places($rec),place:get-nested-loc(),place:get-confessions())
                    }
                    </TEI>
    let $cache :='Change value to force page refresh 558'
    return
       (: $buildRec:) 
       transform:transform($buildRec, doc('../resources/xsl/placepage.xsl'),() )
};