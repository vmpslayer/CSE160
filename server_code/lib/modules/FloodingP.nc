#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/am_types.h"
module FloodingP{
    provides interface Flooding;
}
implementation{

    command error_t Flooding.flood(pack msg, uint16_t dest){

        // If the packet has reached its destination 
        return SUCCESS;
    }
}