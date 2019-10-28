//var baseURL = window.location.origin + '/exist/apps/srophe/api/sparql'

$(document).ready(function () {
    
    //Submit facet, add params to facetParam Array to be submitted by facet query and main query
    $('.searchFacets').on('click', 'button', function (e) {
        e.preventDefault(e);
        var value = $(this).closest('.searchFacets').find("input").val();
        var name = $(this).closest('.searchFacets').find("input").attr('id');
        var params = '?view=' + $.urlParam('view') + '&fq=;' + name + ':' + value + $.urlParam('fq');
        if (value.endsWith("/")) {
          alert('No entity entered')
        } else {
           document.location.href =  window.location.pathname + params 
        }
    });
    
});

//Get URL parameters by name. See: https://stackoverflow.com/questions/7731778/get-query-string-parameters-url-values-with-jquery-javascript-querystring
$.urlParam = function (name) {
    var results = new RegExp('[\?&]' + name + '=([^&#]*)')
                      .exec(window.location.search);
    return (results !== null) ? results[1] || 0 : false;
}
