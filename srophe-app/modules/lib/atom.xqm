xquery version "3.0";
(:
 : Build atom feed for all syrica.org modules
 : Module is used by atom.xql and rest.xqm 
 : @param $collection selects data collection for feed 
 : @param $id return single entry matching xml:id
 : @param $start start paged results
 : @param $perpage default set to 25 can be changed via perpage param
:)
module namespace feed="http://syriaca.org/atom";
import module namespace global="http://syriaca.org/global" at "global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace georss="http://www.georss.org/georss";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

(:~
 : Return subsequence of full feed passed from search results or search api
 : @param $nodes name of syriaca.org subcollection 
 : @param $start start position for results
 : @param $perpage number of pages to return 
 : @return An atom entry element
:)
declare function feed:build-search-feed($nodes as node()*,$start as xs:integer?, $perpage as xs:integer?){
    for $rec in subsequence($nodes,$start, $perpage)
    return feed:build-entry($rec)
};

(:~
 : Correctly format dates in the TEI
 : @param $date date passed from TEI records
 : @return A string
:)
declare function feed:format-dates($date as xs:string?) as xs:string?{
    if($date) then 
        if(string-length($date) = 10) then concat($date,'T12:00:00Z')
        else if(string-length($date) = 4) then concat($date,'01-01T12:00:00Z')
        else if(string-length($date) gt 10) then concat(substring($date,1,10),'T12:00:00Z')
        else ()
    else ()
};

(:~
 : Get single entry 
 : @param $node tei data passed to library function 
 : @param $id record id
 : @return As atom feed element
:)
declare function feed:get-entry($node as node()?) as element()?{ 
    let $rec := if($node/self::tei:TEI) then $node else $node/ancestor::tei:TEI
    let $subtitle := if($rec//tei:titleStmt/tei:title[2]) then concat(': ',$rec//tei:titleStmt/tei:title[2]) else ()
    let $title := concat(string($rec//tei:titleStmt/tei:title[1]),$subtitle)
    let $date := $node[1]//tei:publicationStmt[1]/tei:date[1]/text()
    let $rec-id := substring-before($rec//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei')
    return 
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
            <title>{$title}</title>
            <link rel="self" type="application/atom+xml" href="{$rec-id}/atom"/>
            <id>tag:{replace($global:base-uri,'http://','')},{if($rec//tei:publicationStmt/tei:date[. != '']) then substring($rec//tei:publicationStmt/tei:date[. != ''],1,4) else '2013'}:{$rec-id}/atom</id>
            <updated xmlns="http://www.w3.org/2005/Atom">{feed:format-dates($date)}</updated>
            {feed:build-entry($rec)}
        </feed>
};
 
(:~
 : Build atom entry from TEI record data
 : @param $rec TEI record
 : @return A atom entry element
:)
declare function feed:build-entry($node as element()*) as element(entry){
    let $rec := if($node/self::tei:TEI) then $node else $node/ancestor::tei:TEI
    let $rec-id := substring-before($rec//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][1],'/tei')
    let $subtitle := if($rec//tei:titleStmt/tei:title[2]) then concat(': ',$rec//tei:titleStmt/tei:title[2]) else ()
    let $title := concat(string($rec//tei:titleStmt/tei:title[1]),$subtitle)
    let $date := $rec//tei:publicationStmt[1]/tei:date[1]/text()
    let $geo := if($rec//tei:geo) then <georss:point>{string($rec//tei:geo)}</georss:point> else ()         
    let $res-pers :=  
                let $author-name := distinct-values($rec//tei:titleStmt/tei:editor) 
                for $author in $author-name
                return <author xmlns="http://www.w3.org/2005/Atom"><name>{$author}</name></author>
    let $summary := 
        if($rec//tei:desc[contains(@xml:id,'abstract')]) then
            <summary xmlns="http://www.w3.org/2005/Atom">
                {
                    for $sum in $rec//tei:desc[contains(@xml:id,'abstract')]
                    return feed:tei2atom($sum)
                }
            </summary>
        else ()
    return    
    <entry xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss">
        <title>{normalize-space($title)}</title>
        <link rel="alternate" type="text/html" href="{$rec-id}"/>
        <link rel="alternate" type="text/xml" href="{$rec-id}/tei"/>
        <link rel="self" type="application/atom+xml" href="{$rec-id}/atom"/>
        <id>tag:{replace($global:base-uri,'http://','')},2013:{$rec-id}</id>
        {$geo}
        <updated>{feed:format-dates($date)}</updated>
        {($summary, $res-pers)}
    </entry>  
};

(:~
 : Build atom feed
 : @param $nodes passed to module from search or browse 
 : @return A atom feed element
:)
declare function feed:build-atom-feed($nodes as node()*, $title as xs:string*) as element(feed)?{ 
let $title := if($title !='') then $title else $global:app-title 
return             
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss"> 
        <title>{$title}</title>
        <link href="http://syriaca.org/"/>
        <link rel="self" type="application/atom+xml" href="{$self}"/>
        {($next)}
        <id>tag:{replace($global:base-uri,'http://','')},{if($rec//tei:publicationStmt/tei:date[. != '']) then substring($rec//tei:publicationStmt/tei:date[. != ''],1,4) else '2013'}:{$title}/atom</id>
        <updated xmlns="http://www.w3.org/2005/Atom">{feed:format-dates($nodes[1]//tei:publicationStmt[1]/tei:date[1])}</updated>
        <author>
          <name>{if($rec//tei:publicationStmt/tei:authority) then $rec//tei:publicationStmt/tei:authority else $global:app-title}</name>
        </author>
        {feed:build-search-feed($nodes,$start,$perpage)}
    </feed>
};

(:~
 : Typeswitch to output all child elements in atom summary
 : @param $node elements passed to function
:)
declare function feed:tei2atom($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case text() return
                $node
            case comment() return ()
            case element() return
                feed:tei2atom($node/node())
            default return
                $node/string()
};
