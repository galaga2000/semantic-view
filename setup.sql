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

use database real_estate_db;
use schema real_estate;
WITH county_map AS (
  SELECT
    geo_id,
    geo_name,
    related_geo_id,
    related_geo_name
  FROM
    real_estate.geography_relationships
  WHERE
    geo_name = 'Phoenix-Mesa-Chandler, AZ Metro Area'
    AND related_level = 'County'
),
gross_income_data AS (
  SELECT
    geo_id,
    geo_name AS msa,
    date,
    SUM(value) AS gross_income_inflow
  FROM
    real_estate.irs_origin_destination_migration_timeseries AS ts
    JOIN county_map ON county_map.related_geo_id = ts.to_geo_id
  WHERE
    ts.variable_name = 'Adjusted Gross Income'
  GROUP BY
    geo_id,
    msa,
    date
),
home_price_data AS (
  SELECT
    LAST_DAY(date, YEAR) AS end_date,
    AVG(value) AS home_price_index
  FROM
    real_estate.fhfa_house_price_timeseries AS ts
    JOIN real_estate.fhfa_house_price_attributes AS att ON ts.variable = att.variable
  WHERE
    geo_id IN (
      SELECT
        geo_id
      FROM
        county_map
    )
    AND att.index_type = 'purchase-only'
    AND att.seasonally_adjusted = TRUE
  GROUP BY
    end_date
)
SELECT
  gid.msa,
  gid.date,
  gid.gross_income_inflow,
  hpi.home_price_index
FROM
  gross_income_data AS gid
  JOIN home_price_data AS hpi ON gid.date = hpi.end_date
ORDER BY
  gid.date