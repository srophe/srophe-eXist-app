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
          ?s <http://purl.org/dc/terms/relation> <",$ref,">.}
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
          ?s <http://purl.org/dc/terms/relation> <",$ref,">.}
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
          <",$ref,"> <http://purl.org/dc/terms/relation> ?o;
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
          <",$ref,"> <http://purl.org/dc/terms/relation> ?o;
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
          <",$ref,"> skos:prefLabel ?o;
        }")
return sparql:query($q) 
};

declare function sprql-queries:run-query($data){
    sparql:query($data)
};