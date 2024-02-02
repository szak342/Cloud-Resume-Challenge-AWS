import pytest
import requests
from requests_html import HTMLSession

DOMAIN_NAME = os.environ["DOMAIN_NAME"]

urls = [f"https://{DOMAIN_NAME}", f"https://www.{DOMAIN_NAME}"]


def test_lambda_on_webpage():
    for site in urls:
        r = requests.get(site)
        assert r.status_code == 200


def get_org_counter(url):
    session = HTMLSession()
    r = session.get(url)
    r.html.render(sleep=3)
    y = r.html.find("span#show", first=True)
    return int(y.text)

def test_visit_counter_on_webpage():

    org_counter = get_org_counter(urls[0])

    counter = org_counter

    for i in range(2):
        session = HTMLSession()
        r = session.get(url)
        r.html.render(sleep=3)
        x = r.html.find("span#show", first=True)
        counter += int(x.text)

    assert org_counter < counter