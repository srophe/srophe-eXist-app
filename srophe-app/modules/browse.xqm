xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace browse="http://syriaca.org//browse";

import module namespace templates="http://syriaca.org//templates" at "templates.xql";
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) for browse display 
 : @param $browse:type selects doc type filter
 : @param $browse:view selects language for browse display
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:type {request:get-parameter('type', '')}; 
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};
declare variable $browse:type-map {request:get-parameter('type-map', '')};
declare variable $browse:date {request:get-parameter('date', '')};

(:~
 : Build browse path for evaluation
:)
declare function browse:get-all($node as node(), $model as map(*), $coll as xs:string?){
let $browse-path := 
    if(exists($coll)) then 
        if($coll = 'persons') then concat("collection('",$config:app-root,"/data/persons/tei')//tei:person",browse:get-syr()) 
        else if($coll = 'places') then concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr()) 
        else concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr())
    else concat("collection('",$config:app-root,"/data/places/tei')//tei:place",browse:get-syr())
return 
    map{"browse-data" := util:eval($browse-path)}        
};

(:~
 : Build browse using supplied options
 : @param $browse:type place type browse
 : @param $browse:view browse option, lang or map
 : @param $browse:sort place returned by first character in title
:)
declare function browse:build-browse-results($node as node(), $model as map(*)){  
    for $data in $model('browse-data')
    let $id := string($data/@xml:id)
    let $type := string($data/@type)
    let $ana := string($data/@ana)
    let $en-title := 
        if($data/tei:persName[@syriaca-tags='#syriaca-headword']) then 
            if($data/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang,'en'][1]/child::*) then
                $data/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang,'en'][1]/child::*[1]/text()
            else $data/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang,'en'][1]/text()
        else    
            $data/tei:placeName[starts-with(@xml:lang,'en')][1]/text() 
    let $syr-title := 
        if($data/tei:persName[@syriaca-tags='#syriaca-headword']) then
            $data/tei:persName[@syriaca-tags='#syriaca-headword'][@xml:lang,'syr'][1]/child::*[1]/text()
        else $data/tei:placeName[@xml:lang = 'syr'][1]/text()
    let $title := 
        if($browse:view = 'syr') then $syr-title else $en-title
    let $browse-title := browse:build-sort-string($title)
    where contains(browse:get-sort(), substring($browse-title,1,1))
    return
        <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$type}" ana="{$ana}" sort-title="{$browse-title}">
            {
                for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                return $browse-name
            }
        </browse>
};


(:~
 : Returns a list places by type
 : @param $browse:type indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
:)
declare function browse:get-place-type($node as node(), $model as map(*)){
    for $data in $model('browse-data')//self::*[@type = $browse:type]
    let $id := string($data/@xml:id)
    let $type := string($data/@type)
    let $ana := string($data/@ana)
    let $title := 
        if($browse:view = 'syr') then $data/tei:placeName[@xml:lang = 'syr'][1]/text()
        else $data/tei:placeName[1]/text()
    let $browse-title := browse:build-sort-string($title)
    let $geo := $data/descendant::*/tei:geo
    return 
     <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$type}" ana="{$ana}" sort-title="{$browse-title}">
            {
                (
                for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                return $browse-name,
                $geo
                )
            }
        </browse>
};

(:~
 : Returns a list persons by type
 : @param $browse:type indicates language of browse list
 : @param $browse:sort indicates letter for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
 :)
declare function browse:get-pers-type($node as node(), $model as map(*)){
    for $data in $model('browse-data')
    let $id := string($data/@xml:id)
    let $type := string($data/@type)
    let $ana := string($data/@ana)
    let $title := 
        if($browse:view = 'syr') then $data/tei:placeName[@xml:lang = 'syr'][1]/text()
        else $data/tei:placeName[1]/text()
    let $browse-title := browse:build-sort-string($title)
    where if($browse:type != '') then 
            if($browse:type = 'unknown') then $data[not(@ana)]
            else $data[@ana = concat('#',$browse:type)]
          else ()  
    return 
     <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" type="{$type}" ana="{$ana}" sort-title="{$browse-title}">
            {
                (
                for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                return $browse-name,
                if($data/descendant::*/tei:geo) then $data/descendant::*/tei:geo else ()
                )
            }
        </browse>
};

