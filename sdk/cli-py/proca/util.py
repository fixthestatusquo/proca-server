#!/usr/bin/env python3

from logging import  getLogger, DEBUG, INFO, StreamHandler, Formatter

def configure_log(logger):
    console = StreamHandler()
    console.setFormatter(Formatter("%(message)s"))
    logger.addHandler(console)
    logger.setLevel(INFO)

log = getLogger("proca")
