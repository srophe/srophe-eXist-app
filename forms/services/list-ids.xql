xquery version "3.0";
(:~
 : Build dropdown list of available resources for citation
:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare function local:check-db-ids(){
<list>
{
let $ids :=
    for $id in
    distinct-values(
        for $recid in collection('/db/apps/srophe-data/data')//tei:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][not(contains(.,'tei'))][not(contains(.,'source'))]
        return $recid
        )
    return
    <id type="{substring-before(substring-after($id,'http://syriaca.org/'),'/')}" uri="{$id}"  num="{if(functx:is-a-number(tokenize($id,'/')[last()])) then xs:integer(tokenize($id,'/')[last()])  else 0}"/>
return
    for $id in $ids
    group by $category := $id/@type
    return
            <div class="{$category}">
                {
                (for $grpids in $id order by xs:integer($grpids/@num) ascending return $grpids)[last()]
                }
            </div>
    }
</list>
};

try {xmldb:store('/db/apps/srophe-forms/forms/services','syr-ids.xml', local:check-db-ids())}
catch * {concat($err:code, ": ", $err:description)}
