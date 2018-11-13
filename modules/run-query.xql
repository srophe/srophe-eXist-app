xquery version "3.0";
(:
 : Run modules as needed
:)

import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace tei2rdf="http://syriaca.org/tei2rdf" at "lib/tei2rdf.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


for $r in collection('/db/apps/srophe-data/data/places')
return tei2rdf:save-rec($r)