#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
ObsPy Test Suite Module.

All tests in ObsPy are located in the tests directory of the each specific
module. The __init__.py of the tests directory itself as well as every test
file located in the tests directory has a function called suite, which is
executed using this script. Running the script with the verbose keyword exposes
the names of all available test cases.

Examples
--------
(1) Run all tests::

    python runtests.py

    or

    >>> import obspy.core
    >>> obspy.core.runTests()  # DOCTEST: +SKIP

(2) Verbose output::

    python runtests.py -v

    or

    >>> import obspy.core
    >>> obspy.core.runTests(verbosity=2)"  # DOCTEST: +SKIP

(3) Run tests of module :mod:`obspy.mseed`::

    python runtests.py obspy.mseed.tests.suite 

    or as shortcut::

    python runtests.py mseed

(4) Run a certain test case::

    python runtests.py obspy.core.tests.test_stats.StatsTestCase.test_init

    or

    >>> import obspy.core
    >>> tests = ['obspy.core.tests.test_stats.StatsTestCase.test_init']
    >>> obspy.core.runTests(verbosity=2, tests=tests)  # DOCTEST: +SKIP
"""

from optparse import OptionParser
import os
import sys
import time
import unittest


DEFAULT_MODULES = ['core', 'gse2', 'mseed', 'sac', 'wav', 'signal', 'imaging',
                   'xseed', 'seisan', 'sh']
ALL_MODULES = DEFAULT_MODULES + ['fissures', 'arclink', 'seishub']
DEPENDENCIES = ['numpy', 'scipy', 'matplotlib', 'lxml.etree', '_omnipy']


def _getSuites(verbosity=1, tests=[]):
    """
    The obspy test suite.
    """
    if tests == []:
        names = DEFAULT_MODULES
    else:
        names = []
        # Search for short cuts in tests, if there are no short cuts,
        # names variables is equal to tests variable
        for test in tests:
            if test in ALL_MODULES:
                names.append(test)
    # Construct the test suite from the given names. Modules
    # need not be imported before in this case
    suites = {}
    ut = unittest.TestLoader()
    for name in names:
        module = 'obspy.%s.tests.suite' % name
        suite = []
        try:
            suite.append(ut.loadTestsFromName(module, None))
        except Exception, e:
            if verbosity:
                print e
                print "Cannot import test suite for module obspy.%s" % name
        else:
            suites[name] = ut.suiteClass(suite)
    return suites


def _createReport(ttrs, timetaken, log, server):
    # import additional libraries here to speed up normal tests
    import httplib
    import urllib
    from urlparse import urlparse
    import platform
    from xml.etree import ElementTree as etree
    timestamp = int(time.time())
    result = {'timestamp': timestamp}
    result['timetaken'] = timetaken
    if log:
        try:
            result['install_log'] = open(log, 'r').read()
        except:
            print "Cannot open log file %s" % log
    # get ObsPy module versions
    result['obspy'] = {}
    tests = 0
    errors = 0
    failures = 0
    for module in ALL_MODULES:
        result['obspy'][module] = {}
        try:
            mod = __import__('obspy.' + module, fromlist='obspy')
            result['obspy'][module]['installed'] = mod.__version__
        except:
            result['obspy'][module]['installed'] = ''
        if module not in ttrs:
            continue
        # test results
        ttr = ttrs[module]
        result['obspy'][module]['tested'] = True
        result['obspy'][module]['tests'] = ttr.testsRun
        tests += ttr.testsRun
        result['obspy'][module]['errors'] = {}
        for method, text in ttr.errors:
            result['obspy'][module]['errors'][str(method)] = text
            errors += 1
        result['obspy'][module]['failures'] = {}
        for method, text in ttr.failures:
            result['obspy'][module]['failures'][str(method)] = text
            failures += 1
    # get dependencies
    result['dependencies'] = {}
    for module in DEPENDENCIES:
        temp = module.split('.')
        try:
            mod = __import__(module, fromlist=temp[1:])
            if module == '_omnipy':
                result['dependencies'][module] = mod.coreVersion()
            else:
                result['dependencies'][module] = mod.__version__
        except:
            result['dependencies'][module] = ''
    # get system / environment settings
    result['platform'] = {}
    for func in ['system', 'node', 'release', 'version', 'machine',
                 'processor', 'python_version', 'python_implementation',
                 'python_compiler', 'architecture']:
        try:
            temp = getattr(platform, func)()
            if isinstance(temp, tuple):
                temp = temp[0]
            result['platform'][func] = temp
        except:
            result['platform'][func] = ''
    # test results
    result['tests'] = tests
    result['errors'] = errors
    result['failures'] = failures
    # generate XML document
    def _dict2xml(doc, result):
        for key, value in result.iteritems():
            key = key.split('(')[0].strip()
            if isinstance(value, dict):
                child = etree.SubElement(doc, key)
                _dict2xml(child, value)
            elif value:
                etree.SubElement(doc, key).text = str(value)
            else:
                etree.SubElement(doc, key)
    root = etree.Element("report")
    _dict2xml(root, result)
    xml_doc = etree.tostring(root, "UTF-8")
    print
    # send result to report server
    params = urllib.urlencode({
        'timestamp': timestamp,
        'system': result['platform']['system'],
        'python_version': result['platform']['python_version'],
        'architecture': result['platform']['architecture'],
        'tests': tests,
        'errors': failures + errors,
        'modules': len(ttrs),
        'xml': xml_doc
    })
    headers = {"Content-type": "application/x-www-form-urlencoded",
               "Accept": "text/plain"}
    conn = httplib.HTTPConnection(server)
    conn.request("POST", "/", params, headers)
    # get the response
    response = conn.getresponse()
    # handle redirect
    if response.status == 301:
        o = urlparse(response.msg['location'])
        conn = httplib.HTTPConnection(o.netloc)
        conn.request("POST", o.path, params, headers)
        # get the response
        response = conn.getresponse()
    # handle errors
    if response.status == 200:
        print "Test report has been sent to %s." % (server)
    else:
        print "Error: Could not sent a test report to %s." % (server)
        print response.reason


class _TextTestRunner:
    def __init__(self, stream=sys.stderr, descriptions=1, verbosity=1):
        self.stream = unittest._WritelnDecorator(stream)
        self.descriptions = descriptions
        self.verbosity = verbosity

    def _makeResult(self):
        return unittest._TextTestResult(self.stream, self.descriptions,
                                        self.verbosity)

    def run(self, suites):
        "Run the given test case or test suite."
        startTime = time.time()
        results = {}
        for id, test in suites.iteritems():
            result = self._makeResult()
            test(result)
            results[id] = result
        stopTime = time.time()
        timeTaken = stopTime - startTime
        runs = 0
        faileds = 0
        erroreds = 0
        wasSuccessful = True
        self.stream.writeln()
        for result in results.values():
            failed, errored = map(len, (result.failures, result.errors))
            faileds += failed
            erroreds += errored
            if not result.wasSuccessful():
                wasSuccessful = False
                result.printErrors()
            runs += result.testsRun
        self.stream.writeln(unittest._TextTestResult.separator2)
        self.stream.writeln("Ran %d test%s in %.3fs" %
                            (runs, runs != 1 and "s" or "", timeTaken))
        self.stream.writeln()
        if not wasSuccessful:
            self.stream.write("FAILED (")
            if faileds:
                self.stream.write("failures=%d" % faileds)
            if erroreds:
                if faileds: self.stream.write(", ")
                self.stream.write("errors=%d" % erroreds)
            self.stream.writeln(")")
        else:
            self.stream.writeln("OK")
        return results, timeTaken


def runTests(verbosity=1, tests=[], report=False, log=None,
             server="tests.obspy.org"):
    """
    This function executes ObsPy test suites.

    Parameters
    ----------
    verbosity : [ 0 | 1 | 2 ], optional
        Run tests in verbose mode (0=quiet, 1=normal, 2=verbose, default is 1).
    tests : list of strings, optional
        Test suites to run. If no suite is given all installed tests suites
        will be started (default is a empty list).
        Example ['obspy.core.tests.suite']
    report : boolean, optional
        Submits a test report if enabled (default is False).
    log : string, optional
        Filename of install log file to append to report
    server : string, optional
        Report server URL (default is "tests.obspy.org").
    """
    suites = _getSuites(verbosity, tests)
    ttr, timetaken = _TextTestRunner(verbosity=verbosity).run(suites)
    if report:
        _createReport(ttr, timetaken, log, server)


def main():
    usage = "USAGE: %prog [options] modules\n\n" + \
            "\n".join(__doc__.split("\n")[3:])
    parser = OptionParser(usage.strip())
    parser.add_option("-v", "--verbose", default=False,
                      action="store_true", dest="verbose",
                      help="verbose mode")
    parser.add_option("-q", "--quiet", default=False,
                      action="store_true", dest="quiet",
                      help="quiet mode")
    parser.add_option("-r", "--report", default=False,
                      action="store_true", dest="report",
                      help="submit a test report")
    parser.add_option("-u", "--server", default="tests.obspy.org",
                      type="string", dest="server",
                      help="report server (default is tests.obspy.org)")
    parser.add_option("-l", "--log", default=None,
                      type="string", dest="log",
                      help="append log file to test report")
    (options, _) = parser.parse_args()
    # set correct verbosity level
    if options.verbose:
        verbosity = 2
    elif options.quiet:
        verbosity = 0
    else:
        verbosity = 1
    # check for send report option or environmental settings
    if options.report or 'OBSPY_REPORT' in os.environ.keys():
        report = True
    else:
        report = False
    if 'OBSPY_REPORT_SERVER' in os.environ.keys():
        options.server = os.environ['OBSPY_REPORT_SERVER']
    runTests(verbosity, parser.largs, report, options.log, options.server)


if __name__ == "__main__":
    # It is not possible to add the code of main directly to here.
    # This script is automatically installed with name obspy-runtests by
    # setup.py to the Scripts or bin directory of your Python distribution
    # setup.py needs a function to which it's scripts can be linked.
    main()