This directory contains implementation of logging and metrics for my SSL proxy.

The general idea is that nginx emits the access logs to a listener over
`rsyslog`. `vector` takes those messages, parses them and stores them in the
analytical DB for long term storage and analytics.

In parallel with storing the logs, `vector` aggregates the access logs and
exposes for `prometheus` to scrape.

Schematically:

![](./nginx logging and metrics.png)
