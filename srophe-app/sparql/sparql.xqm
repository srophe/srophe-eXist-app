xquery version "3.1";
(:
 : Srophe SPARQL queries
:)
module namespace sprql-queries="http://syriaca.org/sprql-queries";

import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(: Subjects counts all the records that reference this idno  :)
declare function sprql-queries:related-subjects($ref){
let $q :=
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          ?s dcterms:relation <",$ref,">.}
    ")
return sparql:query($q)
};

(: Subjects counts all the records that reference this idno  :)
declare function sprql-queries:related-subjects-count($ref){
let $q :=
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT (COUNT(*) AS ?count)
        WHERE {
          ?s dcterms:relation <",$ref,">.}
    ")
return sparql:query($q)
};

declare function sprql-queries:related-citations($ref){
let $q :=
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          <",$ref,"> dcterms:relation ?o;
        }")
return sparql:query($q)
};

declare function sprql-queries:related-citations-count($ref){
let $q :=
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT (COUNT(*) AS ?count)
        WHERE {
          <",$ref,"> dcterms:relation ?o;
        }")
return sparql:query($q)
};

declare function sprql-queries:label($ref){
let $q := 
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          <",$ref,"> rdfs:prefLabel ?o;
        }")
return sparql:query($q) 
};

declare function sprql-queries:label-desc($ref){
let $q := 
    concat("prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>      
                                
        SELECT *
        WHERE {
          <",$ref,"> rdfs:label ?o;
            
        }")
return sparql:query($q) 
};


(:SPEAR relationship and events Queries :)
(: relationships and counts :)
declare function sprql-queries:personFactoids(){
let $q := 
    "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>  
        prefix syriaca: <http://syriaca.org/schema#>
                                
        SELECT *
        WHERE {
          ?factoid syriaca:personFactoid ?person;
            rdfs:label  ?factoidLabel.
        }"
return sparql:query($q) 
};

(: Test query :)
declare function sprql-queries:test-q(){
let $q := 
    "prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        prefix owl: <http://www.w3.org/2002/07/owl#>
        prefix skos: <http://www.w3.org/2004/02/skos/core#>
        prefix xsd: <http://www.w3.org/2001/XMLSchema#>
        prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        prefix lawd: <http://lawd.info/ontology/>
        prefix dcterms: <http://purl.org/dc/terms/>
        prefix foaf: <http://xmlns.com/foaf/0.1/>
        prefix dc: <http://purl.org/dc/terms/>  
        prefix syriaca: <http://syriaca.org/schema#>
                                
        SELECT *
        WHERE {
          ?factoid <http://syriaca.org/schema#/personFactoid> ?person.
        }"
(:
let $q := "
    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    prefix owl: <http://www.w3.org/2002/07/owl#>
    prefix skos: <http://www.w3.org/2004/02/skos/core#>
    prefix xsd: <http://www.w3.org/2001/XMLSchema#>
    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    prefix lawd: <http://lawd.info/ontology/>
    prefix dcterms: <http://purl.org/dc/terms/>
    prefix foaf: <http://xmlns.com/foaf/0.1/>
    prefix dc: <http://purl.org/dc/terms/>      
                                                    
    SELECT *
    WHERE {
        ?relatedID <http://purl.org/dc/terms/relation> <http://syriaca.org/place/78>;
            skos:prefLabel  ?relatedLabel.
        FILTER ( langMatches(lang(?relatedLabel), 'en')) .
        }
    LIMIT 25"
    
    Realted to edessa, with edessa
                       
                    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                    prefix owl: <http://www.w3.org/2002/07/owl#>
                    prefix skos: <http://www.w3.org/2004/02/skos/core#>
                    prefix xsd: <http://www.w3.org/2001/XMLSchema#>
                    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                    prefix lawd: <http://lawd.info/ontology/>
                    prefix dcterms: <http://purl.org/dc/terms/>
                    prefix foaf: <http://xmlns.com/foaf/0.1/>
                    prefix dc: <http://purl.org/dc/terms/>      
                                                                    
                    SELECT *
                    WHERE {
                        ?relatedID <http://purl.org/dc/terms/relation> ?objectID.
                        ?relatedID skos:prefLabel  ?relatedLabel.
                        ?objectID skos:prefLabel  ?objectLabel.
                        FILTER ( ?objectID = <http://syriaca.org/place/78>) .
                        FILTER ( langMatches(lang(?relatedLabel), 'en')) .
                        FILTER ( langMatches(lang(?objectLabel), 'en')) .
                        }
                    LIMIT 25 

                    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                    prefix owl: <http://www.w3.org/2002/07/owl#>
                    prefix skos: <http://www.w3.org/2004/02/skos/core#>
                    prefix xsd: <http://www.w3.org/2001/XMLSchema#>
                    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                    prefix lawd: <http://lawd.info/ontology/>
                    prefix dcterms: <http://purl.org/dc/terms/>
                    prefix foaf: <http://xmlns.com/foaf/0.1/>
                    prefix dc: <http://purl.org/dc/terms/>      
                                                                    
                    SELECT *
                    WHERE {
                        ?relatedID <http://purl.org/dc/terms/relation> ?relatedObject.
                        ?relatedID skos:prefLabel  ?relatedLabel.
                        ?relatedObject skos:prefLabel  ?relatedObjectLabel.
                        FILTER ( ?relatedObject = <http://syriaca.org/place/78>) .
                        }
                    LIMIT 25

    :)
    
return sparql:query($q)   
};

declare function sprql-queries:run-query($data){
    sparql:query($data)
};