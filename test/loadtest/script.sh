# good old ab, trying to add 1000 signatures from 500 concurrent users. Will the server drop a ball and 5xx a request?
# checkout output.txt for an example (hint, no, it doesn't)
ab -n 1000 -c 500 -p payload.json -T application/json https://api.proca.app/api

