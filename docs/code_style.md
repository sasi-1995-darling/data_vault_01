# Code Style

This guide is about how we style our dbt code at FBIN Data & Analytics team.

## Purpose

Maintaining consistency in code is important, especially in a  multi-person team. Having the same standards means that code is easier to understand, which leads to:

* Make the code easier for a new engineer to on board.
* Coders make fewer mistakes.
* Foster high quality codebase, which reduces bugs.

## Basic Rules

Here are some notable code style rules and reasoning for sql, jinja, and yaml.

### Lines are Cheap, Use Multi-lines

Lines are cheap, cognitive overload isn't. Break up your code into multiple lines. It boils down to this: would you rather read 5 lines so that you can understand the code logic in 2 seconds or spend 5 seconds trying to track multiple things in one line. For example:

```sql
-- BAD!
-- This way too much information in one line for you to track.
CAST((MD5_BINARY(NULLIF(UPPER(TRIM(CAST(ID AS VARCHAR))), ''))) AS BINARY(16)) AS hub_HK
```

How many states are there in one line? By the time you get to `upper`, you are so far down the rabbit hole that you likely lost what states are set prior to a nested call? Also what is value is cast as `binary(16)`? Is it the output of `nullif` or `md5_binary`? You end counting the parentheses so that we can find the leading or trailing parenthesis.

Write clear, consistent, and well-understood code not only help your fellow engineers who may one day look or even rewrite this code, but you who may need to revisit this code 3 months later. By breaking previous code into multiple lines, we can easily move between states or function calls by going line by line while having intention to show the nested level.

```sql
-- BETTER!
cast(
    (
        md5_binary(
            nullif(
                upper(
                    trim(
                        cast(
                            id as varchar
                        )
                    )
                ), ''
            )
        )
    ) as binary(16)
) as hub_hk
```

### Avoid (or Eliminate) Nesting

The previous example is extreme as if we should always avoid nesting beyond the third level. This example has six levels of nesting. Think about reducing nesting in the code by:

* It is jinga code, so write a macro for hash function.
* Use Common Table Expression (CTE) to keep your code organized and manage states.

### Use Lowercase

This rule is perhaps a more contentious one. SQL is case insensitive but canonical sql commands (ANSI and proprietary) are usually documented in uppercase. Also, most source tables that we extract from our data sources are in uppercase. So why are we using lowercase in our code?

* dbt is a tool that reads in a high-level language like jinga and builds the actual sql code of the target database or data warehouse that we configure in the project. Hence dbt stands database build tool. So if we are not building the target code, why would we be concerned about the case.
* The problem with most sql code is they usually have a mix of uppercase and lowercase. With this setup, coders need to switch between coding in uppercase and lowercase depending on the context. Furthermore, we need to hold the shift button while typing out the code in uppercase.
* Most names are automatically translated to uppercase in Snowflake unless we enclose the names in double quotes `"`.

For these reasons, use lowercase in the following areas:

* Model filenames
* sql code ie. commands, clause, etc
* Names - use lowercase as much as possible. There are cases where we need a literal value, enclose the value with double quotes `"`.

```sql
-- BETTER!
select id, name, address from customers
```

A model file should have this name `customers.yml`.

```yaml
# BAD!
version: 2

models:
  - name: CUSTOMERS
    description: Our customers
    columns:
      - name: ID
      - name: NAME  
      - name: ADDRESS
```

Let's use the lowercase in the identifier names.

```yaml
# BETTER!
version: 2

models:
  - name: customers
    # If there are multi-word text, enclose that string with single quotes.
    description: 'Our customers'
    columns:
      - name: id
      - name: name  
      - name: address
```

### Snake Case

Schema, table, and column names should be in `snake_case`.

### Indentation

Indents should be 4 spaces for sql and jinja, and 2 spaces for yaml.

### Length of Lines

Lines of code (sql, yaml, and Python) should be no longer than 120 characters.

## Code Style in Data Vault

Many of the standards in this section is taken from [dbt Labs best practices](https://docs.getdbt.com/best-practices/how-we-style/0-how-we-style-our-dbt-projects) with inputs from phData and Data Platforms leads.

### Workflow

* As Raw Vaults get built, when it comes to projecting source data into Satellite tables, in context of data from Oracle EBS, there can be challenges surface around similar named columns adjoined from multiple tables. To streamline this data's unification into a singular Satellite table, there should be a prefix before these column names so we can categorize the source of these similar named columns in the sql queries. This will help in:
  * Help in discovery of these columns with the source data.
  * Help attain Data Vault standards of keeping the Raw Vault as true to the source as possible.
  * Ease the development of Info Mart queries whilst referring to the Raw data. Column aliases should be set in Info Marts.

### Data Sources

* Source data tables that contain columns with 0% population should NOT be ingested into the Staging -> Raw Vault tables. This introduces overhead, unused data and potential inefficiencies in the ingestion process of no business value.
* When it comes to cloning Snowflake objects for dbt project purposes, the general direction is to use the instructions listed here in order to streamline data pushes and management, for development purposes, by dbt Cloud.

### Names

* dbt models should be singular, eg. `customer`, `order`, `product`.
* Each dbt base model should keep the original column names and column order of source table except business key fields should be brought to the top of the SELECT. 
* Add the ingestion load timestamp field (for Fivetran it is `_fivetran_synced`) under the source table’s `last_update_date` field. Use underscores for naming dbt models; avoid dots. This means `snake_case`.
* Avoid the use abbreviations or aliases. There are exceptions: if a abbreviation is commonly used as a business nomenclature, then by all means use it.
* CTE code blocks should be named with a `cte_<short-name>` prefix in the stage and base layer where SQL code resides.
* When working in dbt Cloud use the Format button in order to validate and format your yaml files automatically.

### Types

* Boolean value should be prefixed with `is_` or `has_`.
* Timestamp columns should be named `<event>_at` (for example, `created_at`) and should be in UTC (normalize to UTC if possible). If a different time zone is used, this should be indicated with a suffix `created_at_pt`.
* Dates should be past tense and named `<event>_date`. For example, `created_date`.

## SQLFluff

We use sqlfluff as our linter to maintain our style rules automatically. A linter allows us to automate the style rules objectively and scale the operations.

SQLFluff uses the following files:

* `.sqlfluff` in the root project directory contains all configurations and rules to be applied to the sql code. 
* `.sqlignore`, a file similar to `.gitignore` use to control which files are and are not linted.

### Ignoring Warnings

Individual lines can be ignored by adding `-- noqa` to the end of a sql line.

```sql
-- Ignore all errors.
select  1 from tBl;    -- noqa

-- Ignore specific rules CP02 and CP03.
select  1 from tBl;    -- noqa: CP02,CP03

-- Ignore all parsing errors.
select 1 from tBl;      -- noqa: PRS
```

## References

[SQLFluff Rules](https://docs.sqlfluff.com/en/stable/rules.html)
[dbt Labs Best Practices](https://docs.getdbt.com/best-practices/how-we-style/0-how-we-style-our-dbt-projects)