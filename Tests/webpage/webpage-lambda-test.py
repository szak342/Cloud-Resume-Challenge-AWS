import pytest
import requests
from requests_html import HTMLSession

url = ["https://krzysztofszadkowski.com", "https://www.krzysztofszadkowski.com"]



def test_lambda_on_webpage():
    for site in url:
        r = requests.get(site)
        assert r.status_code == 200


def get_org_counter(url):
    session = HTMLSession()
    r = session.get(url)
    r.html.render(sleep=1)
    y = r.html.find("span#show", first=True)
    return int(y.text)

def test_visit_counter_on_webpage():
    url = "https://krzysztofszadkowski.com"

    org_counter = get_org_counter(url)

    counter = org_counter

    for i in range(2):
        session = HTMLSession()
        r = session.get(url)
        r.html.render(sleep=1)
        x = r.html.find("span#show", first=True)
        counter += int(x.text)

    assert org_counter < counter