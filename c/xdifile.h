#define MAX_COLUMNS 64

typedef struct {
  long nmetadata;       /* number of metadata key/val pairs */
  long narrays;         /* number of arrays */
  long npts;            /* number of data points for all arrays */
  long narray_labels;   /* number of labeled arrays (may be < narrays) */
  double dspacing;      /* monochromator d spacing */
  char *xdi_version;    /* XDI version string */
  char *extra_version;  /* Extra version strings from first line of file */
  char *filename;       /* name of file */
  char *element;        /* atomic symbol for element */
  char *edge;           /* name of absorption edge: "K", "L1", ... */
  char *comments;       /* multi-line, user-supplied comment */
  char **array_labels;  /* labels for arrays */
  char **array_units;   /* units for arrays */
  char **metadata_keys; /* keys for metadata from file header */
  char **metadata_vals; /* value for metadata from file header */
  double **array;       /* 2D array of all array data */
} XDIFile;

int XDI_hasfile(char *filename);
int XDI_readfile(char *filename, XDIFile *xdifile) ;
int XDI_get_array_index(XDIFile *xdifile, long n, double *out);
int XDI_get_array_name(XDIFile *xdifile, char *name, double *out);
int XDI_get_metadata_keys(XDIFile *xdifile, char **keys);
int XDI_get_metadata(XDIFile *xdifile, char *key, char *value);

