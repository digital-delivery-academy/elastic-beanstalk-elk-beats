# elastic-beanstalk-elk-beats
Elastic Beanstalk configuration for shipping logs, metrics and audit details using ELK Beats to the ELK stack (ElasticSearch, Logstash and Kibana).

This little guide and the contained configuration should plug nicely into your existing build pipeline, and give you an out of the box monitoring system with some sexy dashboards.

This repoository contains:

- initial configurations for Filebeat
- initial configurations for Metricbeat
- initial configuriations for Auditbeat
- a small script for customisation in a build pipeline
- a little guide on getting up and running

The base configurations here are for Elastic Beanstalk deployments that are for applications in a `docker` container with `nginx` on the `eb` instance.

If you have any custom `nginx` configurations that you're already using, then you need to merge them with the configurtion here.

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

## Overview of the ebextensions we're making

We have four thing for `ebextensions` to take care of here:

- deploying a new custom `nginx` configuration
- deploy and configure `filebeat`
- deploy and configure `metricbeat`
- deploy and configure `auditbeat`

### `nginx` configuration

There's nothing magic here really.  We're adding an endpoint to allow us to monitor `nginx` in `/server-status` with a simple `location` addition:

```
location /server-status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

And we're making some changes to the log format.  We're replacing `remote_ip` with `http_x_forwarded_for` to make sure that we're tracking the IP address of the requester as it hits the Elasic Load Balancer.  We do this because we want to see the geographic positions that consumers are hittin the serivces from.  If we don't do this bit, then we'll only ever get the internal AWS IP from the load balancer (I burnt 4 hours wondering why `geopip` wasn't working for the Kibana dashboards that we're going to get to later, and this was, quite obviously the reason; can't get geographic information from an internal IP address, duh.)

### `filebeat`

Filebeat is the thing we use to prospect for log files and ship them off to ELK.  We have a configuration here that takes all of the log files that you'd get if you requested the logs in the Elastic Beanstalk console screen.  Additionally, we use two `filebeat` modules that are preconfigured for us (and do a lot of heavy lifting behind the scenes) to gather and analyse `system` and `nginx` logs.  This is especially helpful as they work super nicely with the built in dashboards in Kibana that we're gonna set up next.

If you want to enable additional `filebeat` modules that are pacakged with `filebeat`, then just edit the `filebeat.config` file at the bottom under the `commands` section and simply include their names.

We have two custom fields that we ship with each entry.  That is  `environment` and `application`.  We use that to allow us to filter by environment and application.  I've picked confusing names here if we're in the `eb` space, but `environment` in this context maps to `test`, `live`, `prod` etc (the type of enviornment) and `application` maps to the name of the application e.g. `my-microservice`.  This would then allow us in Kibana to see logs from `my-microservice` across `test` and `prod`, or just `test` or just `prod` etc.  This is useful for using the same ELK instance to manage all of our logs.

### `metricbeat`

Metricbeat is the thing we use to pull metrics about uptime, memory, disk, CPU, network etc etc etc from the instance and from running `docker` containers.  We have the same additional fields for `environment` and `application` as we do for `filebeat`.  Metricbeat gives us some great dashboards and timeseries mapping of utilisation over time.  We also collect the service status that we configured in the `nginx` configuration with Metricbeat.

### `auditbeat`

Auditbeat is the thing that we use to monitor `auditd` and watch some basic operations that we probably want to track over time (like who and when people are reading the `/etc/passwd` file or `ssh` access etc).  We add `environment` and `application` fields to everything we ship as well so we can drill down per service and per environment.  The Auditbeat monitoring gives us some basic dashboards and collated, centralised information that we could, if we had too, start a basic security investigation.  We definitely wouldn't be any worse off if we had the information this thing collects in the event of a breach etc, and collecting it allows us to work to setup alerts when some of the things it watches for happen.


## Updating the pacakging of your applciations via your pipeline/CI system

There are some scripts in the `scripts` directory that should make things simple for you to use this repo in your build system.  If you're just using the configurations as they are, then you can follow this flow, othewise, feel free to do what you need to do.  So, in your pipeline add a step before packaging to do something like this:

- clone this repo
- `chmod` the scripts directory
- from the root of the checked out repos directory, run `./scripts/package-in-ebextensions.sh`
- move the produced `.ebextensions` directory to the root of the directory that will be zipped up to be shipped to Elastic Beanstalk.

### `package-in-ebextensions.sh`

All this does is create an `.ebextensions` folder with the contents in it.  Ship this to the root of your deployable directory that will be zipped up for Elastic Beanstalk.