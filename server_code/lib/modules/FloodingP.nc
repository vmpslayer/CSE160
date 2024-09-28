#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
module FloodingP{
    provides interface Flooding;

    uses interface SimpleSend as Sender;
    uses interface Receive as Receiver;
    uses interface Packet;
}
implementation{
    uint16_t sequence = 0;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    command error_t Flooding.flood(void* payload, uint8_t len){
        pack floodPacket
        floodPacket.src = TOS_NODE_ID;
        floodPacket.dest = TOS_BCAST_ADDR;
        floodPacket.seq = seq + 1;
        floodPacket.TTL = MAX_TTL;
        floodPacket.protocol = AM_FLOODING;

        memcpy(floodPacket.payload, payload, len);

        error_t sendResult = call Sender.send(floodPacket, TOS_BCAST_ADDR);
        if(sendResult == SUCCESS){
            dbg(GENERAL_CHANNEL, "Flood Pckaet sent\n");
        }
        else
        {
            dbg(GENERAL_CHANNEL, "Failed to send flood packet\n");
        }
        return sendResult
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        if(len == sizeof(pack)){
            pack* receivedPacket = (pack*) payload;

            if(receivedPacket->protocol == AM_FLOODING){
                logPack(receivedPacket);

                if(receivedPacket->TTL > 0 && receivedPacket->seq > sequence){
                    sequence = receivedPacket->seq;

                    receivedPacket->TTL--;
                    call Sender.send(receivedPacket, TOS_BCAST_ADDR);

                    signal Flooding.floodReceive(receivedPacket->src, receivedPacket->payload, len);
                    dbg(FLOODING_CHANNEL, "Node %d recieved flood packet from %d\n", TOS_NODE_ID, receivedPacket->src);
                }
            }
        }
        return msg;
    }

    event void Sender.sendDone(message_t *msg, error_t error){
        if (error == SUCCESS){
            dbg(GENERAL_CHANNEL, "Send completed successfully\n");
        }
        else
        {
            dbg(GENERAL_CHANNEL, "Send failed\n");
        }
    }
}