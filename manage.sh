#!/bin/bash

REGION=eu-west-3
PROFILE=juhocli
AWS="/usr/local/bin/aws --profile=$PROFILE --region=$REGION"
INFRA_TPL="$(cat cfn/infrastructure.yaml)"
INFRA_PARAMS="[]"
ENV_TPL="https://s3.eu-west-3.amazonaws.com/$ARTIFACT_BUCKET/${ARTIFACT_CFN_PREFIX}env-$APP_VERSION.yaml"
APP_VERSION="$(git rev-parse --short HEAD)"
APP_PARAMS="ParameterKey=Version,ParameterValue=$APP_VERSION"
TARGET_DIR="$(pwd)/target"
ARTIFACT_BUCKET="notes-artifacts-20171228"
ARTIFACT_LAMBDA_PREFIX="lambda/"
ARTIFACT_CFN_PREFIX="cfn/"
APP_TPL="https://s3.eu-west-3.amazonaws.com/$ARTIFACT_BUCKET/${ARTIFACT_CFN_PREFIX}app-$APP_VERSION.yaml"

mkdir -p "$TARGET_DIR"

create_with_body() {
	STACK_NAME=$1; shift
	TPL=$1; shift
	PARAMS=$1; shift
	$AWS cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name "$STACK_NAME" --parameters "$PARAMS" --template-body "$TPL"
}

update_with_body() {
	STACK_NAME=$1; shift
	TPL=$1; shift
	PARAMS=$1; shift
	$AWS cloudformation update-stack --stack-name "$STACK_NAME" --parameters "$PARAMS" --template-body "$TPL"
}

create() {
	STACK_NAME=$1; shift
	TPL=$1; shift
	PARAMS=$1; shift
	$AWS cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name "$STACK_NAME" --parameters "$PARAMS" --template-url "$TPL"
}

update() {
	STACK_NAME=$1; shift
	TPL=$1; shift
	PARAMS=$1; shift
	$AWS cloudformation update-stack --stack-name "$STACK_NAME" --parameters "$PARAMS" --template-url "$TPL"
}

delete() {
	STACK_NAME=$1; shift
	$AWS cloudformation delete-stack --stack-name "$STACK_NAME"
}

list() {
	$AWS cloudformation describe-stacks
}

create_zip_file() {
	WD=$(mktemp -d)
	ZIPFILE=$1; shift
	rm $ZIPFILE
	cp lambda/* "$WD"
	cp -r env/lib/python3.5/site-packages/* "$WD"
	pushd "$WD"
	zip -qR "$ZIPFILE" '*.py'
	popd
	rm -r "$WD"
	echo $ZIPFILE
}

push_app() {
	VERSION=$1; shift
	ZIP_FILE="$TARGET_DIR/app-$VERSION.zip"
	create_zip_file $ZIP_FILE
	$AWS s3 cp "$ZIP_FILE" "s3://$ARTIFACT_BUCKET/${ARTIFACT_LAMBDA_PREFIX}app-$VERSION.zip"
}

push_cfn() {
	TPL_BASE=$1; shift
	VERSION=$1; shift
	SRC="cfn/$TPL_BASE.yaml"
	DEST="s3://$ARTIFACT_BUCKET/$ARTIFACT_CFN_PREFIX$TPL_BASE-$VERSION.yaml"
	$AWS s3 cp "$SRC" "$DEST"
}

create_lambda() {
	F_NAME=$1; shift
	HANDLER=$1; shift
	$AWS lambda create-function \
		--function-name "$F_NAME"  \
		--zip-file fileb://$(TARGET_DIR)/l.zip \
		--role arn:aws:iam::768079660079:role/NotesLambdaRole \
		--handler "$HANDLER" \
		--runtime python3.6
#		--vpc-config SubnetIds=comma-separated-subnet-ids,SecurityGroupIds=default-vpc-security-group-id \
}

update_lambda() {
	F_NAME=$1; shift
	$AWS lambda update-function-code \
		--function-name "$F_NAME"  \
		--zip-file fileb://$(TARGET_DIR)/l.zip
}

delete_lambda() {
	$AWS lambda delete-function \
		--function-name NotesInitDB
}

init_db() {
	$AWS lambda invoke \
		--function-name NotesInitDB  \
		$TARGET_DIR/output.txt
}
usage() {
	echo usage
	exit 1
}
while [ "$#" -gt 0 ]
do
	cmd=$1; shift
	case $cmd in
		create-infra) create_with_body notes-infra "$INFRA_TPL" "$INFRA_PARAMS"
		;;
		update-infra) update_with_body notes-infra "$INFRA_TPL" "$INFRA_PARAMS"
		;;
		delete-infra) delete notes-infra "$INFRA_TPL" "$INFRA_PARAMS"
		;;
		create-env) create notes-infra "$ENV_TPL" "ParameterKey=Name,ParameterValue=$1"
		shift
		;;
		update-env) update notes-infra "$ENV_TPL" "ParameterKey=Name,ParameterValue=$1"
		shift
		;;
		delete-env) delete notes-infra "$ENV_TPL"
		shift
		;;
		create-app) create notes-app "$APP_TPL" "$APP_PARAMS"
		;;
		update-app) update notes-app "$APP_TPL" "$APP_PARAMS"
		;;
		delete-app) delete notes-app "$APP_TPL"
		;;
		list) list
		;;
		create-l-zip) create_zip_file "$TARGET_DIR/l.zip"
		;;
		push-app-cfn) push_cfn app "$APP_VERSION"
		;;
		push-env-cfn) push_cfn env "$1"
		shift
		;;
		push-app) push_app "$APP_VERSION"
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
