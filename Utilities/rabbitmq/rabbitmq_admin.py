#!/usr/bin/env python
############################################################################
###
##  File: rabbitmq_admin.py
##  Desc: Provides command line management of a RabbitMQ server
#
#   The contents of this file are subject to the Mozilla Public License
#   Version 1.1 (the "License"); you may not use this file except in
#   compliance with the License. You may obtain a copy of the License at
#   http://www.mozilla.org/MPL/
#
#   Software distributed under the License is distributed on an "AS IS"
#   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#   License for the specific language governing rights and limitations
#   under the License.
#
#   The Original Code is RabbitMQ Management Plugin.
#
#   The Initial Developer of the Original Code is VMware, Inc.
#   Copyright (c) 2007-2010 VMware, Inc.  All rights reserved.

from optparse import OptionParser
import sys
import httplib
import urllib
import base64
import json
import os
import socket

LISTABLE = ['connections', 'channels', 'exchanges', 'queues', 'bindings',
            'users', 'vhosts', 'permissions', 'nodes']

PROMOTE_COLUMNS = ['vhost', 'name', 'type',
                   'source', 'destination', 'destination_type', 'routing_key']

URIS = {
    'exchange':   '/exchanges/{vhost}/{name}',
    'queue':      '/queues/{vhost}/{name}',
    'binding':    '/bindings/{vhost}/e/{source}/{destination_char}/{destination}',
    'binding_del':'/bindings/{vhost}/e/{source}/{destination_char}/{destination}/{properties_key}',
    'vhost':      '/vhosts/{name}',
    'user':       '/users/{name}',
    'permission': '/permissions/{vhost}/{user}'
    }

DECLARABLE = {
    'exchange':   {'mandatory': ['name', 'type'],
                   'optional':  {'auto_delete': 'false', 'durable': 'true'}},
    'queue':      {'mandatory': ['name'],
                   'optional':  {'auto_delete': 'false', 'durable': 'true'}},
    'binding':    {'mandatory': ['source', 'destination_type', 'destination',
                                 'routing_key'],
                   'optional':  {}},
    'vhost':      {'mandatory': ['name'],
                   'optional':  {}},
    'user':       {'mandatory': ['name', 'password', 'administrator'],
                   'optional':  {}},
    'permission': {'mandatory': ['vhost', 'user', 'configure', 'write', 'read'],
                   'optional':  {}}
    }

DELETABLE = {
    'exchange':   {'mandatory': ['name']},
    'queue':      {'mandatory': ['name']},
    'binding':    {'mandatory': ['source', 'destination_type', 'destination',
                                 'properties_key']},
    'vhost':      {'mandatory': ['name']},
    'user':       {'mandatory': ['name']},
    'permission': {'mandatory': ['vhost', 'user']}
    }

CLOSABLE = {
    'connection': {'mandatory': ['name'],
                   'optional':  {},
                   'uri':       '/connections/{name}'}
    }

PURGABLE = {
    'queue': {'mandatory': ['name'],
              'optional':  {},
              'uri':       '/queues/{vhost}/{name}/contents'}
    }

for k in DECLARABLE:
    DECLARABLE[k]['uri'] = URIS[k]

for k in DELETABLE:
    DELETABLE[k]['uri'] = URIS[k]
    DELETABLE[k]['optional'] = {}
DELETABLE['binding']['uri'] = URIS['binding_del']

def make_usage():
    usage = """usage: %prog [options] cmd
where cmd is one of:

"""
    for l in LISTABLE:
        usage += "  list {0}\n".format(l)
    usage += fmt_usage_stanza(DECLARABLE, 'declare')
    usage += fmt_usage_stanza(DELETABLE,  'delete')
    usage += fmt_usage_stanza(CLOSABLE,   'close')
    usage += fmt_usage_stanza(PURGABLE,   'purge')
    usage += """
  export FILE
  import FILE"""
    return usage

def fmt_usage_stanza(root, verb):
    def fmt_args(args):
        res = " ".join(["<{0}>".format(a) for a in args['mandatory']])
        opts = " ".join("{0}=...".format(o) for o in args['optional'].keys())
        if opts != "":
            res += " [{0}]".format(opts)
        return res

    text = "\n"
    for k in root.keys():
        text += "  {0} {1} {2}\n".format(verb, k, fmt_args(root[k]))
    return text

parser = OptionParser(usage=make_usage())

