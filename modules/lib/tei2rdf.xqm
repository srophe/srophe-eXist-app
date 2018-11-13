xquery version "3.0";
(:
 : Build generic TEI to RDF/XML 
:)
module namespace tei2rdf="http://syriaca.org/tei2rdf";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace data="http://syriaca.org/data" at "data.xqm";
import module namespace config="http://syriaca.org/config" at "../config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cito = "http://purl.org/spar/cito";
declare namespace cnt = "http://www.w3.org/2011/content";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace geo = "http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace gn = "http://www.geonames.org/ontology#";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace collex="http://www.collex.org/schema#";
declare namespace ra="http://www.rossettiarchive.org/schema#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace role="http://www.loc.gov/loc.terms/relators/";
declare namespace syriaca="http://syriaca.org/schema#";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

declare function tei2rdf:rec-type($rec){
    if($rec/descendant::tei:body/tei:listPerson) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://lawd.info/ontology/Person"/>
    else if($rec/descendant::tei:body/tei:listPlace) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://lawd.info/ontology/Place"/>
    else if($rec/descendant::tei:body/tei:bibl[@type="lawd:ConceptualWork"]) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://lawd.info/ontology/conceptualWork"/>
    else if($rec/descendant::tei:body/tei:biblStruct) then
        <rdf:type xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:resource="http://purl.org/dc/terms/bibliographicResource"/>    
    else ()
};

declare function tei2rdf:rec-label($rec){
    for $headword in $rec/descendant::*[@syriaca-tags='#syriaca-headword'][node()]
    return <skos:prefLabel xml:lang="{string($headword/@xml:lang)}" xmlns:skos="http://www.w3.org/2004/02/skos/core#">{string-join($headword/descendant::text(),' ')}</skos:prefLabel>
};

(:~ 
 : TEI descriptions
 : @param $rec TEI record. 
 :)
declare function tei2rdf:desc($rec) as xs:string* {
for $desc in $rec/descendant::tei:desc
let $source := $desc/tei:quote/@source
return
    if($desc[@type='abstract'][not(@source)][not(tei:quote/@source)] or $desc[contains(@xml:id,'abstract')][not(@source)][not(tei:quote/@source)][. != '']) then 
        <dcterms:description xmlns:dcterms="http://purl.org/dc/terms/">{string-join($desc/text(),' ')}</dcterms:description>
    else ()
    (: this is unclear save for later
        if($desc/child::* != '' or $desc != '') then 
            <dcterms:description xmlns:dcterms="http://purl.org/dc/terms/">
                <rdfs:label xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
                    {if($desc/@xml:lang) then attribute lang {$desc/@xml:lang} else ()}
                    {}
                    
                </rdfs:label>
            </dcterms:description>
            
            concat('&#xa; dcterms:description [',
                tei2ttl:make-triple('','rdfs:label', tei2ttl:make-literal($desc, string($desc/@xml:lang))),
                    if($source != '') then
                       if($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p/tei:listBibl/tei:bibl/tei:ptr/@target = $source) then 
                            tei2ttl:make-triple('','dcterms:license', tei2ttl:make-uri(string($desc/ancestor::tei:TEI/descendant::tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/@target)))
                       else ()
                    else (),
            '];')
            :)
};

(:~
 : Handling tei:bibl 
 : @param $rec TEI record.
 :)
declare function tei2rdf:bibl($rec) {
let $bibl-ids := $rec//descendant::tei:body//tei:bibl/tei:ptr/@target
(:[not(@type='lawd:ConceptualWork')]/tei:ptr:)
return 
if($bibl-ids != '') then
    for $id in $bibl-ids
    return <dc:relation rdf:resource="{$id}" xmlns:dc="http://purl.org/dc/terms/"/>
else ()   
};

