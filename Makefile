UPSTREAM_DIR = Geyser
PATCHED_UPSTREAM_DIR = patched-geyser
PATCHES_DIR = patches
UPSTREAM_REV := $(shell git -C $(UPSTREAM_DIR) rev-parse HEAD)

.PHONY: all
all: applyPatches

$(PATCHED_UPSTREAM_DIR):
	@if [ ! -d "$(PATCHED_UPSTREAM_DIR)" ]; then \
		echo "$(PATCHED_UPSTREAM_DIR) does not exist. Cloning from $(UPSTREAM_DIR)..."; \
		git clone $(UPSTREAM_DIR) $(PATCHED_UPSTREAM_DIR); \
	fi
	@echo "Resetting $(PATCHED_UPSTREAM_DIR) to commit $(UPSTREAM_REV)..."
	cd $(PATCHED_UPSTREAM_DIR) && git fetch && git reset --hard $(UPSTREAM_REV)

.PHONY: applyPatches
applyPatches: $(PATCHED_UPSTREAM_DIR)
	@echo "Resetting $(PATCHED_UPSTREAM_DIR) to commit $(UPSTREAM_REV) before applying patches..."
	cd $(PATCHED_UPSTREAM_DIR) && git fetch && git reset --hard $(UPSTREAM_REV)
	@for patch in $(PATCHES_DIR)/*.patch; do \
		echo "Applying $$patch"; \
		git -C $(PATCHED_UPSTREAM_DIR) am --reject --whitespace=fix < $$patch; \
	done
	@echo "Patches applied successfully!"

.PHONY: makePatches
makePatches: $(PATCHED_UPSTREAM_DIR)
	@mkdir -p $(PATCHES_DIR)
	@echo "Creating patches from $(PATCHED_UPSTREAM_DIR)..."
	cd $(PATCHED_UPSTREAM_DIR) && git format-patch -N $(UPSTREAM_REV) -o ../$(PATCHES_DIR)
	@echo "Patches created successfully!"

.PHONY: build
build: $(PATCHED_UPSTREAM_DIR)
	@echo "Running npm build in $(PATCHED_UPSTREAM_DIR)..."
	cd $(PATCHED_UPSTREAM_DIR) && npm install && npm run bundle-webapp
	@echo "Build completed successfully!"
