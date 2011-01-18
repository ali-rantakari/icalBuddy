

def wrap_ansi(s, start_code, end_code):
    return '\x1b[%im%s\x1b[%im' % (start_code, s, end_code)


def wrap_ansi_sgr(s, sgr):
    sgr_by_ten = int(sgr / 10.0)
    end_code = 49 if (sgr_by_ten == 4 or sgr_by_ten == 10) else 39
    return wrap_ansi(s, sgr, end_code)


def black(s):
    return wrap_ansi_sgr(s, 30)


def bright_black(s):
    return wrap_ansi_sgr(s, 90)


def red(s):
    return wrap_ansi_sgr(s, 31)


def green(s):
    return wrap_ansi_sgr(s, 32)


def yellow(s):
    return wrap_ansi_sgr(s, 33)


def blue(s):
    return wrap_ansi_sgr(s, 34)


def magenta(s):
    return wrap_ansi_sgr(s, 35)


def cyan(s):
    return wrap_ansi_sgr(s, 36)


def white(s):
    return wrap_ansi_sgr(s, 37)


def bg_black(s):
    return wrap_ansi_sgr(s, 40)


def bg_bright_black(s):
    return wrap_ansi_sgr(s, 100)


def bg_red(s):
    return wrap_ansi_sgr(s, 41)


def bg_green(s):
    return wrap_ansi_sgr(s, 42)


def bg_yellow(s):
    return wrap_ansi_sgr(s, 43)


def bg_blue(s):
    return wrap_ansi_sgr(s, 44)


def bg_magenta(s):
    return wrap_ansi_sgr(s, 45)


def bg_cyan(s):
    return wrap_ansi_sgr(s, 46)


def bg_white(s):
    return wrap_ansi_sgr(s, 47)


def bold(s):
    return wrap_ansi(s, 1, 22)


def under(s):
    return wrap_ansi(s, 4, 24)


# get visible length of string that has ansi escape sequences
def ansi_str_len(s):
    s = unicode(s)
    clean_s = ''
    esc = '\x1b'
    len_s = len(s)
    last = 0
    i = 0
    while i < len_s:
        if s[i] == esc and (i + 1 < len_s) and s[i + 1] == '[':
            clean_s += s[last:i]
            i += 2
            while True:
                if i < len_s:
                    i += 1
                ord_val = ord(s[i])
                if 64 < ord_val and ord_val < 126:
                    i += 1
                    break
            last = i
            continue
        i += 1
    clean_s += s[last:i]
    return len(clean_s)



