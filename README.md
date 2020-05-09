# elastic-beanstalk-elk-beats
Elastic Beanstalk configuration for shipping logs, metrics and audit details using ELK Beats to the ELK stack (ElasticSearch, Logstash and Kibana).

This repoository contains:

- initial configurations for Filebeat
- initial configurations for Metricbeat
- initial configuriations for Auditbeat
- a small script for customisation
- a little guide on getting up and running

## Deploying ELK stack to AWS EC2

Deploy a new EC2 instance from the AWS Marketplace.  We've tested this with the `bitnami` image.  You can find that here: https://aws.amazon.com/marketplace/pp/Bitnami-ELK-Certified-by-Bitnami/B01N3YZR4I.
Make sure that you add an SSH key and that you download it.

### Connect to the EC2 instance

We're going for a super simple configuration here, so we're not going to talk about additional nodes or anything like that for ELK.  We're just going to configure the default image a little.  Firstly, we need to 
`ssh` into the EC2 instance.  You can do this by right clicking on the instance in the AWS console, and clicking `Connect`.  The details for how to `ssh` to the box
will be shown on the screen.  Follow them.  They typically involve making sure that the key has the right permissions:

`chmod 400 key.pem`

And then connecting (tip: the AWS `ssh` command will say to connect with `root` or `ec2-user` as the username, for `bitnami` images though we need to replace `root` or `ec2-user` with `bitnami`).  So you'll end up with something like:

`ssh -i "key.pem" bitnami@ec2-XX-XX-XX-XX.eu-west-1.compute.amazonaws.com`

### Configure an ingest node

Once you're connected, we need to make a quick change to the `elasticsearch` configuration:

`cd /home/bitnami/stack/elasticsearch/conf`
`sudo vi elasticsearch.yml`

With `vi` we need to change the `node.ingest` option to be `true`.

Once thats complete, write the changes to the file and quit.  Head back to the `stack` directory:

`cd /home/bitnami/stack`

And now we're going to restart the stack with the `ctlscript.sh`:

`sudo ./ctlscript.sh restart`

### Adjust EC2 Security Group to open inbound ports

Wait for everything to restart and head back to the EC2 console window.  Click on the ELK instance and in the more details view, we need to edit the Security Group settings.  Do this
by clicking on the Security Group link, it'll be called something like `ELK Certified by Bitnami-7-6-2-6-r01-AutogenByAWSMP` if you didn't make any changes during the launch instance.  Once you've opened it, and you're in the Security Groups
main view, click on the Security Group ID (which will look something like `sg-0XX000x0x000x0xx0`.  We now need to click `Edit the inbound rules`.

We're going to expose ports that ELK needs to allow us to ship their logs.  All of the entries will be of the type `Custom TCP`.  Wwe're going to add the following inboud ports:

- `5044`
- `5601`
- `9300`
- `9200`

Save the rules.

### Add a DNS record (if you want to)

No guide here, people will likely use lots of different DNS providers.  Do what you need to do.  Either way, you need to collec the public `ip address` of the EC2 instance.

### Log into the UI

We need the credentials for the Kibana user interface now so we can see our logs etc.  We can get these from the logs in EC2.

Right click on the EC2 instance, click `Instance Settings` and then `Get System log`.  Scroll through the logs and you'll see the username and password for the UI there.

Load up a browser and point it to your instance: `http://<public ip or dns address>:5601` and enter your credentials.  Kibana should load up!



