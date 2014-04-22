var should = require('should'),
	http = require('http'),
	express = require('express'),
	request = require('request'),
	log = require("node-logging"),
	Cookies = require('cookies'),
	os = require("os"),
	util = require('util'),
	net = require('net'),
	spawn = require('child_process').spawn;
    
log.setLevel("info")
    
var backend = express();

backend.get('*', function(req, res){
	backend.emit('request', req);
	if (backend.listeners('response').length == 0) {
		res.send('hello world');
	} else {
		backend.emit('response', res);
	}
});

backend.post('*', function(req, res){
	backend.emit('request', req);
	if (backend.listeners('response').length == 0) {
		res.send('hello world');
	} else {
		backend.emit('response', res);
	}
});

backend.put('*', function(req, res){
	backend.emit('request', req);
	if (backend.listeners('response').length == 0) {
		res.send('hello world');
	} else {
		backend.emit('response', res);
	}
});

backend.delete('*', function(req, res){
	backend.emit('request', req);
	if (backend.listeners('response').length == 0) {
		res.send('hello world');
	} else {
		backend.emit('response', res);
	}
});



backend.listen(35357);
backend.listen(5000);

describe("Varnish Tests" ,function(done){
	   
	afterEach(function(done){
		backend.removeAllListeners('request');
		backend.removeAllListeners('response');
		done();
 	});
  
  	beforeEach(function(done){
		backend.removeAllListeners('request');
		backend.removeAllListeners('response');
		done();
 	});

	it("Retorno X-Request-Start", function(done){
		request({
			url:"http://localhost:8081/lalalala",
			method:"GET",
			jar: false,
		}, function(error, response, body){
			response.statusCode.should.equal(200)
			should.exist(response.headers['x-request-start'])
			done()
		})
	});

	it("Retorno X-MLVarnish-Server", function(done){
		request({
			url:"http://localhost:8081/lala",
			method:"GET",
			jar: false
		}, function(error, response, body){
			response.statusCode.should.equal(200)
			should.exist(response.headers['x-mlvarnish-server'])
			response.headers['x-mlvarnish-server'].should.equal(os.hostname());
			done()
		})
	});

	it("Retorno cache-control para !~ /v2.0/tokens/.*", function(done){
		request({
			url:"http://localhost:8081/lalala",
			method:"GET"},
		function(error, response, body) {
			response.statusCode.should.equal(200)
			should.exist(response.headers['cache-control'])
			response.headers['cache-control'].should.equal("max-age=900");
			done()
		})
	});

	it("NO se cachea HEAD", function(done){
		backend.on ('response', function (response) {
			response.send(200);
		});
		
		request({
			url:"http://localhost:8081/v2.0/tokens",
			method:"POST"},
		function(error, response, body){
			response.statusCode.should.equal(200)
			backend.removeAllListeners('response');
			backend.on ('response', function (response) {
				response.send(201);
			});
			request({
				url:"http://localhost:8081/v2.0/tokens",
				method:"POST"},
			function(error, response, body){
				response.statusCode.should.equal(201)
				done()
			})
		})
	});
	
	it("NO se cachea PUT", function(done){
		backend.on ('response', function (response) {
			response.send(200);
		});
		
		request({
			url:"http://localhost:8081/v2.0/tokens",
			method:"PUT"},
		function(error, response, body){
			response.statusCode.should.equal(200)
			backend.removeAllListeners('response');
			backend.on ('response', function (response) {
				response.send(201);
			});
			request({
				url:"http://localhost:8081/v2.0/tokens",
				method:"PUT"},
			function(error, response, body){
				response.statusCode.should.equal(201)
				done()
			})
		})
	});
	
	it("NO se cachea DELETE", function(done){
		backend.on ('response', function (response) {
			response.send(200);
		});
		
		request({
			url:"http://localhost:8081/v2.0/tokens",
			method:"DELETE"},
		function(error, response, body){
			response.statusCode.should.equal(200)
			backend.removeAllListeners('response');
			backend.on ('response', function (response) {
				response.send(201);
			});
			request({
				url:"http://localhost:8081/v2.0/tokens",
				method:"DELETE"},
			function(error, response, body){
				response.statusCode.should.equal(201)
				done()
			})
		})
	});

	
	it("NO se cachea HEAD", function(done){
		backend.on ('response', function (response) {
			response.send(200);
		});
		
		request({
			url:"http://localhost:8081/v2.0/tokens",
			method:"HEAD"},
		function(error, response, body){
			response.statusCode.should.equal(200)
			backend.removeAllListeners('response');
			backend.on ('response', function (response) {
				response.send(201);
			});
			request({
				url:"http://localhost:8081/v2.0/tokens",
				method:"HEAD"},
			function(error, response, body){
				response.statusCode.should.equal(201)
				done()
			})
		})
	});
	

	it("No se retorna cache-control en status != 200", function(done){
		backend.on ('response', function (response) {
			response.send(201);
		});	
		http.get({
			port: 8081,
			path: '/lelele'
		}, function(response) {
			response.statusCode.should.equal(201)
			should.not.exist(response.headers['cache-control'])
			done();
		}).on('error', function(e) {
			should.fail('expected an error!')
		});
	});
	
	it("Cache de objeto sin tener en cuenta el domain", function(done){
		request({
			url:"http://localhost:8081/lalalalalala",
			method:"GET"},
		function(error, response, body){
			request({
				url:"http://localhost:8081/lalalalalala",
				method:"GET"},
			function(error, response, body){
				response.statusCode.should.equal(200)
				var xvarnish = response.headers['x-varnish'];
				request({
					url:"http://127.0.0.1:8081/lalalalalala",
					method:"GET"}, 
				function(error, response, body) {
					response.statusCode.should.equal(200)
					should.exist(response.headers['x-varnish'])
					should.exist(response.headers['x-varnish'].split(" ")[1])
					xvarnish.split(" ")[1].should.equal(response.headers['x-varnish'].split(" ")[1]);
					done()
				})
			})
		})
	});

});

