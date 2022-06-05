# pokt-node-monitor
## Summary
Node Monitor is an open source tool for monitoring Pocket nodes and alerting node administrators when certain issues arise. 
The current version monitors the node’s block height. If the block height is behind by more than a specified number, Node Monitor will send an email notification to one or more defined recipients. Future versions will also support monitoring other metrics such as disk, CPU, and memory usage. 

## Preliminary
To set up notification you'll need a <a href="https://sendgrid.com/">sendgrid</a> api key.

See documentation on how to set up an API key <a href="https://docs.sendgrid.com/for-developers/sending-email/api-getting-started">here</a>.

## Installation
Log in into your node using ssh

```
ssh <hostname>
```
You can find the hostname by running 

```
hostname
```

You will need to log in as root to download and execute the script

Change to root user by

```
su 
```

Download and excecute the script from github
Use wget to download the script and set up the blockheight service

```
bash <(wget -q https://raw.githubusercontent.com/dabblelab/pokt-node-monitor/dev/blockheight.sh -O -)
```

## Parameters 

### Enter email to recieve notifications
This is the email address that will receive the notification when the node falls behind by a specific number of blocks

### Enter email from which to send notifications
This is the email address that will send the notifications when the node falls behind.
NB:- This must be the email configured with sendgrid account.

### Enter sender name
This is the name of the email sender , it could be the name of the node.

### Enter the Subject of the email notification
This is the subject of the email , it could something to make it easier for you to identify the node generating the email.

### Enter the threshold number of blocks (minimum 2 blocks)
### Press enter to leave it at the default 4 blocks
This is the minimum number of blocks that if the node falls behind,the blockheight service will start sending notifications.
This service starts sending notifications if the service falls behind by the configured blocks.
The default is 4 blocks also, if the user chooses any figure below 4 blocks the service automatically defaults to 4 blocks.
Anything above 4 the service sets the figure as the user preference for the block threshold.

See how to enter parameters below

![Node Monitor Parameters](/images/parameters.png?raw=true "Parameter configuration")

The confirmation email looks like in below image

![Set up confirmation email](/images/email_template.png?raw=true "Email template")

After a successful installation you'll recieve an email with the hostname and IP address of the node showing that it's successfully configured.




