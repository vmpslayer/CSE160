#ifndef TCP_H
#define TCP_H

#include "packet.h"

enum flag_type{
    SYN,
    SYNACK,
    ACK,
    FIN,
    DATA
};

enum{
    TCP_HEADER_LENGTH = 7,
	TCP_MAX_PAYLOAD_SIZE = PACKET_MAX_PAYLOAD_SIZE - TCP_HEADER_LENGTH,
};

typedef struct TCP{
    nx_uint8_t srcPort;
    nx_uint8_t destPort;
    nx_uint8_t seq;
    nx_uint8_t ack;
    enum flag_type flags; // SYN, ACK, SYNACK, FIN (never carry payload data) 
    uint8_t adwindow;
    uint8_t payload[TCP_MAX_PAYLOAD_SIZE];
} TCP;

#endif