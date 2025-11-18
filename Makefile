UPSTREAM_DIR := Geyser
PATCHED_UPSTREAM_DIR := patched-geyser
PATCHES_DIR := patches
UPSTREAM_REV := $(shell git -C $(UPSTREAM_DIR) rev-parse HEAD)

.PHONY: all
all: applyPatches

$(PATCHED_UPSTREAM_DIR):
	@if [ ! -d "$(PATCHED_UPSTREAM_DIR)/.git" ]; then \
		echo "Cloning $(UPSTREAM_DIR) into $(PATCHED_UPSTREAM_DIR)..."; \
		git clone --recurse-submodules $(UPSTREAM_DIR) $(PATCHED_UPSTREAM_DIR); \
	else \
		echo "$(PATCHED_UPSTREAM_DIR) already exists."; \
	fi
	@echo "Resetting $(PATCHED_UPSTREAM_DIR) to upstream commit $(UPSTREAM_REV)..."
	@git -C $(PATCHED_UPSTREAM_DIR) fetch $(abspath $(UPSTREAM_DIR)) HEAD
	@git -C $(PATCHED_UPSTREAM_DIR) checkout -B upstream-sync FETCH_HEAD
	@git -C $(PATCHED_UPSTREAM_DIR) reset --hard $(UPSTREAM_REV)

applyPatches: $(PATCHED_UPSTREAM_DIR)
	@echo "Stashing any local changes..."
	@STASHED=0; \
	if ! git -C $(PATCHED_UPSTREAM_DIR) diff-index --quiet HEAD --; then \
		git -C $(PATCHED_UPSTREAM_DIR) stash push -u -m "autostash before patch application"; \
		STASHED=1; \
	fi; \
	echo "Resetting to upstream commit $(UPSTREAM_REV)..."; \
	git -C $(PATCHED_UPSTREAM_DIR) fetch $(abspath $(UPSTREAM_DIR)) HEAD; \
	git -C $(PATCHED_UPSTREAM_DIR) reset --hard $(UPSTREAM_REV); \
	echo "Applying patches from $(PATCHES_DIR)..."; \
	if [ -d "$(PATCHED_UPSTREAM_DIR)/.git/rebase-apply" ]; then \
		echo "!! A previous patch application is in progress. Run 'git am --abort' first."; \
		exit 1; \
	fi; \
	git -C $(PATCHED_UPSTREAM_DIR) am --3way --whitespace=fix $(abspath $(PATCHES_DIR))/*.patch || { \
		echo "!! Patch application failed. Resolve conflicts and run 'git am --continue'."; exit 1; \
	}; \
	if [ "$$STASHED" -eq 1 ]; then \
		echo "Restoring stashed changes..."; \
		git -C $(PATCHED_UPSTREAM_DIR) stash pop || echo "!! Could not apply stashed changes automatically. Resolve manually."; \
	fi
	@echo "Patches applied successfully!"

makePatches: $(PATCHED_UPSTREAM_DIR)
	@mkdir -p $(PATCHES_DIR)
	@echo "Creating patches from $(PATCHED_UPSTREAM_DIR)..."
	@git -C $(PATCHED_UPSTREAM_DIR) format-patch --no-signature --no-stat -N $(UPSTREAM_REV) -o $(abspath $(PATCHES_DIR))
	@echo "Patches created successfully!"
