xquery version "3.0";
(:
 : Build generic TEI to RDF/XML 
 : 
:)
module namespace tei2rdf="http://syriaca.org/tei2rdf";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace data="http://syriaca.org/data" at "data.xqm";
import module namespace config="http://syriaca.org/config" at "../config.xqm";
import module namespace bibl2html="http://syriaca.org/bibl2html" at "bibl2html.xqm";
import module namespace rel="http://syriaca.org/related" at "get-related.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dcterms = "http://purl.org/dc/terms/";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace snap = "http://syriaca.org/snap#";
declare namespace syriaca = "http://syriaca.org/schema#";
declare namespace schema = "http://schema.org/";
declare namespace person = "http://syriaca.org/person/";
declare namespace cwrc = "http://sparql.cwrc.ca/ontologies/cwrc#";
declare namespace geo  = "http://www.w3.org/2003/01/geo/wgs84_pos#";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

(:~
 : Create a triple element with the rdf qname and content
 : @type indicates if element is literal default is rdf:resources
:)
declare function tei2rdf:create-element($element-name as xs:string, $lang as xs:string?, $content as xs:string*, $type as xs:string?){
 if($type='literal') then        
        element { xs:QName($element-name) } {
          (if ($lang) then attribute {xs:QName("xml:lang")} { $lang } else (), $content)
        } 
 else 
    element { xs:QName($element-name) } {
            (if ($lang) then attribute {xs:QName("xml:lang")} { $lang } else (),
            attribute {xs:QName("rdf:resource")} { $content }
            )
        }
};

(:~
 : Modified functx function to translate syriaca.org relationship names attributes to camel case.
 : @param $property as a string. 
:)
declare function tei2rdf:translate-relation-property($property as xs:string?) as xs:string{
    string-join((tokenize($property,'-')[1],
       for $word in tokenize($property,'-')[position() > 1]
       return functx:capitalize-first($word))
      ,'')
};

(: Create lawd:hasAttestation for elements with a source attribute and a matching bibl element. :)
declare function tei2rdf:attestation($rec, $source){
    for $source in tokenize($source)
    return 
        let $source := 
            if($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr) then
                string($rec//tei:bibl[@xml:id = replace($source,'#','')]/tei:ptr/@target)
            else string($source)
        return tei2rdf:create-element('lawd:hasAttestation', (), $source, ())
};

(: Decode record type based on TEI elements:)
declare function tei2rdf:rec-type($rec){
    if($rec/descendant::tei:body/tei:listPerson) then
         'http://lawd.info/ontology/Person'
    else if($rec/descendant::tei:body/tei:listPlace) then
        'http://lawd.info/ontology/Place'
    else if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        'http://lawd.info/ontology/conceptualWork'
    else if($rec/descendant::tei:body/tei:biblStruct) then
        'http://purl.org/dc/terms/bibliographicResource'    
    else if($rec/tei:listPerson) then
       'http://syriaca.org/schema#/personFactoid'    
    else if($rec/tei:listEvent) then
        'http://syriaca.org/schema#/eventFactoid'
    else if($rec/tei:listRelation) then
        'http://syriaca.org/schema#/relationFactoid'
    else()
};

(: Decode record label and title based on Syriaca.org headwords if available 'rdfs:label' or dcterms:title:)
declare function tei2rdf:rec-label-and-titles($rec, $element as xs:string?){
    if($rec/descendant::*[@syriaca-tags='#syriaca-headword']) then 
        for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][node()]
        return tei2rdf:create-element($element, string($headword/@xml:lang), string-join($headword/descendant-or-self::text(),' '), 'literal')
    else if($rec/descendant::tei:body/tei:listPlace/tei:place) then 
        for $headword in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName[node()]
        return tei2rdf:create-element($element, string($headword/@xml:lang), string-join($headword/descendant-or-self::text(),' '), 'literal')
    else if($rec[self::tei:div/@uri]) then 
        if(tei2rdf:rec-type($rec) = 'http://syriaca.org/schema#/relationFactoid') then
            tei2rdf:create-element($element, (), rel:relationship-sentence($rec/descendant::tei:listRelation/tei:relation), 'literal')
        else tei2rdf:create-element($element, (), normalize-space(string-join($rec/descendant::*[not(self::tei:citedRange)]/text(),' ')), 'literal')        
    else tei2rdf:create-element($element, string($rec/descendant::tei:title[1]/@xml:lang), string-join($rec/descendant::tei:title[1]/text(),' '), 'literal')
};

