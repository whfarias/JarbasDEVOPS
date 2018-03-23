segments_number=$(python -c 'import json,sys;obj=json.load(sys.stdin);print len(obj["items"]);' < Jarbassegments.txt)
counter=0
while [ $segments_number -gt $counter ]
do
    segment=$(cat Jarbassegments.txt | python -c 'import json,sys;obj=json.load(sys.stdin);data_str=json.dumps(obj["items"]['$counter']);print data_str;')
    echo $segment | curl -X POST -d @- --user admin:sAhni_8uxr --header "Content-Type:application/json" https://mobiledemodevopsed-server.eu-gb.mybluemix.net/mfpadmin/management-apis/2.0/runtimes/mfp/admin-plugins/liveUpdateAdapter/com.ibm.codebakery.jarbas/segment
    ((counter++))
done