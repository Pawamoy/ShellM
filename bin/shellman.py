#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys

SHELLMAN_VERSION = '1.0'

# tag: (occurrences, lines)
TAGS = {
    'author': ('+', 1),
    'brief': ('+', 1),  # script / function brief
    'bug': ('+', '+'),
    'caveat': ('+', '+'),
    'copyright': (1, '+'),
    'date': (1, 1),
    'desc': (1, '+'),  # script description
    'env': ('+', '+'),
    'error': ('+', '+'),
    'export': ('+', 1),
    'example': ('+', '+'),
    'exit': ('+', '+'),  # script exit code
    'file': ('+', '+'),
    'fn': ('+', 1),  # prototype / usage of a function
    'history': (1, '+'),
    'host': ('+', 1),
    'license': (1, '+'),
    'note': ('+', '+'),
    'option': ('+', '+'),  # script option
    'param': ('+', 1),  # function argument / parameter
    'pre': ('+', 1),
    'require': (1, 1),
    'return': ('+', 1),  # function return code
    'seealso': ('+', 1),
    'stderr': ('+', '+'),
    'stdin': ('+', '+'),
    'stdout': ('+', '+'),
    'usage': ('+', '+'),  # script usage
    'version': (1, 1)
}

MAN_SECTIONS_ORDER = [
    'NAME',
    'SYNOPSIS',
    'DESCRIPTION',
    'OPTIONS',
    'ENVIRONMENT VARIABLES',
    'FILES',
    'EXAMPLES',
    'EXIT STATUS',
    'ERRORS',
    'BUGS',
    'CAVEATS',
    'AUTHORS',
    'COPYRIGHT',
    'LICENSE',
    'HISTORY',
    'NOTES',
    'SEE ALSO',
]

TEXT_SECTIONS_ORDER = [
    'SYNOPSIS',
    'DESCRIPTION',
    'OPTIONS',
    'EXAMPLES'
]


class Doc(object):
    def __init__(self, file):
        self.file = file
        self.doc = {k: None for k in TAGS.keys()}
        self.doc['_file'] = os.path.basename(self.file)

    @staticmethod
    def tag_value(line):
        line = line.lstrip('#')
        first_char = line.lstrip(' ')[0]
        if first_char in '@\\':
            words = line.lstrip(' ').split(' ')
            return words[0][1:], ' '.join(words[1:])

        if len(line) > 1:
            if line[0] == ' ':
                return None, line[1:]
        return None, line

    def update_value(self, tag, value, end=False):
        if TAGS[tag][0] == '+':
            if TAGS[tag][1] == '+':
                if self.doc[tag] is None:
                    self.doc[tag] = [[]]
                elif end:
                    self.doc[tag].append([])
                self.doc[tag][-1].append(value)
                return True
            if self.doc[tag] is None:
                self.doc[tag] = []
            self.doc[tag].append(value.rstrip('\n'))
            return False
        if TAGS[tag][1] == '+':
            if self.doc[tag] is None:
                self.doc[tag] = []
            self.doc[tag].append(value)
            return True
        self.doc[tag] = value.rstrip('\n')
        return False

    def read(self):
        current_tag = None
        in_tag = False
        with open(self.file) as f:
            for line in f:
                line = line.lstrip(' \t')
                if line == '\n':
                    current_tag = None
                    in_tag = False
                elif re.search(r'^##', line):
                    tag, value = Doc.tag_value(line)
                    if tag is not None:
                        if tag not in TAGS.keys():
                            continue  # ignore invalid tags
                        current_tag = tag
                        in_tag = self.update_value(
                            current_tag, value, end=True)
                    else:
                        if in_tag:
                            in_tag = self.update_value(current_tag, value)
                        else:
                            pass  # doc without tag, ignored
        return self.doc


