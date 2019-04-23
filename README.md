# NERC Arctic Office Projects Manager

Management application for projects in the NERC Arctic Office Projects Database

...

## Setup

```shell
$ git clone https://gitlab.data.bas.ac.uk/web-apps/arctic-office-projects-manager.git
$ cd arctic-office-projects-manager
```

### Terraform remote state

For environments using Terraform, state information is stored remotely as part of 
[BAS Terraform Remote State](https://gitlab.data.bas.ac.uk/WSF/terraform-remote-state) project.

Remote state storage will be automatically initialised when running `terraform init`, with any changes automatically 
saved to the remote (AWS S3) backend, there is no need to push or pull changes.

#### Remote state authentication

Permission to read and/or write remote state information for this project is restricted to authorised users. Contact
the [BAS Web & Applications Team](mailto:servicedesk@bas.ac.uk) to request access.

See the [BAS Terraform Remote State](https://gitlab.data.bas.ac.uk/WSF/terraform-remote-state) project for how these
permissions to remote state are enforced.

### Local development

Docker and Docker Compose are required to setup a local development environment of this application.

#### Local development - Docker Compose

If you have access to the [BAS GitLab instance](https://gitlab.data.bas.ac.uk), you can pull the application Docker 
image from the BAS Docker Registry. Otherwise you will need to build the Docker image locally.

```shell
# If you have access to gitlab.data.bas.ac.uk
$ docker login docker-registry.data.bas.ac.uk
$ docker-compose pull
# If you don't have access
$ docker-compose build
```

Copy `.env.example` to `.env` and edit the file to set at least any required (uncommented) options.

To run the application using the Flask development server (which reloads automatically if source files are changed):

```shell
$ docker-compose up
```

To run other commands against the Flask application (such as [Integration tests](#integration-tests)):

```shell
# in a separate terminal to `docker-compose up`
$ docker-compose run app flask [command]
# E.g.
$ docker-compose run app flask test
# List all available commands
$ docker-compose run app flask
```

#### Local development - auth

See 
[these instructions](https://gitlab.data.bas.ac.uk/web-apps/flask-extensions/flask-azure-oauth#registering-an-application-in-azure)
for how to register the application as a service.

* use `BAS NERC Arctic Office Projects Manager` as the application name
* choose *Accounts in this organizational directory only* as the supported account type
* do not enter a redirect URL
* from the *API permissions* section of the registered application's permissions page:
    * remove the default 'User.Read' permission
* from the manifest page of the registered application:
    * change the `accessTokenAcceptedVersion` property from `null` to `2`
    * add an item, `api://[appId]`, to the `identifierUris` array, where `[appId]` is the value of the `appId` property
    * add these items to the `appRoles` property [1]

**Note:** It is not yet possible to register clients programmatically due to limitations with the Azure CLI and Azure
provider for Terraform.

**Note:** This describes how to register this API itself as a *service*, see the 
[Registering API clients](#registering-api-clients) section for how to register a *client* of this API.

Set the `AZURE_OAUTH_TENANCY`, `AZURE_OAUTH_APPLICATION_ID` and `AZURE_OAUTH_CLIENT_APPLICATION_IDS` options in the 
local `.env` file.

[1] Application roles for the BAS NERC Arctic Office Projects Manager:

**Note:** Replace `[uuid]` with a UUID.

```json
{
  "appRoles": []
}
```

### Staging

Docker, Docker Compose and Terraform are required to setup the staging environment of this application.

Access to the *BAS Web & Applications* Heroku account is needed to setup the staging environment of this application.

**Note:** Make sure the `HEROKU_API_KEY` and `HEROKU_EMAIL` environment variables are set within your local shell.

#### Staging - Heroku
 
```shell
$ cd provisioning/terraform
$ docker-compose run terraform
$ terraform init
$ terraform apply
```

This will create a Heroku Pipeline, containing staging and production applications.

Non-sensitive config vars should be set using Terraform.

Once running, add the appropriate configuration to the BAS General Load Balancer

##### Staging - Heroku sensitive config vars

Config vars should be set [manually](https://dashboard.heroku.com/apps/bas-arctic-projects-app-stage/settings) for 
sensitive settings. Other config vars should be set in Terraform.

| Config Var    | Config Value                        | Description                                         |
| ------------- | ----------------------------------- | --------------------------------------------------- |
| `SENTRY_DSN`  | *Available from Sentry*             | Identifier for application in Sentry error tracking |

#### Staging - auth

Use the same *BAS NERC Arctic Office Projects Manager Testing* application registered in the 
[Auth sub-section in the local development section](#local-development-auth).

### Production

Docker, Docker Compose and Terraform are required to setup the production environment of this application.

Access to the *BAS Web & Applications* Heroku account is needed to setup the staging environment of this application.

**Note:** Make sure the `HEROKU_API_KEY` and `HEROKU_EMAIL` environment variables are set within your local shell.

#### Production - Heroku

See the [Heroku sub-section in the staging section](#staging-heroku) for general instructions.

##### Production - Heroku sensitive config vars

Config vars should be set [manually](https://dashboard.heroku.com/apps/bas-arctic-projects-app-prod/settings) for 
sensitive settings. Other config vars should be set in Terraform.

| Config Var    | Config Value                        | Description                                         |
| ------------- | ----------------------------------- | --------------------------------------------------- |
| `SENTRY_DSN`  | *Available from Sentry*             | Identifier for application in Sentry error tracking |

#### Production - auth

Using the [Auth sub-section in the local development section](#local-development-auth), register an additional Azure
application with these differences:

* tenancy: *NERC*
* name: *BAS NERC Arctic Office Projects Manager*

## Development

This application is developed as a Flask application.

Environments and feature flags are used to control which elements of this application are enabled in different 
situations. For example in the development environment, Sentry error tracking is disabled and Flask's debug mode is on.

New features should be implemented with appropriate [Configuration](#configuration) options available. Sensible defaults 
for each environment, and if needed feature flags, should allow end-users to fine tune which features are enabled.

Ensure `.env.example` is kept up-to-date if any configuration options are added or changed.

Also ensure:

* [Integration tests](#integration-tests) are updated to prevent future regression

### Code Style

PEP-8 style and formatting guidelines must be used for this project, with the exception of the 80 character line limit.

[Flake8](http://flake8.pycqa.org/) is used to ensure compliance, and is ran on each commit through 
[Continuous Integration](#continuous-integration).

To check compliance locally:

```shell
$ docker-compose run app flake8 . --ignore=E501
```

### Dependencies

Python dependencies should be defined using Pip through the `requirements.txt` file. The Docker image is configured to
install these dependencies into the application image for consistency across different environments. Dependencies should
be periodically reviewed and updated as new versions are released.

To add a new dependency:

```shell
$ docker-compose run app ash
$ pip install [dependency]==
# this will display a list of available versions, add the latest to `requirements.txt`
$ exit
$ docker-compose down
$ docker-compose build
```

If you have access to the BAS GitLab instance, push the rebuilt Docker image to the BAS Docker Registry:

```shell
$ docker login docker-registry.data.bas.ac.uk
$ docker-compose push
```

### Dependency vulnerability scanning

To ensure the security of this API, all dependencies are checked against 
[Snyk](https://app.snyk.io/org/antarctica/project/782452d6-430e-4a97-a75f-75366edbf9ab/history) for vulnerabilities. 

**Warning:** Snyk relies on known vulnerabilities and can't check for issues that are not in it's database. As with all 
security tools, Snyk is an aid for spotting common mistakes, not a guarantee of secure code.

Some vulnerabilities have been ignored in this project, see `.snyk` for definitions and the 
[Dependency exceptions](#dependency-vulnerability-exceptions) section for more information.

Through [Continuous Integration](#continuous-integration), on each commit current dependencies are tested and a snapshot
uploaded to Snyk. This snapshot is then monitored for vulnerabilities.

#### Dependency vulnerability exceptions

This project contains known vulnerabilities that have been ignored for a specific reason.

* [Py-Yaml `yaml.load()` function allows Arbitrary Code Execution](https://snyk.io/vuln/SNYK-PYTHON-PYYAML-42159)
    * currently no known or planned resolution
    * indirect dependency, required through the `bandit` package
    * severity is rated *high*
    * risk judged to be *low* as we don't use the Yaml module in this application
    * ignored for 1 year for re-review

### Static security scanning

To ensure the security of this API, source code is checked against [Bandit](https://github.com/PyCQA/bandit) for issues 
such as not sanitising user inputs or using weak cryptography. 

**Warning:** Bandit is a static analysis tool and can't check for issues that are only be detectable when running the 
application. As with all security tools, Bandit is an aid for spotting common mistakes, not a guarantee of secure code.

Through [Continuous Integration](#continuous-integration), each commit is tested.

To check locally:

```shell
$ docker-compose run app bandit -r .
```

### Logging

In a request context, the default Flask log will include the URL and [Request ID](#request-ids) of the current request.
In other cases, these fields are substituted with `NA`.

**Note:** When not running in Flask Debug mode, only messages with a severity of warning of higher will be logged.

### Debugging

To debug using PyCharm:

* *Run* -> *Edit Configurations*
* *Add New Configuration* -> *Python*

In *Configuration* tab:

* Script path: `[absolute path to project]/manage.py`
* Python interpreter: *Project interpreter* (*app* service in project Docker Compose)
* Working directory: `[absolute path to project]`
* Path mappings: `[absolute path to project]=/usr/src/app`

## Testing

### Integration tests

This project uses integration tests to ensure features work as expected and to guard against regressions and 
vulnerabilities.

The Python [UnitTest](https://docs.python.org/3/library/unittest.html) library is used for running tests using Flask's 
test framework. Test cases are defined in files within `tests/` and are automatically loaded when using the 
`test` Flask CLI command.

Tests are automatically ran on each commit through [Continuous Integration](#continuous-integration).

To run tests manually:

```shell
$ docker-compose run -e FLASK_ENV=testing app flask test
```

To run tests using PyCharm:

* *Run* -> *Edit Configurations*
* *Add New Configuration* -> *Python Tests* -> *Unittests*

In *Configuration* tab:

* Script path: `[absolute path to project]/tests`
* Python interpreter: *Project interpreter* (*app* service in project Docker Compose)
* Working directory: `[absolute path to project]`
* Path mappings: `[absolute path to project]=/usr/src/app`

**Note:** This configuration can be also be used to debug tests (by choosing *debug* instead of *run*).

### Continuous Integration

All commits will trigger a Continuous Integration process using GitLab's CI/CD platform, configured in `.gitlab-ci.yml`.

This process will run the application [Integration tests](#integration-tests).

Pip dependencies are also [checked and monitored for vulnerabilities](#dependency-vulnerability-scanning).

## Deployment

### Deployment - Local development

In development environments, the App is ran using the Flask development server through the project Docker container.

Code changes will be deployed automatically by Flask reloading the application where a source file changes.

See the [Local development](#local-development) sub-section in the [Setup](#setup) section for more information.

### Deployment - Staging

The staging environment is deployed on [Heroku](https://heroku.com) as an 
[application](https://dashboard.heroku.com/apps/bas-arctic-projects-app-stage) within a 
[pipeline](https://dashboard.heroku.com/pipelines/fef94cce-ef52-469b-9b3c-363f4e381aa6) in the `webapps@bas.ac.uk` 
shared account.

This Heroku application uses their 
[container hosting](https://devcenter.heroku.com/articles/container-registry-and-runtime) option running a Docker image 
built from the application image (`./Dockerfile`) with the application source included and development related features
disabled. This image (`./Dockerfile.heroku`) is built and pushed to Heroku on each commit to the `master` branch 
through [Continuous Deployment](#continuous-deployment).

An additional Docker image (`./Dockerfile.heroku-release`) is built to act as a 
[Release Phase](https://devcenter.heroku.com/articles/release-phase) for the Heroku application. This image is based on 
the Heroku application image and includes an additional script for running [Database migrations](#database-migrations). 
Heroku will run this image automatically before each deployment of this project.

### Deployment - Production

The production environment is deployed in the same way as the [Staging environment](#deployment-staging), using an
different Heroku [application](https://dashboard.heroku.com/apps/bas-arctic-projects-app-prod) as part of the same 
pipeline.

Deployments are also made through [Continuous Deployment](#continuous-deployment) but only on tagged commits.

### Continuous Deployment

A Continuous Deployment process using GitLab's CI/CD platform is configured in `.gitlab-ci.yml`. This will:

* build a Heroku specific Docker image using a 'Docker In Docker' (DIND/DND) runner and push this image to Heroku
* create a Sentry release and associated deployment in the appropriate environment

This process will deploy changes to the *staging* environment on all commits to the *master* branch.

This process will deploy changes to the *production* environment on all tagged commits.

## Release procedure

### At release

For all releases:

1. create a release branch
2. if needed, build & push the Docker image
3. close release in `CHANGELOG.md`
4. push changes, merge the release branch into `master` and tag with version

The application will be automatically deployed into production using [Continuous Deployment](#continuous-deployment).

## Feedback

The maintainer of this project is the BAS Web & Applications Team, they can be contacted at: 
[servicedesk@bas.ac.uk](mailto:servicedesk@bas.ac.uk).

## Issue tracking

This project uses issue tracking, see the 
[Issue tracker](https://gitlab.data.bas.ac.uk/web-apps/arctic-office-projects-manager/issues) for more 
information.

**Note:** Read & write access to this issue tracker is restricted. Contact the project maintainer to request access.

## License

© UK Research and Innovation (UKRI), 2019, British Antarctic Survey.

You may use and re-use this software and associated documentation files free of charge in any format or medium, under 
the terms of the Open Government Licence v3.0.

You may obtain a copy of the Open Government Licence at http://www.nationalarchives.gov.uk/doc/open-government-licence/
