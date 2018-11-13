xquery version "3.0";
(:
 :
:)
import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare namespace fo="http://www.w3.org/1999/XSL/Format";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xslfo="http://exist-db.org/xquery/xslfo";
declare namespace jmx="http://exist-db.org/jmx";

declare variable $collection {request:get-parameter('collection', '')};
declare variable $id {request:get-parameter('id', '')};
declare variable $perpage {request:get-parameter('perpage', 25) cast as xs:integer};
declare variable $start {request:get-parameter('start', 1) cast as xs:integer};

let $data-directory := 
        let $request := <http:request method="GET" href="http://localhost:{request:get-server-port()}/{request:get-context-path()}/status?c=disk"/>
        let $response := http:send-request($request)
        return $response[2]//jmx:DataDirectory/string()
let $pkgRoot := $config:expath-descriptor/@abbrev || "-" || $config:expath-descriptor/@version        
let $fontsDir := $data-directory || '/expathrepo/' || $pkgRoot || '/resources/fonts'        
let $tei := global:get-rec($id)
let $fop-config :=
    <fop version="1.0">
            <!-- Strict user configuration -->
            <strict-configuration>true</strict-configuration>
            <!-- Strict FO validation -->
            <strict-validation>false</strict-validation>
            <!-- Base URL for resolving relative URLs -->
            <base>./</base>
            <renderers>
                <renderer mime="application/pdf">
                    <fonts>
                    {
                        if ($fontsDir) then (
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/syrcomedessa.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="EstrangeloEdessa" style="normal" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/syrcombatnan.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="SertoBatnan" style="normal" weight="700"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/syrcombatnanbold.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="SertoBatnan" style="bold" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/syrcomadiabene.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="EastSyriacAdiabene" style="normal" weight="700"/>
                            </font>
                        ) else
                            ()
                    }
                    </fonts>
                </renderer>
            </renderers>
        </fop>
 

let $fo-doc := transform:transform($tei, doc('../resources/xsl/tei2PDF.xsl'),())
let $pdf := xslfo:render($fo-doc, "application/pdf", (), $fop-config)
return response:stream-binary($pdf, "application/pdf", "output.pdf")