.PHONY: ci test lint
ci: lint test

lint:
	bash -n sync-youtube-downloads tests/test.sh
	if command -v shellcheck >/dev/null; then shellcheck sync-youtube-downloads tests/test.sh; fi

test:
	tests/test.sh
