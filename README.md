# sql-quality-monitor
Monitors MS SQL Servers for database changes and quality metrics by only querying SQL Server and database metadata.


## Why is this needed?
In corporate environments, development and operations teams may face challenges maintaining their application and database infrastructure as well as their data pipelines.  Over time, a number of problems and technical debt accumulate and the following issues may be present: 

- data stops being updated in tables
    - data pipeline stops running
    - application services stops running
- data keeps being updated but in unusual patterns
    - table growth rate changes
    - data is deleted from table
    - data pipeline drops data from table for brief periods
    - update frequency changes
- changes in table schema cause upstream/downstream problems:
    - columns are added/removed
    - data type is changed
- Databases and tables are no longer being used:
    - applications were decommissionned but databases remain
    - databases and tables were created but never ended-up being used or were only used temporarily
    - unknown dead/unused databases that can to be removed/decommisionned
    - unknown applications/users for active databases 

Tooling is available to monitor SQL server metrics for identifying performance issues and help database administrators maintain SQL Server and their databases. However,    

## Quality Metrics being Monitored
In order to help troubleshoot the issues above, SQL-Quality-Monitor queries MS SQL database servers metadata for the following aspects:

- Database "design"
    - Schema Changes
- Data Freshness
    - Time since tables were last updated
    - Time since tables were last accessed
- Data Volume
    - Number of rows in tables (and change rate) 
- Data Usefulness (Monitor last access to DB and Tables)
    - Users
    - Applications
    - Remote clients/servers

## What it NOT designed for
SQL-Quality-Monitor is not meant as a replacement for infrastructure monitoring or data governance tools.  As such, it's not designed to perform the following:

- Monitor SQL Server administration tasks
    - monitor backups
    - monitor jobs
    - identify long running queries
    - identify query waits and other collisions 
- Scan Data in tables for data quality issues
    - missing/incomplete data
    - late row updates
    - data range analysis
    - data conformity with business rules
    - outlier and pattern analysis
- Scan object definitions for Data lineage
    - Table, Views, Stored procedures and Field definition/usage
    - Report (to identify impact of data issues)
- Data Catalog
    - Documentation of what tables and fields are used for
- Integrate with Machine learning 
    - Automated Rules for issue detection
    - Automated data lineage 
- Integrate with 3rd party services for
    - Incident Management

A number of commercial offerings are available to address the elements above. 
SQL-Quality-Monitor can be used by Operations and Development teams to increase their data quality and data pipeline monitoring maturity and help them identify the requirements for such commercial tools. 


## High Level Architecture

SQL Quality Monitor consists of the following components: 
- MS SQL database to store configuration and monitoring results.
- QMon CLI to configure the system.
- QMon service the list of MS SQL database servers to fetch the metadata to collect from.
- [Grafana](https://grafana.com/oss/grafana/) presents dashboards and reports. 

``` mermaid
flowchart LR
    S1[MS SQL Server 1]
    S2[MS SQL Server 2]
    S3[MS SQL Server 3]

    M1[QMon Service]
    M2[QMon CLI]
    D1[QualityMonitor DB]
    G1[Grafana Dashboards]
    
    S1 --> M1
    S2 --> M1
    S3 --> M1

    subgraph "Server 1"
    S1
    end
    
    subgraph "Server 2"
    S2
    end

    subgraph "Server 3"
    S3
    end

    subgraph "SQL Quality Monitor" 
    M1 --> D1 --> G1
    M2 --> D1
    end

```

## Installation
Download the latest release.

### Install Database

Using [SSMS](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms), run the install script from the database folder to create the database.  Note that you need to login with a user with dbadmin role in order to create the database.

### Initialize Database

### Install Service

### Install Grafana

### Configure Grafana Datasource

### Install Grafana dashboards

## Upgrading
- Download the latest release.
- Using [SSMS](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms), run the upgrade script from the database folder to update the database.  Note that you need to login with a user with dbadmin role in order to modify the database.
- Stop the Windows Service if it was installed to run as a service
- Replace the CLI/Service executable files
- Start the Windows Service if it was installed to run as a service


## Uninstalling

- Remove Windows service if it was installed to run as a service
- Using [SSMS](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms), detatch the database from the server.  Note that you need to login with a user with dbadmin role in order to perform this operation.
- Delete database files
- Delete CLI/Service executable files
- Delete CLI/Service config files
- Remove Grafana if desired/needed 

## Supported Platforms

### Monitored Servers
Queries used by the QMon Service to collect metadata were tested with the following SQL Server versions:
- MS SQL Server 2014
- MS SQL Server 2016
- MS SQL Server 2017
- MS SQL Server 2019
- MS SQL Server 2022

### Hosting Server
The QualityMonitor Databases uses System Version Tables which were introduced in MS SQL Server 2016.