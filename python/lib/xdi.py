#!/usr/bin/env python
"""
Read/Write XAS Data Interchange Format for Python
"""
import re
import math
import time
try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

PRINTABLES = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n\r\x0b\x0c'

ALLOWED_CRYSTALS = ("Si", "Ge", "Diamond", "YB66",
                    "InSb", "Beryl", "Multilayer")
MATHEXPR = r'(-+)?(ln|exp|sin|asin)?\(?(\$\d)([/\*])*(\$\d)*\)?$'
DATETIME = r'(\d{4})-(\d{1,2})-(\d{1,2})[ T](\d{1,2}):(\d{1,2}):(\d{1,2})$'

MATCH = {'word':       re.compile(r'[a-zA-Z0-9_]+$').match,
         'properword': re.compile(r'[a-zA-Z_][a-zA-Z0-9_-]*$').match,
         'mathexpr':   re.compile(MATHEXPR).match,
         'datetime':   re.compile(DATETIME).match
         }

def validate_datetime(sinput):
    "validate allowed datetimes"
    return MATCH['datetime'](sinput)

def validate_mathexpr(sinput):
    "validate mathematical expression"
    return MATCH['mathexpr'](sinput)

def validate_crystal(sinput):
    """validate allowed names of crystal reflections:
    Si 111,  Ge 220 etc are allowed:  ALLOWED CRYSTAL  3_integers
    """    
    xtal, reflection  = sinput.split(' ', 1)
    if xtal.lower() not in (a.lower() for a in  ALLOWED_CRYSTALS):
        return False
    try:
        refl = [int(i) for i in reflection.replace(' ','')]
        return len(refl)>2
    except ValueError:
        return False
    
def validate_int(sinput):
    "validate for int"
    try:
        int(sinput)
        return True
    except ValueError:
        return False
    
def validate_float(sinput):
    "validate for float"
    try:
        float(sinput)
        return True
    except ValueError:
        return False

def validate_float_or_nan(sinput):
    "validate for float, with nan, inf"
    try:
        return (sinput.lower() == 'nan' or
                sinput.lower() == 'inf' or
                float(sinput))
    except ValueError:
        return False

def validate_words(sinput):
    "validate for words"
    for word in sinput.strip().split(' '):
        if not MATCH['word'](word):
            return False
    return True

def validate_properword(sinput):
    "validate for words"
    return  MATCH['properword'](sinput)

def validate_chars(sinput):
    "validate for string"
    for char in sinput:
        if char not in PRINTABLES:
            return False
    return True

def strip_comment(sinput):
    """remove leading '#' or ';', return stripped_string,
    returns None if string does NOT start with # or ;"""
    if sinput.startswith('#') or sinput.startswith(';'):
        return sinput[1:].strip()
    return None

class XDIFileException(Exception):
    """XDI File Exception: General Errors"""
    def __init__(self, msg, **kws):
        Exception.__init__(self)
        self.msg = msg

    def __str__(self):
        return self.msg

COLUMN_NAMES = ('energy', 'i0', 'itrans', 'ifluor', 'irefer',
                'mutrans', 'mufluor', 'murefer')

DEFINED_FIELDS = {
    "abscissa": validate_mathexpr,
    "beamline": validate_words,
    "collimation": validate_words,
    "crystal" : validate_crystal,
    "d_spacing" : validate_float,
    "edge_energy": validate_float, 
    "end_time"   : validate_datetime,
    "focusing"   : validate_words, 
    "harmonic_rejection": validate_chars,
    "mu_fluorescence" : validate_mathexpr,
    "mu_reference"    : validate_mathexpr,
    "mu_transmission" : validate_mathexpr,
    "ring_current"  : validate_float,
    "ring_energy"   : validate_float,
    "start_time"    : validate_datetime, 
    "source"        : validate_words, 
    "undulator_harmonic" : validate_int}

