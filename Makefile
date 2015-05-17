DESTDIR?=/usr
COVERAGE?=/usr/bin/python-coverage

.PHONY: clean cov covhtml check install lint man bench benchshm

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  clean		=> clean all generated files"
	@echo "  cov		=> coverage report using $(COVERAGE) (use COVERAGE env to change that)"
	@echo "  covhtml	=> coverage html report"
	@echo "  man		=> build manpage"
	@echo "  test		=> run embedded tests"
	@echo "  install	=> install msrsync in $(DESTDIR)/bin (use DESTDIR env to change that)"
	@echo "  lint		=> run pylint"
	@echo "  bench		=> run benchmarks (linux only. Need root to drop buffer cache between run)"
	@echo "  benchshm	=> run benchmarks using /dev/shm (linux only. Need root to drop buffer cache between run)"

install: msrsync
	install -m 0755 msrsync $(DESTDIR)/bin

clean:
	@find . -name \*.pyc -delete
	@find . -name \*__pycache__ -delete
	@rm -rf __pycache__ || true

.check_cov:
	@$(COVERAGE) --version

.coverage: msrsync .check_cov
	@$(COVERAGE) run ./msrsync --selftest

cov: .coverage
	@$(COVERAGE) report -m

covhtml: .coverage
	@$(COVERAGE) html
	@echo "Check htmlcov/index.html (xdg-open $(shell pwd)/htmlcov/index.html)"

man:
	@true

lint:
	pylint --disable=too-many-lines,line-too-long msrsync || :

test:
	@./msrsync --selftest

bench:
	@./msrsync --bench

benchshm:
	@./msrsync --benchshm
