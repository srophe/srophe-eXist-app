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

(:
bibl citedRange desc 
entryFree gloss idno listBibl 
listRelation note p ptr relation state term
:)
declare function tei2tsv:tei2tsv($nodes as node()*) {
let $headers :=concat(string-join(
                ('title', 'uri','principal','principal2','principal3','editor', 'editor2', 'editor3', 'published',
                 'term-en','term-zh-latn-pinyin','term-zh-Hant',
                 'term-zh-Hans','term-Wade-Giles','term-other','term-other2',
                 'scopeNote','sourceNote','otherNote','otherNote2',
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
    let $note := tei2tsv:value($n/tei:note[@type="getty:scopeNote"])
    let $note2 := tei2tsv:value($n/tei:note[@type="sources"])
    let $note3 := tei2tsv:value($n/tei:note[not(@type="getty:scopeNote") and not(@type="sources")][1])
    let $note4 := tei2tsv:value($n/tei:note[not(@type="getty:scopeNote") and not(@type="sources")][2])
    let $bibl := string-join(
        for $b in $n/tei:bibl 
        return concat($b/tei:ptr/@target,': ', $b/tei:citedRange/text()),' | ')
    let $relations := string-join(
        for $r in $n//tei:relation
        return concat($r/@ref,': ', $r/@passive),' | ')
    return 
        concat(
            string-join(($title,$uri,$principal,$principal2,
            $principal3,$editor,$editor2,$editor3,$published,
            $term1,$term2,$term3,$term4,$term5,$term6,
            $term7,$note,$note2,$note3,$note4,$bibl,$relations
            ),"&#x9;"),'&#xa;'))
return concat($headers,($data))    
};
