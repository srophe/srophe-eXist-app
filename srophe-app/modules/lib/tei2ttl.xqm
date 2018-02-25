xquery version "3.0";
(:
 : Build ttl output for Gazetteer data. 
 : Updated to work with Persons/Places and Works:
 : https://github.com/srophe/srophe-app-data/issues/702#issuecomment-280301046 
:)

module namespace tei2ttl="http://syriaca.org/tei2ttl";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace bibl2html="http://syriaca.org/bibl2html" at "bibl2html.xqm";
import module namespace rel="http://syriaca.org/related" at "get-related.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=text media-type=text/turtle indent=yes";

(:~
 : Modified functx function to translate syriaca.org relationship names attributes to camel case.
 : @param $property as a string. 
:)
declare function tei2ttl:translate-relation-property($property as xs:string?) as xs:string{
    string-join((tokenize($property,'-')[1],
       for $word in tokenize($property,'-')[position() > 1]
       return functx:capitalize-first($word))
      ,'')
};

(:~
 : Create an RDF URI
 : @param $uri uri/id as xs:string 
 :)
declare function tei2ttl:make-uri($uri){
    concat('<',normalize-space($uri),'>')
};

(:~
 : Add language tag to triple
 : @param $lang language code as xs:string 
 :)
declare function tei2ttl:make-lang($lang) as xs:string?{
    concat('@',$lang)
};

(:~ 
 : Build literal string, normalize spaces and strip "", add lang if specified
 : @param $string string for literal
 : @param $lang language code as xs:string  
 :)
declare function tei2ttl:make-literal($string as xs:string*, $lang as xs:string*) as xs:string?{
    concat('"',replace(normalize-space(string-join($string,' ')),'"',''),'"',
        if($lang != '') then tei2ttl:make-lang($lang) 
        else ()) 
};

(:~ 
 : Build basic triple string, output as string. 
 : @param $s triple subject
 : @param $o triple object
 : @param $p triple predicate
 :)
declare function tei2ttl:make-triple($s as xs:string?, $o as xs:string?, $p as xs:string?) as xs:string* {
    concat('&#xa;', $s,' ', $o,' ', $p, ' ;')
};

(: Create lawd:hasAttestation for elements with a source attribute and a matching bibl element. :)
declare function tei2ttl:attestation($rec, $source){
    for $source in tokenize($source)
    return 
        let $source := 
            if($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr) then
                string($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr/@target)
            else string($source)
        return tei2ttl:make-triple('','lawd:hasAttestation', tei2ttl:make-uri($source))
};

(:~ 
 : TEI descriptions
 : @param $rec TEI record. 
 :)
declare function tei2ttl:desc($rec) as xs:string* {
string-join((
for $desc in $rec/descendant::tei:desc
let $source := $desc/tei:quote/@source
return
    if($desc[@type='abstract'][not(@source)][not(tei:quote/@source)] or $desc[contains(@xml:id,'abstract')][not(@source)][not(tei:quote/@source)][. != '']) then 
        tei2ttl:make-triple('', 'dcterms:description', tei2ttl:make-literal($desc/text(),()))
    else 
        if($desc/child::* != '' or $desc != '') then 
            concat('&#xa; dcterms:description [',
                tei2ttl:make-triple('','rdfs:label', tei2ttl:make-literal($desc, string($desc/@xml:lang))),
                    if($source != '') then
                       if($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p/tei:listBibl/tei:bibl/tei:ptr/@target = $source) then 
                            tei2ttl:make-triple('','dcterms:license', tei2ttl:make-uri(string($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/@target)))
                       else ()
                    else (),
            '];')
        else ()), '')
};

(:~
 : Handling tei:idno 
 : @param $rec TEI record.
 :)
declare function tei2ttl:idnos($rec, $id) as xs:string* {
let $ids := $rec//descendant::tei:body//tei:idno[@type='URI'][text() != $id]/text()
return 
if($ids != '') then
    string-join(
        (tei2ttl:make-triple('','skos:closeMatch',
           string-join((for $i in $ids
            return tei2ttl:make-uri($i)), ', ')),
        tei2ttl:make-triple('','dcterms:relation',
           string-join((for $i in $ids
            return tei2ttl:make-uri($i)), ', '))
            ),' ')
else ()   
};

(:~
 : Handling tei:bibl 
 : @param $rec TEI record.
 :)
declare function tei2ttl:bibl($rec) as xs:string* {
let $bibl-ids := $rec//descendant::tei:body//tei:bibl/tei:ptr/@target
(:[not(@type='lawd:ConceptualWork')]/tei:ptr:)
return 
if($bibl-ids != '') then 
        tei2ttl:make-triple('','dcterms:source',
           string-join((for $i in $bibl-ids
            return tei2ttl:make-uri($i)), ', '))
else ()   
};

(:~ 
 : Place/Person names 
 : @param $rec TEI record.
 :)
