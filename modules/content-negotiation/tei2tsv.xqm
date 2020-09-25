xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2tsv="http://syriaca.org/srophe/tei2tsv";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

declare function tei2tsv:value($nodes as item()*){
(:let $q := codepoints-to-string(34)
return concat('"',replace(normalize-space(string-join($nodes//text(),' ')),$q,concat($q,$q)),'"')
:)
normalize-space(string-join($nodes//text(),' '))
};
declare function tei2tsv:tei2tsv($nodes as node()*){
let $collection := request:get-parameter("collection", ())
return 
    if($collection = 'sites') then
        tei2tsv:tei2tsv-sites($nodes)
    else if($collection = 'buildings') then
        tei2tsv:tei2tsv-buildings($nodes)        
    else tei2tsv:tei2tsv-keywords($nodes)
};

declare function tei2tsv:tei2tsv-sites($nodes as node()*) {
let $headers :=concat(string-join(
                ('title', 'uri', 'principal', 'editor', 'editor2', 'editor3', 'published',
                'site-name-en','site-name-zh-latn-pinyin','site-name-zh-Hant','site-name-zh-Hans',
                'site-name-Wade-Giles','site-name-other','site-name-other2','site-name-other3',
                'site-name-other4','site-name-other5','site-name-other6','site-name-other7',
                'site-name-other8','site-name-other9','site-name-other10',
                'date','dynasty','site data',
                'site type','buildings in site'),"&#x9;"),'&#xa;')
let $data :=                   
    string-join(
    for $record in $nodes//tei:TEI
    let $n := $record/descendant::tei:place
    let $title := tei2tsv:value($record/descendant::tei:title[1])
    let $uri := replace($record/descendant::tei:idno[1],'/tei','')
    let $principal := tei2tsv:value($record/descendant::tei:principal[1])
    let $editor := tei2tsv:value($record/descendant::tei:editor[1])
    let $editor2 := tei2tsv:value($record/descendant::tei:editor[2])
    let $editor3 := tei2tsv:value($record/descendant::tei:editor[3])
    let $published := tei2tsv:value($record/descendant::tei:publicationStmt/tei:date)
    let $site-name-en := tei2tsv:value($n/tei:placeName[@xml:lang="en"][1])
    let $site-name-zh-latn-pinyin := tei2tsv:value($n/tei:placeName[@xml:lang="zh-latn-pinyin"][1])
    let $site-name-zh-Hant := tei2tsv:value($n/tei:placeName[@xml:lang="zh-Hant"][1])
    let $site-name-zh-Hans := tei2tsv:value($n/tei:placeName[@xml:lang="zh-Hans"][1])
    let $site-name-Wade-Giles := tei2tsv:value($n/tei:placeName[@xml:lang="Wade-Giles" or @xml:lang = 'zh-latn-wadegile'][1])
    let $site-name-other := tei2tsv:value($n/tei:placeName[6])
    let $site-name-other2 := tei2tsv:value($n/tei:placeName[7])
    let $site-name-other3 := tei2tsv:value($n/tei:placeName[8])
    let $site-name-other4 := tei2tsv:value($n/tei:placeName[9])
    let $site-name-other5 := tei2tsv:value($n/tei:placeName[10])
    let $site-name-other6 := tei2tsv:value($n/tei:placeName[11])
    let $site-name-other7 := tei2tsv:value($n/tei:placeName[12])
    let $site-name-other8 := tei2tsv:value($n/tei:placeName[13])
    let $site-name-other9 := tei2tsv:value($n/tei:placeName[14])
    let $site-name-other10 := tei2tsv:value($n/tei:placeName[15])
    let $date := concat($n/tei:state[@type="existence"][1]/@from,'/',$n/tei:state[@type="existence"][1]/@to)
    let $dynasty := tei2tsv:value($n/tei:state[@subtype="dynasty"]/tei:desc)
    let $site-data := tei2tsv:value($n/tei:desc[@type="site-data"])
    let $site-type := tei2tsv:value($n/tei:trait[@type="type"])
    let $buildings-in-site := string($record/descendant::tei:relation[@ana="site-type"]/@passive)
    return 
        concat(
            string-join(($title,$uri,$principal,$editor,$editor2,$editor3,$published,
            $site-name-en, $site-name-zh-latn-pinyin, $site-name-zh-Hant, $site-name-zh-Hans, $site-name-Wade-Giles, 
            $site-name-other, $site-name-other2,$site-name-other3,$site-name-other4,$site-name-other5,$site-name-other6,
            $site-name-other7,$site-name-other8,$site-name-other9,$site-name-other10,
            $date, $dynasty, $site-data, $site-type, $buildings-in-site),"&#x9;"),'&#xa;'))
return concat($headers,($data))    
};

declare function tei2tsv:tei2tsv-buildings($nodes as node()*) {
let $headers :=concat(string-join(
                ('title', 'uri', 'principal', 'editor', 'editor2', 'editor3', 'published',
                'building-name-en','building-name-zh-latn-pinyin','building-name-zh-Hant','building-name-zh-Hans',
                'building-name-Wade-Giles','building-name-other','building-name-other2',
                'building-name-other3','building-name-other4','building-name-other5','building-name-other6',
                'building-name-other7','building-name-other8','building-name-other9','building-name-other10',
                'date','dynasty','building data',
                'building type','contained in what site'),"&#x9;"),
                  '&#xa;')
let $data :=                   
    string-join(
    for $record in $nodes//tei:TEI
    let $n := $record/descendant::tei:place
    let $title := tei2tsv:value($record/descendant::tei:title[1])
    let $uri := replace($record/descendant::tei:idno[1],'/tei','')
    let $principal := tei2tsv:value($record/descendant::tei:principal[1])
    let $editor := tei2tsv:value($record/descendant::tei:editor[1])
    let $editor2 := tei2tsv:value($record/descendant::tei:editor[2])
    let $editor3 := tei2tsv:value($record/descendant::tei:editor[3])
    let $published := tei2tsv:value($record/descendant::tei:publicationStmt/tei:date)
    let $site-name-en := tei2tsv:value($n/tei:placeName[@xml:lang="en"][1])
    let $site-name-zh-latn-pinyin := tei2tsv:value($n/tei:placeName[@xml:lang="zh-latn-pinyin"][1])
    let $site-name-zh-Hant := tei2tsv:value($n/tei:placeName[@xml:lang="zh-Hant"][1])
    let $site-name-zh-Hans := tei2tsv:value($n/tei:placeName[@xml:lang="zh-Hans"][1])
    let $site-name-Wade-Giles := tei2tsv:value($n/tei:placeName[@xml:lang="Wade-Giles" or @xml:lang = 'zh-latn-wadegile'][1])
    let $site-name-other := tei2tsv:value($n/tei:placeName[6])
    let $site-name-other2 := tei2tsv:value($n/tei:placeName[7])
    let $site-name-other3 := tei2tsv:value($n/tei:placeName[8])  
    let $site-name-other4 := tei2tsv:value($n/tei:placeName[9])  
    let $site-name-other5 := tei2tsv:value($n/tei:placeName[10])  
    let $site-name-other6 := tei2tsv:value($n/tei:placeName[11])  
    let $site-name-other7 := tei2tsv:value($n/tei:placeName[12])  
    let $site-name-other8 := tei2tsv:value($n/tei:placeName[13])  
    let $site-name-other9 := tei2tsv:value($n/tei:placeName[14])  
    let $site-name-other10 := tei2tsv:value($n/tei:placeName[15])  
    let $date := concat($n/tei:state[@type="existence"][1]/@from,'/',$n/tei:state[@type="existence"][1]/@to)
    let $dynasty := tei2tsv:value($n/tei:state[@subtype="dynasty"]/tei:desc)
    let $site-data := tei2tsv:value($n/tei:desc[@type="site-data"])
    let $site-type := tei2tsv:value($n/tei:trait[@type="type"])
    let $buildings-in-site := string($record/descendant::tei:relation[@ref="schema:containedInPlace"]/@passive)
    return 
        concat(
            string-join(($title,$uri,$principal,$editor,$editor2,$editor3,$published,
            $site-name-en, $site-name-zh-latn-pinyin, $site-name-zh-Hant, $site-name-zh-Hans, $site-name-Wade-Giles, 
            $site-name-other, $site-name-other2, $site-name-other3, $site-name-other4, $site-name-other5, $site-name-other6,
            $site-name-other7, $site-name-other8, $site-name-other9, $site-name-other10, 
            $date, $dynasty, $site-data, $site-type, $buildings-in-site),"&#x9;"),'&#xa;'))
return concat($headers,($data))    
};

declare function tei2tsv:tei2tsv-keywords($nodes as node()*) {
let $headers :=concat(string-join(
                ('title', 'uri','principal','principal2','principal3','editor', 'editor2', 'editor3', 'published','team',
                 'term-en','term-literal_translation','term-zh-latn-pinyin','term-zh-Hant',
                 'term-zh-Hans','term-Wade-Giles','term-other','term-other2',
                 'getty-scopeNote-en','getty-scopeNote-zh-hant',
                 'sources-note-en','sources-note-zh-hant',
                 'scope-note-brief-en','scope-note-brief-zh-hant',
                 'scope-note-full-en','scope-note-full-zh-hant',
                 'note-brief-en','note-brief-zh-hant',
                 'note-full-en','note-full-zh-hant',
                 'related-concepts-en','related-concepts-zh-hant',
                 'related-concepts2-en','related-concepts2-zh-hant',
                 'related-concepts3-en','related-concepts3-zh-hant',
                 'related-concepts4-en','related-concepts4-zh-hant',
                 'related-concepts5-en','related-concepts5-zh-hant',
                 'related-concepts6-en','related-concepts6-zh-hant',
                 'related-concepts7-en','related-concepts7-zh-hant',
                 'related-concepts8-en','related-concepts8-zh-hant',
                 'related-concepts9-en','related-concepts9-zh-hant',
                 'related-concepts10-en','related-concepts10-zh-hant',
                 'related-terms-en','related-terms-zh-hant',
                 'otherNote','otherNote2',
                 'bibl','relations'),"&#x9;"),
                  '&#xa;')
let $data :=                   
    string-join(
    for $record in $nodes//tei:TEI
    let $n := $record/descendant::tei:entryFree
    let $title := tei2tsv:value($record/descendant::tei:title[1])
    let $uri := replace($record/descendant::tei:idno[1],'/tei','')
    let $principal := tei2tsv:value($record/descendant::tei:principal[1])
    let $principal2 := tei2tsv:value($record/descendant::tei:principal[2])
    let $principal3 := tei2tsv:value($record/descendant::tei:principal[3])
    let $editor := tei2tsv:value($record/descendant::tei:editor[1])
    let $editor2 := tei2tsv:value($record/descendant::tei:editor[2])
    let $editor3 := tei2tsv:value($record/descendant::tei:editor[3])
    let $published := tei2tsv:value($record/descendant::tei:publicationStmt/tei:date)
    let $team := tei2tsv:value($record/descendant::tei:name[@type='team'])
    let $term1 := tei2tsv:value($n/tei:term[@xml:lang="en"][1])
    let $term2 := tei2tsv:value($n/tei:term[@xml:lang="en"][@type="literal_translation"])
    let $term3 := tei2tsv:value($n/tei:term[@xml:lang="zh-latn-pinyin"][1])
    let $term4 := tei2tsv:value($n/tei:term[@xml:lang="zh-Hant"][1])
    let $term5 := tei2tsv:value($n/tei:term[@xml:lang="zh-Hans"][1])
    let $term6 := tei2tsv:value($n/tei:term[@xml:lang="Wade-Giles" or @xml:lang = 'zh-latn-wadegile'][1])
    let $term7 := tei2tsv:value($n/tei:term[6])
    let $term8 := tei2tsv:value($n/tei:term[7])  
    let $getty-scopeNote-en := tei2tsv:value($n/tei:note[@type="getty:scopeNote" or @type="Scope Note"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $getty-scopeNote-zh-hant := tei2tsv:value($n/tei:note[@type="getty:scopeNote" or @type="Scope Note"]/tei:p[@xml:lang = 'zh-Hant'])
    let $sources-note-en := tei2tsv:value($n/tei:note[@type="sources"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $sources-note-zh-hant := tei2tsv:value($n/tei:note[@type="sources"]/tei:p[@xml:lang = 'zh-Hant'])
    let $scope-note-brief-en := tei2tsv:value($n/tei:note[@type="Scope Note (brief)"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $scope-note-brief-zh-hant := tei2tsv:value($n/tei:note[@type="Scope Note (brief)"]/tei:p[@xml:lang = 'zh-Hant'])    
    let $scope-note-full-en := tei2tsv:value($n/tei:note[@type="Scope Note (full)"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $scope-note-full-zh-hant := tei2tsv:value($n/tei:note[@type="Scope Note (full)"]/tei:p[@xml:lang = 'zh-Hant'])
    let $note-brief-en := tei2tsv:value($n/tei:note[@type="Note (brief)"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $note-brief-zh-hant := tei2tsv:value($n/tei:note[@type="Note (brief)"]/tei:p[@xml:lang = 'zh-Hant'])    
    let $note-full-en := tei2tsv:value($n/tei:note[@type="Note (full)"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $note-full-zh-hant := tei2tsv:value($n/tei:note[@type="Note (full)"]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts-en := tei2tsv:value($n/tei:note[@type="related concepts"][1]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][1]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts2-en := tei2tsv:value($n/tei:note[@type="related concepts"][2]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts2-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][2]/tei:p[@xml:lang = 'zh-Hant'])    
    let $related-concepts3-en := tei2tsv:value($n/tei:note[@type="related concepts"][3]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts3-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][3]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts4-en := tei2tsv:value($n/tei:note[@type="related concepts"][4]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts4-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][4]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts5-en := tei2tsv:value($n/tei:note[@type="related concepts"][5]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts5-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][5]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts6-en := tei2tsv:value($n/tei:note[@type="related concepts"][6]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts6-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][6]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts7-en := tei2tsv:value($n/tei:note[@type="related concepts"][7]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts7-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][7]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts8-en := tei2tsv:value($n/tei:note[@type="related concepts"][8]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts8-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][8]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts9-en := tei2tsv:value($n/tei:note[@type="related concepts"][9]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts9-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][9]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-concepts10-en := tei2tsv:value($n/tei:note[@type="related concepts"][10]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-concepts10-zh-hant := tei2tsv:value($n/tei:note[@type="related concepts"][10]/tei:p[@xml:lang = 'zh-Hant'])
    let $related-terms-en := tei2tsv:value($n/tei:note[@type="related terms"]/tei:p[@xml:lang = 'en' or not(@xml:lang)])
    let $related-terms-zh-hant := tei2tsv:value($n/tei:note[@type="related terms"]/tei:p[@xml:lang = 'zh-Hant'])
    let $otherNote := tei2tsv:value($n/tei:note[not(@type)][1])
    let $otherNote2 := tei2tsv:value($n/tei:note[not(@type)][2])
    let $bibl := string-join(
        for $b in $n/tei:bibl 
        return concat($b/tei:ptr/@target,': ', string-join(for $cite in $b/tei:citedRange return $cite/text(),' ')),' | ')
    let $relations := string-join(
        for $r in $n//tei:relation
        return concat($r/@ref,': ', $r/@passive),' | ')
    return 
        concat(
            string-join(($title,$uri,$principal,$principal2,
            $principal3,$editor,$editor2,$editor3,$published,$team,
            $term1,$term2,$term3,$term4,$term5,$term6,
            $term7,$term8,$getty-scopeNote-en, $getty-scopeNote-zh-hant,
            $sources-note-en,$sources-note-zh-hant,$scope-note-brief-en,$scope-note-brief-zh-hant,    
            $scope-note-full-en,$scope-note-full-zh-hant,
            $note-brief-en,$note-brief-zh-hant,$note-full-en,$note-full-zh-hant,
            $related-concepts-en, $related-concepts-zh-hant,
            $related-concepts2-en,$related-concepts2-zh-hant,$related-concepts3-en,$related-concepts3-zh-hant,
            $related-concepts4-en,$related-concepts4-zh-hant,$related-concepts5-en,$related-concepts5-zh-hant,
            $related-concepts6-en,$related-concepts6-zh-hant,$related-concepts7-en,$related-concepts7-zh-hant,
            $related-concepts8-en,$related-concepts8-zh-hant,$related-concepts9-en,$related-concepts9-zh-hant,
            $related-concepts10-en,$related-concepts10-zh-hant,$related-terms-en,$related-terms-zh-hant,
            $otherNote,$otherNote2,$bibl,$relations
            ),"&#x9;"),'&#xa;'))
return concat($headers,($data))    
};
