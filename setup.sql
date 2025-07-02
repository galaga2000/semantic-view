CREATE DATABASE IF NOT EXISTS REAL_ESTATE_DB;
CREATE SCHEMA IF NOT EXISTS REAL_ESTATE;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;

USE DATABASE REAL_ESTATE_DB;
USE SCHEMA REAL_ESTATE;

CREATE or replace GIT REPOSITORY git_repo_semantic_view
api_integration = git_api_integration
origin = 'https://github.com/galaga2000/semantic-view';


-- Make sure we get the latest files
ALTER GIT REPOSITORY git_repo FETCH;
show api integrations;

current_account();
current_user();
current_database();
current_schema();

select '-a ' || current_account() || ' -u ' || current_user() || ' -d ' || current_database() || ' -s ' || current_schema();