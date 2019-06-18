# E-Corp Demo

The goal of this demo is to have a discussion and deep dive with potential customer E-Corp.

Below are essentially the notes with commands that I use to run through the presentation steps.
Few notes for setup and execution:
* local paths are based on the windows laptop I used for the demo - you may need to change them.
* repo and execution was in the folder C:\hashi3 -  you may need to change that in some commands.
* a file with the version of Oracle Java JDK named below will need to downloaded available in a location to be copied from (in C:\projects\hashitest1\ in cp command). This is because of Oracle changing the ability to download dynamically.
* aws creds and config are borrowed from local user's .aws folder
* for the individual products demonstrations, use the output document rather than notes as it is tailored with neessary build-specific values.

```
Open PS window
cd \hashi3
git clone https://github.com/practicalint/ECorp-demo.git
cp C:\projects\hashitest1\jdk-8u211-linux-x64.rpm C:\hashi3\ECorp-demo\workstation\jdk-8u211-linux-x64.rpm
cd .\ECorp-demo\workstation\

[ BUILD WORKSTATION ]
vagrant box list
[ vagrant box add bento/centos-7.6 # if not present]
vagrant validate
vagrant up --provision
vagrant ssh
- verify state
  terraform --version
  packer --version
  git --version
  aws --version
  aws ec2 describe-vpcs

[ BUILD IMAGES ]
cd projects
git clone https://github.com/practicalint/ECorp-demo.git
cd ECorp-demo/build-images/guides-configuration/
source aws-local-env.sh
cp /vagrant/jdk-8u211-linux-x64.rpm .
cd hashistack/
packer build -except=amazon-ebs-ubuntu-16.04-systemd hashistack-aws.json

[ BUILD INFRASTRUCTURE ] 
cd ~/projects/ECorp-demo/build-infrastructure/best-practices/terraform-aws
terraform init
terraform plan
terraform apply

{CAPTURE output text to file, move text file to shared screen} 
cp hashi-stack-ecorp-override-58d03e3e.key.pem /vagrant/.

[ CONFIGURE & REVIEW ] 	  
ssh-agent bash
ssh-add hashi-stack-ecorp-override-58d03e3e.key.pem  #change to match 
ssh -A -i hashi-stack-ecorp-override-58d03e3e.key.pem ec2-user@00.26.150.56  #change to match

consul members
consul kv put cli bar=baz
consul kv get cli 
curl \
      -X PUT \
      -d '{"bar=baz"}' \
      -k --cacert ${CONSUL_CACERT} --cert ${CONSUL_CLIENT_CERT} --key ${CONSUL_CLIENT_KEY} \
      ${CONSUL_ADDR}/v1/kv/api | jq '.' # Write a KV
curl \
      -X GET \
      -k --cacert ${CONSUL_CACERT} --cert ${CONSUL_CLIENT_CERT} --key ${CONSUL_CLIENT_KEY} \
      ${CONSUL_ADDR}/v1/kv/api | jq '.' # Read a KV
	  
[VAULT UNSEAL]
ssh -A ec2-user@$(curl http://127.0.0.1:8500/v1/agent/members | jq -M -r \
      '[.[] | select(.Name | contains ("hashi-stack-ecorp-hashistack")) | .Addr][0]')
vault operator init
(capture keys to doc)
vault operator unseal IA1KiA84UQG5IJgmnhNESBJoeUNvHPGiywVQk383dDti  #replace and run 3 keys, repeat for just 1 more
vault status
(sealed went to false, HA Mode to active)
export VAULT_TOKEN=1qN0ulXhC5hMr1qoAjo8QzUs # If Vault token has not been set
vault kv put secret/cli foo=bar
vault kv get secret/cli
curl \
      -H "X-Vault-Token: $VAULT_TOKEN" \
      -k --cacert ${VAULT_CACERT} --cert ${VAULT_CLIENT_CERT} --key ${VAULT_CLIENT_KEY} \
      ${VAULT_ADDR}/v1/secret/cli | jq '.' # Read secret set by cli

[NOMAD]
nomad server members
nomad node-status
nomad init
(don't do rest of nomad unless a lot of time)
curl \
      -X POST \
      -d @example.json \
      -k --cacert ${NOMAD_CACERT} --cert ${NOMAD_CLIENT_CERT} --key ${NOMAD_CLIENT_KEY} \
      ${NOMAD_ADDR}/v1/job/example/plan | jq '.' # Run a nomad plan on the example job

[UI]
ssh tunnel configuration needed for accessing UIs (or a VPN configured)
from aws lb page put url of LB and point to key,ports should be there (consul 8500, vault 8200, nomad 4646) 
consul needs to be referenced with http, others https

[ WRAP UP ]
exit linux stations
stop tunnels
terraform destroy -auto-approve
exit
vagrant destroy -f
```