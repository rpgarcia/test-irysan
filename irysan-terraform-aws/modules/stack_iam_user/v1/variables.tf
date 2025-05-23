variable "username" {}
variable "policies" {
  type = list(string)
  default = []
}
variable "tags" {
  type = map(string)
  default = {}
}