TEST_FILES:= $(wildcard test/*_test.rb)

.DEFAULT_GOAL:=test

Gemfile.lock: Gemfile barcelona.gemspec
	bundle install
	touch $@

.PHONY: test
test: Gemfile.lock
	@ruby -I$(PWD) $(foreach file,$(TEST_FILES),-r$(file)) -e exit
