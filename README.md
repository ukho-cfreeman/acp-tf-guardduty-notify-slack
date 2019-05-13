## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| create\_sns\_topic | Whether to create new SNS topic | string | `"true"` | no |
| create\_with\_kms\_key | Whether to create resources with KMS encryption | string | `"false"` | no |
| lambda\_function\_name | The name of the Lambda function to create | string | `"guardduty_notify_slack"` | no |
| slack\_channel | The name of the channel in Slack for notifications | string | n/a | yes |
| slack\_emoji | A custom emoji that will appear on Slack messages | string | `":aws:"` | no |
| slack\_username | The username that will appear on Slack messages | string | n/a | yes |
| slack\_webhook\_url | The URL of the  Slack webhook | string | n/a | yes |
| sns\_topic\_name | The name of the SNS topic to create | string | n/a | yes |


## Usage

```hcl
module "notify_slack" {
  source = "git::https://github.com/UKHomeOffice/acp-tf-guardduty-notify-slack?ref=master"

  sns_topic_name = "slack-topic"

  slack_webhook_url = "https://hooks.slack.com/services/AAA/BBB/CCC"
  slack_channel     = "AWS"
  slack_username    = "GuardDuty"
}
```
