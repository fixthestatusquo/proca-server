# Miscellaneous


## Remove the petition visit request for improved privacy

When user visits petition site, the widget loads and makes a request to Proca API to fetch signature count and optionally some widget settings.
This means that even if somebody is visiting, their browser will "ping" the Proca server. We do not store the IP of any requests, but you might still want to avoid this to happen.

There is a solution where you can download the signature count data every minute, and configure the petition widget to fetch it from your server. 
The mechanism is simple:

1. Run a script as cron job every minute.
2. The cron job fetches JSON with data for a particular widget name.
3. The JSON is stored in a file that is available on your website (eg. in `uploads` of your Wordpress).
4. Configure the widget to use URL of the JSON.
5. If you _run the widget on different domain then you store the json_, You need
   to configure [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
   on your server so it allows fetching the file from a website with different
   domain. [Guide here.](https://www.keycdn.com/support/cors)


We provide a bash script to help with that: [get-action-page.sh](https://raw.githubusercontent.com/fixthestatusquo/proca-backend/main/utils/get-action-page.sh)

1. Download it to server
2. make it executable (`chmod +x get-action-page.sh`)
3. Decide where the location of JSON file (eg `/home/wordpress/wp-content/uploads/petition.json`)  
4. Make sure you know the name of the widget (it looks like `domain.name/someidentifier`)
4. Fetch data to see if it works:
```
./get-action-page.sh -n greenplanet.org/trees -o /home/wordpress/wp-content/uploads/petition.json -w
```
5. You can add `-w` parameter so the file ownership is changed to www-data (the user usually running the http server)
6. If the file is created without error, and it has proper content (see `cat /home/wordpress/wp-content/uploads/petition.json`), run it again with `-c` to create a cronjob:
```
./get-action-page.sh -n greenplanet.org/trees -o /home/wordpress/wp-content/uploads/petition.json -w -c
```

## Sync the number of signatures to proca campaign

You can add the number of signatures you have collected in another system with a campaign running on Proca, by setting *extra supporters* count of one of the campaign's widgets/action pages. 
The *extra supporters* from all widgets/action pages of a campaign are added to the total deduplicated number of signatures collected on Proca.

To do this:
1. Know your org name (acronym), user email and secret access token
1. Have a widget/action page participating in the campaign.
2. Know the name of the action page eg. ourplanet.org/oceans (or it's numerical ID, eg. 123)
3. Install command line too: proca-cli by running `sudo npm install -g @proca/cli` or for local user `npm install @proca/cli`. Former is recommended.
4. To update the *extra supporters* of an action page with ID 123 to 10000 run:
```
proca-cli page:update -u your@email.com -p YOUR_TOKEN -o org_name -e 10000 -i 123 
```
5. To update the *extra supporters* of an action page with a NAME ourplanet.org/oceans run:
```
proca-cli page:update -u your@email.com -p YOUR_TOKEN -o org_name -e 10000 -i $(proca-cli page -P -n ourplanet.org/oceans |head -1 |cut -f 1 -d ' ') 
```


