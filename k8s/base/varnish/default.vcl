vcl 4.1;

import dynamic;

backend default none;

sub vcl_init {
    # Section default code

    # set up a dynamic director
    # for more info, see https://github.com/nigoroll/libvmod-dynamic/blob/master/src/vmod_dynamic.vcc
    new d = dynamic.director(port = "80", ttl = 60s);
}

sub vcl_recv {
    set req.backend_hint = d.backend("egress-router");
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

}


# Method: vcl_deliver
# Description: Happens when we have all the pieces we need, and are about to send the
# response to the client.
#
# Purpose: You can do accounting logic or modify the final object here.
sub vcl_deliver {
    set resp.http.X-Section-Varnish-Cache = "True";
}

# Method: vcl_hash
# Description: This method is used to build up a key to look up the object in Varnish.
#
# Purpose: You can specify which headers you want to cache by.
sub vcl_hash {
    # Purpose: Split cache by HTTP and HTTPS protocol.
    hash_data(req.http.X-Forwarded-Proto);
}
