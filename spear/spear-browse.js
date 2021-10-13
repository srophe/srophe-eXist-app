//Array of selected facets
var facetParams =[];
//Get facet name to build SPARQL url
var facetName;

var baseURL = window.location.origin + '/exist/apps/srophe/api/sparql'
//'http://localhost:8080/exist/apps/srophe/api/sparql'

$(document).ready(function () {
    $('[data-toggle="tooltip"]').tooltip({
        container: 'body'
    })
    
    //Find facets to display on page load. Uses facets.html to load facet menus
    facetName = $('.nav-tabs .active > a').data('facet');
    $('#' + facetName).load('facets.html #' + facetName + 'Facets');
    
    //Build URLs
    var facetsURL = baseURL + '?qname=facets&facet-name=' + facetName
    var datesURL = baseURL + '?qname=' + facetName + '-dates' + '&facet-name=' + facetName
    var mainQueryURL = baseURL + '?buildSPARQL=true&facet-name=' + facetName
    
    //Populate drop down menus and facets
    populateFacets(facetsURL);
    populateDates(datesURL);
    //Run intial query
    mainQuery(mainQueryURL);
    
    //Toggle facets
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        var facetName = $(e.target).data('facet') // activated tab
        //Clear other facets (some facetLists may share facets, and thus duplicate ids)
        $('.tab-pane').empty();
        //load matching facet from facets.html
        $('#' + facetName).load('facets.html #' + facetName + 'Facets');
        //Clear selected facets array when switching to a new tab.
        facetParams.splice(0, facetParams.length);
        selectedFacets();
        mainQuery(baseURL + '?buildSPARQL=true&facet-name=' + facetName);
        populateFacets(baseURL + '?qname=facets&facet-name=' + facetName);
        populateDates(baseURL + '?qname=' + facetName + '-dates' + '&facet-name=' + facetName);
    });
    
    //Submit facet, add params to facetParam Array to be submitted by facet query and main query
    $('.facetLists').on('click', '.facetGroup a', function (e) {
        e.preventDefault(e);
        var facetName = $('.nav-tabs .active > a').data('facet');
        var facetKey = $(this).data('key');
        var facetValue = $(this).data('value');
        var facetLabel = $(this).data('label');
        //Push new facet values to facetParams array.
        facetParams.push({
            name: facetKey, value: facetValue, label: facetLabel
        })
        // Build query URL
        var parameters = (facetParams.length === 0) ? '': '&' + $.param(facetParams)
        mainQuery(baseURL + '?buildSPARQL=true&facet-name=' + facetName + parameters);
        populateFacets(baseURL + '?qname=facets&facet-name=' + facetName + parameters);
        populateDates(baseURL + '?qname=' + facetName + '-dates' + '&facet-name=' + facetName + parameters);
        selectedFacets();
    });
    
    //Submit results on format change
    $('.facetLists').on('change', '#type', function () {
        var facetName = $('.nav-tabs .active > a').data('facet');
        var parameters = (facetParams.length === 0) ? '': '&' + $.param(facetParams)
        // If JSON/XML submit the form with the appropriate/requested format
        if (this.value === "JSON" || this.value === "XML") {
            window.open(baseURL + '?buildSPARQL=true&facet-name=' + facetName + parameters + '&format=' + this.value);
        } else {
            mainQuery(baseURL + '?buildSPARQL=true&facet-name=' + facetName + parameters);
        }
    })
    
    //Submit facet from input options (Person ID and Place ID), add params to facetParam Array to be submitted by facet query and main query
    $('.facetLists').on('click', '.addFacet button', function (e) {
        e.preventDefault(e);
        var facetName = $('.nav-tabs .active > a').data('facet');
        var facetKey = $(this).prev().attr('id');
        // $(this) refers to the button
        var facetValue = $(this).prev().val();
        // $(this) refers to the button
        var facetLabel = $(this).prev().val();
        // $(this) refers to the button
        //Push new facet values to facetParams array.
        facetParams.push({
            name: facetKey, value: facetValue, label: facetLabel
        })
        // Build query URL
        var parameters = (facetParams.length === 0) ? '': '&' + $.param(facetParams)
        mainQuery(baseURL + '?buildSPARQL=true&facet-name=' + facetName + parameters);
        populateFacets(baseURL + '?qname=facets&facet-name=' + facetName + parameters);
        populateDates(baseURL + '?qname=' + facetName + '-dates' + '&facet-name=' + facetName + parameters);
        selectedFacets();
    });
    
    //Remove selected facets and resubmit facet and main queries.
    $('#selectedFacetsList').on('click', 'a', function (e) {
        e.preventDefault(e);
        var facetName = $('.nav-tabs .active > a').data('facet');
        var facetKey = $(this).data('value');
        //Remove facet
        $.each(facetParams, function (i, el) {
            if (this.value == facetKey) {
                facetParams.splice(i, 1);
            }
        });
        //facetParams.splice( $.inArray(facetKey, facetParams), 1 );
        // Build query URL
        var parameters = (facetParams.length === 0) ? '': '&' + $.param(facetParams)
        mainQuery(baseURL + '?buildSPARQL=true&facet-name=' + facetName + parameters);
        populateFacets(baseURL + '?qname=facets&facet-name=' + facetName + parameters);
        populateDates(baseURL + '?qname=' + facetName + '-dates' + '&facet-name=' + facetName + parameters);
        selectedFacets();
    })
    
    $('.facetLists').bind("userValuesChanged", "#slider", function (e, data) {
        //Remove facet
        var facetName = $('.nav-tabs .active > a').data('facet');
        $.each(facetParams, function (i, el) {
            if (this.name == 'startDate') {
                facetParams.splice(i, 1);
            }
        });
        $.each(facetParams, function (i, el) {
            if (this.name == 'endDate') {
                facetParams.splice(i, 1);
            }
        });
        //facetParams.splice( $.inArray('startDate', facetParams), 1 );
        //facetParams.splice( $.inArray('endDate', facetParams), 1 );
        var url = window.location.href.split('?')[0];
        var minDate = data.values.min.toISOString().split('T')[0]
        var maxDate = data.values.max.toISOString().split('T')[0]
        //Push new facet values to facetParams array.
        facetParams.push({
            name: 'startDate', value: minDate, label: minDate
        })
        facetParams.push({
            name: 'endDate', value: maxDate, label: maxDate
        })
        // Build query URL
        var parameters = (facetParams.length === 0) ? '': '&' + $.param(facetParams)
        mainQuery(baseURL + '?buildSPARQL=true&facet-name=' + facetName + parameters);
        populateFacets(baseURL + '?qname=facets&facet-name=' + facetName + parameters);
        populateDates(baseURL + '?qname=' + facetName + '-dates' + '&facet-name=' + facetName + parameters);
    });
});

