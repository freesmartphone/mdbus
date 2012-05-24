#/bin/sh
srcrev=$1
release_ver=$1
. ./scripts/list_components.sh
for comp in $COMPONENTS; do
	git tag -a -s $comp-$release_ver $srcrev -m "Release $release_ver of $comp"
done

