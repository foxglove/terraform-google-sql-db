mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "random" {}
mock_provider "null" {}

variables {
  project_id       = "data-api-test"
  name             = "api"
  database_version = "POSTGRES_17"
  zone             = "us-central1-a"
  tier             = "db-custom-2-7680"
  data_api_access  = "DISALLOW_DATA_API"
  read_replicas = [
    {
      zone             = "us-central1-a"
      name             = "app"
      data_api_access  = "DISALLOW_DATA_API"
      user_labels      = {}
      ip_configuration = {}
    },
    {
      zone             = "us-central1-a"
      name             = "analytics"
      data_api_access  = "ALLOW_DATA_API"
      user_labels      = {}
      ip_configuration = {}
    },
  ]
}

run "enable_data_api_only_on_selected_replica" {
  command = plan

  assert {
    condition = (
      google_sql_database_instance.default.settings[0].data_api_access != "ALLOW_DATA_API" &&
      google_sql_database_instance.replicas["api-replicaapp"].settings[0].data_api_access != "ALLOW_DATA_API" &&
      google_sql_database_instance.replicas["api-replicaanalytics"].settings[0].data_api_access == "ALLOW_DATA_API"
    )
    error_message = "Enabling the analytics replica must not enable the primary or application replica."
  }
}

run "enable_data_api_on_primary" {
  command = plan

  variables {
    data_api_access = "ALLOW_DATA_API"
    read_replicas   = []
  }

  assert {
    condition     = google_sql_database_instance.default.settings[0].data_api_access == "ALLOW_DATA_API"
    error_message = "The explicit primary setting must be passed to Cloud SQL."
  }
}
