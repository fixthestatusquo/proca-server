// Require the framework and instantiate it
const fastify = require('fastify')({ logger: true })

const lookup = email => { // do the lookup
  return { hello: email }
}

fastify.route({
  method: 'GET',
  url: '/lookup-trust',
  handler: async (request, reply) => {
    return lookup (request.query.email);
  }
})

// Run the server!
const start = async () => {
  try {
    await fastify.listen({ port: 3000 })
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}
start()


