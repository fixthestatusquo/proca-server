// Require the framework and instantiate it
const fastify = require('fastify')({ logger: true })
import { lookup } from './client';

const BodyJsonSchema = {
    type: 'object',
    required: ['email'],
    properties: {
      email: { type: 'string' },
    },
}

  const schema = {
    body: BodyJsonSchema,
  }

  fastify.post('/lookup-trust', { schema }, async (request, reply) => {
    // we can use the `request.body` object to get the data sent by the client
    console.log(request.body.email);
    return lookup(request.query.email);
  })

fastify.route({
  method: 'GET',
  url: '/lookup-trust',
    schema: {
    querystring: {
      email: { type: 'string' }
    },
    response: {
      200: {
        type: 'object',
        properities: {
          action: { customFields: { subscribeNewsletter: { type: 'string' } } }
        }

      }
    }
  },
  handler: async (request, reply) => {
    const isSubscribed = { action: { customFields: { subscribeNewsletter: true } } }
    const status = await lookup(request.query.email);
    if (status === 200) {
      isSubscribed.action.customFields.subscribeNewsletter = false
    }
    return isSubscribed;
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


