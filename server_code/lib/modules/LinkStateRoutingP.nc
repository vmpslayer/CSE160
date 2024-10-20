#include "../../includes/linkstate.h"

module LinkStateRoutingP{
    provides interface LinkStateRouting;

    uses interface Timer<TMilli> as linkStateTimer;
    uses interface NeighborDiscovery;
    uses interface Flooding;
}
implementation{
    // Initialization:
    // N’ = {u} // Compute least cost path from u to all other nodes
    // For all nodes a
    // If a adjacent to u // u initially knows direct-path-cost to direct neighbors
    // Then D(a) = Cu,a // but it may not be the minimum cost!
    //         Else D(a) = ∞
    // Loop:
    //     Find a not in N’ such that D(a) is a minimum
    //     Add a to N’
    //     Update D(b) for all b adjacent to a and not in N’:
    //         D(b) = min(D(b), D(a) + Ca,b)
    //     // new least-path-cost to b is either old least-cost-path to 
    // b or known least-cost-path to a plus direction-cost from a to b
    // Until all nodes in N’

    LinkState linkTable[MAX_NEIGHBORS];
    pack pkt;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    // 1. Neighbor discovery: Determine current set of neighors per node.
    command error_t LinkStateRouting.initLinkState(){
        call NeighborDiscovery.findNeighbor();
        call linkStateTimer.startPeriodic(60000);
    }

    event void linkStateTimer.fired(){
        getPacket();
    }

    // 2.Link State Flooding: Tell all nodes about all neighbors, use proj 1 to disseminate link-state packets
    void getPacket(){
        uint8_t i;
        for(i = 0; i < MAX_NEIGHBORS; i++){
            if(nodeTable[i].address != 0){
                makePack(&pkt, TOS_NODE_ID, nodeTable[i].address, 1, PROTOCOL_LINKSTATE, sqNumber, "", PACKET_MAX_PAYLOAD_SIZE);
            }
        }
        call Flooding.initFlood(pkt);
    }

    // Filter and placement of neighbors and costs, used in Dijkstra
    command void LinkStateRouting.receiveHandler(pack myMsg){
        uint8_t i;
        dbg(ROUTING_CHANNEL, "SUCCESS: Link-State packet from %d received by Node %d", myMsg.src, myMsg.dest);
        
        for(i = 0; i < MAX_NEIGHBORS; i++){
            // linkTable[msg.source].
        }
        Dijkstra();
    }

    // 3. Shortest path calculation using Dijkstra's algorithm: build and keep up to date a routing
    // table that allows us to determine the next hop to forward a packet toward its destination
    void Dijkstra(){
        uint8_t i;
        
        for(i = 0; i < MAX_NEIGHBORS; i++){

        }
    }

    // 4. Forwarding: to send packets using routing table for next hops
    command error_t LinkStateRouting.forward(pack msg){
        // uint16_t nextHop;
    }


    // Result of the algorithm should be a routing table containing the next-hop neighbor to send to for each destination address.
    command void LinkStateRouting.listRouteTable(uint8_t srcNode){
        // List forwarding table for certain node
        uint8_t i;
        
        for(i = 0; i < MAX_NEIGHBORS; i++){

        }
    }
}