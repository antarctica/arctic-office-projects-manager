#
# This file is used to define compute resources for applications

# Pipeline
#
# This resource relies on the Heroku Terraform provider being previously configured.
#
# Heroku source: https://devcenter.heroku.com/articles/pipelines
# Terraform source: https://www.terraform.io/docs/providers/heroku/r/pipeline.html
resource "heroku_pipeline" "bas-arctic-office-projects-app" {
  name = "bas-arctic-office-projects-app"
}

# Staging stage
#
# This resource relies on the Heroku Terraform provider being previously configured.
#
# Heroku source: https://devcenter.heroku.com/articles/how-heroku-works#defining-an-application
# Terraform source: https://www.terraform.io/docs/providers/heroku/r/app.html
resource "heroku_app" "bas-arctic-office-projects-app-stage" {
  name   = "bas-arctic-projects-app-stage"
  region = "eu"

  config_vars {
    AZURE_OAUTH_TENANCY                   = "d14c529b-5558-4a80-93b6-7655681e55d6"
    AZURE_OAUTH_APPLICATION_ID            = "9657cd94-0a8d-4e8b-b134-3d695e2bdc5f"
    AZURE_OAUTH_NERC_ARCTIC_OFFICE_SCOPES = "api://2b3f5c55-1a7d-4e26-a9a7-5b56b0f612f1/.default"
  }
}

# # Production stage
# #
# # This resource relies on the Heroku Terraform provider being previously configured.
# #
# # Heroku source: https://devcenter.heroku.com/articles/how-heroku-works#defining-an-application
# # Terraform source: https://www.terraform.io/docs/providers/heroku/r/app.html
# resource "heroku_app" "bas-arctic-office-projects-app-prod" {
#   name   = "bas-arctic-projects-app-prod"
#   region = "eu"

#   config_vars {
#     AZURE_OAUTH_TENANCY                      = "x"
#     AZURE_OAUTH_APPLICATION_ID               = "x"
#    AZURE_OAUTH_NERC_ARCTIC_OFFICE_SCOPES     = "X"
#   }
# }

# Staging dyno
#
# This resource implicitly depends on the 'heroku_app.bas-arctic-office-projects-app-stage' resource.
# This resource relies on the Heroku Terraform provider being previously configured.
#
# Heroku source: https://devcenter.heroku.com/articles/dyno-types
# Terraform source: https://www.terraform.io/docs/providers/heroku/r/formation.html
resource "heroku_formation" "bas-arctic-office-projects-app-stage" {
  app      = "${heroku_app.bas-arctic-office-projects-app-stage.name}"
  type     = "web"
  quantity = 1
  size     = "free"
}

# # Production dyno
# #
# # This resource implicitly depends on the 'heroku_app.bas-arctic-office-projects-app-prod' resource.
# # This resource relies on the Heroku Terraform provider being previously configured.
# #
# # Heroku source: https://devcenter.heroku.com/articles/dyno-types
# # Terraform source: https://www.terraform.io/docs/providers/heroku/r/formation.html
# resource "heroku_formation" "bas-arctic-office-projects-app-prod" {
#   app      = "${heroku_app.bas-arctic-office-projects-app-prod.name}"
#   type     = "web"
#   quantity = 1
#   size     = "hobby"
# }

# Staging pipeline stage
#
# This resource implicitly depends on the 'heroku_pipeline.bas-arctic-office-projects-app' resource.
# This resource implicitly depends on the 'heroku_app.bas-arctic-office-projects-app-stage' resource.
# This resource relies on the Heroku Terraform provider being previously configured.
#
# Heroku source: https://devcenter.heroku.com/articles/pipelines#adding-apps-to-a-pipeline
# Terraform source: https://www.terraform.io/docs/providers/heroku/r/pipeline_coupling.html
resource "heroku_pipeline_coupling" "bas-arctic-office-projects-app-stage" {
  app      = "${heroku_app.bas-arctic-office-projects-app-stage.name}"
  pipeline = "${heroku_pipeline.bas-arctic-office-projects-app.id}"
  stage    = "staging"
}

# # Production pipeline stage
# #
# # This resource implicitly depends on the 'heroku_pipeline.bas-arctic-office-projects-app' resource.
# # This resource implicitly depends on the 'heroku_app.bas-arctic-office-projects-app-prod' resource.
# # This resource relies on the Heroku Terraform provider being previously configured.
# #
# # Heroku source: https://devcenter.heroku.com/articles/pipelines#adding-apps-to-a-pipeline
# # Terraform source: https://www.terraform.io/docs/providers/heroku/r/pipeline_coupling.html
# resource "heroku_pipeline_coupling" "bas-arctic-office-projects-app-prod" {
#   app      = "${heroku_app.bas-arctic-office-projects-app-prod.name}"
#   pipeline = "${heroku_pipeline.bas-arctic-office-projects-app.id}"
#   stage    = "production"
# }

