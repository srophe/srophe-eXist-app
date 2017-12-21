xquery version "3.0";

(:~
 : Build email from form returns error or sucess message to ajax function
 :)

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace recap = "http://www.exist-db.org/xquery/util/recapture" at "recaptcha.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(:request:get-parameter("recaptcha_response_field",()):)
declare function local:recaptcha(){
let $recapture-private-key := string(environment-variable('secret'))
return 
    recap:validate($recapture-private-key, request:get-parameter("g-recaptcha-response",()))
};

declare function local:build-message(){
let $id := request:get-parameter('id','')
let $collection := request:get-parameter('collection','')
let $uri := 
    if($collection = 'places') then concat('Place: ',$id)
    else if($collection = ('q','authors','sbd')) then concat('Person: ',$id)
    else if($collection = ('bhse','nhsl')) then concat('Work: ',$id)
    else if($collection = 'bibl') then concat('Work Cited: ',$id)
    else if($collection = 'spear') then concat('SPEAR: ',$id)
    else if($collection = 'mss') then concat('Manuscript: ',$id)
    else request:get-parameter('id','')
return
  <mail>
    <from>Syriaca.org &lt;david.a.michelson@vanderbilt.edu&gt;</from>
    {
    if($collection = 'places') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>thomas.a.carlson@okstate.edu</to>)
    else if($collection = 'q') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>jeannenicolesaint@gmail.com</to>)
    else if($collection = 'bhse') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>jeannenicolesaint@gmail.com</to>,  
        <to>nathan.p.gibson@vanderbilt.edu</to>)
    else if($collection = 'nhsl') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>jeannenicolesaint@gmail.com</to>,  
        <to>nathan.p.gibson@vanderbilt.edu</to>)     
    else if($collection = 'sbd') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>jeannenicolesaint@gmail.com</to>,  
        <to>nathan.p.gibson@vanderbilt.edu</to>,
        <to>daniel.schwartz@tamu.edu</to>)     
    else if($collection = 'authors') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>nathan.p.gibson@vanderbilt.edu</to>)
    else if($collection = 'bibl') then
        (<to>david.a.michelson@vanderbilt.edu</to>,
        <to>nathan.p.gibson@vanderbilt.edu</to>)
    else if($collection = 'spear') then
        <to>daniel.schwartz@tamu.edu</to>
    else if($collection = 'mss') then
        <to>david.a.michelson@vanderbilt.edu</to>        
    else 
        <cc>david.a.michelson@vanderbilt.edu</cc>
    }
    <cc>wsalesky@gmail.com</cc>
    <subject>{request:get-parameter('subject','')} RE: {$uri}</subject>
    <message>
      <xhtml>
           <html>
               <head>
                 <title>{request:get-parameter('subject','')}</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')}</p>
                 <p>{$uri}</p>
                 <p>{request:get-parameter('comments','')}</p>
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};


let $cache := current-dateTime()
return 
    if(exists(request:get-parameter('email','')) and request:get-parameter('email','') != '') 
        then 
            if(exists(request:get-parameter('comments','')) and request:get-parameter('comments','') != '') 
              then 
               if(local:recaptcha()//*:pair[@name='success'] = 'true') then 
                 if (mail:send-email(local:build-message(),"library.vanderbilt.edu", ()) ) then
                   <h4>Thank you. Your message has been sent.</h4>
                 else
                   <h4>Could not send message.</h4>
                else 'Recaptcha fail' 
            else  <h4>Incomplete form.</h4>
   else  <h4>Incomplete form.</h4>
