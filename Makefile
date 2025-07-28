UPSTREAM_DIR = Geyser
PATCHED_UPSTREAM_DIR = patched-geyser
PATCHES_DIR = patches
UPSTREAM_REV := $(shell git -C $(UPSTREAM_DIR) rev-parse HEAD)

.PHONY: all
all: applyPatches

$(PATCHED_UPSTREAM_DIR):
	@if [ ! -d "$(PATCHED_UPSTREAM_DIR)" ]; then \
		echo "$(PATCHED_UPSTREAM_DIR) does not exist. Cloning from $(UPSTREAM_DIR)..."; \
		git clone --recurse-submodules $(UPSTREAM_DIR) $(PATCHED_UPSTREAM_DIR); \
	fi
	@echo "Resetting $(PATCHED_UPSTREAM_DIR) to commit $(UPSTREAM_REV)..."
	cd $(PATCHED_UPSTREAM_DIR) && git fetch && git reset --hard $(UPSTREAM_REV)

.PHONY: applyPatches
applyPatches: $(PATCHED_UPSTREAM_DIR)
	@echo "Resetting $(PATCHED_UPSTREAM_DIR) to commit $(UPSTREAM_REV) before applying patches..."
	cd $(PATCHED_UPSTREAM_DIR) && git fetch && git reset --hard $(UPSTREAM_REV)

	@echo "Applying patches from $(PATCHES_DIR)..."
	@cd $(PATCHED_UPSTREAM_DIR) && \
		if [ -d ".git/rebase-apply" ]; then \
			echo "A previous patch application is in progress. Run 'git am --abort' first."; \
			exit 1; \
		fi && \
		git am --3way --whitespace=fix ../$(PATCHES_DIR)/*.patch || \
		{ echo "Patch application failed. Resolve the conflict and run 'git am --continue' manually."; exit 1; }

	@echo "Patches applied successfully!"

.PHONY: makePatches
makePatches: $(PATCHED_UPSTREAM_DIR)
	@mkdir -p $(PATCHES_DIR)
	@echo "Creating patches from $(PATCHED_UPSTREAM_DIR)..."
	cd $(PATCHED_UPSTREAM_DIR) && git format-patch --no-signature --no-stat -N $(UPSTREAM_REV) -o ../$(PATCHES_DIR)
	@echo "Patches created successfully!"

.PHONY: build
build: $(PATCHED_UPSTREAM_DIR)
	@echo "Running npm build in $(PATCHED_UPSTREAM_DIR)..."
	cd $(PATCHED_UPSTREAM_DIR) && npm install && npm run bundle-webapp
	@echo "Build completed successfully!"
