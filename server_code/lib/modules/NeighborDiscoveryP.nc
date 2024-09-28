#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/am_types.h"

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;

    uses interface Timer<TMilli> as discoveryTimer;
    uses interface SimpleSend as Sender;
    uses interface Receive as Receiver;
    uses interface Random;
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
    Neighbor nodeTable[10];
    uint8_t nodeTableIndex = 0;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    void addNeighbor(uint8_t node, uint8_t neighbor){
        uint8_t neighborIndex = 0;
        nodeTable[nodeTableIndex].address = node;
        nodeTable[nodeTableIndex].neighbors[neighborIndex] = neighbor;
    }

    command void NeighborDiscovery.listNeighborhood(){
        uint8_t i = 0;
        for(i; i < sizeof(nodeTable); i++){
            dbg(NEIGHBOR_CHANNEL, "");
        }
    }

    // 30 second timer - Post a task (Neighbor Finding task)
    // call discoveryTimer.startPeriodic(30000);
    // event void discoveryTimer.fired() then send ping, wait for response
    command void NeighborDiscovery.findNeighbor(){
        dbg(NEIGHBOR_CHANNEL, "Find Neighbor Activated\n");
        if(!active){
            active = TRUE;
            call discoveryTimer.startPeriodic(30000);
        }
    }

    // 
    event void discoveryTimer.fired(){
        pack pkt;
        if(active){
            makePack(&pkt, TOS_NODE_ID, AM_BROADCAST_ADDR, 0, 0, PROTOCOL_PING, "Neighbor Test", PACKET_MAX_PAYLOAD_SIZE);
            if(call Sender.send(pkt, AM_BROADCAST_ADDR) == SUCCESS){
                dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery message sent\n");
            }
            else{
                dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery message UNSUCCESSFULLY sent");
            }
        }
        active = FALSE;
        dbg(NEIGHBOR_CHANNEL, "Discovery timer fired\n");
    }

    // Upon reception of a neighbor discovery packet, receiving node must reply back
    event message_t* Receiver.receive(message_t* msg, void* payload, uint8_t len){
        dbg(NEIGHBOR_CHANNEL, "Packet Received\n");
        if(len==sizeof(pack)){
            pack* myMsg=(pack*) payload;
            dbg(NEIGHBOR_CHANNEL, "Package Payload: %s\n", myMsg->payload);
            if(myMsg->dest == AM_BROADCAST_ADDR){
                myMsg->dest = myMsg->src;
                myMsg->src = TOS_NODE_ID;
                myMsg->protocol = PROTOCOL_PINGREPLY;
                call Sender.send(*myMsg, myMsg->dest);
            }
            else if(myMsg->dest == TOS_NODE_ID){
                addNeighbor(myMsg->src, myMsg->dest);
            }
        }
        dbg(NEIGHBOR_CHANNEL, "Unknown Packet Type %d\n", len);
        return msg;
    }
}