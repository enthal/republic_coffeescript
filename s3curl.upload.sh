cd public/
for x in `find .`
do
  y=`echo $x | cut -c 3-`
  echo $y
  s3curl.pl --id=tim --put=$y --debug -- -H 'x-amz-acl: public-read' http://s3.amazonaws.com/www.onplatosrepublic.com/$y
done
