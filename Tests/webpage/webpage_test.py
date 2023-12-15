import json
import os
import pytest
import sys

path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../') + 'webpage/')
sys.path.append(path)

files = ['img', 'index.html', 'script.js', 'styles.css']
images = ["achievement.png", "AWSCCP.png", "AWSCDA.png", "AWSCSA.png", "email.png", "github.png", "gps.png", "linkedin.png"]

def test_api_link():
    assert True

def test_root_folder():
    output = os.listdir(path)
    assert output == files

def test_img_folder():
    output = os.listdir(f"{path}/img")
    assert output == images



    

