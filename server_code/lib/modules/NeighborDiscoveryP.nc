#include "../../includes/neighbor.h"

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;

    uses interface Timer<TMilli> as discoveryTimer;
    uses interface Timer<TMilli> as neighorCheckTimer;
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

    // Neighbor Table:
        // Neighbor Address
        // Quality of Link
        // Active Neighbor
    bool active = FALSE; // 0 = Receiving; 1 = Sending
    bool deadNeighbor = FALSE;
    Neighbor nodeTable[MAX_NODES];
    uint8_t nodeTableIndex = 0;
    uint8_t neighborIndex = 0;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void NeighborDiscovery.addNeighbor(uint8_t node, uint8_t neighbor){
        uint8_t i = 0;
        nodeTable[node].address = node;
        for(i; i < MAX_NEIGHBORS; i++){
            if(nodeTable[node].neighbors[i] == 0){
                nodeTable[node].neighbors[i] = neighbor;
                dbg(NEIGHBOR_CHANNEL, "Node %d has a new neighbor, %d\n", node, neighbor);
                break;
            }
        }
        // nodeTable[nodeTableIndex].address = node;
        // nodeTable[nodeTableIndex].neighbors[neighborIndex] = neighbor;
    }

    void refreshTable(){
        uint8_t i = 0;
        uint8_t j = 0;
        for(i; i < MAX_NODES; i++){
            for(j; j < MAX_NEIGHBORS; j++){
                nodeTable[i].neighbors[j] == 0;
            }
        }
        dbg(NEIGHBOR_CHANNEL, "Node Table Refreshed\n");
    }

    command void NeighborDiscovery.listHood(){
        uint8_t i = 0;
        uint8_t j = 0;
        for(i; i < MAX_NODES; i++){
            dbg(NEIGHBOR_CHANNEL, "Node %d Address: %u\n", i, nodeTable[i].address);
            for(j; j < MAX_NEIGHBORS; j++){
                dbg(NEIGHBOR_CHANNEL, "Node %d's Neighbor %d: %u\n", i, j, nodeTable[i].neighbors[j]);
            }
        }
    }

    // 30 second timer - Post a task (Neighbor Finding task)
    // call discoveryTimer.startPeriodic(30000);
    // event void discoveryTimer.fired() then send ping, wait for response
    command void NeighborDiscovery.findNeighbor(){
        dbg(NEIGHBOR_CHANNEL, "Find Neighbor Activated\n");
        if(!active){
            active = TRUE;
            refreshTable();
            call discoveryTimer.startPeriodic(30000);
        }
    }

    command void NeighborDiscovery.checkNeighbor(){
        dbg(NEIGHBOR_CHANNEL, "Checking for Neighbors\n");
        if(!deadNeighbor){
            deadNeighbor = TRUE;
            call neighorCheckTimer.startPeriodic(5000);
        }
    }

    // 
    event void discoveryTimer.fired(){
        pack pkt;
        if(active){
            makePack(&pkt, TOS_NODE_ID, 0, 0, PROTOCOL_NEIGHBOR, 0, "Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
            if(call Sender.send(pkt, AM_BROADCAST_ADDR) == SUCCESS){
                dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery message sent\n");
            }
            else{
                dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery message UNSUCCESSFULLY sent\n");
            }
        }
        active = FALSE;
        dbg(NEIGHBOR_CHANNEL, "Discovery timer fired\n");
    }

    event void neighorCheckTimer.fired(){
        pack pkt;
        if(deadNeighbor){
            uint8_t i = 0;
            for(i; i < MAX_NEIGHBORS; i++){
                makePack(&pkt, TOS_NODE_ID, nodeTable[TOS_NODE_ID].neighbors[i], 0, PROTOCOL_CHECK, 0, "Check Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
                if(call Sender.send(pkt, nodeTable[TOS_NODE_ID].neighbors[i]) == SUCCESS){
                    dbg(NEIGHBOR_CHANNEL, "Dead Neighbor Check\n");
                }
                else{
                    dbg(NEIGHBOR_CHANNEL, "CANNOT check for Dead Neighbors\n");
                }
            }
        }
    }

    command void NeighborDiscovery.removeNeighbor(uint8_t node, uint8_t neighbor){
        uint8_t i = 0;
        for(i; i < MAX_NEIGHBORS; i++){
            if(nodeTable[TOS_NODE_ID].neighbors[i] != 0){
                nodeTable[TOS_NODE_ID].neighbors[i] = 0;
                dbg(NEIGHBOR_CHANNEL, "Node %d has a DEAD neighbor, %d\n", node, neighbor);
                break;
            }
        }
    }
}