(:~
 : Uses XSLT templates to properly format bibl, extracts just text nodes. 
 : @param $rec
:)
declare function tei2rdf:bibl-citation($rec){
let $citation := 
    normalize-space(string-join(transform:transform(
    <text-citation xmlns="http://www.tei-c.org/ns/1.0">{$rec//tei:teiHeader}</text-citation>, doc($global:app-root || '/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
        <param name="nav-base" value="{$global:nav-base}"/>
        <param name="base-uri" value="{$global:base-uri}"/>
        <param name="mode" value="text"/>
    </parameters>)/text(),' '))
return 
    <dcterms:bibliographicCitation xmlns:dc="http://purl.org/dc/terms/">{$citation}</dcterms:bibliographicCitation>
};

(:~
 : Handling tei:idno 
 : @param $rec TEI record.
 :)
declare function tei2rdf:idnos($rec, $id) {
let $ids := $rec//descendant::tei:body//tei:idno[@type='URI'][text() != $id]/text()
return 
if($ids != '') then
    for $id in $ids
    return 
    (<skos:closeMatch rdf:resource="{$id}" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>, 
    <dc:relation rdf:resource="{$id}" xmlns:dc="http://purl.org/dc/terms/" />)
else ()   
};

declare function tei2rdf:other-formats($id) {
   (
    <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{concat($id,'/html')}"/>,
    <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{concat($id,'/tei')}"/>,
    <dc:relation xmlns:dc="http://purl.org/dc/terms/" rdf:resource="{concat($id,'/ttl')}"/>,
    <foaf:primaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{concat($id,'/html')}"/>,
    <foaf:primaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{concat($id,'/tei')}"/>,
    <foaf:primaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{concat($id,'/ttl')}"/>
   )
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

declare function tei2rdf:related($rec, $id) {
(for $relation in $rec/descendant::tei:relation[not(parent::*/parent::tei:bibl)]
return 
    if($relation/@ref) then 
        let $related := distinct-values((tokenize($relation/@active,' '), tokenize($relation/@passive,' '), tokenize($relation/@mutual,' ')))
        return 
            let $relation := string($relation/@ref)
            for $r in $related[not(starts-with(.,('#','bibl'))) and (. != $id)]
            return 
                element { xs:QName($relation) } 
                        { attribute {xs:QName("rdf:resource")} { $r} } 
    else 
        if($relation/@name = 'contained') then 
            for $active in tokenize($relation/@active,' ')
            return <dcterms:isPartOf xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$active}"/>
        else if($relation/@name = 'share-a-name') then 
            let $rel := normalize-space($relation/@mutual)
            for $mutual in tokenize($rel,' ') 
            return 
                if(starts-with($mutual,'#')) then ()
                else <dcterms:relation xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$mutual}"/>
        else if(contains($relation/@name,'-')) then 
            let $related := distinct-values((tokenize($relation/@active,' '), tokenize($relation/@passive,' '), tokenize($relation/@mutual,' ')))
            return 
                let $relation := concat('syriaca:',tei2rdf:translate-relation-property(string($relation/@name)))
                for $r in $related[not(starts-with(.,('#','bibl'))) and (. != $id)]
                return 
                    element { xs:QName($relation) } 
                        { attribute {xs:QName("rdf:resource")} { $r} }    
        else (),
for $location-relation in $rec/descendant::tei:location[@type='nested']/child::*[starts-with(@ref,'http://syriaca.org/')]/@ref
return <dcterms:isPartOf xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$location-relation}"/>
) 
};

declare function tei2rdf:internal-refs($rec){
let $links := distinct-values($rec/descendant::tei:body//@ref[starts-with(.,'http://')] | $rec/descendant::tei:body//@target[starts-with(.,'http://')])
return 
if($links != '') then
    for $i in $links
    return <dcterms:relation xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$i}"/>
else ()
};

