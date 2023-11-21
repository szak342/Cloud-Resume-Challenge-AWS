name: Website
#test

on:
  push:
    branches: [ "developer", "main" ]
    paths:
      - webpage/**
  pull_request:
    branches: [ "developer", "main" ]
    paths:
      - webpage/**

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Set up Python 3.11
      uses: actions/setup-python@v3
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pytest
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
#    - name: Test with pytest
#      run: |
#        pytest
    - name: Checkout
      uses: actions/checkout@v3
    - name: load variables from file
      run: |
        source config
        echo $s3bucket
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: eu-west-1
    - name: echo s3bucket
      run: echo $s3bucket
    - name: Sync files with s3 bucket
      run: aws s3 sync build s3://${s3bucket} --delete