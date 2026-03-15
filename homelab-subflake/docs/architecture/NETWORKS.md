# LAN

Physical network where most of the hosts are

# Client

Network through which I can connect when not at home. Uses service records set
up as a view in DNS.

# Backbone pattern

Today I have two networks, `backbone` and `backbone-inner`.

- **`backbone`**: The "outer" backbone, providing the physical/logical path
  between nodes.
- **`backbone-inner`**: The service interconnect network (overlay). Its job is
  to allow services to talk directly over a private segment without there being
  a central node that can snoop on the traffic.

All internal service traffic (SSL Proxy -> Backend, Prometheus -> Exporter)
should use `backbone-inner`.

Example routing:

1. `$device` in LAN wishes to access NTP
2. `$device` resolves NTP domain
3. `$device` can just go to 192.168.1.1 (LAN IP) and get the data

1. `$device` in LAN wishes to access Gitea
2. `$device` resolves Gitea domain, it maps to SSL proxy (LAN IP)
3. `$device` accesses SSL proxy IP
4. SSL proxy reaches out to the Gitea instance over `backbone-inner`

1. `$device` in client network wishes to access Gitea
2. `$device` resolves Gitea domain, it maps to SSL proxy IP in the client view
3. `$device` accesses SSL proxy IP
4. SSL proxy reaches out to the Gitea instance over `backbone-inner`

# DB

Used by services to access the database. Legacy, will be folded into
`backbone-inner`

# Mgmt

Used by admin to access nodes over SSH. Potentially legacy. May be folded into
`backbone-inner`

# Deprecated

Following dedicated networks have been deprecated, they were not worth the
trouble.

- `logging`
- `monitoring`
