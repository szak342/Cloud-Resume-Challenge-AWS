import json
import os
import pytest
import sys

path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../') + 'webpage/')
sys.path.append(path)

files = ['css', 'img', 'js', 'scss', 'vendor', 'gulpfile.js', 'index.html', 'LICENSE', 'package.json']

files = sorted(files)

def test_api_link():
    assert True

def test_root_folder():
    output = os.listdir(path)
    output = sorted(output)
    assert output == files




    

