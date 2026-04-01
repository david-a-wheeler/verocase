# verocase: Simple Makefile to simplify checking

.PHONY: check test lint

check: lint test

lint:
	ruff check verocase.py

test:
	python3 -m unittest tests.run_tests
