<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <sch:ns uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
    <sch:ns uri="https://srophe.app" prefix="srophe"/>
    <sch:pattern>
        
        
        <sch:rule context="//tei:text//tei:place/tei:placeName[@xml:lang='en']">
            <sch:assert test="count(./parent::tei:place/tei:placeName[@xml:lang='en' and @srophe:tags='#syriaca-headword']) = 1">
                There must be one and only one &lt;placeName&gt; element with the combination of @srophe:tags="#syriaca-headword" and @xml:lang="en".
            </sch:assert>
        </sch:rule>
        
        <sch:rule context="//tei:text//tei:place/tei:placeName[@srophe:tags='#syriaca-headword']">
            <sch:let name="langsOfHW" value="//tei:place/tei:placeName[@srophe:tags='#syriaca-headword']/@xml:lang"/>
            <sch:assert test="count(distinct-values($langsOfHW)) = count($langsOfHW)">
                There cannot be more than one headword (@srophe:tags="#syriaca-headword") per &lt;placeName&gt; with the same language (@xml:lang).
            </sch:assert>
        </sch:rule>
        
        <sch:rule context="//tei:text//tei:person/tei:persName[@xml:lang='en']">
            <sch:assert test="count(./parent::tei:person/tei:persName[@xml:lang='en' and @srophe:tags='#syriaca-headword']) = 1">
                There must be one and only one &lt;persName&gt; element with the combination of @srophe:tags="#syriaca-headword" and @xml:lang="en".
            </sch:assert>
        </sch:rule>
        
        <sch:rule context="//tei:text//tei:person/tei:persName[@srophe:tags='#syriaca-headword']">
            <sch:let name="langsOfHW" value="//tei:person/tei:persName[@srophe:tags='#syriaca-headword']/@xml:lang"/>
            <sch:assert test="count(distinct-values($langsOfHW)) = count($langsOfHW)">
                There cannot be more than one headword (@srophe:tags="#syriaca-headword") per &lt;persName&gt; with the same language (@xml:lang).
            </sch:assert>
        </sch:rule>
        

        
        
    </sch:pattern>
</sch:schema>