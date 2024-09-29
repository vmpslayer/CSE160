#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/am_types.h"
module FloodingP{
    provides interface Flooding;

    uses interface SimpleSend as Sender;
    uses interface Receive;
    uses interface Pool<pack>;
}
implementation{
    // Sequence Number
    uint16_t seqNum = 0;

    command error_t Flooding.flood(pack msg, uint16_t src){
        msg.dest = 0xFFFF; // Broadcast address
        msg.src = src;
        msg.seq = seqNum++;
        msg.TTL = MAX_TTL;
        msg.protocol = PROTOCOL_FLOODING;

        dbg(FLOODING_CHANNEL, "Node %d has send a message\n");
        return call Sender.send(msg, 0xFFFF);
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        pack *receivedPacket = (pack*) payload;

        if(receivedPacket->TTL > 0){
            receivedPacket->TTL--;

            call Flooding.flood(*receivedPacket, receivedPacket->src);
        }

        return msg;
    }
}