#!/usr/bin/env python3


from colored import fg, bg, attr

# blue 63
# violet 141
# magenta 207
# 205
# red 202

gradient = ['royal_blue_1', 'medium_purple_1', 'medium_orchid_1b', 'hot_pink_1a', 'orange_red_1']
gradient.reverse()

# y = lambda txt: colored(txt, color='yellow')
# Y = lambda txt: colored(txt, color='yellow', attrs=['bold'])
# r = lambda txt: colored(txt, color='red')
# R = lambda txt: colored(txt, color='red', attrs=['bold'])
# m = lambda txt: colored(txt, color='magenta')
# M = lambda txt: colored(txt, color='magenta', attrs=['bold'])
# b = lambda txt: colored(txt, color='blue')
# B = lambda txt: colored(txt, color='blue', attrs=['bold'])
# c = lambda txt: colored(txt, color='cyan')
# C = lambda txt: colored(txt, color='cyan', attrs=['bold'])
# w = lambda txt: colored(txt, color='white')
# W = lambda txt: colored(txt, color='white', attrs=['bold'])

def cc(cfun, text):
    if len(text) > 0:
        return cfun(colored(text[0], attrs=['bold'])) + cfun(text[1:])
    else:
        return text

def rainbow(text):

    parts = text.split('|')
    out = []

    for i, p in enumerate(parts):
        col = ''
        if len(p) > 0 and p[0] == '!':
            col = attr('bold')
            p = p[1:]
        col += fg(gradient[i % 5])
        out.append(col + p + attr(0))

    return ' '.join(out)


# Awesome triangle symbols
# https://www.alt-codes.net/triangle-symbols
