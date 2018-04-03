__author__ = 'tonycastronova'
__AdapedBy__ = 'AdelAbdallah'

import os, sys
from os.path import join, dirname, basename
import base
import translator
import xml.etree.ElementTree as et
from optparse import OptionParser

input_file = 'WaMDaMMay2_2017.xml'
use_schemas = True
default_schema = 'WaMDaMMay2_2017'

def parse_xml(input_file):
    # parse the dbwrench file
    try:

        sys.stdout.write('> Parsing XML...')

        tree = et.parse(input_file)
        root = tree.getroot()

        table_output = ''

        ddl_objs = []

        # find all of the schemas
        schemas = root.findall('Sch')


        if not use_schemas:
            sch_obj = base.Schema(name=default_schema)

        for schema in schemas:

            schemaname = schema.attrib['nm']
            schemacomment = schema.attrib['Cm']

            if use_schemas:
                # create schema object
                sch_obj = base.Schema(name=schemaname)

            # get all tables in schema
            tables = schema.findall('Tbl')


            for table in tables:
                tablename = table.attrib['nm']

                # get the primary key
                pk = table.find('Pk')

                # if pk is none catching
                if pk == None:
                    raise Exception('There is no primary key in ' + tablename +' Table')

                pk_col_name = pk.attrib['ClNs']

                # create table object
                tbl_obj = base.Table(name=tablename, pk=pk)

                # get the columns for this table
                cols = table.findall('Cl')

                for col in cols:
                    att = col.attrib
                    att.update(col.find('DT').attrib)


                    pkey = 1 if att['nm'] == pk_col_name else 0
                    # add column instance to table obj
                    tbl_obj.add_column(base.Column(name=att['nm'], datatype=att['ds'], primarykey = pkey, autoincrement=att['au'],
                                                   length=att['ln'] if att['ln'] != 'null' else None,
                                              scale=att['sc'], unsigned=att['un'], id=att['id'], nullable=att['nu'],default=att['df']))


                # add foriegn keys to table
                fks = table.findall('Fk')
                for fk in fks:
                    # get parent table
                    p = fk.find('PrTb')
                    if p == None:
                        raise Exception('There is no PrTb in ' + tablename +' Table')

                    # get child table
                    c = fk.find('CdTb')
                    if c == None:
                        raise Exception('There is no CdTb in ' + tablename +' Table')

                    # get relation
                    r = fk.find('ClPr')
                    if r == None:
                        raise Exception('There is no ClPr in ' + tablename +' Table')

                    foreignKey = base.ForeignKey(name=fk.attrib['nm'],
                                                 parentSch=p.attrib['sch'], parentTbl=p.attrib['nm'], parentCol=r.attrib['prCl'],
                                                 childSch=c.attrib['sch'], childTbl=c.attrib['nm'], childCol=r.attrib['cdCl'] )
                    tbl_obj.add_foreignkey(foreignKey)

                # add table object to the schema object
                sch_obj.add_table(tbl_obj)

            # store the schema object
            ddl_objs.append(sch_obj)

        return ddl_objs

    except Exception, e:
        raise Exception('Parsing XML Error: ' + e.message)

def BUILD_MSSSQL_DDL(opts, ddl_objs, use_schemas):
    #---------------------------------#
    #-------- Write MsSQL DDL --------#
    #---------------------------------#
    try:
        sys.stdout.write('> Building MsSQL DDL...')
        extension = opts.mms
        if (extension[len(extension)-4:] != ".sql"):
            extension = extension + ".sql"
        outdir = os.path.join(os.path.abspath(opts.output), extension)
        with open(outdir, 'w') as f:
            f.write(translator.MSSQL(opts, ddl_objs).build_ddl())
        sys.stdout.write('done\n')
    except Exception, e:
        raise  Exception('Building MsSQL DDL Error: ' + e.message)

def BUILD_POSTGRES_DDL(opts, ddl_objs, use_schemas):
    #--------------------------------------#
    #-------- Write PostgreSQL DDL --------#
    #--------------------------------------#
    try:
        sys.stdout.write('> Building PostgreSQL DDL...')
        extension = opts.postgres
        if (extension[len(extension)-4:] != ".sql"):
            extension = extension + ".sql"
        outdir = os.path.join(os.path.abspath(opts.output), extension)
        with open(outdir, 'w') as f:
            f.write(translator.POSTGRESQL(opts, ddl_objs).build_ddl())
        sys.stdout.write('done\n')
    except Exception, e:
        raise Exception('Building PostgreSQL DDL Error: ' + e.message)

def BUILD_MYSQL_DDL(opts, ddl_objs, use_schemas):
    #---------------------------------#
    #-------- Write MySQL DDL --------#
    #---------------------------------#
    try:
        sys.stdout.write('> Building MySQL DDL...')
        extension = opts.mysql
        if (extension[len(extension)-4:] != ".sql"):
            extension = extension + ".sql"
        outdir = os.path.join(os.path.abspath(opts.output), extension)
        with open(outdir, 'w') as f:
            f.write(translator.MYSQL(opts, ddl_objs).build_ddl())
        sys.stdout.write('done\n')
    except Exception, e:
        raise Exception('Building MySQL DDL Error: ' + e.message)
