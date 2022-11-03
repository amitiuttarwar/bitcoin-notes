## debug: ModuleNotFound error received when trying to `import tabulate`

### how importing works
- resource: https://docs.python.org/3/reference/import.html
- packages are a special kind of module -> any module that contains a
  `__path__` attribute is considered a package
- regular packages typically implemented as a directory containing an
  `__init.py__ file