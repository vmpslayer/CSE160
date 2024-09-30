#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/am_types.h"
module FloodingP{
    provides interface Flooding;
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
    command error_t Flooding.flood(pack msg, uint16_t dest){
        dbg(FLOODING_CHANNEL, "Flooding?\n");
        // If the packet has reached its destination 
        return SUCCESS;
    }
}