(:~
 : Returns a list persons by date
 : @param $browse:type indicates language of browse list
 : @param $browse:date indicates date for browse
 : Uses browse:build-sort-string() to strip title of non sort characters
 :)
declare function browse:get-pers-date($node as node(), $model as map(*)){  
    if($browse:date = 'BC dates') then
        browse:get-pers-date-bc($node, $model)
    else browse:get-pers-date-ad($node, $model)
};

declare function browse:get-pers-date-bc($node as node(), $model as map(*)){  
        for $data in $model('browse-data')[starts-with(descendant::*/@notBefore,'-') or starts-with(descendant::*/@notAfter,'-')]
        let $id := string($data/@xml:id)
        let $ana := string($data/@ana)
        let $title := $data/tei:persName[1]
        let $browse-title := browse:build-sort-string($title) 
        return 
            <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" ana="{$ana}" sort-title="{$browse-title}" date="{$browse:date}">
                {
                    for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                    return $browse-name
                }
            </browse>
};
declare function browse:get-pers-date-ad($node as node(), $model as map(*)){  
        let $end :=
            if($browse:date = '0-100') then xs:date('0100-01-01')
            else if($browse:date = '100-200') then xs:date('0200-01-01')
            else if($browse:date = '200-300') then xs:date('0300-01-01')
            else if($browse:date = '300-400') then xs:date('0400-01-01')
            else if($browse:date = '400-500') then xs:date('0500-01-01')
            else if($browse:date = '500-600') then xs:date('0600-01-01')
            else if($browse:date = '600-700') then xs:date('0700-01-01')
            else if($browse:date = '700-800') then xs:date('0800-01-01')
            else if($browse:date = '800-900') then xs:date('0900-01-01')
            else if($browse:date = '900-1000') then xs:date('1000-01-01')
            else if($browse:date = '1000-1100') then xs:date('1100-01-01')
            else if($browse:date = '1100-1200') then xs:date('1200-01-01')
            else if($browse:date = '1200-1300') then xs:date('1300-01-01')
            else if($browse:date = '1300-1400') then xs:date('1400-01-01')
            else if($browse:date = '1400-1500') then xs:date('1500-01-01')
            else if($browse:date = '1500-1600') then xs:date('1600-01-01')
            else if($browse:date = '1600-1700') then xs:date('1700-01-01')
            else if($browse:date = '1700-1800') then xs:date('1800-01-01')
            else if($browse:date = '1800-1900') then xs:date('1900-01-01')
            else if($browse:date = '1900-2000') then xs:date('2000-01-01')
            else if($browse:date = '2000-') then xs:date('2100-01-01')
            else xs:date('0100-01-01')
        let $start := 
            if($browse:date = '0-100') then xs:date('0001-01-01')
            else if($browse:date = '100-200') then xs:date('0100-01-01')
            else if($browse:date = '200-300') then xs:date('0200-01-01')
            else if($browse:date = '300-400') then xs:date('0300-01-01')
            else if($browse:date = '400-500') then xs:date('0400-01-01')
            else if($browse:date = '500-600') then xs:date('0500-01-01')
            else if($browse:date = '600-700') then xs:date('0600-01-01')
            else if($browse:date = '700-800') then xs:date('0700-01-01')
            else if($browse:date = '800-900') then xs:date('0800-01-01')
            else if($browse:date = '900-1000') then xs:date('0900-01-01')
            else if($browse:date = '1000-1100') then xs:date('1000-01-01')
            else if($browse:date = '1100-1200') then xs:date('1100-01-01')
            else if($browse:date = '1200-1300') then xs:date('1200-01-01')
            else if($browse:date = '1300-1400') then xs:date('1300-01-01')
            else if($browse:date = '1400-1500') then xs:date('1400-01-01')
            else if($browse:date = '1500-1600') then xs:date('1500-01-01')
            else if($browse:date = '1600-1700') then xs:date('1600-01-01')
            else if($browse:date = '1700-1800') then xs:date('1700-01-01')
            else if($browse:date = '1800-1900') then xs:date('1800-01-01')
            else if($browse:date = '1900-2000') then xs:date('1900-01-01')
            else if($browse:date = '2000-') then xs:date('2000-01-01')
            else xs:date('0100-01-01')
        for $data in $model('browse-data')[descendant::*/@syriaca-computed-start lt $end][descendant::*/@syriaca-computed-end gt $start]
        let $id := string($data/@xml:id)
        let $ana := string($data/@ana)
        let $title := $data/tei:persName[1]
        let $browse-title := browse:build-sort-string($title) 
        return 
            <browse xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$id}" ana="{$ana}" sort-title="{$browse-title}" date="{$browse:date}">
                {
                    for $browse-name in $data/child::*[@syriaca-tags="#syriaca-headword"]
                    return $browse-name
                }
            </browse>
};

