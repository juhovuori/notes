#!/bin/bash

REGION=eu-west-3
PROFILE=juhocli
AWS="/usr/local/bin/aws --profile=$PROFILE --region=$REGION"
TPL="$(cat aws/infrastructure.yaml)"

create() {
	$AWS cloudformation create-stack --stack-name notes-infra --template-body "$TPL"
}

update() {
	$AWS cloudformation update-stack --stack-name notes-infra --template-body "$TPL"
}

delete() {
	$AWS cloudformation delete-stack --stack-name notes-infra
}

list() {
	$AWS cloudformation describe-stacks
}

create_l_zip() {
	WD=$(mktemp -d)
	ZIPFILE=$(pwd)/l.zip
	rm $ZIPFILE
	cp lambda/* "$WD"
	cp -r env/lib/python3.5/site-packages/* "$WD"
	pushd "$WD"
	zip -r "$ZIPFILE" *
	popd
	rm -r "$WD"
}

create_lambda() {
	$AWS lambda create-function \
		--function-name NotesInitDB  \
		--zip-file fileb://./l.zip \
		--role arn:aws:iam::768079660079:role/NotesLambdaRole \
		--handler init_db.handler \
		--runtime python3.6
#		--vpc-config SubnetIds=comma-separated-subnet-ids,SecurityGroupIds=default-vpc-security-group-id \
}

update_lambda() {
		$AWS lambda update-function-code \
		--function-name NotesInitDB  \
		--zip-file fileb://./l.zip
}

delete_lambda() {
		$AWS lambda delete-function \
		--function-name NotesInitDB
}

init_db() {
	$AWS lambda invoke \
		--function-name NotesInitDB  \
		output.txt 
}
usage() {
	echo usage
	exit 1
}
while [ "$#" -gt 0 ]
do
	cmd=$1; shift
	case $cmd in
		create) create
		;;
		update) update
		;;
		delete) delete
		;;
		list) list
		;;
		create-l-zip) create_l_zip
		;;
		create-lambda) create_lambda
		;;
		update-lambda) update_lambda
		;;
		delete-lambda) delete_lambda
		;;
		init-db) init_db
		;;
		tpl) echo "$TPL"
		;;
		*) usage
		;;
	esac
done
