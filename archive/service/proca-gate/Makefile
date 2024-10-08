.PHONY: build-IdentitySync build-RuntimeDependenciesLayer events

build-IdentitySync:
	yarn build
	cp -r dist/* "$(ARTIFACTS_DIR)/"

build-CollectDeps:
	mkdir -p "$(ARTIFACTS_DIR)/nodejs"
	yarn install
	cp -r node_modules package.json yarn.lock "$(ARTIFACTS_DIR)/nodejs/"

events:
	events/gen-event.sh register.json