declare function tei2ttl:names($rec) as xs:string*{
string-join((
for $name in $rec/descendant::tei:body/descendant::tei:placeName | $rec/descendant::tei:body/descendant::tei:persName
return 
    if($name/parent::tei:place or $name/parent::tei:person) then  
            concat('&#xa; lawd:hasName [',
                if($name/@syriaca-tags='#syriaca-headword') then
                    string-join((tei2ttl:make-triple('','lawd:primaryForm',tei2ttl:make-literal($name/text(),$name/@xml:lang)),
                    tei2ttl:attestation($rec, $name/@source))) 
                else 
                    string-join((tei2ttl:make-triple('','lawd:variantForm',tei2ttl:make-literal($name/text(),$name/@xml:lang)),
                    tei2ttl:attestation($rec, $name/@source)))
            ,'];')
    else 
        if($name/ancestor::tei:location[@type='nested'][starts-with(@ref,$global:base-uri)]) then
           tei2ttl:make-triple('','dcterms:isPartOf',tei2ttl:make-uri($name/@ref)) 
        else if($name[starts-with(@ref,$global:base-uri)]) then  
            tei2ttl:make-triple('','skos:related',tei2ttl:make-uri($name/@ref))
        else ()),' ')        
};

(:~ 
 : Locations with coords 
 : @param $rec TEI record.
 :)
declare function tei2ttl:geo($rec) as xs:string*{
string-join((
for $geo in $rec/descendant::tei:location[tei:geo]
return 
    concat('&#xa;geo:location [',
        tei2ttl:make-triple('','geo:lat',tei2ttl:make-literal(tokenize($geo/tei:geo,' ')[1],())),
        tei2ttl:make-triple('','geo:long',tei2ttl:make-literal(tokenize($geo/tei:geo,' ')[2],())),
    '];')),'')
};

(:~
 : Uses XSLT templates to properly format bibl, extracts just text nodes. 
 : @param $rec
:)
declare function tei2ttl:bibl-citation($rec) as xs:string*{
let $citation := string-join(bibl2html:citation($rec/ancestor-or-self::tei:TEI))
return 
    tei2ttl:make-triple('','dcterms:bibliographicCitation', tei2ttl:make-literal($citation,()))
};

