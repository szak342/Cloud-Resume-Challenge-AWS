# Cloud Resume Challenge - AWS Edition

## Introduction

Welcome to my Cloud Resume Challenge project! This repository showcases my skills in deploying a simple static website using AWS services

## Project Overview

The Cloud Resume Challenge is a project that aims to demonstrate proficiency in various AWS services by creating and deploying a resume website in the cloud. The project involves setting up a static website, securing it with SSL, and implementing continuous integration and continuous deployment (CI/CD) pipelines.

## Project Structure

- **/webpage:** Contains the source code for the static resume website.
- **/terraform:** Terraform files for provisioning the required resources.
- **/sam-app:** SAM (Serverless Application Model) application for deploying Lambda function.
- **/Tests:** Contains the unit tests for the Lambda function and website

## Technologies Used

- **AWS Services:**
  - S3 (Simple Storage Service) for hosting static website files
  - CloudFront for content delivery and SSL termination
  - ACM (AWS Certificate Manager) for managing SSL certificates
  - Route 53 for domain registration and DNS
  - DynamoDB for storing visit counter data
  - API Gateway for exposing API
  - Lambda for serverless function
  - AWS SAM for deploying Lambda function
  
- **Others::**
  - Python Pytest for testing
  - JavaScript code for connecting to API
  - Modified page template for resume
  - Terraform for provisioning AWS resources.
  - Github Actions for CI/CD pipelines.

