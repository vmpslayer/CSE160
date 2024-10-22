#include "../../includes/linkstate.h"
#include "../../includes/routing.h"

module LinkStateRoutingP{
    provides interface LinkStateRouting;

    uses interface NeighborDiscovery;
    uses interface Flooding;
    uses interface SimpleSend as Sender;
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
            // Forward the packet using the shortest route
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
        uint8_t j;
        // We're going to make a packet with the payload, an array of Node addresses that are the neighbors of this Node.
        // We're going to accomplish this by making an array of uint16_t with the size of 4 so it only takes 8 bytes in the payload
        uint8_t neighbors[4] = {0,0,0,0};
        i = 0;

        while(j < 20 && i < 4){
            if(nodeTable[j].address != 0){
                neighbors[i] = j;
                i++;
            }
            j++;
        }
        

        for(i = 0; i < 4; i++){
            dbg(ROUTING_CHANNEL,"Neighbor %d, %u\n", i, neighbors[i]);
        }
        
        makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKSTATE, lsSeqNum, (uint8_t*)neighbors, sizeof(neighbors));

        /*
        for(i = 0; i < 4; i++){
            dbg(ROUTING_CHANNEL,"Neighbor %d, %u\n", i, neighbors[i]);
        }
        */

        call Flooding.initFlood(pkt);
    }

    // 2. Link State Flooding: Tell all nodes about all neighbors, use proj 1 to disseminate link-state packets
        // Filter and placement of neighbors and costs, used in Dijkstra
        // Extract payload, get neighbor data from payload. Store it. Flood packet.
        // Link State Flooding: Tell all nodes about all neighbors, use proj 1 to disseminate link-state packets
        // Filter and placement of neighbors and costs, used in Dijkstra
    command void LinkStateRouting.receiveHandler(pack myMsg){
        uint8_t i;
        uint8_t j;
        floodPack flood_pack;
        uint8_t array[4];
        
        // Takes stuff from the payload and puts it into floodPack
        memcpy(&flood_pack, &myMsg.payload, sizeof(floodPack));

        /*
        for(i = 0; i < 4; i++){
            dbg(ROUTING_CHANNEL,"Received neighbor %d, %u from %i\n", i, flood_pack.payload[i], myMsg.src);
        }
        */

        // dbg(ROUTING_CHANNEL, "These are the neighbors of: %i\n", flood_pack.floodSource);
        
        linkTable[flood_pack.floodSource].address = flood_pack.floodSource;
        memcpy(&linkTable[flood_pack.floodSource].neighbors, flood_pack.payload, sizeof(flood_pack.payload));

        dbg(ROUTING_CHANNEL, "Node %i has the neighbors: ", linkTable[flood_pack.floodSource].address);
        for(i = 0; i < 4; i++){
            dbg_clear(ROUTING_CHANNEL, "%i ", linkTable[flood_pack.floodSource].neighbors[i]);
        }
        dbg_clear(ROUTING_CHANNEL, "\n");

        call Flooding.receiveHandler(myMsg);
    }

    // 3. Shortest path calculation using Dijkstra's algorithm: build and keep up to date a routing
    // table that allows us to determine the next hop to forward a packet toward its destination
    command void LinkStateRouting.Dijkstra(){
        uint8_t i;
        uint8_t j;

        bool considered[MAX_NEIGHBORS];
        
        // Initialization:
        // N’ = {u} // Compute least cost path from u to all other nodes
        // For all nodes a
        // If a adjacent to u // u initially knows direct-path-cost to direct neighbors
        // Then D(a) = Cu,a // but it may not be the minimum cost!
        //         Else D(a) = ∞
        for(i = 0; i < MAX_NEIGHBORS; i++){
            if(linkTable[i].address == TOS_NODE_ID){
                forwardingTable[i].cost[i] = 0;
            }
            for(j = 0; j < MAX_NEIGHBORS; j++){
                if(nodeTable[i].address == 1){
                    forwardingTable[i].cost[j] = 1;
                }
                else{
                    forwardingTable[i].cost[j] = 255;
                }
            }
            forwardingTable[i].nextHop = 255;
        }

        for(i = 0; i < MAX_NEIGHBORS; i++){
            dbg(ROUTING_CHANNEL, "forwarding: %d %d \n", i, forwardingTable[i].address); 

            for(j = 0; j < MAX_NEIGHBORS; j++){
                // if(linkTable[i].neighbors[j] != INFINITY){
                    dbg(ROUTING_CHANNEL, "neighbors: %d \n", j);
                // }
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

        // Unnconsidered = forwardingTable
        while(TRUE){
            bool consider = FALSE; 
            uint8_t lowestCost = INFINITY;
            uint8_t costHolder = 0;

            for(i = 0; i < MAX_NEIGHBORS; i++){
                // Handle considered, if all elements are considered, we then exit this loop
                if(considered[i]){
                    consider = TRUE;
                    break;
                }
                // Find C(w) is the smallest in unconsidered
                if(!considered[i] && forwardingTable[i].cost[i] < lowestCost){
                    lowestCost = forwardingTable[i].cost[i];
                }
                // Check all the neighbors of this link (lowest cost link)
                // linkTable[i] is stuck on a certain node, we check their neighbors.
                for(j = 0; j < MAX_NEIGHBORS; j++){
                    if(!considered[j] && linkTable[i].neighbors[j]){
                        costHolder = lowestCost + linkTable[i].neighbors[j];

                    }
                }
                considered[i] = TRUE;
            }
            // Since we exit the loop, we also set consider to true, breaking the while loop
            if(consider == TRUE){
                break;
            }
        }
    }

    // // 4. Forwarding: to send packets using routing table for next hops
    // command error_t LinkStateRouting.forward(pack *msg){
    //     // if(call Sender.send(pkt, dest) == SUCCESS){
    //     //     dbg(ROUTING_CHANNEL, "SUCCESS: Forwarding with Link State Routing Complete")
    //     // }
    // }


    // // Result of the algorithm should be a routing table containing the next-hop neighbor to send to for each destination address.
    // command void LinkStateRouting.listRouteTable(uint8_t srcNode){
    //     // List forwarding table for certain node
    //     uint8_t i;
        
    //     for(i = 0; i < MAX_NEIGHBORS; i++){
    //         dbg_clear(ROUTING_CHANNEL, "===========================\nRouting Table for Node %d\n", TOS_NODE_ID);
    //         dbg_clear(ROUTING_CHANNEL, "Dest    Cost    NextHop");
    //         // dbg_clear(ROUTING_CHANNEL, "%d      %d      %d \n===========================", linkTable[i].address, linkTable[i].cost, linkTable[i].nextHop)
    //     }
    // }
}