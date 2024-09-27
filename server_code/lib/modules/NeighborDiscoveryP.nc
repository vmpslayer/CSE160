#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/am_types.h"

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;
    
    uses interface Timer<TMilli> as discoveryTimer;
    uses interface Boot;
    // uses interface Packet;
    // uses interface AMPacket;
    // uses interface AMSend;
    // uses interface AMReceiverC;
}
implementation{
    // ndPeriod = 30000; // 30 seconds in milliseconds
    message_t transmitMsg;
    bool active; // If node is active or alive

    typedef nx_struct Neighbor{
        nx_uint8_t address; // Identifier for node
        nx_uint16_t pktReceived; // For calculations, X = total packets received
        nx_uint16_t pktSent; // For calculations, Y = total packets sent
    } Neighbor;

    typedef nx_struct NeighborDiscoveryMsg{
        nx_uint8_t type; // Request or Reply
        nx_uint16_t sequenceNum; // Sequence number
        nx_uint16_t sourceAddr; // Source address
        nx_uint16_t destAddr; // Destination address
    } NDMsg;

    command void NeighborDiscovery.findNeighbor(NDMsg msg){
        uint8_t type = msg.type;
        uint16_t sequenceNum = msg.sequenceNum;
        uint16_t sourceAddr = msg.sourceAddr;
        uint16_t destAddr = msg.destAddr;

        dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery: Type=%d, Seq=%d, Src=%d, Dst=%d\n", type, sequenceNum, sourceAddr, destAddr);
        return SUCCESS;
    }

    event void Boot.booted() {
        call discoveryTimer.startPeriodic(30000);
        dbg(NEIGHBOR_CHANNEL, "Booted and Timer Started\n");
    }

    event void discoveryTimer.fired(){
        dbg(GENERAL_CHANNEL, "Discovery timer fired\n");
    }
}