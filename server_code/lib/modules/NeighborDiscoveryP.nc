#include "../../includes/node.h"

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
    bool deadNeighbor = FALSE; // Dead Neighbor Check // 0 = inactive, 1 = active
    Node device; // House all information; address, pkt sent/receive
    uint8_t nodeTable[MAX_NEIGHBORS]; // Houses just THIS node's neighbors

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command void NeighborDiscovery.addNeighbor(uint8_t device, uint8_t neighbor){
        uint8_t nodeTableIndex = 0;
        nodeTable[nodeTableIndex] = neighbor;
        dbg(NEIGHBOR_CHANNEL, "Node %d has a new neighbor, %d\n", device, neighbor);
        nodeTableIndex++;
        // nodeTable[nodeTableIndex].address = node;
        // nodeTable[nodeTableIndex].neighbors[neighborIndex] = neighbor;
    }

    void refreshTable(){
        uint8_t i = 0;

        for(i; i < MAX_NEIGHBORS; i++){
            nodeTable[i] == 0;
        }
        dbg(NEIGHBOR_CHANNEL, "Node Table Refreshed\n");
    }

    command void NeighborDiscovery.listHood(){
        uint8_t i = 0;

        for(i; i < MAX_NEIGHBORS; i++){
            dbg(NEIGHBOR_CHANNEL, "Node %d's Neighbor: %u\n", device.address, nodeTable[i]);
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
            makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, 0, PROTOCOL_NEIGHBOR, 0, "Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
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
                makePack(&pkt, TOS_NODE_ID, nodeTable[i], 0, PROTOCOL_CHECK, 0, "Check Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
                if(call Sender.send(pkt, nodeTable[i]) == SUCCESS){
                    // dbg(NEIGHBOR_CHANNEL, "Dead Neighbor Check\n");
                }
                else{
                    dbg(NEIGHBOR_CHANNEL, "CANNOT check for Dead Neighbors\n");
                }
            }
        }
    }

    command void NeighborDiscovery.removeNeighbor(uint8_t device, uint8_t neighbor){
        uint8_t i = 0;

        for(i; i < MAX_NEIGHBORS; i++){
            if(nodeTable[i] != 0){
                nodeTable[i] = 0;
                dbg(NEIGHBOR_CHANNEL, "Node %d has a DEAD neighbor, %d\n", device, neighbor);
                break;
            }
        }
    }
}