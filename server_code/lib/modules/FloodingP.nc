#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/am_types.h"
module FloodingP{
    provides interface Flooding;
}
implementation{
    /* Flooding - Each node floods a packet to all its neighbor nodes. These
    packets continue to flood until they reach their final destination.
    Must work as pings and ping replies. Only use information accessible
    from the packet and its headers 
    
    There are protocols PING = 0, and PINGREPLY = 1.

    am_types has AM_FLOODING = 10

    If flood is called, the node will send out a flood type (protocol) packet 
    to all nodes around it using AM_BROADCAST_ADDR
    */
    command error_t Flooding.flood(pack msg, uint16_t dest){

        // If the packet has reached its destination 
        return SUCCESS;
    }
}