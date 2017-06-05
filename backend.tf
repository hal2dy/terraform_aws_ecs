# ----------------------------------------------------------------
# BACKEND
# ----------------------------------------------------------------

terraform { 
    backend "s3" {
        region = "ap-southeast-1"
        key = "terraform.tfstate" 
        bucket = "terraform-remote-state-test"
        lock_table = "terraform_lock_table_hung_test"
    }
}
