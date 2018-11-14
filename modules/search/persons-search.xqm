xquery version "3.0";
(:~
 : Builds search information for persons sub-collection
 : Search string is passed to search.xqm for processing.  
 :)
module namespace persons="http://syriaca.org/srophe/persons";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";
import module namespace data="http://syriaca.org/srophe/data" at "../lib/data.xqm";
import module namespace global="http://syriaca.org/srophe/global" at "../lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $persons:q {request:get-parameter('q', '')};
declare variable $persons:name {request:get-parameter('persName', '')};

declare variable $persons:uri {request:get-parameter('uri', '')};
declare variable $persons:coll {request:get-parameter('coll', '')};
declare variable $persons:type {request:get-parameter('type', '')};

declare variable $persons:start-date {request:get-parameter('start-date', '')};
declare variable $persons:end-date {request:get-parameter('end-date', '')};
declare variable $persons:date-type {request:get-parameter('date-type', '')};

declare variable $persons:gender {request:get-parameter('gender', '')};
declare variable $persons:state {request:get-parameter('state', '')};

declare variable $persons:related-place {request:get-parameter('related-place', '')};
declare variable $persons:place-type {request:get-parameter('place-type', '')};

declare variable $persons:related-persons {request:get-parameter('related-persons', '')};
declare variable $persons:mentioned {request:get-parameter('mentioned', '')};

(:~
 : Build full-text keyword search over all tei:person data
 : @param $q query string
:)
declare function persons:keyword() as xs:string? {
    if($persons:q != '') then concat("[ft:query(.,'",data:clean-string($persons:q),"',data:search-options()) | ft:query(descendant::tei:persName,'",data:clean-string($persons:q),"',data:search-options()) | ft:query(descendant::tei:placeName,'",data:clean-string($persons:q),"',data:search-options()) | ft:query(ancestor::tei:TEI/descendant::tei:teiHeader/descendant::tei:title,'",data:clean-string($persons:q),"',data:search-options()) | ft:query(descendant::tei:desc,'",data:clean-string($persons:q),"',data:search-options())]")
    else ()    
};

(:~
 : Search Name
 : @param $name search persName
 want to be able to return all given/family ect without a search term?
 given / family / title
:)
declare function persons:name() as xs:string? {
    if($persons:name != '') then
        concat("[ft:query(descendant::tei:person/tei:persName,'",data:clean-string($persons:name),"',data:search-options())]")   
    else ()
};

(:~
 : Search URI
 : Accepts a URI  
 : NOT used
:)
declare function persons:uri() as xs:string? { 
    if($persons:uri != '') then    
        concat("[descendant::tei:person/tei:idno[matches(.,'",$persons:uri,"')]]")
    else ()
};

(:~
 : Search limit by submodule. 
:)
declare function persons:coll($coll as xs:string?) as xs:string?{
let $collection := if($persons:coll = 'sbd' ) then 'The Syriac Biographical Dictionary'
                   else if($persons:coll = 'q' ) then 'Qadishe: A Guide to the Syriac Saints'
                   else if($persons:coll = 'authors' ) then 'A Guide to Syriac Authors'
                   else if($coll = 'sbd' ) then 'The Syriac Biographical Dictionary'
                   else if($coll = 'q' ) then 'Qadishe: A Guide to the Syriac Saints'
                   else if($coll = 'authors' ) then 'A Guide to Syriac Authors'
                   else ()
return                    
    if($collection != '') then concat("[ancestor::tei:TEI/descendant::tei:title/text() = '",$collection,"']")
    else ()
};

(:~
 : Search limit by person type. 
:)
declare function persons:type() as xs:string?{
    if($persons:type != '') then
        if($persons:type = 'any') then ()
        else
         concat("[descendant::tei:person[contains(@ana, '#syriaca-",$persons:type,"')]]")
    else ()
};

(:~
 : Search limit by person sex/gender. 
:)
declare function persons:gender() as xs:string?{
    if($persons:gender != '') then
        if($persons:gender = 'other') then 
            "[descendant::tei:sex[@value != 'M' and @value != 'F' and @value != 'E']]"
        else concat("[descendant::tei:sex[@value = '",$persons:gender,"']]")
    else ()
};