def make_parser():
    parser.add_option("-H", "--host", dest="hostname", default="localhost",
                      help="connect to host HOST [default: %default]",
                      metavar="HOST")
    parser.add_option("-P", "--port", dest="port", default="55672",
                      help="connect to port PORT [default: %default]",
                      metavar="PORT")
    parser.add_option("-V", "--vhost", dest="vhost",
                      help="connect to vhost VHOST [default: all vhosts for list, '/' for declare]",
                      metavar="VHOST")
    parser.add_option("-u", "--username", dest="username", default="guest",
                      help="connect using username USERNAME [default: %default]",
                      metavar="USERNAME")
    parser.add_option("-p", "--password", dest="password", default="guest",
                      help="connect using password PASSWORD [default: %default]",
                      metavar="PASSWORD")
    parser.add_option("-q", "--quiet", action="store_false", dest="verbose",
                      default=True, help="suppress status messages")
    parser.add_option("-f", "--format", dest="format", default="table",
                      help="format for listing commands - one of [" + ", ".join(FORMATS.keys())  + "]  [default: %default]")
    parser.add_option("-d", "--depth", dest="depth", default="1",
                      help="maximum depth to recurse for listing tables [default: %default]")
    parser.add_option("--bash-completion", action="store_true",
                      dest="bash_completion", default=False,
                      help="Print bash completion script")

def assert_usage(expr, error):
    if not expr:
        print "\nERROR: {0}\n".format(error)
        print "{0} --help for help\n".format(os.path.basename(sys.argv[0]))
        sys.exit(1)

def column_sort_key(col):
    if col in PROMOTE_COLUMNS:
        return (1, PROMOTE_COLUMNS.index(col))
    else:
        return (2, col)

def main():
    make_parser()
    (options, args) = parser.parse_args()
    if options.bash_completion:
        print_bash_completion()
        exit(0)
    assert_usage(len(args) > 0, 'Action not specified')
    mgmt = Management(options, args[1:])
    mode = "invoke_" + args[0]
    assert_usage(hasattr(mgmt, mode),
                 'Action {0} not understood'.format(args[0]))
    method = getattr(mgmt, "invoke_%s" % args[0])
    method()

def die(str):
    sys.stderr.write("*** {0}".format(str))
    exit(1)

class Management:
    def __init__(self, options, args):
        self.options = options
        self.args = args

    def get(self, path):
        return self.http("GET", path, "")

    def put(self, path, body):
        return self.http("PUT", path, body)

    def post(self, path, body):
        return self.http("POST", path, body)

    def delete(self, path):
        return self.http("DELETE", path, "")

    def http(self, method, path, body):
        conn = httplib.HTTPConnection(self.options.hostname, self.options.port)
        headers = {"Authorization":
                       "Basic " + base64.b64encode(self.options.username + ":" +
                                                   self.options.password)}
        if body != "":
            headers["Content-Type"] = "application/json"
        try:
            conn.request(method, "/api%s" % path, body, headers)
        except socket.error as e:
            die("Could not connect: {0}".format(e))
        resp = conn.getresponse()
        if resp.status == 400:
            die(json.loads(resp.read())['reason'])
        if resp.status == 401:
            die("Access refused: {0}".format(path))
        if resp.status == 404:
            die("Not found: {0}".format(path))
        if resp.status < 200 or resp.status > 400:
            raise Exception("Received %d %s for path %s\n%s"
                            % (resp.status, resp.reason, path, resp.read()))
        return resp.read()

    def verbose(self, string):
        if self.options.verbose:
            print string

    def get_arg(self):
        assert_usage(len(self.args) == 1, 'Exactly one argument required')
        return self.args[0]

    def invoke_export(self):
        path = self.get_arg()
        config = self.get("/all-configuration")
        with open(path, 'w') as f:
            f.write(config)
        self.verbose("Exported configuration for %s to \"%s\""
                     % (self.options.hostname, path))

    def invoke_import(self):
        path = self.get_arg()
        with open(path, 'r') as f:
            config = f.read()
        self.post("/all-configuration", config)
        self.verbose("Imported configuration for %s from \"%s\""
                     % (self.options.hostname, path))

    def invoke_list(self):
        obj_type = self.get_arg()
        assert_usage(obj_type in LISTABLE,
                     "Don't know how to list {0}".format(obj_type))
        uri = "/%s" % obj_type
        if self.options.vhost:
            uri += "/%s" % urllib.quote_plus(self.options.vhost)
        format_list(self.get(uri), self.options)

    def invoke_declare(self):
        (obj_type, uri, payload) = self.declare_delete_parse(DECLARABLE)
        if obj_type == 'binding':
            self.post(uri, json.dumps(payload))
        else:
            self.put(uri, json.dumps(payload))
        self.verbose("{0} declared".format(obj_type))

    def invoke_delete(self):
        (obj_type, uri, payload) = self.declare_delete_parse(DELETABLE)
        self.delete(uri)
        self.verbose("{0} deleted".format(obj_type))

    def invoke_close(self):
        (obj_type, uri, payload) = self.declare_delete_parse(CLOSABLE)
        self.delete(uri)
        self.verbose("{0} closed".format(obj_type))

    def invoke_purge(self):
        (obj_type, uri, payload) = self.declare_delete_parse(PURGABLE)
        self.delete(uri)
        self.verbose("{0} purged".format(obj_type))

    def declare_delete_parse(self, root):
        assert_usage(len(self.args) > 0, 'Type not specified')
        obj_type = self.args[0]
        assert_usage(obj_type in root,
                     'Type {0} not recognised'.format(obj_type))
        args = self.args[1:]
        mandatory = root[obj_type]['mandatory']
        optional = root[obj_type]['optional']
        args = self.args[1:]
        payload = {}
        for k in optional.keys():
            payload[k] = optional[k]
        for arg in args:
            assert_usage("=" in arg,
                         'Argument "{0}" not in format name=value'.format(arg))
            (name, value) = arg.split("=")
            assert_usage(name in mandatory or name in optional.keys(),
                         'Argument "{0}" not recognised'.format(name))
            payload[name] = value
        for m in mandatory:
            assert_usage(m in payload.keys(),
                         'mandatory argument "{0}" required'.format(m))
        payload['arguments'] = {}
        payload['vhost'] = self.options.vhost or '/'
        uri_args = {}
        for k in payload:
            uri_args[k] = urllib.quote_plus(payload[k])
            if k == 'destination_type':
                uri_args['destination_char'] = payload[k][0]
        uri = root[obj_type]['uri'].format(**uri_args)
        return (obj_type, uri, payload)

