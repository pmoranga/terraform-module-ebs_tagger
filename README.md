# EBS Tagger

Useful for tagging volumes when they are created without desired tags, as examples as EBS's from  Auto Scaling Group (ASG) instaces and from EKS pvc with EBS backend.

## Usage

```
module "ebs_tagger" {
  source = "github.com/pmoranga/terraform-module-ebs_tagger?ref=1.0"

  tags = {
    "approval" = "joe@example.com",
    "owner"    = "awsteam"
    "cc"       = "3423"
  }

  enforce_tags = {
    "approval" = "joe@example.com",
    "owner"    = "Ops"
    "cc"       = "3423"
  }
}

output "lambda_arn" {
  description = "ARN from EBS Tagger lambda"
  value = "${module.ebs_tagger.arn}"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
|enforce_tags|Tags to be added to resources by Lambda|map(string)||yes|
|tags|Tags for the lambda resources itself |map(string)|{}|no|

## Outputs

| Name | Description |
|------|-------------|
|aws_iam_role_arn| ARN of Role created|
|lambda_function_arn|ARN of the Lambda function created|
|lambda_function_name|Lambda function name created|

## License

See LICENSE file 
