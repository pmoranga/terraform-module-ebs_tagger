output "aws_iam_role_arn" {
  value = "${aws_iam_role.ebs_tagger.arn}"
  description = "Created Role's ARN"
}

output "lambda_function_name" {
  value = "${aws_lambda_function.ebs_tagger.function_name}"
  description = "Name of the function created"
}

output "lambda_function_arn" {
  value = "${aws_lambda_function.ebs_tagger.arn}"
  description = "ARN of the function created"
}