def format_list(json_list, options):
    format = options.format
    formatter = None
    if format == "raw_json":
        print json_list
        return
    elif format == "pretty_json":
        enc = json.JSONEncoder(False, False, True, True, True, 2)
        print enc.encode(json.loads(json_list))
        return
    else:
        formatter = FORMATS[format]
    assert_usage(formatter != None,
                 "Format {0} not recognised".format(format))
    formatter_instance = formatter(options)
    formatter_instance.display(json_list)

class Lister:
    def verbose(self, string):
        if self.options.verbose:
            print string

    def display(self, json_list):
        (columns, table) = self.list_to_table(json.loads(json_list),
                                              int(self.options.depth))
        if len(table) > 0:
            self.display_list(columns, table)
        else:
            self.verbose("No items")

    def list_to_table(self, items, max_depth):
        columns = {}
        column_ix = {}
        row = None
        table = []

        def add(prefix, depth, item, fun):
            for key in item:
                column = prefix == '' and key or (prefix + '_' + key)
                if type(item[key]) == dict:
                    if depth < max_depth:
                        add(column, depth + 1, item[key], fun)
                elif type(item[key]) == list:
                    # TODO - ATM this is only applications inside nodes. Not
                    # sure how to handle this sensibly.
                    pass
                else:
                    fun(column, item[key])

        def add_to_columns(col, val):
            columns[col] = True

        def add_to_row(col, val):
            row[column_ix[col]] = str(val)

        for item in items:
            add('', 1, item, add_to_columns)
        columns = columns.keys()
        columns.sort(key=column_sort_key)
        for i in xrange(0, len(columns)):
            column_ix[columns[i]] = i
        for item in items:
            row = len(columns) * ['']
            add('', 1, item, add_to_row)
            table.append(row)

        return (columns, table)

class TSVList(Lister):
    def __init__(self, options):
        self.options = options

    def display_list(self, columns, table):
        head = ""
        for col in columns:
            head += col + "\t"
        self.verbose(head)

        for row in table:
            line = ""
            for cell in row:
                line += cell + "\t"
            print line

class LongList(Lister):
    def __init__(self, options):
        self.options = options

    def display_list(self, columns, table):
        sep = "\n" + "-" * 80 + "\n"
        max_width = 0
        for col in columns:
            max_width = max(max_width, len(col))
        fmt = "{0:>" + str(max_width) + "}: {1}"
        print sep
        for i in xrange(0, len(table)):
            for j in xrange(0, len(columns)):
                print fmt.format(columns[j], table[i][j])
            print sep

