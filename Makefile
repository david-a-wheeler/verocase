# verocase: Simple Makefile to simplify checking

.PHONY: verify test lint typecheck

verify: lint typecheck test

lint:
	ruff check verocase.py

typecheck:
	pyright verocase.py

test:
	python3 -m unittest tests.run_tests
