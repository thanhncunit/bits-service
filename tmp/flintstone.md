## /var/vcap/jobs/bits-service/config/nginx.conf
```
log_format main  '$host - [$time_local] "$request" $status $bytes_sent "$http_referer" "$http_user_agent" $proxy_add_x_forwarded_for vcap_request_id:$upstream_http_x_vcap_request_id response_time:$upstream_response_time';
log_format metrics '"$time_local" request:"$request" status:$status request-time:$request_time bytes-sent:$bytes_sent';
log_format metrics_csv '"$time_local","$request",$status,$request_time,$bytes_sent';

access_log /var/vcap/sys/log/nginx_bits/access.log main;
access_log /var/vcap/sys/log/nginx_bits/metrics.log metrics;
access_log /var/vcap/sys/log/nginx_bits/metrics_csv.log metrics_csv;
```

## Bosh scp
bosh -t sl -d egurnov.yml scp bits-service/0 --download /tmp/collectd.csv.conf ./
bosh -t sl -d egurnov.yml scp bits-service/0 --upload collectd.egurnov.conf.bits-service.0 /tmp/collectd.egurnov.conf.1

## Commands
monit restart collectd & watch -n 1 monit summary

## Poor man's HTTP server
### New shell for each response
while true ; do nc -l 9001 -c 'echo -e "HTTP/1.1 200 OK\n\n $(date)"'; done

### Pre-configured message
while true ; do echo -e "HTTP/1.1 200 OK\n\n" | nc -l 9001 ; done

### Pretty-print JSON
while true ; do echo -e "HTTP/1.1 200 OK\n\n" | nc -l 9001 | grep -E 'bytes_sent|response-time' | jq . ; done

### Filter for bytes_sent and response-time
while true ; do echo -e "HTTP/1.1 200 OK\n\n" | nc -l 9001 | grep '^\[' | jq '.[] | select(.type_instance == "bytes_sent" or .type_instance == "response-time")' ; done

### Filter for tail_csv
while true ; do echo -e "HTTP/1.1 200 OK\n\n" | nc -l 9001 | grep '^\[' | jq '.[] | select(.plugin == "tail_csv")' ; done

## Grafana metric string
 e5a3df78-1e62-4da0-aa4c-b4500ee4edc7.bosh.bits-service-local.bits-service.0.f04e3ee7-0965-4d10-a00e-8ffdb7befd7a.tail-wtf-tail.gauge-bytes_sent
|space id                            |hard|deployment name   |job name    |i| host name                          |plugin|plugin instance |type| type instance|
                                      coded                                nstance

https://collectd.org/wiki/index.php/Naming_schema
space id from /var/vcap/jobs/collectd/collectd.d/write_metric_mtlumberjack.conf
