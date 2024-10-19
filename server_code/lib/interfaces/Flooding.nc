#include "../../includes/packet.h"

interface Flooding{
    command error_t initFlood(pack msg);
    command error_t receiveHandler(pack msg);
}