#ifndef TCP_H
#define TCP_H

enum flag_type{
    SYN,
    SYNACK,
    ACK,
    FIN, 
};

typedef struct TCP{
    nx_uint16_t srcPort;
    nx_uint16_t destPort;
    nx_uint32_t seq;
    nx_uint32_t ack;
    enum flag_type flags; // SYN, ACK, SYNACK, FIN (never carry payload data)
    nx_uint16_t adwindow;
} TCP;

#endif