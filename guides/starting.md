# minimal setup

now that your dev server is running on http://localhost:4000, you need to setup the proca-cli to talk with it and start creating campaigns. *We recommend you to use "locale" as the name of the environment, it will make it easier later to work both with the locale and production/remote servers, but you're free to choose another name (or skip it, it defaults to "default")*

You need two extra components, the proca-cli (for the "admin" instructions) and the widget builder (to see the result of your configurations and let you have the frontend). the last one isn't stricly needed, but we'll assume it will be installed under /var/www/proca in the rest of the document

### the widget builder

    $git clone https://github.com/fixthestatusquo/proca /var/www/proca

### proca-cli

    $ npm install -g proca
    # create an authentication token, it will ask for the password it generated when you set up your server
    $ proca user token --url=http://localhost:4000 <your admin email>
    # copy the generated token (API-xxx)
    $ proca config init --url=http://localhost:4000 --env=locale  --folder=/var/www/proca/config.locale --token=<your API token>
    # you should be ready


check your config, you can run the config init again if you want to update any param at any time

    $ proca config server
    $ proca config user
    

create an organisation, a campaign, a widget and an action

    $ proca org add --name=test-org  --env=locale
    $ proca campaign add --org=test-org  --name=test-campaign  --env=locale
    $ proca widget add --org=test-org --campaign=test-campaign --lang=en --name=test-campaign/en  --env=locale
    $ proca action add --testing=false --name=test-campaign/en --email=supporter@example.org --firstname=Jane  --env=locale

back to the widget builder, let's see that widget we created
    
    $ cd /var/www/proca
    $ npm run cli-init
    $ proca widget pull --name=test-campaign/en
    $ proca widget serve --name=test-campaign/en
