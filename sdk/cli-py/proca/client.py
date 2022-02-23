#!/usr/bin/env python3

"""
GraphQL API client code.

"""

from urllib.parse import urlparse
from urllib.request import Request, urlopen, HTTPError
from gql import Client
from gql.transport.aiohttp import AIOHTTPTransport
from gql.transport.phoenix_channel_websockets import PhoenixChannelWebsocketsTransport
from aiohttp.helpers import BasicAuth


class Endpoint:
    """Proca API endpoint.

    Proca offers GraphQL over HTTP and over WebSocket. These listen on different
    endpoints, and have a different auth mechanisms (WS does not support
    BasicAuth)

    This class is doing some guesswork:
    - If only domain given, it will append /api
    - It will replace xxx/api by xxx/socket/websocket to find the socket url (if not given)
    - It will match the TLS protocol between http and ws

    props:

    http_url
    ws_url
    ws_given - if a special socket url was given (and not inferred from http_url)

    """
    def __init__(self, url, socket=None):
        self.ws_given = socket is not None

        # if got just domain, append /api
        parsed = urlparse(url)
        if parsed.path == '' or parsed.path == '/':
            url = parsed.scheme + "://" + parsed.netloc + "/api"

        # figure out WS path
        parsed = urlparse(url)
        if socket is None and parsed.path.endswith("/api"):
            wss = {"http": "ws", "https": "wss"}
            #         https->wss                    domain    ->    path except /api -> ws path
            socket = wss[parsed.scheme] + "://" + parsed.netloc +  parsed.path[0:-4] + "/socket/websocket"

        # Add necessary phoenix path to select WS as channel transport
        if socket is not None and not socket.endswith("/websocket"):
            socket += "/websocket"

        self.http_url = url
        self.ws_url = socket

    def check_http_url(self):
        """
        Check if OPTIONS on url does not return error (4xx 5xx)
        """
        try:
            urlopen(Request(self.http_url, method="OPTIONS"))
            return True
        except HTTPError:
            return False



    @staticmethod
    def wrap(endpoint):
        "Convert url to endpoint if isn't already"

        if isinstance(endpoint, str):
            return Endpoint(endpoint)
        if isinstance(endpoint, Endpoint):
            return endpoint
        raise RuntimeError(f"Endpoint must be either a proca.client.Endpoint or url string, given: {endpoint}")


def http(endpoint, auth=None):
    """
    Return a HTTP client given endpoint and authentication.
    authentication can be a dict with {user: .. password:..}, or {token: } (not yet implemented)
    """
    if auth and 'user' in auth and 'password' in auth:
        auth = BasicAuth(auth['user'], auth['password'])

    transport = AIOHTTPTransport(url=endpoint.http_url, auth=auth)
    client = Client(transport=transport)

    return client

def ws(endpoint, _auth=None):
    """
    Return a WebSocket client
    auth param is currently unused
    """
    transport = PhoenixChannelWebsocketsTransport(url=endpoint.ws_url)
    client = Client(transport=transport)

    return client
