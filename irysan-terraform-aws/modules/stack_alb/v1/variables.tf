variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where to the deploy the load balancer"
  nullable    = false
}

variable "public_subnets" {
  description = "Lists of the public subnets where to deploy the load balancer"
  type        = list(string)
  nullable    = false
}

variable "initial_certificate_arn" {
  description = "An existing cert arn to allow the creation of the https listener"
  type        = string
  nullable    = false
}

variable "create_alarms" {
  default = false
}

variable "opsgenie_endpoint" {
  type    = string
  default = "https://api.eu.opsgenie.com/v1/json/cloudwatch?apiKey="
}

variable "opsgenie_key" {
  type = string
  default = ""
}
