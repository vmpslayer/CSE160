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

    // Helper function for Node Q
    bool allConsidered(bool *considered){
        int i;

        for(i = 0; i < MAX_NEIGHBORS; i++){
            if(!considered[i]){
                return FALSE;
            }
        }
        return TRUE;
    }

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
        // Initializing an array of addresses with a max of 4 entries
        uint8_t neighbors[MAX_NEIGHBORS];
        i = 0;
        j = 0;

        // Filling the payload with the information already on the node
        while(j < MAX_NEIGHBORS && i < MAX_NEIGHBORS){
            if(nodeTable[j].address != 0){
                neighbors[i] = j;
                i++;
                // dbg(ROUTING_CHANNEL,"Node %i: neighbors[%d]: %d \n", TOS_NODE_ID, i, j);
            }
            j++;
        }
        
        makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKSTATE, lsSeqNum, (uint8_t*)neighbors, MAX_NEIGHBORS*sizeof(neighbors));

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
        
        // Copy the payload to parse the data
        // dbg(ROUTING_CHANNEL, "Before memcpy: linkTable[0] neighbors: %d\n", linkTable[1].neighbors[0]);
        memcpy(&flood_pack, myMsg.payload, sizeof(linkTable[flood_pack.floodSource].neighbors));
        // dbg(ROUTING_CHANNEL, "After memcpy: linkTable[0] neighbors: %d\n", linkTable[1].neighbors[0]);

        linkTable[flood_pack.floodSource].address = flood_pack.floodSource;
        // Fill the linkTable for floodSource address entry with its neighbors
        
        for(i = 0; i < MAX_NEIGHBORS + 2; i++){
            if(flood_pack.payload[i] != 0){
                linkTable[flood_pack.floodSource].neighbors[i] = flood_pack.payload[i];
            }
            else{
                break;
            }
        }
        
        // if(TOS_NODE_ID == 19){
        //     dbg(GENERAL_CHANNEL, "Node 19 Receives from Node %d", flood_pack.floodSource);
        //     for(i = 0; i < MAX_NEIGHBORS; i++){
        //         dbg(GENERAL_CHANNEL, "%d \n", flood_pack.payload[i]);

        //         // for(j = 0; j < MAX_NEIGHBORS; j++){
        //         //     if(linkTable[i].neighbors[j] != 0){
        //         //         dbg_clear(GENERAL_CHANNEL, "%d \n", linkTable[i].neighbors[j]);
        //         //     }
        //         // }
        //         dbg_clear(GENERAL_CHANNEL, "\n");
        //     }
        // }

        // Flood the neighbor information to the rest of the network
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
        // Else D(a) = ∞
        for(i = 1; i < MAX_NEIGHBORS; i++){

            // dbg(ROUTING_CHANNEL, "In node %i, linkTable[%i].address = %i\n", TOS_NODE_ID, i, linkTable[i].address);

            if(linkTable[i].address == TOS_NODE_ID){
                forwardingTable[i].cost = 0;
                forwardingTable[i].altCost = 0;
                considered[i] = TRUE;
            }
            // Since this loop is iterating through all addresses in linkTable
            // its going to find the Nodes in the linkTable that match addresses
            // with the neighbor data and set their cost to 1
            else if(nodeTable[i].address != 0){
                // dbg(ROUTING_CHANNEL, "Node %i has a neighbor at %i", TOS_NODE_ID, i);
                forwardingTable[i].cost = 1;
                forwardingTable[i].nextHop = i;
                forwardingTable[i].altNextHop = i;
                forwardingTable[i].altCost = 1;
                considered[i] = FALSE;
            }
            else{
                forwardingTable[i].cost = INFINITY;
                forwardingTable[i].nextHop = INFINITY;
                forwardingTable[i].altNextHop = INFINITY;
                forwardingTable[i].altCost = INFINITY;
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
        while(TRUE){
            uint8_t w;
            uint8_t lowestCost = INFINITY;
            uint8_t hopCost;

            // Exit the loop if all consideres values are TRUE
            // If Unconsidered == {} break
            if(allConsidered(considered)){
                break;
            }

            // Print all unconsidered
            // dbg(ROUTING_CHANNEL, "ALL UNCONSIDERED NODES: ");
            // for(i = 1; i < MAX_NEIGHBORS; i++){
            //     if(!considered[i]){
            //         dbg_clear(ROUTING_CHANNEL, "%d ", i);
            //     }
            // }
            // dbg_clear(ROUTING_CHANNEL, "\n");

            // Find C(w) is the smallest in unconsidered
            // dbg(ROUTING_CHANNEL, "SEARCHING FOR SHORTEST PATH\n");
            for(i = 1; i < MAX_NEIGHBORS; i++){
                if(!considered[i] && forwardingTable[i].cost < lowestCost){
                    // dbg(ROUTING_CHANNEL, "Node %i is %i away from Node %i\n", i, forwardingTable[i].cost, TOS_NODE_ID);
                    lowestCost = forwardingTable[i].cost;
                    w = i;
                }
            }         

            // dbg(ROUTING_CHANNEL, "The lowestCost is %i from i = %i\n", lowestCost, w);
            
            considered[w] = TRUE;
            // dbg(ROUTING_CHANNEL, "NODE %d HAS BEEN CONSIDERED\n", w);

            // dbg(ROUTING_CHANNEL, "Node %d has neighbors: ", w);
            for(i = 0; i < MAX_NEIGHBORS; i++){
                // dbg_clear(ROUTING_CHANNEL, "%d ", linkTable[w].neighbors[i]);
                // Set the cost of w's neighbors
                if(linkTable[w].neighbors[i] != 0 && forwardingTable[linkTable[w].neighbors[i]].cost > (forwardingTable[w].cost + 1)){
                    // dbg_clear(ROUTING_CHANNEL, "%d ", linkTable[w].neighbors[i]);
                    forwardingTable[linkTable[w].neighbors[i]].cost = forwardingTable[w].cost + 1;
                    forwardingTable[linkTable[w].neighbors[i]].nextHop = forwardingTable[w].nextHop;
                }
                // Alternate:
                if(forwardingTable[linkTable[w].neighbors[i]].cost > forwardingTable[w].cost + 1){
                    forwardingTable[linkTable[w].neighbors[i]].altCost = forwardingTable[w].cost + 1;
                    forwardingTable[linkTable[w].neighbors[i]].altNextHop = forwardingTable[w+1].nextHop;
                }
                else if(forwardingTable[linkTable[w].neighbors[i]].cost == forwardingTable[w].cost + 1){
                    forwardingTable[linkTable[w].neighbors[i]].altCost = forwardingTable[w].cost + 1;
                    forwardingTable[linkTable[w].neighbors[i]].altNextHop = forwardingTable[w].nextHop;
                    // dbg_clear(GENERAL_CHANNEL, "w: %d \n linkTable[w].neighbors[i]: %d \n linkTable[w + 1].neighbors[i]: %d \n linkTable[w + 1].neighbors[i + 1]: %d \n", w, linkTable[w].neighbors[i], linkTable[w + 1].neighbors[i], linkTable[w + 1].neighbors[i + 1]);
                }
            }
            // dbg_clear(ROUTING_CHANNEL, "\n");

            // Just to break the loop
            if(lowestCost == 255){
                break;
            }
            dbg_clear(ROUTING_CHANNEL, "\n");

            // Just to break the loop
            if(lowestCost == 255){
                break;
            }
        }
        call LinkStateRouting.listLinkStateTable();
        call LinkStateRouting.listRouteTable();
    }

    // 4. Forwarding: to send packets using routing table for next hops
    command error_t LinkStateRouting.forward(uint16_t dest, uint8_t *payload){
        uint8_t hoptoDest = forwardingTable[dest].nextHop;

        if(dest == TOS_NODE_ID){
            dbg(ROUTING_CHANNEL, "SUCCESS: Packet was received at destination %d; Message: \n", dest, payload);
            return SUCCESS;
        }

        makePack(&pkt, TOS_NODE_ID, dest, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
        dbg(ROUTING_CHANNEL, "SENDING: Sending packet to %d \n", dest);
        if(call Sender.send(pkt, dest) == SUCCESS){
            dbg(ROUTING_CHANNEL, "SUCCESS: Forwarding (using ping) with Link State Routing to Node %d \n", hoptoDest);
            return SUCCESS;
        }
        else{
            dbg(ROUTING_CHANNEL, "ERROR: Forwarding (using ping) with Link State Routing to Node %d has failed. Retrying with alternate path...\n", hoptoDest);
            hoptoDest = forwardingTable[dest].altNextHop;
            call Sender.send(pkt, hoptoDest);
            return FAIL;
        }
    }

    // Result of the algorithm should be a routing table containing the next-hop neighbor to send to for each destination address.
    command void LinkStateRouting.listRouteTable(){
        // List forwarding table for certain node
        uint8_t i;
        dbg_clear(ROUTING_CHANNEL, "========================\nRouting Table for Node %d\n", TOS_NODE_ID);
        dbg_clear(ROUTING_CHANNEL, "Dest    Cost    NextHop    AltCost    AltNextHop\n");
        for(i = 1; i < MAX_NEIGHBORS; i++){
            dbg_clear(ROUTING_CHANNEL, "%d        %d        %d          %d            %d \n", i, forwardingTable[i].cost, forwardingTable[i].nextHop, forwardingTable[i].altCost, forwardingTable[i].altNextHop);
        }
        dbg_clear(ROUTING_CHANNEL, "========================\n");
    }

    // Testing purposes
    command void LinkStateRouting.listLinkStateTable(){
        int i, j;
        dbg_clear(ROUTING_CHANNEL, "===========================\nLink State Table for Node %d\n", TOS_NODE_ID);
        dbg_clear(ROUTING_CHANNEL, "Node    Neighbors\n");
        for(i = 1; i < MAX_NEIGHBORS; i++){
            if(linkTable[i].address != 0){
                dbg_clear(ROUTING_CHANNEL, "%d       ", linkTable[i].address);
                for(j = 0; j < MAX_NEIGHBORS; j++){
                    if(linkTable[i].neighbors[j] != 0 && linkTable[i].neighbors[j] < MAX_NEIGHBORS){
                        dbg_clear(ROUTING_CHANNEL, "%d ", linkTable[i].neighbors[j]);
                    }
                }
                dbg_clear(ROUTING_CHANNEL, "\n");
            }
        }
        dbg_clear(ROUTING_CHANNEL, "===========================\n");
    }
}
