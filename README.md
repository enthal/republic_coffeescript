# Megillah

Build to convert https://github.com/kquandt/githubRepublic to a website.

New way:
```shell
coffee -c public/

RCQ=~/Downloads/RepublicCommentaryQuandt/
npm start -- $RCQ/content.xml $RCQ/meta.xml $RCQ/styles.xml
```

Be aware of coffee compiler watch mode:
```shell
coffee -cw public/
```

Don't forget to put the PDF `RepublicCommentary_Quandt.pdf` to S3!

Old style:
```shell
npm start -- ../githubRepublic/RepublicCommentary_Quandt.xml
```


