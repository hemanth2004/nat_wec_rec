# nat_wec_rec
## How to run
1. Navigate to the folder with vnet.sh on a terminal and execute the script with sudo perms
```
sudo bash vnet.sh
```
2. Test the network using the following example commands
**Ping client2 from client1**
```
sudo ip netns exec client1 ping 192.168.10.102
```

**Ping google from the router**
```
sudo ip netns exec router ping 8.8.8.8
```

**HTTPS from client1**
```
sudo ip netns exec client1 curl -I https://142.250.72.196
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

4. Port Forwarding and Security \[BONUS\]:

Forwarded incoming HTTP (port 80) traffic on the router to client1’s web server.
The difference between receiving it at an IP and receiving it at an IP:PORT type address is that the latter lets you explicitly direct packets to a service/process.
Also configured iptables rules to only allow outgoing traffic on HTTP (port 80) and HTTPS (port 443), while dropping all other outgoing packets for security. Although ICMP works for testing purposes.

## Challenges Faced

1. Faced issues with getting access to internet from within from the main enp0s3 interface on my Virtual Machine.
2. Figuring out that setting up two NATs is the way to make the intermediate router namespace into an actual router was pretty challenging, else the root namespace can only be the router.
3. Facing challenges with packet filtering of outgoing packets. For example, something like SSH still works from client1 and client2 despite having iptable rules that essentially state 'DROP ALL PACKETS', 'ALLOW ONLY TCP PACKETS WITH PORT 80 and 443'.
4. Learning what port forwarding even is and why its hekpful was an experience.

## Bonus Tasks
1. Completed port forwarding to client1's web server
2. Added commands to limit outbound traffic to http and https only but they don't seem to work. 

   