(:~
 : Search limit by person state/type. 
:)
declare function persons:state() as xs:string?{
    if($persons:state != '') then concat("[descendant::tei:state[@type = '",$persons:state,"']]")
    else ()
};

(:~
 : Build date search string
 : @param $persons:date-type indicates element to restrict date searches on, if empty, no element restrictions
 : @param $persons:start-date start date
 : @param $persons:end-date end date       
:)
declare function persons:date-range() as xs:string?{
if($persons:date-type != '') then 
    if($persons:date-type = 'birth') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:birth[(
            @syriaca-computed-start >= 
                '",global:make-iso-date($persons:start-date),"' 
                and @syriaca-computed-start <= 
                '",global:make-iso-date($persons:end-date),"'
                )]]") 
         else if($persons:start-date != '' and $persons:end-date = '') then 
             concat("[descendant::tei:birth[@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:birth[@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
    else if($persons:date-type = 'death') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:death[(
            @syriaca-computed-start >= 
                '",global:make-iso-date($persons:start-date),"' 
                and @syriaca-computed-start <= 
                '",global:make-iso-date($persons:end-date),"'
                )]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:death[@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:death[@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
    else if($persons:date-type = 'floruit') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:floruit[(
            @syriaca-computed-start >= 
                '",global:make-iso-date($persons:start-date),"' 
                and @syriaca-computed-end <= 
                '",global:make-iso-date($persons:end-date),"'
                ) or (
                    @syriaca-computed-start >= 
                    '",global:make-iso-date($persons:start-date),"' 
                    and @syriaca-computed-start <= 
                    '",global:make-iso-date($persons:end-date),"' and 
                    not(exists(@syriaca-computed-end)))]]")  
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:floruit[@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:floruit[@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else ''      
   else if($persons:date-type = 'office') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:state[@type='office'][(
            @syriaca-computed-start >= 
                '",global:make-iso-date($persons:start-date),"' 
                and @syriaca-computed-end <= 
                '",global:make-iso-date($persons:end-date),"'
                ) or (
                    @syriaca-computed-start >= 
                    '",global:make-iso-date($persons:start-date),"' 
                    and @syriaca-computed-start <= 
                    '",global:make-iso-date($persons:end-date),"' and 
                    not(exists(@syriaca-computed-end)))]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:state[@type='office'][@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:state[@type='office'][@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
   else if($persons:date-type = 'event') then 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::tei:event[(
            @syriaca-computed-start >= 
                '",global:make-iso-date($persons:start-date),"' 
                and @syriaca-computed-end <= 
                '",global:make-iso-date($persons:end-date),"'
                ) or (
                    @syriaca-computed-start >= 
                    '",global:make-iso-date($persons:start-date),"' 
                    and @syriaca-computed-start <= 
                    '",global:make-iso-date($persons:end-date),"' and 
                    not(exists(@syriaca-computed-end)))]]")  
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::tei:event[@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::tei:event[@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else ''
    else 
        if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::*[(
                @syriaca-computed-start >= 
                    '",global:make-iso-date($persons:start-date),"' 
                    and @syriaca-computed-end <= 
                    '",global:make-iso-date($persons:end-date),"'
                    ) or (
                    @syriaca-computed-start >= 
                    '",global:make-iso-date($persons:start-date),"' 
                    and @syriaca-computed-start <= 
                    '",global:make-iso-date($persons:end-date),"' and 
                    not(exists(@syriaca-computed-end)))]]") 
             else if($persons:start-date != ''  and $persons:end-date = '') then 
                 concat("[descendant::*[@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
             else if($persons:end-date != ''  and $persons:start-date = '') then
                concat("[descendant::*[@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
             else ''
else 
    if($persons:start-date != '' and $persons:end-date != '') then concat("[descendant::*[(
            @syriaca-computed-start >= 
                '",global:make-iso-date($persons:start-date),"' 
                and @syriaca-computed-end <= 
                '",global:make-iso-date($persons:end-date),"'
                ) or (
                    @syriaca-computed-start >= 
                    '",global:make-iso-date($persons:start-date),"' 
                    and @syriaca-computed-start <= 
                    '",global:make-iso-date($persons:end-date),"' and 
                    not(exists(@syriaca-computed-end)))]]") 
         else if($persons:start-date != ''  and $persons:end-date = '') then 
             concat("[descendant::*[@syriaca-computed-start >= '",global:make-iso-date($persons:start-date),"' or @syriaca-computed-end >= '",global:make-iso-date($persons:start-date),"']]")
         else if($persons:end-date != ''  and $persons:start-date = '') then
            concat("[descendant::*[@syriaca-computed-end <= '",global:make-iso-date($persons:end-date),"' or @syriaca-computed-start <= '",global:make-iso-date($persons:end-date),"' and not(@syriaca-computed-end)]]")
         else '' 
}; 

(:~
 : Search related places 
:)
declare function persons:related-places() as xs:string?{
    if($persons:related-place != '') then 
        let $ids := 
            if(matches($persons:related-place,'^http://syriaca.org/')) then
                normalize-space($persons:related-place)
            else string-join(distinct-values(
                for $name in collection($config:data-root || '/places')//tei:place[ft:query(tei:placeName,$persons:related-place)]
                let $id := $name/parent::*/descendant::tei:idno[starts-with(.,'http://syriaca.org')]
                return concat($id/text(),'(\s|$)')),'|')
        return 
            if($persons:place-type !='' and $persons:place-type !='any') then 
                if($persons:place-type = 'birth') then 
                    concat("[descendant::tei:relation[@name ='born-at'][@passive[matches(.,'",$ids,"')] or @active[matches(.,'",$ids,"')]]]")
                else if($persons:place-type = 'death') then
                    concat("[descendant::tei:relation[@name ='died-at'][@passive[matches(.,'",$ids,"')] or @active[matches(.,'",$ids,"')]]]")   
                else if($persons:place-type = 'venerated') then 
                    concat("[descendant::tei:event[matches(@contains,'",$ids,"')]]")
                else concat("[descendant::tei:relation[@passive[matches(.,'",$ids,"')] or @active[matches(.,'",$ids,"')]]]")             
            else concat("[descendant::tei:relation[@passive[matches(.,'",$ids,"')] or @active[matches(.,'",$ids,"')]]]")
    else ()
};

(:~
 : Search related persons 
 : Uses regex to match on word boundries
:)
declare function persons:related-persons() as xs:string?{
    if($persons:related-persons != '') then 
        if(matches($persons:related-persons,'^http://syriaca.org/')) then 
            let $id := normalize-space($persons:related-persons)
            return concat("[descendant::tei:relation[@passive[matches(.,'",$id,"')] or @active[matches(.,'",$id,"')] or @mutual[matches(.,'",$id,"')]]]")
        else 
            let $ids := 
                string-join(distinct-values(
                    for $name in collection($config:data-root || '/persons')//tei:persName[ft:query(.,$persons:related-persons)]
                    let $id := $name/ancestor::tei:person/descendant::tei:idno[starts-with(.,'http://syriaca.org')]
                    return concat($id/text(),'(\s|$)')),'|')
            return concat("[descendant::tei:relation[@passive[matches(.,'",$ids,"(\W|$)')] or @active[matches(.,'",$ids,"')] or @mutual[matches(.,'",$ids,"')]]]")
    else ()  
};

(:~
 : Search related texts 
 : Uses regex to match on word boundries
 ref="http://syriaca.org/work/939"
 <title ref="http://syriaca.org/work/939">Aaron (text)</title>
:)
declare function persons:mentioned() as xs:string?{
      if($persons:mentioned != '') then 
        if(matches($persons:mentioned,'^http://syriaca.org/')) then 
            let $id := normalize-space($persons:mentioned)
            return concat("[descendant::*[@ref[matches(.,'",$id,"')]]]")
        else 
            concat("[descendant::*[ft:query(tei:title,'",data:clean-string($persons:mentioned),"',data:search-options())]]")
    else ()  
};

(:~
 : Build query string to pass to search.xqm 
:)
declare function persons:query-string($collection as xs:string?) as xs:string? {
 concat("collection('",$config:data-root,"/persons/tei')//tei:body",
    persons:coll($collection),
    persons:type(),
    persons:gender(),
    persons:state(),
    data:keyword-search(),
    persons:name(),
    persons:uri(),
    persons:date-range(),
    data:related-places(),
    data:related-persons(),
    data:mentioned()
    )
};

(:~
 : Builds advanced search form for persons
 :)
declare function persons:search-form($collection) {   
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal" role="form">
    <div class="well well-small">
        {let $search-config := 
                if(doc-available(concat($config:app-root, '/persons/search-config.xml'))) then concat($config:app-root, '/persons/search-config.xml')
                else concat($config:app-root, '/search-config.xml')
            let $config := 
                if(doc-available($search-config)) then doc($search-config)
                else ()                            
            return 
                if($config != '') then 
                    (<button type="button" class="btn btn-info pull-right clearfix search-button" data-toggle="collapse" data-target="#searchTips">
                        Search Help <span class="glyphicon glyphicon-question-sign" aria-hidden="true"></span></button>,                       
                    if($config//search-tips != '') then
                    <div class="panel panel-default collapse" id="searchTips">
                        <div class="panel-body">
                        <h3 class="panel-title">Search Tips</h3>
                        {$config//search-tips}
                        </div>
                    </div>
                    else if(doc-available($config:app-root || '/searchTips.html')) then doc($config:app-root || '/searchTips.html')
                    else ())
                else ()}
        <div class="well well-small search-inner well-white">
         <!-- Person Type -->
           <div class="form-group">            
                <label for="coll" class="col-sm-2 col-md-3  control-label">Search in Resource: </label>
                <div class="col-sm-10 col-md-6">
                    <label class="checkbox-inline">
                        <input type="radio" name="coll" value="sbd" aria-label="SBD"/>
                        {
                            if($collection = 'sbd') then attribute checked { "checked" }
                            else ()
                         }
                            SBD (all entries)
                    </label>
                    <label class="checkbox-inline">
                        <input type="radio" name="coll" value="q" aria-label="Qadishe"/>
                        {
                            if($collection = 'q') then attribute checked { "checked" }
                            else ()
                        }
                        Qadishe (SBD Vol. I)
                    </label>
                    <label class="checkbox-inline">
                        <input type="radio" name="coll" value="authors" aria-label="Authors"/>
                            {
                            if($collection = 'authors') then attribute checked { "checked" }
                            else ()
                            }
                        Authors (SBD Vol. 2)
                    </label>
                </div>
            </div>
            <div class="form-group">            
                <label for="type" class="col-sm-2 col-md-3  control-label">- and/or - </label>
            </div>
            <div class="form-group">            
                <label for="type" class="col-sm-2 col-md-3  control-label">Search by Type: </label>
                <div class="col-sm-10 col-md-6">
                    <label class="checkbox-inline">
                        <input type="radio" name="type" value="" aria-label="All" checked="checked"/>
                            all
                    </label>
                    <label class="checkbox-inline">
                        <input type="radio" name="type" value="saint" aria-label="Saints"/>
                        {
                            if($persons:type = 'saint') then attribute checked { "checked" }
                            else ()
                        }
                       saints
                    </label>
                    <label class="checkbox-inline">
                        <input type="radio" name="type" value="author" aria-label="Authors"/>
                            {
                            if($persons:type = 'author') then attribute checked { "checked" }
                            else ()
                            }
                        authors
                    </label>
                </div>
            </div>
            <hr/>
        <!-- Keyword -->
            <div class="form-group">
                <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="qs" name="q" class="form-control keyboard" placeholder="Any script (Syriac, Roman, etc.)"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('qs')}</div>
                    </div> 
                </div>
            </div>
            <!-- Person Name -->
            <div class="form-group">
                <label for="name" class="col-sm-2 col-md-3  control-label">Person Name: </label>
                <div class="col-sm-10 col-md-6">
                    <div class="input-group">
                        <input type="text" id="persNameSearch" name="persName" class="form-control keyboard" placeholder="Any script (Syriac, Roman, etc.)"/>
                        <div class="input-group-btn">{global:keyboard-select-menu('persNameSearch')}</div>
                    </div> 
                </div>
            </div>
            <hr/>            
            <!-- Date range-->
                <div class="form-group">
                        <label for="start-date" class="col-sm-2 col-md-3  control-label">Gregorian Date Range: </label>
                        <div class="col-sm-10 col-md-6 form-inline">
                            <input type="text" id="start-date" name="start-date" placeholder="Start Date" class="form-control"/>&#160;
                            <input type="text" id="end-date" name="end-date" placeholder="End Date" class="form-control"/>&#160;
                            <select name="date-type" class="form-control">
                                <option value="">all</option>
                                <option value="birth">birth</option>
                                <option value="death">death</option>
                                <option value="floruit">active</option>
                                <option value="office">office</option>
                                <option value="event">other</option>
                            </select>
                            <p class="hint">* Dates should be entered as YYYY or YYYY-MM-DD. Add a minus sign (-) in front of BC dates. <span><a href="http://syriaca.org/documentation/dates.html">more <i class="glyphicon glyphicon-circle-arrow-right"></i></a></span></p>
                        </div>
                </div>    
                
                <!-- Sex or Gender --> 
                    <div class="form-group">
                        <label for="gender" class="col-sm-2 col-md-3  control-label">Sex or Gender: </label>
                        <div class="col-sm-10 col-md-6 form-inline">
                            <select name="gender" class="form-control">
                                <option value="">all</option>
                                <option value="F">female</option>
                                <option value="M">male</option>
                                <option value="E">eunuch</option>
                                <option value="other">other</option>
                            </select>
                        </div>
                </div>
                <!-- State  Limit to: [Dropdown] martyr, confession, office  -->
                <div class="form-group">
                        <label for="state" class="col-sm-2 col-md-3  control-label">Limit to: </label>
                        <div class="col-sm-10 col-md-6 form-inline">
                            <select name="state" class="form-control">
                                <option value="">all</option>
                                <option value="martyr">martyr</option>
                                <option value="confession">confession</option>
                                <option value="office">office</option>
                                <option value="other">other</option>
                            </select>
                        </div>
                </div>
            <hr/>
                
            <!-- Associated Places-->
            <div class="form-group">            
                <label for="related-place" class="col-sm-2 col-md-3  control-label">Related Places: </label>
                <div class="col-sm-10 col-md-6 form-inline">
                    <input type="text" id="related-place" name="related-place" placeholder="Related Places" class="form-control"/>&#160;
                    <select name="place-type" id="place-type" class="form-control">
                         <option value="">any</option>
                         <option value="birth">birth</option>
                         <option value="death">death</option>
                         <!--<option value="venerated">venerated</option>-->
                         <option value="other">other</option>
                    </select>
                    <p class="hint">* Enter syriaca.org URI, ex: http://syriaca.org/place/78</p>
                </div>
            </div>
            <!-- Related persons-->
            <div class="form-group">            
                <label for="related-persons" class="col-sm-2 col-md-3  control-label">Related Persons: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="related-persons" name="related-persons" class="form-control"/>
                    <p class="hint">* Enter syriaca.org URI, ex: http://syriaca.org/person/13</p>
                </div>
            </div>
            <!--Associated Texts:-->
            <div class="form-group">            
                <label for="mentioned" class="col-sm-2 col-md-3  control-label">Related Works: </label>
                <div class="col-sm-10 col-md-6">
                    <input type="text" id="mentioned" name="mentioned" class="form-control"/>
                    <p class="hint">* Enter syriaca.org URI, ex: http://syriaca.org/work/429</p>
                </div>
            </div> 
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>
</form>
};