Syriaca.org: Gazetteer App
=======

This branch is a subset of the Syriac.org app containing only code for Gazetteer. 

Application data for Syriaca.org [http://syriaca.org]: The Syriac Reference Portal
All publications of Syriaca.org are made available online in a free and open format using the Creative Commons licenses.

### Dependencies
#### TEI data 
Syriaca.org TEI data for publications is available: [https://github.com/srophe/srophe-app-data]
The data must be packaged and deployed to your eXist instance in order to use the syriaca.org app. 

A different data repository can be used, and specified in the config.xml file. 

#### Additional dependancies 
Check that the following packages/libraries are deployed in eXist before deploying the srophe-eXist-app:
* eXist-db Shared apps: [http://exist-db.org:8098/exist/apps/public-repo/packages/shared.html]
* JSON Parser and Serializer for XQuery .1.6 + : [https://github.com/joewiz/xqjson]
* Functx Library: [http://exist-db.org:8098/exist/apps/public-repo/packages/functx.html]

Packages can be deployed via the eXistdb dashboard. 

