Syriaca.org
=======

Application data for Syriaca.org [http://syriaca.org]: The Syriac Reference Portal
All publications of Syriaca.org are made available online in a free and open format using the Creative Commons licenses.

### Dependencies
#### TEI data 
Syriaca.org TEI data for publications is available: [https://github.com/srophe/srophe-app-data]
The data must be packaged and deployed to your eXist instance in order to use the syriaca.org app. 

#### Additional dependancies 
Check that the following packages/libraries are deployed in eXist before deploying the srophe-eXist-app:
* eXist-db Shared apps: [http://exist-db.org:8098/exist/apps/public-repo/packages/shared.html]
* JSON Parser and Serializer for XQuery .1.6 + : [https://github.com/joewiz/xqjson]
* Functx Library: [http://exist-db.org:8098/exist/apps/public-repo/packages/functx.html]
* SPARQL and RDF indexing for eXist-db [http://exist-db.org:8098/exist/apps/public-repo/packages/exist-sparql.html?eXist-db-min-version=3.0.3]
* EXPath Crypto library (For github webhooks, not needed otherwise) [http://exist-db.org:8098/exist/apps/public-repo/packages/expath-crypto-exist-lib.html]

Packages can be deployed via the eXistdb dashboard. 

### Setting up Github webhooks
Syrica.org uses Github webhooks [https://developer.github.com/webhooks/] to keep the remote application upto date with the github repository.
* Requires the EXPath Crypto library to verify Github submissions. [http://exist-db.org:8098/exist/apps/public-repo/packages/expath-crypto-exist-lib.html]
* Requires a config file added to the app home directory. Do not store this file in your github repository. 
  Example:
    
    ```
    <config>
        <!-- Configuration for Github webhooks sync feature -->
        <git-config>
            <!-- github secret key can be stored here or as a environment variable. (prefered)  -->
            <private-key/>
            <private-key-variable>VARIABLE_NAME</private-key-variable>
            <!-- github token for rate limiting. can be stored here or as a environment variable. (prefered)  -->
            <gitToken/>
            <gitToken-variable/>
            <!-- Branch to sync, if empty assumes master -->
            <github-branch>master</github-branch>
            <!-- Collection in eXistdb to sync app to. example: /db/apps/srophe -->
            <exist-collection>/db/apps/srophe</exist-collection>
            <!-- App root in git repository. example: srophe-app -->
            <repo-name>srophe-app</repo-name>
        </git-config>
    </config>
    ```
* Setup webhooks on your github repository, Syriaca.org XQuery endpoint: http://localhost:8080/exist/apps/srophe/modules/git-sync.xql. [https://developer.github.com/webhooks/creating/]   


