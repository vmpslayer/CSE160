#include "../../includes/linkstate.h"

module LinkStateRoutingP{
    provides interface LinkStateRouting;

    uses interface NeighborDiscovery;
    uses interface Flooding;
    uses interface Sender;
}
implementation{
    // Work Flow Overview:
        // 1. Neighbor Discovery: 
        // Start with LinkStateRouting.initLinkState() which will call NeighborDiscovery.initNeighborDisco()
        // We then have a NeighborDiscovery.updateListener() to receive the packet. 
        // Calling for Flood.initFlood(packet) to flood their information

        // 2. Flooding:
        // After Flood is called, we have Flood.receiveHandler() that will handle,
        // filter, sort all information for the link state table then call Dijkstra algorithm

        // 3. Dijkstra:
        // For each node, the link state table will be globally available so we can calculate
        // the shortest (least cost) path to each node. 

        // 4. Forwarding the packet:
        // 
    Neighbor nodeTable[MAX_NEIGHBORS];
    LinkState linkTable[MAX_NEIGHBORS];
    Routing forwardingTable[MAX_NEIGHBORS];
    uint lsSeqNum = 0;
    pack pkt;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
    
    // Neighbor Discovery listener, when it is initialized and there is an update,
    // it will also update it for this module
    event void NeighborDiscovery.updateListener(Neighbor* table, uint8_t length){
        memcpy(nodeTable, table, length * sizeof(Neighbor));
    }

    // 1. Neighbor discovery: Determine current set of neighors per node.
    command error_t LinkStateRouting.initLinkState(){
        uint8_t i;
        makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_LINKSTATE, lsSeqNum, (uint8_t*)nodeTable, PACKET_MAX_PAYLOAD_SIZE);
        for(i = 0; i < MAX_NEIGHBORS; i++){
            dbg(ROUTING_CHANNEL, "nodeTable: %d, %d, %d \n", nodeTable[i].address, nodeTable[i].address, nodeTable[i].qol);    
        }

        call Flooding.initFlood(pkt);
    }

    // 2. Extract payload, get neighbor data from payload. Store it. Flood packet.
    // Link State Flooding: Tell all nodes about all neighbors, use proj 1 to disseminate link-state packets
    // Filter and placement of neighbors and costs, used in Dijkstra
    command void LinkStateRouting.receiveHandler(pack myMsg){
        uint8_t i;
        pack msg;
        
    }

    // 2. Link State Flooding: Tell all nodes about all neighbors, use proj 1 to disseminate link-state packets
    // Filter and placement of neighbors and costs, used in Dijkstra
    // event void Flooding.updateListener(pack myMsg){
    //     uint8_t i;

        dbg(ROUTING_CHANNEL, "SUCCESS: Link-State packet from %d received by Node %d", myMsg.src, myMsg.dest);
        for(i = 0; i < MAX_NEIGHBORS; i++){
            
        }
        call Flooding.initFlood(pkt)
    }

    // 3. Shortest path calculation using Dijkstra's algorithm: build and keep up to date a routing
    // table that allows us to determine the next hop to forward a packet toward its destination
    void Dijkstra(){
        uint8_t i;
        
        // Initialization:
        // N’ = {u} // Compute least cost path from u to all other nodes
        // For all nodes a
        // If a adjacent to u // u initially knows direct-path-cost to direct neighbors
        // Then D(a) = Cu,a // but it may not be the minimum cost!
        //         Else D(a) = ∞
        for(i = 0; i < MAX_NEIGHBORS; i++){
            if(linkTable[i].address == TOS_NODE_ID){
                linkTable[i].cost = 0;
            }
            else if(nodeTable[i].address == 1){
                linkTable[i].cost = 
            }
            else{
                linkTable[i].cost = INFINITY;
            }
        }
        // Loop:
        //     Find a not in N’ such that D(a) is a minimum
        //     Add a to N’
        //     Update D(b) for all b adjacent to a and not in N’:
        //         D(b) = min(D(b), D(a) + Ca,b)
        //     // new least-path-cost to b is either old least-cost-path to 
        // b or known least-cost-path to a plus direction-cost from a to b
        // Until all nodes in N’
        for(i = 0; i < MAX_NEIGHBORS; i++){

        }

    }

    // 4. Forwarding: to send packets using routing table for next hops
    command error_t LinkStateRouting.forward(pack *msg){
        // if(call Sender.send(pkt, dest) == SUCCESS){
        //     dbg(ROUTING_CHANNEL, "SUCCESS: Forwarding with Link State Routing Complete")
        // }
    }


    // Result of the algorithm should be a routing table containing the next-hop neighbor to send to for each destination address.
    command void LinkStateRouting.listRouteTable(uint8_t srcNode){
        // List forwarding table for certain node
        uint8_t i;
        
        for(i = 0; i < MAX_NEIGHBORS; i++){
            dbg_clear(ROUTING_CHANNEL, "===========================\nRouting Table for Node %d\n", TOS_NODE_ID);
            dbg_clear(ROUTING_CHANNEL, "Dest    Cost    NextHop");
            // dbg_clear(ROUTING_CHANNEL, "%d      %d      %d \n===========================", linkTable[i].address, linkTable[i].cost, linkTable[i].nextHop)
        }
    }
}