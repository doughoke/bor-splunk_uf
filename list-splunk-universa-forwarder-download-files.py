#!/usr/bin/python """ Simple little script to build a list of splunks build and version numbers pulled from the 'previous download' page on Splunk's main web page. """

import os, sys, re, csv, urllib2

webpage_urls = [
"https://download.splunk.com/products",
"http://www.splunk.com/page/previous_releases"
]
# Be sure to set this to an appropriate path on your system.
#outfile = os.path.join(os.environ["SPLUNK_HOME"], "etc", "system", "lookups", "splunk_builds.csv")
outfile = "splunk_universalforwarder_builds.csv"

splunk_splitter = re.compile(r'\bsplunkforwarder-\d+.\d+(?:.\d+)?-\d+-[\w.-]+.(?:tgz|rpm|deb|msi|pkg.Z|tar.Z|bin)\b')
splunk_re = re.compile(r'^splunkforwarder-(?P<version>\d+.\d+(?:.\d+)?)-(?P<build>\d+)-(?P<platform>[\w.-]+).(?P<ext>tgz|rpm|deb|msi|pkg.Z|tar.Z|bin)')

def extract_version(url):
    fp = urllib2.urlopen(url)
    content = fp.read()
    for txt in splunk_splitter.findall(content):
        d = splunk_re.match(txt).groupdict()
        if d["ext"] == "msi":
            d["platform"] = d["platform"].replace("release", "windows")
        yield d

results = {}
for url in webpage_urls:
    for gd in extract_version(url):
        k = (int(gd["build"]), gd["version"])
        platform = gd["platform"]
        if k in results:
            results[k].add(platform)
        else:
            results[k] = set([platform])

o = csv.writer(open(outfile, "w"))
o.writerow(("build", "version", "platforms"))

for key in sorted(results.keys()):
    platform = results[key]
    print key[0], key[1]
    o.writerow( (key[0], key[1], ";".join(platform)) )