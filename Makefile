PACKAGES = notesserver notesapi
.PHONY: requirements

include .travis/docker.mk

validate: test.requirements test

test: clean
	./manage.py test --settings=notesserver.settings.test --with-coverage --with-ignore-docstrings \
		--exclude-dir=notesserver/settings --cover-inclusive --cover-branches \
		--cover-html --cover-html-dir=build/coverage/html/ \
		--cover-xml --cover-xml-file=build/coverage/coverage.xml --verbosity=2 \
		$(foreach package,$(PACKAGES),--cover-package=$(package)) \
		$(PACKAGES)

pii_check: test.requirements pii_clean
	code_annotations django_find_annotations --config_file .pii_annotations.yml --report_path pii_report/ \
		--lint --report --coverage

run:
	./manage.py runserver 0.0.0.0:8120

shell:
	./manage.py shell

clean:
	coverage erase

pii_clean:
	rm -rf pii_report
	mkdir -p pii_report

quality:
	pep8 --config=.pep8 $(PACKAGES)
	pylint $(PACKAGES)

diff-coverage:
	diff-cover build/coverage/coverage.xml --html-report build/coverage/diff_cover.html

diff-quality:
	diff-quality --violations=pep8 --html-report build/coverage/diff_quality_pep8.html
	diff-quality --violations=pylint --html-report build/coverage/diff_quality_pylint.html

coverage: diff-coverage diff-quality

create-index:
	python manage.py rebuild_index

migrate:
	python manage.py migrate --noinput

static:  # provide the static target for devstack's tooling.
	@echo "The notes service does not need staticfiles to be compiled. Skipping."

requirements:
	pip install -q -r requirements/base.txt --exists-action=w

test.requirements: requirements
	pip install -q -r requirements/test.txt --exists-action=w

develop: test.requirements
