vcl 4.1;

import dynamic;
import brotli;
import headerplus;

backend default {
    .host = "1.1.1.1";
    .port = "80";
}

sub vcl_init {
    # Section default code

    # set up a dynamic director
    # for more info, see https://github.com/nigoroll/libvmod-dynamic/blob/master/src/vmod_dynamic.vcc
    new d = dynamic.director(port = "80", ttl = 60s);
	brotli.init(encoding = BOTH);
}

sub vcl_recv {
    set req.backend_hint = d.backend("egress-router");
	if (req.http.accept-encoding ~ "br") {
		set req.http.x-ae = "br";
	} else {
		set req.http.x-ae = "gzip";
	}
}

sub vcl_backend_fetch {
	# If the backend supports brotli nativly, use this code
	# to get the right version and cache it:
	if (bereq.http.x-ae == "br") {
		brotli.accept(BOTH);
	} else {
		brotli.accept(GZIP);
	}
}

# Method: vcl_recv
# Description: Happens before we check if we have this in cache already.
#
# Purpose: Typically you clean up the request here, removing cookies you don't need,
# rewriting the request, etc.
sub vcl_recv {
    
}

# Method: vcl_backend_response
# Description: Happens after reading the response headers from the backend.
#
# Purpose: Here you clean the response headers, removing Set-Cookie headers
# and other mistakes your backend may produce. This is also where you can manually
# set cache TTL periods.
sub vcl_backend_response {
	headerplus.init(beresp);
	headerplus.attr_set("Vary", "x-ae");
	headerplus.write();

	# If the backend does not support Brotli, or if the
	# support for it is unknown, use this code
	if (bereq.http.x-ae == "br") {
		# Adjust quality here, if needed
		brotli.compress(quality=6);
	} else {
		brotli.decompress();
	}
}

# Method: vcl_deliver
# Description: Happens when we have all the pieces we need, and are about to send the
# response to the client.
#
# Purpose: You can do accounting logic or modify the final object here.
sub vcl_deliver {
    set resp.http.X-Varnish-Cache = "true";
	headerplus.init(resp);
	headerplus.attr_delete("Vary", "x-ae");
	headerplus.write();
}

# Method: vcl_hash
# Description: This method is used to build up a key to look up the object in Varnish.
#
# Purpose: You can specify which headers you want to cache by.
sub vcl_hash {
    # Purpose: Split cache by HTTP and HTTPS protocol.
    hash_data(req.http.X-Forwarded-Proto);
}
