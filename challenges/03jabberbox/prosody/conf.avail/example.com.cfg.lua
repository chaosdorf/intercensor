-- Section for example.com

VirtualHost "example.com"
	enabled = false -- Remove this line to enable this host

	-- Assign this host a certificate for TLS, otherwise it would use the one
	-- set in the global section (if any).
	-- Note that old-style SSL on port 5223 only supports one certificate, and will always
	-- use the global one.
	ssl = { 
		key = "/etc/prosody/certs/example.com.key";
		certificate = "/etc/prosody/certs/example.com.crt";
		}

------ Components ------
-- You can specify components to add hosts that provide special services,
-- like multi-user conferences, and transports.
-- For more information on components, see http://prosody.im/doc/components

-- Set up a MUC (multi-user chat) room server on conference.example.com:
Component "conference.example.com" "muc"

-- Set up a SOCKS5 bytestream proxy for server-proxied file transfers:
--Component "proxy.example.com" "proxy65"

---Set up an external component (default component port is 5347)
--Component "gateway.example.com"
--	component_secret = "password"

