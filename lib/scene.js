var request = require('request');
var cheerio = require('cheerio');

var getJPG = function(url, callback) {
	request({url:url,pool:false}, function(error, response, html) {
		if (!error) {
			var $ = cheerio.load(html);

			var image_url= 'http://www.clevescene.com' + $('.slideImg').find('img').first()[0].attribs.src;
			var imageTitle = $('.subheadline').text().match(/\S.*\S/)[0];
			var imageDes = $('.caption').text().match(/\S.*\S/)[0];
			callback(image_url, imageTitle, imageDes);
		}
	});
};

function baseURL(url, callback) {
	var choppedURL = url.split('/');
	var type = choppedURL[3];
	var title = [];	
	var oid = [];
	var albumTitle = [];
	var slideURL = [];

	function buildURL(oid, title) {
		return 'http://www.clevescene.com/cleveland/' + title + '/Slideshow?oid=' + oid + '&slide=';
	}

	request({url:url, pool:false}, function(error, response, html) {
		debugger;
		var $ = cheerio.load(html);
		if (type == 'scene-and-heard') {
			oid = $('.slideshowThumbnails').find('a').first()[0].attribs.href;
			oid = oid.match(/oid=[0-9]{7}/)[0];
			oid = oid.substr(4,7);

			albumTitle = $('.postTitle').text().match(/\S.*\S/)[0];
			albumDes = $('.postBody').text().match(/\S.*\S/)[0];

			title = choppedURL[choppedURL.length-1];
			slideURL = buildURL(oid, title);
			callback(slideURL, albumTitle, albumDes);
		} else if (type == 'cleveland') {
				baseURL($('.storyItem').find('a').first()[0].attribs.href);
		}
	});
}

module.exports = {
	getJPG: getJPG,
	baseURL: baseURL
};
