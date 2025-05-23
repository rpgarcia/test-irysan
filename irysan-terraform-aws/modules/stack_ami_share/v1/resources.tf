locals {
  composite_variable = flatten([for region, value in var.share_config:
    flatten([for ami, accounts in value:
      [for account in accounts:
          {
            "region" = region
            "ami" = ami
            "account" = account
          }
      ]
    ])
  ])
}

resource "aws_ami_launch_permission" "ami" {
  for_each =  { for index, record in local.composite_variable : index => record }

  image_id   = each.value.ami
  account_id = each.value.account
}
