#include "../../includes/linkstate.h"
#include "../../includes/packet.h"
#include "../../includes/routing.h"
interface LinkStateRouting{
    command error_t initLinkState();
    command void receiveHandler(pack myMsg);
    command error_t Dijkstra();
    // command error_t forward();
    command void listRouteTable();
    command void listLinkStateTable();
}