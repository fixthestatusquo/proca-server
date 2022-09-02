// Require the framework and instantiate it
const fastify = require("fastify")({ logger: true });
const trust = require("./client.ts");
const lookup = (email) => {
  // do the lookup
  return { hello: email };
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
  async (request, reply) => {
    // we can use the `request.body` object to get the data sent by the client
    reply
      .code(200)
      .header("Content-Type", "application/json; charset=utf-8")
      .send(lookup(request.body.email));
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
  handler: async (request, reply) => {
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
