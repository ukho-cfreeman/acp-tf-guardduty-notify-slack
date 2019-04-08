data "aws_sns_topic" "topic" {
  count = "${(1 - var.create_sns_topic) * var.create}"
  name  = "${var.sns_topic_name}"
}

resource "aws_sns_topic" "topic" {
  count = "${var.create_sns_topic * var.create}"

  name = "${var.sns_topic_name}"
}

locals {
  sns_topic_arn = "${element(concat(aws_sns_topic.topic.*.arn, data.aws_sns_topic.topic.*.arn, list("")), 0)}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack" {
  count = "${var.create}"

  topic_arn = "${local.sns_topic_arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack" {
  count = "${var.create}"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${local.sns_topic_arn}"
}

data "null_data_source" "lambda_file" {
  inputs {
    filename = "${substr("${path.module}/functions/notify_slack.py", length(path.cwd) + 1, -1)}"
  }
}

#  the path the python or node.js file is stored in the directory
data "null_data_source" "lambda_archive" {
  inputs {
    filename = "${substr("${path.module}/functions/notify_slack.zip", length(path.cwd) + 1, -1)}"
  }
}

data "archive_file" "notify_slack" {
  count = "${var.create}"

  type        = "zip"
  source_file = "${data.null_data_source.lambda_file.outputs.filename}"
  output_path = "${data.null_data_source.lambda_archive.outputs.filename}"
}

resource "aws_lambda_function" "notify_slack" {
  count = "${var.create}"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.topic.arn}"
}

## eu-west-1

resource "aws_sns_topic" "guard_duty_findings_to_slack" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.eu-west-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_eu_west_1" {
  count     = "${var.create}"
  provider  = "aws.eu-west-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_eu_west_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_eu_west_1" {
  count    = "${var.create}"
  provider = "aws.eu-west-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_eu_west_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack.arn}"
}

resource "aws_lambda_function" "notify_slack_eu_west_1" {
  count    = "${var.create}"
  provider = "aws.eu-west-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_eu_west_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.eu-west-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_eu_west_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_eu_west_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack.arn}"
  provider  = "aws.eu-west-1"
}

## us-east-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_us_east_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.us-east-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_us_east_1" {
  count     = "${var.create}"
  provider  = "aws.us-east-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_us_east_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_us_east_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_us_east_1" {
  count    = "${var.create}"
  provider = "aws.us-east-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_eu_west_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_us_east_1.arn}"
}

resource "aws_lambda_function" "notify_slack_us_east_1" {
  count    = "${var.create}"
  provider = "aws.us-east-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_us_east_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.us-east-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_us_east_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_us_west_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_us_east_1.arn}"
  provider  = "aws.us-east-1"
}

## us-east-2

resource "aws_sns_topic" "guard_duty_findings_to_slack_us_east_2" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.us-east-2"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_us_east_2" {
  count     = "${var.create}"
  provider  = "aws.us-east-2"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_us_east_2.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_us_east_2.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_us_east_2" {
  count    = "${var.create}"
  provider = "aws.us-east-2"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_us_east_2.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_us_east_2.arn}"
}

resource "aws_lambda_function" "notify_slack_us_east_2" {
  count    = "${var.create}"
  provider = "aws.us-east-2"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_us_east_2" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.us-east-2"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_us_east_2" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_us_east_2.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_us_east_2.arn}"
  provider  = "aws.us-east-2"
}

## us-west-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_us_west_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.us-west-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_us_west_1" {
  count     = "${var.create}"
  provider  = "aws.us-west-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_us_west_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_us_west_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_us_west_1" {
  count    = "${var.create}"
  provider = "aws.us-west-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_us_west_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_us_west_1.arn}"
}

resource "aws_lambda_function" "notify_slack_us_west_1" {
  count    = "${var.create}"
  provider = "aws.us-west-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_us_west_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.us-west-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_us_west_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_us_west_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_us_west_1.arn}"
  provider  = "aws.us-west-1"
}

## us-west-2

resource "aws_sns_topic" "guard_duty_findings_to_slack_us_west_2" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.us-west-2"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_us_west_2" {
  count     = "${var.create}"
  provider  = "aws.us-west-2"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_us_west_2.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_us_west_2.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_us_west_2" {
  count    = "${var.create}"
  provider = "aws.us-west-2"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_us_west_2.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_us_west_2.arn}"
}

