#!/usr/bin/env python3

from logging import  getLogger, DEBUG, INFO, StreamHandler, Formatter

def configure_log(logger):
    console = StreamHandler()
    console.setFormatter(Formatter("%(message)s"))
    logger.addHandler(console)
    logger.setLevel(INFO)


DATETIME_FORMATS=[
    '%Y-%m-%d',
    '%Y-%m-%dT%H:%M:%SZ',
    '%Y-%m-%dT%H:%M:%S',
    '%Y-%m-%d %H:%M',
    '%Y-%m-%d %H:%M:%S'
]

log = getLogger("proca")
