require 'awspec'
require 'json'

tfvars = JSON.parse(File.read('./' + ENV['INSTANCE'] + '.auto.tfvars.json'))

describe eks(tfvars["instance_name"]) do
  it { should exist }
  it { should be_active }
  its(:version) { should eq tfvars['eks_version'] }
end

describe iam_role(tfvars["instance_name"] + '-vpc-cni') do
  it { should exist }
end

describe iam_role(tfvars["instance_name"] + '-ebs-csi-controller-sa') do
  it { should exist }
end