declare function tei2rdf:rec-title($rec){
    <dcterms:title xmlns:dcterms="http://purl.org/dc/terms/">{string-join($rec//tei:titleStmt/tei:title/node(),' ')}</dcterms:title>
};

declare function tei2rdf:make-triple-set($rec){
let $id := replace($rec/descendant::tei:idno[starts-with(.,'http://syriaca.org/')][1],'/tei','')
return 
(<skos:Concept rdf:about="{$id}" xmlns:skos="http://www.w3.org/2004/02/skos/core#">
    {(tei2rdf:rec-type($rec),
    tei2rdf:rec-label($rec),
    tei2rdf:idnos($rec, $id),
    tei2rdf:bibl($rec),
    tei2rdf:other-formats($id),
    tei2rdf:related($rec, $id),
    tei2rdf:internal-refs($rec)
    )}
</skos:Concept>,
<rdfs:Resource rdf:about="{concat($id,'/html')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    {(
    tei2rdf:rec-title($rec),
    <dcterms:subject xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$id}"/>,
    <dcterms:format xmlns:dcterms="http://purl.org/dc/terms/">text/html</dcterms:format>,
    tei2rdf:bibl-citation($rec)
    )}
</rdfs:Resource>,
<rdfs:Resource rdf:about="{concat($id,'/tei')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    {(
    tei2rdf:rec-title($rec),
    <dcterms:subject xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$id}"/>,
    <dcterms:format xmlns:dcterms="http://purl.org/dc/terms/">text/xml</dcterms:format>,
    tei2rdf:bibl-citation($rec)
    )}
</rdfs:Resource>,
<rdfs:Resource rdf:about="{concat($id,'/ttl')}" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
    {(
    tei2rdf:rec-title($rec),
    <dcterms:subject xmlns:dcterms="http://purl.org/dc/terms/" rdf:resource="{$id}"/>,
    <dcterms:format xmlns:dcterms="http://purl.org/dc/terms/">text/turtle</dcterms:format>,
    tei2rdf:bibl-citation($rec)
    )}
</rdfs:Resource>
)
};

declare function tei2rdf:rdf-output($recs){
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:skos="http://www.w3.org/2004/02/skos/core#"
         xmlns:dc="http://purl.org/dc/terms/"
         xmlns:dcterms="http://purl.org/dc/terms/"
         xmlns:lawd="http://lawd.info/ontology/"
         xmlns:foaf="http://xmlns.com/foaf/0.1/"
         xmlns:syriaca="http://syriaca.org/schema#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
         {
            for $r in $recs
            return tei2rdf:make-triple-set($r) 
         }
</rdf:RDF>
};

declare function tei2rdf:save-rec($doc){
let $id := $doc/descendant::tei:idno[1]
let $filename := concat(tokenize(replace($id,'/tei',''),'/')[last()],'.rdf')
let $collection := substring-before(substring-after($id,'http://syriaca.org/'),'/')
let $file-data :=  
        try {
            tei2rdf:rdf-output($doc)
        } catch * {
            <error>Caught error {$err:code}: {$err:description}</error>
            }  
return xmldb:store(xs:anyURI(concat('/db/apps/srophe-data/rdf/',$collection,'s')), xmldb:encode-uri($filename), $file-data)
        
};
declare function tei2rdf:get-ttl($id, $collection, $start, $perpage){
if($id) then 
    let $rec := data:get-rec($id)
    let $filename := if($rdf-file-name) then $rdf-file-name else concat(tokenize(replace($id,'/tei',''),'/')[last()],'.rdf')
    let $file-data :=  
        try {
            tei2rdf:rdf-output($rec)
        } catch * {
            <error>Caught error {$err:code}: {$err:description}</error>
            }  
    return $file-data
        (:xmldb:store(xs:anyURI('/db/apps/srophe-rdf/rdf'), xmldb:encode-uri($filename), $file-data):)
else if($collection) then 
    let $start := if($start) then $start else 1
    let $perpage := if($perpage) then $perpage else 50
    let $filename := $rdf-file-name
    let $recs := collection($global:data-root || '/' || $collection)//tei:TEI
    let $full :=  tei2rdf:rdf-output($recs)                
    return $full
        (:(xmldb:login('/db/apps/srophe/', 'admin', '', true()),xmldb:store(xs:anyURI('/db/apps/srophe-rdf/rdf'), xmldb:encode-uri($filename), $full)):)
else()
};