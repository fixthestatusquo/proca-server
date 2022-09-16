FROM node:14-alpine

WORKDIR /app
COPY bin/proca-cli /usr/local/bin/proca-cli
COPY node_modules /usr/local/lib/node_modules 
RUN rm -f /usr/local/lib/node_modules/@proca/api && npm i -g @proca/api cross-fetch @sentry/node
COPY dist /usr/local/dist
env NODE_PATH /usr/local/lib/node_modules