class Base(object):
    def __init__(self, doc, order):
        self.doc = doc
        self.order = order
        self.render = {
            'AUTHORS': self.get_render('authors'),
            'BUGS': self.get_render('bugs'),
            'CAVEATS': self.get_render('caveats'),
            'COPYRIGHT': self.get_render('copyright'),
            'DATE': self.get_render('date'),
            'DESCRIPTION': self.get_render('description'),
            'ENVIRONMENT VARIABLES': self.get_render('environment_variables'),
            # 'ERR': self.get_render('err'),
            'ERRORS': self.get_render('errors'),
            'EXAMPLES': self.get_render('examples'),
            # 'EXPORT': self.get_render('export'),
            'EXIT STATUS': self.get_render('exit_status'),
            'FILES': self.get_render('files'),
            'FUNCTIONS': self.get_render('functions'),
            'HISTORY': self.get_render('history'),
            # 'HOST': self.get_render('host'),
            # 'IN': self.get_render('in'),
            'LICENSE': self.get_render('license'),
            'NAME': self.get_render('name'),
            'NOTES': self.get_render('notes'),
            'OPTIONS': self.get_render('options'),
            # 'OUT': self.get_render('out'),
            # 'PARAM': self.get_render('param'),
            # 'PRE': self.get_render('pre'),
            'REQUIRE': self.get_render('require'),
            # 'RETURN': self.get_render('return'),
            'SEE ALSO': self.get_render('see_also'),
            'SYNOPSIS': self.get_render('usage'),
            'USAGE': self.get_render('usage'),
            'VERSION': self.get_render('version')
        }

    def get_render(self, section):
        attr = 'render_%s' % section
        if not hasattr(self, attr):
            return lambda: None
        return getattr(self, attr)

    def write(self):
        self.write_init()
        for section in self.order:
            self.render[section](section)

    def write_init(self):
        pass


class Man(Base):
    def esc(self, string):
        if string:
            return string.replace('-', '\\-').replace("'", "\\(cq")
        return string

    def write_init(self):
        print('.if n.ad l')
        print('.nh')
        print('.TH %s 1 "%s" "Shellman %s" "User Commands"' % (
            self.doc['_file'], self.esc(self.doc['date']) or '',
            SHELLMAN_VERSION))

    def render_single_many(self, title, value):
        if value:
            print('.SH "%s"' % title)
            print('%s' % self.esc(''.join(value)))

    def render_multi_many(self, title, value):
        if value:
            print('.SH "%s"' % title)
            for v in value:
                print('.IP "\\fB%s\\fR" 4' % v[0].rstrip('\n'))
                print(self.esc(''.join(v[1:])).rstrip('\n'))

    def render_multi_many_no_head(self, title, value):
        if value:
            print('.SH "%s"' % title)
            for v in value:
                print('%s' % self.esc(''.join(v)))

    def render_authors(self, title):
        if self.doc['author']:
            print('.SH "%s"' % title)
            for author in self.doc['author']:
                print('.br')
                print(author)

    def render_bugs(self, title):
        self.render_multi_many_no_head(title, self.doc['bug'])

    def render_caveats(self, title):
        self.render_multi_many_no_head(title, self.doc['caveat'])

    def render_copyright(self, title):
        self.render_single_many(title, self.doc['copyright'])

    def render_date(self, title):
        pass

    def render_description(self, title):
        self.render_single_many(title, self.doc['desc'])

    def render_environment_variables(self, title):
        self.render_multi_many(title, self.doc['env'])

    def render_err(self, title):
        pass

    def render_errors(self, title):
        self.render_multi_many_no_head(title, self.doc['error'])

    def render_examples(self, title):
        self.render_multi_many(title, self.doc['example'])

    def render_exit_status(self, title):
        self.render_multi_many(title, self.doc['exit'])

    def render_files(self, title):
        self.render_multi_many(title, self.doc['file'])

    def render_functions(self, title):
        pass

    def render_history(self, title):
        self.render_single_many(title, self.doc['history'])

    def render_host(self, title):
        pass

    def render_in(self, title):
        pass

    def render_license(self, title):
        self.render_single_many(title, self.doc['license'])

    def render_name(self, title):
        if self.doc['brief']:
            print('.SH "%s"' % title)
            print('%s \- %s' % (self.doc['_file'],
                                self.esc(self.doc['brief'][0])))

    def render_notes(self, title):
        self.render_multi_many_no_head(title, self.doc['note'])

    def render_options(self, title):
        if not self.doc['option']:
            return
        print('.SH "%s"' % title)
        for option in self.doc['option']:
            print('.IP "\\fB%s\\fR" 4' % option[0]
                  .rstrip('\n')
                  .replace(',', '\\fR,\\fB'))
            sys.stdout.write(''.join(option[1:]))

    def render_out(self, title):
        pass

    def render_param(self, title):
        pass

    def render_pre(self, title):
        pass

    def render_require(self, title):
        pass

    def render_return(self, title):
        pass

    def render_see_also(self, title):
        pass

    def render_usage(self, title):
        if not self.doc['usage']:
            return
        print('.SH "%s"' % title)
        rep_reg_opt = re.compile(r'(--?[a-z0-9-]+=?)')
        rep_reg_arg = re.compile(r'([A-Z]+)')
        for usage in self.doc['usage']:
            syn = ''.join(usage)
            syn = rep_reg_arg.sub(r'\\fI\1\\fR', syn)  # order is important!
            syn = rep_reg_opt.sub(r'\\fB\1\\fR', syn)
            print('.br')
            sys.stdout.write('\\fB%s\\fR %s' % (self.doc['_file'], self.esc(syn)))

    def render_version(self, title):
        pass


