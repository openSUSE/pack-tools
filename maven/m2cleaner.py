#!/usr/bin/python3
import string, os

from versioncomparator import VersionComparator

vc = VersionComparator()

pomfiles = os.popen('find ~/.m2/repository -name "*.pom"').readlines()
# Remove trailing '\n'
for index,file in enumerate(pomfiles):
    pomfiles[index]=file.replace('\n','')

vers = { }

# Return [groupId/artifactId,version] extracted from a pom location
def get_path_and_version(path):
    [tmppath,sep,filename] = path.rpartition('/')
    [path1,sep,version] = tmppath.rpartition('/')
    return [path1,version]


# First pass
def first_pass():
    for file in pomfiles:
        [path,version_file]=get_path_and_version(file)
        try:
            [nopath,version_vers_file]=get_path_and_version(vers[path])
        except KeyError:
            version_vers_file='0'
        if vc.gt(version_file, version_vers_file):
            vers[path]=file

# Second pass
def second_pass():
    for file in pomfiles:
        [path,novers]=get_path_and_version(file)
        if file != vers[path]:
            print(file + ' -> ' + vers[path] )
            os.remove(file)
            os.symlink(vers[path],file)
        else:
            print(file)

first_pass()
second_pass()
