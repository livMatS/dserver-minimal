# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'dserver'
copyright = '2024, Tjelvar S. G. Olsson, Johannes L. Hörmann, Lars Pastewka, Luis Yanes, Matthew Hartley'
author = 'Tjelvar S. G. Olsson, Johannes L. Hörmann, Lars Pastewka, Luis Yanes, Matthew Hartley'

import dserver_minimal
version = dserver_minimal.__version__
release = dserver_minimal.__version__

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinxcontrib.spelling',
    'sphinxcontrib.bibtex',
    'myst_parser'
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

# -- Extension configuration -------------------------------------------------

# spell check with sphinxcontrib.spelling
spelling_lang = 'en_US'
spelling_show_suggestions = True

# bibliography with sphinxcontrib.bibtex
bibtex_bibfiles = ['refs.bib']
bibtex_default_style = 'unsrt'
bibtex_reference_style = 'label'
