xquery version "3.1";

(:~ 
 : Build indexes for all facets and search fields in configuration files. 
 :)
 
import module namespace sf = "http://srophe.org/srophe/facets" at "lib/facets.xql";

sf:update-index()
(:sf:build-index():)

