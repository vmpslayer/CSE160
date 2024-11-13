module TransportP{
    provides interface Transport;

    uses interface Timer<TMilli> as transportTimer;
}
implementation{
    socket_store_t connections[MAX_NUM_OF_SOCKETS];

    event void transportTimer.fired(){
        
    }

    command socket_t Transport.socket(){

    }
    command error_t Transport.bind(socket_t fd, socket_addr_t *addr){

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
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
}