(:~
 : Filter titles by syriac 
 : @param $browse:view
:)
declare function browse:get-syr(){
    if($browse:view = 'syr') then
        "[child::*[@xml:lang = 'syr'][@syriaca-tags='#syriaca-headword']]"
    else ()    
};

(:~
 : Filter titles by type 
 : @param $browse:view
:)
declare function browse:get-type(){
    if($browse:type != '') then
        concat('[@type =', $browse:type,']')
    else ()    
};
(:~
 : Builds collation for syriac results
 : @param $browse:view
:)
declare function browse:get-order(){
    if($browse:view = 'syr') then
        'collation "?view=syr"'
    else ()
};

(:~
 : Matches English letters and thier equivalent letters as established by The Syriac Gazetteer
 : @param $browse:sort indicates letter for browse
 :)
declare function browse:get-sort(){
    if(exists($browse:sort) and $browse:sort != '') then
        if($browse:sort = 'A') then 'A a ẵ Ẵ ằ Ằ ā Ā'
        else if($browse:sort = 'D') then 'D d đ Đ'
        else if($browse:sort = 'S') then 'S s š Š ṣ Ṣ'
        else if($browse:sort = 'E') then 'E e ễ Ễ'
        else if($browse:sort = 'U') then 'U u ū Ū'
        else if($browse:sort = 'H') then 'H h ḥ Ḥ'
        else if($browse:sort = 'T') then 'T t ṭ Ṭ'
        else if($browse:sort = 'I') then 'I i ī Ī'
        else if($browse:sort = 'O') then 'O Ō o Œ œ'
        else $browse:sort
    else 'A a ẵ Ẵ ằ Ằ ā Ā'
};

(:~
 : Strips english titles of non-sort characters as established by The Syriac Gazetteer
 :)
declare function browse:build-sort-string($titlestring){
    replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]','')
};

