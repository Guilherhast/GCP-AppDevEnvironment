#!/bin/bash

CLOUDCMD=echo
NPMCMD=echo

APPFOLDER=./nodeApp

# Global
PROJECT=123

ZONE=us-centralc-1
REGION=${ZONE%-*}

# Scripts
BUCKETNAME=lab-bucket
TOPICNAME=lab-topic
FUNCTIONNAME=lab-function
ENTRYPOINTNAME=$FUNCTIONNAME
OLDUSERNAME=Ernesto

STORAGEOBJECT=${PROJECT}-${BUCKETNAME}

echoDivision(){
	RESETCOLOR='\033[0m'
	GREEN='\033[0;32m'

	echo
	echo -e "${GREEN}$*${RESETCOLOR}"
	echo
}

setProject(){
	$CLOUDCMD config set project $PROJECT
	$CLOUDCMD config set compute/region $REGION
	$CLOUDCMD config set compute/zone $ZONE
}

createBucket(){
	$CLOUDCMD storage buckets create gs://$BUCKETNAME
	# --placement=$REGION
}

createPubSub(){
	$CLOUDCMD pubsub topics create $TOPICNAME
}

createCloudFunction(){
	cd $APPFOLDER

	$NPMCMD install
	$CLOUDCMD functions deploy $FUNCTIONNAME \
		--gen2 \
		--runtime=nodejs20 \
		--region=$REGION \
		--source=. \
		--entry-point=$ENTRYPOINTNAME \
		--trigger-resource=$BUCKETNAME \
		--trigger-event=google.storage.object.finalize \
		--stage-bucket ${PROJECT}-${BUCKETNAME} \
		--service-account cloudfunctionsa@${PROJECT}.iam.gserviceaccount.com \
		--allow-unauthenticated

	sed -i  "s/GCLOUD_FUNCTION_NAME/$FUNCTIONNAME/" $APPFOLDER/index.js
	sed -i  "s/GCLOUD_TOPIC_NAME/$TOPICNAME/" $APPFOLDER/index.js

	cd - >/dev/null
}

removeOldUser(){
	$CLOUDCMD iam roles delete $OLDUSERNAME --project=$PROJECT
	$CLOUDCMD project remove-iam-policy-binding $PROJECT  \
		--member=user:$OLDUSERNAME \
		--role=roles/viewer

}

uploadFile(){
	FILE="map"$(uuidgen | tr -d '-' )".jpg"
	cp ./Data/map.jpg $FILE
	$CLOUDCMD storage cp  ./Data/$FILE gs://$BUCKETNAME
	rm $FILE
	unset $FILE
}

testCloudFunction(){
	$CLOUDCMD run services describe $FUNCTIONNAME \
		--region $REGION
}


# Run
#
echoDivision "Setup project" &&
setProject &&
echoDivision "Creating bucket" &&
createBucket &&
echoDivision "Creating pub/sub" &&
createPubSub &&
echoDivision "Creating cloudFunction" &&
createCloudFunction &&
echoDivision "Uploading object" &&
uploadFile &&
echoDivision "Removing old user" &&
removeOldUser &&
echoDivision "Testing cloud function" &&
testCloudFunction &&
echoDivision "Finished"
