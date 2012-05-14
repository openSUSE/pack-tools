import rpm, re, sys

# the rpm's epoch:version:release pattern
RPMEVR_PATTERN = re.compile("((?P<epoch>\d+):)?(?P<version>.*?)-(?P<release>.*)")

def parseevr(string):
    global RPMEVR_PATTERN

    m = RPMEVR_PATTERN.match(string)
    if not m:
        raise ValueError("'%s' does not look like rpm epoch:version-release string" % string)

    return  int(m.group('epoch') or 0), \
            m.group('version'), \
            m.group('release')

def hdrfromstr(string):

    e, v, r = parseevr(string)
    hdr = rpm.hdr()
    hdr['Epoch'] = e
    hdr['Version'] = v
    hdr['Release'] = r
    return hdr

def hdrtostr(hdr):

    return "%d:%s-%s" % (hdr['Epoch'], hdr['Version'], hdr['Release'])

#import pdb; pdb.set_trace()

def usage():
    print >>sys.stderr, """Usage: rpmvercmp.py [-q] evr1 evr2

    compares evr1 (epoch:version-release) and evr2 string using
    versionCompare function of rpm and print the result

    argument -q suppresses the human readable output
    
    returns 42 in case of wrong usage
     * 0 if both strings are the same
     * 255 (-1) if evr1 is older than evr2
     * 1 if evr1 is newer than evr2
    """

args = sys.argv[1:]

quiet = False
if '-q' in args:
    args.remove('-q')
    quiet = True

if len(args) < 2:
    usage()
    sys.exit(42)

try:
    hdr1 = hdrfromstr(args[0])
    hdr2 = hdrfromstr(args[1])
except ValueError, ve:
    print >>sys.stderr, ve
    sys.exit(42)

ret =  rpm.versionCompare(hdr1, hdr2)

if not quiet:
    if ret < 0:
        result = "is older than"
    elif ret == 0:
        result = "is equal to"
    else:
        result = "is newer than"

    print "'%s' %s '%s'" % (hdrtostr(hdr1), result, hdrtostr(hdr2))

sys.exit(ret)
