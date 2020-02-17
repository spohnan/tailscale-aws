## Overview



This repo contains a CloudFormation template that automates the deployment process described in the [Setting up Tailscale on AWS EC2](https://tailscale.com/kb/1021/install-aws) project knowledgebase article.

_With the default configuration this solution will deploy resources that cost about $0.01/hr_

Resource List:

* A VPC with one public and one private subnet
* A NAT/Bastion EC2 instance provisioned in the public subnet
* A second EC2 instance provisioned in the private subnet

Both of the EC2 instances have the Tailscale Relay software installed and configured but need to be initialized using commands run on the console of each node and then an additional configuration step in the [Tailscale management console](https://login2.tailscale.io/admin).

## Step 1: Deploy the CloudFormation Template

### Manual Template Deployment

* Clone this repo or copy the tailscale-demo.yaml
* Ensure you have an [EC2 Key Pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair) created in the region in which you'll deploy the stack
* Launch the stack from the [CloudFormation console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html)
  * Choose the Upload a template file option and upload the `templates/tailscale-demo.yaml` file
* Give the stack a name using only alphanumeric chars and dashes
  * The automated deployment Makefile uses tailscale-demo as an example
* Select your SSH keypair from the drop-down list
* Enter a CIDR mask for just your IP using a web [IPv4 lookup service](https://checkip.amazonaws.com)
  * Make sure you add the /32 suffix to restrict to just your IP

### Automated Template Deployment

If you're using Mac or Linux _and_ have your AWS CLI configured for your account you can deploy
using a two step process

* At the top of the Makefile change the name of the SSH key to the one you'll use in your account. You can optionally update the SSH_ALLOWED_IPS variable.
  * `SSH_KEY := 'ts'` <~~ Your key name here
* Deploy or delete using the make  
  * `make deploy`
  * `make delete`

## Step 2: Configuration

### Step 2.1 - SSH Config File

The configuration steps require you to log into the console of each node and authenticate to the Tailscale service. This will create a config file which is needed before you can start the service. Read the SSH Config File Suggestion section below for a suggestion on how to configure your SSH using a config file. You can accomplish the ssh steps in a number of different ways but the remainder of this section assumes you've set up your config file as suggested. If you can't connect try running ssh with the `-v` flag to identify the connection problem.

### Step 2.2 - Configure the NAT Server

Locate the public IP of the NAT server either in the EC2 console or by looking at the Outputs tab of the CloudFormation stack and update the HostName line in the ts-nat-public block of your config file. SSH into the NAT instance (Using config file example: `ssh ts-nat-public`) and run the following commands. 

From the NAT server console run the `sudo tailscale-login` command
  * In any browser, open the URL printed to the console
  * Upon successful authentication you will see the Tailscale client exit. Note that it has written a configuration file to `/var/lib/tailscale/relay` conf.

From the Tailscale web console click the Enable Subnet Routes option for the NAT server
* After succesfully authenticating and starting the service on the NAT server you'll see an entry for the node in the [Tailscale Admin Console](https://login2.tailscale.io/admin) in the Machines section.
* The routes to both the public and private subnets have been configured as described in the [documentation](https://tailscale.com/kb/1019/install-subnets) but an additional step of Enabling Subnet Routes from the admin console must be completed before connectivity to nodes in the private subnet can be established.
* After enabling subnet routes the NAT server node should now have both a green checkmark and a blue network icon.

Once you've authorized the service to enable subnet routes _then_ start the tailscale-relay service in the console of the NAT server
* Start the service using the command `sudo systemctl start tailscale-relay`
  * Check service status with `sudo systemctl status tailscale-relay`

### Step 2.3 - Configure the second node in the private subnet

Locate the private IP of the second server either in the EC2 console or by looking at the Outputs tab of the CloudFormation stack adn update the Hostname line in the ts-node-private block of your config file. This block has an additional ProxyJump command which allows us to get to the console of an instance with no public IP by jumping through the NAT/Bastion instance.

SSH into the NAT instance (Using config file example: `ssh ts-node-private`) and run the following commands. 

Commands to run from the second instance console
* `sudo tailscale-login`
* Start the service using the command `sudo systemctl start tailscale-relay`
  * Check service status with `sudo systemctl status tailscale-relay`

## Step 3: Tests

* To test an individual node you should be able to curl the IRC web client from the console
  * `curl http://100.101.102.103`
  * If this command doesn't succeed and return a redirect then the node has not been configured correctly
* To test connectivity between nodes you should be able to ping the 100.x.x.x address between any two nodes
* If you've installed the client on your Mac or Windows workstation you should be able to ping or SSH into either of these EC2 instances using their 100.x.x.x IPs despite the fact that one of them is in a private subnet and doesn't even have a public IP
* In your ~/.ssh/config file update the HostName values for the `ts-nat` and `ts-node` blocks with the 100.x.x.x IPs found in the admin console and attempt to ssh into the servers again using their Tailscale IPs

## Step 4: Delete the CloudFormation Stack

To tear down the stack and release all the provisioned resources [use the Delete button](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html).

## Misc Notes

### SSH Config File Suggestion

Use an `~/.ssh/config` file to map the various name and ip combinations. An example below showing the two nodes below described in Step 2 of the setup instructions.

Update the x.x.x.x placeholders with the IPs of your servers and change the IdentityFile name if you didn't save your key pair as ts.pem

```
# The public IP of the NAT server
Host ts-nat-public
	HostName x.x.x.x

# The Tailscale IP of the NAT server once configured
Host ts-nat
	HostName 100.x.x.x

# The private IP of the node in the private subnet
Host ts-node-private
    HostName x.x.x.x
    ProxyJump ts-nat-public

# The Tailscale IP of the node in the private subnet
Host ts-node
    HostName 100.x.x.x

# Settings that apply to all hosts. Update IdentityFile if needed.
Host *
	User ec2-user
    IdentityFile ~/.ssh/ts.pem
```

### Contributing

Run the lint utilities to ensure the CloudFormation/YAML stays tidy

```
# Once per project
python3 -m venv ./venv
pip install -r requirements.txt

# Once per session
. ./venv/bin/activate

# When you want to check
make lint
```
