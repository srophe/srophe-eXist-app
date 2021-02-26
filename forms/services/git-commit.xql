xquery version "3.1";

(:~ 
 : POC: eXist-db module to commit content to github reop via github API 
 : Code creates a new branch off of the master branch, commits updated content to new branch and then submits a pull request when complete. 
 : Intended use is for online data submission, using GitHub for review/approval process.
 :
 : Prerequisites:
 : In order to run the module, you will need a github Authorization token.
 : When you create authorization token your OAuth Scope will need to include the github repository you would like to commit to.  
 : @see https://github.com/blog/1509-personal-api-tokens
 :
 : Github API Steps for creating/updating repository contents:
 :   1. Get a reference to HEAD of branch, in this case we use master
 :      Save sha and url from github response
 :   2. create a new branch
 :      Save sha and url from github response on the new branch
 :   3. Get the latest commit for the new branch 
 :      Save sha, tree sha and tree url
 :   4. Post your content to github
 :      Save sha
 :   5. Create a tree containing your new content
 :      Save sha
 :   6. Create a new commit
 :      Save commit sha
 :   7. Update refs with new commit information    
 :   8. Create a pull request
 :      If step 7 returns @status='200' create a pull request. 
 :
 : Links to useful github api info
 : https://developer.github.com/v3/ 
 : https://developer.github.com/v3/git/
 : https://gist.github.com/jasonrudolph/10727108
 : http://www.mdswanson.com/blog/2011/07/23/digging-around-the-github-api-take-2.html
 : http://www.levibotelho.com/development/commit-a-file-with-the-github-api/ (*This was the most helpful)
 : http://patrick-mckinley.com/tech/github-api-commit.html
 :
 : @author Winona Salesky
 : @version 1.0
 :)
module namespace gitcommit="http://syriaca.org/srophe/gitcommit";

import module namespace http="http://expath.org/ns/http-client";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

(: Set up global varaibles :)
(: Access git-api configuration file :) 
(:
declare variable $gitcommit:git-config := if(doc('../config.xml')) then doc('../config.xml') else <response status="fail"><message>Load config.xml file please.</message></response>;
declare variable $gitcommit:repo := $gitcommit:git-config//*:git-submit-repository/text();
declare variable $gitcommit:authorization-token := $gitcommit:git-config//*:git-submit-token/text();
:)
declare variable $gitcommit:repo := 'https://github.com/VandyVRC/tcadrt';
declare variable $gitcommit:authorization-token := $gitcommit:git-config//*:git-submit-token/text();

declare function gitcommit:step1($data as item()*,$path as xs:string?, $commit-message as xs:string?){
(: 1. Get a reference to HEAD of branch, master:)
    let $branch :=  
            http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/git/refs/heads/development'))}" method="get">
                                <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                                <http:header name="Connection" value="close"/>
                              </http:request>)
    let $branch-data := util:base64-decode($branch[2])
    (: Get latest commit SHA from master branch  :)
    let $branch-sha := parse-json($branch-data)?object?sha
    return 
       if(starts-with(string($branch[1]/@status),'2')) then
           ('Step 1 ',gitcommit:step2($data,$path, $commit-message, $branch-sha))
        else ('Fail step 1 ',string($branch[1]/@message))   
};

declare function gitcommit:step2($data as item()*,$path as xs:string?, $commit-message as xs:string?, $branch-sha as xs:string?){
    (: 2. create a new branch :)
    let $branch-name := concat(replace($path,'/|\.',''),'-',replace(util:random(),'\.',''))
    let $new-branch-name := 
        serialize(
            <object>
                <ref>refs/heads/{$branch-name}</ref>
                <sha>{$branch-sha}</sha>
            </object>, 
            <output:serialization-parameters>
                <output:method>json</output:method>
            </output:serialization-parameters>)            
    let $new-branch := http:send-request(
                        <http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/git/refs'))}" method="post">
                            <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                            <http:header name="Connection" value="close"/>
                            <http:header name="Accept" value="application/json"/>
                            <http:body media-type="application/json" method="text">{$new-branch-name}</http:body>
                        </http:request>)               
    let $new-branch-data := util:base64-decode($new-branch[2])
    (: Get latest commit SHA from master branch  :)
    let $new-branch-sha := parse-json($new-branch-data)?object?sha
    (: Get latest commit SHA from master branch  :)
    let $new-branch-url := parse-json($new-branch-data)?object?url
    return 
        if(starts-with(string($new-branch[1]/@status),'2')) then
            ('Step 2', gitcommit:step3($data,$path,$commit-message, $branch-name, $branch-sha, $new-branch-sha, $new-branch-url))
        else ('Fail step 2 ',$new-branch-data)
};

