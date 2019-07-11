

data "aws_iam_policy_document" "ebs_tagger_assume_role_policy" {
  statement {
    sid = ""
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "ebs_tagger" {
  name = "ebs_tagger"

  assume_role_policy = "${data.aws_iam_policy_document.ebs_tagger_assume_role_policy.json}"
}

data "aws_iam_policy_document" "ebs_tagger_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [ "arn:aws:logs:*:*:*" ]
  }
  statement {
    effect = "Allow"
    actions = [
        "ec2:DescribeVolumes",
        "ec2:CreateTags",
        "ec2:DescribeTags"
    ]
    resources = [ "*" ]
  }
}

resource "aws_iam_policy" "ebs_tagger" {
  name        = "ebs_tagger"
  description = "Policy for ebs_tagger lambda"

  policy =  "${data.aws_iam_policy_document.ebs_tagger_policy.json}"
}

resource "aws_iam_role_policy_attachment" "ebs_tagger_role_policy_attachment" {
  role       = "${aws_iam_role.ebs_tagger.name}"
  policy_arn = "${aws_iam_policy.ebs_tagger.arn}"
}

# lambda functions have to be zip'ed up
data "archive_file" "ebs_tagger_zip" {
  type        = "zip"
  source_file  = "${path.module}/lambda.py"
  output_path = "/tmp/ebs_tagger.zip"
}

# create the lambda function
resource "aws_lambda_function" "ebs_tagger" {
  function_name    = "ebs_tagger"
  runtime          = "python2.7"
  handler          = "lambda.ebs_tagger_handler"
  role             = "${aws_iam_role.ebs_tagger.arn}"
  timeout          = 20
  filename         = "/tmp/ebs_tagger.zip"
  source_code_hash = "${data.archive_file.ebs_tagger_zip.output_base64sha256}"

  environment {
    variables = {
      LAMBDA_TAGS = "${join(",",formatlist("%s=%s",keys(var.tags),values(var.tags)))}"
    }
  }
}

# create cloudwatch event rule
resource "aws_cloudwatch_event_rule" "ebs_tagger" {
  name        = "ec2-volumes-events-to-ebs_tagger"
  description = "Trigger lambda when EC2 Volume receives notification"

  event_pattern = "${jsonencode( {"source":[ "aws.ec2" ], "detail-type":[ "EBS Volume Notification" ]} )}"
}

# invoke lambda when the cloudwatch event rule triggers
resource "aws_cloudwatch_event_target" "invoke-lambda" {
  rule      = "${aws_cloudwatch_event_rule.ebs_tagger.name}"
  target_id = "InvokeLambda"
  arn       = "${aws_lambda_function.ebs_tagger.arn}"
}

# permit cloudwatch event rule to invoke lambda
resource "aws_lambda_permission" "lambda_permissions" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ebs_tagger.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ebs_tagger.arn}"
}
