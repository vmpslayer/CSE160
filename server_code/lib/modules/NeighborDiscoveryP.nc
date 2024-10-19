#include "../../includes/neighbor.h"

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;

    uses interface Timer<TMilli> as discoveryTimer;
    uses interface SimpleSend as Sender;
}
implementation{
    // 1. Discovery Header:
        // Request or Reply Field
        // Monotonically increasing sequence number to uniquely identify the packet
        // Link layer for source address (source address, destination address)
        // Request/reply & Sequence Number
        // Source Address & Destination Address
        // Notes: Can use simple send for this, sending a simple packet

    // Gather statistics
        // X = total packets received
        // Y = total packets send
        // Link quality (t + 1) = X(t + 1) / Y(t + 1) = 60/120 = 50%
    bool active = FALSE; // 0 = Receiving; 1 = Sending
    bool knownNeighbor = FALSE; // Neighbor Check // 0 = unknown, 1 = known
    bool deadNeighbor = FALSE;
    uint8_t sqNumber = 0;
    Neighbor nodeTable[MAX_NEIGHBORS]; // Houses just THIS node's neighbors
    uint8_t nodeTableIndex = -1;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void NeighborDiscovery.addNeighbor(uint8_t srcNode){
        nodeTable[srcNode].pktReceived++;

        if(nodeTable[srcNode].address == 1){
            // dbg(NEIGHBOR_CHANNEL, "EXISTS: Node %d already has neighbor node %d\n", TOS_NODE_ID, srcNode);
            return;
        }
        else if(nodeTable[srcNode].address == 0){
            dbg(NEIGHBOR_CHANNEL, "NEW: Node %d discovered a new neighbor node %d\n", TOS_NODE_ID, srcNode);
            nodeTable[srcNode].pktReceived = 0;
            nodeTable[srcNode].pktSent = 0;
            nodeTable[srcNode].address = 1;
            return;
        }
        nodeTable[srcNode].qol = nodeTable[srcNode].pktReceived / nodeTable[srcNode].pktSent;
    }

    void refreshTable(){
        uint8_t i;
        for(i = 0; i < MAX_NEIGHBORS; i++){
            if(nodeTable[i].address != 0){
                nodeTable[i].address = 0;
            }
            else{
                break;
            }
        }
        dbg(NEIGHBOR_CHANNEL, "SUCCESS: Node Table Refreshed\n");
    }
    
    // Neighbor Table:
        // Neighbor Address
        // Quality of Link
        // Active Neighbor
    void listHood(){
        uint8_t i;
        bool hasNeighbors = FALSE;

        for(i = 0; i < MAX_NEIGHBORS; i++){
            if(nodeTable[i].address != 0){
                hasNeighbors = TRUE;
                break;
            }
        }
        if(hasNeighbors){
            dbg(NEIGHBOR_CHANNEL, "Node %d's Neighbors: ", TOS_NODE_ID);
            for(i = 0; i < MAX_NEIGHBORS; i++){
                if(nodeTable[i].address == 0){
                    
                }
                else{
                    dbg_clear(NEIGHBOR_CHANNEL, "%d ", i);
                    dbg(NEIGHBOR_CHANNEL, "%d's Link Quality: %d\n", i, nodeTable[i].qol);
                }
                // dbg_clear(NEIGHBOR_CHANNEL, "%d ", nodeTable[i]);
            }
            dbg_clear(NEIGHBOR_CHANNEL, "\n");
        }
    }

    // 30 second timer - Post a task (Neighbor Finding task)
    // call discoveryTimer.startPeriodic(30000);
    // event void discoveryTimer.fired() then send ping, wait for response
    command void NeighborDiscovery.findNeighbor(){
        dbg(NEIGHBOR_CHANNEL, "SUCCESS: Find Neighbor Activated\n");
        if(!active){
            active = TRUE;
            call discoveryTimer.startPeriodic(30000);
        }
    }

    event void discoveryTimer.fired(){
        pack pkt;
        if(active){
            makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_NEIGHBOR, sqNumber, "Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
            if(call Sender.send(pkt, AM_BROADCAST_ADDR) == SUCCESS){
                // dbg(NEIGHBOR_CHANNEL, "SUCCESS: Neighbor Discovery packet (%d) sent\n", sqNumber);
                sqNumber++;
                nodeTable[TOS_NODE_ID].pktSent++;
            }
            else{
                dbg(NEIGHBOR_CHANNEL, "ERROR: Neighbor Discovery message UNSUCCESSFULLY sent\n");
            }
        }
        listHood();
    }

    command void NeighborDiscovery.removeNeighbor(uint8_t srcNode){
        nodeTable[srcNode].address = 0;
        dbg(NEIGHBOR_CHANNEL, "DEATH: Node %d has a DEAD (he died) neighbor, %d\n", TOS_NODE_ID, srcNode);
    }
}