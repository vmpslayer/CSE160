#include "../../includes/TCP.h"
#include "../../includes/socket.h"

module TransportP{
    provides interface Transport;

    uses interface Timer<TMilli> as transportTimer;
}
implementation{
    socket_store_t connections[MAX_NUM_OF_SOCKETS];

    command void Transport.initTransport(){
        call transportTimer.startOneShot(1000);
    }

    event void transportTimer.fired(){
        dbg(TRANSPORT_CHANNEL, "SUCCESS: Transport Started");
    }

    command socket_t Transport.socket(){
        // uint8_t i;
        // for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
        //     connections[i].state == CLOSED;
        // }
        // return 
    }
    command error_t Transport.bind(socket_t fd, socket_addr_t *addr){
        if(connections[fd].state == CLOSED){
            connections[fd].src = addr->port;
            connections[fd].dest = *addr;
            return SUCCESS;
        }
        return FAIL;
    }
    command socket_t Transport.accept(socket_t fd){

    }
    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){

    }
    command error_t Transport.receive(pack* package){

    }
    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){

    }
    command error_t Transport.connect(socket_t fd, socket_addr_t * addr){

    }
    command error_t Transport.close(socket_t fd){

    }
    command error_t Transport.release(socket_t fd){

    }
    command error_t Transport.listen(socket_t fd){

    }
    command error_t Transport.testServer(nx_uint8_t srcPort){
        if(connections[TOS_NODE_ID].srcPort == CLOSED){
            connections[TOS_NODE_ID].
        }
    }
    command error_t Transport.testClient(nx_uint8_t){

    }
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
}