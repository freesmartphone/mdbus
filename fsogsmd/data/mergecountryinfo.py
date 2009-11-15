#!/usr/bin/env python
#
# Sources:
#
# iso3361.txt: http://www.asksam.com/ebooks/country-codes/ISO-3166-Country-Code-List.htm
#

SIMILARITY_THRESHOLD = 0.8

import FuGrep

def findMaxSimilarity( name ):
    maxsimilarity = -1.0
    othername = ""
    for key in countries:
        similarity = FuGrep.similarity( name, key )
        if ( similarity > maxsimilarity ):
            othername = key
            maxsimilarity = similarity
    print "%s is maximum similar to %s (value = %s)" % ( name, othername, maxsimilarity )
    return othername, maxsimilarity

def writeMatch( entries, countryname ):
    realname = entries[0].strip().replace( "&", "and" )
    countrycode = countries[countryname]
    dialcode = entries[1].strip()
    timezone_from = entries[2].strip().replace( "GMT", "UTC" )
    timezone_to = timezone_from
    if ( len( entries ) == 4 and len( entries[3].strip() ) > 2 ):
        timezone_to = entries[3].strip().replace( "GMT", "UTC" )

    output.write( "%s\t%s\t%s\t%s\t%s\n" % ( countrycode, realname, dialcode, timezone_from, timezone_to ) )

iso3166 = open( "./iso3361.txt" ).read()
timezones = open( "./timezones.txt" ).read()

output = open( "./iso3361+tz.txt", "w" )
output.write( "# ccode\trealname\tdialcode\ttimezone1\ttimezone2\n" )

countries = {}

for line in iso3166.split( "\n" ):
    if line == "":
        continue
    print "dealing with line '%s'..." % line
    ccode, fullname = line.strip().split( "\t" )
    countries[fullname.lower().strip()] = ccode.lower().strip()

match = 0
nomatch = 0

for line in timezones.split( "\n" ):
    entries = line.strip().split( "\t" )

    name = entries[0].lower().strip().replace( "&", "and" )
    if name in countries:
        print "found exact match for '%s'" % name
        writeMatch( entries, name )
        match += 1
        continue

    othername, similarity = findMaxSimilarity( name )
    if similarity >= SIMILARITY_THRESHOLD:
        print "found fuzzy match for '%s' = '%s' [%s])" % ( name, othername, similarity )
        writeMatch( entries, othername )
        match += 1
    else:
        print "found no match for '%s'" % name
        nomatch += 1

print "STATS: matched %d times, not matched %d time" % ( match, nomatch )

