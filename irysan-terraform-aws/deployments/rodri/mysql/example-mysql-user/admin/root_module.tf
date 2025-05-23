data "onepassword_item" "password" {
  vault = "1pass_vault"
  uuid  = "1pass_uuid"
}

module "root_module" {
  source = "./modules/stack_mysql_user/v1"

  username  = "admin_mysql"
  password           = data.onepassword_item.password.password
  
  grants = {
    grant1 = {
      database    = "admin"
      host        = "%"
      privileges  = ["ALL"]
    }
  }
}