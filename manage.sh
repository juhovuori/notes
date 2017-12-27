#!/bin/bash

REGION=eu-west-3
PROFILE=juhocli
AWS="/usr/local/bin/aws --profile=$PROFILE --region=$REGION"
TPL="$(cat cfn/infrastructure.yaml)"

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
	zip -R "$ZIPFILE" '*.py'
	popd
	rm -r "$WD"
}

create_lambda() {
	F_NAME=$1; shift
	HANDLER=$1; shift
	$AWS lambda create-function \
		--function-name "$F_NAME"  \
		--zip-file fileb://./l.zip \
		--role arn:aws:iam::768079660079:role/NotesLambdaRole \
		--handler "$HANDLER" \
		--runtime python3.6
#		--vpc-config SubnetIds=comma-separated-subnet-ids,SecurityGroupIds=default-vpc-security-group-id \
}

update_lambda() {
	F_NAME=$1; shift
	$AWS lambda update-function-code \
		--function-name "$F_NAME"  \
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
		create-lambda) create_lambda "$1" "$2"
		shift 2
		;;
		create-lambdas)
		create_lambda NotesInitDB init_db.handler
		;;
		update-lambda) update_lambda "$1"
		shift
		;;
		update-lambdas)
		update_lambda NotesAdd
		update_lambda NotesFetch
		update_lambda NotesList
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
