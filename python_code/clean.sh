sudo virsh destroy vm1
sudo virsh destroy vm2
sudo virsh destroy vm3
sudo virsh destroy vm4
sudo virsh destroy vm5
sudo virsh destroy vm6
sudo virsh destroy vm7

sudo rm vm1*
sudo rm vm2*
sudo rm vm3*
sudo rm vm4*
sudo rm vm5*
sudo rm vm6*
sudo rm vm7*

sudo rm test*
sudo rm ccnd.conf*

sudo rm nodeIPs
sudo rm routing_table.txt

sudo virsh undefine vm1
sudo virsh undefine vm2
sudo virsh undefine vm3
sudo virsh undefine vm4
sudo virsh undefine vm5
sudo virsh undefine vm6
sudo virsh undefine vm7
