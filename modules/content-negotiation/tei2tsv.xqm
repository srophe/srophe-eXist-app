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

declare function tei2tsv:tei2tsv($nodes as node()*) {
let $headers :=concat(string-join(
                ('title', 'uri','principal','principal2','principal3','editor', 'editor2', 'editor3', 'published',
                 'term-en','term-zh-latn-pinyin','term-zh-Hant',
                 'term-zh-Hans','term-Wade-Giles','term-other','term-other2',
                 'getty-scopeNote-en','getty-scopeNote-zh-Hans',
                 'sources-note-en','sources-note-zh-Hans',
                 'scope-note-brief-en','scope-note-brief-zh-Hans',
                 'scope-note-full-en','scope-note-full-zh-Hans',
                 'note-brief-en','note-brief-zh-Hans',
                 'note-full-en','note-full-zh-Hans',
                 'related-concepts-en','related-concepts-zh-Hans',
                 'related-concepts2-en','related-concepts2-zh-Hans',
                 'related-concepts3-en','related-concepts3-zh-Hans',
                 'related-concepts4-en','related-concepts4-zh-Hans',
                 'related-concepts5-en','related-concepts5-zh-Hans',
                 'related-concepts6-en','related-concepts6-zh-Hans',
                 'related-concepts7-en','related-concepts7-zh-Hans',
                 'related-concepts8-en','related-concepts8-zh-Hans',
                 'related-concepts9-en','related-concepts9-zh-Hans',
                 'related-concepts10-en','related-concepts10-zh-Hans',
                 'related-terms-en','related-terms-zh-Hans',
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
    let $term1 := tei2tsv:value($n/tei:term[@xml:lang="en"][1])
    let $term2 := tei2tsv:value($n/tei:term[@xml:lang="zh-latn-pinyin"][1])
    let $term3 := tei2tsv:value($n/tei:term[@xml:lang="zh-Hant"][1])
    let $term4 := tei2tsv:value($n/tei:term[@xml:lang="zh-Hans"][1])
    let $term5 := tei2tsv:value($n/tei:term[@xml:lang="Wade-Giles"][1])
    let $term6 := tei2tsv:value($n/tei:term[5])
    let $term7 := tei2tsv:value($n/tei:term[6])  
    let $getty-scopeNote-en := tei2tsv:value($n/tei:note[@type="getty:scopeNote" or @type="Scope Note"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $getty-scopeNote-zh-Hans := tei2tsv:value($n/tei:note[@type="getty:scopeNote" or @type="Scope Note"][tei:p[@xml:lang = 'zh-Hans']])
    let $sources-note-en := tei2tsv:value($n/tei:note[@type="sources"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $sources-note-zh-Hans := tei2tsv:value($n/tei:note[@type="sources"][tei:p[@xml:lang = 'zh-Hans']])
    let $scope-note-brief-en := tei2tsv:value($n/tei:note[@type="Scope Note (brief)"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $scope-note-brief-zh-Hans := tei2tsv:value($n/tei:note[@type="Scope Note (brief)"][tei:p[@xml:lang = 'zh-Hans']])    
    let $scope-note-full-en := tei2tsv:value($n/tei:note[@type="Scope Note (full)"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $scope-note-full-zh-Hans := tei2tsv:value($n/tei:note[@type="Scope Note (full)"][tei:p[@xml:lang = 'zh-Hans']])
    let $note-brief-en := tei2tsv:value($n/tei:note[@type="Note (brief)"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $note-brief-zh-Hans := tei2tsv:value($n/tei:note[@type="Note (brief)"][tei:p[@xml:lang = 'zh-Hans']])    
    let $note-full-en := tei2tsv:value($n/tei:note[@type="Note (full)"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $note-full-zh-Hans := tei2tsv:value($n/tei:note[@type="Note (full)"][tei:p[@xml:lang = 'zh-Hans']])
    let $related-concepts-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][1])
    let $related-concepts-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][1])
    let $related-concepts2-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][2])
    let $related-concepts2-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][2])    
    let $related-concepts3-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][3])
    let $related-concepts3-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][3])
    let $related-concepts4-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][4])
    let $related-concepts4-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][4])
    let $related-concepts5-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][5])
    let $related-concepts5-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][5])
    let $related-concepts6-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][6])
    let $related-concepts6-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][6])
    let $related-concepts7-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][7])
    let $related-concepts7-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][7])
    let $related-concepts8-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][8])
    let $related-concepts8-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][8])
    let $related-concepts9-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][9])
    let $related-concepts9-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][9])
    let $related-concepts10-en := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]][10])
    let $related-concepts10-zh-Hans := tei2tsv:value($n/tei:note[@type="related concepts"][tei:p[@xml:lang = 'zh-Hans']][10])
    let $related-terms-en := tei2tsv:value($n/tei:note[@type="related terms"][tei:p[@xml:lang = 'en'] or tei:p[not(@xml:lang)]])
    let $related-terms-zh-Hans := tei2tsv:value($n/tei:note[@type="related terms"][@xml:lang = 'zh-Hans'])    
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
            $principal3,$editor,$editor2,$editor3,$published,
            $term1,$term2,$term3,$term4,$term5,$term6,
            $term7,$getty-scopeNote-en, $getty-scopeNote-zh-Hans,
            $sources-note-en,$sources-note-zh-Hans,$scope-note-brief-en,$scope-note-brief-zh-Hans,    
            $scope-note-full-en,$scope-note-full-zh-Hans,
            $note-brief-en,$note-brief-zh-Hans,$note-full-en,$note-full-zh-Hans,
            $related-concepts-en, $related-concepts-zh-Hans,
            $related-concepts2-en,$related-concepts2-zh-Hans,$related-concepts3-en,$related-concepts3-zh-Hans,
            $related-concepts4-en,$related-concepts4-zh-Hans,$related-concepts5-en,$related-concepts5-zh-Hans,
            $related-concepts6-en,$related-concepts6-zh-Hans,$related-concepts7-en,$related-concepts7-zh-Hans,
            $related-concepts8-en,$related-concepts8-zh-Hans,$related-concepts9-en,$related-concepts9-zh-Hans,
            $related-concepts10-en,$related-concepts10-zh-Hans,$related-terms-en,$related-terms-zh-Hans,
            $otherNote,$otherNote2,$bibl,$relations
            ),"&#x9;"),'&#xa;'))
return concat($headers,($data))    
};
