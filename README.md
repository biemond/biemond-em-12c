## Oracle Enterprise Manager 12.1.0.4

### Software
- linuxamd64_12c_database_1of2.zip  ( 12.1.0.1 )
- linuxamd64_12c_database_2of2.zip
- em12104_linux64_disk1.zip   ( 12.1.0.4 )
- em12104_linux64_disk2.zip
- em12104_linux64_disk3.zip

### Vagrant
Update the local path of the /software share in Vagrantfile to your own DB & EM software location

### EM DB steps
- vagrant up emdb

### EM App steps
- vagrant up emapp

### default urls
- Enterprise Manager Cloud Control URL: https://10.10.10.25:7802/em
- Admin Server URL: https://10.10.10.25:7102/console

### passwords
- em weblogic Welcome01
- em sysman Welcome01
- db sys Welcome01