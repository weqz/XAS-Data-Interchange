"""
   Xas Data Interchange Format

   Matthew Newville <newville@cars.uchicago.edu>
   last update:  2001-March-06
      
== License:
   To the extent possible, the authors have waived all rights
   granted by copyright law and related laws for the code and
   documentation that make up the XAS Data Library.  While
   information about Authorship may be retained in some files
   for historical reasons, this work is hereby placed in the
   Public Domain.  This work is published from: United States.
   
== Overview:
   The xdi module provides a way to read/write files in the
   XAS Data Interchange format
   
"""
__version__ = '0.1.0'

from . import xdi
XDIFile = xdi.XDIFile
XDIFileException = xdi.XDIFileException

DEFINED_FIELDS = tuple(sorted(xdi.DEFINED_FIELDS.keys()))
COLUMN_NAMES = xdi.COLUMN_NAMES
