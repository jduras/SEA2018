// save the webpage specified in var url to the hard drive as 1.html

var url ='https://www.southerneconomic.org/current-year-program/?conferenceId=4';
var page = new WebPage();
var fs = require('fs');
var waittime = 2500;

page.open(url, function (status) {
    just_wait();
});

function just_wait() {
    setTimeout(function() {
        fs.write('1.html', page.content, 'w');
        phantom.exit();
    }, waittime);
}