resource "aws_lambda_function" "notify_slack_us_west_2" {
  count    = "${var.create}"
  provider = "aws.us-west-2"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_us_west_2" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.us-west-2"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_us_west_2" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_us_west_2.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_us_west_2.arn}"
  provider  = "aws.us-west-2"
}

## ap-southeast-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_ap_southeast_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.ap-southeast-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_ap_southeast_1" {
  count     = "${var.create}"
  provider  = "aws.ap-southeast-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_ap_southeast_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_ap_southeast_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_ap_southeast_1" {
  count    = "${var.create}"
  provider = "aws.ap-southeast-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_ap_southeast_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_ap_southeast_1.arn}"
}

resource "aws_lambda_function" "notify_slack_ap_southeast_1" {
  count    = "${var.create}"
  provider = "aws.ap-southeast-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_ap_southeast_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.ap-southeast-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_ap_southeast_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_ap_southeast_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_ap_southeast_1.arn}"
  provider  = "aws.ap-southeast-1"
}

## ap-southeast-2

resource "aws_sns_topic" "guard_duty_findings_to_slack_ap_southeast_2" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.ap-southeast-2"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_ap_southeast_2" {
  count     = "${var.create}"
  provider  = "aws.ap-southeast-2"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_ap_southeast_2.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_ap_southeast_2.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_ap_southeast_2" {
  count    = "${var.create}"
  provider = "aws.ap-southeast-2"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_ap_southeast_2.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_ap_southeast_2.arn}"
}

resource "aws_lambda_function" "notify_slack_ap_southeast_2" {
  count    = "${var.create}"
  provider = "aws.ap-southeast-2"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_ap_southeast_2" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.ap-southeast-2"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_ap_southeast_2" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_ap_southeast_2.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_ap_southeast_2.arn}"
  provider  = "aws.ap-southeast-2"
}

## ap-northeast-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_ap_northeast_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.ap-northeast-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_ap_northeast_1" {
  count     = "${var.create}"
  provider  = "aws.ap-northeast-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_ap_northeast_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_ap_northeast_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_ap_northeast_1" {
  count    = "${var.create}"
  provider = "aws.ap-northeast-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_ap_northeast_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_ap_northeast_1.arn}"
}

resource "aws_lambda_function" "notify_slack_ap_northeast_1" {
  count    = "${var.create}"
  provider = "aws.ap-northeast-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_ap_northeast_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.ap-northeast-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_ap_northeast_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_ap_northeast_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_ap_northeast_1.arn}"
  provider  = "aws.ap-northeast-1"
}

## ap-northeast-2

resource "aws_sns_topic" "guard_duty_findings_to_slack_ap_northeast_2" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.ap-northeast-2"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_ap_northeast_2" {
  count     = "${var.create}"
  provider  = "aws.ap-northeast-2"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_ap_northeast_2.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_ap_northeast_2.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_ap_northeast_2" {
  count    = "${var.create}"
  provider = "aws.ap-northeast-2"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_ap_northeast_2.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_ap_northeast_2.arn}"
}

resource "aws_lambda_function" "notify_slack_ap_northeast_2" {
  count    = "${var.create}"
  provider = "aws.ap-northeast-2"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_ap_northeast_2" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.ap-northeast-2"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_ap_northeast_2" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_ap_northeast_2.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_ap_northeast_2.arn}"
  provider  = "aws.ap-northeast-2"
}

## ap-south-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_ap_south_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.ap-south-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_ap_south_1" {
  count     = "${var.create}"
  provider  = "aws.ap-south-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_ap_south_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_ap_south_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_ap_south_1" {
  count    = "${var.create}"
  provider = "aws.ap-south-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_ap_south_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_ap_south_1.arn}"
}

resource "aws_lambda_function" "notify_slack_ap_south_1" {
  count    = "${var.create}"
  provider = "aws.ap-south-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_ap_south_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.ap-south-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_ap_south_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_ap_south_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_ap_south_1.arn}"
  provider  = "aws.ap-south-1"
}

