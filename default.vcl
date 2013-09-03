#
# CLOUDBUILDERS - KEYSTONE VARNISH v1 VCL
# 


probe healthcheck {
	.url = "/v2.0/";
	.interval = 20s;
	.timeout = 1.0s;
	.window = 8;
	.threshold = 3;
	.initial = 3;
}



backend essexkeystone500010 {
    .host = "172.16.167.163";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500011 {
    .host = "172.16.167.164";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500012 {
    .host = "172.16.149.79";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500013 {
    .host = "10.32.136.80";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500014 {
    .host = "10.32.136.84";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500015 {
    .host = "172.16.167.165";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500016 {
    .host = "172.16.149.133";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500017 {
    .host = "172.16.149.82";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone500018 {
    .host = "172.16.167.166";
    .port = "5000";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}



backend essexkeystone3535710 {
    .host = "172.16.167.163";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535711 {
    .host = "172.16.167.164";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535712 {
    .host = "172.16.149.79";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535713 {
    .host = "10.32.136.80";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535714 {
    .host = "10.32.136.84";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535715 {
    .host = "172.16.167.165";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535716 {
    .host = "172.16.149.133";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535717 {
    .host = "172.16.149.82";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}

backend essexkeystone3535718 {
    .host = "172.16.167.166";
    .port = "35357";
    .connect_timeout = 1s;
    
    
    .probe = healthcheck;
}



director k5000 round-robin {
	{ .backend = essexkeystone500010; }
	{ .backend = essexkeystone500011; }
	{ .backend = essexkeystone500012; }
	{ .backend = essexkeystone500013; }
	{ .backend = essexkeystone500014; }
	{ .backend = essexkeystone500015; }
	{ .backend = essexkeystone500016; }
	{ .backend = essexkeystone500017; }
	{ .backend = essexkeystone500018; }
}

director k35357 round-robin {
    { .backend = essexkeystone3535710; }
    { .backend = essexkeystone3535711; }
    { .backend = essexkeystone3535712; }
    { .backend = essexkeystone3535713; }
    { .backend = essexkeystone3535714; }
    { .backend = essexkeystone3535715; }
    { .backend = essexkeystone3535716; }
    { .backend = essexkeystone3535717; }
    { .backend = essexkeystone3535718; }
}


acl purge {
	"localhost";
	"172.16.144.11";
	"172.16.180.212";
}

C{
       #include <syslog.h>
       #include <sys/time.h>
       #include <stdlib.h>
       #include <stdio.h>
       #include <string.h>
}C


sub vcl_recv {
	
	C{
		struct timeval detail_time;
		gettimeofday(&detail_time,NULL);
		char start[20];
		sprintf(start, "%lu%06lu", detail_time.tv_sec, detail_time.tv_usec);
		VRT_SetHdr(sp, HDR_REQ, "\020X-Request-Start:", start, vrt_magic_string_end);
	}C	
	
	if (req.request == "PURGE") {
		if (!client.ip ~ purge) {
			error 405 "Not allowed.";
		}
		return (lookup);
	}

	if (req.http.port == "5000") {
		set req.backend = k5000;
	}
	else {
		set req.backend = k35357;
	}
	/* we dont wanna cache other than GETS, since HEADS are fast enough */
	if (req.request == "DELETE" || req.request == "POST" || req.request == "PUT" || req.request == "HEAD") {
		return(pass);
	}
	else {
		return(lookup);
	}
}

sub vcl_deliver {
	set resp.http.X-MLVarnish-Server = ""+ server.hostname;
	set resp.http.X-Request-Start = req.http.X-Request-Start;
}

sub vcl_hit {
	if (req.request == "PURGE") {
		purge;
       	error 200 "Purged.";
	}
}

sub vcl_miss {
    if (req.http.port == "5000") {
        set req.backend = k5000;
    }
    else {
        set req.backend = k35357;
    }
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged.";
    }
}

sub vcl_fetch {
	if(beresp.status == 503) {
		error 503;
	}
	if(beresp.status == 200 && req.url !~ "/v2.0/tokens/.*") {
		set beresp.http.cache-control = "max-age=900";
		set beresp.ttl = 1w;
	}
}

sub vcl_error {

	if (obj.status == 503 && req.restarts < 1) {
		return(restart);
	}
}