//Submit main SPARQL query based on facet parameters
function mainQuery(url) {
    type = $("#type option:selected").val();
    var config = ''
    //var win = window.open(url, '_blank');
    // Otherwise send to d3 visualization, set format to json.
    $. get (url + '&type=' + type + '&format=json', function (data) {
        d3sparql.graphType(data, type, config);
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.log("JavaScript error: " + textStatus);
    });
}

// Build Facets
function populateFacets(url) {
    $. get (url + '&format=json', function (data) {
        $('.facetGroup a').remove();
        var dataArray = data.results.bindings;
        if (dataArray[0] == undefined) dataArray =[dataArray];
        $.each(dataArray, function (currentIndex, currentElem) {
            if (currentElem.facet_value) {
                $("<a/>").attr("class", "facet").attr("href", "#").attr("data-key", currentElem.key.value).attr("data-label", currentElem.facet_label.value).attr("data-value", currentElem.facet_value.value).append(currentElem.facet_label.value + ' (' + currentElem.facet_count.value + ') ').appendTo("#" + currentElem.key.value);
            }
        });
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.log(textStatus);
    });
}

//Print Selected facets in HTML
function selectedFacets() {
    $('#selectedFacetsList span').remove();
    if (facetParams.length !== 0) {
        $.each(facetParams, function (currentIndex, currentElem) {
            if (currentElem.value) {
                $("<span/>").attr("class", "selectedFacet").append(currentElem.label + " <a href='#' class='removeFacet' data-value='" + currentElem.value + "' data-label='" + currentElem.label + "'>X</a>").appendTo("#selectedFacetsList");
            }
        })
    }
}

//Fill in dates for Date slider
//if(getMin != '' && getMin != '0') {
function populateDates(url) {
    if ($("#slider").dateRangeSlider()) {
        $("#slider").dateRangeSlider("destroy");
        $("#noDates").remove();
    }
    $. get (url + '&format=json', function (data) {
        var dataArray = data.results.bindings;
        if (dataArray[0] == undefined) dataArray =[dataArray];
        if (dataArray[0].facet_count.value != '0') {
            var getMin = dataArray[0].facet_value.value;
            var minValue = (getMin.startsWith('-0')) ? getMin.replace('-0', '-000'): getMin;
            var getMax = dataArray[dataArray.length - 1].facet_value.value;
            var maxValue = (getMax.startsWith('-0')) ? getMax.replace('-0', '-000'): getMax;
            var minPadding = -00500; //(parseInt(minValue) - 25)
            var maxPadding = 1900; //(parseInt(maxValue) + 25)
            $("#slider").dateRangeSlider({
                bounds: {
                    min: new Date(minPadding, 0, 0),
                    max: new Date(maxPadding, 0, 0)
                },
                defaultValues: {
                    min: new Date(minValue), max: new Date(maxValue)
                },
                formatter: function (val) {
                    var year = val.getFullYear();
                    return year;
                }
            });
        } else {
            // console.log('No dates');
            $("#slider").html("<p id='noDates' class='alert alert-warning'>No Dates available</p>");
        }
    }).fail(function (jqXHR, textStatus, errorThrown) {
        console.log(textStatus);
    });
}

/* Toggle textarea */
function toggle() {
    d3sparql.toggle()
}