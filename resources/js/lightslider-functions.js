$(document).ready(function () {
    $("#lightSlider").lightSlider({
        item: 5,
        autoWidth: false,
        slideMove: 1, // slidemove will be 1 if loop is true
        loop: false,
        easing: 'cubic-bezier(0.25, 0, 0.25, 1)',
        speed: 600,
        slideMargin: 5,
        prevHtml: '<span class="glyphicon glyphicon-chevron-left slider-control" aria-hidden="true"/>',
        nextHtml: '<span class="glyphicon glyphicon-chevron-right slider-control" aria-hidden="true"/>',
        responsive:[ {
            breakpoint: 768,
            settings: {
                item: 3,
                slideMove: 1,
                slideMargin: 5
            }
        }, {
            breakpoint: 320,
            settings: {
                item: 1,
                slideMove: 1
            }
        }]
    });
});