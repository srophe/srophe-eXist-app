xquery version "3.0";
(:~
 : Log users into forms, if not alread logged into admin module. 
:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace functx="http://www.functx.com";
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

let $user := 
    if(request:get-attribute(concat($global:login-domain, '.user'))) then 
        request:get-attribute(concat($global:login-domain, '.user'))
    else ()    
return 
(login:set-user($global:login-domain, (), true()),
    if(request:get-parameter('user', '') != '') then
        <response><user>{$user}</user><password/></response>
    else if(request:get-parameter('logout', ()) = true()) then 
        <response><user></user><password/></response>          
    else  <response><user>{$user}</user><password/></response>)
