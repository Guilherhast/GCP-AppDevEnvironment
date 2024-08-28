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
ENTRYPOINTNAME=lab-entryPoint
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
	$CLOUDCMD storage buckets create $BUCKETNAME --placement=$REGION
}

createPubSub(){
	$CLOUDCMD pubsub topics create $TOPICNAME
}

createCloudFunction(){
	cd $APPFOLDER

	$NPMCMD install
	$CLOUDCMD functions deploy nodejs-pubsub-function \
		--gen2 \
		--runtime=nodejs20 \
		--region=$REGION \
		--source=. \
		--entry-point=$ENTRYPOINTNAME \
		--trigger-topic cf-demo \
		--stage-bucket ${PROJECT}-${BUCKETNAME} \
		--service-account cloudfunctionsa@${PROJECT}.iam.gserviceaccount.com \
		--allow-unauthenticated

	cd - >/dev/null
}

removeOldUser(){
	$CLOUDCMD iam roles delete $OLDUSERNAME --project=$PROJECT
}

uploadFile(){
	$CLOUDCMD storage cp ./Data/map.jpg \
		gs://$BUCKETNAME
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
echoDivision "Finished"