declare function gitcommit:step3($data as item()*,
    $path as xs:string?, $commit-message as xs:string?, 
    $branch-name as xs:string?, $branch-sha as xs:string?, $new-branch-sha as xs:string?, 
    $new-branch-url as xs:string?){
(: 3. Get the latest commit for the new branch :)
    let $get-latest-commit := http:send-request(
                                <http:request http-version="1.1" href="{xs:anyURI($new-branch-url)}" method="get">
                                    <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                                    <http:header name="Connection" value="close"/>
                                </http:request>)
    let $get-latest-commit-data := util:base64-decode($get-latest-commit[2])
    (:Note the commit SHA, the tree SHA, and the tree URL.:)
    let $get-latest-commit-sha := parse-json($get-latest-commit-data)?sha
    let $get-latest-commit-tree-sha := parse-json($get-latest-commit-data)?tree?sha
    let $get-latest-commit-tree-url := parse-json($get-latest-commit-data)?tree?url
    return 
        if(starts-with(string($get-latest-commit[1]/@status),'2')) then
            ('Step 3 ',gitcommit:step4($data, $path, $commit-message, $branch-name, $get-latest-commit-sha, $get-latest-commit-tree-url))
        else ('Fail step 3 ',string($get-latest-commit[1]/@message))
    
};

declare function gitcommit:step4($data as item()*,
    $path as xs:string?, $commit-message as xs:string?, $branch-name as xs:string?, 
    $get-latest-commit-sha as xs:string?, $get-latest-commit-tree-url as xs:string?){
(: 4. Post your content to github :)
(: Create new blob with new content base64/utf-8 :)
    let $xml-data := serialize($data,
                    <output:serialization-parameters>
                        <output:method>xml</output:method>
                    </output:serialization-parameters>) 
    let $new-blob-content := 
        serialize(
            <object>
                <content>{$xml-data}</content>
                <encoding>utf-8</encoding>
            </object>, 
            <output:serialization-parameters>
                <output:method>json</output:method>
            </output:serialization-parameters>)             
    let $new-blob :=     
            http:send-request(<http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/git/blobs'))}" method="post">
                                <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                                <http:header name="Connection" value="close"/>
                                <http:header name="Accept" value="application/json"/>
                                <http:body media-type="application/json" method="text">{$new-blob-content}</http:body>
                              </http:request>)  
    let $new-blob-data := util:base64-decode($new-blob[2])                             
    let $blob-sha := parse-json($new-blob-data)?sha        
    return 
        if(starts-with(string($new-blob[1]/@status),'2')) then
            let $get-tree := 
                http:send-request(<http:request http-version="1.1" href="{xs:anyURI($get-latest-commit-tree-url)}" method="get">
                                    <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                                    <http:header name="Connection" value="close"/>
                                  </http:request>) 
            let $get-tree-data := util:base64-decode($get-tree[2])                                 
            let $get-tree-sha := parse-json($get-tree-data)?sha 
            return 
                if(starts-with(string($get-tree[1]/@status),'2')) then
                    ('step 4 ',gitcommit:step5($path, $commit-message, $branch-name, $get-latest-commit-sha, $get-latest-commit-tree-url, $get-tree-sha, $blob-sha))
                else ('fail step 4a ',string($get-tree[1]/@message))
        else ('fail step 4b ',string($new-blob[1]/@message), $new-blob-content)
};

