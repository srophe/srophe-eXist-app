xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Browse by type
 :
 : @see lib/geojson.xqm for map generation
 :)

module namespace browse="http://syriaca.org//browse";

import module namespace common="http://syriaca.org//common" at "search/common.xqm";
import module namespace geo="http://syriaca.org//geojson" at "lib/geojson.xqm";
import module namespace templates="http://syriaca.org//templates" at "templates.xql";
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) for browse.html 
 : @param $browse:type selects doc type filter eg: place@type person@ana
 : @param $browse:view selects language for browse display
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:type {request:get-parameter('type', '')}; 
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:sort {request:get-parameter('sort', '')};
declare variable $browse:type-map {request:get-parameter('type-map', '')};
declare variable $browse:date {request:get-parameter('date', '')};
declare variable $browse:fq {request:get-parameter('fq', '')};

(:~
 : Build browse path for evaluation 
 : Uses $coll to build path to appropriate data set 
 : If no $coll parameter is present data and all subdirectories will be searched.
 : @param $coll collection name passed from html, should match data subdirectory name
:)
declare function browse:get-all($node as node(), $model as map(*), $coll as xs:string?){
let $browse-path := 
        if($coll = ('persons','authors','saints')) then concat("collection('",$config:data-root,"/persons/tei')//tei:person",browse:get-pers-coll($coll),browse:get-syr()) 
    else if($coll = 'places') then concat("collection('",$config:data-root,"/places/tei')//tei:place",browse:get-syr())
    else if($coll = 'bhse') then concat("collection('",$config:data-root,"/works/tei')//tei:body/tei:bibl",browse:get-syr())
    else if($coll = 'manuscripts') then concat("collection('",$config:data-root,"/manuscripts/tei')//tei:teiHeader")
    else if(exists($coll)) then concat("collection('",$config:data-root,xs:anyURI($coll),"')//tei:body",browse:get-syr())
    else concat("collection('",$config:data-root,"')//tei:body",browse:get-syr())
return 
    map{"browse-data" := util:eval($browse-path)}        
};

(:~
 : Return only Syriac titles 
 : Based on Syriac headwords 
 : @param $browse:view
:)
declare function browse:get-syr() as xs:string?{
    if($browse:view = 'syr') then
        "[child::*[@xml:lang = 'syr'][@syriaca-tags='#syriaca-headword']]"
    else ()    
};

(:~
 : Filter titles by subcollection
 : Used by persons as there are several subcollections within SBD
 : @param $coll passed from html template
:)
declare function browse:get-pers-coll($coll) as xs:string?{
if($coll = 'persons' or 'authors' or 'saints') then 
    if($coll = 'authors') then '[contains(@ana,"#syriaca-author")]'
    else if($coll = 'saints') then '[contains(@ana,"#syriaca-saint")]'
    else ()
else ()    
};

(:~
 : Matches English letters and their equivalent letters as established by Syriaca.org
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
 : @depreciated - use common:build-sort-string()
 : Strips english titles of non-sort characters as established by Syriaca.org
 : @param $titlestring 
 :)
declare function browse:build-sort-string($titlestring as xs:string*) as xs:string* {
    replace(replace(replace(replace($titlestring,'^\s+',''),'^al-',''),'[‘ʻʿ]',''),'On ','')
};

