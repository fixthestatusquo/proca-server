# good old ab, trying to add 1000 signatures from 500 concurrent users. Will the server drop a ball and 5xx a request?
# checkout output.txt for an example (hint, no, it doesn't)
ab -n 1000 -c 500 -r 'https://api.proca.app/api?query=query%20getCount(%24actionPage%3A%20Int!)%7BactionPage(id%3A%24actionPage)%20%7B%20campaign%20%7B%20stats%20%7B%20supporterCount%20%7D%20%7D%7D%7D&variables=%7B%22actionPage%22%3A20%7D'

