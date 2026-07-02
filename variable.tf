variable "name" {
    default = "FCT"
  
}
variable "public_subnet" {
    default = "10.0.0.0/20"
  
}
variable "private_subnet-1" {
    default = "10.0.16.0/20"
  
}
variable "private_subnet-2" {
    default = "10.0.32.0/20"
  
}
variable "az1" {
    default = "us-east-2a"
  
}
variable "az2" {
    default = "us-east-2b"
  
}
variable "az3" {
    default = "us-east-2c"
  
}
variable "igw-rt-cidr" {
    default = "0.0.0.0/0"
  
}  
variable "nat-rt-cidr" {
    default = "0.0.0.0/0"
  
}
variable "ami" {
    default = "ami-0772d6acfbccb1275"
}
variable "instance_type" {
    default = "t3.micro"
  
}
variable "key" {
    default = "project_key"
  
}