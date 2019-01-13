.PHONY: test/all test

DEFAULT_VERSION=1.13
SWAGGER_SPECS = $(wildcard ./priv/swagger/*.json)

test/all:
	$(foreach SPEC, $(SWAGGER_SPECS), $(MAKE) test/$(basename $(notdir $(SPEC))))

test:
	$(MAKE) test/$(DEFAULT_VERSION)

priv/swagger/%.json:
	mix k8s.swagger -v $*

test/%:
	$(MAKE) priv/swagger/$*.json
	K8S_SPEC=priv/swagger/$*.json mix test
