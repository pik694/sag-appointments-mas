.PHONY: init
init:
	mix local.rebar --force
	mix local.hex --force
	mix deps.get

.PHONY: clean
clean:
	rm -rf _build deps

.PHONY: build
build:
	mix compile 

.PHONY: test
test:
	mix test

.PHONY: lint
lint:
	mix format --check-formatted