(: Output place and person names and name varients :)
declare function tei2rdf:names($rec){ 
    for $name in $rec/descendant::tei:body/tei:listPlace/tei:place/tei:placeName | $rec/descendant::tei:body/tei:listPerson/tei:person/tei:persName
    return 
        if($name/@syriaca-tags='#syriaca-headword') then 
                element { xs:QName('lawd:hasName') } {
                    element { xs:QName('rdf:Description') } {(
                        tei2rdf:create-element('lawd:primaryForm', string($name/@xml:lang), string-join($name/descendant-or-self::text(),' '), 'literal'),
                        tei2rdf:attestation($rec, $name/@source)   
                    )} 
                } 
        else 
                element { xs:QName('lawd:hasName') } {
                        element { xs:QName('rdf:Description') } {(
                            tei2rdf:create-element('lawd:variantForm', string($name/@xml:lang), string-join($name/descendant-or-self::text(),' '), 'literal'),
                            tei2rdf:attestation($rec, $name/@source)   
                        )} 
                    }
};

declare function tei2rdf:location($rec){
    for $geo in $rec/descendant::tei:location/tei:geo[. != '']
    return
         element { xs:QName('geo:location') } {
            element { xs:QName('rdf:Description') } {(
                tei2rdf:create-element('geo:lat', (), tokenize($geo,' ')[1], 'literal'),
                tei2rdf:create-element('geo:long', (), tokenize($geo,' ')[2], 'literal')
                )} 
            }
};
 
(:~ 
 : TEI descriptions
 : @param $rec TEI record. 
 : See if there is an abstract element?
 :)
declare function tei2rdf:desc($rec)  {
    for $desc in $rec/descendant::tei:body/descendant::tei:desc | $rec/descendant::tei:body/descendant::tei:note
    let $source := $desc/tei:quote/@source
    return 
        if($source != '') then 
            element { xs:QName('dcterms:description') } {
                element { xs:QName('rdf:Description') } {(
                    tei2rdf:create-element('dcterms:description', string($desc/@xml:lang), string-join($desc/descendant-or-self::text(),' '), 'literal'),
                    tei2rdf:attestation($rec, $source)
                )} 
             }
        else tei2rdf:create-element('dcterms:description', (), string-join($desc/descendant-or-self::text(),' '), 'literal')
};

(:~
 : Uses XQuery templates to properly format bibl, extracts just text nodes. 
 : @param $rec
:)
declare function tei2rdf:bibl-citation($rec){
let $citation := bibl2html:citation(root($rec))
return 
    <dcterms:bibliographicCitation xmlns:dc="http://purl.org/dc/terms/">{normalize-space(string-join($citation))}</dcterms:bibliographicCitation>
};

(: Handle TEI relations:)
declare function tei2rdf:relations-with-attestation($rec, $id){
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    return 
        if($rel/@mutual) then 
            for $s in tokenize($rel/@mutual,' ')
            return
                element { xs:QName('rdf:Description') } {(
                            attribute {xs:QName("rdf:about")} { $s },
                            for $o in tokenize($rel/@mutual,' ')[. != $s]
                            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                            return 
                                (tei2rdf:create-element('dcterms:relation', (), $o, ()),
                                tei2rdf:create-element($element-name, (), $o, ()),
                                tei2rdf:create-element('lawd:hasAttestation', (), $id, ()))
                        )}
        else 
            for $s in tokenize($rel/@active,' ')
            return 
                    element { xs:QName('rdf:Description') } {(
                            attribute {xs:QName("rdf:about")} { $s },
                            for $o in tokenize($rel/@passive,' ')
                            let $element-name := if($rel/@ref and $rel/@ref != '') then string($rel/@ref) else if($rel/@name and $rel/@name != '') then string($rel/@name) else 'dcterms:relation'
                            let $element-name := if(starts-with($element-name,'dct:')) then replace($element-name,'dct:','dcterms:') else $element-name
                            return (tei2rdf:create-element('dcterms:relation', (), $o, ()),tei2rdf:create-element($element-name, (), $o, ()),tei2rdf:create-element('lawd:hasAttestation', (), $id, ()))
                        )}
};

