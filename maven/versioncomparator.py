#!/usr/bin/python
#
# Copyright (c) 2010-2011 SUSE Linux Products GmbH.
# Licensed under the terms of the LGPL license.
#
# Author: Bo Maryniuk <bo@suse.de>

import re


class VersionComparator:
    """
    Valid version format: <n.n~>[mod][n]
    Example:
      1.2
      1.2.3
      1.2.3alpha
      1.2.3alpha1
      etc.
    """

    def __init__(self):
        """
        Initialize class.
        """
        self._getModifier = re.compile("[^a-z]")
        self._cleanModifiers = re.compile("[a-z\s]")
        self.cleanToString = lambda v:self._cleanModifiers.split(str(v).lower())[0]


    def cleanToNumber(self, version):
        """
        Clean version, leaving only numeric repr.
        """
        v = self.cleanToString(version)
        return float(v.split(".")[0] + "." + ''.join(v.split(".")[1:]))


    def getModifier(self, version):
        """
        Extracts [mod][n] from the version.
        """
        mod = "z"
        if self.cleanToString(version) != version:
            mod = list(filter(None, self._getModifier.split(version)))[0]
            modv = filter(None, self._cleanModifiers.split(version)[1:])
            if modv:
                mod += ''.join(modv)

        return mod
            

    def greaterThan(self, ver1, ver2):
        """
        Compare two versions.
        """
        return self._gtNonReleases(ver1, ver2) or self._gtFinalReleases(ver1, ver2)


    gt = greaterThan


    def _gtNonReleases(self, ver1, ver2):
        """
        Compares any versions that has version modifiers (alpha, beta, rc etc).
        """
        if self.cleanToString(ver1) == ver1 and self.cleanToString(ver2) == ver2:
            return False

        mod1 = self.getModifier(ver1)
        mod2 = self.getModifier(ver2)
        nver1 = self.cleanToNumber(ver1)
        nver2 = self.cleanToNumber(ver2)

        return (mod1 > mod2 and nver1 >= nver2) or (mod1 >= mod2 and nver1 > nver2)


    def _gtFinalReleases(self, ver1, ver2):
        """
        Compare only final releases.
        """
        return self.cleanToNumber(ver1) > self.cleanToNumber(ver2)



# Quick test and usage example
if __name__ == "__main__":
    vc = VersionComparator()

    versions = [
        ("0.1", "0.3alpha"),
        ("0.3", "0.3alpha"),
        ("0.5", "0.3alpha"),
        ("0.3", "0.3"),
        ("1.0", "0.9"),
        ("1.0.1", "0.9.9"),
        ("1.0.1alpha", "0.9.9beta"),
        ("1.0.1", "1.0.1rc"),
        ("1.0.1rc1", "1.0.1rc"),
        ("0.3beta", "0.3alpha"),
        ("0.4alpha", "0.3beta"),
        ("0.3", "0.4"),
        ("0.3beta", "0.3rc"),
        ("0.3rc2", "0.3rc1"),
        ]

    for ver1, ver2 in versions:
        print("Version %s is greater than %s : %s" % (ver1, ver2, vc.gt(ver1, ver2)))
