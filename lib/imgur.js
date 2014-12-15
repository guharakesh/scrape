var request = require('request');
var cheerio = require('cheerio');
var scene = require('./scene.js');


function createAlbum(albumTitle, albumDes, callback) {
	var options = {
		url: 'https://api.imgur.com/3/album/',
		headers: {
			'Authorization': 'Client-ID e6c26e0091c2b91'
		},
		pool: false
	};
	request.post(options, function(error, response, body) {
		var hash = JSON.parse(body).data.deletehash;
		var id = JSON.parse(body).data.id;
		var albumURL = 'http://imgur.com/a/' + id;
		callback(hash, albumURL);	
	}).form({'title': albumTitle, 'description': albumDes});
}

function upload(image_url, hash, imageTitle, imageDes, callback) {
	var options = {
		url: 'https://api.imgur.com/3/image',
		headers: {
			'Authorization': 'Client-ID e6c26e0091c2b91'
		},
		pool: false
	};
	request.post(options, function(error, response, body) {
		var imageID = JSON.parse(body).data.id;
		callback(imageID);
	}).form({'image': image_url, 'album': hash, 'title': imageTitle, 'description': imageDes});
}

var upImages = function(url, albumTitle, albumDes, callback) {
	var idArray = [];
	var firstURL = url + '1';
	var count = [];
	var hash = [];
	request({url:firstURL, pool:false}, function(error, response, html) {

		var $ = cheerio.load(html);
		count = $('.slideshowCount').text().match(/of [0-9]+/)[0].substr(3);
		var fullURL = [];

		createAlbum(albumTitle, albumDes, function(hash, link) {

			var upAndPush = function(image_url, imageTitle, imageDes) {
				upload(image_url, hash, imageTitle, imageDes, function(imageID) {
					idArray.push(imageID);
					if (idArray.length == count) {
						callback(link);
					}
				});
			};
			for (var i=1; i<=count; i++) {
				fullURL = url + i;	
				scene.getJPG(fullURL, upAndPush);
			}
		});
	});

};

module.exports = {
	upload: upload,
	upImages: upImages,
	createAlbum: createAlbum
};