class Text(Base):
    def render_single_many(self, title, value):
        if value:
            print(title)
            print('  %s' % ''.join(value))

    def render_multi_many(self, title, value):
        if value:
            print(title)
            for v in value:
                print('  %s' % v[0].rstrip('\n'))
                if len(v) > 1:
                    print('    %s' % ''.join(v[1:]))

    def render_multi_many_no_head(self, title, value):
        if value:
            print(title)
            for v in value:
                print('  %s' % v)

    def render_authors(self, title):
        print('Authors:')
        for v in self.doc['author']:
            print('  %s' % v)

    def render_bugs(self, title):
        self.render_multi_many_no_head('Bugs:', self.doc['bug'])

    def render_caveats(self, title):
        self.render_multi_many_no_head('Caveats:', self.doc['caveat'])

    def render_copyright(self, title):
        self.render_single_many('Copyright:', self.doc['copyright'])

    def render_date(self, title):
        print('Date: %s' % self.doc['date'])

    def render_description(self, title):
        if self.doc['desc']:
            print('%s' % ''.join(self.doc['desc']))

    def render_environment_variables(self, title):
        self.render_multi_many('Environment variables:', self.doc['env'])

    def render_err(self, title):
        pass

    def render_errors(self, title):
        self.render_multi_many_no_head('Errors:', self.doc['error'])

    def render_examples(self, title):
        self.render_multi_many('Examples:', self.doc['example'])

    def render_exit_status(self, title):
        self.render_multi_many('Exit status:', self.doc['exit'])

    def render_files(self, title):
        self.render_multi_many('Files:', self.doc['file'])

    def render_functions(self, title):
        pass

    def render_history(self, title):
        self.render_single_many('History:', self.doc['history'])

    def render_host(self, title):
        pass

    def render_in(self, title):
        pass

    def render_license(self, title):
        self.render_single_many('License:', self.doc['license'])

    def render_name(self, title):
        print('%s - %s' % (self.doc['_file'], self.doc['brief'][0]))

    def render_notes(self, title):
        self.render_multi_many_no_head('Notes:', self.doc['note'])

    def render_options(self, title):
        self.render_multi_many('Options:', self.doc['option'])

    def render_out(self, title):
        pass

    def render_param(self, title):
        pass

    def render_pre(self, title):
        pass

    def render_require(self, title):
        pass

    def render_return(self, title):
        pass

    def render_see_also(self, title):
        pass

    def render_usage(self, title):
        if self.doc['usage']:
            print('Usage: %s' % ''.join(self.doc['usage'][0]))
            for v in self.doc['usage'][1:]:
                print('       %s %s' % (self.doc['_file'], ''.join(v)))

    def render_version(self, title):
        print('Version: %s' % self.doc['version'])


def main():
    file = sys.argv[1]
    doc = Doc(file).read()
    fmt = os.environ.get('SHELLMAN_FORMAT', 'text')
    if fmt == 'text':
        out = Text(doc, TEXT_SECTIONS_ORDER)
    elif fmt == 'man':
        out = Man(doc, MAN_SECTIONS_ORDER)
    else:
        raise ValueError('Env var SHELLMAN_FORMAT incorrect')
    out.write()


if __name__ == "__main__":
    sys.exit(main())