(:~
 : Returns a count of all places with coordinates
:)
declare function browse:count-geo($node as node(), $model as map(*)){
    count($model("browse-data")//self::*[descendant::*/tei:geo]) 
};

(:~
 : Returns a count of all places
:)
declare function browse:count-all($node as node(), $model as map(*)){
    count($model("browse-data")) 
};

(:~
 : Build browse type menu with count for each type
:)
declare function browse:type-counts($node as node(), $model as map(*), $coll as xs:string?){
if($browse:view = 'type') then 
    if($coll = 'persons') then     
    <div class="col-md-4 clearfix">
        <ul class="nav nav-tabs nav-stacked">
            {
                for $types in $model("browse-data")
                group by $pers-types := $types/@ana
                order by $pers-types ascending
                return
                    let $pers-types-labels := if($pers-types) then replace(string($pers-types),'#','') else 'unknown'
                    return
                    <li>{if($browse:type = $pers-types-labels) then attribute class {'active'} else '' }
                        <a href="?view=type&amp;type={$pers-types-labels}">
                        {if(string($pers-types) = '') then 'unknown' else replace(string($pers-types),'#syriaca-','')}  <span class="count"> ({count($types)})</span>
                        </a>
                    </li>
            }
        </ul>
    </div>
    else
    <div class="col-md-4 clearfix">
        <ul class="nav nav-tabs nav-stacked">
            {
                for $types in $model("browse-data")
                group by $place-types := $types/@type
                order by $place-types ascending
                return
                    <li>{if($browse:type = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                        <a href="?view=type&amp;type={$place-types}">
                        {if(string($place-types) = '') then 'unknown' else replace(string($place-types),'#|-',' ')}  <span class="count"> ({count($types)})</span>
                        </a>
                    </li>
            }
        </ul>
    </div>    
else if($browse:view = 'date') then browse:build-date-menu()
else ()
};

declare function browse:build-date-menu(){
    <div class="col-md-4">
        <ul class="nav nav-tabs nav-stacked pull-left type-nav">
            {
                let $all-dates := 'BC dates, 0-100, 100-200, 200-300, 300-400, 400-500, 500-600, 700-800, 800-900, 900-1000, 1100-1200, 1200-1300, 1300-1400, 1400-1500, 1500-1600, 1600-1700, 1700-1800, 1800-1900, 1900-2000, 2000-'
                for $date in tokenize($all-dates,', ')
                return
                    <li>{if($browse:date = $date) then attribute class {'active'} else '' }
                        <a href="?view=date&amp;date={$date}">
                            {$date}  <!--<span class="count"> ({count($types)})</span>-->
                        </a>
                    </li>
            }
        </ul>
    </div>
};

declare function browse:build-tabs($node as node(), $model as map(*), $coll as xs:string?){
if($coll = 'persons') then 
    <ul class="nav nav-tabs" id="nametabs">
        <li>{if(not($browse:view)) then 
                attribute class {'active'} 
             else if($browse:view = 'en') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
        </li>
        <li>{if($browse:view = 'syr') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
        </li>
        <li>{if($browse:view = 'type') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=type">Type</a>
        </li>
        <li>{if($browse:view = 'date') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=date">Date</a>
        </li>
    </ul>
else
    <ul class="nav nav-tabs" id="nametabs">
        <li>{if(not($browse:view)) then 
                attribute class {'active'} 
            else if($browse:view = 'en') then 
                attribute class {'active'} else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
        </li>
        <li>{if($browse:view = 'syr') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
        </li>
        <li>{if($browse:view = 'type') then 
                attribute class {'active'}
             else '' }<a href="browse.html?view=type">Type</a>
        </li>
        <li>{if($browse:view = 'map') then 
                attribute class {'active'} 
             else '' }<a href="browse.html?view=map">Map</a>
        </li>
    </ul>
};

(:~
 : Builds tei node to be transformed by xslt
 : Final results are passed to ../resources/xsl/browselisting.xsl
 :)
declare %templates:wrap function browse:get-browse-names($node as node(), $model as map(*), $coll as xs:string?){
    let $cache := 'change this value to force page refresh 28'
    let $results := 
     <tei:TEI xml:lang="en"
        xmlns:xi="http://www.w3.org/2001/XInclude"
        xmlns:svg="http://www.w3.org/2000/svg"
        xmlns:math="http://www.w3.org/1998/Math/MathML"
        xmlns="http://www.tei-c.org/ns/1.0" browse-coll="{$coll}" browse-view="{$browse:view}" browse-sort="{$browse:sort}" browse-type="{$browse:type}" browse-type-map="{$browse:type-map}">
        {
            (
            if($browse:view = 'map') then 
                <tei:count-geo>
                *{browse:count-geo($node, $model)} of {browse:count-all($node, $model)} places have coordinates 
                and are shown on this map. <a href="#map-selection" role="button"  data-toggle="modal">
                Read more...</a>
                </tei:count-geo>
             else (),  
             if($browse:view = 'type') then 
                if($browse:type != '') then
                    if($coll = 'persons') then 
                        browse:get-pers-type($node, $model)
                    else
                        browse:get-place-type($node, $model) 
                else 'Type'
             else if($browse:view = 'date') then
                if($browse:date = '') then 'Date'
                else browse:get-pers-date($node, $model)
             else browse:build-browse-results($node, $model)
            )
          }
     </tei:TEI>  
    return 
    (:$results:)
    transform:transform($results, doc('../resources/xsl/browselisting.xsl'),() )
};