class TableList(Lister):
    def __init__(self, options):
        self.options = options

    def display_list(self, columns, table):
        total = [columns]
        total.extend(table)
        self.ascii_table(total)

    def ascii_table(self, rows):
        table = ""
        col_widths = [0] * len(rows[0])
        for i in xrange(0, len(rows[0])):
            for j in xrange(0, len(rows)):
                col_widths[i] = max(col_widths[i], len(rows[j][i]))
        self.ascii_bar(col_widths)
        self.ascii_row(col_widths, rows[0], "^")
        self.ascii_bar(col_widths)
        for row in rows[1:]:
            self.ascii_row(col_widths, row, "<")
        self.ascii_bar(col_widths)

    def ascii_row(self, col_widths, row, align):
        txt = "|"
        for i in xrange(0, len(col_widths)):
            fmt = " {0:" + align + str(col_widths[i]) + "} "
            txt += fmt.format(row[i]) + "|"
        print txt

    def ascii_bar(self, col_widths):
        txt = "+"
        for w in col_widths:
            txt += ("-" * (w + 2)) + "+"
        print txt

class KeyValueList(Lister):
    def __init__(self, options):
        self.options = options

    def display_list(self, columns, table):
        for i in xrange(0, len(table)):
            row = []
            for j in xrange(0, len(columns)):
                row.append("{0}=\"{1}\"".format(columns[j], table[i][j]))
            print " ".join(row)

# TODO handle spaces etc in completable names
class BashList(Lister):
    def __init__(self, options):
        self.options = options

    def display_list(self, columns, table):
        ix = None
        for i in xrange(0, len(columns)):
            if columns[i] == 'name':
                ix = i
        if ix is not None:
            res = []
            for row in table:
                res.append(row[ix])
            print " ".join(res)

FORMATS = {
    'raw_json'    : None, # Special cased
    'pretty_json' : None, # Ditto
    'tsv'         : TSVList,
    'long'        : LongList,
    'table'       : TableList,
    'kvp'         : KeyValueList,
    'bash'        : BashList
}

def print_bash_completion():
    script = """# This is a bash completion script for rabbitmqadmin.
# Redirect it to a file, then source it or copy it to /etc/bash_completion.d
# to get tab completion. rabbitmqadmin must be on your PATH for this to work.
_rabbitmqadmin()
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="list declare delete close purge import export"
    fargs="--help --host --port --vhost --username --password --format --depth"

    case "${prev}" in
	list)
	    COMPREPLY=( $(compgen -W '""" + " ".join(LISTABLE) + """' -- ${cur}) )
            return 0
            ;;
	declare)
	    COMPREPLY=( $(compgen -W '""" + " ".join(DECLARABLE.keys()) + """' -- ${cur}) )
            return 0
            ;;
	delete)
	    COMPREPLY=( $(compgen -W '""" + " ".join(DELETABLE.keys()) + """' -- ${cur}) )
            return 0
            ;;
	close)
	    COMPREPLY=( $(compgen -W '""" + " ".join(CLOSABLE.keys()) + """' -- ${cur}) )
            return 0
            ;;
	purge)
	    COMPREPLY=( $(compgen -W '""" + " ".join(PURGABLE.keys()) + """' -- ${cur}) )
            return 0
            ;;
	export)
	    COMPREPLY=( $(compgen -f ${cur}) )
            return 0
            ;;
	import)
	    COMPREPLY=( $(compgen -f ${cur}) )
            return 0
            ;;
	--host)
	    COMPREPLY=( $(compgen -A hostname ${cur}) )
            return 0
            ;;
	--vhost)
            opts="$(rabbitmqadmin -q -f bash list vhosts)"
	    COMPREPLY=( $(compgen -W "${opts}"  -- ${cur}) )
            return 0
            ;;
	--username)
            opts="$(rabbitmqadmin -q -f bash list users)"
	    COMPREPLY=( $(compgen -W "${opts}"  -- ${cur}) )
            return 0
            ;;
	--format)
	    COMPREPLY=( $(compgen -W \"""" + " ".join(FORMATS.keys()) + """\"  -- ${cur}) )
            return 0
            ;;

"""
    for l in LISTABLE:
        key = l[0:len(l) - 1]
        script += "        " + key + """)
            opts="$(rabbitmqadmin -q -f bash list """ + l + """)"
	    COMPREPLY=( $(compgen -W "${opts}"  -- ${cur}) )
            return 0
            ;;
"""
    script += """        *)
        ;;
    esac

   COMPREPLY=($(compgen -W "${opts} ${fargs}" -- ${cur}))
   return 0
}
complete -F _rabbitmqadmin rabbitmqadmin
"""
    print script

if __name__ == "__main__":
    main()