(: Handle TEI relations:)
declare function tei2rdf:relations($rec, $id){
    for $rel in $rec/descendant::tei:listRelation/tei:relation
    let $ids := distinct-values((
                    for $r in tokenize($rel/@active,' ') return $r,
                    for $r in tokenize($rel/@passive,' ') return $r,
                    for $r in tokenize($rel/@mutual,' ') return $r
                    ))
    for $i in $ids 
    return 
        if(contains($id,'/spear/')) then tei2rdf:create-element('dcterms:subject', (), $i, ())
        else tei2rdf:create-element('dcterms:relation', (), $i, ())
};

(: Internal references :)
declare function tei2rdf:internal-refs($rec){
    let $links := distinct-values($rec//@ref[starts-with(.,'http://')][not(ancestor::tei:teiHeader)])
    return 
        for $i in $links[. != '']
        return tei2rdf:create-element('dcterms:subject', (), $i, ()) 
};

(: Special handling for SPEAR :)
declare function tei2rdf:spear-related-triples($rec, $id){
    if(contains($id,'/spear/')) then
        (: Person Factoids :)
        if($rec/tei:listPerson) then  
            element { xs:QName('rdf:Description') } {(
                attribute {xs:QName("rdf:about")} { $rec/tei:listPerson/child::*/tei:persName/@ref },
                if($rec/tei:listPerson/child::*/tei:birth/tei:date) then 
                    tei2rdf:create-element('schema:birthDate', (), string-join($rec/tei:listPerson/child::*/tei:birth/tei:date/@when | $rec/tei:listPerson/child::*/tei:birth/tei:date/@notAfter | $rec/tei:listPerson/child::*/tei:birth/tei:date/@notBefore,' '), 'literal')
                else(),
                if($rec/tei:listPerson/child::*/tei:birth/tei:placeName[@ref]) then 
                    tei2rdf:create-element('schema:birthPlace', (), string($rec/tei:listPerson/child::*/tei:birth/tei:placeName/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:nationality/tei:placeName/@ref) then 
                    tei2rdf:create-element('person:citizenship', (), string($rec/tei:listPerson/child::*/tei:nationality/tei:placeName/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:death/tei:date) then 
                    tei2rdf:create-element('person:citizenship', (), string-join($rec/tei:listPerson/child::*/tei:death/tei:date/@when | $rec/tei:listPerson/child::*/tei:death/tei:date/@notAfter | $rec/tei:listPerson/child::*/tei:death/tei:date/@notBefore,' '), 'literal')
                else(),
                if($rec/tei:listPerson/child::*/tei:death/tei:placeName[@ref]) then 
                    tei2rdf:create-element('schema:deathPlace', (), string($rec/tei:listPerson/child::*/tei:death/tei:placeName/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:education[@ref]) then 
                    tei2rdf:create-element('syriaca:studiedSubject', (), string($rec/tei:listPerson/child::*/tei:education/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel'][@ref]) then 
                    tei2rdf:create-element('cwrc:hasEthnicity', (), string($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel']/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='gender'][@ref]) then 
                    tei2rdf:create-element('schema:gender', (), string($rec/tei:listPerson/child::*/tei:trait[@type='ethnicLabel']/@ref), ())
                else(),
                if($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown[@ref]) then 
                    tei2rdf:create-element('cwrc:hasLinguisticAbility', (), string($rec/descendant::tei:person/tei:langKnowledge/tei:langKnown/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:state[@type='mental'][@ref]) then 
                    tei2rdf:create-element('syriaca:hasMentalState', (), string($rec/tei:listPerson/child::*/tei:state/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:occupation[@ref]) then 
                    tei2rdf:create-element('snap:occupation', (), string($rec/tei:listPerson/child::*/tei:occupation/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='physical'][@ref]) then 
                    tei2rdf:create-element('syriaca:hasPhysicalTrait', (), string($rec/tei:listPerson/child::*/tei:trait[@type='physical']/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:residence/tei:placeName[@type='physical'][@ref]) then 
                    tei2rdf:create-element('person:residency', (), string($rec/tei:listPerson/child::*/tei:residence/tei:placeName[@type='physical']/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:state[@type='sanctity'][@ref]) then
                    tei2rdf:create-element('syriaca:sanctity', (), string($rec/tei:listPerson/child::*/tei:state[@type='sanctity']/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:sex) then 
                    tei2rdf:create-element('syriaca:sex', (), string($rec/tei:listPerson/child::*/tei:sex/@value), 'literal')
                else(),
                if($rec/tei:listPerson/child::*/tei:socecStatus[@ref]) then 
                    tei2rdf:create-element('syriaca:hasSocialRank', (), string($rec/tei:listPerson/child::*/tei:socecStatus/@ref), ())
                else(),
                if($rec/tei:listPerson/child::*/tei:trait[@type='physical'][@ref]) then 
                    tei2rdf:create-element('syriaca:hasPhysicalTrait', (), string($rec/tei:listPerson/child::*/tei:trait[@type='physical']/@ref), ())                    
                else(),
                if($rec/tei:listPerson/child::*/tei:persName[descendant-or-self::text()]) then 
                    for $name in $rec/tei:listPerson/child::*/tei:persName[descendant-or-self::text()]
                    return tei2rdf:create-element('foaf:name', (), string-join($name//text(),' '), 'literal')
                else (),
                tei2rdf:create-element('lawd:hasAttestation', (), $id, ())
             )}
        else if($rec/descendant::tei:listRelation) then 
            tei2rdf:relations-with-attestation($rec,$id)
        else ()
    else ()
};

declare function tei2rdf:spear($rec, $id){
   if(contains($id,'/spear/')) then
        (if($rec/tei:listEvent) then ( 
                (: Subjects:)
                let $subjects := tokenize($rec/descendant::tei:event/tei:ptr/@target,' ')
                for $subject in $subjects
                return tei2rdf:create-element('dcterms:subject', (), $subject, ()),
                (: Places :)
                let $places := $rec/descendant::tei:event/tei:desc/descendant::tei:placeName/@ref
                for $place in $places
                return tei2rdf:create-element('schema:location', (), $place, ()), 
                (: Dates :)
                let $dates := $rec/descendant::tei:event/descendant::tei:date/@when | $rec/descendant::tei:event/descendant::tei:date/@notBefore
                | $rec/descendant::tei:event/descendant::tei:date/@notAfter
                for $date in $dates
                return tei2rdf:create-element('dcterms:date', (), string($date), 'literal')
                )
        else (),
        for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
        return  tei2rdf:create-element('dcterms:source', (), $bibl, ()),
        tei2rdf:create-element('dcterms:isPartOf', (), replace($rec/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[@type="URI"][1],'/tei',''), ()),
        let $work-uris := distinct-values($rec/ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:sourceDesc//@ref) 
        for $work-uri in $work-uris[contains(.,'/work/')]
        return  tei2rdf:create-element('dcterms:source', (), $work-uri, ()),        
        tei2rdf:create-element('dcterms:isPartOf', (), 'http://syriaca.org/spear', ())
        )
    else () 
};

(:~
 : Pull to gether all triples for a single record
:)
declare function tei2rdf:make-triple-set($rec){
let $rec := if($rec/tei:div[@uri[starts-with(.,$global:base-uri)]]) then $rec/tei:div else $rec
let $id := if($rec/descendant::tei:idno[starts-with(.,$global:base-uri)]) then replace($rec/descendant::tei:idno[starts-with(.,$global:base-uri)][1],'/tei','')
           else if($rec/@uri[starts-with(.,$global:base-uri)]) then $rec/@uri[starts-with(.,$global:base-uri)]
           else $rec/descendant::tei:idno[1]
let $resource-class := if($rec/descendant::tei:body/tei:biblStruct) then 'rdfs:Resource'    
                       else 'skos:Concept'            
return  
    (element { xs:QName('rdf:Description') } {(
                attribute {xs:QName("rdf:about")} { $id }, 
                tei2rdf:create-element('rdf:type', (), tei2rdf:rec-type($rec), ()),
                (:NOTE: Not sure about the resource class, I think this was from Nathan ?:)
                (:tei2rdf:create-element($resource-class, (), $id, ()),:)
                tei2rdf:rec-label-and-titles($rec, 'rdfs:label'),
                tei2rdf:names($rec),
                if(contains($id,'/spear/')) then ()
                else tei2rdf:location($rec),
                tei2rdf:desc($rec),
                tei2rdf:spear($rec, $id),
                for $temporal in $rec/descendant::tei:state[@type="existence"]
                return 
                    tei2rdf:create-element('dcterms:temporal', (), string-join(($temporal/@when,$temporal/@from,$temporal/@to,$temporal/@notBefore,$temporal/@notAfter),'/'), 'literal'),
                for $id in $rec/descendant::tei:body/descendant::tei:idno[@type='URI'][text() != $id and text() != '']/text() 
                return 
                    tei2rdf:create-element('skos:closeMatch', (), $id, ()),
                tei2rdf:internal-refs($rec),
                tei2rdf:relations($rec, $id),
                for $s in root($rec)/descendant::tei:seriesStmt
                return 
                    if($s/tei:idno[@type="URI"]) then
                        tei2rdf:create-element('dcterms:isPartOf', (), $s/tei:idno[@type="URI"][1], ())            
                    else tei2rdf:create-element('dcterms:isPartOf', (), $s/tei:title[1], 'literal'),                    
                if(contains($id,'/spear/')) then tei2rdf:bibl-citation($rec) else (),
                (: Other formats:)
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/html'), ()),
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/tei'), ()),
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/ttl'), ()),
                tei2rdf:create-element('dcterms:hasFormat', (), concat($id,'/rdf'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/html'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/tei'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/ttl'), ()),
                tei2rdf:create-element('foaf:primaryTopicOf', (), concat($id,'/rdf'), ())
        )},
        if(contains($id,'/spear/')) then tei2rdf:spear-related-triples($rec, $id) 
        else 
            (tei2rdf:relations-with-attestation($rec,$id),
            <rdfs:Resource rdf:about="{concat($id,'/html')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/html", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>,
            <rdfs:Resource rdf:about="{concat($id,'/tei')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/xml", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>,
            <rdfs:Resource rdf:about="{concat($id,'/ttl')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                {(
                tei2rdf:rec-label-and-titles($rec, 'dcterms:title'),
                tei2rdf:create-element('dcterms:subject', (), $id, ()),
                for $bibl in $rec//tei:bibl[not(ancestor::tei:teiHeader)]/tei:ptr/@target[. != '']
                return tei2rdf:create-element('dcterms:source', (), $bibl, ()),
                tei2rdf:create-element('dcterms:format', (), "text/turle", "literal"),
                tei2rdf:bibl-citation($rec)
                )}
            </rdfs:Resource>)
        )
};        
    
(:~ 
 : Build RDF output for records. 
:)
declare function tei2rdf:rdf-output($recs){
element rdf:RDF {namespace {""} {"http://www.w3.org/1999/02/22-rdf-syntax-ns#"}, 
    namespace cwrc {"http://sparql.cwrc.ca/ontologies/cwrc#"},
    namespace dcterms {"http://purl.org/dc/terms/"},
    namespace foaf {"http://xmlns.com/foaf/0.1"},
    namespace lawd {"http://lawd.info/ontology/"},    
    namespace person {"http://syriaca.org/person/"},
    namespace rdfs {"http://www.w3.org/2000/01/rdf-schema#"},
    namespace schema {"http://schema.org/"},
    namespace skos {"http://www.w3.org/2004/02/skos/core#"},
    namespace snap {"http://syriaca.org/snap#"},
    namespace syriaca {"http://syriaca.org/schema#"},
    namespace geo {"http://www.w3.org/2003/01/geo/wgs84_pos#"},
            for $r in $recs
            return tei2rdf:make-triple-set($r) 
    }
};