## eu-central-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_eu_central_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.eu-central-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_eu_central_1" {
  count     = "${var.create}"
  provider  = "aws.eu-central-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_eu_central_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_eu_central_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_eu_central_1" {
  count    = "${var.create}"
  provider = "aws.eu-central-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_eu_central_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_eu_central_1.arn}"
}

resource "aws_lambda_function" "notify_slack_eu_central_1" {
  count    = "${var.create}"
  provider = "aws.eu-central-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_eu_central_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.eu-central-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_eu_central_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_eu_central_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_eu_central_1.arn}"
  provider  = "aws.eu-central-1"
}

## eu-west-3

resource "aws_sns_topic" "guard_duty_findings_to_slack_eu_west_3" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.eu-west-3"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_eu_west_3" {
  count     = "${var.create}"
  provider  = "aws.eu-west-3"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_eu_west_3.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_eu_west_3.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_eu_west_3" {
  count    = "${var.create}"
  provider = "aws.eu-west-3"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_eu_west_3.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_eu_west_3.arn}"
}

resource "aws_lambda_function" "notify_slack_eu_west_3" {
  count    = "${var.create}"
  provider = "aws.eu-west-3"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_eu_west_3" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.eu-west-3"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_eu_west_3" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_eu_west_3.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_eu_west_3.arn}"
  provider  = "aws.eu-west-3"
}

## sa-east-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_sa_east_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.sa-east-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_sa_east_1" {
  count     = "${var.create}"
  provider  = "aws.sa-east-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_sa_east_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_sa_east_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_sa_east_1" {
  count    = "${var.create}"
  provider = "aws.sa-east-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_sa_east_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_sa_east_1.arn}"
}

resource "aws_lambda_function" "notify_slack_sa_east_1" {
  count    = "${var.create}"
  provider = "aws.sa-east-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_sa_east_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.sa-east-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_sa_east_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_sa_east_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_sa_east_1.arn}"
  provider  = "aws.sa-east-1"
}

## ca-central-1

resource "aws_sns_topic" "guard_duty_findings_to_slack_ca_central_1" {
  count    = "${var.create_sns_topic * var.create}"
  provider = "aws.ca-central-1"
  name     = "${var.sns_topic_name}"
}

resource "aws_sns_topic_subscription" "sns_notify_slack_ca_central_1" {
  count     = "${var.create}"
  provider  = "aws.ca-central-1"
  topic_arn = "${aws_sns_topic.guard_duty_findings_to_slack_ca_central_1.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.notify_slack_ca_central_1.0.arn}"
}

resource "aws_lambda_permission" "sns_notify_slack_ca_central_1" {
  count    = "${var.create}"
  provider = "aws.ca-central-1"

  statement_id  = "ExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_slack_ca_central_1.0.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.guard_duty_findings_to_slack_ca_central_1.arn}"
}

resource "aws_lambda_function" "notify_slack_ca_central_1" {
  count    = "${var.create}"
  provider = "aws.ca-central-1"

  filename = "${data.archive_file.notify_slack.0.output_path}"

  function_name = "${var.lambda_function_name}"

  role             = "${aws_iam_role.lambda.arn}"
  handler          = "notify_slack.lambda_handler"
  source_code_hash = "${data.archive_file.notify_slack.0.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${var.slack_webhook_url}"
      SLACK_CHANNEL     = "${var.slack_channel}"
      SLACK_USERNAME    = "${var.slack_username}"
      SLACK_EMOJI       = "${var.slack_emoji}"
    }
  }

  lifecycle {
    ignore_changes = [
      "filename",
      "last_modified",
    ]
  }
}

resource "aws_cloudwatch_event_rule" "guard_duty_findings_to_slack_ca_central_1" {
  name        = "guardduty-finding-events"
  description = "AWS GuardDuty event findings"
  provider    = "aws.ca-central-1"

  event_pattern = "${file("${path.module}/event-pattern.json")}"
}

resource "aws_cloudwatch_event_target" "guard_duty_findings_to_slack_ca_central_1" {
  rule      = "${aws_cloudwatch_event_rule.guard_duty_findings_to_slack_ca_central_1.name}"
  target_id = "slack-topic"
  arn       = "${aws_sns_topic.guard_duty_findings_to_slack_ca_central_1.arn}"
  provider  = "aws.ca-central-1"
}
