// Require the framework and instantiate it
const fastify = require("fastify")({ logger: true });
const trust = require("./client");


const lookup = async (email:string) => {
  // do the lookup
  console.log("email:"+email);
  try { 
    const r= await trust.lookup(email);
    console.log("result",r);
    return r.success; // no idea why I have the string
  } catch (e) {
    console.log(e);
    return false;
  }

};

const lookupSchema = {
  body: {
    type: "object",
        required: ['email'],
    properties: {
      email: { type: "string" },
    },
  },
};

fastify.post(
  "/lookup-trust", // XXX lets just have it at / ? We can always add a path using reverse proxy
  { schema: lookupSchema },
  async (request: any, reply: any) => {
    const result = await trust.lookup(request.body.email);
    let code = 200;
    let details = {};

    switch (result.status) {
      case 200: // found
        code = 200;
        details = {action: {customFields: {isSubscribed: true}}}
        break;
      case 404: // not found
        code = 200;
        details = {};
        break;
      default:
        code = result.code; // failure
        details = {};
    }


    console.log(`Return ${code}:`, details);
    reply
      .code(code)
      .header("Content-Type", "application/json; charset=utf-8")
      .send(details);
  }
);

fastify.route({
  method: "GET",
  url: "/lookup-trust",
  schema: {
    querystring: {
      email: { type: "string" },
    },
    response: {
      200: {
        type: "object",
        properties: {
          hello: { type: "string" },
        },
      },
    },
  },
  handler: async (request:any, reply:any) => {
    return lookup(request.query.email);
  },
});

// Run the server!
const start = async () => {
  try {
    await fastify.listen({ port: process.env.PORT || 3000 });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

module.exports = {start, lookup};
