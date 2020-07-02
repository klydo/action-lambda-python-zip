#!/bin/bash

configure_aws_credentials(){
	aws configure set aws_access_key_id "${INPUT_AWS_ACCESS_KEY_ID}"
    aws configure set aws_secret_access_key "${INPUT_AWS_SECRET_ACCESS_KEY}"
    aws configure set default.region "${INPUT_LAMBDA_REGION}"
}

install_zip_dependencies(){
	echo "Installing and zipping dependencies..."
	mkdir python
	pip install --target=python -r "${INPUT_REQUIREMENTS_TXT}"
	zip -r dependencies.zip ./python
	zipsplit -n 50000000 dependencies.zip
	rm dependencies.zip
}

process_dependencies() {
	FILES=depende*.zip
	for f in $FILES
	do
		publish_dependencies_as_layer $f
	done
	rm -rf python

}

publish_dependencies_as_layer(){
    echo ""
	FILE_NAME=$1
	echo "Publishing $FILE_NAME as a layer..."
	FILE_NUMBER=${FILE_NAME//[^0-9]/}
	echo "FILE_NUMBER: $FILE_NUMBER"
	LAYER_NAME="${INPUT_LAMBDA_LAYER_ARN}${FILE_NUMBER}"
	echo "LAYER_NAME: $LAYER_NAME"
	local result=$(aws lambda publish-layer-version --layer-name "${LAYER_NAME}" --zip-file fileb://${FILE_NAME})
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	ALL_LAMBDA_LAYERS="${ALL_LAMBDA_LAYERS} \"${LAYER_NAME}:${LAYER_VERSION}\""
	echo $ALL_LAMBDA_LAYERS
	rm ${FILE_NAME}
}

publish_function_code(){
	echo "Deploying the code itself..."
	zip -r code.zip . -x \*.git\*
	aws lambda update-function-code --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --zip-file fileb://code.zip
}

update_function_layers(){
	echo "Using the layer in the function..."
	aws lambda update-function-configuration --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --layers ${ALL_LAMBDA_LAYERS}
}

deploy_lambda_function(){
    configure_aws_credentials
	install_zip_dependencies
	process_dependencies
	publish_function_code
	update_function_layers
}

deploy_lambda_function
echo "Each step completed, check the logs if any error occured."