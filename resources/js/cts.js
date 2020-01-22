// Script for dynamically changing sort order
$(document).ready(function () {
    populateCTS();
});

//JQuery to populate CTS sections. May need to move this to main syriaca.org
function populateCTS() {
    var baseURL = window.location.origin + '/exist/apps/srophe/api/cts'
    $('.ctsResolver').each(function () {
        var cachedThis = this;
        var url = baseURL + '?urn=' + $(this).data('cts-urn') + '&action=' + $(this).data('cts-format')
        $.ajax({
            url: url,
            type: 'get',
            contentType: "text/xml; charset=utf-8",                
            dataType: "html",
            success: function (data) {
                var htmlURL = window.location.origin + '/exist/apps/srophe/api/content-negotiation';
                //$(cachedThis).html(data);
                console.log(data);
                $(cachedThis).html(data);
                //get HTML
                /* 
                $.ajax({
                    url: htmlURL,
                    type: 'post',
                    contentType: "application/xml",
                    dataType: "html",
                    data: data,
                    processData: false,
                    success: function (data) {
                        $(cachedThis).html(data);
                    }
                });
                 */
            }
        });
    });
    //console.log('Start CTS development')
}