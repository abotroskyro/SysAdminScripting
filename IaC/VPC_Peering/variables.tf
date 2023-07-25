#blahblahblah
##blahblahblah
variable "East1NetSpace" {
  type    = any
  default = "10.0.0.0/16"
}

variable "East2NetSpace" {
type = string
default = "10.1.0.0/16"

}
variable West1NetSpace {
type = string
default = "10.2.0.0/16"


}
variable E1PrivateSubnet {

type = list(string)
default = ["10.0.16.0/20","10.0.32.0/20"]

}

variable E2PrivateSubnet {

type = any
default = ["10.1.16.0/20","10.1.32.0/20"]

}





variable W1PrivateSubnet {

type = any
default = ["10.2.16.0/20","10.2.32.0/20"]

}

variable E1PublicSubnet {

type = list(string)

default = ["10.0.0.0/20"]

}

variable E2PublicSubnet {

type = list(string)

default = ["10.1.0.0/20"]

}
variable W1PublicSubnet {

type = list(string)

default = ["10.2.0.0/20"]

}
variable E1AZ {

type = list

default = ["us-east-1a","us-east1b"]
}
