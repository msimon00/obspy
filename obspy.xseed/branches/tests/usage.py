# -*- coding: utf-8 -*-
"""
Simple usage example.
"""

from lxml import etree
from obspy.xseed import Parser
import StringIO


# parse SEED file
parser = Parser(strict=False, debug=False)
parser.read('data/dataless/bw/dataless.seed.BW_ZUGS')
xml_doc = parser.getXSEED()

# read schema
xmlschema_doc = etree.parse('xml-seed-1.1.xsd')
xmlschema = etree.XMLSchema(xmlschema_doc)

# validate XML document with schema
parsed_xml_doc = etree.parse(StringIO.StringIO(xml_doc))
xmlschema.assertValid(parsed_xml_doc)

# write XML results to file system
fp = open('output/dataless.seed.BW_ZUGS.xml', 'w')
fp.write(xml_doc)
fp.close()