declare function gitcommit:step5($path as xs:string?, 
    $commit-message as xs:string?, 
    $branch-name as xs:string?,
    $get-latest-commit-sha as xs:string?, 
    $get-latest-commit-tree-url as xs:string?, 
    $get-tree-sha as xs:string?, 
    $blob-sha as xs:string?){
(: 5. Create a tree containing your new content :)
    let $new-tree-content := 
        serialize(
            <object>
                <base_tree>{$get-tree-sha}</base_tree>
                <tree json:array="true">
                    <path>{$path}</path>
                    <mode>100644</mode>
                    <type>blob</type>
                    <sha>{$blob-sha}</sha>
                </tree>
            </object>, 
            <output:serialization-parameters>
                <output:method>json</output:method>
            </output:serialization-parameters>)
    let $new-tree := http:send-request(
                        <http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/git/trees'))}" method="post">
                            <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                            <http:header name="Connection" value="close"/>
                            <http:header name="Accept" value="application/json"/>
                            <http:body media-type="application/json" method="text">{$new-tree-content}</http:body>
                        </http:request>)
    let $new-tree-data := util:base64-decode($new-tree[2])                        
    let $get-new-tree-sha := parse-json($new-tree-data)?sha       
    return 
        if(starts-with(string($new-tree[1]/@status),'2')) then
            ('step 5',gitcommit:step6($path, $commit-message, $branch-name, $get-latest-commit-sha, $get-new-tree-sha))
        else ('fail step5 ',$new-tree[1], $new-tree-data)
};

declare function gitcommit:step6($path as xs:string?, 
    $commit-message as xs:string?, 
    $branch-name as xs:string?, 
    $get-latest-commit-sha as xs:string?, 
    $get-new-tree-sha as xs:string?){
(: 6. Create a new commit :)
(: Update refs in repository to your new commit SHA :)
    let $commit-ref-data :=
        serialize(
            <object>
                <message>{$commit-message}</message>
                <parents json:array="true">{$get-latest-commit-sha}</parents>
                <tree>{$get-new-tree-sha}</tree>
            </object>, 
            <output:serialization-parameters>
                <output:method>json</output:method>
            </output:serialization-parameters>)
    let $commit :=  http:send-request(
                        <http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/git/commits'))}" method="post">
                            <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                            <http:header name="Connection" value="close"/>
                            <http:header name="Accept" value="application/json"/>
                            <http:body media-type="application/json" method="text">{$commit-ref-data}</http:body>
                        </http:request>)
    let $commit-data := util:base64-decode($commit[2])        
    let $commit-sha := parse-json($commit-data)?sha        
    return 
        if(starts-with(string($commit[1]/@status),'2')) then
            ('step 6 ',gitcommit:step7($path, $branch-name, $commit-sha))
        else ('fail step 6 ',string($commit[1]/@message))
};

declare function gitcommit:step7($path as xs:string?, $branch-name as xs:string?, $commit-sha as xs:string?){
(: 7. Update refs :)
    let $update-ref :=
        serialize(
            <object>
                <sha>{$commit-sha}</sha>
                <force json:literal="true">true</force>
            </object>, 
            <output:serialization-parameters>
                <output:method>json</output:method>
            </output:serialization-parameters>)
    let $commit-ref := http:send-request(
                        <http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/git/refs/heads/',$branch-name))}" method="post">
                            <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                            <http:header name="Connection" value="close"/>
                            <http:header name="Accept" value="application/json"/>
                            <http:body media-type="application/json" method="text">{$update-ref}</http:body>
                         </http:request>)[1]
    return 
        if(starts-with(string($commit-ref/@status),'2')) then
            let $pull-request-data :=
                serialize(
                    <object>
                        <title>Updates from online corrections. {$path}</title>
                        <body>Review submitted changes and merge into master if acceptable.</body>
                        <head>{$branch-name}</head>
                        <base>master</base>
                    </object>, 
                    <output:serialization-parameters>
                        <output:method>json</output:method>
                    </output:serialization-parameters>)
        let $pull-request := http:send-request(
                                <http:request http-version="1.1" href="{xs:anyURI(concat($gitcommit:repo,'/pulls'))}" method="post">  
                                    <http:header name="Authorization" value="{concat('token ',$gitcommit:authorization-token)}"/>
                                    <http:header name="Connection" value="close"/>
                                    <http:header name="Accept" value="application/json"/>
                                    <http:body media-type="application/json" method="text">{$pull-request-data}</http:body>
                                </http:request>)
        let $pull-request-data := util:base64-decode($pull-request[2])
        return ('pull request ',string($pull-request[1]/@message))
    else ('fail pull request',$commit-ref/@message)   
};

declare function gitcommit:run-commit($data as item()*, $path as xs:string?, $commit-message as xs:string?) {
    if(not(empty($data))) then  
      gitcommit:step1($data, $path, $commit-message)
    else 'Failed to submit, please download your changes and send via email. ' 
};