# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

VERSION := $(shell git rev-parse --abbrev-ref HEAD)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

build-landing:
	rm -rf ./landing/build
	cd ./landing && yarn && yarn build && cd ..

deploy-landing:
	aws s3 rm --recursive s3://${BUCKET_NAME}/ \
		  --include="*" --exclude="workspace/*"
	aws s3 cp --recursive --acl public-read \
		./landing/build s3://${BUCKET_NAME}/
	aws s3 cp --acl public-read \
		--cache-control="max-age=0, no-cache, no-store, must-revalidate" \
		./landing/build/index.html s3://${BUCKET_NAME}/

build-space:
	rm -rf ./workspace/build
	cd ./workspace && yarn && yarn build && cd ..

deploy-space:
	aws s3 rm --recursive s3://${BUCKET_NAME}/ \
		  --include="workspace/*" --exclude="*"
	aws s3 cp --recursive --acl public-read \
		./workspace/build s3://${BUCKET_NAME}/workspace
	aws s3 cp --acl public-read \
		--cache-control="max-age=0, no-cache, no-store, must-revalidate" \
		./workspace/build/index.html s3://${BUCKET_NAME}/workspace

build: build-landing build-space
deploy: deploy-space deploy-landing