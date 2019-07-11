variable "tags" {
  default = {}
  type = "map"
  description = "Tags for the lambda resources itself"
}

variable "enforce_tags" {
  type = "map"
  description = "Tags to be added to resources by Lambda"
}
