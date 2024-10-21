#include "../../includes/linkstate.h"
#include "../../includes/packet.h"
#include "../../includes/routing.h"
interface LinkStateRouting{
    command error_t initLinkState();
    // command error_t forward();
    command void receiveHandler(pack myMsg);
    // command void listRoute(uint8_t srcNode);
    command void Dijkstra();
}