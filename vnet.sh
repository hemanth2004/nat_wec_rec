# 192.168.11.0/24 gives us access to the internet
# This network exists between the root namespace and the router, kind of like a subnet

# 192.168.10.0/24 our actual virtual computer network whose router is the 'router' namespace
# This network exists bebtween the router and the clients like a typical star topology LAN setup


# preparing kernel for the network
ip -all netns delete
iptables -F
sysctl -w net.ipv4.ip_forward=1


# add our router namespace
ip netns add router
ip -n router link set lo up



# link up the router and the root namespace
# 192.168.11.1 could be regarded as the router's "public IP" in this context
ip link add veth-root type veth peer name veth-router
ip link set veth-router netns router
ip addr add 192.168.11.2/24 dev veth-root
ip -n router addr add 192.168.11.1/24 dev veth-router
ip link set veth-root up
ip -n router link set veth-router up



# to make veth-router act as an external connection to the internet 
# (taking root namespace as part of the 'internet')
ip -n router route add default via 192.168.11.2 
ip route add 192.168.10.0/24 via 192.168.11.1
iptables -t nat -A POSTROUTING -s 192.168.11.0/24 -o enp0s3 -j MASQUERADE
iptables -A FORWARD -i enp0s3 -o veth-root -j ACCEPT
iptables -A FORWARD -o enp0s3 -i veth-root -j ACCEPT



# set up virtual switch of router
ip -n router link add vbr type bridge
ip -n router addr add 192.168.10.1/24 dev vbr
ip -n router link set vbr up



# the actual router NATting that concerns our 192.168.10.0 network
# also implement the firewall here
ip netns exec router iptables -F
ip netns exec router iptables -t nat -F
ip netns exec router iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o veth-router -j MASQUERADE

# allow outgoing port 80 and 443 traffic
ip netns exec router iptables -A FORWARD -i vbr -o veth-router -p tcp --dport 80 -j ACCEPT
ip netns exec router iptables -A FORWARD -i vbr -o veth-router -p tcp --dport 443 -j ACCEPT

# allow all incoming traffic since the firewall is only for outbound traffic
ip netns exec router iptables -A FORWARD -i veth-router -o vbr -p tcp -j ACCEPT

# once filters are specified, drop all packets
ip netns exec router iptables -P FORWARD DROP



# set up client1
ip netns add client1
ip -n router link add veth1-br type veth peer name veth1
ip -n router link set veth1-br master vbr
ip -n router link set veth1-br up
ip -n router link set veth1 netns client1
ip -n client1 link set veth1 up
ip -n client1 addr add 192.168.10.101/24 dev veth1
ip -n client1 route add default via 192.168.10.1



# set up client2
ip netns add client2 
ip -n router link add veth2-br type veth peer name veth2
ip -n router link set veth2-br master vbr
ip -n router link set veth2-br up
ip -n router link set veth2 netns client2
ip -n client2 link set veth2 up
ip -n client2 addr add 192.168.10.102/24 dev veth2
ip -n client2 route add default via 192.168.10.1

# ensuring bridge is on for one final time
ip -n router link set vbr up


# creation of a http web server on client1
ip netns exec client1 python3 -m http.server 80 &

sleep 2

# forward port 80 requests on network's "public IP" to client1's web server
ip netns exec router iptables -t nat -A PREROUTING -d 192.168.11.1 -p tcp --dport 80 -j DNAT --to-destination 192.168.10.101:80
ip netns exec router iptables -A FORWARD -p tcp -d 192.168.10.101 --dport 80 -j ACCEPT




echo ' '
echo 'Testing http from client1'
ip netns exec client1 curl http://93.184.216.34
echo ' '

echo 'Testing https from client2'
ip netns exec client2 curl -k https://104.16.132.229
echo ' '

echo 'Testing web server from client2'
ip netns exec client2 curl http://192.168.10.101
echo ' '

echo 'Testing ping 8.8.8.8 from client1'
ip netns exec client1 ping 8.8.8.8
