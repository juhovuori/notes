#!/bin/bash

REGION=eu-west-3
AWS="/usr/local/bin/aws --profile=juhocli"
TPL="$(cat aws/infrastructure.yaml)"

create() {
	$AWS cloudformation create-stack --stack-name notes-infra --template-body "$TPL" --region $REGION
}

update() {
	$AWS cloudformation update-stack --stack-name notes-infra --template-body "$TPL" --region $REGION
}

delete() {
	$AWS cloudformation delete-stack --stack-name notes-infra --region $REGION
}

list() {
	$AWS cloudformation describe-stacks --region $REGION
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
		tpl) echo "$TPL"
			;;
		*) usage
			;;
	esac
done
