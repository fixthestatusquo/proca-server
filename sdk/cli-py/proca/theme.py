#!/usr/bin/env python3


from termcolor import colored

gradient = ["yellow", "red", "magenta", "blue", "cyan", 'white']

y = lambda txt: colored(txt, color='yellow')
Y = lambda txt: colored(txt, color='yellow', attrs=['bold'])
r = lambda txt: colored(txt, color='red')
R = lambda txt: colored(txt, color='red', attrs=['bold'])
m = lambda txt: colored(txt, color='magenta')
M = lambda txt: colored(txt, color='magenta', attrs=['bold'])
b = lambda txt: colored(txt, color='blue')
B = lambda txt: colored(txt, color='blue', attrs=['bold'])
c = lambda txt: colored(txt, color='cyan')
C = lambda txt: colored(txt, color='cyan', attrs=['bold'])
w = lambda txt: colored(txt, color='white')
W = lambda txt: colored(txt, color='white', attrs=['bold'])

def cc(cfun, text):
    if len(text) > 0:
        return cfun(colored(text[0], attrs=['bold'])) + cfun(text[1:])
    else:
        return text

def rainbow(text):

    parts = text.split('|')
    out = []

    for i, p in enumerate(parts):
        attrs = []
        if len(p) > 0 and p[0] == '!':
            attrs = ['bold']
            p = p[1:]
        out.append(colored(p, color=gradient[i % 5], attrs=attrs))

    return ' '.join(out)
