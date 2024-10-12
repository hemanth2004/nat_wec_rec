# nat_wec_rec
Bash script that uses network namespaces, iptables and iproute2 to create a virtual private network with a firewall and port forwarding. Made for the WEC Systems SIG recruitment.

## How to run
Navigate to the folder with vnet.sh on a terminal and execute the script with sudo perms
```
sudo bash vnet.sh
```

## Commands to test task objectives
1. View network topology details
```
sudo ip netns list
ip addr
sudo ip -n router addr
sudo ip -n client1 addr
sudo ip -n client2 addr
```

2. Check internet access from client1 and client2
```
sudo ip netns exec client1 curl http://93.184.216.34
sudo ip netns exec client2 curl -k https://104.16.132.229
```

3. Check Web Server Status 
```
sudo ip netns exec client2 curl http://192.168.10.101
```

4. Port Forwarding 
```
curl http://192.168.11.1
```

5. Test firewall for outbound traffic
Verify that HTTPS and HTTP connections are allowed
```
sudo ip netns exec client1 curl http://93.184.216.34
sudo ip netns exec client2 curl -k https://104.16.132.229
```
Verify that non-(HTTP and HTTPS) connections are not allowed (no response since unworthy packets are dropped and not rejected)
```
sudo ip netns exec client1 ping 8.8.8.8
```

## Approach Taken
1. Setting up the router:

Created a router namespace to simulate the router.
Connected the router to the root namespace via a veth pair.

2. Virtual Bridge:

Created a virtual bridge (vbr) inside the router namespace to act as a switch for connecting clients.
NAT rules were applied to route traffic from the 192.168.10.0/24 subnet to the 192.168.11.0/24 subnet. This is to simulate internet access so that the router has direct internet access even though its only a namespace within the root.

Each packet from a client goes through two NATs. One that translates it from 192.168.10.0/24 network to 192.168.11.0/24 network. the 11.0 one is a network between root and router just for them to communicate. The other is the main LAN network we are supposed to create.

3. Client Setup:

I created two clients, client1 and client2, in separate network namespaces.
Each client was assigned a virtual Ethernet interface and connected to the router’s bridge (vbr).
The clients were assigned IPs in 192.168.10.0/24, and default routes were set via the router’s bridge IP (192.168.10.1).

4. Port Forwarding and Outbound Traffic control \[BONUS\]:

Forwarded incoming HTTP (port 80) traffic on the router to client1’s web server.
Also configured iptables rules to only allow outgoing traffic on HTTP (port 80) and HTTPS (port 443), while dropping all other outgoing packets for security. Even ICMP packets that support the ping command.

## Challenges Faced

1. Faced issues with getting access to internet from within from the main enp0s3 interface on my Virtual Machine.
2. Figuring out that setting up two NATs is the way to make the intermediate router namespace into an actual router was pretty challenging, else the root namespace can only be the router.
3. Faced challenges with packet filtering of outgoing packets. The actual firewall is to be placed in the path between router's "public IP" interface and the virtual switch interface.
4. Learning what port forwarding is, how web servers work and why port forwarding helpful was an experience.

## Bonus Tasks
1. Completed port forwarding to client1's web server
2. Added commands to limit outbound traffic to http and https only but they don't seem to work. 

   

