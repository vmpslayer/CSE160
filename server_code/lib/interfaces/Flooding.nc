#include "../../includes/packet.h"

interface Flooding{
    command error_t flood(pack msg);
    command void reset();
    command void receiveCheck(); // Debug tool
}