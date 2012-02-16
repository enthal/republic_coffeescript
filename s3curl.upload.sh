(cd public/; for x in `find .`; do y=`echo $x | cut -c 3-`; echo $y; s3curl.pl --id=tim --put=$y --debug -- http://s3.amazonaws.com/timtest1/$y; done)
