#!/usr/bin/env python
#-*- coding: utf-8 -*-

import argparse, os

FILE = '/var/lib/alsa/asound.state'
STATE = None

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('-f', '--file', help='alsa state file, defaults to current alsa state')
	parser.add_argument('-d', '--dev', help='alsa device, e.g. -s Intel for "state.Intel {...}"')
	args = parser.parse_args()
	global FILE
	global STATE

	if args.file:
		FILE = args.file
	if args.dev:
		STATE = args.dev

	f = open( FILE, 'r' )
	current = None
	state = None

	for line in f:
		l = line.strip()
		if l[0:6] == 'state.':
			state =  l[6:-2]
			if STATE is None or STATE == state:
				try:
					os.remove( state+'.scenario' )
				except:
					pass
		if l[0:8] == 'control.':
			current = { 'id':-1, 'name':'', 'val':[] }
			current['id'] = int(l[8:-2])
		if l[0:5] == 'name ':
			current['name'] = l[5:]
		if l[0:5] == 'value':
			if current['name'] == 'ELD':
				current['val'] = []
			elif current['name'][1:7] == 'IEC958':
				current['val'].append('<IEC958>')
			else:
				if l.split( ' ' )[1] == 'true':
					current['val'].append(1)
				elif l.split( ' ' )[1] == 'false':
					current['val'].append(0)
				else:
					current['val'].append(l.split( ' ' )[1])
		if l[0:7] == 'comment':
			write_out( state, current )
	f.close()

def write_out( s, c ):
	if STATE is None or STATE == s:
		f = open( s+'.scenario', 'a' )
		line = ''
		line += str(c['id'])+':'
		if c['name'][0] != "'" and c['name'][-1] != "'":
			line += "'"+c['name']+"'"
		else:
			line += c['name']
		line += ':'+str(len(c['val']))+':'
		for v in c['val']:
			line += str(v)+','
		line = line[0:-1]
		f.write( line+'\n' )
		f.close()

if __name__ == '__main__':
    main()
