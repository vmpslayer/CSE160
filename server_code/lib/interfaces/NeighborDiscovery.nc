#include "../../includes/neighbor.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command error_t NeighborDiscovery.initNeighborDisco(){
    event void updateListener(Neighbor table);
    command void addNeighbor(uint8_t node);
    command void removeNeighbor(uint8_t node);
    command error_t receiveHandler(pack msg);
}   