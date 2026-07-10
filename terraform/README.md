# Terraform

We use [Terraform](https://www.terraform.io/) to manage our infrastructure as code. This folder contains the Terraform configuration files for the Google Cloud resources.

To apply changes made to the `.tf` files, follow these steps:

1. Download and [install Terraform](https://developer.hashicorp.com/terraform/install) on your machine.

1. Download and [install `gcloud`](https://cloud.google.com/sdk/docs/install) on your machine.

1. Connect the GitHub repository to the Google Cloud project using the [Google Cloud console](https://console.cloud.google.com/cloud-build/triggers).

1. Configure `gcloud` to use your Google Cloud project.
    ```bash
    gcloud config set project <GOOGLE-CLOUD-PROJECT-ID>
    ```
    Replace `<GOOGLE-CLOUD-PROJECT-ID>` with your Google Cloud project ID.

1. Log into `gcloud` for Google API calls (used by Terraform).
    ```bash
    gcloud auth application-default login
    ```

1. Initialize Terraform and download modules and providers (plugins) such as the Google Cloud provider.
    ```bash
    terraform init
    ```

1. Apply the Terraform configuration and create the infrastructure.
    ```bash
    terraform apply \
      -var 'google_cloud_project_id=<GOOGLE-CLOUD-PROJECT-ID>' \
      -var 'books_image_tag=<BOOKS-IMAGE-TAG>'
    ```
    Replace `<GOOGLE-CLOUD-PROJECT-ID>` with your Google Cloud project ID.

    Replace `<BOOKS-IMAGE-TAG>` with the tag of the Books Docker image. It looks like "abcde123" representing the short SHA of the commit.