def BUILD_SQLITE_DDL(opts, ddl_objs, use_schemas):
    #----------------------------------#
    #-------- Write SQLite DDL --------#
    #----------------------------------#
    try:
        sys.stdout.write('> Building SQLite DDL...')
        extension = opts.sqlite
        if (extension[len(extension)-4:] != ".sql"):
            extension = extension + ".sql"
        outdir = os.path.join(os.path.abspath(opts.output), extension)
        with open(outdir, 'w') as f:
            f.write(translator.SQLITE(opts, ddl_objs).build_ddl())
        sys.stdout.write('done\n')
    except Exception, e:
        raise Exception('Building SQLite DDL Error: ' + e.message)
def BUILD_ALL(opts, ddl_objs, use_schemas):

    if opts.mms != None and opts.mms != "":
        BUILD_MSSSQL_DDL(opts, ddl_objs, use_schemas)
    if opts.postgres != None and opts.postgres != "":
        BUILD_POSTGRES_DDL(opts, ddl_objs, use_schemas)
    if opts.mysql != None and opts.mysql != "":
        BUILD_MYSQL_DDL(opts, ddl_objs, use_schemas)
    if opts.sqlite != None and opts.sqlite != "":
        BUILD_SQLITE_DDL(opts, ddl_objs, use_schemas)


print 'done'


def parse_args(arg):
    try:
        # check if input file exists
        if not os.path.exists(arg.xml):
            print '> could not find [XML] path: %s'%arg.xml
            return

        # parse XML

        objs = parse_xml(arg.xml)
        sys.stdout.write('done\n')

        # build DDLs
        if arg.database.lower() == 'mssql': BUILD_MSSSQL_DDL(arg, objs, use_schemas)
        elif arg.database.lower() == 'mysql': BUILD_MYSQL_DDL(arg, objs, use_schemas)
        elif arg.database.lower() == 'postgresql': BUILD_POSTGRES_DDL(arg, objs, use_schemas)
        elif arg.database.lower() == 'sqlite': BUILD_SQLITE_DDL(arg, objs, use_schemas)
        elif arg.database.lower() == 'all': BUILD_ALL(arg, objs, use_schemas)
        else: print '> error in input arguments %s %s %s' %(arg.xml,arg.database,use_schemas)
    except Exception, e:
        raise Exception(e.message)


def main(argv):
    print '|---------------------------------|'
    print '|          Welcome to the         |'
    print '|     WaM-DaM DDL Building Tool (Adapted from the ODM Tool)   |'
    print '|---------------------------------|'
    print '   Warning: Use at your own risk!  '
    print '\nPlease enter a command or type "-h, --help" for a list of commands'

    arg = None
    input_file = argv['inputFile']

    usage = "Usage: %s [options]" % basename(__file__).split('.')[0]

    parser = OptionParser(usage = usage )
    parser.add_option('-u','--use-schemas', help='Indicates that schemas should be used when building the DDL', default=False,action = 'store_true')
    parser.add_option('-d','--database', help='Type of database to generate the DDL for, (e.g. mssql, mysql, postgresql, sqlite, all)',default='all')
    parser.add_option('-x', '--xml', help='A DbWrench XML file path',default=argv['inputFile'])
    parser.add_option('-c','--maintain-case', help='Maintain CamelCasing in DDL',default=False,action = 'store_true')
    parser.add_option('-o','--output', help='The output directory for the DDL script',default=argv['outDir'])
    parser.add_option('-g','--global-schema', help='Specifies the name of a single (global) schema to be used',default='WaMDaM')
    parser.add_option('--sqlite','--sqlitename', help='Sqlite Name',default=argv['sqlite'])
    parser.add_option('--mysql','--mysqlname', help='MySql Name',default=argv['mysql'])
    parser.add_option('--mms','--mmsname', help='Description of your schema',default=argv['mmsql'])
    parser.add_option('--postgres','--postgresname', help='Description of your schema',default=argv['postgres'])
    parser.add_option('--description','--description', help='Description of your schema',default=argv['schema'])


    # while True:

        # # get the users command
        # arg = raw_input("> ").split(' ')

    try:

        (opts,cmd) = parser.parse_args(arg)

        # if arg[0] =='exit' or arg[0] == 'quit':
        #     break

        # if cmd[0] == 'build_ddl':

        # make sure XML path is given
        if opts.xml is None:
            print '> [Error] XML file path not given'

        else:

            # make output directory
            if not os.path.exists(opts.output):
                os.makedirs(opts.output)

            print '\n' + 50*'-'
            print '> [SETTING] Build DDL for             : %s'%opts.database
            print '> [SETTING] Use Schemas               : %s'%opts.use_schemas
            print '> [SETTING] Global Schema Name        : %s'%opts.global_schema
            print '> [SETTING] Maintain Case Sensitivity : %s'%opts.maintain_case
            print '> [SETTING] Output Directory          : %s'%opts.output
            print 50*'-' + '\n'

            parse_args(opts)

    except Exception, e:
        print e
        raise Exception(e.message)

        #print '> Operation Completed Successfully.'


# if __name__ == '__main__':
#     main(sys.argv[1:])
