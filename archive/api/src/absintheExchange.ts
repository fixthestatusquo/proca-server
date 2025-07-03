import { subscriptionExchange } from '@urql/core'
import { Channel, Socket } from 'phoenix'
import { make, pipe, toObservable } from 'wonka'
import WebSocket from 'ws'


const createAbsintheExchange = (wsUrl: string) => {
    const socket = new Socket(wsUrl, {
  transport: WebSocket as unknown as new (endpoint: string) => object
})

    let absintheChannel : Channel

    const createAbsintheChannel = () : Channel => {
        if (absintheChannel)
            return absintheChannel

        socket.connect()
        absintheChannel = socket.channel('__absinthe__:control')
        absintheChannel.join()
        return absintheChannel
    }


    const absintheExchange = subscriptionExchange({
        forwardSubscription({ query, variables }) {
            let subscriptionChannel: Channel

            const source = make((observer) => {
                const { next } = observer

                createAbsintheChannel().push('doc', { query, variables }).receive('ok', (v) => {
                    const subscriptionId = v.subscriptionId

                    if (subscriptionId) {
                        subscriptionChannel = socket.channel(subscriptionId)
                        subscriptionChannel.on('subscription:data', (value) => {
                            next(value.result)
                        })
                    }
                })

                return () => {
                    subscriptionChannel?.leave()
                }
            })

            return pipe(source, toObservable)
        },
    })

    return absintheExchange;
}

export default createAbsintheExchange;
