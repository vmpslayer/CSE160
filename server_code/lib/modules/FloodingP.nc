#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/am_types.h"
module FloodingP{
    provides interface Flooding;

    uses interface Timer<TMilli> as floodTimer;
    uses interface SimpleSend as Sender;
}
implementation{
    /*
    Flooding - Each node floods a packet to all its neighbor nodes. These
    packets continue to flood until they reach their final destination.
    Must work as pings and ping replies. Only use information accessible
    from the packet and its headers 
    
    There are protocols PING = 0, and PINGREPLY = 1.

    am_types has AM_FLOODING = 10

    If flood is called, the node will send out a flood type (protocol) packet 
    to all nodes around it using AM_BROADCAST_ADDR. Then receive will check if
    the protocol is flood. If it is, then it will check if it has received the
    payload before. If not it will check if its the intented destination.
    If not, send it to all nodes around it.

    This will be accomplished by creating a new function in TestSim.py that will
    take in a source node, a destination node, and a payload message. These
    parameters will then be fed into the send command fucntion with the flooding
    command ID. Which the command handler will then need a flood command switch
    case, which will make a call to a Command Handler flood event.
    The Command Handler flood event needs to be declared in CommandHandler.nc and
    defined in Node.nc. This flood event will have a debug message stating that
    flooding has been selected as the chosen 'event'. From there, the actual
    Flooding.flood command will be executed, which will utilize SimpleSend to
    broadcast the packet to all available nodes. When a node receives the flooding
    packet, it will check if it is the intended destination for the packet.
    If not, it will check if it has received the packet before. If it has not,
    it will rebroadcast too all available nodes.
    */
    bool flooding = FALSE;
    uint8_t init = 0;

    uint16_t received[20];
    //uint16_t receivedIndex = 0;

    pack sendPackage;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    bool hasReceived(uint16_t src);    

    command void Flooding.resetTable(){
        uint8_t entry;
        for(entry = 0; entry < 20; entry++){
            received[entry] = 0;
            // dbg(FLOODING_CHANNEL, "%i\n", received[entry]);
        }
        dbg(FLOODING_CHANNEL, "Reseting table...\n");
        dbg(FLOODING_CHANNEL, "received[%i] = %i\n", TOS_NODE_ID, received[TOS_NODE_ID]);
    }

    command error_t Flooding.flood(pack msg){       
        if(init == 0){
            init++;
            flooding = TRUE;
        }

        dbg(FLOODING_CHANNEL, "received[%i] = %i\n", TOS_NODE_ID, received[TOS_NODE_ID]);

        // If the packet still has life and the source node is not in the received list
        if(msg.TTL > 0 && received[TOS_NODE_ID] == 0 && flooding == TRUE){
            // Add the source node to the list
            received[TOS_NODE_ID] = 1;
            dbg(FLOODING_CHANNEL, "Node %i has initiated flooding.\n", TOS_NODE_ID);

            dbg(FLOODING_CHANNEL, "received[%i] = %i\n", TOS_NODE_ID, received[TOS_NODE_ID]);

            makePack(&sendPackage, msg.src, msg.dest, (msg.TTL - 1), msg.protocol, msg.seq, msg.payload, ""); // Why does this work?
            // dbg(FLOODING_CHANNEL, "payload: %s\n", sendPackage.payload);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            // If the packet has reached its destination 
            return SUCCESS;
        }

        return FAIL;
    }

    command void Flooding.reset(){
        flooding = FALSE;
        init = 0;
    }

    event void floodTimer.fired(){
        dbg(FLOODING_CHANNEL, "Hello my friend :3\n");
    }

    command void Flooding.receiveCheck(){
        dbg(FLOODING_CHANNEL, "received[%i] = %i\n", TOS_NODE_ID, received[TOS_NODE_ID]);
    }

    /*
    bool hasReceived(uint16_t src){
        for(i = 0; i < receivedIndex; i++){
            if(received[i]==src){
                return TRUE;
            }
        }
        dbg(FLOODING_CHANNEL, "Fail\n");
        return FALSE;
    }
    */

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}