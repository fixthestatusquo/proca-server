// Require the framework and instantiate it
const fastify = require("fastify")({ logger: true });
const trust = require("./client.ts");


const lookup = async (email:string) => {
  // do the lookup
  console.log("email:"+email);
  try { 
    const r= await trust.lookup(email);
    console.log("result",r);
    return r; // no idea why I have the string
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
  "/lookup-trust",
  { schema: lookupSchema },
  async (request: any, reply: any) => {
    const result = await lookup(request.body.email);
    const code= result === true?200:404;
    console.log("result",result);
    reply
      .code(code)
      .header("Content-Type", "application/json; charset=utf-8")
      .send(result);
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
    await fastify.listen({ port: 3000 });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};
start();