(:
 : Set up browse page, select correct results function based on URI params
 : @param $coll passed from html 
:)
declare function browse:results-panel($node as node(), $model as map(*),$coll){
if($browse:view = 'type' or $browse:view = 'date') then
    (<div class="col-md-4">{if($browse:view='type') then browse:browse-type($node,$model,$coll)  else browse:browse-date()}</div>,
     <div class="col-md-8">{
        if($browse:view='type') then
            if($browse:type != '') then 
                (<h3>{concat(upper-case(substring($browse:type,1,1)),substring($browse:type,2))}</h3>,
                 <ul>{browse:get-data($node,$model,$coll)}</ul>)
            else <h3>Select Type</h3>    
        else if($browse:view='date') then 
            if($browse:date !='') then 
                (<h3>{$browse:date}</h3>,
                 <ul>{browse:get-data($node,$model,$coll)}</ul>)
            else <h3>Select Date</h3>  
        else ()}</div>)
else if($browse:view = 'map') then
    <div class="col-md-12 map-lg">
        {geo:build-map($model("browse-data")//tei:geo, '', '')}
    </div>
else 
    <div class="col-md-12">
        { (
        if(($browse:view = 'syr')) then (attribute dir {"rtl"}) else(),
        browse:browse-abc-menu(),
        <h3>{(if(($browse:view = 'syr')) then (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) else attribute class {"label"},substring(browse:get-sort(),1,1))}</h3>,
        <div class="{if($browse:view = 'syr') then 'syr-list' else 'en-list'}">
            {browse:get-data($node,$model,$coll)}
        </div>
        )
        }
    </div>
};

(:~
 : Evaluates additional browse parameters; type and date
 : Adds narrowed data set to new map
:)
declare function browse:get-narrow($node as node(), $model as map(*),$coll){
let $data := 
   if($browse:view = 'type') then 
        if($browse:type != '') then 
            if($coll ='persons' or $coll = 'saints' or $coll = 'authors') then
                if($browse:type != '') then 
                    if($browse:type = 'unknown') then $model("browse-data")/self::*[not(@ana)]
                    else $model("browse-data")/self::*[contains(@ana,concat('#',$browse:type))]
                else ()
            else   
                if($browse:type != '') then 
                    $model("browse-data")/self::*[contains(@type,$browse:type)]
                else $model("browse-data")
        else ()        
    else if($browse:view = 'date') then 
        if($browse:date != '') then 
            if($browse:date = 'BC dates') then 
                $model("browse-data")/self::*[starts-with(descendant::*/@syriaca-computed-start,"-") or starts-with(descendant::*/@syriaca-computed-end,"-")]
            else
            $model("browse-data")/self::*[descendant::*[@syriaca-computed-start lt browse:get-end-date() and @syriaca-computed-start gt  browse:get-start-date()]] 
            | $model("browse-data")/self::*[descendant::*[@syriaca-computed-end gt browse:get-start-date() and @syriaca-computed-start lt browse:get-end-date()]]
        else ()    
    else if($browse:view = 'map') then $model("browse-data")
    else if($browse:view = 'syr') then $model("browse-data")/self::*[contains($browse:sort, substring(string-join(descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/descendant-or-self::*/text(),' '),1,1))]
    else $model("browse-data")/self::*[contains(browse:get-sort(), substring(browse:build-sort-string(string-join(descendant::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/descendant-or-self::text(),' ')),1,1))]
return
    map{"browse-refine" := $data}
};

(:
 : Sorts and outputs results set
 : @param $coll from html template
:)
declare function browse:get-data($node as node(), $model as map(*), $coll as xs:string*) as node()*{
(
if($browse:view = 'type') then
        if($model("browse-refine")//tei:geo) then
            <div class="map-sm inline-map well">{geo:build-map($model("browse-refine")//tei:geo, '', '')}</div>
        else ()
else (),
for $data in $model("browse-refine")
let $en-title := 
             if($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/child::*) then 
                 string-join($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/child::*/text(),' ')
             else if(string-join($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/text())) then 
                string-join($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^en')][1]/text(),' ')   
             else $data/ancestor::tei:TEI/descendant::tei:title[1]/text()               
let $syr-title := 
             if($data/child::*[@syriaca-tags='#syriaca-headword'][1]) then
                if($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/child::*) then 
                 string-join($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/child::*/text(),' ')
                else string-join($data/child::*[@syriaca-tags='#syriaca-headword'][matches(@xml:lang,'^syr')][1]/text(),' ')
             else 'NA'  
let $title := if($browse:view = 'syr') then $syr-title else $en-title
let $browse-title := browse:build-sort-string($title)
order by $browse-title collation "?lang=en&lt;syr&amp;decomposition=full"             
return 
(: Temp patch for manuscripts :)
    if($coll = "manuscripts") then 
        let $title := $data/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[1]/text()
        let $id := $data/ancestor::tei:TEI/descendant::tei:idno[@type='URI'][starts-with(.,'http://syriaca.org')][2]/text()
        return 
        <li>
            <a href="manuscript.html?id={$id}">{$title}</a>
        </li>
    else if($browse:view = 'syr') then common:display-recs-short-view($data,'syr') else common:display-recs-short-view($data,'')
) 
};
 
(:Dynamic where:)
declare function browse:conditions($data, $browse-title, $coll){
 if($browse:view ='en' or $browse:view = 'syr' or $browse:view ='') then 
    contains(browse:get-sort(), substring($browse-title,1,1))
 else if($browse:sort = 'all') then true()    
 else true()
};

declare function browse:get-end-date(){
if($browse:date = '0-100') then '0100-01-01'
else if($browse:date = '100-200') then '0200-01-01'
else if($browse:date = '200-300') then '0300-01-01'
else if($browse:date = '300-400') then '0400-01-01'
else if($browse:date = '400-500') then '0500-01-01'
else if($browse:date = '500-600') then '0600-01-01'
else if($browse:date = '600-700') then '0700-01-01'
else if($browse:date = '700-800') then '0800-01-01'
else if($browse:date = '800-900') then '0900-01-01'
else if($browse:date = '900-1000') then '1000-01-01'
else if($browse:date = '1000-1100') then '1100-01-01'
else if($browse:date = '1100-1200') then '1200-01-01'
else if($browse:date = '1200-1300') then '1300-01-01'
else if($browse:date = '1300-1400') then '1400-01-01'
else if($browse:date = '1400-1500') then '1500-01-01'
else if($browse:date = '1500-1600') then '1600-01-01'
else if($browse:date = '1600-1700') then '1700-01-01'
else if($browse:date = '1700-1800') then '1800-01-01'
else if($browse:date = '1800-1900') then '1900-01-01'
else if($browse:date = '1900-2000') then '2000-01-01'
else if($browse:date = '2000-') then '2100-01-01'
else '0100-01-01'
};

declare function browse:get-start-date(){
if($browse:date = '0-100') then '0001-01-01'
else if($browse:date = '100-200') then '0100-01-01'
else if($browse:date = '200-300') then '0200-01-01'
else if($browse:date = '300-400') then '0300-01-01'
else if($browse:date = '400-500') then '0400-01-01'
else if($browse:date = '500-600') then '0500-01-01'
else if($browse:date = '600-700') then '0600-01-01'
else if($browse:date = '700-800') then '0700-01-01'
else if($browse:date = '800-900') then '0800-01-01'
else if($browse:date = '900-1000') then '0900-01-01'
else if($browse:date = '1000-1100') then '1000-01-01'
else if($browse:date = '1100-1200') then '1100-01-01'
else if($browse:date = '1200-1300') then '1200-01-01'
else if($browse:date = '1300-1400') then '1300-01-01'
else if($browse:date = '1400-1500') then '1400-01-01'
else if($browse:date = '1500-1600') then '1500-01-01'
else if($browse:date = '1600-1700') then '1600-01-01'
else if($browse:date = '1700-1800') then '1700-01-01'
else if($browse:date = '1800-1900') then '1800-01-01'
else if($browse:date = '1900-2000') then '1900-01-01'
else if($browse:date = '2000-') then '2000-01-01'
else '0100-01-01'
};

(:~
 : Browse Alphabetical Menus
:)
declare function browse:browse-abc-menu(){
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
        {
            if(($browse:view = 'en') or ($browse:view='')) then
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')
                return
                    <li><a href="?view={$browse:view}&amp;sort={$letter}">{$letter}</a></li>
            else if(($browse:view = 'syr')) then  
                for $letter in tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return 
                    <li class="syr-menu" lang="syr"><a href="?view={$browse:view}&amp;sort={$letter}">{$letter}</a></li>
            else ()
        }
        </ul>
    </div>
};

declare function browse:browse-type($node as node(), $model as map(*), $coll){  
    <ul class="nav nav-tabs nav-stacked">
        {
            if($coll = 'places') then 
                for $types in $model("browse-data")
                    group by $place-types := $types/@type
                    order by $place-types ascending
                    return
                        <li>{if($browse:type = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                            <a href="?view=type&amp;type={$place-types}">
                            {if(string($place-types) = '') then 'unknown' else replace(string($place-types),'#|-',' ')}  <span class="count"> ({count($types)})</span>
                            </a>
                        </li>
            else             
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

};

(:
 : Browse by date
 : Precomputed values
 : NOTE: would be nice to use facets, however, it is currently inefficient 
:)
declare function browse:browse-date(){
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
};

(:~
 : Browse Tabs - Eng
 : Choose which functions to include with each browse. 
 : Note: should this be done with javascript? possibly. 
:)
declare  %templates:wrap function browse:build-tabs-en($node, $model){
    <li>{if(not($browse:view)) then attribute class {'active'} 
         else if($browse:view = 'en') then attribute class {'active'} 
         else '' }<a href="browse.html?view=en&amp;sort=A">English</a>
    </li>   
};

(:~
 : Browse Tabs - Syr
:)
declare  %templates:wrap function browse:build-tabs-syr($node, $model){
    <li>{if($browse:view = 'syr') then attribute class {'active'} 
         else '' }<a href="browse.html?view=syr&amp;sort=ܐ" xml:lang="syr" lang="syr" dir="ltr" title="syriac">ܠܫܢܐ ܣܘܪܝܝܐ</a>
    </li>   
};

(:~
 : Browse Tabs - Type  
:)
declare  %templates:wrap function browse:build-tabs-type($node, $model){
    <li>{if($browse:view = 'type') then attribute class {'active'}
         else '' }<a href="browse.html?view=type">Type</a>
    </li>
};

(:~
 : Browse Tabs - Map
:)
declare  %templates:wrap function browse:build-tabs-date($node, $model){
    <li>{if($browse:view = 'date') then attribute class {'active'} 
         else '' }<a href="browse.html?view=date">Date</a>
    </li>
};

(:~
 : Browse Tabs - Map
:)
declare  %templates:wrap function browse:build-tabs-map($node, $model){
    <li>{if($browse:view = 'map') then attribute class {'active'} 
         else '' }<a href="browse.html?view=map">Map</a>
    </li>
};