class XDIFile(object):
    """ XAS Data Interchange Format:

    See https://github.com/bruceravel/XAS-Data-Interchange

    for further details

    >>> xdi_file = XDFIile(filename)

    Principle data members:
      columns:  dict of column indices, with keys
                       'energy', 'i0', 'itrans', 'ifluor', 'irefer'
                       'mutrans', 'mufluor', 'murefer'
                 some of which may be None.
      column_data: dict of data for arrays -- same keys as
                 for columns.

      
      comments:  list of user comments
      labels:    original column labels.
      abscissa:  column # for abscissa of data
      beamline:    text description of beamline 
      collimation:  text description of source collimation
      crystal :    text description of crystal
      d_spacing :  monochromator d spacing (Angstroms?)
      edge_energy: nominal edge energy (ev?)
      end_time   : ending datetime
      focusing   : text description of beamline focusing
      harmonic_rejection: text description of harmonic rejection
      mu_fluorescence : math expression to calculate mu_fluorescence 
      mu_reference    : math expression to calculate mu_reference
      mu_transmission : math expression to calculate mu_transmission 
      ring_current  : value of ring current (mA?)
      ring_energy   : value of ring energy (GeV?)
      start_time    : starting datetime, 
      source        : text description of source
      undulator_harmonic : value of undulator harmonic
       
    Principle methods:
      read():     read XDI data file, set column data and attributes
      write(filename):  write xdi_file data to an XDI file.
      
    """
    def __init__(self, fname=None):
        self.fname = fname
        self.attributes = {}
        self.comments = []
        self.data = []
        self.column_data = {}
        self.columns  = {}
        self.has_numpy = HAS_NUMPY
        for key in COLUMN_NAMES:
            self.columns[key] = None
            self.column_data[key] = None

        self.npts = 0
        self.file_version = None
        self.application_info = None
        self.lineno  = 0
        self.line    = ''
        self.labels = []
        for keyname in DEFINED_FIELDS:
            setattr(self, keyname, None)
        if self.fname:
            self.read(self.fname)

    def error(self, msg, with_line=True):
        "wrapper for raising an XDIFile Exception"
        msg = '%s: %s' % (self.fname, msg)
        if with_line:
            msg = "%s (line %i)\n   %s" % (msg, self.lineno, self.line)
        raise XDIFileException(msg)

    def write(self, fname):
        "write out an XDI File"

        if self.columns['energy'] is None:
            self.error("cannot write datafile '%s': No data to write" % fname)
        
        topline = "# XDI/1.0"
        if hasattr(self, 'application_info'):
            topline = "%s %s" % (topline, '/'.join(self.application_info))
        buff = [topline]
        labels = []
        icol = 0
        for attrib in COLUMN_NAMES:
            if self.column_data[attrib] is not None:
                icol = icol + 1
                buff.append('# Column_%s: %i' % (attrib, icol))
                labels.append(attrib)
                
        buff.append('# Abscissa: $1')
        for attrib in sorted(DEFINED_FIELDS):
            if attrib.startswith('abscissa'):
                continue
            if hasattr(self, attrib) and getattr(self, attrib) is not None:
                buff.append("# %s: %s" % (attrib.title(),
                                          str(getattr(self, attrib))))
                
        self.attributes['Original_Labels'] = ' '.join(self.labels)
        for key  in sorted(self.attributes):
            buff.append("# %s: %s" % (key.title(), str(self.attributes[key])))
        
        buff.append('# ///')
        for cline in self.comments:
            buff.append("# %s" % cline)
        
        buff.append('#----')        
        buff.append('# %s' % ' '.join(labels))
        for idx in range(len(self.column_data['energy'])):
            dat = []
            for lab in labels:
                dat.append(str(self.column_data[lab][idx]))
            buff.append("  %s" % '  '.join(dat))
        
        fout = open(fname, 'w')
        fout.writelines(('%s\n' % l for l in buff))
        fout.close()
    
    def read(self, fname=None):
        "read, validate XDI datafile"
        if fname is None and self.fname is not None:
            fname = self.fname
        text  = open(fname, 'r').readlines()
        line0 = strip_comment(text.pop(0))

        if not line0.startswith('XDI/'):
            self.error('is not a valid XDI File.', with_line=False)

        self.file_version, other = line0[4:].split(' ', 1)
        self.application_info = other.split('/')
            

        self.lineno = 1
        state = 'FIELDS'
        for line in text:
            self.line = line
            self.lineno += 1
            if state != 'DATA':
                line = strip_comment(line)

            if line.startswith('//'):
                state = 'COMMENTS'
            elif line.startswith('---'):
                state = 'LABELS'
            elif state == 'COMMENTS':
                if not validate_chars(line):
                    self.error('invalid comment')
                self.comments.append(line)
            elif state == 'LABELS':
                self.labels = line.split()
                for lab in self.labels:
                    if not validate_properword(lab):
                        self.error("invalid column label")
                state = 'DATA'
            elif state == 'DATA':
                if len(self.data) == 0:
                    dat = line.split()
                    self.npts = len(dat)
                else:
                    dat = line.split()
                    if len(dat) != self.npts:
                        self.error("inconsistent number of data points")
                try:
                    [validate_float_or_nan(i) for i in dat]
                except ValueError:
                    self.error("non-numeric data")
                dat = [float(d) for d in dat]
                self.data.append(dat)
            elif state == 'FIELDS':
                fieldname, value = [i.strip() for i in line.split(':', 1)]
                attrib = fieldname.lower().replace('-','_')
                validator = DEFINED_FIELDS.get(attrib, validate_chars)
                isColumnLabel = False
                if attrib.startswith('column_'):
                    validator = validate_int
                    isColumnLabel = True
                    col_label = attrib[7:]
                    
                if (attrib not in DEFINED_FIELDS and 
                    not validate_properword(fieldname)):
                    self.error("invalid field name '%s'" % fieldname)
                if not validator(value):
                    self.error("invalid field value '%s'" % value)
                if attrib in DEFINED_FIELDS:
                    setattr(self, attrib, value)
                elif isColumnLabel:
                    self.columns[col_label] = int(value)
                else:
                    self.attributes[fieldname] = value

        if self.has_numpy:
            self.data = np.array(self.data)
        self.assign_arrays()
        
    def assign_arrays(self):
        """assign data arrays for i0, itrans, ifluor, irefer"""
        cols = self.columns
        if cols['energy'] is None:            
            expr = validate_mathexpr(self.abscissa).groups()
            cols['energy'] = int(expr[2].replace('$', ''))

            
        # is there transmission data?
        if cols['mutrans'] is None and cols['itrans'] is None and \
           self.mu_transmission is not None:
            trans =  validate_mathexpr(self.mu_transmission).groups()
            if trans is not None and trans[1] == 'ln' and trans[3] == '/':
                if trans[0] == '-':
                    cols['i0']  = int(trans[4].replace('$', ''))
                    cols['itrans'] = int(trans[2].replace('$', ''))
                else:
                    cols['i0'] = int(trans[2].replace('$', ''))
                    cols['itrans'] = int(trans[4].replace('$', ''))

        # is there reference data?
        if cols['murefer'] is None and cols['irefer'] is None and \
           self.mu_reference is not None:            
            refer =  validate_mathexpr(self.mu_reference).groups()
            if refer is not None and refer[1] == 'ln' and refer[3] == '/':
                if refer[0] == '-':
                    cols['irefer'] = int(refer[2].replace('$', ''))
                else:
                    cols['irefer'] = int(refer[4].replace('$', ''))

        # is there fluoreecence data?
        if cols['mufluor'] is None and cols['ifluor'] is None and \
           self.mu_fluorescence is not None:            
            fluor =  validate_mathexpr(self.mu_fluorescence).groups()
            if fluor is not None:
                cols['ifluor'] = int(fluor[2].replace('$', ''))
            
        # set column_data and mu arrays
        for name in COLUMN_NAMES:
            if cols[name] is not None:
                self.column_data[name] = self.get_column(cols[name])

        # complete column and mu assignments
        dat = self.column_data
        if cols['i0'] is not None:
            if (cols['mutrans'] is None and cols['itrans'] is not None):
                dat['mutrans'] = self._op('itrans', 'i0', '/', use_log=True)
            elif (cols['itrans'] is None and cols['mutrans'] is not None):
                dat['itrans'] = self._op('i0', 'mutrans', 'mul_exp')
 
            if (cols['mufluor'] is None and cols['ifluor'] is not None):
                dat['mufluor'] = self._op('ifluor', 'i0', '/')
            elif (cols['ifluor'] is None and cols['mufluor'] is not None):
                dat['ifluor'] = self._op('mufluor', 'i0', '*')

        if cols['itrans'] is not None:
            if (cols['murefer'] is None and cols['irefer'] is not None):
                dat['murefer'] = self._op('irefer', 'itrans', '/', use_log=True)
            elif (cols['irefer'] is None and cols['murefer'] is not None):
                dat['irefer'] = self._op('itrans', 'murefer', 'mul_exp')
            
    def _op(self, col1, col2, op, use_log=False):
        "support two-array operations for intensity <-> mu calcs " 
        dat1 = self.column_data[col1]
        dat2 = self.column_data[col2]
        if self.has_numpy:
            if op == '/':
                out =  dat1 / dat2
            elif op == '*':
                out = dat1 * dat2
            elif op=='mul_exp':
                out = dat1 * np.exp(-dat2)
            if use_log:
                out = np.log(out)
        else:
            if op == '/':
                out =  [(1.0*d1/d2) for d1, d2 in zip(dat1, dat2)]
            elif op == '*':
                out = [(d1*d2) for d1, d2 in zip(dat1, dat2)]
            elif op=='mul_exp':
                out = [(1.0*d1*math.exp(-d2)) for d1, d2 in zip(dat1, dat2)]
            if use_log:
                out = [math.log(d1) for d1 in out]
        return out
        
    def get_column(self, idx):
        if idx is None or idx < 1:
            return None
        if self.has_numpy:
            return self.data[:, idx-1]
        else:
            return [row[idx-1] for row in self.data]
    