declare function tei2ttl:internal-refs($rec) as xs:string*{
let $links := distinct-values($rec/descendant::tei:body//@ref[starts-with(.,'http://')] | $rec/descendant::tei:body//@target[starts-with(.,'http://')])
return 
if($links != '') then
    tei2ttl:make-triple('','dcterms:relation',
           string-join((for $i in $links
            return tei2ttl:make-uri($i)), ', '))
else ()
};

declare function tei2ttl:rec-type($rec){
    if($rec/descendant::tei:body/tei:listPerson) then
        'lawd:Person'
    else if($rec/descendant::tei:body/tei:listPlace) then
        'lawd:Place'
    else if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        'lawd:conceptualWork'
    else if($rec/descendant::tei:body/tei:biblStruct) then
        'dcterms:bibliographicResource'        
    else if($rec/tei:listPerson) then
       'syriaca:personFactoid'    
    else if($rec/tei:listEvent) then
        'syriaca:eventFactoid'
    else if($rec/tei:listRelation) then
        'syriaca:relationFactoid'
    else()
};

declare function tei2ttl:resource-class($rec) as xs:string?{
     if($rec/descendant::tei:body/tei:biblStruct) then
        'rdfs:Resource'    
    else 'skos:Concept'
};

(: 
 : Relations
 : @param $rec TEI record. 
 :)
declare function tei2ttl:relations-with-attestation($rec,$id){
string-join((for $rel in $rec/descendant::tei:listRelation/tei:relation
    return 
        if($rel/@mutual) then 
            for $s in tokenize($rel/@mutual,' ')
            return
                tei2ttl:record(string-join((
                    for $o in tokenize($rel/@mutual,' ')[. != $s]
                    let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                    let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                    return 
                        concat(tei2ttl:make-triple('', $element-name, tei2ttl:make-uri($o)),
                               tei2ttl:make-triple('', 'lawd:hasAttestation', tei2ttl:make-uri($id)))
                                ),' '))
        else 
            for $s in tokenize($rel/@active,' ')
            return 
                tei2ttl:record(string-join((
                    for $o in tokenize($rel/@passive,' ')
                    let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                    let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                    return 
                        concat(tei2ttl:make-triple('', $element-name, tei2ttl:make-uri($o)),
                            tei2ttl:make-triple('', 'lawd:hasAttestation', tei2ttl:make-uri($id)))
                            ),''))
 ),'')                            
};

declare function tei2ttl:relations($rec, $id){
string-join((for $rel in $rec/descendant::tei:listRelation/tei:relation
    let $ids := distinct-values((
                    for $r in tokenize($rel/@active,' ') return $r,
                    for $r in tokenize($rel/@passive,' ') return $r,
                    for $r in tokenize($rel/@mutual,' ') return $r
                    ))
    for $i in $ids 
    return tei2ttl:make-triple('', 'dcterms:relation', tei2ttl:make-uri($i))
    ),' ')
};



(: Prefixes :)
declare function tei2ttl:prefix() as xs:string{
"@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#> .
@prefix geosparql: <http://www.opengis.net/ont/geosparql#> .
@prefix gn: <http://www.geonames.org/ontology#> .
@prefix lawd: <http://lawd.info/ontology/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix schema: <http://schema.org/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix syriaca: <http://syriaca.org/schema#> .
@prefix snap: <http://syriaca.org/snap#> .
@prefix wdata: <https://www.wikidata.org/wiki/Special:EntityData/> .&#xa;"
};

(: Triples for a single record :)
declare function tei2ttl:make-triple-set($rec as item()?){
let $rec := if($rec/tei:div[@uri[starts-with(.,$global:base-uri)]]) then $rec/tei:div[@uri[starts-with(.,$global:base-uri)]] else $rec
let $id := if($rec/descendant::tei:idno[starts-with(.,$global:base-uri)]) then replace($rec/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei','')
           else if($rec/@uri[starts-with(.,$global:base-uri)]) then $rec/@uri[starts-with(.,$global:base-uri)]
           else $rec/descendant::tei:idno[1]
let $resource-class := if($rec/descendant::tei:body/tei:biblStruct) then 'rdfs:Resource'    
                       else 'skos:Concept'    
return 
concat(
    (: skos:Concept :)
    tei2ttl:record(concat(
        tei2ttl:make-triple(tei2ttl:make-uri($id), 'a', tei2ttl:rec-type($rec)),
        if($rec/descendant::tei:place/@type='schema:LandmarksOrHistoricalBuildings') then 
            tei2ttl:make-triple((), 'a', 'schema:LandmarksOrHistoricalBuildings')
        else (),
        tei2ttl:make-triple((),'rdfs:label',
                if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                    string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')
                else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                    string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')                        
                else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else ())),
       tei2ttl:names($rec),
       tei2ttl:geo($rec),
       tei2ttl:idnos($rec, $id),
       tei2ttl:relations($rec, $id),
       tei2ttl:make-triple('','dcterms:hasFormat', 
            concat(tei2ttl:make-uri(concat($id,'/html')),
            ', ',tei2ttl:make-uri(concat($id,'/tei')),
            ', ',tei2ttl:make-uri(concat($id,'/ttl')),
            ', ',tei2ttl:make-uri(concat($id,'/rdf')))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/html'))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/tei'))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/ttl'))),
       tei2ttl:make-triple('','foaf:primaryTopicOf', tei2ttl:make-uri(concat($id,'/rdf'))),
       tei2ttl:internal-refs($rec)
    )),
    string-join((
    (: rdfs:Resource, html :)
    tei2ttl:record(concat(
        tei2ttl:make-triple(tei2ttl:make-uri(concat($id,'/html')), 'a', 'rdfs:Resource;'),
        tei2ttl:make-triple((),'dcterms:title',
                if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                    string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')
                else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                    string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')                        
                else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else ())),
        tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
        if(contains($id,'/spear/')) then () else tei2ttl:bibl($rec),
        tei2ttl:make-triple('','dcterms:format', tei2ttl:make-literal('text/html','')),
        tei2ttl:bibl-citation($rec)
    )),
    (: rdfs:Resource, tei :)
    tei2ttl:record(concat(
        tei2ttl:make-triple(tei2ttl:make-uri(concat($id,'/tei')), 'a', 'rdfs:Resource;'),
        tei2ttl:make-triple((),'dcterms:title',
                if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                    string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')
                else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                    string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')                        
                else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else ())),
        tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
        if(contains($id,'/spear/')) then () else tei2ttl:bibl($rec), 
        tei2ttl:make-triple('','dcterms:format', tei2ttl:make-literal('text/xml','')),
        tei2ttl:bibl-citation($rec)
    )),
    (: rdfs:Resource, ttl :)
    tei2ttl:record(concat(
        tei2ttl:make-triple(tei2ttl:make-uri(concat($id,'/ttl')), 'a', 'rdfs:Resource;'),
        tei2ttl:make-triple((),'dcterms:title',
                if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then
                    string-join(for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')
                else if($rec/descendant::tei:body/tei:listPlace/tei:place) then
                    string-join(for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[. != '']
                        return tei2ttl:make-literal($headword/descendant::text(),if($headword/@xml:lang) then string($headword/@xml:lang) else ()),', ')                        
                else tei2ttl:make-literal($rec/descendant::tei:title[1]/text(),if($rec/descendant::tei:title[1]/@xml:lang) then string($rec/descendant::tei:title[1]/@xml:lang) else ())),        tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
        tei2ttl:make-triple('','dcterms:subject', tei2ttl:make-uri($id)),
        if(contains($id,'/spear/')) then () else tei2ttl:bibl($rec),         
        tei2ttl:make-triple('','dcterms:format', tei2ttl:make-literal('text/turtle','')),
        tei2ttl:bibl-citation($rec)
    ))))
    )
};

(: Make sure record ends with a '.' :)
declare function tei2ttl:record($triple as xs:string*) as xs:string*{
    replace($triple,';$','.&#xa;')
};

declare function tei2ttl:ttl-output($recs as item()*) {
    (concat(tei2ttl:prefix(), string-join(for $r in $recs return tei2ttl:make-triple-set($r)),''))
};
