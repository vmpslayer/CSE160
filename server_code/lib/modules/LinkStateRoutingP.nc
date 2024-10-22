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
        
        // Takes stuff from the payload and puts it into floodPack
        memcpy(&flood_pack, myMsg.payload, sizeof(floodPack));

        /*
        for(i = 0; i < 4; i++){
            dbg(ROUTING_CHANNEL,"Received neighbor %d, %u from %i\n", i, flood_pack.payload[i], myMsg.src);
        }
        */

        // dbg(ROUTING_CHANNEL, "These are the neighbors of: %i\n", flood_pack.floodSource);

        
        dbg(ROUTING_CHANNEL, "Node %i has the neighbors (Packet): ", myMsg.src);
        for(i = 0; i < 4; i++){
            dbg_clear(ROUTING_CHANNEL, "%i ", flood_pack.payload[i]);
        }
        dbg_clear(ROUTING_CHANNEL, "\n");

        // dbg(ROUTING_CHANNEL, "linkTable[%i].neighbors[0]: ", flood_pack.floodSource, linkTable[flood_pack.floodSource].neighbors[0]);
        
        linkTable[flood_pack.floodSource].address = flood_pack.floodSource;
        for(i = 0; i < 4; i++){
            dbg_clear(ROUTING_CHANNEL, "%i ", linkTable[flood_pack.floodSource].neighbors[i]);
        }

        dbg(ROUTING_CHANNEL, "Node %i has the neighbors (LinkTable): ", linkTable[flood_pack.floodSource].address);
        for(i = 0; i < 4; i++){
            dbg_clear(ROUTING_CHANNEL, "%i ", linkTable[flood_pack.floodSource].neighbors[i]);
        }
        dbg_clear(ROUTING_CHANNEL, "\n");

        call Flooding.receiveHandler(myMsg);
    }

    // 3. Shortest path calculation using Dijkstra's algorithm: build and keep up to date a routing
    // table that allows us to determine the next hop to forward a packet toward its destination
    command error_t LinkStateRouting.Dijkstra(){
        uint8_t i;
        bool considered[MAX_NEIGHBORS];
        
        dbg(ROUTING_CHANNEL,"SUCCESS: Dijkstra Algorithm Started\n");
        // Initialization:
        // N’ = {u} // Compute least cost path from u to all other nodes
        // For all nodes a
        // If a adjacent to u // u initially knows direct-path-cost to direct neighbors
        // Then D(a) = Cu,a // but it may not be the minimum cost!
        //         Else D(a) = ∞
        for(i = 1; i < MAX_NEIGHBORS; i++){
            if(linkTable[i].address == TOS_NODE_ID){
                forwardingTable[i].cost = 0;
                considered[i] = TRUE;
            }
            else if(nodeTable[i].address == 1){
                // dbg(GENERAL_CHANNEL, "%d \n", i);
                forwardingTable[i].cost = 1;
                forwardingTable[i].nextHop = i;
                considered[i] = FALSE;
            }
            else{
                forwardingTable[i].cost = INFINITY;
                forwardingTable[i].nextHop = INFINITY;
                considered[i] = FALSE;
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
            uint8_t w = 0;
            uint8_t lowestCost = INFINITY;
            uint8_t hopCost = 0;

            dbg(ROUTING_CHANNEL, "SUCCESS: REACHED WHILE LOOP\n");

            for(i = 1; i < MAX_NEIGHBORS; i++){
                // Handle considered, if all elements are considered, we then exit this loop
                if(!considered[i]){
                    consider = TRUE;
                }
            }
            for(i = 1; i < MAX_NEIGHBORS; i++){
                // Find C(w) is the smallest in unconsidered
                if(!considered[i] && forwardingTable[i].cost < lowestCost){
                    lowestCost = forwardingTable[i].cost;
                    w = i;
                    dbg(ROUTING_CHANNEL, "W: %d\n", w);
                }
            }
            // Since we exit the loop, we also set consider to true, breaking the while loop

            // Passed consider check, now checking for neighbors for each node
            // if the cost of my forwardingTable at [w] to a certain node +1 is < cost of neighbor under consideration
            for(i = 1; i < MAX_NEIGHBORS; i++){
                // Check all the neighbors of this link (lowest cost link)
                // linkTable[i] is stuck on a certain node, we check their neighbors.
                dbg(ROUTING_CHANNEL, "linkTable[w].neighbors[i]: %d \n", linkTable[w].neighbors[i]);
                if(linkTable[w].neighbors[i] != 0){
                    // C(w) + L(w,n)
                    hopCost = lowestCost + 1;
                    dbg(ROUTING_CHANNEL, "hopCost: %d \n", hopCost);

                    // Check if the hop cost is lower 
                    if(hopCost < forwardingTable[linkTable[w].neighbors[i]].cost){
                        forwardingTable[linkTable[w].neighbors[i]].cost = hopCost;
                        forwardingTable[linkTable[w].neighbors[i]].nextHop = forwardingTable[w].nextHop; 
                    }
                }
            }
            if(consider == TRUE) break;
            considered[w] = TRUE;
        }
        call LinkStateRouting.listRouteTable();
    }

    // 4. Forwarding: to send packets using routing table for next hops
    // command error_t LinkStateRouting.forward(pack *msg){
    //     if(call Sender.send(pkt, dest) == SUCCESS){
    //         dbg(ROUTING_CHANNEL, "SUCCESS: Forwarding with Link State Routing Complete")
    //     }
    // }

    // Result of the algorithm should be a routing table containing the next-hop neighbor to send to for each destination address.
    command void LinkStateRouting.listRouteTable(){
        // List forwarding table for certain node
        uint8_t i;
        dbg_clear(ROUTING_CHANNEL, "===========================\nRouting Table for Node %d\n", TOS_NODE_ID);
        dbg_clear(ROUTING_CHANNEL, "Dest    Cost    NextHop\n");
        for(i = 1; i < MAX_NEIGHBORS; i++){
            dbg_clear(ROUTING_CHANNEL, "%d        %d        %d \n", i, forwardingTable[i].cost, forwardingTable[i].nextHop);
        }
        dbg_clear(ROUTING_CHANNEL, "===========================\n");
    }
}